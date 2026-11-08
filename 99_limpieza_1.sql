-- =====================================================================
-- Tipos de índices en Oracle
-- 99_limpieza.sql — deja el esquema como estaba
-- =====================================================================
SET SERVEROUTPUT ON

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
             WHERE table_name IN ('VENTA','VENTA_PART','CLIENTE','PRODUCTO',
                                  'SUCURSAL','TICKET_IOT','AUDITORIA',
                                  'CARGA_SIN_IDX','CARGA_CON_IDX')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('Eliminada: '||t.table_name);
  END LOOP;
  FOR sq IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name = 'SEQ_AUDITORIA') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||sq.sequence_name;
  END LOOP;
END;
/

PURGE RECYCLEBIN;
SELECT table_name FROM user_tables ORDER BY 1;
