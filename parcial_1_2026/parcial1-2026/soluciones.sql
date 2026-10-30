USE creditos_cuotas;
/*
1 
Listar los préstamos que estén vigentes o en mora y cuyo capital solicitado esté entre 200.000
y 600.000, mostrando además quién los tomó.
Para cada préstamo devolver: el id del préstamo, el nombre completo del cliente en una sola
columna con el formato Apellido, Nombre, su provincia, el monto solicitado, el estado y la fecha
de otorgamiento.
Ordenar por monto descendente y, a igual monto, por apellido del cliente.
*/
USE creditos_cuotas;
SELECT p.id_prestamo, CONCAT(c.apellido, ", ", c.nombre) AS`Apellido, Nombre`, c.provincia, p.monto_solicitado, p.estado, p.fecha_otorgamiento  
FROM prestamos AS p
INNER JOIN clientes AS c ON c.id_cliente = p.id_cliente
ORDER BY p.monto_solicitado, c.apellido DESC;
--el AS`Apellido, Nombre` todo pegadito porque sino el linter tira error 
/*
2
Clientes con más de un préstamo.
Usando una CTE, armar un resumen por cliente con la cantidad de préstamos que tomó, el
capital total solicitado y la fecha de su último préstamo. Después, en la consulta principal, cruzar
ese resumen con clientes para mostrar el nombre completo y la provincia, quedándose
únicamente con los que tomaron más de un préstamo.
*/
USE creditos_cuotas;
WITH resumen AS (
    SELECT p.id_cliente, COUNT(p.id_prestamo) AS cant_prest, SUM(p.monto_solicitado),MAX(p.fecha_otorgamiento)
    FROM prestamos AS p
    GROUP BY p.id_cliente 
)
SELECT c.nombre, c.apellido, c.provincia
FROM resumen AS r, clientes AS c
WHERE r.id_cliente = c.id_cliente AND r.cant_prest > 1;
--capaz ni esta bien esto xd
-- otra forma era con un join pero supongo que no era la idea xd
--INNER JOIN clientes AS c ON c.id_cliente = r.id_cliente

/*
3a?
Libro de cobranzas.
El área de auditoría necesita un registro cronológico de todos los pagos que entran, para eso se
requiere crear una nueva tabla para tal fin y autocompletar esta información a medida que
ingresan los pagos. Resolver los siguientes puntos:
1. Crear la tabla log_cobranzas, con su propio identificador autoincremental y columnas
para el pago, el préstamo, la fecha, el monto, el medio de pago y el momento en que se
registró. Solo tienen que crearla como se detalla a continuación.
*/
USE creditos_cuotas;
DROP TABLE IF EXISTS log_cobranzas;
CREATE TABLE log_cobranzas(
    id_log INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pago INT UNSIGNED NOT NULL,
    id_prestamo INT UNSIGNED NOT NULL,
    fecha_pago DATE NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    medio_pago VARCHAR(30) NOT NULL,
    registrado_el DATETIME NOT NULL,
    PRIMARY KEY (id_log)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
--wtf xd
/*
3b?
Crear un trigger sobre pagos que, cada vez que se inserta un pago, agregue
automáticamente una fila a ese registro en la tabla log_cobranzas. Tener en cuenta el
id_prestamo no está en pagos: hay que buscarlo en cuotas a partir del id_cuota del
pago.
*/
USE creditos_cuotas;
CREATE TRIGGER updateLog_cobranzas
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
    INSERT INTO log_cobranzas(id_pago, id_prestamo, fecha_pago, monto_pagado, medio_pago, registrado_el)
        SELECT new.id_pago, cu.id_prestamo, new.fecha_pago, new.monto_pagado, new.medio_pago, NOW() 
        FROM  cuotas AS cu
        WHERE cu.id_cuota = new.id_cuota;
END;
--gracias mysql por fucionar con solo 1 extension a la vez y por marcar toda la funcion cuando tiene un problema de ; adentro de la linea 76!!!
--si estas leyendo esto sos put@ (no se ofendan plz, es solo una bromita para seguir corrigiendo parciales con animos!)