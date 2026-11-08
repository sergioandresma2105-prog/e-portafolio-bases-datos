-- =====================================================================
-- Bases de Datos 2 · Tipos de índices en Oracle
-- 00_setup.sql — esquema de práctica y datos
--
-- Motor      : Oracle 19c (sirve igual en 12c, 21c y 23ai)
-- Ejecución  : una sola vez, completo, antes de la clase.  ~40 segundos
-- Requiere   : CREATE TABLE, CREATE INDEX, CREATE SEQUENCE y cuota
--              Para los demos de bitmap y particionamiento: Enterprise
--              Edition o XE. En Standard Edition 2 esos dos no existen.
-- =====================================================================

SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 100

-- ---------------------------------------------------------------------
-- Limpieza previa
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('VENTA','VENTA_PART','CLIENTE','PRODUCTO',
                                  'SUCURSAL','TICKET_IOT','AUDITORIA')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR sq IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name IN ('SEQ_AUDITORIA')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||sq.sequence_name;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- Dimensiones
-- ---------------------------------------------------------------------
CREATE TABLE sucursal (
  id_sucursal  NUMBER        NOT NULL,
  nombre       VARCHAR2(40)  NOT NULL,
  ciudad       VARCHAR2(30)  NOT NULL,
  region       VARCHAR2(20)  NOT NULL,     -- 4 valores: bitmap join index
  CONSTRAINT pk_sucursal PRIMARY KEY (id_sucursal)
);

CREATE TABLE producto (
  id_producto  NUMBER        NOT NULL,
  nombre       VARCHAR2(60)  NOT NULL,
  categoria    VARCHAR2(20)  NOT NULL,
  precio       NUMBER(12,2)  NOT NULL,
  CONSTRAINT pk_producto PRIMARY KEY (id_producto)
);

CREATE TABLE cliente (
  id_cliente   NUMBER        NOT NULL,
  documento    VARCHAR2(15)  NOT NULL,
  nombre       VARCHAR2(60)  NOT NULL,     -- mayúsculas y minúsculas mezcladas
  ciudad       VARCHAR2(30)  NOT NULL,
  segmento     VARCHAR2(12)  NOT NULL,     -- 3 valores: bitmap
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente)
);

-- ---------------------------------------------------------------------
-- Hechos: 500.000 ventas
-- ---------------------------------------------------------------------
CREATE TABLE venta (
  id_venta     NUMBER        NOT NULL,
  fecha_venta  DATE          NOT NULL,     -- con hora: demo de índice basado en función
  id_cliente   NUMBER        NOT NULL,
  id_producto  NUMBER        NOT NULL,
  id_sucursal  NUMBER        NOT NULL,
  canal        VARCHAR2(10)  NOT NULL,     -- 2 valores  : bitmap
  estado       VARCHAR2(12)  NOT NULL,     -- 3 valores sesgados
  cantidad     NUMBER(5)     NOT NULL,
  valor        NUMBER(14,2)  NOT NULL,
  CONSTRAINT pk_venta PRIMARY KEY (id_venta)
);

-- ---------------------------------------------------------------------
-- Carga
-- ---------------------------------------------------------------------
INSERT /*+ APPEND */ INTO sucursal
SELECT level,
       'Sucursal '||TO_CHAR(level,'FM00'),
       CASE MOD(level,5) WHEN 0 THEN 'BOGOTA' WHEN 1 THEN 'MEDELLIN'
                         WHEN 2 THEN 'CALI'   WHEN 3 THEN 'BARRANQUILLA'
                         ELSE 'BUCARAMANGA' END,
       CASE MOD(level,4) WHEN 0 THEN 'CENTRO' WHEN 1 THEN 'NORTE'
                         WHEN 2 THEN 'SUR'    ELSE 'OCCIDENTE' END
  FROM dual CONNECT BY level <= 40;
COMMIT;

INSERT /*+ APPEND */ INTO producto
SELECT level,
       'Producto '||TO_CHAR(level,'FM0000'),
       CASE MOD(level,5) WHEN 0 THEN 'HOGAR' WHEN 1 THEN 'TECNOLOGIA'
                         WHEN 2 THEN 'ROPA'  WHEN 3 THEN 'DEPORTE'
                         ELSE 'LIBROS' END,
       ROUND(DBMS_RANDOM.VALUE(10000,900000),-2)
  FROM dual CONNECT BY level <= 2000;
COMMIT;

INSERT /*+ APPEND */ INTO cliente
SELECT level,
       TO_CHAR(1000000+level),
       CASE MOD(level,50) WHEN 0 THEN 'GARCIA'
                          WHEN 1 THEN 'Garcia'
                          ELSE 'Apellido'||TO_CHAR(MOD(level,5000),'FM0000') END,
       CASE MOD(level,5) WHEN 0 THEN 'BOGOTA' WHEN 1 THEN 'MEDELLIN'
                         WHEN 2 THEN 'CALI'   WHEN 3 THEN 'BARRANQUILLA'
                         ELSE 'BUCARAMANGA' END,
       CASE MOD(level,3) WHEN 0 THEN 'PREMIUM' WHEN 1 THEN 'ESTANDAR'
                         ELSE 'BASICO' END
  FROM dual CONNECT BY level <= 50000;
COMMIT;

INSERT /*+ APPEND */ INTO venta
SELECT level,
       DATE '2024-01-01' + MOD(level,700) + (MOD(level,86400)/86400),
       MOD(level,50000)+1,
       MOD(level,2000)+1,
       MOD(level,40)+1,
       CASE MOD(level,2) WHEN 0 THEN 'WEB' ELSE 'TIENDA' END,
       CASE WHEN MOD(level,1000)=0 THEN 'ANULADA'
            WHEN MOD(level,20)=0   THEN 'PENDIENTE'
            ELSE 'PAGADA' END,
       MOD(level,5)+1,
       ROUND(DBMS_RANDOM.VALUE(20000,2000000),-2)
  FROM dual CONNECT BY level <= 500000;
COMMIT;

ALTER TABLE venta ADD CONSTRAINT fk_venta_cliente  FOREIGN KEY (id_cliente)  REFERENCES cliente;
ALTER TABLE venta ADD CONSTRAINT fk_venta_producto FOREIGN KEY (id_producto) REFERENCES producto;
ALTER TABLE venta ADD CONSTRAINT fk_venta_sucursal FOREIGN KEY (id_sucursal) REFERENCES sucursal;

-- ---------------------------------------------------------------------
-- Tabla particionada, para el demo de índices locales y globales
-- ---------------------------------------------------------------------
CREATE TABLE venta_part (
  id_venta     NUMBER        NOT NULL,
  fecha_venta  DATE          NOT NULL,
  id_cliente   NUMBER        NOT NULL,
  canal        VARCHAR2(10)  NOT NULL,
  valor        NUMBER(14,2)  NOT NULL
)
PARTITION BY RANGE (fecha_venta) (
  PARTITION p_2024_s1 VALUES LESS THAN (DATE '2024-07-01'),
  PARTITION p_2024_s2 VALUES LESS THAN (DATE '2025-01-01'),
  PARTITION p_2025_s1 VALUES LESS THAN (DATE '2025-07-01'),
  PARTITION p_resto   VALUES LESS THAN (MAXVALUE)
);

INSERT /*+ APPEND */ INTO venta_part
SELECT id_venta, fecha_venta, id_cliente, canal, valor FROM venta;
COMMIT;

-- ---------------------------------------------------------------------
-- Tabla para el demo de secuencia y clave inversa
-- ---------------------------------------------------------------------
CREATE SEQUENCE seq_auditoria START WITH 1 CACHE 100;

CREATE TABLE auditoria (
  id_evento    NUMBER        NOT NULL,
  fecha_evento DATE          DEFAULT SYSDATE NOT NULL,
  usuario      VARCHAR2(30)  NOT NULL,
  accion       VARCHAR2(40)  NOT NULL
);

INSERT /*+ APPEND */ INTO auditoria (id_evento, fecha_evento, usuario, accion)
SELECT seq_auditoria.NEXTVAL,
       SYSDATE - MOD(level,365),
       'USR'||TO_CHAR(MOD(level,50),'FM00'),
       CASE MOD(level,4) WHEN 0 THEN 'LOGIN' WHEN 1 THEN 'CONSULTA'
                         WHEN 2 THEN 'ACTUALIZA' ELSE 'BORRA' END
  FROM dual CONNECT BY level <= 100000;
COMMIT;

-- ---------------------------------------------------------------------
-- Estadísticas
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('VENTA','VENTA_PART','CLIENTE','PRODUCTO',
                                  'SUCURSAL','AUDITORIA')) LOOP
    DBMS_STATS.GATHER_TABLE_STATS(USER, t.table_name, cascade => TRUE);
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------
SELECT table_name, num_rows FROM user_tables
 WHERE table_name IN ('VENTA','VENTA_PART','CLIENTE','PRODUCTO','SUCURSAL','AUDITORIA')
 ORDER BY 1;

-- Los únicos índices que existen ahora son los de las claves primarias.
SELECT index_name, table_name, index_type, uniqueness
  FROM user_indexes ORDER BY table_name, index_name;

PROMPT
PROMPT ==========================================================
PROMPT  Listo. Siga con 01_btree.sql
PROMPT ==========================================================
