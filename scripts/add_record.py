#!/usr/bin/env python3
"""Add a timestamped record to the repo-local SQLite database.

Usage examples:
    python3 scripts/add_record.py \
        --source Zimaboard --type diagnostic --summary "Boot fixed" \
        --details "Edited GRUB"

    python3 scripts/add_record.py \
        --source Zimaboard --type diagnostic \
        --summary "Privileged diagnostics" \
        --details-file diagnostics/remote_privileged.txt
"""

import argparse
import os
import sqlite3
import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'records.db')
REPO_ROOT = os.path.join(os.path.dirname(__file__), '..')
METADATA_TMPL = os.path.join(REPO_ROOT, 'template', 'metadata.yml.tmpl')
METADATA_OUT = os.path.join(REPO_ROOT, 'metadata.yml')

SCHEMA = '''
CREATE TABLE IF NOT EXISTS records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT NOT NULL,
    source TEXT,
    type TEXT,
    summary TEXT,
    details TEXT
);
'''


def ensure_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute(SCHEMA)
    conn.commit()
    return conn


def add_record(conn, source, rtype, summary, details):
    ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    cur = conn.cursor()
    cur.execute('INSERT INTO records (ts, source, type, summary, details) VALUES (?, ?, ?, ?, ?)',
                (ts, source, rtype, summary, details))
    conn.commit()
    return cur.lastrowid, ts


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', required=False, default='local')
    p.add_argument('--type', dest='rtype', required=False, default='note')
    p.add_argument('--summary', required=True)
    p.add_argument('--details', required=False, help='Details text')
    p.add_argument(
        '--details-file', required=False,
        help='Path to a file whose contents will be stored as details'
    )
    p.add_argument(
        '--init-project', action='store_true',
        help='Initialize a metadata.yml from template if present'
    )
    p.add_argument(
        '--project-name', required=False,
        help='Project name used when initializing metadata'
    )
    p.add_argument(
        '--owner', required=False,
        help='Owner name used when initializing metadata'
    )
    args = p.parse_args()

    details = ''
    if args.details_file:
        try:
            with open(args.details_file, 'r') as f:
                details = f.read()
        except Exception as e:
            print(f'Warning: could not read details file: {e}')
            details = ''
    elif args.details:
        details = args.details

    conn = ensure_db()
    if args.init_project:
        # try to create metadata.yml from template
        if os.path.exists(METADATA_OUT):
            print('metadata.yml already exists; skipping init')
        elif os.path.exists(METADATA_TMPL):
            try:
                with open(METADATA_TMPL, 'r') as f:
                    tpl = f.read()
                name = args.project_name or '<project-name>'
                owner = args.owner or '<owner-name>'
                created = datetime.datetime.utcnow().date().isoformat()
                out = tpl.replace('<project-name>', name)
                out = out.replace('<YYYY-MM-DD>', created)
                out = out.replace('<owner-name>', owner)
                with open(METADATA_OUT, 'w') as f:
                    f.write(out)
                print(f'Wrote metadata.yml to {METADATA_OUT}')
            except Exception as e:
                print(f'Warning: could not initialize metadata.yml: {e}')
        else:
            print('No metadata template found; skipping init')
    rid, ts = add_record(conn, args.source, args.rtype, args.summary, details)
    print(f'Inserted record id={rid} ts={ts}')


if __name__ == '__main__':
    main()
