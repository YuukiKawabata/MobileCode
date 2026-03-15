import type { WebSocket } from "ws";
import type { PtyManager } from "./pty-manager.js";
import { config } from "./config.js";
import {
  parseClientMessage,
  type ServerMessage,
} from "./protocol.js";

export function handleConnection(ws: WebSocket, ptyManager: PtyManager): void {
  let authenticated = false;

  console.log("[ws] new connection");

  const sendJson = (msg: ServerMessage) => {
    ws.send(JSON.stringify(msg));
  };

  // PTY output → client (binary frames)
  const onPtyData = (data: string) => {
    if (authenticated && ws.readyState === ws.OPEN) {
      ws.send(Buffer.from(data, "utf-8"), { binary: true });
    }
  };

  ptyManager.onData(onPtyData);

  // Ensure PTY is running
  if (!ptyManager.isRunning) {
    try {
      ptyManager.spawn();
    } catch (err) {
      const msg = err instanceof Error ? err.message : "failed to spawn PTY";
      console.error("[pty] spawn error:", msg);
      sendJson({ type: "error", message: `PTY spawn failed: ${msg}` });
      ws.close(4002, "pty spawn failed");
      return;
    }
  }

  ws.on("message", (raw, isBinary) => {
    // Binary frame → PTY input
    if (isBinary) {
      if (!authenticated) return;
      // Auto-respawn PTY if it exited
      if (!ptyManager.isRunning) {
        try {
          ptyManager.spawn();
        } catch (err) {
          const emsg = err instanceof Error ? err.message : "failed to spawn PTY";
          sendJson({ type: "error", message: `PTY spawn failed: ${emsg}` });
          return;
        }
      }
      const buf = raw as Buffer;
      ptyManager.write(buf.toString("utf-8"));
      return;
    }

    // Text frame → control message
    const text = raw.toString("utf-8");
    const msg = parseClientMessage(text);

    if (!msg) {
      sendJson({ type: "error", message: "invalid message" });
      return;
    }

    if (msg.type === "auth") {
      if (msg.token === config.authToken) {
        authenticated = true;
        sendJson({ type: "auth_result", success: true });
        console.log("[ws] authenticated");
        // Respawn PTY if it exited
        if (!ptyManager.isRunning) {
          try {
            ptyManager.spawn();
          } catch (err) {
            const emsg = err instanceof Error ? err.message : "failed to spawn PTY";
            console.error("[pty] spawn error:", emsg);
            sendJson({ type: "error", message: `PTY spawn failed: ${emsg}` });
          }
        }
      } else {
        sendJson({ type: "auth_result", success: false });
        console.log("[ws] auth failed");
        ws.close(4001, "authentication failed");
      }
      return;
    }

    if (!authenticated) {
      sendJson({ type: "error", message: "not authenticated" });
      return;
    }

    if (msg.type === "resize") {
      ptyManager.resize(msg.cols, msg.rows);
    }
  });

  ws.on("close", () => {
    console.log("[ws] disconnected (PTY kept alive)");
  });

  ws.on("error", (err) => {
    console.error("[ws] error:", err.message);
  });
}
