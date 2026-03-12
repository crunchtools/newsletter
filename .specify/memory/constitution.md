# kill-the-newsletter Constitution

> **Version:** 1.1.0
> **Ratified:** 2026-03-11
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.0.0
> **Profile:** Container Image

This constitution establishes the core principles, constraints, and workflows that govern the Kill the Newsletter container image.

---

## I. Core Principles

### 1. Upstream Binary Packaging

This repo packages the upstream [leafac/kill-the-newsletter](https://github.com/leafac/kill-the-newsletter) release as a container image. It does NOT fork, modify, or rebuild the upstream source.

**What this repo provides:**
- Multi-stage Containerfile (UBI download stage + Hummingbird runtime)
- GitHub Actions workflow for dual-registry push (Quay.io + GHCR)
- Self-signed TLS certificates for SMTP STARTTLS
- Governance documents (.specify/)

**What upstream provides:**
- The self-contained kill-the-newsletter binary (bundled Node.js + Caddy)
- Application source code, static assets, and build artifacts

### 2. Two Registry Channels

Every release MUST be available through both registries:

| Registry | Image |
|----------|-------|
| Quay.io (primary) | `quay.io/crunchtools/kill-the-newsletter` |
| GHCR (mirror) | `ghcr.io/crunchtools/kill-the-newsletter` |

### 3. Semantic Versioning

Follow [Semantic Versioning 2.0.0](https://semver.org/) strictly.

- **MAJOR**: Breaking changes (upstream major version bump, changed port mappings)
- **MINOR**: New functionality (upstream minor bump, new configuration options)
- **PATCH**: Bug fixes (Containerfile fixes, cert updates, base image updates)

---

## II. Technology Stack

| Layer | Technology |
|-------|------------|
| Upstream App | Kill the Newsletter v2.0.9 |
| Download Stage | registry.access.redhat.com/ubi10/ubi |
| Runtime Base | quay.io/hummingbird/nodejs:latest |
| Web Server | Caddy (bundled in upstream binary) |
| SMTP Server | smtp-server (Node.js, bundled) |
| Database | SQLite (in /data volume) |
| TLS (SMTP) | Self-signed RSA 4096-bit |
| CI/CD | GitHub Actions (dual-push) |

---

## III. Containerfile Conventions

- Uses `Containerfile` (not Dockerfile)
- Multi-stage build: UBI download stage fetches upstream binary, Hummingbird runtime stage runs it
- Self-signed TLS certificates generated via `openssl` for SMTP STARTTLS
- `dnf install -y --nodocs` in download stage, `dnf clean all` after

## IV. Container Architecture

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 443 | HTTPS | Caddy web UI (local self-signed certs) |
| 80 | HTTP | Caddy HTTP redirect |
| 25 | SMTP | Email reception (STARTTLS with self-signed certs) |

### Volumes

| Path | Purpose |
|------|---------|
| `/data` | SQLite database + feed files |
| `/config/configuration.mjs` | Runtime configuration (bind mount) |

### Configuration

Runtime configuration is provided via bind-mounted `/config/configuration.mjs`:

```javascript
export default {
  hostname: "newsletter.example.com",
  tls: {
    key: "/tls/smtp.key",
    certificate: "/tls/smtp.crt",
  },
  dataDirectory: "/data/",
};
```

---

## V. Testing

- **Build test**: CI builds the container image on every push to main
- **Weekly rebuild**: Picks up base image and upstream updates

---

## VI. Quality Gates

Every change must pass:

1. **Container Build** — `podman build -f Containerfile .`
2. **Trivy Scan** — Weekly CVE scanning (continue-on-error)
3. **Gourmand** — AI slop detection (zero violations)

---

## VII. Naming Conventions

| Context | Name |
|---------|------|
| GitHub repo | `crunchtools/newsletter` |
| Container image | `quay.io/crunchtools/kill-the-newsletter` |
| Lotor service | `newsletter.crunchtools.com.service` |
| License | AGPL-3.0-or-later |

---

## VIII. Governance

### Amendment Process

1. Create a PR with proposed changes to this constitution
2. Document rationale in PR description
3. Require maintainer approval
4. Update version number upon merge

### Ratification History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-08 | Initial constitution |
| 1.1.0 | 2026-03-11 | Add Containerfile conventions, testing section; fix section numbering |
