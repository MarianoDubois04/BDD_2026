USE olympics;

-- 1. Listar todas las ciudades sede de los Juegos Olímpicos de verano junto con su año, de más reciente a menos reciente.
WITH sedes_de_verano AS (
    SELECT DISTINCT
        c.city_name AS ciudad,
        g.games_year AS anio
    FROM games AS g
    INNER JOIN games_city AS gc ON gc.games_id = g.id
    INNER JOIN city AS c ON c.id = gc.city_id
    WHERE g.season = 'Summer'
)
SELECT
    ciudad,
    anio
FROM sedes_de_verano
ORDER BY anio DESC, ciudad;

-- 2. Obtener el ranking de los 10 países con más medallas de oro en fútbol.
WITH oros_en_futbol AS (
    SELECT
        pr.region_id,
        COUNT(*) AS medallas_de_oro
    FROM competitor_event AS ce
    INNER JOIN medal AS m ON m.id = ce.medal_id
    INNER JOIN `event` AS e ON e.id = ce.event_id
    INNER JOIN sport AS s ON s.id = e.sport_id
    INNER JOIN games_competitor AS gc ON gc.id = ce.competitor_id
    INNER JOIN person_region AS pr ON pr.person_id = gc.person_id
    WHERE s.sport_name = 'Football'
      AND m.medal_name = 'Gold'
    GROUP BY pr.region_id
)
SELECT
    nr.region_name AS pais,
    ofu.medallas_de_oro
FROM oros_en_futbol AS ofu
INNER JOIN noc_region AS nr ON nr.id = ofu.region_id
ORDER BY ofu.medallas_de_oro DESC, nr.region_name
LIMIT 10;

-- 3. Listar con la misma consulta el país con más participaciones y el país con menos participaciones en los Juegos Olímpicos.
WITH participaciones_por_pais AS (
    SELECT
        pr.region_id,
        COUNT(DISTINCT gc.id) AS participaciones
    FROM person_region AS pr
    INNER JOIN games_competitor AS gc ON gc.person_id = pr.person_id
    GROUP BY pr.region_id
),
extremos AS (
    SELECT
        pp.region_id,
        pp.participaciones,
        ROW_NUMBER() OVER (
            ORDER BY pp.participaciones DESC, pp.region_id
        ) AS mayor,
        ROW_NUMBER() OVER (
            ORDER BY pp.participaciones ASC, pp.region_id
        ) AS menor
    FROM participaciones_por_pais AS pp
)
SELECT
    nr.region_name AS pais,
    ex.participaciones
FROM extremos AS ex
INNER JOIN noc_region AS nr ON nr.id = ex.region_id
WHERE ex.mayor = 1 OR ex.menor = 1
ORDER BY ex.participaciones DESC;

-- 4. Crear una vista con país, deporte, medallas de oro, plata y bronce, y participaciones sin medallas.
CREATE VIEW medallas_por_pais_deporte AS
WITH resultados AS (
    SELECT
        pr.region_id,
        e.sport_id,
        SUM(CASE WHEN m.medal_name = 'Gold' THEN 1 ELSE 0 END) AS oro,
        SUM(CASE WHEN m.medal_name = 'Silver' THEN 1 ELSE 0 END) AS plata,
        SUM(CASE WHEN m.medal_name = 'Bronze' THEN 1 ELSE 0 END) AS bronce,
        SUM(CASE WHEN m.medal_name = 'NA' OR m.id IS NULL THEN 1 ELSE 0 END) AS sin_medalla
    FROM competitor_event AS ce
    INNER JOIN games_competitor AS gc ON gc.id = ce.competitor_id
    INNER JOIN person_region AS pr ON pr.person_id = gc.person_id
    INNER JOIN `event` AS e ON e.id = ce.event_id
    LEFT JOIN medal AS m ON m.id = ce.medal_id
    GROUP BY pr.region_id, e.sport_id
)
SELECT
    nr.region_name AS pais,
    s.sport_name AS deporte,
    r.oro,
    r.plata,
    r.bronce,
    r.sin_medalla
FROM resultados AS r
INNER JOIN noc_region AS nr ON nr.id = r.region_id
INNER JOIN sport AS s ON s.id = r.sport_id;

-- 5. Crear un procedimiento que reciba un país y devuelva sus cantidades totales de medallas de oro, plata y bronce.
DELIMITER $$

CREATE PROCEDURE medallas_de_pais(IN input_pais VARCHAR(200))
BEGIN
    SELECT
        COALESCE(SUM(v.oro), 0) AS oro,
        COALESCE(SUM(v.plata), 0) AS plata,
        COALESCE(SUM(v.bronce), 0) AS bronce
    FROM medallas_por_pais_deporte AS v
    WHERE v.pais = input_pais;
END$$

DELIMITER ;

-- 6. Agregar y completar event.sport_name, eliminar event.sport_id y eliminar la tabla sport.
ALTER TABLE `event`
ADD COLUMN sport_name VARCHAR(200);

UPDATE `event` AS e
INNER JOIN sport AS s ON s.id = e.sport_id
SET e.sport_name = s.sport_name;

ALTER TABLE `event`
DROP FOREIGN KEY fk_ev_sp;

ALTER TABLE `event`
DROP COLUMN sport_id;

DROP TABLE sport;

CREATE OR REPLACE VIEW medallas_por_pais_deporte AS
SELECT
    nr.region_name AS pais,
    e.sport_name AS deporte,
    SUM(CASE WHEN m.medal_name = 'Gold' THEN 1 ELSE 0 END) AS oro,
    SUM(CASE WHEN m.medal_name = 'Silver' THEN 1 ELSE 0 END) AS plata,
    SUM(CASE WHEN m.medal_name = 'Bronze' THEN 1 ELSE 0 END) AS bronce,
    SUM(CASE WHEN m.medal_name = 'NA' OR m.id IS NULL THEN 1 ELSE 0 END) AS sin_medalla
FROM competitor_event AS ce
INNER JOIN games_competitor AS gc ON gc.id = ce.competitor_id
INNER JOIN person_region AS pr ON pr.person_id = gc.person_id
INNER JOIN noc_region AS nr ON nr.id = pr.region_id
INNER JOIN `event` AS e ON e.id = ce.event_id
LEFT JOIN medal AS m ON m.id = ce.medal_id
GROUP BY nr.id, nr.region_name, e.sport_name;
