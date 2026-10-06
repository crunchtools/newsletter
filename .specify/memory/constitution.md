# kill-the-newsletter Constitution

> **Version:** 1.2.0
> **Ratified:** 2026-03-11
> **Amended:** 2026-10-02
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.20.0
> **Profile:** Container Image

This file holds what is specific to the Kill the Newsletter image. The fleet
rules and the Container Image profile apply at the inherited version and are
checked against this repo's files by `constitution.yml`. They are not restated
here.

## Upstream Binary Packaging

This repo packages the upstream
[leafac/kill-the-newsletter](https://github.com/leafac/kill-the-newsletter)
release (v2.0.9, the self-contained binary with bundled Node.js and Caddy) as
a container image. It does NOT fork or rebuild the upstream source. The only
change to upstream is a build-time patch to the bundled Caddy module so it
serves plain HTTP on port 8000 with the real hostname, letting a reverse
proxy front it while keeping correct Host headers for CSRF and URL
generation.

Image versioning: MAJOR for an upstream major version bump or changed port
mappings; MINOR for an upstream minor bump or new configuration options;
PATCH for Containerfile fixes, certificate updates and base image updates.

## Build Stages

| Stage | Image | Role |
|-------|-------|------|
| Download | `registry.access.redhat.com/ubi10/ubi` | Fetches the upstream release, generates the SMTP TLS certificate |
| Runtime | `quay.io/hummingbird/nodejs:latest` | Runs the binary |

`libatomic` is copied from the download stage because the bundled Node.js
needs it and the Hummingbird image does not ship it. SMTP STARTTLS uses a
self-signed RSA 4096-bit certificate generated at build time.

## Instance

| Context | Name |
|---------|------|
| GitHub repo | `crunchtools/newsletter` |
| Container image | `quay.io/crunchtools/kill-the-newsletter` |
| systemd service | `newsletter.crunchtools.com.service` |

## Ports and Volumes

| Port | Purpose |
|------|---------|
| 8000 | HTTP web UI (Caddy, patched from its default 443) |
| 25 | SMTP email reception (STARTTLS) |

| Path | Purpose |
|------|---------|
| `/data` | SQLite database and feed files |
| `/config/configuration.mjs` | Runtime configuration, bind-mounted read-only |

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-08 | Initial constitution |
| 1.1.0 | 2026-03-11 | Add Containerfile conventions, testing section; fix section numbering |
| 1.1.1 | 2026-09-25 | Gatehouse review, triage and pre-commit gates |
| 1.2.0 | 2026-10-02 | Manifest under constitution v1.18.0: fleet and profile restatement removed; ports corrected to match the Containerfile (8000, 25) |
