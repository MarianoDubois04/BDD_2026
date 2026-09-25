USE airbnb_like_db;

-- 1. Listar las 7 propiedades con la mayor cantidad de reviews en el año 2024.
WITH reviews_por_propiedad AS (
    SELECT
        r.property_id,
        COUNT(*) AS cantidad_reviews
    FROM reviews AS r
    WHERE r.created_at >= '2024-01-01'
      AND r.created_at < '2025-01-01'
    GROUP BY r.property_id
)
SELECT
    p.name,
    rp.cantidad_reviews
FROM reviews_por_propiedad AS rp
INNER JOIN properties AS p ON p.id = rp.property_id
ORDER BY rp.cantidad_reviews DESC, p.id
LIMIT 7;

-- 2. Obtener los ingresos por reservas de cada propiedad usando noches reservadas por precio por noche.
WITH ingresos_por_propiedad AS (
    SELECT
        b.property_id,
        SUM(DATEDIFF(b.check_out, b.check_in) * p.price_per_night) AS ingresos_totales
    FROM bookings AS b
    INNER JOIN properties AS p ON p.id = b.property_id
    WHERE b.status IN ('confirmed', 'paid')
    GROUP BY b.property_id
)
SELECT
    p.name,
    COALESCE(ip.ingresos_totales, 0) AS ingresos_totales
FROM properties AS p
LEFT JOIN ingresos_por_propiedad AS ip ON ip.property_id = p.id
ORDER BY p.id;

-- 3. Listar los 10 principales usuarios según la suma de los pagos realizados.
WITH pagos_por_usuario AS (
    SELECT
        p.user_id,
        SUM(p.amount) AS pagos_totales
    FROM payments AS p
    WHERE p.status = 'completed'
    GROUP BY p.user_id
)
SELECT
    u.name,
    pu.pagos_totales
FROM pagos_por_usuario AS pu
INNER JOIN users AS u ON u.id = pu.user_id
ORDER BY pu.pagos_totales DESC, u.id
LIMIT 10;

-- 4. Crear el trigger notify_host_after_booking para avisar al anfitrión después de insertar una reserva.
DELIMITER $$

CREATE TRIGGER notify_host_after_booking
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO messages (sender_id, receiver_id, property_id, content)
    SELECT
        NEW.user_id,
        p.owner_id,
        NEW.property_id,
        CONCAT('Nueva reserva #', NEW.id, ' para tu propiedad.')
    FROM properties AS p
    WHERE p.id = NEW.property_id;
END$$

-- 5. Crear el procedimiento add_new_booking que inserte una reserva si la propiedad está disponible en las fechas solicitadas.
CREATE PROCEDURE add_new_booking(
    IN input_property_id INT,
    IN input_user_id INT,
    IN input_check_in DATE,
    IN input_check_out DATE
)
BEGIN
    IF input_check_in < input_check_out
       AND EXISTS (
           SELECT 1
           FROM property_availability AS a
           WHERE a.property_id = input_property_id
             AND a.status = 'available'
             AND a.available_from <= input_check_in
             AND a.available_to >= input_check_out
       )
       AND NOT EXISTS (
           SELECT 1
           FROM property_availability AS a
           WHERE a.property_id = input_property_id
             AND a.status = 'blocked'
             AND input_check_in < a.available_to
             AND input_check_out > a.available_from
       )
       AND NOT EXISTS (
           SELECT 1
           FROM bookings AS b
           WHERE b.property_id = input_property_id
             AND b.status IN ('pending', 'confirmed', 'paid')
             AND input_check_in < b.check_out
             AND input_check_out > b.check_in
       ) THEN
        INSERT INTO bookings (property_id, user_id, check_in, check_out, total_price)
        SELECT
            p.id,
            input_user_id,
            input_check_in,
            input_check_out,
            DATEDIFF(input_check_out, input_check_in) * p.price_per_night
        FROM properties AS p
        WHERE p.id = input_property_id;
    END IF;
END$$

DELIMITER ;

-- 6. Crear el rol admin con permiso para insertar propiedades y actualizar solo property_availability.status.
CREATE ROLE 'admin';
GRANT INSERT ON airbnb_like_db.properties TO 'admin';
GRANT UPDATE (status) ON airbnb_like_db.property_availability TO 'admin';

-- 7. Explicar por qué modificar comentarios existentes y confirmar la transacción no contradice la durabilidad de ACID.
-- Durabilidad significa que un cambio confirmado con COMMIT persiste incluso
-- si ocurre un fallo posterior. No significa que una fila confirmada sea
-- inmutable: otra transacción puede modificarla y confirmar un nuevo valor.
