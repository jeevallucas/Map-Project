<?php

declare(strict_types=1);

use App\Application\Settings\Settings;
use App\Application\Settings\SettingsInterface;
use DI\ContainerBuilder;
use Monolog\Logger;
use Psr\Container\ContainerInterface;
use Illuminate\Database\Capsule\Manager as Capsule;

return function (ContainerBuilder $containerBuilder) {

    // Global Settings Object
    $containerBuilder->addDefinitions([
        SettingsInterface::class => function () {
            return new Settings([
                'displayErrorDetails' => true, // Should be set to false in production
                'logError' => false,
                'logErrorDetails' => false,
                'logger' => [
                    'name' => 'slim-app',
                    'path' => isset($_ENV['docker']) ? 'php://stdout' : __DIR__ . '/../logs/app.log',
                    'level' => Logger::DEBUG,
                ],
            ]);
        },

        'db' => [
            'host' => 'localhost',
            'dbname' => 'db_mapproject',
            'user' => 'root',
            'pass' => '',
        ],
    ]);

    // Database Connection
    $containerBuilder->addDefinitions([
        'dbConnection' => function (ContainerInterface $container) {
            $config = $container->get('db');

            $capsule = new Capsule;
            $capsule->addConnection([
                'driver' => 'mysql',
                'host' => $config['host'],
                'database' => $config['dbname'],
                'username' => $config['user'],
                'password' => $config['pass'],
                'charset' => 'utf8',
                'collation' => 'utf8_unicode_ci',
                'prefix' => '',
            ]);

            // Make this Capsule instance available globally via static methods
            $capsule->setAsGlobal();

            // Setup the Eloquent ORM
            $capsule->bootEloquent();

            return $capsule;
        },
    ]);
};
