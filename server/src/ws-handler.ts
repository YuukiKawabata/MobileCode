import { readdirSync, statSync } from "fs";
import { resolve } from "path";
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

  ws.on("message", (raw, isBinary) => {
    // Binary frame → PTY input
    if (isBinary) {
      if (!authenticated || !ptyManager.isRunning) return;
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

    if (msg.type === "list_dir") {
      try {
        const dirPath = resolve(msg.path || process.env.HOME || "/");
        const items = readdirSync(dirPath, { withFileTypes: true });
        const entries = items
          .filter((item) => !item.name.startsWith("."))
          .map((item) => ({ name: item.name, isDir: item.isDirectory() }))
          .sort((a, b) => {
            if (a.isDir !== b.isDir) return a.isDir ? -1 : 1;
            return a.name.localeCompare(b.name);
          });
        sendJson({ type: "dir_listing", path: dirPath, entries });
      } catch (err) {
        const emsg = err instanceof Error ? err.message : "failed to list directory";
        sendJson({ type: "error", message: emsg });
      }
    }

    if (msg.type === "launch") {
      try {
        const cwd = resolve(msg.cwd);
        // Verify directory exists
        const stat = statSync(cwd);
        if (!stat.isDirectory()) {
          sendJson({ type: "error", message: "Not a directory" });
          return;
        }
        // Kill existing PTY and spawn new one (suppresses stale exit events)
        ptyManager.relaunch(cwd);
        sendJson({ type: "launch_result", success: true, cwd });
        console.log(`[ws] launched claude in ${cwd}`);
      } catch (err) {
        const emsg = err instanceof Error ? err.message : "failed to launch";
        sendJson({ type: "launch_result", success: false, cwd: msg.cwd });
        sendJson({ type: "error", message: emsg });
      }
    }
  });

  ws.on("close", () => {
    console.log("[ws] disconnected (PTY kept alive)");
  });

  ws.on("error", (err) => {
    console.error("[ws] error:", err.message);
  });
}
