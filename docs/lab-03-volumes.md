# Lab 3 — Volumes

**学ぶこと**: named volume によるデータ永続化と、dev の bind mount によるホットリロード

---

## 3-a. データ永続化

### データを作成してコンテナを再起動する

```bash
# Todo を作成
task api:create TITLE="永続化テスト"
task api:list
# → "永続化テスト" が返る

# コンテナを停止・削除 (volume は残る)
task down

# ボリュームが残っていることを確認
docker volume ls | grep php-todo
# → php-todo_db-data

# 再起動
task up

# データが残っていることを確認
task api:list
# → "永続化テスト" がまだ返る
```

### ボリュームごと削除する

```bash
task clean          # down -v でボリュームも削除
task up
task api:list
# → [] (空になっている)
```

---

## 3-b. Dev の bind mount (ホットリロード)

`compose.dev.yaml` で `./app/src:/var/www/html` をマウントしているため、  
コンテナの再ビルドなしにコードの変更が即時反映される。

### 動作を確認する

```bash
task up   # dev で起動

# health エンドポイントのレスポンスを確認
task api:health
# → {"status":"ok","app_key":"configured"}

# app/src/index.php の health 関数にフィールドを追加
```

`app/src/index.php` の `health()` 関数を編集:

```php
function health(): void
{
    respond(200, [
        'status'  => 'ok',
        'app_key' => file_exists('/run/secrets/app_key') ? 'configured' : 'missing',
        'env'     => getenv('APP_ENV') ?: 'unknown',   // ← 追加
    ]);
}
```

```bash
# 再ビルドなしで即反映
task api:health
# → {"status":"ok","app_key":"configured","env":"development"}
```

### prod では bind mount がない

```bash
task down
task up ENV=prod

# PHP ファイルを変更しても反映されない (イメージにbake済み)
# 反映するには task build ENV=prod が必要
```

---

## 3-c. tmpfs volume (decrypted)

SOPS が復号したシークレットは `decrypted` という named volume に書かれる。

```yaml
# compose.yaml
volumes:
  decrypted:
    # Linux本番環境では以下を有効化してメモリ上のみに保持
    # driver_opts:
    #   type: tmpfs
    #   device: tmpfs
```

Linux 本番環境で `driver_opts` を有効にすると、シークレットはメモリ上のみに存在し  
ホストのディスクには残らない。macOS / Docker Desktop では通常の named volume になる。

---

## volume の種類まとめ

| volume | 種類 | 用途 |
|--------|------|------|
| `db-data` | named volume | MySQL データ永続化 |
| `decrypted` | named volume (本番: tmpfs) | SOPS 復号ファイルの一時共有 |
| `./app/src:/var/www/html` | bind mount (dev のみ) | コードのホットリロード |
