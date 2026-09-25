USE northwind;

-- 1. Listar los 10 productos más vendidos (por cantidad total).
WITH ventas_por_producto AS (
    SELECT
        od.ProductID,
        SUM(od.Quantity) AS cantidad_total
    FROM `Order Details` AS od
    GROUP BY od.ProductID
)
SELECT
    p.ProductName,
    v.cantidad_total
FROM ventas_por_producto AS v
INNER JOIN Products AS p ON p.ProductID = v.ProductID
ORDER BY v.cantidad_total DESC, p.ProductID
LIMIT 10;

-- 2. Listar los empleados junto a la cantidad total de órdenes que gestionaron (ordenado).
WITH ordenes_por_empleado AS (
    SELECT
        o.EmployeeID,
        COUNT(*) AS cantidad_ordenes
    FROM Orders AS o
    GROUP BY o.EmployeeID
)
SELECT
    e.FirstName,
    e.LastName,
    COALESCE(oe.cantidad_ordenes, 0) AS cantidad_ordenes
FROM Employees AS e
LEFT JOIN ordenes_por_empleado AS oe ON oe.EmployeeID = e.EmployeeID
ORDER BY cantidad_ordenes DESC, e.EmployeeID;

-- 3. Monto total facturado por cada cliente.
WITH facturacion_por_cliente AS (
    SELECT
        o.CustomerID,
        CAST(
            ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2)
            AS DECIMAL(15, 2)
        ) AS monto_total
    FROM Orders AS o
    INNER JOIN `Order Details` AS od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
)
SELECT
    c.CompanyName,
    COALESCE(fc.monto_total, 0) AS monto_total
FROM Customers AS c
LEFT JOIN facturacion_por_cliente AS fc ON fc.CustomerID = c.CustomerID
ORDER BY c.CustomerID;

-- 4. Crear un trigger que registre automáticamente el país en Orders (ShipCountry) según el cliente antes de insertar la orden.
DELIMITER $$

CREATE TRIGGER copiar_pais_cliente
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    SET NEW.ShipCountry = (
        SELECT c.Country
        FROM Customers AS c
        WHERE c.CustomerID = NEW.CustomerID
    );
END$$

DELIMITER ;

-- 5. Crear un rol llamado analyst con SELECT en todas las tablas y permiso para crear vistas.
CREATE ROLE 'analyst';
GRANT SELECT ON northwind.* TO 'analyst';
GRANT CREATE VIEW ON northwind.* TO 'analyst';
