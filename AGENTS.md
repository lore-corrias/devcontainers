# AGENTS.md

## Repo overview

Monorepo that builds three OCI container images pushed to `ghcr.io/lore-corrias/`:

| Image | Context dir | Distrobox .ini |
|---|---|---|
| `devcontainer` | `devcontainer/` | — |
| `ctfbox` | `ctfbox/` | `distroboxes/ctfbox.ini` |
| `nvim` | `nvim/` | `distroboxes/neovim.ini` |

## Build system

- **CI uses buildah** (redhat-actions/buildah-build), not Docker. Local dev likely uses podman/distrobox.
- Each image has this structure:
  - `<name>/<name>.dockerfile` — the Dockerfile
  - `<name>/packages/` — JSON5 package lists
  - `<name>/scripts/` — shell install scripts

## Package management convention

Package lists live in `*/packages/*.json5` as flat JSON arrays of strings. Install scripts strip `//` comments (via `grep -v '^\s*//'`) and pipe through `jq -r '.[]' | xargs -r <pkg-mgr> install`.

- **devcontainer / nvim**: fedora base, uses `dnf`
- **ctfbox**: archlinux base, uses `pacman`

## CI triggers

All three build workflows (`build-{ctfbox,devcontainer,neovim}.yml`) trigger on:
- `workflow_dispatch` (manual)
- `push` with path filters on their respective dir
- Monthly cron (1st of month at 05:00)

Images are pushed to GHCR and signed with cosign (`cosign.pub` at repo root). Push + sign is gated on the branch **not** starting with `dependencies/` (Renovate branches).

## Renovate

Self-hosted Renovate (`renovate.yml`, `renovate.json5`) runs weekly on Mondays. Custom `regex` manager parses `// renovate:` annotations in the JSON5 package files:

```
// renovate: datasource=... depName=... versioning=...
```

Renovate PRs use the `dependencies/` branch prefix and are grouped by `stack:devcontainer` / `stack:ctfbox` labels.

## Notable quirks

- The `nvim` image (built from `nvim/nvim.dockerfile`) copies scripts from `devcontainer/scripts/` and `devcontainer/packages/` — it shares the devcontainer tooling. CI for neovim (`build-neovim.yml`) monitors `devcontainer/**` for this reason.
- The `build-neovim.yml` workflow may have a latent bug: it references `./devcontainer/devcontainer.dockerfile` as the containerfile (line 37) instead of the expected `./nvim/nvim.dockerfile`. The image name is correctly `nvim`. This has not been flagged because the neovim image also includes devcontainer tooling and both images share the same base — but verify before touching the pipeline.
- `ctfbox` uses a pinned SHA1 checksum (`add-blackarch.sh`) for the BlackArch strap script.
