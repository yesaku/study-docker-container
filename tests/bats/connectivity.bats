load 'helpers/common'

@test "GET /health が 200 を返す" {
  run curl -s -o /dev/null -w "%{http_code}" http://web/health
  assert_output "200"
}

@test "GET /health のレスポンスに status:ok が含まれる" {
  run curl -s http://web/health
  assert_output --partial '"status":"ok"'
}

@test "nginx のバージョンがレスポンスヘッダーに露出していない" {
  run sh -c "curl -sI http://web/health | grep -i '^server:' | tr -d '\r'"
  assert_output "Server: nginx"
  refute_output --partial "nginx/1."
}

@test "db (MySQL) がポート 3306 で待ち受けている" {
  run nc -zv db 3306
  assert_success
}

@test "cache (Valkey) がポート 6379 で待ち受けている" {
  run nc -zv cache 6379
  assert_success
}

@test "cache に PING が通る" {
  run redis-cli -h cache ping
  assert_output "PONG"
}
