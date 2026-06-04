# Lab 6 — SOPS init container

**学ぶこと**: init container パターンで暗号化シークレットをコンテナに安全に渡す

---

## フロー全体像

```
git リポジトリ
  secrets/dev/secrets.enc.yaml   ← 暗号化済み (git 管理 OK)
  secrets/dev/key.txt            ← age 秘密鍵 (.gitignore)

task up
  └─ docker compose up
       ├─ sops-init (init container として起動)
       │    ├─ secrets.enc.yaml を age 秘密鍵で復号
       │    ├─ KEY=VALUE → /run/output/KEY (decrypted volume)
       │    └─ exit 0
       │         ↓ service_completed_successfully
       ├─ db  MYSQL_PASSWORD_FILE=/run/decrypted/DB_PASSWORD
       └─ app file_get_contents('/run/decrypted/DB_PASSWORD')
```

---

## 6-a. 暗号化ファイルの中身を確認する

```bash
cat secrets/dev/secrets.enc.yaml
```

出力例:

```yaml
DB_PASSWORD: ENC[AES256_GCM,data:Xxxx==,iv:yyyy,tag:zzzz,type:str]
DB_ROOT_PASSWORD: ENC[AES256_GCM,data:Aaaa==,iv:bbbb,tag:cccc,type:str]
sops:
    age:
        - recipient: age1abc123...
          enc: |
              -----BEGIN AGE ENCRYPTED FILE-----
              ...
    lastmodified: "2026-05-01T00:00:00Z"
    version:  3.13.1
```

平文は一切含まれていない。このファイルは git にコミットしてよい。

---

## 6-b. ローカルで平文を確認する

```bash
task secrets:decrypt
# → DB_PASSWORD=your_password
# → DB_ROOT_PASSWORD=your_root_password
```

`secrets/dev/key.txt` (秘密鍵) がないと復号できない:

```bash
SOPS_AGE_KEY_FILE=/dev/null sops -d secrets/dev/secrets.enc.yaml
# → Error: no age identity found that can decrypt any of the recipients
```

---

## 6-c. コンテナ内の復号済みファイルを確認する

```bash
task inspect:secrets
# === SOPS decrypted: /run/decrypted/DB_PASSWORD ===
# your_password
```

`sops/entrypoint.sh` が `KEY=VALUE` を1行ずつ読み取り、  
キー名のファイルとして `decrypted` volume に書き出している:

```sh
while IFS= read -r line; do
    key="${line%%=*}"
    value="${line#*=}"
    printf '%s' "$value" > "/run/output/${key}"
done < /tmp/decrypted.env
```

---

## 6-d. dev / prod の鍵分離を確認する

```bash
# dev の秘密鍵で prod のシークレットを復号しようとする
SOPS_AGE_KEY_FILE=secrets/dev/key.txt sops -d secrets/prod/secrets.enc.yaml
# → Error: no age identity found that can decrypt any of the recipients
```

環境ごとに別の鍵ペアを使うことで、dev の開発者が prod のシークレットを読めない。  
本番では age の代わりに AWS KMS や GCP KMS に差し替えるだけで同じフローが使える。

---

## 6-e. シークレットを変更してみる

```bash
# 暗号化ファイルをエディタで直接編集 (復号 → 編集 → 再暗号化を自動でやってくれる)
task secrets:edit

# 再起動して変更を反映
task reset
task api:health
```

---

## sops-init の Dockerfile

```dockerfile
FROM alpine:3.21

ARG SOPS_VERSION=3.9.4

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64)  sops_arch="amd64" ;; \
        aarch64) sops_arch="arm64" ;; \
    esac; \
    apk add --no-cache wget; \
    wget -q ".../sops-v${SOPS_VERSION}.linux.${sops_arch}" -O /usr/local/bin/sops; \
    chmod +x /usr/local/bin/sops
```

`uname -m` でアーキテクチャを自動検出するため、  
Apple Silicon (arm64) でも Intel (amd64) でもそのまま動く。
