# MobileCode

iPhoneからMac上のClaude Codeを操作するモバイルターミナルアプリ。

## アーキテクチャ

- **サーバー**: Node.js中継サーバー (node-pty + WebSocket)
- **iOS**: SwiftUI + SwiftTerm

## セットアップ

### サーバー

```bash
cd server
cp .env.example .env
# .env の AUTH_TOKEN を変更
npm install
npm run dev
```

### iOS

1. `ios/MobileCode.xcodeproj` を Xcode で開く
2. SwiftTerm パッケージが自動解決されるのを待つ
3. iPhone シミュレータまたは実機でビルド・実行
4. 設定画面でサーバーURL (`ws://127.0.0.1:8765`) とトークンを入力

## 使い方

1. `npm run dev` でサーバーを起動
2. iOSアプリを起動して接続
3. ターミナル画面でClaude Codeを操作
