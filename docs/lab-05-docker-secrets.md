# Lab 5 — Docker native Secrets

**学ぶこと**: `secrets` でファイルを `/run/secrets/` にマウントする仕組み

---

## マウントされたシークレットを確認する

```bash
task inspect:secrets
```

出力:

```
=== Docker native secret: /run/secrets/app_key ===
dGhpcyBpcyBhIHRlc3Qga2V5...   ← secrets/app_key.txt の内容

=== SOPS decrypted: /run/decrypted/DB_PASSWORD ===
your_password
```

---

## health エンドポイントで確認する

```bash
task api:health
# → {"status":"ok","app_key":"configured"}
```

`app_key` フィールドは `/run/secrets/app_key` の存在チェック結果。  
ファイルが正しくマウントされていれば `configured`、なければ `missing`。

`app/src/index.php` の該当箇所:

```php
function health(): void
{
    respond(200, [
        'status'  => 'ok',
        'app_key' => file_exists('/run/secrets/app_key') ? 'configured' : 'missing',
    ]);
}
```

---

## compose.yaml の該当箇所

```yaml
secrets:
  app_key:
    file: ./secrets/app_key.txt   # ← ホストのファイルを登録

services:
  app:
    secrets:
      - app_key   # → /run/secrets/app_key にマウント
```

---

## secrets と volumes の違い

| | secrets | volumes |
|-|---------|---------|
| マウント先 | `/run/secrets/<name>` (固定) | 任意のパス |
| 書き込み | 読み取り専用 | 読み書き可能 |
| Docker Swarm | 暗号化転送・メモリ上のみ | ノードローカル |
| 用途 | パスワード・トークン等 | データ永続化 |

---

## SOPS secrets との使い分け

| | Docker native secrets | SOPS + sidecar |
|-|-----------------------|----------------|
| ファイル管理 | 平文ファイル (git 非管理) | 暗号化ファイル (git 管理 OK) |
| 鍵管理 | 不要 | age / KMS 等 |
| チーム共有 | ファイルを別途共有 | 暗号化ファイルをリポジトリで共有 |
| 向いている用途 | ローカル / CI の静的シークレット | チーム開発・複数環境 |

このプロジェクトでは両方を使って学習できる:
- `app_key.txt` → Docker native secrets
- `DB_PASSWORD` → SOPS サイドカー ([Lab 6](lab-06-sops.md) 参照)
