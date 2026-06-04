# Lab 1 — サービスとヘルスチェック

**学ぶこと**: `depends_on + condition: service_healthy` による起動順制御

---

## 起動ログで順序を観察する

```bash
task up
task logs
```

ログの流れ:

```
sops-init   | [sops-init] secrets written to volume
sops-init   | exited with code 0
db-1        | ready for connections
cache-1     | Ready to accept connections
app-1       | NOTICE: fpm is running, ready to handle connections
web-1       | start worker processes
```

`sops-init` が正常終了してから `db` / `cache` / `app` が起動する。

---

## サービス状態を確認する

```bash
task ps
```

期待する出力:

```
NAME                  STATUS
php-todo-sops-init-1  Exited (0)    ← 正常終了した init container
php-todo-db-1         healthy
php-todo-cache-1      healthy
php-todo-app-1        healthy
php-todo-web-1        running
```

**ポイント**: `sops-init` が `Exited (0)` 以外だと `app` と `db` は起動しない。

---

## healthcheck の仕組みを確認する

`compose.yaml` の各サービスに設定されている `healthcheck`:

| サービス | ヘルスチェックコマンド |
|---------|---------------------|
| `app` | `nc -z localhost 9000` (PHP-FPM ポート確認) |
| `db` | `mysqladmin ping -h localhost` |
| `cache` | `valkey-cli ping` |

### ヘルスチェックを手動で試す

```bash
# PHP-FPM がポート 9000 でリッスンしているか
docker compose exec app nc -zv localhost 9000
# → localhost (127.0.0.1:9000) open

# MySQL が応答するか
docker compose exec db mysqladmin ping -h localhost
# → mysqld is alive  (または Access denied)
# ※ "Access denied" はサーバーがネットワーク接続に応答した証拠
#    ヘルスチェックの目的は「疎通確認」なので Access denied = 正常とみなしてよい
#    コンテナ未起動やネットワーク断の場合は "Connection refused" になり exit 1 で検知できる

# Valkey が応答するか
docker compose exec cache valkey-cli ping
# → PONG
```

---

## sops-init のログを確認する

```bash
task logs SVCNAME=sops-init
```

```
sops-init-1  | [sops-init] secrets written to volume
```

`service_completed_successfully` は exit code 0 のときだけ成立する。  
シークレットのパスや鍵が間違っている場合はここでエラーになる。
