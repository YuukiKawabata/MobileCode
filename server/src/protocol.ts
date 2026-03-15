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

// Server → Client
export interface AuthResultMessage {
  type: "auth_result";
  success: boolean;
}

export interface ErrorMessage {
  type: "error";
  message: string;
}

export type ClientMessage = AuthMessage | ResizeMessage;
export type ServerMessage = AuthResultMessage | ErrorMessage;

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
    return null;
  } catch {
    return null;
  }
}
