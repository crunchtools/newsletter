# Kill the Newsletter — Email-to-RSS bridge
#
# Converts email newsletters into Atom feeds using Kill the Newsletter v2.0.9
# Self-contained binary (bundled Node.js + Caddy) from upstream release
#
# Build:
#   podman build -t quay.io/crunchtools/kill-the-newsletter -f Containerfile .
#
# Run:
#   podman run -d --name newsletter.crunchtools.com \
#     -p 127.0.0.1:8093:8000 \
#     -p 0.0.0.0:25:25 \
#     -v /srv/newsletter.crunchtools.com/config/configuration.mjs:/config/configuration.mjs:ro,Z \
#     -v /srv/newsletter.crunchtools.com/data:/data:Z \
#     quay.io/crunchtools/kill-the-newsletter:latest

# Stage 1: Download and prepare release artifacts
FROM registry.access.redhat.com/ubi10/ubi AS download

RUN dnf install -y openssl libatomic && dnf clean all

WORKDIR /build

# Download Kill the Newsletter v2.0.9 pre-built release (self-contained binary)
RUN curl -sL https://github.com/leafac/kill-the-newsletter/releases/download/v2.0.9/kill-the-newsletter--ubuntu--v2.0.9.tar.gz | \
    tar xzf - --strip-components=1

# Generate self-signed certs for SMTP STARTTLS
RUN openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
    -keyout /build/smtp.key \
    -out /build/smtp.crt \
    -subj "/CN=newsletter.crunchtools.com" 2>/dev/null

# Stage 2: Minimal runtime image
FROM quay.io/hummingbird/nodejs:latest

LABEL name="kill-the-newsletter" \
      version="0.1.0" \
      summary="Email-to-RSS bridge converting newsletters to Atom feeds" \
      description="Kill the Newsletter converts email newsletters into Atom feeds for RSS readers" \
      maintainer="crunchtools.com" \
      url="https://github.com/crunchtools/newsletter" \
      io.k8s.display-name="Kill the Newsletter" \
      io.openshift.tags="newsletter,rss,atom,email,smtp" \
      org.opencontainers.image.source="https://github.com/crunchtools/newsletter" \
      org.opencontainers.image.description="Email-to-RSS bridge converting newsletters to Atom feeds" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

USER root

WORKDIR /app

# Copy the self-contained binary and source tree from download stage
COPY --from=download /build/kill-the-newsletter /app/kill-the-newsletter
COPY --from=download /build/_/ /app/_/

# Copy libatomic (required by bundled Node.js binary, not in Hummingbird image)
COPY --from=download /usr/lib64/libatomic.so.1* /usr/lib64/

# Copy SMTP TLS certs
COPY --from=download /build/smtp.key /tls/smtp.key
COPY --from=download /build/smtp.crt /tls/smtp.crt

# Patch Caddy module at build time to serve HTTP on port 8000 with the real
# hostname (not localhost). This lets Apache proxy via plain HTTP while keeping
# correct Host headers for CSRF and URL generation.
RUN mkdir -p /data /config && \
    chmod +x /app/kill-the-newsletter && \
    /app/_/node_modules/.bin/node -e ' \
      const fs = require("fs"); \
      const f = "/app/_/node_modules/@radically-straightforward/caddy/build/index.mjs"; \
      let c = fs.readFileSync(f, "utf8"); \
      c = c.replace( \
        /systemAdministratorEmail !== undefined \? hostname : .localhost./, \
        "`http://${hostname}:8000`" \
      ); \
      fs.writeFileSync(f, c); \
      console.log("Caddy module patched for HTTP on port 8000"); \
    '

# Web (Caddy): 8000 (HTTP, patched from default 443)
# SMTP: 25
EXPOSE 8000 25

VOLUME ["/data"]

ENTRYPOINT ["/app/kill-the-newsletter"]
CMD ["/config/configuration.mjs"]
