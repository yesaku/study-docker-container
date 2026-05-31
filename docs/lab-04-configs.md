# Lab 4 — Configs

**学ぶこと**: `configs` でホストのファイルをコンテナに注入する仕組み

---

## マウントされた nginx.conf を確認する

```bash
task inspect:config
```

出力:

```nginx
server {
    listen      80;
    server_name _;

    location / {
        fastcgi_pass  app:9000;
        fastcgi_index index.php;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;
    }
}
```

`web/nginx.conf` の内容がコンテナの `/etc/nginx/conf.d/default.conf` に届いている。

---

## compose.yaml の該当箇所

```yaml
configs:
  nginx_conf:
    file: ./web/nginx.conf           # ← ホストのファイルを登録

services:
  web:
    configs:
      - source: nginx_conf
        target: /etc/nginx/conf.d/default.conf   # ← コンテナ内パス
```

---

## nginx.conf を変更して動作を確認する

`web/nginx.conf` にカスタムヘッダーを追加:

```nginx
server {
    listen      80;
    server_name _;

    add_header X-Powered-By "php-todo-handson";   # ← 追加

    location / {
        fastcgi_pass  app:9000;
        fastcgi_index index.php;
        include       fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;
    }
}
```

configs は再起動時に再読み込みされる:

```bash
task restart
curl -si http://localhost:8080/health | grep X-Powered-By
# → X-Powered-By: php-todo-handson
```

変更後は元に戻しておく。

---

## configs と volumes の違い

| | configs | volumes |
|-|---------|---------|
| 用途 | 設定ファイルの注入 | データの永続化・共有 |
| 書き込み | 読み取り専用 | 読み書き可能 |
| Docker Swarm | 複数ノードに配布 | ノードローカル (要別途対応) |
| サイズ制限 | 512 KB | 制限なし |
