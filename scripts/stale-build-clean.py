#!/usr/bin/env python3
"""Find rebuildable build folders in projects nobody has touched lately, and optionally delete them.

  stale-build-clean.py                 dry run: write a plan and print totals
  stale-build-clean.py --delete PLAN   delete exactly what a reviewed plan lists (node_modules and .next only)

A project is stale when no source file changed and no git commit, checkout or pull happened in --days
(default 30). Folders used by a running process or a systemd user unit are never touched.
Virtualenvs (.venv, venv) are only listed, never deleted: some are slow or fragile to rebuild.
"""
import argparse, json, os, shutil, subprocess, sys, time

HOME = os.path.expanduser('~')
BASES = [os.path.join(HOME, d) for d in ('dev', 'Desktop', 'Documents')]
DELETABLE = {'node_modules', '.next'}
LIST_ONLY = {'.venv', 'venv'}
# build or tool output: never descended into, and never counted as "someone worked here"
IGNORED = {'.git', 'dist', 'build', 'out', '__pycache__', '.turbo', '.cache', '.vercel', '.expo', 'target',
           '.gradle', 'coverage', '.pytest_cache', '.mypy_cache', '.ruff_cache', '.wrangler', '.svelte-kit', '.astro'}


def git_activity(d):
    """Newest of HEAD and logs/HEAD. Not the index: a plain `git status` rewrites it."""
    g = os.path.join(d, '.git')
    if os.path.isfile(g):  # worktree: "gitdir: /path"
        try:
            g = open(g).read().split('gitdir:', 1)[1].strip()
        except (OSError, IndexError):
            return 0
    newest = 0
    for f in ('HEAD', os.path.join('logs', 'HEAD')):
        try:
            newest = max(newest, os.stat(os.path.join(g, f)).st_mtime)
        except OSError:
            pass
    return newest


def busy_paths():
    """Folders a running process or a systemd user unit points at."""
    out = set()
    for pid in filter(str.isdigit, os.listdir('/proc')):
        try:
            out.add(os.path.realpath(f'/proc/{pid}/cwd'))
            for arg in open(f'/proc/{pid}/cmdline', 'rb').read().split(b'\0'):
                a = arg.decode('utf-8', 'replace')
                if a.startswith(HOME + '/'):
                    out.add(os.path.realpath(a))
        except OSError:
            pass
    units = os.path.join(HOME, '.config/systemd/user')
    for name in os.listdir(units) if os.path.isdir(units) else []:
        try:
            for line in open(os.path.join(units, name), errors='replace'):
                if line.startswith(('ExecStart', 'WorkingDirectory')):
                    for tok in line.split('=', 1)[1].replace('%h', HOME).split():
                        if tok.startswith(HOME + '/'):
                            out.add(os.path.realpath(tok))
        except OSError:
            pass
    return out


def scan(d, root, found, newest):
    """Returns the newest source mtime under d. Records build folders in `found` as (path, kind, project root)."""
    try:
        entries = list(os.scandir(d))
    except OSError:
        return 0
    names = {e.name for e in entries}
    mine = 0
    if '.git' in names:
        root = d
        mine = git_activity(d)
    for e in entries:
        try:
            if e.is_symlink():
                continue
            if e.is_dir():
                if e.name in DELETABLE or e.name in LIST_ONLY:
                    # a venv must look like one; a node_modules needs a package.json beside it
                    if e.name in LIST_ONLY and not os.path.exists(os.path.join(e.path, 'pyvenv.cfg')):
                        mine = max(mine, scan(e.path, root, found, newest))
                        continue
                    found.append((e.path, e.name, root or d, 'package.json' in names))
                elif e.name not in IGNORED:
                    mine = max(mine, scan(e.path, root, found, newest))
            else:
                mine = max(mine, e.stat().st_mtime)
        except OSError:
            pass
    newest[d] = mine
    return mine


def size_kb(p):
    r = subprocess.run(['du', '-sk', p], capture_output=True, text=True)
    try:
        return int(r.stdout.split()[0])
    except (IndexError, ValueError):
        return 0


def plan(days, path):
    found, newest = [], {}
    for b in BASES:
        if os.path.isdir(b):
            scan(b, None, found, newest)
    busy, cutoff, items = busy_paths(), time.time() - days * 86400, []
    for p, kind, root, has_pkg in found:
        in_use = any(b == root or b.startswith(root + '/') for b in busy)
        if newest.get(root, 0) > cutoff:
            why = 'active'
        elif in_use:
            why = 'in use'
        elif kind in DELETABLE and not has_pkg:
            why = 'no package.json'
        else:
            why = ''
        if why:
            continue
        last = newest.get(root, 0)
        items.append({'path': p, 'kind': kind, 'root': root, 'kb': size_kb(p),
                      'idle_days': int((time.time() - last) / 86400) if last else None,
                      'delete': kind in DELETABLE})
    items.sort(key=lambda i: -i['kb'])
    json.dump({'days': days, 'made': time.strftime('%F %T'), 'items': items}, open(path, 'w'), indent=1)
    for label, pick in (('to delete (node_modules, .next)', True), ('listed only (virtualenvs)', False)):
        sel = [i for i in items if i['delete'] == pick]
        print(f"{label}: {len(sel)} folders, {sum(i['kb'] for i in sel) / 1048576:.1f} GB")
    print(f'skipped as active or in use: {len(found) - len(items)} folders\nplan: {path}')


def delete(path, log):
    data = json.load(open(path))
    freed, failed = 0, 0
    with open(log, 'a') as out:
        out.write(f"\n## Stale build folders removed, {time.strftime('%F %T')}\n\n"
                  f"From projects idle for {data['days']}+ days. Restore with the project's install command.\n\n")
        for i in data['items']:
            p = i['path']
            if not i['delete'] or os.path.basename(p) not in DELETABLE or not os.path.isdir(p) or os.path.islink(p):
                continue
            try:
                try:
                    shutil.rmtree(p)
                except PermissionError:  # read-only folders (copied from Windows): make them writable, retry once
                    subprocess.run(['chmod', 'u+w', os.path.dirname(p)])  # removing p needs a writable parent
                    subprocess.run(['chmod', '-R', 'u+w', p])
                    shutil.rmtree(p)
                freed += i['kb']
                out.write(f"- {p.replace(HOME, '~')} ({i['kb'] / 1024:.0f} MB)\n")
            except OSError as e:
                failed += 1
                out.write(f"- {p.replace(HOME, '~')}: FAILED ({e.__class__.__name__}), left as is\n")
            out.flush()
        out.write(f"\nTotal: about {freed / 1048576:.1f} GB, {failed} failed.\n")
    print(f'removed about {freed / 1048576:.1f} GB, {failed} failed, log: {log}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--days', type=int, default=30)
    ap.add_argument('--plan', default=os.path.join(HOME, '.local/state/stale-build-plan.json'))
    ap.add_argument('--delete', metavar='PLAN')
    ap.add_argument('--log', default=os.path.join(HOME, '.local/state/stale-build-clean.log'))
    a = ap.parse_args()
    delete(a.delete, a.log) if a.delete else plan(a.days, a.plan)
