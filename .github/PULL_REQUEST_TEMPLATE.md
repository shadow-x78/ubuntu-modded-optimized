### What does this PR do?

### Why?

Reference the `CHANGELOG.md` entry or issue this PR belongs to.

### How was it tested?

- [ ] `sh -n` passes on all modified scripts
- [ ] `shellcheck -s sh` shows no new warnings
- [ ] Manual smoke test on: <!-- Android version + Termux version -->

### Checklist

- [ ] File headers match UMO style (`# UMO - <module> (GPL-3.0-or-later)` + GitHub URL).
- [ ] `CHANGELOG.md` updated with a new versioned entry.
- [ ] Version bump in `bin/umo-install` if this is a release PR.
- [ ] If touching the UMO mark or banner art: all five version homes agree, both
      terminal modes verified (UTF-8 half-blocks and `UMO_ASCII=1`), and every art
      line is the same width.
