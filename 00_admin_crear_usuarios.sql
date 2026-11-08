-- =====================================================================
-- Bases de Datos 2 · Concurrencia, transacciones y bloqueos
-- 00_admin_crear_usuarios.sql
--
-- LO EJECUTA EL DOCENTE, como ADMIN, en la Autonomous Database.
-- Crea un usuario por pareja, con permisos para crear sus propias
-- tablas y para entrar por Database Actions.
--
-- Ejecutar UNA sola vez, antes de la clase.
-- =====================================================================

SET SERVEROUTPUT ON
SET LINESIZE 200

-- ---------------------------------------------------------------------
-- Configuración: cuántas parejas y con qué contraseña
--   La política de Autonomous exige entre 12 y 30 caracteres,
--   al menos una mayúscula, una minúscula y un dígito, sin comillas.
-- ---------------------------------------------------------------------
DECLARE
  n_parejas   PLS_INTEGER := 15;
  v_usuario   VARCHAR2(30);
  v_clave     VARCHAR2(60);
BEGIN
  FOR i IN 1 .. n_parejas LOOP
    v_usuario := 'P' || TO_CHAR(i, 'FM00');
    v_clave   := 'Bosque2026_' || v_usuario;      -- ej: Bosque2026_P01

    -- Si el usuario ya existe, se elimina y se vuelve a crear
    BEGIN
      EXECUTE IMMEDIATE 'DROP USER ' || v_usuario || ' CASCADE';
      DBMS_OUTPUT.PUT_LINE('Recreando ' || v_usuario);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    EXECUTE IMMEDIATE 'CREATE USER ' || v_usuario ||
                      ' IDENTIFIED BY "' || v_clave || '"';
    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO ' || v_usuario;
    EXECUTE IMMEDIATE 'ALTER USER ' || v_usuario || ' QUOTA 200M ON DATA';

    -- Habilita el usuario en Database Actions (necesario en ADB para
    -- que pueda entrar por el navegador con su propio usuario)
    BEGIN
      ORDS_ADMIN.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => v_usuario,
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => LOWER(v_usuario),
        p_auto_rest_auth      => TRUE);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('  Aviso ORDS en ' || v_usuario || ': ' || SQLERRM);
    END;

    DBMS_OUTPUT.PUT_LINE('OK  ' || RPAD(v_usuario, 6) || '  clave: ' || v_clave);
  END LOOP;
  COMMIT;
END;
/

-- ---------------------------------------------------------------------
-- Permisos de monitoreo (opcional)
--   Permite que las parejas vean sus propios bloqueos. Si falla, no pasa
--   nada: el docente proyecta el monitoreo desde ADMIN.
-- ---------------------------------------------------------------------
DECLARE
  n_parejas PLS_INTEGER := 15;
  v_usuario VARCHAR2(30);
BEGIN
  FOR i IN 1 .. n_parejas LOOP
    v_usuario := 'P' || TO_CHAR(i, 'FM00');
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON SYS.V_$SESSION TO ' || v_usuario;
      EXECUTE IMMEDIATE 'GRANT SELECT ON SYS.V_$LOCK TO '    || v_usuario;
      EXECUTE IMMEDIATE 'GRANT SELECT ON SYS.V_$TRANSACTION TO ' || v_usuario;
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Sin permisos de V$ para ' || v_usuario ||
                           ' (el docente proyecta el monitoreo)');
    END;
  END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------
SELECT username, account_status, created
  FROM dba_users
 WHERE username LIKE 'P__'
 ORDER BY username;

PROMPT
PROMPT ======================================================================
PROMPT  Usuarios listos.  Reparta a cada pareja:
PROMPT    - la URL de Database Actions
PROMPT    - su usuario (P01, P02, ...) y su clave (Bosque2026_Pnn)
PROMPT  Cada pareja ejecuta luego 01_setup_pareja.sql
PROMPT ======================================================================
