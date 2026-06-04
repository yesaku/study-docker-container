load 'helpers/common'

setup() {
  redis-cli -h cache FLUSHALL > /dev/null
}

@test "POST /todos → 201 + to-do body" {
  run curl -s -w "\n%{http_code}" -X POST http://web/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"bats test"}'
  assert_output --partial "201"
  assert_output --partial '"title":"bats test"'
  assert_output --partial '"done":false'
}

@test "title なし POST → 400" {
  run curl -s -o /dev/null -w "%{http_code}" -X POST http://web/todos \
    -H "Content-Type: application/json" \
    -d '{}'
  assert_output "400"
}

@test "GET /todos → 200 + 配列" {
  run sh -c "curl -s http://web/todos | jq -e 'type == \"array\"'"
  assert_success
}

@test "DELETE /todos/:id → 204" {
  id=$(curl -s -X POST http://web/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"delete-me"}' | jq -r '.id')
  run curl -s -o /dev/null -w "%{http_code}" -X DELETE "http://web/todos/${id}"
  assert_output "204"
}

@test "存在しない ID の DELETE → 404" {
  run curl -s -o /dev/null -w "%{http_code}" -X DELETE http://web/todos/99999
  assert_output "404"
}

@test "GET 後に Valkey キャッシュが作成される" {
  curl -s http://web/todos > /dev/null
  run redis-cli -h cache EXISTS todos
  assert_output "1"
}

@test "POST 後に Valkey キャッシュが削除される" {
  curl -s http://web/todos > /dev/null
  curl -s -X POST http://web/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"invalidate"}' > /dev/null
  run redis-cli -h cache EXISTS todos
  assert_output "0"
}
