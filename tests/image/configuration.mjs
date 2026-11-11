// Minimal config for the boot gate only; production mounts its own.
export default {
  hostname: "localhost",
  systemAdministratorEmail: "admin@example.com",
  tls: { key: "/tls/smtp.key", certificate: "/tls/smtp.crt" },
  dataDirectory: "/data/",
};
