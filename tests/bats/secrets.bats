load 'helpers/common'

@test "Docker native secret (app_key) がマウントされている" {
  run curl -s http://web/health
  assert_output --partial '"app_key":"configured"'
}

@test "SOPS 復号済み DB_PASSWORD で MySQL 接続が機能する" {
  # DB 接続が正常なら 200 が返る (誤ったパスワードなら 500 になる)
  run curl -s -o /dev/null -w "%{http_code}" http://web/todos
  assert_output "200"
}

@test "SOPS 復号済みシークレットで Valkey 接続が機能する" {
  run redis-cli -h cache ping
  assert_output "PONG"
}
