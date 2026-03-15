// Client → Server
export interface AuthMessage {
  type: "auth";
  token: string;
}

export interface ResizeMessage {
  type: "resize";
  cols: number;
  rows: number;
}

export interface ListDirMessage {
  type: "list_dir";
  path: string;
}

export interface LaunchMessage {
  type: "launch";
  cwd: string;
  cols?: number;
  rows?: number;
}

// Server → Client
export interface AuthResultMessage {
  type: "auth_result";
  success: boolean;
}

export interface ErrorMessage {
  type: "error";
  message: string;
}

export interface DirListingMessage {
  type: "dir_listing";
  path: string;
  entries: { name: string; isDir: boolean }[];
}

export interface LaunchResultMessage {
  type: "launch_result";
  success: boolean;
  cwd: string;
}

export interface PtyExitedMessage {
  type: "pty_exited";
  code: number | null;
}

export type ClientMessage = AuthMessage | ResizeMessage | ListDirMessage | LaunchMessage;
export type ServerMessage = AuthResultMessage | ErrorMessage | DirListingMessage | LaunchResultMessage | PtyExitedMessage;

export function parseClientMessage(data: string): ClientMessage | null {
  try {
    const msg = JSON.parse(data);
    if (msg.type === "auth" && typeof msg.token === "string") {
      return msg as AuthMessage;
    }
    if (
      msg.type === "resize" &&
      typeof msg.cols === "number" &&
      typeof msg.rows === "number"
    ) {
      return msg as ResizeMessage;
    }
    if (msg.type === "list_dir" && typeof msg.path === "string") {
      return msg as ListDirMessage;
    }
    if (msg.type === "launch" && typeof msg.cwd === "string") {
      return {
        type: "launch",
        cwd: msg.cwd,
        cols: typeof msg.cols === "number" ? msg.cols : undefined,
        rows: typeof msg.rows === "number" ? msg.rows : undefined,
      } as LaunchMessage;
    }
    return null;
  } catch {
    return null;
  }
}
