-- =====================================================================
-- Tipos de índices en Oracle
-- 01_btree.sql — el B-tree: único, no único, compuesto y de cobertura
--
-- Ejecutar POR BLOQUES. Cada bloque termina en un plan que hay que leer.
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 300
SET TIMING ON

-- Atajo para no repetir la llamada a DBMS_XPLAN
-- (en SQL Developer basta con F10 sobre la consulta)


-- #####################################################################
-- 1. El índice que usted no creó: el de la clave primaria
-- #####################################################################
SELECT index_name, index_type, uniqueness, blevel, leaf_blocks, distinct_keys
  FROM user_indexes WHERE table_name = 'VENTA';

-- Oracle crea un índice ÚNICO al declarar la PRIMARY KEY.
-- Ese índice es el que hace cumplir la restricción, no un adorno.

EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_venta = 250000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> INDEX UNIQUE SCAN: baja por el árbol y devuelve una fila. Costo mínimo.

-- Ojo con esto: una llave FORÁNEA no crea índice.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC'));
EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> TABLE ACCESS FULL. Es la causa número uno de escaneos completos
--  inesperados en bases recién creadas.


-- #####################################################################
-- 2. B-tree no único
-- #####################################################################
CREATE INDEX ix_venta_cliente ON venta (id_cliente);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS +PREDICATE'));
--> INDEX RANGE SCAN + TABLE ACCESS BY INDEX ROWID BATCHED
--  El predicado pasó de "filter" a "access".

-- Altura del árbol y factor de agrupamiento
SELECT index_name, blevel AS altura, leaf_blocks, distinct_keys, clustering_factor
  FROM user_indexes WHERE table_name = 'VENTA' ORDER BY 1;
--> blevel 2 para medio millón de filas: tres saltos hasta cualquier valor.


-- #####################################################################
-- 3. Cuándo el B-tree NO conviene
-- #####################################################################
EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_cliente BETWEEN 1 AND 25000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Vuelve al escaneo completo: el filtro deja pasar la mitad de la tabla.
--  Comprobemos que el optimizador tiene razón:
EXPLAIN PLAN FOR
SELECT /*+ INDEX(venta ix_venta_cliente) */ * FROM venta
 WHERE id_cliente BETWEEN 1 AND 25000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Compare el Cost de los dos planes.


-- #####################################################################
-- 4. Índice compuesto y la regla del prefijo izquierdo
-- #####################################################################
CREATE INDEX ix_venta_suc_fecha ON venta (id_sucursal, fecha_venta);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

-- 4.1  Filtro por la primera columna: lo usa
EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_sucursal = 7;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));

-- 4.2  Filtro por las dos: lo usa y acota mucho más
EXPLAIN PLAN FOR
SELECT * FROM venta
 WHERE id_sucursal = 7
   AND fecha_venta >= DATE '2024-03-01' AND fecha_venta < DATE '2024-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS +PREDICATE'));

-- 4.3  Filtro SOLO por la segunda columna
EXPLAIN PLAN FOR
SELECT * FROM venta
 WHERE fecha_venta >= DATE '2024-03-01' AND fecha_venta < DATE '2024-03-02';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> No sirve. El índice está ordenado por (sucursal, fecha), como un
--  directorio por (apellido, nombre): buscar solo por el nombre obliga
--  a recorrerlo entero.

-- 4.4  La excepción de Oracle: INDEX SKIP SCAN
--      Funciona cuando la primera columna tiene MUY pocos valores distintos.
CREATE INDEX ix_venta_canal_fecha ON venta (canal, fecha_venta);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR
SELECT /*+ INDEX_SS(venta ix_venta_canal_fecha) */ id_venta, fecha_venta
  FROM venta
 WHERE fecha_venta >= DATE '2024-03-01' AND fecha_venta < DATE '2024-03-02';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Con dos canales, saltar dos veces sale barato. Con 2.000 productos,
--  no. El skip scan es un rescate, no un criterio de diseño.


-- #####################################################################
-- 5. Índice de cobertura: cuando el motor ni toca la tabla
-- #####################################################################
EXPLAIN PLAN FOR
SELECT id_sucursal, fecha_venta FROM venta WHERE id_sucursal = 7;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Solo INDEX RANGE SCAN: desaparece el TABLE ACCESS.

EXPLAIN PLAN FOR
SELECT id_sucursal, fecha_venta, valor FROM venta WHERE id_sucursal = 7;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Al pedir una columna que no está en el índice, reaparece.

-- Regla práctica: agregar al índice una columna muy consultada puede
-- ahorrar el acceso a la tabla, a cambio de un índice más grande.


-- #####################################################################
-- 6. Índice único creado a mano
-- #####################################################################
CREATE UNIQUE INDEX ux_cliente_documento ON cliente (documento);
--> Además de acelerar, IMPIDE duplicados. Es una restricción disfrazada
--  de índice; si esa es la intención, es más claro declarar la
--  restricción UNIQUE y dejar que Oracle cree el índice.

SELECT index_name, uniqueness, index_type
  FROM user_indexes WHERE table_name IN ('CLIENTE','VENTA') ORDER BY 1;
