import { createServer } from "http";
import { WebSocketServer } from "ws";
import { config } from "./config.js";
import { PtyManager } from "./pty-manager.js";
import { handleConnection } from "./ws-handler.js";

const ptyManager = new PtyManager();
const server = createServer((_req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("MobileCode relay server\n");
});

const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  handleConnection(ws, ptyManager);
});

ptyManager.onExit((code) => {
  console.log(`[pty] exited with code ${code}`);
  // Notify all connected clients
  for (const client of wss.clients) {
    if (client.readyState === client.OPEN) {
      client.send(JSON.stringify({ type: "error", message: "PTY process exited" }));
    }
  }
});

server.listen(config.port, config.bindAddress, () => {
  console.log(`[server] listening on ${config.bindAddress}:${config.port}`);
});

// Graceful shutdown
const shutdown = () => {
  console.log("\n[server] shutting down...");
  ptyManager.kill();
  wss.close();
  server.close();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
