# Lab 7 — Valkey キャッシュ

**学ぶこと**: キャッシュのヒット/ミス・TTL・リアルタイム監視

---

## Valkey とは

Redis 7.2 互換の OSS フォーク。PHP の `phpredis` 拡張がそのまま使える。  
このプロジェクトでは `GET /todos` の結果を 30 秒間キャッシュする。

---

## 7-a. キャッシュのベンチマーク

DB 直接取得とキャッシュヒットのレスポンス時間を比較する:

```bash
task api:bench
```

出力例:

```
--- 1回目: DB直接取得 (キャッシュなし) ---
real    0m0.042s

--- 2回目: Valkeyキャッシュ ---
real    0m0.004s
```

---

## 7-b. Valkey に保存されているキーを確認する

```bash
task cache:keys
# → todos

task api:bench
# → [{"id":1,"title":"sample todo","done":false}]
```

TTL (残り有効秒数) を確認:

```bash
docker compose exec cache valkey-cli TTL todos
# → 27  (30秒 - 経過時間)
```

---

## 7-c. キャッシュのヒット/ミスをリアルタイムで観察する

ターミナルを2つ開いて試す:

```bash
# ターミナル1: Valkey へのコマンドを監視
task cache:monitor
```

```bash
# ターミナル2: API を操作
task api:list      # → MONITOR に "GET todos" が流れる
task api:create TITLE="new"  # → "DEL todos" が流れる (キャッシュ削除)
task api:list      # → 再び "GET todos" → キャッシュミス → "SETEX todos 30 ..."
task api:list      # → "GET todos" のみ → キャッシュヒット
```

`Ctrl+C` で監視を終了。

---

## 7-d. キャッシュを手動でクリアする

```bash
task cache:flush
# → OK

task api:list   # → DB から再取得 (キャッシュミス)
```

---

## 7-e. キャッシュの仕組みをコードで確認する

`app/src/index.php`:

```php
function list_todos(): void
{
    $cache  = cache();
    $cached = $cache->get('todos');

    if ($cached !== false) {           // キャッシュヒット
        respond(200, json_decode($cached, true));
        return;
    }
                                       // キャッシュミス → DB から取得
    $rows = db()->query('SELECT id, title, done FROM todos ORDER BY id DESC')->fetchAll();
    $cache->setex('todos', 30, json_encode($rows));   // 30秒キャッシュ
    respond(200, $rows);
}
```

Todo を作成・削除すると `cache()->del('todos')` でキャッシュが削除される。  
次の `GET /todos` で DB から再取得してキャッシュを更新する。
