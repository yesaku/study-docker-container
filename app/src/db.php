<?php

declare(strict_types=1);

function db(): PDO
{
    static $pdo = null;

    if ($pdo !== null) {
        return $pdo;
    }

    // SOPS sidecar が tmpfs volume に書き込んだファイルから読む
    $password = trim(file_get_contents('/run/decrypted/DB_PASSWORD'));

    $dsn = sprintf(
        'mysql:host=%s;dbname=%s;charset=utf8mb4',
        getenv('DB_HOST') ?: 'db',
        getenv('DB_NAME') ?: 'app_db',
    );

    $pdo = new PDO($dsn, getenv('DB_USER') ?: 'app', $password, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);

    return $pdo;
}
