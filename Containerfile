# Kill the Newsletter — Email-to-RSS bridge
#
# Converts email newsletters into Atom feeds using Kill the Newsletter v2.0.9.
# Upstream's release is self-contained: it bundles its own Node.js and Caddy
# binaries, and both went stale (node 25.2.1, Caddy built against a
# golang.org/x/net and x/crypto with fixable criticals, one node CVE on KEV).
# This image keeps upstream's application tree and swaps both binaries out:
# Node.js comes from Hummingbird's nodejs:24 (LTS) runtime, and Caddy is built
# from source in caddy/ with its Go dependencies pinned there. Node 24 rather
# than 26: the better-sqlite3 that KTN v2.0.9 ships does not compile against
# node 26's V8, and 24 needs no change to the application tree.
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

# Stage 1: Caddy from source (caddy/go.mod pins it and its dependencies)
FROM quay.io/hummingbird/go:1.27-builder AS caddy

WORKDIR /src
COPY caddy/ ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/caddy . && \
    /out/caddy version

# Stage 2: Kill the Newsletter's application tree, rebuilt for Node.js 24
FROM quay.io/hummingbird/nodejs:24-builder AS download

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# gcc-c++/make/python3: node-gyp, to build better-sqlite3 against node 24's
# ABI. libatomic is no longer needed: it was for the bundled node binary.
RUN dnf install -y gcc-c++ make python3 openssl tar gzip && dnf clean all

WORKDIR /build

# Download Kill the Newsletter v2.0.9 pre-built release
RUN curl -fsSL https://github.com/leafac/kill-the-newsletter/releases/download/v2.0.9/kill-the-newsletter--ubuntu--v2.0.9.tar.gz | \
    tar xzf - --strip-components=1

# Drop the bundled runtimes. The launcher and @radically-straightforward/caddy
# both look for them at node_modules/.bin/, so the replacements go there too.
# better-sqlite3 is the one native addon; rebuild it for this node.
RUN rm _/node_modules/.bin/node _/node_modules/.bin/caddy && \
    ln -s /usr/bin/node _/node_modules/.bin/node && \
    rm -rf _/node_modules/better-sqlite3/build && \
    node-gyp rebuild --release --directory=_/node_modules/better-sqlite3 && \
    node -e 'new (require("/build/_/node_modules/better-sqlite3"))(":memory:").close(); console.log("better-sqlite3 loads under", process.version)'

# Patch Caddy module at build time to serve HTTP on port 8000 with the real
# hostname (not localhost). This lets Apache proxy via plain HTTP while keeping
# correct Host headers for CSRF and URL generation.
RUN node -e ' \
      const fs = require("fs"); \
      const f = "/build/_/node_modules/@radically-straightforward/caddy/build/index.mjs"; \
      let c = fs.readFileSync(f, "utf8"); \
      const patched = c.replace( \
        /systemAdministratorEmail !== undefined \? hostname : .localhost./, \
        "`http://${hostname}:8000`" \
      ); \
      if (patched === c) { console.error("Caddy module patch did not apply"); process.exit(1); } \
      fs.writeFileSync(f, patched); \
      console.log("Caddy module patched for HTTP on port 8000"); \
    '

# Generate self-signed certs for SMTP STARTTLS
RUN openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
    -keyout /build/smtp.key \
    -out /build/smtp.crt \
    -subj "/CN=newsletter.crunchtools.com" 2>/dev/null

# Stage 3: Minimal runtime image
FROM quay.io/hummingbird/nodejs:24

LABEL name="kill-the-newsletter" \
      version="1.0.3" \
      summary="Email-to-RSS bridge converting newsletters to Atom feeds" \
      description="Kill the Newsletter converts email newsletters into Atom feeds for RSS readers" \
      maintainer="crunchtools.com" \
      url="https://github.com/crunchtools/newsletter" \
      io.k8s.display-name="Kill the Newsletter" \
      io.openshift.tags="newsletter,rss,atom,email,smtp" \
      org.opencontainers.image.source="https://github.com/crunchtools/newsletter" \
      org.opencontainers.image.description="Email-to-RSS bridge converting newsletters to Atom feeds" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

# Root, as before: SMTP binds port 25 and /data is owned by root on the host.
USER root

WORKDIR /app

COPY --from=download /build/kill-the-newsletter /app/kill-the-newsletter
COPY --from=download /build/_/ /app/_/
COPY --from=caddy /out/caddy /app/_/node_modules/.bin/caddy

# Copy SMTP TLS certs
COPY --from=download /build/smtp.key /tls/smtp.key
COPY --from=download /build/smtp.crt /tls/smtp.crt

# Web (Caddy): 8000 (HTTP, patched from default 443)
# SMTP: 25
EXPOSE 8000 25

VOLUME ["/data"]

ENTRYPOINT ["/app/kill-the-newsletter"]
CMD ["/config/configuration.mjs"]
