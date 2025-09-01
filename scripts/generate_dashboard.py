#!/usr/bin/env python3
"""Generate a simple HTML dashboard from the SQLite records DB.
Produces `dashboard/index.html` and per-record markdown files under `dashboard/entries/`.
"""
import os
import sqlite3

REPO_ROOT = os.path.join(os.path.dirname(__file__), '..')
DB_PATH = os.path.join(REPO_ROOT, 'data', 'records.db')
DASH_DIR = os.path.join(REPO_ROOT, 'dashboard')
ENT_DIR = os.path.join(DASH_DIR, 'entries')

HTML_TMPL = '''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Rescue Repo Dashboard</title>
  <style>
    body{font-family:system-ui,Segoe UI,Roboto,Arial;margin:2rem}
    table{border-collapse:collapse;width:100%}
    th,td{border:1px solid #ddd;padding:8px}
    th{background:#f2f2f2}
  </style>
</head>
<body>
  <h1>Rescue Repo Dashboard</h1>
  <p>Generated from <code>data/records.db</code></p>
  <h2>Summary</h2>
  <ul>
    <li>Total records: {{total}}</li>
  </ul>
  <h2>Recent entries</h2>
  <table>
    <thead><tr><th>ID</th><th>Timestamp</th><th>Source</th><th>Type</th><th>Summary</th></tr></thead>
    <tbody>
    {{rows}}
    </tbody>
  </table>
</body>
</html>
'''

ROW_TMPL = '<tr><td><a href="entries/{id}.md">{id}</a></td><td>{ts}</td><td>{source}</td><td>{type}</td><td>{summary}</td></tr>'


def read_records():
    if not os.path.exists(DB_PATH):
        return []
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute('SELECT id, ts, source, type, summary, details FROM records ORDER BY id DESC')
    rows = cur.fetchall()
    conn.close()
    return rows


def ensure_dirs():
    os.makedirs(ENT_DIR, exist_ok=True)
    os.makedirs(DASH_DIR, exist_ok=True)


def write_entry_file(r):
    fid, ts, source, rtype, summary, details = r
    path = os.path.join(ENT_DIR, f'{fid}.md')
    with open(path, 'w') as f:
        f.write(f'# Record {fid}\n\n')
        f.write(f'- timestamp: {ts}\n')
        f.write(f'- source: {source}\n')
        f.write(f'- type: {rtype}\n')
        f.write('\n## Summary\n\n')
        f.write(summary or '')
        f.write('\n\n## Details\n\n')
        f.write(details or '')


def generate():
    ensure_dirs()
    rows = read_records()
    total = len(rows)
    rows_html = '\n'.join(ROW_TMPL.format(id=r[0], ts=r[1], source=r[2] or '', type=r[3] or '', summary=(r[4] or '').replace('<', '&lt;')) for r in rows[:50])

    # write per-entry files
    for r in rows:
        write_entry_file(r)

    html = HTML_TMPL.replace('{{total}}', str(total)).replace('{{rows}}', rows_html)
    out = os.path.join(DASH_DIR, 'index.html')
    with open(out, 'w') as f:
        f.write(html)
    print(f'Wrote dashboard: {out} (total records: {total})')


if __name__ == '__main__':
    generate()
