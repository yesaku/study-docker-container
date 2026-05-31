<?php

declare(strict_types=1);

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/cache.php';

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'];
$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

preg_match('#^/todos(?:/(\d+))?$#', $uri, $m);
$id = isset($m[1]) ? (int) $m[1] : null;

match (true) {
    $method === 'GET'    && $uri === '/health' => health(),
    $method === 'GET'    && $uri === '/todos'  => list_todos(),
    $method === 'POST'   && $uri === '/todos'  => create_todo(),
    $method === 'DELETE' && $id !== null       => delete_todo($id),
    default                                    => respond(404, ['error' => 'not found']),
};

function list_todos(): void
{
    $cache  = cache();
    $cached = $cache->get('todos');

    if ($cached !== false) {
        respond(200, json_decode($cached, true));
        return;
    }

    $rows = db()->query('SELECT id, title, done FROM todos ORDER BY id DESC')->fetchAll();
    $cache->setex('todos', 30, json_encode($rows));
    respond(200, $rows);
}

function create_todo(): void
{
    $body  = json_decode(file_get_contents('php://input'), true) ?? [];
    $title = trim((string) ($body['title'] ?? ''));

    if ($title === '') {
        respond(400, ['error' => 'title is required']);
        return;
    }

    $stmt = db()->prepare('INSERT INTO todos (title) VALUES (?)');
    $stmt->execute([$title]);

    cache()->del('todos');

    respond(201, ['id' => (int) db()->lastInsertId(), 'title' => $title, 'done' => false]);
}

function delete_todo(int $id): void
{
    $stmt = db()->prepare('DELETE FROM todos WHERE id = ?');
    $stmt->execute([$id]);

    if ($stmt->rowCount() === 0) {
        respond(404, ['error' => 'not found']);
        return;
    }

    cache()->del('todos');
    respond(204, null);
}

function health(): void
{
    respond(200, [
        'status'  => 'ok',
        // Docker native secrets の確認 (compose.yaml secrets: app_key)
        'app_key' => file_exists('/run/secrets/app_key') ? 'configured' : 'missing',
    ]);
}

function respond(int $code, mixed $body): void
{
    http_response_code($code);
    if ($body !== null) {
        echo json_encode($body);
    }
}
