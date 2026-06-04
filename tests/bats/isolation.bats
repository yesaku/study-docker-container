load 'helpers/common'

# このテストは frontend ネットワークのみのコンテナから実行される

@test "frontend から web に到達できる" {
  run curl -s -o /dev/null -w "%{http_code}" http://web/health
  assert_output "200"
}

@test "frontend から db に到達できない (backend 分離)" {
  run sh -c "nc -zv db 3306 2>&1"
  assert_failure
}

@test "frontend から cache に到達できない (backend 分離)" {
  run sh -c "nc -zv cache 6379 2>&1"
  assert_failure
}
