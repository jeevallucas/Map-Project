<?php

declare(strict_types=1);

use App\Application\Actions\User\ListUsersAction;
use App\Application\Actions\User\ViewUserAction;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\App;
use Slim\Interfaces\RouteCollectorProxyInterface as Group;

return function (App $app) {
    $container = $app->getContainer();

    //------------------------------------UAS progmob 2023 tentang MapProject------------------------------

    $app->get("/mapproject/{nim}/", function (Request $request, Response $response, $args) {
        $nim = $args["nim"];
        $sql = "SELECT * FROM `$nim`";
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        $result = $stmt->fetchAll();
        return $response->withJson(["status" => "success", "data" => $result], 200);
    });

    $app->post("/mapproject/{nim}/", function (Request $request, Response $response, $args) {
        $nim = $args["nim"];
        $mapProject = $request->getParsedBody();

        $nim = preg_replace("/[^a-zA-Z0-9_]+/", "", $nim);

        $sql = "INSERT INTO `$nim` (informasi, lat, longi) VALUES (:informasi, :lat, :longi)";
        $stmt = $this->db->prepare($sql);

        $data = [
            ":informasi" => $mapProject["informasi"],
            ":lat" => $mapProject["lat"],
            ":longi" => $mapProject["longi"],
        ];

        if ($stmt->execute($data)) {
            return $response->withJson(["status" => "success", "data" => "1"], 200);
        }

        return $response->withJson(["status" => "failed", "data" => "0"], 200);
    });
};