#!/bin/sh
set -e

# 暗号化ファイルを dotenv 形式で復号
sops --output-type dotenv -d /secrets/secrets.enc.yaml > /tmp/decrypted.env

# KEY=VALUE を1行ずつ読み取り、キー名のファイルとして書き出す
# (例: DB_PASSWORD=secret → /run/output/DB_PASSWORD に "secret" を書く)
while IFS= read -r line; do
    [ -z "$line" ] && continue
    key="${line%%=*}"
    value="${line#*=}"
    printf '%s' "$value" > "/run/output/${key}"
    chmod 600 "/run/output/${key}"
done < /tmp/decrypted.env

rm /tmp/decrypted.env
echo "[sops-init] secrets written to volume"
