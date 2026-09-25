USE olympics;

-- 1. Crear person.total_medals con valor inicial 0.
ALTER TABLE person
ADD COLUMN total_medals INT NOT NULL DEFAULT 0;

-- 2. Actualizar person.total_medals con la cantidad real de medallas ganadas por cada persona.
UPDATE person AS p
LEFT JOIN (
    SELECT
        gc.person_id,
        COUNT(*) AS cantidad_medallas
    FROM games_competitor AS gc
    INNER JOIN competitor_event AS ce ON ce.competitor_id = gc.id
    INNER JOIN medal AS m ON m.id = ce.medal_id
    WHERE m.medal_name IN ('Gold', 'Silver', 'Bronze')
    GROUP BY gc.person_id
) AS mp ON mp.person_id = p.id
SET p.total_medals = COALESCE(mp.cantidad_medallas, 0);

-- 3. Devolver los medallistas olímpicos de Argentina con la cantidad obtenida de cada tipo de medalla.
SELECT
    p.full_name AS deportista,
    m.medal_name AS medalla,
    COUNT(*) AS cantidad
FROM (
    SELECT DISTINCT pr.person_id
    FROM person_region AS pr
    INNER JOIN noc_region AS nr ON nr.id = pr.region_id
    WHERE nr.region_name = 'Argentina'
) AS a
INNER JOIN person AS p ON p.id = a.person_id
INNER JOIN games_competitor AS gc ON gc.person_id = p.id
INNER JOIN competitor_event AS ce ON ce.competitor_id = gc.id
INNER JOIN medal AS m ON m.id = ce.medal_id
WHERE m.medal_name IN ('Gold', 'Silver', 'Bronze')
GROUP BY p.id, p.full_name, m.id, m.medal_name
ORDER BY p.full_name, m.id;

-- 4. Listar el total de medallas ganadas por deportistas argentinos en cada deporte.
SELECT
    s.sport_name AS deporte,
    COUNT(*) AS total_medallas
FROM (
    SELECT DISTINCT pr.person_id
    FROM person_region AS pr
    INNER JOIN noc_region AS nr ON nr.id = pr.region_id
    WHERE nr.region_name = 'Argentina'
) AS a
INNER JOIN games_competitor AS gc ON gc.person_id = a.person_id
INNER JOIN competitor_event AS ce ON ce.competitor_id = gc.id
INNER JOIN medal AS m ON m.id = ce.medal_id
INNER JOIN `event` AS e ON e.id = ce.event_id
INNER JOIN sport AS s ON s.id = e.sport_id
WHERE m.medal_name IN ('Gold', 'Silver', 'Bronze')
GROUP BY s.id, s.sport_name
ORDER BY total_medallas DESC, s.sport_name;

-- 5. Listar la cantidad total de medallas de oro, plata y bronce ganadas por cada país.
SELECT
    nr.region_name AS pais,
    COALESCE(mp.oro, 0) AS oro,
    COALESCE(mp.plata, 0) AS plata,
    COALESCE(mp.bronce, 0) AS bronce
FROM noc_region AS nr
LEFT JOIN (
    SELECT
        pr.region_id,
        SUM(CASE WHEN m.medal_name = 'Gold' THEN 1 ELSE 0 END) AS oro,
        SUM(CASE WHEN m.medal_name = 'Silver' THEN 1 ELSE 0 END) AS plata,
        SUM(CASE WHEN m.medal_name = 'Bronze' THEN 1 ELSE 0 END) AS bronce
    FROM person_region AS pr
    INNER JOIN games_competitor AS gc ON gc.person_id = pr.person_id
    INNER JOIN competitor_event AS ce ON ce.competitor_id = gc.id
    INNER JOIN medal AS m ON m.id = ce.medal_id
    WHERE m.medal_name IN ('Gold', 'Silver', 'Bronze')
    GROUP BY pr.region_id
) AS mp ON mp.region_id = nr.id
ORDER BY nr.region_name;

-- 6. Listar el país con más y el país con menos medallas ganadas en la historia olímpica.
SELECT
    pais,
    total_medallas
FROM (
    SELECT
        nr.region_name AS pais,
        COALESCE(mp.total_medallas, 0) AS total_medallas,
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(mp.total_medallas, 0) DESC, nr.region_name
        ) AS mayor,
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(mp.total_medallas, 0) ASC, nr.region_name
        ) AS menor
    FROM noc_region AS nr
    LEFT JOIN (
        SELECT
            pr.region_id,
            COUNT(*) AS total_medallas
        FROM person_region AS pr
        INNER JOIN games_competitor AS gc ON gc.person_id = pr.person_id
        INNER JOIN competitor_event AS ce ON ce.competitor_id = gc.id
        INNER JOIN medal AS m ON m.id = ce.medal_id
        WHERE m.medal_name IN ('Gold', 'Silver', 'Bronze')
        GROUP BY pr.region_id
    ) AS mp ON mp.region_id = nr.id
) AS extremos
WHERE mayor = 1 OR menor = 1
ORDER BY total_medallas DESC;

-- 7. Crear los triggers increase_number_of_medals y decrease_number_of_medals para mantener person.total_medals.
DELIMITER $$

CREATE TRIGGER increase_number_of_medals
AFTER INSERT ON competitor_event
FOR EACH ROW
BEGIN
    IF NEW.medal_id IN (1, 2, 3) THEN
        UPDATE person AS p
        INNER JOIN games_competitor AS gc ON gc.person_id = p.id
        SET p.total_medals = p.total_medals + 1
        WHERE gc.id = NEW.competitor_id;
    END IF;
END$$

CREATE TRIGGER decrease_number_of_medals
AFTER DELETE ON competitor_event
FOR EACH ROW
BEGIN
    IF OLD.medal_id IN (1, 2, 3) THEN
        UPDATE person AS p
        INNER JOIN games_competitor AS gc ON gc.person_id = p.id
        SET p.total_medals = p.total_medals - 1
        WHERE gc.id = OLD.competitor_id;
    END IF;
END$$

-- 8. Crear add_new_medalists para insertar las medallas de oro, plata y bronce de tres competidores en un evento.
CREATE PROCEDURE add_new_medalists(
    IN input_event_id INT,
    IN g_id INT,
    IN s_id INT,
    IN b_id INT
)
BEGIN
    INSERT INTO competitor_event (event_id, competitor_id, medal_id)
    VALUES
        (input_event_id, g_id, 1),
        (input_event_id, s_id, 2),
        (input_event_id, b_id, 3);
END$$

DELIMITER ;

-- 9. Crear el rol organizer con permiso para eliminar filas de games y actualizar solamente games.games_name.
CREATE ROLE 'organizer';
GRANT DELETE ON olympics.games TO 'organizer';
GRANT UPDATE (games_name) ON olympics.games TO 'organizer';
