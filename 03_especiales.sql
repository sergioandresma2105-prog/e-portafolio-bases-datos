-- =====================================================================
-- Tipos de índices en Oracle
-- 03_especiales.sql — basado en función, descendente, clave inversa,
--                     comprimido, IOT y Oracle Text
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 300
SET TIMING ON

-- #####################################################################
-- 1. Índice basado en función
-- #####################################################################
CREATE INDEX ix_cliente_nombre ON cliente (nombre);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'CLIENTE',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT * FROM cliente WHERE nombre = 'GARCIA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- lo usa

EXPLAIN PLAN FOR SELECT * FROM cliente WHERE UPPER(nombre) = 'GARCIA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- NO lo usa

-- El índice guarda 'Garcia'; UPPER('Garcia') no está en el árbol.
CREATE INDEX fx_cliente_upper_nombre ON cliente (UPPER(nombre));
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'CLIENTE',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT * FROM cliente WHERE UPPER(nombre) = 'GARCIA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- ahora sí

-- El caso de las fechas, que es el que aparece en producción:
CREATE INDEX fx_venta_dia ON venta (TRUNC(fecha_venta));
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT COUNT(*) FROM venta WHERE TRUNC(fecha_venta) = DATE '2024-05-10';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));

-- Alternativa sin índice extra: reescribir el predicado como rango.
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM venta
 WHERE fecha_venta >= DATE '2024-05-10' AND fecha_venta < DATE '2024-05-11';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> Casi siempre es mejor arreglar la consulta que crear un índice más.

-- Truco poco conocido: índice funcional PARCIAL.
-- Indexa solo las filas que interesan; el resto entra como NULL y los
-- nulos no se almacenan en un B-tree.
CREATE INDEX fx_venta_anuladas
    ON venta (CASE WHEN estado = 'ANULADA' THEN id_venta END);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

SELECT index_name, leaf_blocks FROM user_indexes
 WHERE index_name IN ('FX_VENTA_ANULADAS','FX_VENTA_DIA');
--> El índice parcial ocupa una fracción: solo indexa el 0,1 % de las filas.


-- #####################################################################
-- 2. Índice descendente
-- #####################################################################
CREATE INDEX ix_venta_fecha_desc ON venta (fecha_venta DESC);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

EXPLAIN PLAN FOR
SELECT * FROM venta ORDER BY fecha_venta DESC FETCH FIRST 10 ROWS ONLY;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));

-- Nota: para UNA sola columna, un B-tree normal ya se puede recorrer al
-- revés, así que el DESC no aporta. Solo tiene sentido en índices
-- compuestos con órdenes mezclados:
--     CREATE INDEX ix ON venta (id_sucursal ASC, fecha_venta DESC);
-- Curiosidad: Oracle implementa el descendente como índice BASADO EN
-- FUNCIÓN. Compruébelo:
SELECT index_name, index_type FROM user_indexes
 WHERE index_name = 'IX_VENTA_FECHA_DESC';


-- #####################################################################
-- 3. Índice de clave inversa
-- #####################################################################
-- Problema: una clave que crece siempre (una secuencia) concentra todas
-- las inserciones en el ÚLTIMO bloque hoja del índice. Con muchas
-- sesiones insertando a la vez, ese bloque se vuelve un cuello de
-- botella (buffer busy waits, y en RAC mucho peor).
CREATE UNIQUE INDEX rx_auditoria_id ON auditoria (id_evento) REVERSE;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'AUDITORIA',cascade=>TRUE);

SELECT index_name, index_type FROM user_indexes WHERE table_name='AUDITORIA';

-- La clave inversa invierte los bytes: 12345 y 12346 quedan lejísimos
-- uno del otro, y las inserciones se reparten por todo el índice.
EXPLAIN PLAN FOR SELECT * FROM auditoria WHERE id_evento = 55555;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- sirve

EXPLAIN PLAN FOR SELECT * FROM auditoria WHERE id_evento BETWEEN 100 AND 200;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- NO sirve
--> Ese es el precio: al invertir los bytes se pierde el orden, así que
--  los rangos ya no se pueden resolver con el índice. Solo igualdad.


-- #####################################################################
-- 4. Índice comprimido
-- #####################################################################
-- Cuando el prefijo de la clave se repite mucho, se puede guardar una
-- sola vez por bloque hoja.
CREATE INDEX ix_venta_canal_est      ON venta (canal, estado, id_producto);
CREATE INDEX ix_venta_canal_est_comp ON venta (canal, estado, id_cliente) COMPRESS 2;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'VENTA',cascade=>TRUE);

SELECT index_name, leaf_blocks, compression
  FROM user_indexes
 WHERE index_name IN ('IX_VENTA_CANAL_EST','IX_VENTA_CANAL_EST_COMP');
--> COMPRESS 2 comprime las dos primeras columnas, que son las que se
--  repiten. Menos bloques hoja = menos lecturas y menos memoria.
--  Cuesta un poco más de CPU al leer.


-- #####################################################################
-- 5. Tabla organizada por índice (IOT)
-- #####################################################################
-- La tabla ES el índice: las filas viven ordenadas dentro del B-tree de
-- la clave primaria. No hay tabla aparte, así que no hay segundo salto.
CREATE TABLE ticket_iot (
  id_evento   NUMBER        NOT NULL,
  consecutivo NUMBER        NOT NULL,
  descripcion VARCHAR2(200),
  CONSTRAINT pk_ticket_iot PRIMARY KEY (id_evento, consecutivo)
) ORGANIZATION INDEX;

INSERT /*+ APPEND */ INTO ticket_iot
SELECT MOD(level,10000)+1, MOD(level,7)+1, 'Detalle '||level
  FROM dual CONNECT BY level <= 60000;
COMMIT;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'TICKET_IOT',cascade=>TRUE);

EXPLAIN PLAN FOR SELECT * FROM ticket_iot WHERE id_evento = 500;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));
--> INDEX RANGE SCAN sobre la IOT, sin TABLE ACCESS BY INDEX ROWID:
--  la fila completa ya estaba en la hoja del índice.

SELECT table_name, iot_type FROM user_tables WHERE table_name='TICKET_IOT';

-- IOT sí:  tablas de detalle o de cruce a las que casi siempre se accede
--          por la clave primaria completa o por su prefijo.
-- IOT no:  tablas anchas, o con muchos índices secundarios (esos guardan
--          una dirección lógica que se degrada con el tiempo).


-- #####################################################################
-- 6. El caso que ningún índice convencional resuelve
-- #####################################################################
EXPLAIN PLAN FOR SELECT * FROM cliente WHERE nombre LIKE 'GARCIA%';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- usa índice

EXPLAIN PLAN FOR SELECT * FROM cliente WHERE nombre LIKE '%GARCIA%';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL,NULL,'BASIC +COST +ROWS'));   -- escaneo total

-- Para búsquedas de texto dentro de la cadena hace falta Oracle Text:
--   CREATE INDEX tx_cliente_nombre ON cliente (nombre)
--     INDEXTYPE IS CTXSYS.CONTEXT;
--   SELECT * FROM cliente WHERE CONTAINS(nombre, 'GARCIA') > 0;
-- Requiere el componente Oracle Text instalado y mantenimiento del índice
-- (sincronización), así que no se activa a la ligera.
