# GitHub Pages — Dynamic Manual

Goblin-Logic-Manager uses two documentation surfaces:

```text
README.md
  ├─ GitHub repository README
  └─ GitHub Actions
       ↓
     GitHub Markdown API
       ↓
     Goblin visual shell
       ↓
     _site/index.html
       ↓
     GitHub Pages
```

## Authority

`README.md` is the content authority.

`rendered-demo.html` is a visual/theme reference and optional local snapshot.
The Pages deployment is generated at CI time and is not committed back to the
repository.

This avoids generated-file commit loops, a second documentation authority,
CI rewriting `main`, and stale Pages content after README changes.

## One-time Pages enablement

Repository administrators must configure GitHub Pages to use **GitHub Actions**
as its publishing source.

UI:

1. Repository **Settings**
2. **Pages**
3. **Build and deployment**
4. **Source → GitHub Actions**

Or, with a GitHub CLI identity that has repository administration + Pages write
permission:

```bash
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  repos/es-3581100/Goblin-Logic-Manager/pages \
  -f build_type=workflow
```

## Local preview

If `gh auth token` works:

```bash
python3 scripts/build-pages-site.py \
  --repo es-3581100/Goblin-Logic-Manager \
  --output-dir _site

python3 -m http.server 8000 --directory _site
```

Open `http://127.0.0.1:8000/`.

To intentionally refresh the checked-in visual snapshot too:

```bash
python3 scripts/build-pages-site.py \
  --repo es-3581100/Goblin-Logic-Manager \
  --output-dir _site \
  --snapshot
```

Do not make `--snapshot` part of the Pages workflow. The deployment is already
generated from the current README.
