import "dotenv/config";

export const config = {
  port: parseInt(process.env.PORT || "8765", 10),
  authToken: process.env.AUTH_TOKEN || "change-me",
  bindAddress: process.env.BIND_ADDRESS || "127.0.0.1",
} as const;
