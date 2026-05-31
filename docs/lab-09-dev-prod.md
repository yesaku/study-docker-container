# Lab 9 — dev / prod 切り替え

**学ぶこと**: 同じ Taskfile で `ENV=dev|prod` を切り替えたときの差異を体感する

---

## dev と prod の差分

| 項目 | dev | prod |
|------|-----|------|
| PHP ソースマウント | bind mount (ホットリロード) | イメージに bake |
| DB ポート公開 | `3306:3306` | 非公開 |
| Cache ポート公開 | `6379:6379` | 非公開 |
| `APP_ENV` | `development` | `production` |
| `PHP_DISPLAY_ERRORS` | `1` | `0` |
| `restart` ポリシー | なし | `unless-stopped` |
| CPU / Memory 制限 | なし | あり |

---

## 9-a. prod 用シークレットを準備する

```bash
cp secrets/prod/secrets.yaml.example secrets/prod/secrets.yaml
# パスワードを編集
task secrets:encrypt ENV=prod
```

---

## 9-b. prod で起動する

```bash
task down                  # dev を停止
task up ENV=prod
task ps ENV=prod
```

---

## 9-c. ポートの差異を確認する

```bash
# dev: 3306 / 6379 がホストに公開されている
task up
docker compose ps
# php-todo-db-1    0.0.0.0:3306->3306/tcp
# php-todo-cache-1 0.0.0.0:6379->6379/tcp

# prod: ポートが公開されていない
task down
task up ENV=prod
docker compose -f compose.yaml -f compose.prod.yaml ps
# php-todo-db-1    (ポートなし)
# php-todo-cache-1 (ポートなし)
```

---

## 9-d. リソース制限を確認する

```bash
docker inspect php-todo-app-1 \
  | jq '.[0].HostConfig | {Memory, NanoCpus}'
```

dev の出力:

```json
{ "Memory": 0, "NanoCpus": 0 }    ← 制限なし
```

prod の出力:

```json
{ "Memory": 268435456, "NanoCpus": 1000000000 }
# Memory: 256 MB, CPU: 1.0 core
```

---

## 9-e. ホットリロードの有無を確認する

```bash
# dev: bind mount があるのでコード変更が即反映
task down
task up

# app/src/index.php の health() に追加
#   'reload_test' => 'works',

task api:health
# → {"status":"ok","app_key":"configured","reload_test":"works"}  ← 即反映

# prod: bind mount がないので反映されない
task down
task up ENV=prod
task api:health
# → {"status":"ok","app_key":"configured"}  ← reload_test がない

# prod で反映するには再ビルドが必要
task build ENV=prod
task up ENV=prod
task api:health
# → {"status":"ok","app_key":"configured","reload_test":"works"}
```

変更後は `app/src/index.php` を元に戻しておく。

---

## compose.dev.yaml / compose.prod.yaml の仕組み

```bash
# task up ENV=prod が展開するコマンド
docker compose -f compose.yaml -f compose.prod.yaml up -d
#              ^^^^^^^^^^^^^^       ^^^^^^^^^^^^^^^^^
#              ベース設定           prod 上書き (restart / resources 等)
```

`compose.prod.yaml` の設定が `compose.yaml` の設定を上書き・追加する。  
共通の設定は `compose.yaml` に書き、環境差分だけをオーバーライドファイルに書く。
