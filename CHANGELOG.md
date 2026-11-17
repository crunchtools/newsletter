# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and this project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Security

- The image no longer runs the Node.js and Caddy binaries bundled in Kill the
  Newsletter v2.0.9's release (node 25.2.1, and a Caddy built with Go modules
  carrying fixable critical CVEs). Node.js now comes from Hummingbird's
  `nodejs:24` runtime, with better-sqlite3 rebuilt for it, and Caddy v2.11.9 is
  built from source in `caddy/` against golang.org/x/net 0.62.0 and x/crypto
  0.58.0 on Hummingbird's Go 1.27 builder. Dependabot tracks `caddy/go.mod`.

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
