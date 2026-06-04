# Lab 2 — ネットワーク分離

**学ぶこと**: `networks` による frontend / backend 分離と、サービス間の到達可否

---

## ネットワーク構成を確認する

```bash
task inspect:networks
```

注目する箇所:

```json
[
  {
    "Name": "php-todo_frontend",
    "Containers": {
      "<container-id>": { "Name": "php-todo-app-1", "IPv4Address": "172.x.0.x/16" },
      "<container-id>": { "Name": "php-todo-web-1", "IPv4Address": "172.x.0.x/16" }
    }
  },
  {
    "Name": "php-todo_backend",
    "Containers": {
      "<container-id>": { "Name": "php-todo-cache-1", "IPv4Address": "172.y.0.x/16" },
      "<container-id>": { "Name": "php-todo-db-1",    "IPv4Address": "172.y.0.x/16" },
      "<container-id>": { "Name": "php-todo-app-1",   "IPv4Address": "172.y.0.x/16" }
    }
  }
]
```

`app` だけが両方のネットワークに属している。

---

## 到達可否を検証する

### web → db (到達できないはず)

```bash
docker compose exec web sh -c "nc -zv db 3306 2>&1"
```

期待する出力:

```
nc: bad address 'db'
```

`web` は `frontend` ネットワークのみに属するため、`backend` にある `db` を名前解決できない。

### app → db (到達できるはず)

```bash
docker compose exec app sh -c "nc -zv db 3306 2>&1"
```

期待する出力:

```
Connection to db (172.y.0.x) 3306 port [tcp/mysql] succeeded!
```

`app` は両ネットワークに属するため到達できる。

### app → cache (到達できるはず)

```bash
docker compose exec app sh -c "nc -zv cache 6379 2>&1"
```

```
Connection to cache (172.y.0.x) 6379 port [tcp/redis] succeeded!
```

---

## なぜ分離するのか

```
frontend: web ←→ app     (HTTPリクエスト処理)
backend:  app ←→ db      (データ読み書き)
          app ←→ cache   (キャッシュ読み書き)
```

`web` から直接 `db` や `cache` に接続できない設計にすることで、  
nginx の設定ミスや脆弱性をついた攻撃がDBに直接届かなくなる。

---

## compose.yaml の該当箇所

```yaml
networks:
  frontend:
  backend:

services:
  web:
    networks: [frontend]           # frontend のみ

  app:
    networks: [frontend, backend]  # 両方

  db:
    networks: [backend]            # backend のみ

  cache:
    networks: [backend]            # backend のみ
```
