# Lab 8 — API 操作

**学ぶこと**: Task で curl を束ねて API を快適に操作する

---

## エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| `GET` | `/health` | ヘルスチェック |
| `GET` | `/todos` | Todo 一覧 (Valkey キャッシュあり) |
| `POST` | `/todos` | Todo 作成 |
| `DELETE` | `/todos/:id` | Todo 削除 |

---

## ヘルスチェック

```bash
task api:health
```

```json
{
  "status": "ok",
  "app_key": "configured"
}
```

---

## Todo 一覧

```bash
task api:list
```

```json
[
  { "id": 3, "title": "運動",   "done": false },
  { "id": 2, "title": "勉強",   "done": false },
  { "id": 1, "title": "買い物", "done": false }
]
```

---

## Todo 作成

```bash
task api:create TITLE="買い物"
task api:create TITLE="勉強"
task api:create TITLE="運動"
```

```json
{ "id": 1, "title": "買い物", "done": false }
```

タイトルを省略するとデフォルト値が使われる:

```bash
task api:create
# → {"id":4,"title":"sample todo","done":false}
```

---

## Todo 削除

```bash
task api:delete ID=1
# → HTTP 204

# 存在しない ID を削除
task api:delete ID=999
# → HTTP 404
```

---

## MySQL シェルで直接確認する

```bash
task db:shell
```

```sql
-- レコードを確認
SELECT * FROM todos;

-- 実行計画を確認
EXPLAIN SELECT * FROM todos ORDER BY id DESC;

-- 手動で INSERT
INSERT INTO todos (title) VALUES ('直接挿入テスト');

exit
```

---

## シナリオ: 一連の操作

```bash
# 1. 空の状態を確認
task cache:flush
task api:list
# → []

# 2. Todo を作成
task api:create TITLE="タスクA"
task api:create TITLE="タスクB"
task api:create TITLE="タスクC"

# 3. 一覧で ID を確認
task api:list

# 4. 削除して一覧確認
task api:delete ID=2
task api:list

# 5. DB シェルで最終確認
task db:shell
# mysql> SELECT * FROM todos;
```
