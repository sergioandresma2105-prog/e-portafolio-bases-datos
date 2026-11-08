-- =====================================================================
-- Bases de Datos 2 · Concurrencia, transacciones y bloqueos
-- 03_diagnostico.sql — ver los bloqueos mientras están ocurriendo
--
-- Estas consultas leen vistas V$. Con el usuario ADMIN de la Autonomous
-- Database funcionan siempre. Con los usuarios de la práctica pueden
-- fallar por permisos: en ese caso el docente las proyecta.
-- =====================================================================

SET LINESIZE 220
SET PAGESIZE 100

-- ---------------------------------------------------------------------
-- 1. La consulta que responde “¿quién me está bloqueando?”
-- ---------------------------------------------------------------------
SELECT s.sid,
       s.serial#,
       s.username,
       s.status,
       s.blocking_session        AS bloqueado_por,
       s.event,
       s.seconds_in_wait        AS segundos_esperando,
       s.sql_id
  FROM v$session s
 WHERE s.username LIKE 'P%'
 ORDER BY s.blocking_session NULLS FIRST, s.sid;
--> La sesión con BLOQUEADO_POR lleno es la víctima.
--  El valor de esa columna es el SID de quien la tiene detenida.


-- ---------------------------------------------------------------------
-- 2. El árbol de bloqueos, cuando hay varios encadenados
-- ---------------------------------------------------------------------
SELECT LPAD(' ', 2*(LEVEL-1)) || s.sid AS jerarquia,
       s.username, s.status, s.event, s.seconds_in_wait
  FROM v$session s
 START WITH s.blocking_session IS NULL
        AND s.sid IN (SELECT blocking_session FROM v$session
                       WHERE blocking_session IS NOT NULL)
CONNECT BY PRIOR s.sid = s.blocking_session
 ORDER SIBLINGS BY s.sid;
--> Muy útil cuando media aplicación se detiene: muestra la sesión raíz
--  que está deteniendo a todas las demás.


-- ---------------------------------------------------------------------
-- 3. Qué está bloqueado exactamente
-- ---------------------------------------------------------------------
SELECT l.sid,
       s.username,
       l.type,
       CASE l.type WHEN 'TX' THEN 'transacción (fila)'
                   WHEN 'TM' THEN 'tabla (DML)'
                   ELSE l.type END          AS significado,
       DECODE(l.lmode, 0,'ninguno', 1,'null', 2,'RS', 3,'RX',
                       4,'S', 5,'SRX', 6,'X (exclusivo)')  AS modo_que_tiene,
       DECODE(l.request, 0,'-', 1,'null', 2,'RS', 3,'RX',
                         4,'S', 5,'SRX', 6,'X (exclusivo)') AS modo_que_pide,
       o.object_name
  FROM v$lock l
  JOIN v$session s ON s.sid = l.sid
  LEFT JOIN dba_objects o ON o.object_id = l.id1 AND l.type = 'TM'
 WHERE s.username LIKE 'P%'
   AND l.type IN ('TX','TM')
 ORDER BY l.sid, l.type;
--> TX con modo X = tiene filas bloqueadas.
--  TX con request 6 = está esperando una fila de otro.
--  TM = bloqueo de tabla; aparece siempre que hay DML, y en modo fuerte
--  cuando falta el índice de una llave foránea.


-- ---------------------------------------------------------------------
-- 4. Transacciones abiertas y cuánto UNDO están gastando
-- ---------------------------------------------------------------------
SELECT s.sid, s.username,
       t.start_time,
       t.used_ublk  AS bloques_undo,
       t.used_urec  AS registros_undo,
       t.status
  FROM v$transaction t
  JOIN v$session s ON s.saddr = t.ses_addr
 WHERE s.username LIKE 'P%'
 ORDER BY t.start_time;
--> Una transacción abierta hace horas es casi siempre un error: alguien
--  olvidó el COMMIT, o dejó una pantalla abierta en medio de la
--  transacción. Es la causa clásica del “snapshot too old”.


-- ---------------------------------------------------------------------
-- 5. La sentencia que está ejecutando quien bloquea
-- ---------------------------------------------------------------------
SELECT s.sid, s.username, q.sql_text
  FROM v$session s
  JOIN v$sql q ON q.sql_id = s.prev_sql_id
 WHERE s.sid IN (SELECT blocking_session FROM v$session
                  WHERE blocking_session IS NOT NULL);
--> Ojo: se usa PREV_SQL_ID, no SQL_ID. Quien bloquea normalmente ya
--  terminó su sentencia y está inactivo, esperando un COMMIT que nadie
--  hizo.


-- ---------------------------------------------------------------------
-- 6. Cuántos interbloqueos ha habido
-- ---------------------------------------------------------------------
SELECT name, value FROM v$sysstat
 WHERE name IN ('enqueue deadlocks','enqueue waits','enqueue timeouts');


-- ---------------------------------------------------------------------
-- 7. Liberar una sesión atascada  (solo el docente, como ADMIN)
-- ---------------------------------------------------------------------
-- Primero identifique el sid y el serial# con la consulta 1, y luego:
--
--   ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;
--
-- En Autonomous Database también sirve:
--   BEGIN
--     DBMS_CLOUD_ADMIN... -- no aplica
--   END;
-- Use siempre ALTER SYSTEM KILL SESSION.
-- Matar la sesión deshace su transacción: el rollback puede tardar.
