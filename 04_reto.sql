-- =====================================================================
-- Bases de Datos 2 · Taller integrador — Banco Andino
-- 04_reto.sql   Reto final (25 minutos)
--
-- Trabajen en UNA SOLA CONEXIÓN: la pareja comparte el esquema.
-- Este es el ejercicio que se entrega.
-- Todo se resuelve con SQL. No se necesita PL/SQL.
-- =====================================================================

-- ---------------------------------------------------------------------
-- EL TICKET
--
--   De:    Gerencia de Operaciones, Banco Andino
--   Para:  Equipo de Base de Datos
--   Asunto: CRÍTICO — descuadres en transferencias
--
--   "Desde el puente festivo tenemos tres problemas:
--
--    1. La cuenta de compensación no cuadra. Hay días en que el total
--       debitado no coincide con el total acreditado, por montos
--       pequeños pero constantes. Contraloría ya abrió un caso.
--
--    2. Aparecieron transferencias donde al cliente le descontaron la
--       plata y nunca le llegó al destinatario. Otras al revés: llegó
--       al destino sin haber salido del origen. Nadie sabe cuántas son.
--
--    3. El tablero de la Vicepresidencia se demora casi un minuto en
--       abrir, y lo consultan cada media hora.
--
--    Adjunto la secuencia de sentencias que ejecuta el core cada vez
--    que se aplica una transferencia, y la consulta del tablero.
--    Necesitamos un diagnóstico y la corrección."
-- ---------------------------------------------------------------------


-- #####################################################################
-- PIEZA 1 — Lo que ejecuta el core al aplicar una transferencia
--
-- Caso real: la transferencia 950001, de la cuenta 1001 a la 1002,
-- por 300.000 pesos.
--
-- Ejecútelo tal como está y observe qué hace. NO lo corrija todavía.
-- #####################################################################

-- Deje las cuentas en un valor conocido antes de probar
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
COMMIT;

SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001,1002) ORDER BY id_cuenta;


--- inicio de lo que ejecuta el core -----------------------------------

-- 1. Débito del origen: la aplicación lee el saldo...
SELECT saldo FROM cuenta WHERE id_cuenta = 1001;
--> ...guarda ese número, le resta 300.000, y escribe el resultado:
UPDATE cuenta SET saldo = 700000 WHERE id_cuenta = 1001;
COMMIT;

-- 2. Crédito del destino: lo mismo al otro lado
SELECT saldo FROM cuenta WHERE id_cuenta = 1002;
--> ...le suma 300.000 y escribe:
UPDATE cuenta SET saldo = 1300000 WHERE id_cuenta = 1002;
COMMIT;

-- 3. Los dos movimientos contables
INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500001, 1001, 950001, SYSDATE, 'DEBITO', 300000);
COMMIT;

INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500002, 1002, 950001, SYSDATE, 'CREDITO', 300000);
COMMIT;

-- 4. Y al final marca la transferencia
UPDATE transferencia SET estado = 'APLICADA' WHERE id_transferencia = 950001;
COMMIT;

--- fin de lo que ejecuta el core --------------------------------------

SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001,1002) ORDER BY id_cuenta;


-- #####################################################################
-- PIEZA 2 — La consulta del tablero de la Vicepresidencia
-- #####################################################################

SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE TO_CHAR(t.fecha_transf, 'YYYY-MM') = '2026-03'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;


-- #####################################################################
-- LO QUE HAY QUE ENTREGAR
-- #####################################################################
--
-- A. DIAGNÓSTICO  (4 puntos)
--
--    Identifique CUATRO defectos en la secuencia de la PIEZA 1.
--    Para cada uno indique:
--      - qué sentencia o qué parte de la secuencia lo causa
--      - cuál de los tres síntomas del ticket produce
--      - qué pasa en producción con 12.000 transferencias por hora
--
--    Pista: uno es de concurrencia, uno es de transaccionalidad, uno
--    hace que el problema pase inadvertido, y uno es de rendimiento.
--
--    Dos de ellos hay que REPRODUCIRLOS, no solo describirlos:
--      - el de concurrencia: ejecuten la secuencia desde las DOS
--        conexiones sobre la misma cuenta y muestren el resultado
--      - el de transaccionalidad: simulen una falla después del débito
--        y antes del crédito, y muestren el estado en que quedan las
--        dos cuentas y la transferencia
--
--
-- B. CORRECCIÓN  (4 puntos)
--
--    Reescriba la secuencia usando SQL. Debe cumplir las cinco cosas:
--      1. que dos operaciones simultáneas sobre la misma cuenta no
--         puedan perder dinero
--      2. que sea atómica: el débito, el crédito, los dos movimientos y
--         el cambio de estado ocurren todos, o no ocurre ninguno
--      3. que se note cuando algo no se aplicó, en lugar de pasar en
--         silencio
--      4. que no permita dejar una cuenta en saldo negativo
--      5. que dos transferencias cruzadas simultáneas (1001->1002 y
--         1002->1001) NO puedan provocar un interbloqueo
--
--    El punto 5 es el que distingue este caso: no basta con bloquear,
--    hay que bloquear EN UN ORDEN DETERMINISTA.
--
--    Dispone de las herramientas que ya vieron hoy:
--      - SELECT ... FOR UPDATE con ORDER BY   (parte 1)
--      - UPDATE ... SET col = col +/- n
--      - un solo COMMIT al final, o ROLLBACK
--      - la restricción CHECK que ya tiene la tabla CUENTA
--
--    Demuéstrelo: ejecute su versión desde las DOS conexiones al mismo
--    tiempo, en sentidos cruzados, y muestre que no hay ORA-00060 y que
--    los saldos cuadran. Documente cómo lo probó.
--
--
-- C. OPTIMIZACIÓN DE LA CONSULTA  (1 punto)
--
--      - Capture el plan actual y anote COST y consistent gets
--      - Identifique qué impide el uso del índice
--      - Reescriba la consulta y/o cree el índice necesario
--      - Capture el plan nuevo y anote la mejora
--      - Justifique el índice: qué consulta lo usa y por qué no bastaba
--        con los que ya existen
--
--
-- D. UNA RECOMENDACIÓN  (1 punto)
--
--    En un párrafo dirigido a la Gerencia de Operaciones: ¿qué práctica
--    debe cambiar el banco para que este problema no vuelva a aparecer?
--    No hable de esta consulta ni de estas sentencias: hable de la
--    organización. Considere que el descuadre existió durante semanas
--    antes de que alguien lo notara.
--
--
-- FORMATO DE ENTREGA
--   Un archivo .sql con la secuencia corregida y la consulta optimizada,
--   más un documento corto con las respuestas a A y D y las capturas de
--   los planes de ejecución del punto C.
-- #####################################################################


-- ---------------------------------------------------------------------
-- Zona de trabajo: escriba aquí su versión corregida
-- ---------------------------------------------------------------------

-- Sugerencia de estructura, para que no se pierdan:
--
--   1. Bloquee las DOS cuentas en una sola sentencia, ordenadas por
--      id_cuenta. Ese ORDER BY es lo que elimina el interbloqueo.
--   2. Debite el origen y acredite el destino, siempre sobre el valor
--      actual de la fila, nunca sobre un número leído antes.
--   3. Inserte los dos movimientos.
--   4. Cambie el estado de la transferencia, condicionado al estado
--      esperado.
--   5. Revise cuántas filas afectó cada sentencia antes de confirmar.
--   6. Un solo COMMIT al final; si algo salió mal, ROLLBACK.
