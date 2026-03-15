import { spawn, type ChildProcess } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export class PtyManager {
  private process: ChildProcess | null = null;
  private processId = 0;
  private dataListeners: ((data: string) => void)[] = [];
  private exitListeners: ((code: number | undefined) => void)[] = [];

  get isRunning(): boolean {
    return this.process !== null;
  }

  get currentCwd(): string | undefined {
    return this._cwd;
  }

  private _cwd: string | undefined;

  spawn(cwd?: string): void {
    if (this.process) return;

    const bridgePath = join(__dirname, "pty-bridge.py");
    const claudePath = process.env.CLAUDE_PATH || "/Users/yuki/.local/bin/claude";
    const workingDir = cwd || process.env.HOME || "/";
    this._cwd = workingDir;

    const child = spawn("python3", [bridgePath, claudePath], {
      stdio: ["pipe", "pipe", "pipe"],
      env: {
        ...process.env,
        TERM: "xterm-256color",
        COLS: "80",
        ROWS: "24",
        PATH: `${process.env.HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${process.env.PATH || ""}`,
      },
      cwd: workingDir,
    });

    this.process = child;
    const myId = ++this.processId;

    child.stdout?.on("data", (data: Buffer) => {
      if (this.processId !== myId) return;
      const str = data.toString("utf-8");
      for (const listener of this.dataListeners) {
        listener(str);
      }
    });

    child.stderr?.on("data", (data: Buffer) => {
      const lines = data.toString("utf-8").trim().split("\n");
      for (const line of lines) {
        try {
          const msg = JSON.parse(line);
          if (msg.type === "started") {
            console.log(`[pty] spawned claude (pid: ${msg.pid})`);
          } else if (msg.type === "exited") {
            console.log(`[pty] exited with code ${msg.code}`);
          }
        } catch {
          console.error("[pty-bridge]", line);
        }
      }
    });

    child.on("exit", (code) => {
      if (this.processId !== myId) return;
      this.process = null;
      for (const listener of this.exitListeners) {
        listener(code ?? undefined);
      }
    });

    child.on("error", (err) => {
      if (this.processId !== myId) return;
      console.error("[pty] process error:", err.message);
      this.process = null;
    });
  }

  write(data: string): void {
    this.process?.stdin?.write(data);
  }

  resize(cols: number, rows: number): void {
    // Send resize as custom escape sequence: ESC]9;cols;rowsBEL
    this.process?.stdin?.write(`\x1b]9;${cols};${rows}\x07`);
    console.log(`[pty] resized to ${cols}x${rows}`);
  }

  onData(listener: (data: string) => void): void {
    this.dataListeners.push(listener);
  }

  onExit(listener: (code: number | undefined) => void): void {
    this.exitListeners.push(listener);
  }

  relaunch(cwd: string): void {
    // Increment processId first so old exit/data handlers become no-ops
    this.processId++;
    if (this.process) {
      this.process.kill("SIGTERM");
      this.process = null;
    }
    this.spawn(cwd);
  }

  kill(): void {
    this.process?.kill("SIGTERM");
    this.process = null;
  }
}
