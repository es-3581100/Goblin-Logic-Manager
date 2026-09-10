#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

GENERATOR_VERSION = "goblin-pages/1.0"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def github_token() -> str | None:
    value = os.environ.get("GITHUB_TOKEN", "").strip()
    if value:
        return value
    try:
        cp = subprocess.run(
            ["gh", "auth", "token"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=10,
        )
        return cp.stdout.strip() or None
    except (FileNotFoundError, subprocess.SubprocessError):
        return None


def render_gfm(markdown: str, repo: str) -> str:
    body = json.dumps({"text": markdown, "mode": "gfm", "context": repo}).encode()
    headers = {
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json",
        "User-Agent": "Goblin-Logic-Manager-Pages",
        "X-GitHub-Api-Version": "2026-03-10",
    }
    token = github_token()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(
        "https://api.github.com/markdown", data=body, headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status != 200:
                raise RuntimeError(f"GitHub Markdown API returned HTTP {resp.status}")
            return resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub Markdown API HTTP {exc.code}: {detail[:1000]}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"GitHub Markdown API unavailable: {exc}") from exc


def extract_css(template: str) -> str:
    match = re.search(r"<style\b[^>]*>(.*?)</style>", template, re.I | re.S)
    if not match:
        raise RuntimeError("rendered-demo.html has no <style> block")
    return match.group(1).strip()


def build_page(rendered: str, css: str, repo: str, readme_hash: str, commit: str) -> str:
    repo_url = f"https://github.com/{repo}"
    safe_repo = html.escape(repo)
    safe_hash = html.escape(readme_hash)
    safe_commit = html.escape(commit)
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="description" content="Goblin-Logic-Manager — dynamic documentation manual generated from README.md.">
<meta name="goblin-readme-sha256" content="{safe_hash}">
<meta name="goblin-source-commit" content="{safe_commit}">
<title>Goblin-Logic-Manager — Dynamic Manual</title>
<style>
{css}
.source-link {{ color: inherit; text-decoration: none; }}
.source-link:hover {{ text-decoration: underline; }}
.pages-proof {{ word-break: break-all; }}
</style>
</head>
<body>
<header class="topbar">
  <div class="brand"><span class="logo" aria-hidden="true"></span><span>Goblin-Logic-Manager <small>/ Dynamic Manual</small></span></div>
  <div class="top-meta"><span class="badge">README → PAGES</span><span class="badge">AUTO-GENERATED</span></div>
</header>
<div class="layout">
  <aside class="sidebar" aria-label="README navigation">
    <div class="eyebrow">Document map</div>
    <nav class="toc" id="toc"></nav>
  </aside>
  <main>
    <article class="doc" id="readme">
{rendered}
      <div class="footer-note">Generated from <code>README.md</code> by {GENERATOR_VERSION}.</div>
    </article>
  </main>
  <aside class="right-rail" aria-label="Build provenance">
    <div class="rail-card">
      <h4>Source</h4>
      <div class="kv">
        <span>repo</span><span><a class="source-link" href="{repo_url}">{safe_repo}</a></span>
        <span>commit</span><span>{safe_commit}</span>
        <span>README</span><span class="pages-proof">{safe_hash[:16]}…</span>
      </div>
      <div class="rule"><strong>README.md is canonical.</strong><br>This page is a generated presentation surface.</div>
    </div>
  </aside>
</div>
<script>
(() => {{
  const slug = (text) => text.toLowerCase().trim().replace(/[^a-z0-9\\s-]/g, "").replace(/\\s+/g, "-").replace(/-+/g, "-");
  const toc = document.getElementById("toc");
  const seen = new Map();
  document.querySelectorAll("#readme h1, #readme h2, #readme h3").forEach((h) => {{
    let id = h.id || slug(h.textContent);
    const count = seen.get(id) || 0;
    seen.set(id, count + 1);
    if (count) id = `${{id}}-${{count + 1}}`;
    h.id = id;
    const a = document.createElement("a");
    a.href = `#${{id}}`;
    a.textContent = h.textContent;
    a.className = `toc-l${{Math.min(3, Number(h.tagName.substring(1)))}}`;
    toc.appendChild(a);
  }});
  document.querySelectorAll("#readme pre").forEach((pre) => {{
    const button = document.createElement("button");
    button.className = "copy";
    button.type = "button";
    button.textContent = "copy";
    button.addEventListener("click", async () => {{
      try {{
        await navigator.clipboard.writeText(pre.innerText);
        button.textContent = "copied";
        setTimeout(() => button.textContent = "copy", 1200);
      }} catch (_) {{ button.textContent = "failed"; }}
    }});
    pre.appendChild(button);
  }});
}})();
</script>
</body>
</html>
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "es-3581100/Goblin-Logic-Manager"))
    ap.add_argument("--readme", default="README.md")
    ap.add_argument("--template", default="rendered-demo.html")
    ap.add_argument("--output-dir", default="_site")
    ap.add_argument("--snapshot", action="store_true", help="also refresh rendered-demo.html locally")
    args = ap.parse_args()

    root = Path.cwd()
    readme = root / args.readme
    template = root / args.template
    output = root / args.output_dir
    if not readme.is_file():
        raise SystemExit(f"missing README: {readme}")
    if not template.is_file():
        raise SystemExit(f"missing visual template: {template}")

    readme_bytes = readme.read_bytes()
    readme_hash = sha256_bytes(readme_bytes)
    rendered = render_gfm(readme_bytes.decode("utf-8"), args.repo)
    css = extract_css(template.read_text(encoding="utf-8"))
    commit = os.environ.get("GITHUB_SHA", "").strip()
    if not commit:
        try:
            commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, timeout=10).strip()
        except Exception:
            commit = "unknown"

    page = build_page(rendered, css, args.repo, readme_hash, commit)
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    (output / "index.html").write_text(page, encoding="utf-8")
    (output / "rendered-demo.html").write_text(page, encoding="utf-8")
    (output / ".nojekyll").write_text("", encoding="utf-8")
    assets = root / "assets"
    if assets.is_dir():
        shutil.copytree(assets, output / "assets")

    provenance = {
        "schema": "goblin-pages-provenance/v1",
        "generator": GENERATOR_VERSION,
        "repository": args.repo,
        "source_commit": commit,
        "readme_sha256": readme_hash,
        "authority": "README.md",
        "generated_files": ["index.html", "rendered-demo.html"],
    }
    (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    if args.snapshot:
        template.write_text(page, encoding="utf-8")

    print(f"PASS: built {output / 'index.html'}")
    print(f"README_SHA256={readme_hash}")
    print(f"SOURCE_COMMIT={commit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
