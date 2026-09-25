USE airbnb_like_db;

-- 1. Obtener los usuarios que han gastado más en reservas.
WITH gastos_por_usuario AS (
    SELECT
        b.user_id,
        SUM(b.total_price) AS total_gastado
    FROM bookings AS b
    WHERE b.status IN ('confirmed', 'paid')
    GROUP BY b.user_id
)
SELECT
    u.name,
    gu.total_gastado
FROM gastos_por_usuario AS gu
INNER JOIN users AS u ON u.id = gu.user_id
ORDER BY gu.total_gastado DESC, u.id;

-- 2. Obtener las 10 propiedades con el mayor ingreso total por reservas.
WITH ingresos_por_propiedad AS (
    SELECT
        b.property_id,
        SUM(b.total_price) AS ingreso_total
    FROM bookings AS b
    WHERE b.status IN ('confirmed', 'paid')
    GROUP BY b.property_id
)
SELECT
    p.name,
    ip.ingreso_total
FROM ingresos_por_propiedad AS ip
INNER JOIN properties AS p ON p.id = ip.property_id
ORDER BY ip.ingreso_total DESC, p.id
LIMIT 10;

-- 3. Crear un trigger que envíe un mensaje al dueño de la propiedad al recibir una reseña con puntuación menor o igual a 2.
DELIMITER $$

CREATE TRIGGER avisar_resena_negativa
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    IF NEW.rating <= 2 THEN
        INSERT INTO messages (sender_id, receiver_id, property_id, content)
        SELECT
            NEW.user_id,
            p.owner_id,
            NEW.property_id,
            CONCAT('Se recibió una reseña negativa (puntuación: ', NEW.rating, ').')
        FROM properties AS p
        WHERE p.id = NEW.property_id;
    END IF;
END$$

-- 4. Crear el procedimiento process_payment que registre el pago y marque como paid una reserva existente en estado confirmed.
CREATE PROCEDURE process_payment(
    IN input_booking_id INT,
    IN input_user_id INT,
    IN input_amount DECIMAL(10, 2),
    IN input_payment_method VARCHAR(50)
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM bookings AS b
        WHERE b.id = input_booking_id
          AND b.status = 'confirmed'
    ) THEN
        INSERT INTO payments (booking_id, user_id, amount, payment_method)
        VALUES (input_booking_id, input_user_id, input_amount, input_payment_method);

        UPDATE bookings
        SET status = 'paid'
        WHERE id = input_booking_id;
    END IF;
END$$

DELIMITER ;
