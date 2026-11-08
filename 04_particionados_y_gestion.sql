-- =====================================================================
-- Tipos de índices en Oracle
-- 04_particionados_y_gestion.sql — índices locales y globales,
--                                  invisibles, inutilizables y auditoría
--
-- La sección de particionamiento REQUIERE Enterprise Edition o XE.
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 300
SET TIMING ON

-- #####################################################################
-- 1. Índice LOCAL: una pieza por partición
-- #####################################################################
CREATE INDEX ixl_vpart_cliente ON venta_part (id_cliente) LOCAL;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA_PART',cascade=>TRUE);

SELECT index_name, partitioning_type, locality, alignment
  FROM user_part_indexes WHERE table_name = 'VENTA_PART';

SELECT index_name, partition_name, status, leaf_blocks
  FROM user_ind_partitions WHERE index_name = 'IXL_VPART_CLIENTE'
 ORDER BY partition_position;

-- Con la fecha en el filtro, el motor recorta particiones (pruning):
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM venta_part
 WHERE fecha_venta >= DATE '2024-01-01' AND fecha_venta < DATE '2024-07-01'
   AND id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +PARTITION +COST +ROWS'));
--> Mire las columnas Pstart y Pstop: solo toca la partición p_2024_s1.

-- Sin la fecha, tiene que mirar todas las piezas del índice:
EXPLAIN PLAN FOR SELECT COUNT(*) FROM venta_part WHERE id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +PARTITION +COST +ROWS'));


-- #####################################################################
-- 2. Índice GLOBAL: una sola estructura sobre toda la tabla
-- #####################################################################
CREATE INDEX ixg_vpart_valor ON venta_part (valor) GLOBAL;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA_PART',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT COUNT(*) FROM venta_part WHERE valor > 1900000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +PARTITION +COST +ROWS'));

-- La diferencia se ve al mantener las particiones:
--   ALTER TABLE venta_part DROP PARTITION p_resto;
--     · los índices LOCALes: solo pierden su pieza correspondiente
--     · los índices GLOBALes: quedan UNUSABLE y hay que reconstruirlos,
--       salvo que se use UPDATE GLOBAL INDEXES (que cuesta tiempo)
--
-- Regla práctica: LOCAL por defecto en tablas particionadas por fecha
-- con purga o archivado; GLOBAL solo cuando el acceso NUNCA lleva la
-- clave de particionamiento y hace falta unicidad global.


-- #####################################################################
-- 3. Índices invisibles
-- #####################################################################
-- Existe, se mantiene con el DML, pero el optimizador lo ignora.
-- Sirve para probar si un índice hace falta ANTES de borrarlo.
ALTER INDEX ix_venta_cliente INVISIBLE;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Vuelve al escaneo completo, como si el índice no existiera.

-- Se puede pedir que sí se vean, solo para esta sesión:
ALTER SESSION SET optimizer_use_invisible_indexes = TRUE;
EXPLAIN PLAN FOR SELECT * FROM venta WHERE id_cliente = 4321;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
ALTER SESSION SET optimizer_use_invisible_indexes = FALSE;

ALTER INDEX ix_venta_cliente VISIBLE;

SELECT index_name, visibility, status FROM user_indexes
 WHERE table_name='VENTA' ORDER BY 1;


-- #####################################################################
-- 4. Índices inutilizables (UNUSABLE)
-- #####################################################################
-- Truco de carga masiva: se apaga el índice, se cargan los datos sin
-- pagar el mantenimiento fila a fila, y al final se reconstruye de una vez.
ALTER INDEX ix_venta_suc_fecha UNUSABLE;
SELECT index_name, status FROM user_indexes WHERE index_name='IX_VENTA_SUC_FECHA';

-- ... aquí iría la carga masiva ...

ALTER INDEX ix_venta_suc_fecha REBUILD;
SELECT index_name, status FROM user_indexes WHERE index_name='IX_VENTA_SUC_FECHA';

-- Ojo: si el índice es el de una restricción UNIQUE o PRIMARY KEY,
-- dejarlo inutilizable bloquea el DML sobre la tabla.
-- Y en producción se reconstruye con ONLINE para no bloquear:
--   ALTER INDEX ix_venta_suc_fecha REBUILD ONLINE;


-- #####################################################################
-- 5. ¿Alguien usa este índice?
-- #####################################################################
-- Desde 12.2 Oracle lleva la cuenta solo:
SELECT index_name, table_name, used, total_access_count,
       last_used, monitoring_start, monitoring_stop
  FROM v$index_usage_info u
  JOIN user_indexes i ON i.index_name = u.name
 WHERE i.table_name IN ('VENTA','CLIENTE')
 ORDER BY 1;
--> Si esta consulta falla por permisos, pida SELECT sobre V$INDEX_USAGE_INFO.
--  En versiones anteriores: ALTER INDEX ... MONITORING USAGE
--  y luego consultar V$OBJECT_USAGE.


-- #####################################################################
-- 6. Inventario para auditar el esquema
-- #####################################################################
-- Todos los índices con su tipo y tamaño
SELECT i.index_name, i.table_name, i.index_type, i.uniqueness, i.visibility,
       i.status, i.blevel, i.leaf_blocks, i.distinct_keys, i.clustering_factor
  FROM user_indexes i
 WHERE i.table_name IN ('VENTA','VENTA_PART','CLIENTE','AUDITORIA','TICKET_IOT')
 ORDER BY i.table_name, i.index_name;

-- Columnas de cada índice, en orden
SELECT index_name, column_position, column_name, descend
  FROM user_ind_columns
 WHERE table_name IN ('VENTA','CLIENTE')
 ORDER BY index_name, column_position;

-- Expresiones de los índices basados en función
SELECT index_name, column_position, column_expression
  FROM user_ind_expressions ORDER BY index_name, column_position;

-- Índices redundantes: mismo prefijo de columnas.  Candidatos a borrar.
SELECT a.index_name AS indice_a, b.index_name AS indice_b, a.column_name AS primera_columna
  FROM user_ind_columns a
  JOIN user_ind_columns b
    ON a.table_name = b.table_name
   AND a.column_name = b.column_name
   AND a.column_position = 1 AND b.column_position = 1
   AND a.index_name < b.index_name
 WHERE a.table_name IN ('VENTA','CLIENTE')
 ORDER BY 1, 2;

-- Llaves foráneas SIN índice: la causa clásica de bloqueos al borrar el padre
SELECT c.table_name, c.constraint_name, cc.column_name
  FROM user_constraints c
  JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
 WHERE c.constraint_type = 'R'
   AND NOT EXISTS (
        SELECT 1 FROM user_ind_columns ic
         WHERE ic.table_name = c.table_name
           AND ic.column_name = cc.column_name
           AND ic.column_position = 1)
 ORDER BY 1, 2;
