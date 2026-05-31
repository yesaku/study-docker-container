<?php

declare(strict_types=1);

function cache(): Redis
{
    static $client = null;

    if ($client !== null) {
        return $client;
    }

    $client = new Redis();
    $client->connect(
        getenv('CACHE_HOST') ?: 'cache',
        (int) (getenv('CACHE_PORT') ?: 6379),
    );

    return $client;
}
