# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

MobileCode は iPhone から macOS 上の Claude Code CLI を操作するためのリモートターミナルアプリ。2つのコンポーネントで構成される：

- **サーバー** (`server/`): macOS で動作する Node.js/TypeScript の WebSocket リレーサーバー。Python の PTY ブリッジを介して Claude Code CLI とやり取りする
- **iOS アプリ** (`ios/`): SwiftUI + SwiftTerm で実装されたターミナルクライアント

## コマンド

### サーバー (server/)

```bash
cd server
npm install
npm run dev      # 開発: tsx でホットリロード (src/index.ts)
npm run build    # TypeScript を dist/ にコンパイル
npm start        # 本番: node dist/index.js
```

サーバーには `.env` ファイルが必要:
```
PORT=8765
AUTH_TOKEN=change-me
BIND_ADDRESS=127.0.0.1
```

### iOS アプリ (ios/)

Xcode でプロジェクトを開いてビルド・実行:
```bash
open ios/MobileCode.xcodeproj
```

テスト・lint コマンドは未設定 (MVP 段階)。

## アーキテクチャ

### 通信フロー

```
iPhone App (iOS/SwiftUI)
    ↕ WebSocket (binary frames: PTY I/O, text frames: JSON 制御メッセージ)
Relay Server (Node.js)
    ↕ subprocess stdin/stdout
Python PTY Bridge (pty-bridge.py)
    ↕ PTY fork
Claude Code CLI / bash
```

### メッセージプロトコル

`server/src/protocol.ts` と `ios/MobileCode/Models/ControlMessage.swift` で定義:

- **バイナリフレーム**: PTY の生の I/O (テキスト入出力)
- **テキストフレーム (JSON)**: 制御メッセージ
  - `auth`: 認証トークン
  - `resize`: ターミナルサイズ変更 (cols/rows)
  - `list_dir`: ディレクトリ一覧要求/応答
  - `launch`: 指定ディレクトリで PTY セッション開始
  - `status`: 接続状態通知

### サーバー側の主要コンポーネント

- **`ws-handler.ts`**: WebSocket 接続管理、認証、メッセージルーティング、ファイルシステム操作
- **`pty-manager.ts`**: Python ブリッジの起動・I/O 多重化・リサイズ処理
- **`pty-bridge.py`**: PTY fork と I/O リレー、カスタムリサイズエスケープシーケンス (`ESC]9;cols;rowsBEL`) の解析

### iOS 側の主要コンポーネント

- **`RelayConnection.swift`**: Observable な WebSocket クライアント。指数バックオフで最大 5 回まで自動再接続
- **`TerminalContainer.swift`**: SwiftTerm の `UIViewRepresentable` ラッパー
- **`DisplayConfig.swift`**: フォントサイズと画面サイズから cols/rows を動的計算
- **`ControlMessage.swift`**: クライアント↔サーバー間のメッセージ型定義

### 設計上の重要な決定

1. **Python PTY ブリッジ**: node-pty の代わりに Python を使用。リサイズシグナルのカスタムハンドリングを実現
2. **単一グローバル PTY**: 全クライアントが同一ターミナルセッションを共有。切断・再接続してもセッションは保持される
3. **バイナリ/テキスト分離**: PTY I/O はバイナリフレーム、制御メッセージは JSON テキストフレーム

### iOS アプリの画面遷移

設定未入力 → `SettingsView` → 認証成功 → `FolderBrowserView` → ディレクトリ選択 → `TerminalScreen`
