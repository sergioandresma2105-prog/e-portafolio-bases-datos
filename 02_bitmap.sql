-- =====================================================================
-- Tipos de índices en Oracle
-- 02_bitmap.sql — índices bitmap y bitmap join
--
-- REQUIERE Enterprise Edition o Express Edition (XE).
-- En Standard Edition 2 el CREATE BITMAP INDEX falla con ORA-00439.
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 300
SET TIMING ON

-- #####################################################################
-- 1. Cardinalidad de las columnas: quién es candidato a bitmap
-- #####################################################################
SELECT column_name, num_distinct, num_rows,
       ROUND(num_distinct / NULLIF(num_rows,0) * 100, 4) AS pct_distintos
  FROM user_tab_col_statistics c
  JOIN user_tables t USING (table_name)
 WHERE table_name = 'VENTA'
 ORDER BY num_distinct;
--> canal (2), estado (3) y id_sucursal (40) son de baja cardinalidad.
--  id_venta y fecha_venta, todo lo contrario.


-- #####################################################################
-- 2. El problema que el B-tree no resuelve bien
-- #####################################################################
CREATE INDEX ix_venta_estado_btree ON venta (estado);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT COUNT(*) FROM venta WHERE canal='WEB' AND estado='PAGADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Con B-tree, combinar dos condiciones poco selectivas no ayuda:
--  cada índice devuelve media tabla y el motor prefiere leerla entera.

DROP INDEX ix_venta_estado_btree;


-- #####################################################################
-- 3. Bitmap: uno por columna de baja cardinalidad
-- #####################################################################
CREATE BITMAP INDEX bx_venta_canal    ON venta (canal);
CREATE BITMAP INDEX bx_venta_estado   ON venta (estado);
CREATE BITMAP INDEX bx_venta_sucursal ON venta (id_sucursal);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT COUNT(*) FROM venta WHERE canal='WEB' AND estado='PAGADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS +PREDICATE'));
--> Aparecen BITMAP INDEX SINGLE VALUE y BITMAP AND.
--  El motor combina los mapas de bits con un AND binario, sin tocar la
--  tabla, y solo al final convierte a rowids. Eso es lo que un B-tree
--  no puede hacer.

-- Tres condiciones a la vez:
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM venta
 WHERE canal='WEB' AND estado='PAGADA' AND id_sucursal IN (3,7,11);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> BITMAP OR dentro de un BITMAP AND. Este es el patrón típico de un
--  tablero analítico: muchos filtros, cada uno poco selectivo.

-- Tamaño comparado
SELECT index_name, index_type, leaf_blocks, distinct_keys
  FROM user_indexes WHERE table_name='VENTA' ORDER BY index_type, index_name;
--> El bitmap ocupa una fracción de lo que ocuparía un B-tree equivalente.


-- #####################################################################
-- 4. Por qué NO se usa bitmap en OLTP
-- #####################################################################
-- Un bitmap no guarda un rowid por fila, sino un mapa comprimido que
-- cubre un RANGO de rowids. Al modificar una fila, Oracle bloquea todo
-- ese fragmento del mapa: con eso quedan bloqueadas, en la práctica,
-- muchas otras filas que comparten el mismo valor.
--
-- DEMOSTRACIÓN (necesita dos sesiones):
--
--   Sesión A:  UPDATE venta SET estado='ANULADA' WHERE id_venta = 100;
--              -- sin COMMIT
--   Sesión B:  UPDATE venta SET estado='ANULADA' WHERE id_venta = 101;
--              -- se queda esperando, aunque sea OTRA fila
--   Sesión A:  ROLLBACK;   -- la sesión B se libera
--
-- Con un índice B-tree sobre la misma columna esto no pasa.
-- Conclusión: bitmap en tablas con DML concurrente = contención garantizada.

-- Con qué mirar el bloqueo mientras ocurre:
--   SELECT sid, blocking_session, event, sql_id
--     FROM v$session WHERE blocking_session IS NOT NULL;


-- #####################################################################
-- 5. Bitmap join index
-- #####################################################################
-- Indexa una columna de OTRA tabla, resolviendo el join por adelantado.
CREATE BITMAP INDEX bjx_venta_region
    ON venta (s.region)
  FROM venta v, sucursal s
 WHERE v.id_sucursal = s.id_sucursal;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR
SELECT COUNT(*)
  FROM venta v JOIN sucursal s ON s.id_sucursal = v.id_sucursal
 WHERE s.region = 'NORTE';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> El join desaparece del plan: el índice ya sabe qué ventas son de la
--  región NORTE. Es una técnica clásica de bodega de datos.

-- Precio a pagar: cualquier cambio en SUCURSAL.region invalida el índice
-- y obliga a reconstruirlo. Solo tiene sentido sobre dimensiones estables.


-- #####################################################################
-- 6. Resumen para dictar
-- #####################################################################
-- BITMAP  sí:  bodegas de datos, columnas con pocos valores distintos,
--              muchas condiciones combinadas, cargas por lotes, COUNT(*).
-- BITMAP  no:  OLTP con inserciones y actualizaciones concurrentes,
--              columnas de alta cardinalidad, tablas que cambian todo el día.
