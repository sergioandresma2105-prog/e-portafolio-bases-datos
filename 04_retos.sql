-- =====================================================================
-- Bases de Datos 2 · Concurrencia, transacciones y bloqueos
-- 04_retos.sql — para resolver en pareja, en los últimos 25 minutos
--
-- No hay respuestas en este archivo a propósito. Cada reto se entrega
-- con el SQL y una explicación de tres líneas.
-- =====================================================================

-- ---------------------------------------------------------------------
-- RETO 1 — La transferencia que no puede perder plata
-- ---------------------------------------------------------------------
-- Escriba una transferencia de 100.000 de la cuenta 1 a la cuenta 2 que
-- cumpla estas tres condiciones:
--   a) o se aplican los dos movimientos, o no se aplica ninguno
--   b) si el saldo origen no alcanza, no se hace nada y se avisa
--   c) si dos personas transfieren desde la misma cuenta al mismo
--      tiempo, no se puede quedar en negativo
-- Pruébenlo con las dos sesiones ejecutándolo a la vez.
--
-- Pista: ¿bloqueo pesimista o control de versión? Justifiquen la elección.


-- ---------------------------------------------------------------------
-- RETO 2 — El orden importa
-- ---------------------------------------------------------------------
-- Escriban DOS transferencias cruzadas (de la 1 a la 2, y de la 2 a la 1)
-- que provoquen un interbloqueo. Luego reescríbanlas para que sea
-- IMPOSIBLE que ocurra, sin usar NOWAIT ni SKIP LOCKED.
--
-- Pista: si las dos siempre bloquean primero la cuenta de menor id...


-- ---------------------------------------------------------------------
-- RETO 3 — La taquilla
-- ---------------------------------------------------------------------
-- Escriban el SQL que reserva "la primera silla libre" para un cliente,
-- de forma que dos taquilleros trabajando a la vez:
--   · nunca le asignen la misma silla a dos personas
--   · nunca se queden esperando el uno al otro
-- Midan qué pasa si en vez de su solución usan un SELECT simple seguido
-- de un UPDATE.


-- ---------------------------------------------------------------------
-- RETO 4 — El informe que no cuadra
-- ---------------------------------------------------------------------
-- La sesión A ejecuta, una detrás de otra:
--     SELECT SUM(saldo) FROM cuenta;
--     ... pasan 30 segundos ...
--     SELECT SUM(saldo) FROM cuenta;
-- Mientras tanto, B hace una transferencia entre dos cuentas y confirma.
-- ¿Pueden dar las dos sumas resultados distintos? ¿Por qué?
-- ¿Qué habría que hacer para que el informe completo vea una sola foto
-- coherente de toda la base?
--
-- Pista: hay dos maneras, y una de ellas no necesita bloquear nada.


-- ---------------------------------------------------------------------
-- RETO 5 — Diagnóstico
-- ---------------------------------------------------------------------
-- Provoquen un bloqueo a propósito y, sin preguntarle a la otra persona,
-- averigüen desde el diccionario:
--   · qué SID está bloqueado y cuánto lleva esperando
--   · qué SID lo está bloqueando
--   · qué tabla está involucrada
--   · qué sentencia ejecutó el que bloquea
-- Entreguen las consultas que usaron.
