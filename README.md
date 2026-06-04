# PHP Todo — Docker Compose ハンズオン

フレームワーク不使用の PHP 8.4 + MySQL 9.3 + Valkey 8.1 + SOPS で構成した  
Docker Compose 学習用プロジェクトです。

---

## アーキテクチャ

```
                    ┌──────────────────────────────────────────┐
                    │          frontend network                 │
  Client ──HTTP──▶  │  nginx:1.27  ──fastcgi──▶  php-fpm:8.4  │
                    └─────────────────────┬────────────────────┘
                                          │
                    ┌─────────────────────▼────────────────────┐
                    │           backend network                 │
                    │   mysql:9.3          valkey:8.1           │
                    └──────────────────────────────────────────┘

  起動順: sops-init → db / cache (並列) → app → web
```

### Docker Compose 5要素の対応

| 要素 | 実装箇所 |
|------|---------|
| `services` | web / app / db / cache / sops-init |
| `networks` | frontend (web↔app) / backend (app↔db↔cache) |
| `volumes` | db-data (永続化) / decrypted (tmpfs共有) / dev bind mount |
| `configs` | nginx.conf → web コンテナに注入 |
| `secrets` | app_key.txt → Docker native secrets で app にマウント |

---

## 必要なツール

| ツール | 用途 | インストール |
|--------|------|-------------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | コンテナランタイム + Docker Compose | 公式サイトからインストーラーを入手 |
| [Task](https://taskfile.dev/installation/) | タスクランナー (Make の上位互換) | 下記参照 |
| [age](https://github.com/FiloSottile/age#installation) | ファイル暗号化ツール (SOPS のバックエンド) | 下記参照 |
| [SOPS](https://github.com/getsops/sops#1downloading) | シークレットファイルの暗号化・復号 | 下記参照 |
| [jq](https://jqlang.github.io/jq/download/) | JSON 整形 (任意) | 下記参照 |

### macOS

```bash
brew install go-task age sops jq
```

### Linux

```bash
# Task: https://taskfile.dev/installation/
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# age
brew install age   # または https://github.com/FiloSottile/age/releases

# SOPS
brew install sops  # または https://github.com/getsops/sops/releases

# jq
apt-get install jq  # または brew install jq
```

### Windows

```powershell
winget install Task.Task
winget install FiloSottile.age
winget install Mozilla.sops
winget install jqlang.jq
```

---

## クイックスタート

```bash
task setup              # 初回手順を表示
task secrets:init       # age キーペア + app_key 生成
# .sops.yaml に公開鍵を貼り付ける
cp secrets/dev/secrets.yaml.example secrets/dev/secrets.yaml
# パスワードを編集してから
task secrets:encrypt
task up
task ps                 # 全サービスが healthy になるまで待つ
```

---

## ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [セットアップ](docs/setup.md) | 前提条件・初回設定の詳細手順 |
| [Lab 1: サービス](docs/lab-01-services.md) | 起動順制御・ヘルスチェック |
| [Lab 2: ネットワーク](docs/lab-02-networks.md) | frontend / backend 分離の検証 |
| [Lab 3: ボリューム](docs/lab-03-volumes.md) | データ永続化・dev bind mount |
| [Lab 4: Configs](docs/lab-04-configs.md) | nginx.conf の注入 |
| [Lab 5: Docker Secrets](docs/lab-05-docker-secrets.md) | native secrets の仕組み |
| [Lab 6: SOPS](docs/lab-06-sops.md) | init container で暗号化シークレットを渡す |
| [Lab 7: Valkey](docs/lab-07-valkey.md) | キャッシュのヒット/ミス検証 |
| [Lab 8: API](docs/lab-08-api.md) | Task を使った API 操作 |
| [Lab 9: dev / prod](docs/lab-09-dev-prod.md) | 環境切り替えの違い |
| [Task 一覧](docs/tasks.md) | 全タスクのリファレンス |
