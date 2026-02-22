
	
/* ====================================================================== */
/*                 PROYECTO FINAL – SISTEMA DE BIBLIOTECA                 */
/*                 PLANTILLA VACÍA PARA COMPLETAR EL SCRIPT               */
/*                 ENTREGA: 28 DE FEBRERO                                 */
/*                 DATOS DEL ALUMNO: APELLIDOS, NOMBRE, CÉDULA            */
/*                 SUBJECT: TÓPICOS ENTREGA FINAL               	      */
/*                 ARCHIVO: TÓPICOS ENTREGA FINAL.SQL           	      */
/* ====================================================================== */

/* ====================================================================== */
/*  1. CREACIÓN DE BASE DE DATOS                                          */
/*     - Crear la base de datos                                           */
/*     - Cambiar el contexto                                              */
/*     - Limpieza defensiva de objetos                                    */
/* ====================================================================== */
-- Crear usuario si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'userrh'
    ) THEN
        CREATE USER userrh WITH PASSWORD '1234';
    END IF;
END$$;
-- Crear base de datos
CREATE DATABASE rrhh_db OWNER userrh;
-- eliminar tablas, procedimientos, funciones y triggers si existen
DROP TRIGGER IF EXISTS chequearprestamo ON Prestamo CASCADE;
DROP FUNCTION IF EXISTS validarmonto() CASCADE;
DROP PROCEDURE IF EXISTS actualizarprestamonuevo(TEXT, DECIMAL) CASCADE;
DROP PROCEDURE IF EXISTS validarprestamonuevo(TEXT, DECIMAL, INTEGER) CASCADE;
DROP VIEW IF EXISTS facturaprestamo CASCADE;
DROP TABLE IF EXISTS Prestamo CASCADE;
DROP TABLE IF EXISTS Sucursal CASCADE;
-- Crear tablas 
/* ====================================================================== */
/*  2. CREACIÓN DE TABLAS (MODELO OLTP)                                   */
/*     Tablas principales:                                                */
/*       - Autor                                                          */
/*       - Área                                                           */
/*       - Obra (obra literaria escrita)                                  */
/*       - Libro (ejemplar físico que se alquila)                         */
/*       - Usuario                                                        */
/*       - Prestamo (cabecera)                                            */
/*       - DetallePrestamo (detalle)                                      */
/*                                                                        */
/*     Tablas relacionales:                                               */
/*       - ObraAutor (muchos a muchos)                                    */
/*                                                                        */
/*     NOTA IMPORTANTE:                                                   */
/*       - Ustedes alquilan LIBROS, no Obras.                             */
/* ====================================================================== */
CREATE TABLE Autor (
    id_autor SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);
CREATE TABLE Área (
    id_area SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);
CREATE TABLE Obra (
    id_obra SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL, 
    id_area int NOT NULL,
    foreign key (id_area) references Área(id_area)

);
CREATE TABLE ObraAutor (
    id_obraAutor SERIAL PRIMARY KEY,
    id_obra int NOT NULL   ,
    id_autor int NOT NULL,
    foreign key (id_obra) references obra(id_obra),
    foreign key (id_autor) references autor(id_autor)
);

CREATE TABLE Libro (
    id_libro SERIAL PRIMARY KEY,
    codigo VARCHAR(255) NOT NULL,
    id_obra int NOT NULL,
    estado VARCHAR(255) CHECK (estado IN ('disponible', 'prestado')) NOT NULL,
    foreign key (id_obra) references obra(id_obra)

);

CREATE TABLE Usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);
CREATE TABLE Préstamo (
    id_préstamo SERIAL PRIMARY KEY,
    id_usuario int NOT  NULL,
    fecha_préstamo TIMESTAMP NOT NULL,
    foreign key (id_usuario) references usuario(id_usuario),
    );
CREATE TABLE DetallePréstamo (
    id_detallePréstamo SERIAL PRIMARY KEY,
    id_préstamo int NOT NULL,
    id_libro int NOT NULL,  
    foreign key (id_préstamo) references préstamo(id_préstamo),
    foreign key (id_libro) references libro(id_libro)
);

/* ====================================================================== */
/*  3. INSERCIÓN DE DATOS (SEED)                                          */
/*     - Insertar mínimo 8 registros por tabla                            */
/*     - Respetar integridad referencial                                  */
/*     - Pueden usar CTE o JOIN para mapear claves                        */
/*                                                                        */
/*     EJEMPLOS DE REGISTROS (NO ES CÓDIGO, SOLO REFERENCIA):             */
/*       Autor: "Gabriel García Márquez", "J. K. Rowling"                 */
/*       Área: "Realismo mágico", "Fantasía"                              */
/*       Obra: "Cien años de soledad", "Doña Bárbara"                     */
/*       Libro: "L0001" asociado a Obra 1                                 */
/*       Usuario: "Juan Pérez", "María Gómez"                             */
/*       Prestamo: factura + detalle                                      */
/* ====================================================================== */

/* ====================================================================== */
/*  4. CONSULTAS Y JOINS                                                  */
/*     - INNER JOIN                                                       */
/*     - LEFT JOIN                                                        */
/*     - RIGHT JOIN                                                       */
/*     - FULL JOIN (si aplica)                                            */
/*     - Consultas de verificación                                        */
/*     - Consultas de préstamos activos / vencidos                        */
/* ====================================================================== */

/* ====================================================================== */
/*  5. CREACIÓN DE VISTAS                                                 */
/*     Vista 1: Libros extendidos                                         */
/*       - Título de la obra                                              */
/*       - Área                                                           */
/*       - Cantidad de autores                                            */
/*                                                                        */
/*     Vista 2: Préstamos extendidos                                      */
/*       - Usuario                                                        */
/*       - Fechas                                                         */
/*       - Estado del préstamo                                            */
/* ====================================================================== */

/* ====================================================================== */
/*  6. CTE (COMMON TABLE EXPRESSIONS)                                     */
/*     - CTE para libros más solicitados                                  */
/*     - CTE para préstamos vencidos                                      */
/*     - CTE encadenados                                                  */
/* ====================================================================== */

/* ====================================================================== */
/*  7. TABLAS TEMPORALES                                                  */
/*     - Crear tabla temporal                                             */
/*     - Usarla en una consulta                                           */
/*     - Eliminarla                                                       */
/* ====================================================================== */

/* ====================================================================== */
/*  8. STORED PROCEDURES                                                  */
/*     SP 1: Registrar nuevo libro                                        */
/*       - Validar existencia                                             */
/*       - Insertar libro                                                 */
/*       - Asociar con obra                                               */
/*                                                                        */
/*     SP 2: Registrar préstamo                                           */
/*       - Validar disponibilidad del libro                               */
/*       - Validar usuario                                                */
/*       - Manejo de errores TRY/CATCH                                    */
/*                                                                        */
/*     SP 3: Devolver libro                                               */
/*       - Validar préstamo activo                                        */
/*       - Actualizar estado                                              */
/* ====================================================================== */

/* ====================================================================== */
/*  9. TRIGGERS                                                           */
/*     - Evitar préstamos duplicados del mismo libro                      */
/*     - Evitar marcar libro como disponible si tiene préstamos activos   */
/*     - Validar fechas de préstamo y devolución                          */
/*     - Usar inserted y deleted                                          */
/* ====================================================================== */

/* ====================================================================== */
/* 10. TRANSACCIONES                                                      */
/*     - BEGIN TRAN                                                       */
/*     - COMMIT                                                           */
/*     - ROLLBACK                                                         */
/*     - XACT_ABORT                                                       */
/* ====================================================================== */

/* ====================================================================== */
/* 11. DATA WAREHOUSE (DW) – MODELO ANALÍTICO                             */
/*     - Dimensiones: Libro, Obra, Autor, Área, Usuario, Fecha            */
/*     - HechoPréstamo                                                    */
/*     - Métricas: cantidad, días, atraso                                 */
/* ====================================================================== */

/* ====================================================================== */
/* 12. ETL CONCEPTUAL                                                     */
/*     - Extracción desde OLTP                                            */
/*     - Transformación (limpieza, claves surrogate, métricas)            */
/*     - Carga en dimensiones y hechos                                    */
/* ====================================================================== */

/* ====================================================================== */
/* 13. CONSULTAS ANALÍTICAS                                               */
/*     - Libros más prestados                                             */
/*     - Obras más consultadas                                            */
/*     - Áreas más demandadas                                             */
/*     - Autores más leídos                                               */
/*     - Usuarios con mayor actividad                                     */
/*     - Préstamos por periodo                                            */
/* ====================================================================== */

/* ====================================================================== */
/* 14. PRUEBAS DEL MÓDULO                                                 */
/*     - Insertar datos                                                   */
/*     - Registrar préstamos                                              */
/*     - Devolver libros                                                  */
/*     - Ejecutar vistas                                                  */
/*     - Ejecutar CTE                                                     */
/*     - Validar triggers                                                 */
/*     - Verificar integridad                                             */
/*     - Ejecutar consultas analíticas                                    */
/* ====================================================================== */

/* ====================================================================== */
/* 15. FIN DEL PROYECTO                                                   */
/* ====================================================================== */
