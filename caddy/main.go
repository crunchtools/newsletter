// Caddy for Kill the Newsletter, built from source so its Go dependencies can
// move ahead of upstream's release binaries (the one KTN bundles, and
// Hummingbird's, both carried a fixable critical in golang.org/x/net). This is
// what xcaddy writes for a standard build: no plugins, KTN needs none.
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	_ "github.com/caddyserver/caddy/v2/modules/standard"
)

func main() {
	caddycmd.Main()
}
