# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.3] - 2026-11-25

### Security

- The image no longer runs the Node.js and Caddy binaries bundled in Kill the
  Newsletter v2.0.9's release (node 25.2.1, and a Caddy built with Go modules
  carrying fixable critical CVEs). Node.js now comes from Hummingbird's
  `nodejs:24` runtime, with better-sqlite3 rebuilt for it, and Caddy v2.11.9 is
  built from source in `caddy/` against golang.org/x/net 0.62.0 and x/crypto
  0.58.0 on Hummingbird's Go 1.27 builder. Dependabot tracks `caddy/go.mod`.

### Changed
- CI is the fleet ci.yml (sdlc 0.15): one image build per release, published
  as `quay.io/crunchtools/newsletter` (was `quay.io/crunchtools/kill-the-newsletter`).
- Gatehouse triage receives the review job's result (`review_result`), so a PR whose review died before posting anything is held instead of passing.

- Promote signs the image with the fleet cosign key (`sign: true`), because
  bootc hosts are moving to trust only signed `quay.io/crunchtools` images
  (crunchtools/rhel10-bootc-server#47). Needs the repo's `cosign-signing`
  environment to hold `COSIGN_PRIVATE_KEY` and `COSIGN_PASSWORD`.
- The container release runs constitution v1.51.0's `container-release.yml`
  (was v1.46.0) and grants it `issues: write`, so a failed scheduled rebuild
  opens an issue instead of only warning. A `v*` promote now also refuses an
  image whose `version` label names a different release of this repo. This
  image sets that label in the Containerfile and only a release commit has
  ever moved it, so the next release must be a release PR that moves it from
  1.0.1 — where v1.0.2, tagged on a feature merge, left it.

## [1.0.1] - 2026-11-11

### Changed

- Constitution is now a v1.18.0 manifest: it holds only what is specific to
  this repo; fleet and profile rules apply by reference.
- Constitution validation is pinned to the inherited release via
  `.github/workflows/constitution.yml`.
- Dependabot auto-merges GitHub Actions minor and patch updates.

## [1.0.0] - 2026-09-20

First tagged release. This image has been running in production since before
it had version control. No changes are recorded prior to this point --
RT #1484 added this file on 2026-09-19, before this repo's first tag.
