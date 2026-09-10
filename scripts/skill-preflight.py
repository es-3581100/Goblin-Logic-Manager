#!/usr/bin/env python3
"""Read-only preflight for Goblin's routed OpenCode skills."""
from __future__ import annotations
import argparse, json, os, re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
REG=ROOT/'skill-registry.json'

def parse_name(path:Path):
    try: text=path.read_text(encoding='utf-8',errors='replace')
    except OSError: return None
    m=re.match(r'^---\s*\n(.*?)\n---\s*\n',text,re.S)
    if not m: return None
    for line in m.group(1).splitlines():
        if line.startswith('name:'):
            return line.split(':',1)[1].strip().strip("'\"")
    return None

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--json',action='store_true')
    ap.add_argument('--skill-dir',type=Path,default=Path(os.environ.get('OPENCODE_SKILLS_DIR',Path.home()/'.config/opencode/skills')))
    args=ap.parse_args()
    reg=json.loads(REG.read_text())
    rows=[]
    for s in reg['skills']:
        sid=s['id']
        if sid=='goblin-chunk-compact':
            candidates=[ROOT/'.opencode/skills'/sid/'SKILL.md', args.skill_dir/sid/'SKILL.md']
        else:
            candidates=[args.skill_dir/sid/'SKILL.md']
        found=next((p for p in candidates if p.is_file()),None)
        declared=parse_name(found) if found else None
        state='FOUND' if found and declared==sid else ('INVALID' if found else 'MISSING')
        rows.append({'id':sid,'status':s['status'],'state':state,'path':str(found) if found else None,'declared_name':declared})
    if args.json:
        print(json.dumps({'schema':'goblin-logic-manager/skill-preflight/v1','skill_dir':str(args.skill_dir),'skills':rows},indent=2))
    else:
        for r in rows:
            print(f"{r['state']:<7} {r['id']:<34} declared={r['declared_name'] or '-'} path={r['path'] or '-'}")
        print(f"SUMMARY found={sum(r['state']=='FOUND' for r in rows)} missing={sum(r['state']=='MISSING' for r in rows)} invalid={sum(r['state']=='INVALID' for r in rows)}")
    return 1 if any(r['state']=='INVALID' for r in rows) else 0

if __name__=='__main__':
    raise SystemExit(main())
