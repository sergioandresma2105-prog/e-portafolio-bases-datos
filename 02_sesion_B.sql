-- =====================================================================
-- Bases de Datos 2 · Concurrencia, transacciones y bloqueos
-- 02_sesion_B.sql          >>>  VENTANA B  <<<
--
-- NO ejecute este archivo de corrido. Cada bloque dice PASO n:
-- ejecútelo cuando le toque, alternando con la ventana A.
--
-- Verifique primero que el autocommit está APAGADO.
-- =====================================================================

-- Quién soy
SELECT 'SESIÓN B' AS ventana, SYS_CONTEXT('USERENV','SID') AS sid FROM dual;


-- #####################################################################
-- EJERCICIO 1 — Lectura consistente
-- #####################################################################

-- ... espere a que A haga sus PASOS 1 y 2 ...

-- PASO 3  (B)  A ya restó 200.000 pero NO ha confirmado
SELECT id_cuenta, titular, saldo FROM cuenta WHERE id_cuenta = 1;
--> B ve 1.000.000, el valor anterior. No se bloqueó y no vio el cambio
--  sin confirmar. Oracle nunca permite una lectura sucia.

-- PASO 4  (B)  Compruebe que la consulta ni siquiera esperó
SELECT COUNT(*) AS filas_visibles FROM cuenta WHERE saldo >= 1000000;

-- ... A hace COMMIT en su PASO 5 ...

-- PASO 6  (B)  Vuelvo a leer
SELECT id_cuenta, titular, saldo FROM cuenta WHERE id_cuenta = 1;
--> Ahora sí veo 800.000. Ese cambio de respuesta dentro de la misma
--  sesión se llama lectura no repetible, y es lo que READ COMMITTED
--  permite a propósito.


-- #####################################################################
-- EJERCICIO 2 — Bloqueo de fila y actualización perdida
-- #####################################################################

-- ... A hizo su PASO 1 y tiene bloqueada la cuenta 2 ...

-- PASO 2  (B)  Intento actualizar LA MISMA fila
UPDATE cuenta SET saldo = saldo - 50000 WHERE id_cuenta = 2;
--> ESTA SENTENCIA NO RESPONDE. Queda esperando el bloqueo de A.
--  Déjela corriendo y observe. No la cancele.

-- PASO 3  (B)  Desde otra pestaña, o pídale a A el PASO 4:
--   mire cómo se ve el bloqueo desde el diccionario.

-- ... A hace COMMIT en su PASO 5: aquí su UPDATE se destraba solo ...

-- PASO 6  (B)  Ya respondió. Confirmo
COMMIT;

-- PASO 7  (B)
SELECT id_cuenta, titular, saldo FROM cuenta WHERE id_cuenta = 2;
--> 500.000 - 100.000 - 50.000 = 350.000.
--  Aquí NO hubo actualización perdida porque los dos escribieron
--  "saldo = saldo - X": Oracle releyó el valor al destrabarse.
--
--  PERO si los dos hubieran hecho:  saldo = 400000   (un valor calculado
--  en la aplicación a partir de una lectura previa), el segundo habría
--  pisado al primero y los 100.000 de A habrían desaparecido sin dejar
--  rastro. Eso es la actualización perdida.


-- #####################################################################
-- EJERCICIO 3 — Evitar la actualización perdida
-- #####################################################################

-- --- 3.a  PESIMISTA ---

-- ... A hizo SELECT ... FOR UPDATE sobre la cuenta 3 ...

-- PASO 2  (B)  Intento leer con intención de escribir
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3 FOR UPDATE;
--> Se bloquea. A tiene la fila reservada.

-- PASO 3  (B)  Pero una lectura normal SÍ pasa:
--   (ejecútelo mentalmente o en una tercera ventana)
--   SELECT saldo FROM cuenta WHERE id_cuenta = 3;   --> responde de inmediato

-- ... A hace UPDATE y COMMIT en su PASO 4 ...

-- PASO 5  (B)  Mi SELECT FOR UPDATE ya respondió, con el saldo NUEVO
UPDATE cuenta SET saldo = saldo - 25000 WHERE id_cuenta = 3;
COMMIT;
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3;
--> Nadie perdió nada. El costo: B estuvo detenido todo ese tiempo.


-- --- 3.b  OPTIMISTA ---

-- ... A leyó saldo y version de la cuenta 1 en su PASO 6 ...

-- PASO 7  (B)  Leo lo mismo y actualizo PRIMERO
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1;

UPDATE cuenta
   SET saldo   = saldo - 10000,
       version = version + 1
 WHERE id_cuenta = 1
   AND version  = 0;          -- la versión que acabo de leer
COMMIT;
--> 1 fila actualizada: gané la carrera. La versión pasó de 0 a 1.

-- PASO 8  (B)
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1;

-- ... A intenta su UPDATE con version = 0 y actualiza 0 filas ...
--> Nadie se bloqueó en ningún momento, y aun así no se perdió nada.
--  Ese es el trato del bloqueo optimista: cero espera, a cambio de
--  tener que reintentar cuando hay choque.


-- #####################################################################
-- EJERCICIO 4 — FOR UPDATE: NOWAIT, WAIT y SKIP LOCKED
-- #####################################################################

-- ... A tiene bloqueada la silla 5 ...

-- PASO 2  (B)  Sin esperar nada
SELECT id_silla, estado FROM silla WHERE id_silla = 5 FOR UPDATE NOWAIT;
--> ORA-00054: resource busy and acquire with NOWAIT specified
--  Falla al instante en vez de quedarse colgado. Es lo que quiere una
--  pantalla web: avisarle al usuario, no dejarlo esperando.

-- PASO 3  (B)  Esperar, pero con límite
SELECT id_silla, estado FROM silla WHERE id_silla = 5 FOR UPDATE WAIT 5;
--> Espera 5 segundos y luego ORA-30006. Un término medio razonable.

-- PASO 4  (B)  Sáltese las ocupadas y deme cualquier otra libre
SELECT id_silla, fila, numero
  FROM silla
 WHERE estado = 'LIBRE'
 ORDER BY id_silla
 FETCH FIRST 3 ROWS ONLY
   FOR UPDATE SKIP LOCKED;
--> Devuelve sillas, saltándose la 5 que A tiene tomada. Nunca espera.

ROLLBACK;

-- ... A confirma su reserva en el PASO 5 ...

-- PASO 7  (B)  La cola de trabajos: pido otros tres
SELECT id_trabajo, payload
  FROM trabajo
 WHERE estado = 'PENDIENTE'
 ORDER BY id_trabajo
 FETCH FIRST 3 ROWS ONLY
   FOR UPDATE SKIP LOCKED;
--> Son trabajos DISTINTOS a los que tomó A. Así se reparte una cola
--  entre varios procesos sin coordinador y sin bloqueos.

COMMIT;


-- #####################################################################
-- EJERCICIO 5 — Interbloqueo (deadlock)
-- #####################################################################

-- ... A bloqueó la cuenta 1 en su PASO 1 ...

-- PASO 2  (B)  Bloqueo la cuenta 2
UPDATE cuenta SET saldo = saldo - 1000 WHERE id_cuenta = 2;

-- ... A pide la cuenta 2 en su PASO 3 y se queda esperando ...

-- PASO 4  (B)  Ahora yo pido la cuenta 1, que A tiene tomada
UPDATE cuenta SET saldo = saldo + 1000 WHERE id_cuenta = 1;
--> Ciclo cerrado: A espera a B y B espera a A.
--  En unos segundos, una de las dos recibe ORA-00060.

ROLLBACK;

-- Después del ejercicio, revise el rastro que dejó (lo hace el docente
-- desde ADMIN, o usted si tiene permisos):
--   SELECT name, value FROM v$sysstat WHERE name LIKE '%deadlock%';
-- Oracle además escribe un archivo de traza con el grafo del ciclo.


-- #####################################################################
-- EJERCICIO 6 — SAVEPOINT y DDL
-- #####################################################################
-- Este ejercicio lo hace la sesión A sola. Acompáñela y discutan por qué
-- el ROLLBACK final no deshizo nada.


-- #####################################################################
-- EJERCICIO 7 — SERIALIZABLE
-- #####################################################################

-- ... A entró en SERIALIZABLE y leyó la cuenta 3 en su PASO 1 ...

-- PASO 2  (B)  Modifico y confirmo
UPDATE cuenta SET saldo = saldo + 5000 WHERE id_cuenta = 3;
COMMIT;
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 3;
--> B ve el valor nuevo. A, en su foto congelada, sigue viendo el viejo.

-- ... A vuelve a leer (sigue viendo el viejo) y luego intenta escribir:
--     ahí recibe ORA-08177 ...


-- #####################################################################
-- EJERCICIO 8 (opcional) — Llave foránea sin índice
-- #####################################################################

-- ... A insertó un movimiento de la cuenta 2 y NO confirmó ...

-- PASO 2  (B)  Intento borrar la cuenta 3, que no tiene movimientos
DELETE FROM cuenta WHERE id_cuenta = 3;
--> SE BLOQUEA, aunque estoy tocando OTRA cuenta.
--  Sin índice sobre MOVIMIENTO.id_cuenta, Oracle protege la integridad
--  tomando un bloqueo de TABLA sobre el hijo.

-- ... A confirma en su PASO 3: aquí se destraba ...

ROLLBACK;

-- ... A crea el índice en su PASO 4 y repiten el ejercicio: ya no bloquea.
