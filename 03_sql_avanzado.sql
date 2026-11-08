-- =====================================================================
-- Bases de Datos 2 · Taller integrador — Banco Andino
-- 03_sql_avanzado.sql   SQL analítico, jerárquico y MERGE
--
-- Trabajen en UNA SOLA CONEXIÓN: la pareja comparte el esquema.
-- Cada bloque trae una consulta RESUELTA que sirve de modelo, y una
-- consulta que ustedes deben ESCRIBIR. Complete las que dicen ESCRIBA.
-- =====================================================================

SET LINESIZE 220
SET PAGESIZE 60
SET TIMING ON


-- #####################################################################
-- EJERCICIO 3.1 — Ranking dentro de grupos
--
-- La vicepresidencia comercial quiere los 3 productos que más saldo
-- captan dentro de cada FAMILIA de productos, solo cuentas activas.
-- #####################################################################

-- MODELO (resuelto)
WITH captacion AS (
  SELECT f.id_producto  AS id_familia,
         f.nombre       AS familia,
         p.id_producto,
         p.nombre       AS producto,
         SUM(c.saldo)   AS saldo_captado,
         COUNT(*)       AS cuentas
    FROM cuenta c
    JOIN catalogo_producto p ON p.id_producto = c.id_producto
    JOIN catalogo_producto f ON f.id_producto = p.id_padre
   WHERE c.estado = 'ACTIVA'
   GROUP BY f.id_producto, f.nombre, p.id_producto, p.nombre
)
SELECT familia, producto, cuentas, ROUND(saldo_captado) AS saldo_captado, puesto
  FROM (SELECT v.*,
               DENSE_RANK() OVER (PARTITION BY id_familia
                                  ORDER BY saldo_captado DESC) AS puesto
          FROM captacion v)
 WHERE puesto <= 3
 ORDER BY familia, puesto;

--
--  PREGUNTA 3.1 — Cambie DENSE_RANK por RANK y luego por ROW_NUMBER.
--  Explique en qué se diferencian los tres cuando hay empates, y cuál
--  usaría usted para un "top 3" que debe devolver exactamente 3 filas.
--
--  ESCRIBA 3.1 — La misma consulta, pero mostrando además qué porcentaje
--  representa cada producto sobre el saldo total captado por su familia.
--  Use RATIO_TO_REPORT o una función de ventana con SUM() OVER.
--  Cuidado: el porcentaje debe ser sobre la familia COMPLETA, no sobre
--  el top 3.


-- #####################################################################
-- EJERCICIO 3.2 — Series de tiempo: acumulado y variación
--
-- Riesgo operativo quiere la evolución mensual del valor transferido
-- durante 2026, con el acumulado del año y la variación contra el mes
-- anterior. Es la base de las alertas por comportamiento atípico.
-- #####################################################################

-- MODELO (resuelto)
WITH mensual AS (
  SELECT TRUNC(fecha_transf, 'MM') AS mes,
         SUM(valor)                AS valor_transferido,
         COUNT(*)                  AS operaciones
    FROM transferencia
   WHERE fecha_transf >= DATE '2026-01-01'
     AND fecha_transf <  DATE '2027-01-01'
     AND estado = 'APLICADA'
   GROUP BY TRUNC(fecha_transf, 'MM')
)
SELECT TO_CHAR(mes,'YYYY-MM')                          AS mes,
       operaciones,
       ROUND(valor_transferido)                        AS valor,
       ROUND(SUM(valor_transferido) OVER (ORDER BY mes
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS acumulado,
       ROUND(LAG(valor_transferido) OVER (ORDER BY mes)) AS mes_anterior,
       ROUND(100 * (valor_transferido - LAG(valor_transferido) OVER (ORDER BY mes))
                 / NULLIF(LAG(valor_transferido) OVER (ORDER BY mes),0), 1) AS var_pct
  FROM mensual
 ORDER BY mes;

--
--  PREGUNTA 3.2 — ¿Qué diferencia hay entre
--     ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--  y  RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ?
--  Constrúyase un caso donde den resultados distintos.
--
--  ESCRIBA 3.2 — Agregue una columna con el promedio móvil de los
--  últimos 3 meses (mes actual y los dos anteriores), que es la línea
--  base contra la que riesgo compara cada mes.


-- #####################################################################
-- EJERCICIO 3.3 — La misma respuesta, dos planes muy distintos
--
-- Se necesita, por cada cliente PREFERENCIAL, su última transferencia.
-- #####################################################################

-- VERSIÓN A — subconsulta correlacionada  (la que sale sola al escribir)
EXPLAIN PLAN FOR
SELECT cl.id_cliente, cl.nombre, t.id_transferencia, t.fecha_transf, t.valor
  FROM cliente       cl
  JOIN cuenta        c ON c.id_cliente = cl.id_cliente
  JOIN transferencia t ON t.cuenta_origen = c.id_cuenta
 WHERE cl.segmento = 'PREFERENCIAL'
   AND t.fecha_transf = (SELECT MAX(t2.fecha_transf)
                           FROM transferencia t2
                           JOIN cuenta c2 ON c2.id_cuenta = t2.cuenta_origen
                          WHERE c2.id_cliente = cl.id_cliente);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- VERSIÓN B — función analítica
EXPLAIN PLAN FOR
SELECT id_cliente, nombre, id_transferencia, fecha_transf, valor
  FROM (SELECT cl.id_cliente, cl.nombre, t.id_transferencia,
               t.fecha_transf, t.valor,
               ROW_NUMBER() OVER (PARTITION BY cl.id_cliente
                                  ORDER BY t.fecha_transf DESC) AS rn
          FROM cliente       cl
          JOIN cuenta        c ON c.id_cliente = cl.id_cliente
          JOIN transferencia t ON t.cuenta_origen = c.id_cuenta
         WHERE cl.segmento = 'PREFERENCIAL')
 WHERE rn = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

--
--  PREGUNTA 3.3 — Compare los dos planes. ¿Cuántas veces se lee
--  TRANSFERENCIA en cada versión? ¿Cuál es el COST de cada una?
--
--  PREGUNTA 3.4 — Las dos consultas NO son totalmente equivalentes:
--  hay un caso en el que devuelven distinto número de filas. ¿Cuál es?
--  (pista: piense en un cliente que hizo dos transferencias el mismo
--  día a la misma hora, algo perfectamente normal en un pago de nómina)


-- #####################################################################
-- EJERCICIO 3.4 — Jerarquías: la CTE recursiva
--
-- El catálogo tiene tres niveles: línea de negocio, familia y producto.
-- #####################################################################

-- MODELO (resuelto) — ruta completa de cada nodo del catálogo
WITH arbol (id_producto, nombre, id_padre, nivel, ruta) AS (
  SELECT id_producto, nombre, id_padre, 1, CAST(nombre AS VARCHAR2(400))
    FROM catalogo_producto
   WHERE id_padre IS NULL
  UNION ALL
  SELECT c.id_producto, c.nombre, c.id_padre, a.nivel + 1,
         a.ruta || ' > ' || c.nombre
    FROM catalogo_producto c
    JOIN arbol a ON c.id_padre = a.id_producto
)
SELECT LPAD(' ', (nivel-1)*3) || nombre AS jerarquia, nivel, ruta
  FROM arbol
 ORDER BY ruta;

-- El equivalente con CONNECT BY, sintaxis propia de Oracle
SELECT LPAD(' ', (LEVEL-1)*3) || nombre AS jerarquia,
       LEVEL AS nivel,
       SYS_CONNECT_BY_PATH(nombre, ' > ') AS ruta
  FROM catalogo_producto
 START WITH id_padre IS NULL
CONNECT BY PRIOR id_producto = id_padre
 ORDER SIBLINGS BY nombre;

--
--  PREGUNTA 3.5 — ¿Qué ventaja tiene la CTE recursiva sobre CONNECT BY?
--  ¿Y qué le da CONNECT BY que la CTE no?
--
--  ESCRIBA 3.3 — Saldo total captado por LÍNEA DE NEGOCIO.
--  Es decir: el saldo de "Cuenta de ahorros" debe sumar dentro de
--  "Banca Personas". Use la CTE recursiva para resolver a qué línea
--  pertenece cada producto hoja, y únala con los saldos de CUENTA.
--  Muestre además cuántas cuentas activas tiene cada línea.


-- #####################################################################
-- EJERCICIO 3.5 — MERGE: aplicar los ajustes del cierre mensual
--
-- Cada fin de mes se aplican intereses y cuotas de manejo. La tabla
-- AJUSTE_SALDO ya los tiene cargados.
-- #####################################################################

-- PASO 1  Antes
SELECT ROUND(SUM(saldo)) AS saldo_total, COUNT(*) AS cuentas FROM cuenta;
SELECT concepto, COUNT(*), SUM(delta) FROM ajuste_saldo GROUP BY concepto;

-- MODELO (resuelto)
MERGE INTO cuenta c
USING (SELECT id_cuenta, SUM(delta) AS delta
         FROM ajuste_saldo
        GROUP BY id_cuenta) a
   ON (c.id_cuenta = a.id_cuenta)
 WHEN MATCHED THEN
   UPDATE SET c.saldo   = GREATEST(c.saldo + a.delta, 0),
              c.version = c.version + 1;
--> Mire el mensaje de SQL Developer: cuántas filas fusionó.
COMMIT;

-- PASO 2  Después
SELECT ROUND(SUM(saldo)) AS saldo_total FROM cuenta;

--
--  PREGUNTA 3.6 — ¿Por qué se agrupa la tabla de ajustes dentro del
--  USING en lugar de usarla directamente? ¿Qué error da Oracle si una
--  misma cuenta aparece dos veces en el origen?
--
--  PREGUNTA 3.7 — El GREATEST(..., 0) evita que el saldo quede negativo.
--  En un banco eso NO es una solución: si una cuota de manejo excede el
--  saldo, truncar a cero significa que el banco regaló la diferencia.
--  ¿Qué haría usted en un sistema real? Proponga el mecanismo, no solo
--  la crítica.
--
--  ESCRIBA 3.4 — Reescriba el MERGE para que las cuentas cuyo ajuste no
--  se pueda aplicar completo NO se toquen, y en cambio queden
--  identificadas. Pista: la cláusula WHERE de la actualización dentro
--  del MERGE, más una consulta que liste las excluidas.


-- #####################################################################
-- EJERCICIO 3.6 — PIVOT y LISTAGG
-- #####################################################################

-- MODELO (resuelto) — valor transferido por canal y trimestre, en columnas
SELECT *
  FROM (SELECT canal,
               'T' || TO_CHAR(fecha_transf,'Q') AS trimestre,
               valor
          FROM transferencia
         WHERE fecha_transf >= DATE '2026-01-01'
           AND fecha_transf <  DATE '2027-01-01'
           AND estado = 'APLICADA')
 PIVOT (ROUND(SUM(valor)) FOR trimestre IN ('T1' AS t1, 'T2' AS t2,
                                            'T3' AS t3, 'T4' AS t4))
 ORDER BY canal;

-- MODELO (resuelto) — los 10 clientes con más saldo y qué productos tienen
SELECT cl.id_cliente, cl.nombre, cl.segmento,
       ROUND(SUM(c.saldo)) AS saldo_total,
       COUNT(*)            AS cuentas,
       LISTAGG(DISTINCT p.nombre, ', ')
         WITHIN GROUP (ORDER BY p.nombre) AS productos
  FROM cliente cl
  JOIN cuenta  c ON c.id_cliente  = cl.id_cliente
  JOIN catalogo_producto p ON p.id_producto = c.id_producto
 WHERE c.estado = 'ACTIVA'
 GROUP BY cl.id_cliente, cl.nombre, cl.segmento
 ORDER BY saldo_total DESC
 FETCH FIRST 10 ROWS WITH TIES;

--
--  PREGUNTA 3.8 — ¿Qué diferencia hay entre FETCH FIRST 10 ROWS ONLY y
--  FETCH FIRST 10 ROWS WITH TIES? ¿En cuál de los dos casos puede
--  devolver más de 10 filas y por qué?
--
--  ESCRIBA 3.5 — Un informe de "clientes en fuga": clientes
--  PREFERENCIAL cuya última transferencia tiene más de 120 días,
--  mostrando cuántos días llevan inactivos, su saldo total y cuántos
--  productos tienen contratados.
