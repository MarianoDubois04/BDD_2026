USE northwind;

-- 1. Listar los 5 clientes que más ingresos han generado a lo largo del tiempo.
WITH ingresos_por_cliente AS (
    SELECT
        o.CustomerID,
        CAST(
            ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2)
            AS DECIMAL(15, 2)
        ) AS ingresos_totales
    FROM Orders AS o
    INNER JOIN `Order Details` AS od ON od.OrderID = o.OrderID
    GROUP BY o.CustomerID
)
SELECT
    c.CompanyName,
    ic.ingresos_totales
FROM ingresos_por_cliente AS ic
INNER JOIN Customers AS c ON c.CustomerID = ic.CustomerID
ORDER BY ic.ingresos_totales DESC, c.CustomerID
LIMIT 5;

-- 2. Listar cada producto con sus ventas totales, agrupados por categoría.
WITH ventas_por_producto AS (
    SELECT
        od.ProductID,
        CAST(
            ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2)
            AS DECIMAL(15, 2)
        ) AS ventas_totales
    FROM `Order Details` AS od
    GROUP BY od.ProductID
)
SELECT
    c.CategoryName,
    p.ProductName,
    COALESCE(vp.ventas_totales, 0) AS ventas_totales
FROM Categories AS c
INNER JOIN Products AS p ON p.CategoryID = c.CategoryID
LEFT JOIN ventas_por_producto AS vp ON vp.ProductID = p.ProductID
ORDER BY c.CategoryName, p.ProductName;

-- 3. Calcular el total de ventas para cada categoría.
WITH ventas_por_categoria AS (
    SELECT
        p.CategoryID,
        CAST(
            ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2)
            AS DECIMAL(15, 2)
        ) AS ventas_totales
    FROM Products AS p
    INNER JOIN `Order Details` AS od ON od.ProductID = p.ProductID
    GROUP BY p.CategoryID
)
SELECT
    c.CategoryName,
    COALESCE(vc.ventas_totales, 0) AS ventas_totales
FROM Categories AS c
LEFT JOIN ventas_por_categoria AS vc ON vc.CategoryID = c.CategoryID
ORDER BY c.CategoryName;

-- 4. Crear una vista que liste los empleados con más ventas por cada año, mostrando empleado, año y total de ventas, ordenados por año ascendente.
CREATE VIEW empleados_mas_ventas_por_anio AS
WITH ventas_por_empleado_anio AS (
    SELECT
        o.EmployeeID,
        YEAR(o.OrderDate) AS anio,
        CAST(
            ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2)
            AS DECIMAL(15, 2)
        ) AS ventas_totales
    FROM Orders AS o
    INNER JOIN `Order Details` AS od ON od.OrderID = o.OrderID
    WHERE o.OrderDate IS NOT NULL
    GROUP BY o.EmployeeID, YEAR(o.OrderDate)
),
empleados_ordenados AS (
    SELECT
        vea.EmployeeID,
        vea.anio,
        vea.ventas_totales,
        RANK() OVER (
            PARTITION BY vea.anio
            ORDER BY vea.ventas_totales DESC
        ) AS posicion
    FROM ventas_por_empleado_anio AS vea
)
SELECT
    CONCAT(e.FirstName, ' ', e.LastName) AS empleado,
    eo.anio,
    eo.ventas_totales
FROM empleados_ordenados AS eo
INNER JOIN Employees AS e ON e.EmployeeID = eo.EmployeeID
WHERE eo.posicion = 1
ORDER BY eo.anio ASC, e.EmployeeID;

-- 5. Crear un trigger que disminuya el stock de Products después de insertar un detalle en Order Details.
DELIMITER $$

CREATE TRIGGER descontar_stock_por_detalle
AFTER INSERT ON `Order Details`
FOR EACH ROW
BEGIN
    UPDATE Products
    SET UnitsInStock = UnitsInStock - NEW.Quantity
    WHERE ProductID = NEW.ProductID;
END$$

DELIMITER ;

-- 6. Crear un rol llamado admin con permiso para insertar clientes y actualizar solamente su columna Phone.
CREATE ROLE 'admin';
GRANT INSERT ON northwind.Customers TO 'admin';
GRANT UPDATE (Phone) ON northwind.Customers TO 'admin';
