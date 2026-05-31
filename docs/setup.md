# セットアップ

## 前提条件

```bash
docker --version        # Docker version 29.1.4-rd, build 3c6914
docker compose version  # Docker Compose version v5.0.1
task --version          # 3.51.1
age --version           # v1.3.1
sops --version          # sops 3.13.1 (latest)
jq --version            # jq-1.6-159-apple-gcff5336-dirty
```

インストール (macOS):

```bash
brew install go-task age sops jq
```

---

## 手順

### 1. age キーペアと app_key を生成

```bash
task secrets:init
```

出力例:

```
=== Dev public key (paste into .sops.yaml) ===
# public key: age1abc123...

=== Prod public key (paste into .sops.yaml) ===
# public key: age1xyz789...

app_key.txt を生成しました
```

生成されるファイル (いずれも `.gitignore` 済み):

```
secrets/dev/key.txt      # age 秘密鍵 (dev)
secrets/prod/key.txt     # age 秘密鍵 (prod)
secrets/app_key.txt      # Docker native secrets 用ランダムキー
```

### 2. `.sops.yaml` に公開鍵を設定

```yaml
creation_rules:
  - path_regex: secrets/dev/secrets\.yaml$
    age: age1abc123...        # ← dev の公開鍵を貼り付け
  - path_regex: secrets/prod/secrets\.yaml$
    age: age1xyz789...        # ← prod の公開鍵を貼り付け
```

### 3. シークレットファイルを作成して暗号化

```bash
cp secrets/dev/secrets.yaml.example secrets/dev/secrets.yaml
```

`secrets/dev/secrets.yaml` を編集:

```yaml
DB_PASSWORD: 任意のパスワード
DB_ROOT_PASSWORD: 任意のrootパスワード
```

暗号化:

```bash
task secrets:encrypt
# → secrets/dev/secrets.enc.yaml を生成 (git 管理 OK)
```

### 4. 起動

```bash
task up
task ps    # 全サービスが healthy になるまで待つ (30〜60秒)
```

---

## ファイル管理の整理

| ファイル | git 管理 | 説明 |
|---------|---------|------|
| `secrets/*.enc.yaml` | ✅ OK | SOPS 暗号化済み |
| `secrets/*.yaml.example` | ✅ OK | 平文サンプル |
| `secrets/app_key.example.txt` | ✅ OK | サンプル |
| `secrets/dev/key.txt` | ❌ NG | age 秘密鍵 |
| `secrets/prod/key.txt` | ❌ NG | age 秘密鍵 |
| `secrets/dev/secrets.yaml` | ❌ NG | 平文シークレット |
| `secrets/app_key.txt` | ❌ NG | アプリキー |
