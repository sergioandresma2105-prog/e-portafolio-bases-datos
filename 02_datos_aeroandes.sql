-- ============================================================================
--  Universidad El Bosque  |  Bases de Datos 2
--  Quiz 2 - SQL Avanzado en Oracle: Joins, Subconsultas, CTE y Funciones
--  Esquema de practica: Aerolinea AeroAndes
--  Motor: Oracle Database 19c
-- ----------------------------------------------------------------------------
--  02_datos_aeroandes.sql  -  Carga de datos de prueba
-- ============================================================================


-- Ejecutar despues de 01_ddl_aeroandes.sql
-- Los datos estan construidos para que cada defecto del quiz sea observable
-- y para que cada consulta de la solucion devuelva un resultado no trivial.

SET DEFINE OFF;

-- ---------------------------------------------------------------------------
-- AEROPUERTO
-- ---------------------------------------------------------------------------
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('BOG', 'Bogota', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('MDE', 'Medellin', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('CTG', 'Cartagena', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('CLO', 'Cali', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('BAQ', 'Barranquilla', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('SMR', 'Santa Marta', 'Colombia');
INSERT INTO aeropuerto (cod_aeropuerto, ciudad, pais) VALUES ('PEI', 'Pereira', 'Colombia');

-- ---------------------------------------------------------------------------
-- AERONAVE
-- ---------------------------------------------------------------------------
INSERT INTO aeronave (id_aeronave, modelo, capacidad) VALUES (1, 'Airbus A320', 180);
INSERT INTO aeronave (id_aeronave, modelo, capacidad) VALUES (2, 'ATR 72-600', 70);
INSERT INTO aeronave (id_aeronave, modelo, capacidad) VALUES (3, 'Boeing 737-800', 189);

-- ---------------------------------------------------------------------------
-- PASAJERO
--   Primero se insertan todos con referido nulo y luego se actualizan los
--   referidos, para no depender del orden de insercion en la autorreferencia.
--   Referidores (pasajeros que aparecen como id_pasajero_referido de otro):
--   3, 11 y 25. Son los que la Pregunta 1 debe excluir del calculo.
-- ---------------------------------------------------------------------------
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (1, 'Ana Ramirez', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (2, 'Carlos Beltran', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (3, 'Diana Osorio', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (4, 'Esteban Nieto', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (5, 'Felipe Cardona', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (6, 'Gabriela Suarez', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (7, 'Hector Molina', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (8, 'Irene Pardo', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (9, 'Javier Quintero', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (10, 'Karla Mendez', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (11, 'Luis Arango', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (12, 'Marcela Vega', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (13, 'Nicolas Rojas', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (14, 'Olga Trujillo', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (15, 'Pablo Herrera', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (16, 'Quintin Salas', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (17, 'Rocio Bermudez', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (18, 'Samuel Duarte', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (19, 'Tatiana Lozano', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (20, 'Ulises Pena', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (21, 'Valeria Castro', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (22, 'William Gomez', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (23, 'Ximena Rivas', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (24, 'Yesid Camargo', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (25, 'Zulma Bautista', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (26, 'Andres Cifuentes', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (27, 'Beatriz Nunez', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (28, 'Camilo Espinosa', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (29, 'Daniela Forero', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (30, 'Emilio Vargas', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (31, 'Fabiola Restrepo', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (32, 'German Acosta', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (33, 'Helena Cortes', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (34, 'Ivan Mosquera', 'Cartagena', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (35, 'Julia Peralta', 'Barranquilla', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (36, 'Kevin Serrano', 'Pereira', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (37, 'Laura Buitrago', 'Bogota', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (38, 'Mateo Zapata', 'Medellin', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (39, 'Natalia Chaves', 'Cali', NULL);
INSERT INTO pasajero (id_pasajero, nombre, ciudad_residencia, id_pasajero_referido) VALUES (40, 'Oscar Rincon', 'Cartagena', NULL);

UPDATE pasajero SET id_pasajero_referido = 3 WHERE id_pasajero = 7;
UPDATE pasajero SET id_pasajero_referido = 3 WHERE id_pasajero = 12;
UPDATE pasajero SET id_pasajero_referido = 11 WHERE id_pasajero = 19;
UPDATE pasajero SET id_pasajero_referido = 11 WHERE id_pasajero = 26;
UPDATE pasajero SET id_pasajero_referido = 25 WHERE id_pasajero = 33;
UPDATE pasajero SET id_pasajero_referido = 25 WHERE id_pasajero = 38;

-- ---------------------------------------------------------------------------
-- VUELO
-- ---------------------------------------------------------------------------
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1001, 'AA200', DATE '2026-01-06', 'BOG', 'MDE', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1002, 'AA201', DATE '2026-01-21', 'BOG', 'MDE', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1003, 'AA202', DATE '2026-02-06', 'BOG', 'MDE', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1004, 'AA203', DATE '2026-02-21', 'BOG', 'MDE', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1005, 'AA204', DATE '2026-03-06', 'BOG', 'MDE', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1006, 'AA205', DATE '2026-03-21', 'BOG', 'MDE', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1007, 'AA206', DATE '2026-04-06', 'BOG', 'MDE', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1008, 'AA207', DATE '2026-04-21', 'BOG', 'MDE', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1009, 'AA300', DATE '2026-01-06', 'BOG', 'CTG', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1010, 'AA301', DATE '2026-01-21', 'BOG', 'CTG', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1011, 'AA302', DATE '2026-02-06', 'BOG', 'CTG', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1012, 'AA303', DATE '2026-02-21', 'BOG', 'CTG', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1013, 'AA304', DATE '2026-03-06', 'BOG', 'CTG', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1014, 'AA305', DATE '2026-03-21', 'BOG', 'CTG', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1015, 'AA306', DATE '2026-04-06', 'BOG', 'CTG', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1016, 'AA307', DATE '2026-04-21', 'BOG', 'CTG', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1017, 'AA400', DATE '2026-01-06', 'BOG', 'CLO', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1018, 'AA401', DATE '2026-01-21', 'BOG', 'CLO', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1019, 'AA402', DATE '2026-02-06', 'BOG', 'CLO', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1020, 'AA403', DATE '2026-02-21', 'BOG', 'CLO', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1021, 'AA404', DATE '2026-03-06', 'BOG', 'CLO', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1022, 'AA405', DATE '2026-03-21', 'BOG', 'CLO', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1023, 'AA406', DATE '2026-04-06', 'BOG', 'CLO', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1024, 'AA500', DATE '2026-01-06', 'BOG', 'BAQ', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1025, 'AA502', DATE '2026-02-06', 'BOG', 'BAQ', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1026, 'AA503', DATE '2026-02-21', 'BOG', 'BAQ', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1027, 'AA504', DATE '2026-03-06', 'BOG', 'BAQ', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1028, 'AA505', DATE '2026-03-21', 'BOG', 'BAQ', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1029, 'AA506', DATE '2026-04-06', 'BOG', 'BAQ', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1030, 'AA600', DATE '2026-01-06', 'MDE', 'CTG', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1031, 'AA601', DATE '2026-01-21', 'MDE', 'CTG', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1032, 'AA602', DATE '2026-02-06', 'MDE', 'CTG', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1033, 'AA606', DATE '2026-04-06', 'MDE', 'CTG', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1034, 'AA702', DATE '2026-02-06', 'CLO', 'SMR', 3);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1035, 'AA704', DATE '2026-03-06', 'CLO', 'SMR', 1);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1036, 'AA705', DATE '2026-03-21', 'CLO', 'SMR', 2);
INSERT INTO vuelo (id_vuelo, num_vuelo, fecha_salida, cod_origen, cod_destino, id_aeronave) VALUES (1037, 'AA706', DATE '2026-04-06', 'CLO', 'SMR', 3);

-- ---------------------------------------------------------------------------
-- INCIDENCIA
--   Hay vuelos con 0, 1, 2 y 3 incidencias. Los vuelos con varias son los que
--   provocan la multiplicacion de filas en la consulta defectuosa.
-- ---------------------------------------------------------------------------
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1002, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1002, 'METEOROLOGIA', 40);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1002, 'MANTENIMIENTO', 60);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1003, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1005, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1005, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1007, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1010, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1010, 'METEOROLOGIA', 40);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1011, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1011, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1011, 'MANTENIMIENTO', 55);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1013, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1016, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1017, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1017, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1020, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1020, 'METEOROLOGIA', 40);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1020, 'MANTENIMIENTO', 60);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1021, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1024, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1026, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1026, 'METEOROLOGIA', 40);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1026, 'MANTENIMIENTO', 60);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1027, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1029, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1029, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1031, 'RETRASO OPERATIVO', 20);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1034, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1034, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1035, 'RETRASO OPERATIVO', 15);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1035, 'METEOROLOGIA', 35);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1035, 'MANTENIMIENTO', 55);
INSERT INTO incidencia (id_vuelo, tipo, minutos_retraso) VALUES (1037, 'RETRASO OPERATIVO', 15);

-- ---------------------------------------------------------------------------
-- RESERVA
--   Varias reservas comparten fecha_compra dentro del mismo aeropuerto de
--   origen: es la condicion que hace visible la diferencia entre RANGE y ROWS
--   en la Pregunta 2b.
-- ---------------------------------------------------------------------------
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5001, 1001, 1, DATE '2026-01-08', 1000000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5002, 1001, 2, DATE '2026-01-08', 1000000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5003, 1001, 4, DATE '2026-01-08', 1000000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5004, 1001, 5, DATE '2026-01-08', 500000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5005, 1002, 6, DATE '2026-01-18', 1000000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5006, 1002, 7, DATE '2026-01-18', 1000000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5007, 1002, 8, DATE '2026-01-18', 500000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5008, 1003, 9, DATE '2026-02-08', 960000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5009, 1003, 10, DATE '2026-02-08', 960000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5010, 1003, 12, DATE '2026-02-08', 960000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5011, 1003, 13, DATE '2026-02-08', 480000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5012, 1004, 14, DATE '2026-02-18', 960000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5013, 1004, 15, DATE '2026-02-18', 960000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5014, 1004, 16, DATE '2026-02-18', 480000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5015, 1005, 17, DATE '2026-03-08', 600000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5016, 1005, 18, DATE '2026-03-08', 600000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5017, 1005, 19, DATE '2026-03-08', 600000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5018, 1005, 20, DATE '2026-03-08', 300000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5019, 1006, 21, DATE '2026-03-18', 600000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5020, 1006, 22, DATE '2026-03-18', 600000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5021, 1006, 23, DATE '2026-03-18', 300000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5022, 1007, 24, DATE '2026-04-08', 580000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5023, 1007, 26, DATE '2026-04-08', 580000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5024, 1007, 27, DATE '2026-04-08', 580000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5025, 1007, 28, DATE '2026-04-08', 290000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5026, 1008, 29, DATE '2026-04-18', 580000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5027, 1008, 30, DATE '2026-04-18', 580000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5028, 1008, 31, DATE '2026-04-18', 290000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5029, 1009, 32, DATE '2026-01-08', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5030, 1009, 33, DATE '2026-01-08', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5031, 1009, 34, DATE '2026-01-08', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5032, 1009, 35, DATE '2026-01-08', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5033, 1010, 36, DATE '2026-01-18', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5034, 1010, 37, DATE '2026-01-18', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5035, 1010, 38, DATE '2026-01-18', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5036, 1011, 39, DATE '2026-02-08', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5037, 1011, 40, DATE '2026-02-08', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5038, 1011, 1, DATE '2026-02-08', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5039, 1011, 2, DATE '2026-02-08', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5040, 1012, 4, DATE '2026-02-18', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5041, 1012, 5, DATE '2026-02-18', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5042, 1012, 6, DATE '2026-02-18', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5043, 1013, 7, DATE '2026-03-08', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5044, 1013, 8, DATE '2026-03-08', 500000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5045, 1013, 9, DATE '2026-03-08', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5046, 1013, 10, DATE '2026-03-08', 250000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5047, 1014, 12, DATE '2026-03-18', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5048, 1014, 13, DATE '2026-03-18', 500000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5049, 1014, 14, DATE '2026-03-18', 250000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5050, 1015, 15, DATE '2026-04-08', 700000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5051, 1015, 16, DATE '2026-04-08', 700000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5052, 1015, 17, DATE '2026-04-08', 700000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5053, 1015, 18, DATE '2026-04-08', 350000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5054, 1016, 19, DATE '2026-04-18', 700000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5055, 1016, 20, DATE '2026-04-18', 700000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5056, 1016, 21, DATE '2026-04-18', 350000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5057, 1017, 22, DATE '2026-01-08', 600000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5058, 1017, 23, DATE '2026-01-08', 600000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5059, 1017, 24, DATE '2026-01-08', 600000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5060, 1017, 26, DATE '2026-01-08', 300000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5061, 1018, 27, DATE '2026-01-18', 600000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5062, 1018, 28, DATE '2026-01-18', 600000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5063, 1018, 29, DATE '2026-01-18', 300000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5064, 1019, 30, DATE '2026-02-08', 700000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5065, 1019, 31, DATE '2026-02-08', 700000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5066, 1019, 32, DATE '2026-02-08', 700000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5067, 1019, 33, DATE '2026-02-08', 350000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5068, 1020, 34, DATE '2026-02-18', 700000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5069, 1020, 35, DATE '2026-02-18', 700000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5070, 1020, 36, DATE '2026-02-18', 350000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5071, 1021, 37, DATE '2026-03-08', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5072, 1021, 38, DATE '2026-03-08', 720000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5073, 1021, 39, DATE '2026-03-08', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5074, 1021, 40, DATE '2026-03-08', 360000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5075, 1022, 1, DATE '2026-03-18', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5076, 1022, 2, DATE '2026-03-18', 720000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5077, 1022, 4, DATE '2026-03-18', 360000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5078, 1023, 5, DATE '2026-04-08', 300000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5079, 1023, 6, DATE '2026-04-08', 300000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5080, 1023, 7, DATE '2026-04-08', 300000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5081, 1023, 8, DATE '2026-04-08', 300000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5082, 1023, 9, DATE '2026-04-08', 150000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5083, 1024, 10, DATE '2026-01-08', 370000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5084, 1024, 12, DATE '2026-01-08', 370000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5085, 1024, 13, DATE '2026-01-08', 370000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5086, 1024, 14, DATE '2026-01-08', 390000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5087, 1024, 15, DATE '2026-01-08', 180000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5088, 1025, 16, DATE '2026-02-08', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5089, 1025, 17, DATE '2026-02-08', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5090, 1025, 18, DATE '2026-02-08', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5091, 1025, 19, DATE '2026-02-08', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5092, 1026, 20, DATE '2026-02-18', 800000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5093, 1026, 21, DATE '2026-02-18', 800000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5094, 1026, 22, DATE '2026-02-18', 400000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5095, 1027, 23, DATE '2026-03-08', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5096, 1027, 24, DATE '2026-03-08', 720000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5097, 1027, 26, DATE '2026-03-08', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5098, 1027, 27, DATE '2026-03-08', 360000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5099, 1028, 28, DATE '2026-03-18', 720000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5100, 1028, 29, DATE '2026-03-18', 720000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5101, 1028, 30, DATE '2026-03-18', 360000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5102, 1029, 31, DATE '2026-04-08', 250000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5103, 1029, 32, DATE '2026-04-08', 250000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5104, 1029, 33, DATE '2026-04-08', 250000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5105, 1029, 34, DATE '2026-04-08', 250000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5106, 1029, 35, DATE '2026-04-08', 120000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5107, 1030, 36, DATE '2026-01-08', 400000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5108, 1030, 37, DATE '2026-01-08', 400000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5109, 1030, 38, DATE '2026-01-08', 400000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5110, 1030, 39, DATE '2026-01-08', 200000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5111, 1031, 40, DATE '2026-01-18', 400000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5112, 1031, 1, DATE '2026-01-18', 400000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5113, 1031, 2, DATE '2026-01-18', 200000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5114, 1032, 4, DATE '2026-02-08', 470000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5115, 1032, 5, DATE '2026-02-08', 470000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5116, 1032, 6, DATE '2026-02-08', 470000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5117, 1032, 7, DATE '2026-02-08', 490000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5118, 1032, 8, DATE '2026-02-08', 230000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5119, 1033, 9, DATE '2026-04-08', 300000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5120, 1033, 10, DATE '2026-04-08', 300000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5121, 1033, 12, DATE '2026-04-08', 300000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5122, 1033, 13, DATE '2026-04-08', 300000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5123, 1033, 14, DATE '2026-04-08', 150000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5124, 1034, 3, DATE '2026-02-08', 220000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5125, 1034, 11, DATE '2026-02-08', 220000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5126, 1034, 25, DATE '2026-02-08', 220000, 'ECONOMICA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5127, 1034, 3, DATE '2026-02-08', 240000, 'EJECUTIVA', 'VOLADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5128, 1034, 15, DATE '2026-02-08', 110000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5129, 1035, 11, DATE '2026-03-08', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5130, 1035, 25, DATE '2026-03-08', 500000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5131, 1035, 16, DATE '2026-03-08', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5132, 1035, 17, DATE '2026-03-08', 250000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5133, 1036, 18, DATE '2026-03-18', 500000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5134, 1036, 19, DATE '2026-03-18', 500000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5135, 1036, 20, DATE '2026-03-18', 250000, 'ECONOMICA', 'ANULADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5136, 1037, 21, DATE '2026-04-08', 200000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5137, 1037, 22, DATE '2026-04-08', 200000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5138, 1037, 23, DATE '2026-04-08', 200000, 'ECONOMICA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5139, 1037, 24, DATE '2026-04-08', 200000, 'EJECUTIVA', 'CONFIRMADA');
INSERT INTO reserva (id_reserva, id_vuelo, id_pasajero, fecha_compra, tarifa, clase, estado) VALUES (5140, 1037, 26, DATE '2026-04-08', 100000, 'ECONOMICA', 'ANULADA');

COMMIT;

-- ---------------------------------------------------------------------------
-- Verificacion rapida de la carga
--   aeropuerto 7 | aeronave 3 | pasajero 40
--   vuelo 37 | incidencia 34 | reserva 140
-- ---------------------------------------------------------------------------
SELECT 'aeropuerto' AS tabla, COUNT(*) AS filas FROM aeropuerto
UNION ALL SELECT 'aeronave',   COUNT(*) FROM aeronave
UNION ALL SELECT 'pasajero',   COUNT(*) FROM pasajero
UNION ALL SELECT 'vuelo',      COUNT(*) FROM vuelo
UNION ALL SELECT 'incidencia', COUNT(*) FROM incidencia
UNION ALL SELECT 'reserva',    COUNT(*) FROM reserva;
