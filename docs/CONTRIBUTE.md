# Contributing to NexoraOS

Thank you for your interest! NexoraOS is an open, independent distribution and
we welcome contributions of all sizes.

## Ways to contribute

- **Bug reports** — open an issue with the `bug` label. Include the ISO version, hardware, and reproduction steps.
- **Build failures** — these are auto-triaged by `auto-fix.yml`, but manual PRs are welcome. See `docs/ARCHITECTURE.md` for the loop.
- **Package requests** — open an issue with `package-request`. We'll add the package to `archiso/profile/packages.x86_64` if it's in the official repos or AUR.
- **Code** — Python (NexoraDE tools), Bash (build scripts), YAML (CI configs), CSS (theming).
- **Translations** — locale files live in `archiso/profile/airootfs/etc/skel/.config/nexora/locale/` (TBD).
- **Themes** — `nexora-de/themes/Nexora-2026/` for GTK, Openbox, icons.

## Development workflow

1. Fork the repo.
2. Create a feature branch: `git checkout -b feature/your-feature`.
3. Make changes. Test locally:
   ```bash
   ./scripts/dev-setup.sh
   ./nexora-de/bin/nexora-panel    # test panel
   ```
4. For ISO build changes, build locally before pushing:
   ```bash
   ./scripts/build-local.sh --docker
   ```
5. Push and open a PR against `main`. The CI will build an ISO automatically; check the workflow run.

## Coding standards

### Python (NexoraDE tools)

- Target Python 3.10+.
- Use `gi.repository.Gtk` 3.0 (not 4.0 — we want max compatibility).
- Memory budget: < 50 MB RSS per tool.
- Use `subprocess.Popen(cmd, shell=True, start_new_session=True)` for spawning apps.
- No heavy deps (no numpy, no scipy, no Qt in NexoraDE).

### Bash (build scripts)

- `set -euo pipefail` at the top of every script.
- Quote variables.
- Use `sudo` for commands that need root.

### YAML (CI / Calamares)

- 2-space indent.
- No tabs.
- Comment liberally — these files are read by humans, not just machines.

## Commit message format

```
<type>(<scope>): <subject>

<body>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `style`.
Scopes: `panel`, `launcher`, `settings`, `store`, `installer`, `archiso`, `ci`, `docs`.

Example: `feat(panel): add brightness slider on systems with /sys/class/backlight`

## PR checklist

- [ ] Code builds locally (`./scripts/build-local.sh --docker`)
- [ ] No new linter errors
- [ ] Commit messages follow the format above
- [ ] If adding a package: it's available in `core`, `extra`, `multilib`, or AUR
- [ ] If changing CI: tested with `workflow_dispatch` on your fork

## Licensing

By contributing, you agree that your contributions will be licensed under the
same license as the file you're modifying (GPL-3.0-or-later for the distro
as a whole; MIT for the NexoraDE tools).
