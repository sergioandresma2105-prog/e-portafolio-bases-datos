-- =====================================================================
-- Tipos de índices en Oracle
-- 05_costo_del_indice.sql — lo que cuesta tener un índice
--
-- Este es el demo que cambia la actitud del grupo: hasta aquí los índices
-- solo han traído beneficios.
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 300
SET TIMING ON

-- #####################################################################
-- 1. Cuánto ocupan los índices frente a la tabla
-- #####################################################################
SELECT segment_type, COUNT(*) AS objetos,
       ROUND(SUM(bytes)/1024/1024, 1) AS mb
  FROM user_segments
 WHERE segment_name IN (
        SELECT table_name FROM user_tables WHERE table_name='VENTA'
        UNION ALL
        SELECT index_name FROM user_indexes WHERE table_name='VENTA')
 GROUP BY segment_type
 ORDER BY 1;
--> En una tabla muy indexada, los índices suelen pesar tanto o más que
--  los datos. Ese espacio también se respalda y se recupera.


-- #####################################################################
-- 2. Cuánto cuesta insertar con y sin índices
-- #####################################################################
CREATE TABLE carga_sin_idx AS SELECT * FROM venta WHERE 1=0;
CREATE TABLE carga_con_idx AS SELECT * FROM venta WHERE 1=0;

CREATE INDEX ci_1 ON carga_con_idx (id_cliente);
CREATE INDEX ci_2 ON carga_con_idx (id_producto);
CREATE INDEX ci_3 ON carga_con_idx (fecha_venta);
CREATE INDEX ci_4 ON carga_con_idx (id_sucursal, estado);
CREATE INDEX ci_5 ON carga_con_idx (valor);

SET TIMING ON
PROMPT === Insertando 200.000 filas SIN índices ===
INSERT INTO carga_sin_idx SELECT * FROM venta WHERE ROWNUM <= 200000;
COMMIT;

PROMPT === Insertando 200.000 filas CON cinco índices ===
INSERT INTO carga_con_idx SELECT * FROM venta WHERE ROWNUM <= 200000;
COMMIT;

--> Compare los dos tiempos. Cada índice obliga a mantener una estructura
--  ordenada más, en cada INSERT, UPDATE de esa columna y DELETE.
--  Es la respuesta a “¿y por qué no indexamos todas las columnas?”.


-- #####################################################################
-- 3. El mismo efecto al borrar
-- #####################################################################
PROMPT === Borrando 100.000 filas SIN índices ===
DELETE FROM carga_sin_idx WHERE ROWNUM <= 100000;
COMMIT;

PROMPT === Borrando 100.000 filas CON cinco índices ===
DELETE FROM carga_con_idx WHERE ROWNUM <= 100000;
COMMIT;


-- #####################################################################
-- 4. Índices que nadie usa
-- #####################################################################
-- Antes de borrar uno, hágalo invisible una o dos semanas y observe.
-- Si nada se degrada, bórrelo con tranquilidad:
--   ALTER INDEX ix_sospechoso INVISIBLE;
--   ... esperar ...
--   DROP INDEX ix_sospechoso;

DROP TABLE carga_sin_idx PURGE;
DROP TABLE carga_con_idx PURGE;


-- #####################################################################
-- 5. Checklist antes de crear un índice
-- #####################################################################
-- 1) ¿Qué consulta concreta lo necesita? Si no hay una, no hay índice.
-- 2) ¿Cuántas filas devuelve el filtro? Si es buena parte de la tabla,
--    el escaneo completo gana.
-- 3) ¿Ya hay un índice cuyo prefijo izquierdo sirva? Entonces sobra.
-- 4) ¿La columna se actualiza mucho? Cada UPDATE pagará el mantenimiento.
-- 5) ¿El predicado le aplica una función a la columna? Arregle la
--    consulta antes de crear un índice funcional.
-- 6) Créelo, mida de nuevo, y déjelo solo si mejoró.
