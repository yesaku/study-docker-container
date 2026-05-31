# Lab 2 — ネットワーク分離

**学ぶこと**: `networks` による frontend / backend 分離と、サービス間の到達可否

---

## ネットワーク構成を確認する

```bash
task inspect:networks
```

注目する箇所:

```json
"php-todo_frontend": {
  "Containers": {
    "web":  { "IPv4Address": "172.x.0.2/16" },
    "app":  { "IPv4Address": "172.x.0.3/16" }
  }
},
"php-todo_backend": {
  "Containers": {
    "app":   { "IPv4Address": "172.y.0.2/16" },
    "db":    { "IPv4Address": "172.y.0.3/16" },
    "cache": { "IPv4Address": "172.y.0.4/16" }
  }
}
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
nc: getaddrinfo for host "db" port 3306: Name does not resolve
```

`web` は `frontend` ネットワークのみに属するため、`backend` にある `db` を名前解決できない。

### app → db (到達できるはず)

```bash
docker compose exec app sh -c "nc -zv db 3306 2>&1"
```

期待する出力:

```
db (172.y.0.3:3306) open
```

`app` は両ネットワークに属するため到達できる。

### app → cache (到達できるはず)

```bash
docker compose exec app sh -c "nc -zv cache 6379 2>&1"
```

```
cache (172.y.0.4:6379) open
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
