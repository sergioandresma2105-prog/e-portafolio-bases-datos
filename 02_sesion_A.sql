-- =====================================================================
-- Bases de Datos 2 · Concurrencia, transacciones y bloqueos
-- 02_sesion_A.sql          >>>  VENTANA A  <<<
--
-- NO ejecute este archivo de corrido. Cada bloque dice PASO n:
-- ejecútelo cuando le toque, alternando con la ventana B.
--
-- Verifique primero que el autocommit está APAGADO.
-- =====================================================================

-- Quién soy
SELECT 'SESIÓN A' AS ventana, SYS_CONTEXT('USERENV','SID') AS sid FROM dual;


-- #####################################################################
-- EJERCICIO 1 — Lectura consistente: los lectores no se bloquean
-- #####################################################################

-- PASO 1  (A)
SELECT id_cuenta, titular, saldo FROM cuenta ORDER BY id_cuenta;

-- PASO 2  (A)  Retiro 200.000 de la cuenta 1, SIN confirmar
UPDATE cuenta SET saldo = saldo - 200000 WHERE id_cuenta = 1;
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1;
--> A ve 800.000: dentro de su transacción, ve sus propios cambios.

-- ... ahora vaya a la ventana B, PASO 3 ...

-- PASO 5  (A)  Confirmo
COMMIT;

-- ... ventana B, PASO 6 ...

-- CONCLUSIÓN DEL EJERCICIO 1
--   B nunca se bloqueó y nunca vio el saldo a medias. Vio el valor
--   anterior hasta que A confirmó. Eso es la lectura consistente:
--   Oracle reconstruye la versión de los datos desde el UNDO.
--   En Oracle, los lectores NO bloquean a los escritores ni al revés.


-- #####################################################################
-- EJERCICIO 2 — Bloqueo de fila y actualización perdida
-- #####################################################################

-- PASO 1  (A)
UPDATE cuenta SET saldo = saldo - 100000 WHERE id_cuenta = 2;
--> Responde de inmediato: A tomó el bloqueo de esa fila.

-- ... ventana B, PASO 2: intenta actualizar la MISMA fila y se queda esperando ...

-- PASO 4  (A)  Mientras B espera, mire quién bloquea a quién:
--   (si no tiene permisos sobre V$, lo proyecta el docente)
SELECT sid, serial#, status, blocking_session, event, seconds_in_wait
  FROM v$session
 WHERE username = USER
 ORDER BY sid;

-- PASO 5  (A)  Libero
COMMIT;

-- ... ventana B, PASO 6 ...

-- PASO 8  (A)  ¿Cuánto quedó?
SELECT id_cuenta, titular, saldo FROM cuenta WHERE id_cuenta = 2;
--> Empezó en 500.000. A restó 100.000 y B restó 50.000.
--  ¿Quedó en 350.000, o en 450.000? Discútanlo antes de mirar.


-- #####################################################################
-- EJERCICIO 3 — Evitar la actualización perdida
-- #####################################################################

-- --- 3.a  Estrategia PESIMISTA: bloqueo explícito con FOR UPDATE ---

-- PASO 1  (A)
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3 FOR UPDATE;
--> Leo Y bloqueo. Nadie más podrá tocar esta fila hasta mi COMMIT.

-- ... ventana B, PASO 2 ...

-- PASO 4  (A)
UPDATE cuenta SET saldo = saldo - 50000 WHERE id_cuenta = 3;
COMMIT;

-- ... ventana B, PASO 5 ...


-- --- 3.b  Estrategia OPTIMISTA: número de versión ---
-- Nadie bloquea nada; se detecta el choque al escribir.

-- PASO 6  (A)  Leo el saldo y la versión
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1;
--> Anote el número de version que ve.  Suponga que es 0.

-- ... ventana B, PASO 7: lee la misma fila y actualiza primero ...

-- PASO 9  (A)  Intento actualizar con la versión que leí
UPDATE cuenta
   SET saldo   = saldo - 30000,
       version = version + 1
 WHERE id_cuenta = 1
   AND version  = 0;          -- <-- la versión que leí en el PASO 6
COMMIT;

SELECT 'Filas afectadas: ver el mensaje del UPDATE' AS nota FROM dual;
--> Si dice "0 filas actualizadas", alguien cambió la fila entre mi
--  lectura y mi escritura. La aplicación debe releer y reintentar,
--  o avisarle al usuario. Nada se perdió en silencio.

SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1;


-- #####################################################################
-- EJERCICIO 4 — FOR UPDATE: NOWAIT, WAIT y SKIP LOCKED
-- #####################################################################

-- PASO 1  (A)  Reservo la silla 5 y me quedo con el bloqueo
SELECT id_silla, fila, numero, estado FROM silla WHERE id_silla = 5 FOR UPDATE;

-- ... ventana B, PASOS 2, 3 y 4 ...

-- PASO 5  (A)  Confirmo y libero
UPDATE silla SET estado = 'RESERVADA', reservada_por = 'Sesión A' WHERE id_silla = 5;
COMMIT;

-- PASO 6  (A)  La cola de trabajos: dos operarios sin pisarse
--   SKIP LOCKED ignora las filas que otro ya tiene bloqueadas.
SELECT id_trabajo, payload
  FROM trabajo
 WHERE estado = 'PENDIENTE'
 ORDER BY id_trabajo
 FETCH FIRST 3 ROWS ONLY
   FOR UPDATE SKIP LOCKED;

-- ... ventana B, PASO 7: pide otros 3 y recibe trabajos DISTINTOS ...

-- PASO 8  (A)
UPDATE trabajo SET estado='PROCESADO', procesado_por='A'
 WHERE id_trabajo IN (SELECT id_trabajo FROM trabajo
                       WHERE estado='PENDIENTE' AND ROWNUM <= 0);
-- (en la práctica se actualizan los ids que devolvió el SELECT anterior)
COMMIT;


-- #####################################################################
-- EJERCICIO 5 — Interbloqueo (deadlock)
-- #####################################################################

-- PASO 1  (A)  Bloqueo la cuenta 1
UPDATE cuenta SET saldo = saldo - 1000 WHERE id_cuenta = 1;

-- ... ventana B, PASO 2: bloquea la cuenta 2 ...

-- PASO 3  (A)  Ahora pido la cuenta 2, que B tiene tomada  -> me quedo esperando
UPDATE cuenta SET saldo = saldo + 1000 WHERE id_cuenta = 2;

-- ... ventana B, PASO 4: pide la cuenta 1, que yo tengo -> ciclo cerrado ...

--> A los pocos segundos, UNA de las dos sesiones recibe:
--     ORA-00060: deadlock detected while waiting for resource
--  Oracle detecta el ciclo y sacrifica una de las dos sentencias.
--  La transacción NO se deshace entera: solo esa sentencia. La sesión
--  víctima queda con su transacción abierta y debe decidir.

-- PASO 5  (A)  Deshago todo
ROLLBACK;

-- CÓMO SE EVITA
--   Accediendo a los recursos SIEMPRE en el mismo orden. Si las dos
--   sesiones hubieran tomado primero la cuenta 1 y después la 2, no
--   habría ciclo posible.


-- #####################################################################
-- EJERCICIO 6 — SAVEPOINT y el COMMIT implícito del DDL
-- #####################################################################

-- PASO 1  (A)
INSERT INTO asiento VALUES (1, 'Asiento uno', 100);
SAVEPOINT despues_del_uno;

INSERT INTO asiento VALUES (2, 'Asiento dos', 200);
INSERT INTO asiento VALUES (3, 'Asiento tres', 300);
SELECT * FROM asiento ORDER BY id_asiento;      --> 3 filas

ROLLBACK TO SAVEPOINT despues_del_uno;
SELECT * FROM asiento ORDER BY id_asiento;      --> queda 1 fila
--> El rollback parcial deshace hasta el savepoint, no toda la transacción.
--  La transacción sigue abierta.

-- PASO 2  (A)  LA TRAMPA: una sentencia DDL confirma sola
CREATE TABLE basura_temporal (x NUMBER);
--> Ese CREATE hizo COMMIT de todo lo que había pendiente.

ROLLBACK;
SELECT * FROM asiento ORDER BY id_asiento;
--> El asiento 1 sigue ahí: el ROLLBACK ya no tenía nada que deshacer.
--  Regla: nunca mezcle DDL dentro de una transacción de negocio.

DROP TABLE basura_temporal PURGE;


-- #####################################################################
-- EJERCICIO 7 — Nivel de aislamiento SERIALIZABLE
-- #####################################################################

-- PASO 1  (A)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3;
--> A partir de aquí, A ve una foto congelada del momento en que empezó.

-- ... ventana B, PASO 2: modifica la cuenta 3 y confirma ...

-- PASO 3  (A)  Vuelvo a leer
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3;
--> Sigo viendo el valor viejo, aunque B ya confirmó. Es lo que
--  distingue SERIALIZABLE de READ COMMITTED: la foto no cambia.

-- PASO 4  (A)  Ahora intento escribir sobre esa fila
UPDATE cuenta SET saldo = saldo - 1 WHERE id_cuenta = 3;
--> ORA-08177: can't serialize access for this transaction
--  Oracle no puede garantizar la serialización y aborta. La aplicación
--  tiene que reintentar la transacción desde el principio.

ROLLBACK;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- volvemos al valor por defecto


-- #####################################################################
-- EJERCICIO 8 (opcional) — Llave foránea sin índice
-- #####################################################################
-- MOVIMIENTO tiene una FK a CUENTA y esa columna NO está indexada.

-- PASO 1  (A)
INSERT INTO movimiento (id_cuenta, concepto, valor) VALUES (2, 'Prueba', 100);

-- ... ventana B, PASO 2: intenta BORRAR la cuenta 3, que no tiene nada que ver ...
--> B se bloquea. Sin índice sobre la FK, Oracle toma un bloqueo de
--  TABLA sobre el hijo al tocar el padre.

-- PASO 3  (A)
COMMIT;

-- PASO 4  (A)  Se arregla creando el índice que faltaba
CREATE INDEX ix_mov_cuenta ON movimiento (id_cuenta);
--> Repita el ejercicio: ahora B no se bloquea.
--  Moraleja: toda llave foránea con borrados o actualizaciones en el
--  padre necesita su índice.
