# Project Template README

Copy this into a new repo for each project and fill the `metadata.yml`.

- `metadata.yml` - project metadata
- `PLAYBOOK.md` - project-specific playbook for rescue/experiments
- `scripts/` - helpful scripts (rescue, diagnostics, etc.)
- `diagnostics/` - place to store collected logs
- `data/` - runtime data such as `records.db` (usually ignored from VCS)

Usage:
1. Copy this template
2. Edit `metadata.yml`
3. Run `scripts/add_record.py` to create the first record
4. Generate a dashboard with `scripts/generate_dashboard.py`
