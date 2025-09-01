# Contributing

Quick onboarding

- Fork or Use this template to create a project repo.
- Clone and set your git user.name and user.email.
- Run `scripts/add_record.py --init-project --project-name "myproject" --owner "Me" --summary "init"` to initialize `metadata.yml`.

Coding style
- Shell scripts: follow POSIX where practical; run `shellcheck` locally.
- Python: keep simple; run `flake8` and `python -m compileall` before committing.

CI and Pages
- CI runs on pushes and PRs to `main` and enforces linting. Fix failures before merging.
- Pages deploys the `dashboard/` folder. Add or regenerate dashboard entries and push to trigger deploy.

Reporting issues
- Open issues in this repository with reproduction steps and relevant logs under `diagnostics/`.
