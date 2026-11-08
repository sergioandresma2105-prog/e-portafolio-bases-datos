-- ============================================================================
--  Universidad El Bosque  |  Bases de Datos 2
--  Quiz 2 - SQL Avanzado en Oracle: Joins, Subconsultas, CTE y Funciones
--  Esquema de practica: Aerolinea AeroAndes
--  Motor: Oracle Database 19c
-- ----------------------------------------------------------------------------
--  01_ddl_aeroandes.sql  -  Creacion del esquema
-- ============================================================================


-- Ejecutar como el usuario propietario del esquema.
-- El script es reejecutable: elimina los objetos previos antes de crearlos.

-- ---------------------------------------------------------------------------
-- Limpieza previa
-- ---------------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('INCIDENCIA','RESERVA','VUELO',
                                  'PASAJERO','AERONAVE','AEROPUERTO'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

-- ---------------------------------------------------------------------------
-- AEROPUERTO
-- ---------------------------------------------------------------------------
CREATE TABLE aeropuerto (
  cod_aeropuerto  CHAR(3)        NOT NULL,
  ciudad          VARCHAR2(60)   NOT NULL,
  pais            VARCHAR2(60)   NOT NULL,
  CONSTRAINT pk_aeropuerto PRIMARY KEY (cod_aeropuerto)
);

-- ---------------------------------------------------------------------------
-- AERONAVE
-- ---------------------------------------------------------------------------
CREATE TABLE aeronave (
  id_aeronave  NUMBER(6)      NOT NULL,
  modelo       VARCHAR2(60)   NOT NULL,
  capacidad    NUMBER(4)      NOT NULL,
  CONSTRAINT pk_aeronave  PRIMARY KEY (id_aeronave),
  CONSTRAINT ck_aeronave_cap CHECK (capacidad > 0)
);

-- ---------------------------------------------------------------------------
-- PASAJERO
--   id_pasajero_referido es autorreferencia y admite nulos: es la columna que
--   hace fallar el NOT IN de la consulta defectuosa de la Pregunta 1.
-- ---------------------------------------------------------------------------
CREATE TABLE pasajero (
  id_pasajero           NUMBER(8)     NOT NULL,
  nombre                VARCHAR2(80)  NOT NULL,
  ciudad_residencia     VARCHAR2(60)  NOT NULL,
  id_pasajero_referido  NUMBER(8),
  CONSTRAINT pk_pasajero  PRIMARY KEY (id_pasajero),
  CONSTRAINT fk_pas_refer FOREIGN KEY (id_pasajero_referido)
                          REFERENCES pasajero (id_pasajero),
  CONSTRAINT ck_pas_autoref CHECK (id_pasajero_referido <> id_pasajero)
);

-- ---------------------------------------------------------------------------
-- VUELO
-- ---------------------------------------------------------------------------
CREATE TABLE vuelo (
  id_vuelo      NUMBER(8)     NOT NULL,
  num_vuelo     VARCHAR2(10)  NOT NULL,
  fecha_salida  DATE          NOT NULL,
  cod_origen    CHAR(3)       NOT NULL,
  cod_destino   CHAR(3)       NOT NULL,
  id_aeronave   NUMBER(6)     NOT NULL,
  CONSTRAINT pk_vuelo      PRIMARY KEY (id_vuelo),
  CONSTRAINT fk_vuelo_ori  FOREIGN KEY (cod_origen)
                           REFERENCES aeropuerto (cod_aeropuerto),
  CONSTRAINT fk_vuelo_des  FOREIGN KEY (cod_destino)
                           REFERENCES aeropuerto (cod_aeropuerto),
  CONSTRAINT fk_vuelo_aer  FOREIGN KEY (id_aeronave)
                           REFERENCES aeronave (id_aeronave),
  CONSTRAINT ck_vuelo_ruta CHECK (cod_origen <> cod_destino)
);

-- ---------------------------------------------------------------------------
-- RESERVA
-- ---------------------------------------------------------------------------
CREATE TABLE reserva (
  id_reserva    NUMBER(10)    NOT NULL,
  id_vuelo      NUMBER(8)     NOT NULL,
  id_pasajero   NUMBER(8)     NOT NULL,
  fecha_compra  DATE          NOT NULL,
  tarifa        NUMBER(12,2)  NOT NULL,
  clase         VARCHAR2(20)  NOT NULL,
  estado        VARCHAR2(20)  NOT NULL,
  CONSTRAINT pk_reserva      PRIMARY KEY (id_reserva),
  CONSTRAINT fk_res_vuelo    FOREIGN KEY (id_vuelo)    REFERENCES vuelo (id_vuelo),
  CONSTRAINT fk_res_pasajero FOREIGN KEY (id_pasajero) REFERENCES pasajero (id_pasajero),
  CONSTRAINT ck_res_estado   CHECK (estado IN ('CONFIRMADA','VOLADA','ANULADA')),
  CONSTRAINT ck_res_clase    CHECK (clase  IN ('ECONOMICA','EJECUTIVA')),
  CONSTRAINT ck_res_tarifa   CHECK (tarifa >= 0)
);

-- ---------------------------------------------------------------------------
-- INCIDENCIA
--   Sin clave primaria, tal como aparece en el enunciado: un vuelo puede tener
--   cero, una o varias incidencias. Es lo que permite el fan-out del join.
-- ---------------------------------------------------------------------------
CREATE TABLE incidencia (
  id_vuelo         NUMBER(8)     NOT NULL,
  tipo             VARCHAR2(40)  NOT NULL,
  minutos_retraso  NUMBER(5)     NOT NULL,
  CONSTRAINT fk_inc_vuelo FOREIGN KEY (id_vuelo) REFERENCES vuelo (id_vuelo),
  CONSTRAINT ck_inc_min   CHECK (minutos_retraso >= 0)
);

-- ---------------------------------------------------------------------------
-- Indices de apoyo
-- ---------------------------------------------------------------------------
CREATE INDEX ix_vuelo_fecha   ON vuelo (fecha_salida);
CREATE INDEX ix_vuelo_ruta    ON vuelo (cod_origen, cod_destino);
CREATE INDEX ix_reserva_vuelo ON reserva (id_vuelo);
CREATE INDEX ix_reserva_pas   ON reserva (id_pasajero);
CREATE INDEX ix_reserva_fcom  ON reserva (fecha_compra);
CREATE INDEX ix_inc_vuelo     ON incidencia (id_vuelo);
