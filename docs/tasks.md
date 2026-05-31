# Task リファレンス

全タスクの一覧です。`task --list` でも確認できます。

---

## ライフサイクル

| タスク | 説明 |
|--------|------|
| `task setup` | 初回セットアップ手順を表示 |
| `task up` | サービス起動 (dev) |
| `task up ENV=prod` | サービス起動 (prod) |
| `task down` | サービス停止 |
| `task build` | イメージをキャッシュなしでビルド |
| `task restart` | 全サービスを再起動 |
| `task ps` | サービスの状態一覧 |
| `task logs` | 全サービスのログを追跡 |
| `task logs SVCNAME=app` | 特定サービスのログを追跡 |
| `task reset` | ボリューム削除 → 再ビルド → 起動 |
| `task clean` | コンテナ・ネットワーク・ボリュームを全削除 |

---

## API

| タスク | 説明 |
|--------|------|
| `task api:health` | `GET /health` |
| `task api:list` | `GET /todos` |
| `task api:create` | `POST /todos` (タイトル: "sample todo") |
| `task api:create TITLE="xxx"` | `POST /todos` (タイトル指定) |
| `task api:delete ID=1` | `DELETE /todos/1` |
| `task api:bench` | キャッシュなし vs ありのレスポンス時間を比較 |

---

## キャッシュ (Valkey)

| タスク | 説明 |
|--------|------|
| `task cache:keys` | 全キーを表示 |
| `task cache:get` | `todos` キーの値を取得 |
| `task cache:get KEY=xxx` | 任意のキーの値を取得 |
| `task cache:flush` | 全キャッシュを削除 |
| `task cache:monitor` | Valkey へのコマンドをリアルタイム監視 |

---

## データベース

| タスク | 説明 |
|--------|------|
| `task db:shell` | MySQL の対話シェルを開く |
| `task db:dump` | DB を stdout にダンプ |

---

## アプリ

| タスク | 説明 |
|--------|------|
| `task app:shell` | app コンテナの sh を開く |

---

## 検査

| タスク | 説明 |
|--------|------|
| `task inspect:networks` | frontend / backend ネットワークの詳細を表示 |
| `task inspect:secrets` | `/run/secrets/app_key` と `/run/decrypted/DB_PASSWORD` を表示 |
| `task inspect:config` | コンテナにマウントされた nginx.conf を表示 |

---

## シークレット (SOPS)

| タスク | 説明 |
|--------|------|
| `task secrets:init` | age キーペアと app_key.txt を生成 |
| `task secrets:encrypt` | `secrets/dev/secrets.yaml` を暗号化 |
| `task secrets:encrypt ENV=prod` | `secrets/prod/secrets.yaml` を暗号化 |
| `task secrets:decrypt` | dev シークレットを平文で表示 |
| `task secrets:decrypt ENV=prod` | prod シークレットを平文で表示 |
| `task secrets:edit` | 暗号化ファイルをエディタで直接編集 |

---

## 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `ENV` | `dev` | 使用する compose オーバーライドファイル |
| `WEB_PORT` | `8080` | ホストの公開ポート |
| `SVCNAME` | (空) | `task logs` で対象サービスを指定 |
| `TITLE` | `sample todo` | `task api:create` の Todo タイトル |
| `ID` | (必須) | `task api:delete` の Todo ID |
| `KEY` | `todos` | `task cache:get` のキー名 |
