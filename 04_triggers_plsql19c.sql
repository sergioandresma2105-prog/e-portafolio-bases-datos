--------------------------------------------------------------------------------
-- UNIVERSIDAD EL BOSQUE - INGENIERIA DE SISTEMAS
-- Bases de Datos - Modulo 4 de 4: DISPARADORES (TRIGGERS)
-- Oracle Database 19c
-- Docente: Ing. Christian Felipe Duarte
--------------------------------------------------------------------------------
-- COMO USAR ESTE ARCHIVO
--
--   1. Script independiente: crea sus propias tablas (prefijo TRG_) y al final
--      las elimina. No necesita los otros modulos.
--   2. Avance PASO por PASO. Cada paso trae QUE VAMOS A HACER / QUE DEBE
--      OBSERVAR / RESULTADO ESPERADO.
--   3. El PASO 7 DEBE fallar con ORA-04091. No lo salte: el PASO 8 lo resuelve
--      y esa pareja de pasos es el centro de la sesion.
--   4. Requisitos: usuario con CREATE TABLE, CREATE TRIGGER y CREATE VIEW.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT ============================================================
PROMPT  MODULO 4 - DISPARADORES
PROMPT ============================================================


--------------------------------------------------------------------------------
-- PASO 0 - PREPARACION DEL ESQUEMA DE PRACTICA
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : crear estudiantes, asignaturas, inscripciones, una tabla
--                     de auditoria y otra para auditar DDL.
-- QUE DEBE OBSERVAR : los disparadores se eliminan ANTES que las tablas.
-- RESULTADO ESPERADO: 4 estudiantes, 3 asignaturas, 0 inscripciones.
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (SELECT trigger_name FROM user_triggers
             WHERE trigger_name LIKE 'TRG\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.trigger_name;
  END LOOP;

  FOR r IN (SELECT view_name FROM user_views
             WHERE view_name = 'V_TRG_INSCRIPCION_DETALLE') LOOP
    EXECUTE IMMEDIATE 'DROP VIEW ' || r.view_name;
  END LOOP;

  FOR r IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('TRG_INSCRIPCION','TRG_ASIGNATURA',
                                  'TRG_ESTUDIANTE','TRG_AUDITORIA',
                                  'TRG_AUDITORIA_DDL')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

CREATE TABLE trg_estudiante (
  id_estudiante NUMBER(5) CONSTRAINT pk_trg_est PRIMARY KEY,
  nombre        VARCHAR2(40) NOT NULL
);

CREATE TABLE trg_asignatura (
  id_asignatura NUMBER(5) CONSTRAINT pk_trg_asig PRIMARY KEY,
  titulo        VARCHAR2(40) NOT NULL,
  cupo_maximo   NUMBER(3) DEFAULT 3
);

CREATE TABLE trg_inscripcion (
  id_inscripcion   NUMBER GENERATED ALWAYS AS IDENTITY
                   CONSTRAINT pk_trg_ins PRIMARY KEY,
  id_estudiante    NUMBER(5) CONSTRAINT fk_trg_ins_est REFERENCES trg_estudiante,
  id_asignatura    NUMBER(5) CONSTRAINT fk_trg_ins_asig REFERENCES trg_asignatura,
  estado           VARCHAR2(12),
  fecha_registro   DATE,
  usuario_registro VARCHAR2(30)
);

CREATE TABLE trg_auditoria (
  fecha        TIMESTAMP,
  usuario      VARCHAR2(30),
  operacion    VARCHAR2(10),
  id_anterior  NUMBER,
  id_nuevo     NUMBER,
  detalle      VARCHAR2(200)
);

CREATE TABLE trg_auditoria_ddl (
  fecha   TIMESTAMP,
  usuario VARCHAR2(30),
  evento  VARCHAR2(30),
  objeto  VARCHAR2(60),
  tipo    VARCHAR2(30)
);

INSERT INTO trg_estudiante VALUES (101,'Ana Maria Torres');
INSERT INTO trg_estudiante VALUES (102,'Bernardo Pineda');
INSERT INTO trg_estudiante VALUES (103,'Carolina Reyes');
INSERT INTO trg_estudiante VALUES (104,'Daniel Ospina');

INSERT INTO trg_asignatura VALUES (55,'Bases de Datos 1',3);
INSERT INTO trg_asignatura VALUES (56,'Bases de Datos 2',3);
INSERT INTO trg_asignatura VALUES (57,'Sistemas Operativos',2);
COMMIT;

PROMPT Esquema de practica listo.


--------------------------------------------------------------------------------
-- PASO 1 - BEFORE INSERT DE FILA: VALORES DERIVADOS
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : completar fecha, usuario y estado antes de que la fila
--                     se escriba.
-- QUE DEBE OBSERVAR : la asignacion a :NEW solo tiene efecto en un BEFORE de
--                     fila. En un AFTER la fila ya se escribio.
-- RESULTADO ESPERADO: el INSERT no envia esos tres campos y aun asi quedan
--                     con valor.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_inscripcion_bi
BEFORE INSERT ON trg_inscripcion
FOR EACH ROW
BEGIN
  :NEW.fecha_registro   := SYSDATE;
  :NEW.usuario_registro := USER;
  :NEW.estado           := NVL(:NEW.estado, 'PENDIENTE');
END;
/
SHOW ERRORS

INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (101, 55);
INSERT INTO trg_inscripcion (id_estudiante, id_asignatura, estado)
     VALUES (102, 55, 'ACTIVA');
COMMIT;

SELECT id_inscripcion, id_estudiante, estado, usuario_registro,
       TO_CHAR(fecha_registro,'YYYY-MM-DD HH24:MI') AS registrado
  FROM trg_inscripcion ORDER BY id_inscripcion;

-- PARA PENSAR: fecha_registro y estado se podian resolver con DEFAULT en la
-- tabla, sin disparador. Antes de escribir uno, pregunte siempre si la opcion
-- declarativa alcanza: es mas rapida y no se puede deshabilitar por accidente.


--------------------------------------------------------------------------------
-- PASO 2 - AUDITORIA CON PREDICADOS CONDICIONALES
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : un solo disparador para INSERT, UPDATE y DELETE.
-- QUE DEBE OBSERVAR : INSERTING, UPDATING y DELETING permiten distinguir el
--                     evento. En DELETE, :NEW viene vacio; en INSERT, :OLD.
-- RESULTADO ESPERADO: tres filas en TRG_AUDITORIA, una por operacion.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_inscripcion_audita
AFTER INSERT OR UPDATE OR DELETE ON trg_inscripcion
FOR EACH ROW
DECLARE
  v_operacion VARCHAR2(10);
BEGIN
  IF    INSERTING THEN v_operacion := 'INSERT';
  ELSIF UPDATING  THEN v_operacion := 'UPDATE';
  ELSIF DELETING  THEN v_operacion := 'DELETE';
  END IF;

  INSERT INTO trg_auditoria (fecha, usuario, operacion, id_anterior, id_nuevo, detalle)
       VALUES (SYSTIMESTAMP, USER, v_operacion,
               :OLD.id_inscripcion, :NEW.id_inscripcion,
               'estado: ' || NVL(:OLD.estado,'-') || ' -> ' || NVL(:NEW.estado,'-'));
END;
/
SHOW ERRORS

INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (103, 56);
UPDATE trg_inscripcion SET estado = 'ACTIVA' WHERE id_estudiante = 103;
DELETE FROM trg_inscripcion WHERE id_estudiante = 103;
COMMIT;

SELECT operacion, id_anterior, id_nuevo, detalle
  FROM trg_auditoria ORDER BY fecha;


--------------------------------------------------------------------------------
-- PASO 3 - LA CLAUSULA WHEN Y LA DIFERENCIA DE LOS DOS PUNTOS
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : disparar solo cuando el estado cambie realmente.
-- QUE DEBE OBSERVAR : en la clausula WHEN se escribe NEW y OLD SIN los dos
--                     puntos; dentro del cuerpo, CON los dos puntos.
-- RESULTADO ESPERADO: el primer UPDATE no genera auditoria, el segundo si.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_inscripcion_cambio
AFTER UPDATE OF estado ON trg_inscripcion
FOR EACH ROW
WHEN (NEW.estado <> OLD.estado)
BEGIN
  DBMS_OUTPUT.PUT_LINE('Cambio real de estado en la inscripcion ' ||
                       :OLD.id_inscripcion || ': ' ||
                       :OLD.estado || ' -> ' || :NEW.estado);
END;
/
SHOW ERRORS

UPDATE trg_inscripcion SET estado = 'PENDIENTE' WHERE id_estudiante = 101;  -- mismo valor
UPDATE trg_inscripcion SET estado = 'ACTIVA'    WHERE id_estudiante = 101;  -- cambio real
COMMIT;


--------------------------------------------------------------------------------
-- PASO 4 - ORDEN DE DISPARO: SENTENCIA Y FILA
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : instrumentar los cuatro momentos para verlos en vivo.
-- QUE DEBE OBSERVAR : los de sentencia se disparan UNA vez; los de fila, una
--                     vez POR CADA fila afectada.
-- RESULTADO ESPERADO: con un UPDATE que toca 2 filas veran 1 + 2 + 2 + 1 = 6
--                     lineas, en el orden BEFORE stmt, BEFORE row, AFTER row,
--                     AFTER stmt.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_orden_bs
BEFORE UPDATE ON trg_inscripcion
BEGIN
  DBMS_OUTPUT.PUT_LINE('1. BEFORE de SENTENCIA');
END;
/
CREATE OR REPLACE TRIGGER trg_orden_br
BEFORE UPDATE ON trg_inscripcion FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('2. BEFORE de FILA - inscripcion ' || :OLD.id_inscripcion);
END;
/
CREATE OR REPLACE TRIGGER trg_orden_ar
AFTER UPDATE ON trg_inscripcion FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('3. AFTER de FILA  - inscripcion ' || :OLD.id_inscripcion);
END;
/
CREATE OR REPLACE TRIGGER trg_orden_as
AFTER UPDATE ON trg_inscripcion
BEGIN
  DBMS_OUTPUT.PUT_LINE('4. AFTER de SENTENCIA');
END;
/

UPDATE trg_inscripcion SET estado = 'ACTIVA' WHERE id_asignatura = 55;
COMMIT;

-- se apagan para no ensuciar la salida de los pasos siguientes
ALTER TRIGGER trg_orden_bs DISABLE;
ALTER TRIGGER trg_orden_br DISABLE;
ALTER TRIGGER trg_orden_ar DISABLE;
ALTER TRIGGER trg_orden_as DISABLE;


--------------------------------------------------------------------------------
-- PASO 5 - FOLLOWS: ORDENAR DOS DISPARADORES DEL MISMO EVENTO
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : crear un segundo BEFORE INSERT que debe ejecutarse
--                     despues del primero.
-- QUE DEBE OBSERVAR : sin FOLLOWS, el orden entre dos disparadores del mismo
--                     evento NO esta definido. Nunca dependa del azar.
-- RESULTADO ESPERADO: la validacion ve el estado que ya asigno trg_inscripcion_bi.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_inscripcion_valida
BEFORE INSERT ON trg_inscripcion
FOR EACH ROW
FOLLOWS trg_inscripcion_bi
BEGIN
  IF :NEW.estado NOT IN ('PENDIENTE','ACTIVA') THEN
    RAISE_APPLICATION_ERROR(-20030, 'Estado no valido: ' || :NEW.estado);
  END IF;
  DBMS_OUTPUT.PUT_LINE('Validado con estado = ' || :NEW.estado);
END;
/
SHOW ERRORS

INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (104, 56);
COMMIT;

-- [ERROR PROVOCADO] estado no permitido
INSERT INTO trg_inscripcion (id_estudiante, id_asignatura, estado)
     VALUES (104, 57, 'CANCELADA');


--------------------------------------------------------------------------------
-- PASO 6 - INSTEAD OF: HACER ACTUALIZABLE UNA VISTA
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : crear una vista con dos joins e intentar actualizarla.
-- QUE DEBE OBSERVAR : primero falla con ORA-01779. Con el disparador INSTEAD
--                     OF, la misma sentencia funciona porque el disparador la
--                     traduce a la tabla base.
-- RESULTADO ESPERADO: el primer UPDATE falla; el segundo cambia la tabla base.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_trg_inscripcion_detalle AS
  SELECT i.id_inscripcion, i.estado, e.nombre, a.titulo
    FROM trg_inscripcion i
    JOIN trg_estudiante  e ON e.id_estudiante = i.id_estudiante
    JOIN trg_asignatura  a ON a.id_asignatura = i.id_asignatura;

SELECT * FROM v_trg_inscripcion_detalle ORDER BY id_inscripcion;

-- intento sin disparador
UPDATE v_trg_inscripcion_detalle SET titulo = 'Otro titulo' WHERE id_inscripcion = 1;

CREATE OR REPLACE TRIGGER trg_v_inscripcion_upd
INSTEAD OF UPDATE ON v_trg_inscripcion_detalle
FOR EACH ROW
BEGIN
  UPDATE trg_inscripcion
     SET estado = :NEW.estado
   WHERE id_inscripcion = :OLD.id_inscripcion;
END;
/
SHOW ERRORS

UPDATE v_trg_inscripcion_detalle SET estado = 'CERRADA' WHERE id_inscripcion = 1;
COMMIT;

SELECT id_inscripcion, estado FROM trg_inscripcion ORDER BY id_inscripcion;


--------------------------------------------------------------------------------
-- PASO 7 - [ERROR PROVOCADO] LA TABLA MUTANTE
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : validar el cupo consultando la misma tabla que se esta
--                     modificando.
-- QUE DEBE OBSERVAR : ORA-04091. No es un defecto del motor: es la garantia
--                     de que el disparador no vea un estado intermedio.
-- RESULTADO ESPERADO: el INSERT falla con
--                     ORA-04091: table ...TRG_INSCRIPCION is mutating.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_tope_cupo
BEFORE INSERT ON trg_inscripcion
FOR EACH ROW
DECLARE
  v_total NUMBER;
  v_max   NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total
    FROM trg_inscripcion WHERE id_asignatura = :NEW.id_asignatura;

  SELECT cupo_maximo INTO v_max
    FROM trg_asignatura WHERE id_asignatura = :NEW.id_asignatura;

  IF v_total >= v_max THEN
    RAISE_APPLICATION_ERROR(-20031, 'Cupo lleno en la asignatura ' || :NEW.id_asignatura);
  END IF;
END;
/
SHOW ERRORS

INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (102, 57);


--------------------------------------------------------------------------------
-- PASO 8 - EL DISPARADOR COMPUESTO RESUELVE EL CASO
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : recolectar las asignaturas afectadas en la seccion de
--                     fila y validar el cupo en la seccion de sentencia.
-- QUE DEBE OBSERVAR : en AFTER STATEMENT la tabla ya termino de cambiar, de
--                     modo que ahi si se puede consultar sin ORA-04091.
-- RESULTADO ESPERADO: el primer INSERT pasa; el que excede el cupo maximo
--                     falla con el error de negocio -20031, no con ORA-04091.
--------------------------------------------------------------------------------
DROP TRIGGER trg_tope_cupo;

CREATE OR REPLACE TRIGGER trg_tope_cupo
FOR INSERT ON trg_inscripcion
COMPOUND TRIGGER

  TYPE t_asignaturas IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_afectadas t_asignaturas;              -- estado compartido por toda la sentencia

  AFTER EACH ROW IS
  BEGIN
    v_afectadas(:NEW.id_asignatura) := 1; -- solo recolecta, no consulta la tabla
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_idx   PLS_INTEGER;
    v_total NUMBER;
    v_max   NUMBER;
  BEGIN
    v_idx := v_afectadas.FIRST;
    WHILE v_idx IS NOT NULL LOOP
      SELECT COUNT(*) INTO v_total
        FROM trg_inscripcion WHERE id_asignatura = v_idx;

      SELECT cupo_maximo INTO v_max
        FROM trg_asignatura WHERE id_asignatura = v_idx;

      IF v_total > v_max THEN
        RAISE_APPLICATION_ERROR(-20031,
          'Cupo excedido en la asignatura ' || v_idx ||
          ': ' || v_total || ' inscritos para un maximo de ' || v_max);
      END IF;

      v_idx := v_afectadas.NEXT(v_idx);
    END LOOP;
  END AFTER STATEMENT;

END trg_tope_cupo;
/
SHOW ERRORS

-- Sistemas Operativos (57) tiene cupo maximo 2 y hoy no tiene inscritos:
-- estas dos inscripciones deben pasar sin problema.
INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (102, 57);
INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (103, 57);
COMMIT;

SELECT id_asignatura, COUNT(*) AS inscritos
  FROM trg_inscripcion GROUP BY id_asignatura ORDER BY 1;

-- la tercera supera el cupo maximo y debe fallar con -20031, NO con ORA-04091
INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (104, 57);


--------------------------------------------------------------------------------
-- PASO 9 - DISPARADOR DE SISTEMA: AUDITAR DDL DEL ESQUEMA
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : registrar quien crea, altera o elimina objetos.
-- QUE DEBE OBSERVAR : los atributos ORA_SYSEVENT, ORA_DICT_OBJ_NAME y
--                     ORA_LOGIN_USER solo existen dentro de un disparador de
--                     sistema.
-- RESULTADO ESPERADO: al crear y borrar una tabla de prueba quedan dos filas.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audita_ddl
AFTER CREATE OR ALTER OR DROP ON SCHEMA
BEGIN
  INSERT INTO trg_auditoria_ddl (fecha, usuario, evento, objeto, tipo)
       VALUES (SYSTIMESTAMP, ORA_LOGIN_USER, ORA_SYSEVENT,
               ORA_DICT_OBJ_NAME, ORA_DICT_OBJ_TYPE);
END;
/
SHOW ERRORS

CREATE TABLE trg_prueba_ddl (id NUMBER);
DROP TABLE trg_prueba_ddl PURGE;

SELECT evento, objeto, tipo FROM trg_auditoria_ddl ORDER BY fecha;

-- En una entidad regulada este disparador suele ser la primera evidencia de
-- que alguien altero un objeto fuera de la ventana autorizada.


--------------------------------------------------------------------------------
-- PASO 10 - [ERROR PROVOCADO] COMMIT DENTRO DE UN DISPARADOR
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : intentar confirmar la transaccion desde el disparador.
-- QUE DEBE OBSERVAR : compila, pero falla al dispararse con ORA-04092. La
--                     transaccion pertenece a quien ejecuto el DML.
-- RESULTADO ESPERADO: ORA-04092: no se puede efectuar COMMIT en un disparador.
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_mal_commit
AFTER INSERT ON trg_inscripcion
FOR EACH ROW
BEGIN
  INSERT INTO trg_auditoria (fecha, usuario, operacion, detalle)
       VALUES (SYSTIMESTAMP, USER, 'INSERT', 'intento de commit');
  COMMIT;
END;
/
SHOW ERRORS

INSERT INTO trg_inscripcion (id_estudiante, id_asignatura) VALUES (104, 55);

-- CORRECCION: si el registro debe sobrevivir al ROLLBACK, se aisla en un
-- procedimiento con PRAGMA AUTONOMOUS_TRANSACTION, como se vio en el modulo 3.
DROP TRIGGER trg_mal_commit;


--------------------------------------------------------------------------------
-- PASO 11 - DICCIONARIO: QUE HAY ESCONDIDO EN UNA TABLA AJENA
--------------------------------------------------------------------------------
-- QUE VAMOS A HACER : inventariar los disparadores del esquema.
-- QUE DEBE OBSERVAR : TRIGGER_TYPE combina momento y alcance; STATUS indica si
--                     esta habilitado. TRIGGER_BODY guarda el codigo completo.
-- RESULTADO ESPERADO: la lista de los disparadores creados en esta practica.
--------------------------------------------------------------------------------
SELECT trigger_name, trigger_type, triggering_event, status
  FROM user_triggers
 WHERE table_name = 'TRG_INSCRIPCION'
 ORDER BY trigger_name;

SELECT trigger_name, status FROM user_triggers ORDER BY trigger_name;

SELECT name, line, text FROM user_errors WHERE type = 'TRIGGER' ORDER BY name, sequence;

-- reactivar los de orden, solo para comprobar el cambio de estado
ALTER TRIGGER trg_orden_bs ENABLE;
SELECT trigger_name, status FROM user_triggers WHERE trigger_name = 'TRG_ORDEN_BS';
ALTER TRIGGER trg_orden_bs DISABLE;


--------------------------------------------------------------------------------
-- EJERCICIOS PROPUESTOS
--------------------------------------------------------------------------------
-- EJERCICIO 1 - Auditoria de columna
--   Modifique TRG_INSCRIPCION_AUDITA para que registre solo cuando cambie la
--   columna ESTADO, y que guarde en DETALLE el valor anterior y el nuevo.
--   Pista: AFTER UPDATE OF estado mas la clausula WHEN.
--   Logrado si: un UPDATE sobre otra columna no genera ninguna fila de auditoria.
--
-- EJERCICIO 2 - Prohibir el borrado
--   Escriba un disparador que impida eliminar inscripciones en estado ACTIVA y
--   sugiera en el mensaje pasarlas a CERRADA.
--   Pista: BEFORE DELETE de fila con RAISE_APPLICATION_ERROR.
--   Logrado si: el DELETE de una inscripcion CERRADA funciona y el de una
--   ACTIVA falla con su mensaje propio.
--
-- EJERCICIO 3 - Vista actualizable completa
--   Agregue a la vista del PASO 6 los disparadores INSTEAD OF INSERT e
--   INSTEAD OF DELETE, resolviendo el estudiante y la asignatura por nombre.
--   Pista: busque los identificadores con SELECT ... INTO dentro del cuerpo.
--   Logrado si: puede insertar y borrar usando solo la vista.
--
-- EJERCICIO 4 - Del disparador a la restriccion
--   Escriba la regla del PASO 8 sin disparadores: agregue una columna
--   contadora en TRG_ASIGNATURA y mantengala con un procedimiento. Compare
--   ambas soluciones en tres lineas: legibilidad, rendimiento y riesgo.
--   Pista: piense que pasa si alguien inserta directamente sin usar el
--   procedimiento.
--   Logrado si: su comparacion menciona el punto anterior.
--
-- EJERCICIO 5 - Analisis de impacto
--   Mida cuanto tarda insertar 5000 filas con todos los disparadores activos y
--   con ellos deshabilitados. Use DBMS_UTILITY.GET_TIME.
--   Pista: ALTER TABLE trg_inscripcion DISABLE ALL TRIGGERS.
--   Logrado si: puede expresar la diferencia en porcentaje y explicar a que se
--   debe.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- LIMPIEZA - ejecute SOLO cuando haya terminado
--------------------------------------------------------------------------------
-- Los disparadores se eliminan antes que las tablas; el de esquema, aparte.
-- DROP TRIGGER trg_audita_ddl;
-- DROP VIEW v_trg_inscripcion_detalle;
-- DROP TABLE trg_inscripcion PURGE;
-- DROP TABLE trg_asignatura PURGE;
-- DROP TABLE trg_estudiante PURGE;
-- DROP TABLE trg_auditoria PURGE;
-- DROP TABLE trg_auditoria_ddl PURGE;
--------------------------------------------------------------------------------
