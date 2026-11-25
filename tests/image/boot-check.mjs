// Boot gate, run inside the image: start the server with the minimal config and
// require HTTP 200 on loopback :8000, as the host-driven boot-gate.sh did.
import { spawn } from "node:child_process";
import { setTimeout as sleep } from "node:timers/promises";

const server = spawn("/app/kill-the-newsletter", ["tests/image/configuration.mjs"], {
  detached: true,
  stdio: ["ignore", "inherit", "inherit"],
});
let exited = null;
server.on("exit", (code, signal) => {
  exited = code ?? signal;
});

let verdict = 1;
let last = "no response";
for (let attempt = 0; attempt < 60; attempt++) {
  if (exited !== null) {
    console.error(`server exited: ${exited}`);
    break;
  }
  try {
    const response = await fetch("http://127.0.0.1:8000/", {
      headers: { Host: "localhost:8000" },
    });
    last = `HTTP ${response.status}`;
    if (response.status === 200) {
      console.log("boot gate: HTTP 200 on :8000");
      verdict = 0;
      break;
    }
  } catch (error) {
    last = String(error.cause?.code ?? error.message);
  }
  await sleep(2000);
}
if (verdict !== 0) console.error(`boot gate failed: ${last}`);
try {
  process.kill(-server.pid, "SIGKILL");
} catch {}
process.exit(verdict);
