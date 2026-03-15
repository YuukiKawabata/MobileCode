import WebSocket from "ws";
import { config } from "./config.js";

const url = `ws://127.0.0.1:${config.port}`;
const ws = new WebSocket(url);

ws.on("open", () => {
  ws.send(JSON.stringify({ type: "auth", token: config.authToken }));
});

ws.on("message", (data, isBinary) => {
  if (isBinary) {
    process.stdout.write(data as Buffer);
  } else {
    const msg = JSON.parse(data.toString());
    if (msg.type === "auth_result" && msg.success) {
      process.stderr.write("[viewer] connected - read-only mirror\n");
    } else if (msg.type === "error") {
      process.stderr.write(`[viewer] error: ${msg.message}\n`);
    }
  }
});

ws.on("close", () => {
  process.stderr.write("[viewer] disconnected\n");
  process.exit(0);
});

process.on("SIGINT", () => {
  ws.close();
});
