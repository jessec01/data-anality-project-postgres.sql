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
-- Postgres no permite crear base de datos con IF NOT EXISTS
CREATE DATABASE SISTEMA_DE_BIBLIOTECA OWNER userrh;
-- eliminar tablas, procedimientos, funciones y triggers si existen
DROP TRIGGER IF EXISTS validarestadolibro ON Libro CASCADE;
DROP TRIGGER IF EXISTS validarpréstamodisponible ON DetallePréstamo CASCADE;
DROP TRIGGER IF EXISTS validarfechas ON DetallePréstamo CASCADE;
DROP FUNCTION IF EXISTS validarestadolibro() CASCADE;
DROP FUNCTION IF EXISTS validarpréstamodisponible() CASCADE;
DROP FUNCTION IF EXISTS validarfechas() CASCADE;
DROP PROCEDURE IF EXISTS validarregistrolibro(TEXT,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS registrarlibronuevo(TEXT,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS validarpréstamonuevo(TEXT,TEXT,TIMESTAMP,TIMESTAMP) CASCADE;
DROP PROCEDURE IF EXISTS registrarpréstamo(TEXT,TEXT,TIMESTAMP,TIMESTAMP) CASCADE;
DROP PROCEDURE IF EXISTS validarpréstamodevolución(TEXT,TEXT,BOOLEAN,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS devolverlibro(TEXT,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS validarpréstamonuevo(TEXT,TEXT,DATE,BOOLEAN,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS registrarpréstamo(TEXT,TEXT,DATE) CASCADE;
DROP PROCEDURE IF EXISTS validarpréstamonuevo(TEXT,TEXT,TIMESTAMP,TIMESTAMP) CASCADE;
DROP PROCEDURE IF EXISTS registrarpréstamo(TEXT,TEXT,TIMESTAMP,TIMESTAMP) CASCADE;
DROP VIEW IF EXISTS libros_extendidos CASCADE;
DROP VIEW IF EXISTS préstamos_extendidos CASCADE;
DROP TABLE IF EXISTS DetallePréstamo CASCADE;
DROP TABLE IF EXISTS Préstamo CASCADE;
DROP TABLE IF EXISTS Usuario CASCADE;
DROP TABLE IF EXISTS Libro CASCADE;
DROP TABLE IF EXISTS ObraAutor CASCADE;
DROP TABLE IF EXISTS Obra CASCADE;
DROP TABLE IF EXISTS Área CASCADE;
DROP TABLE IF EXISTS Autor CASCADE;
DROP TABLE IF EXISTS Hecho_Préstamo CASCADE;
DROP TABLE IF EXISTS Dim_Usuario CASCADE;
DROP TABLE IF EXISTS Dim_Libro CASCADE;
DROP TABLE IF EXISTS Dim_Area CASCADE;
DROP TABLE IF EXISTS Dim_Obra CASCADE;
DROP TABLE IF EXISTS Dim_Autor CASCADE;
DROP TABLE IF EXISTS Dim_Fecha CASCADE;
DROP TABLE IF EXISTS Dim_Préstamo CASCADE;
/* ====================================================================== */
/*  2. CREACIÓN DE TABLAS (MODELO OLTP)                                   */
/*     Tablas principales:                                                */
/*       - Autor                                                          */
/*       - Área                                                           */
/*       - Obra (obra literaria escrita)                                  */
/*       - Libro (ejemplar físico que se alquila)                         */
/*       - Usuario                                                        */
/*       - Préstamo (cabecera)                                            */
/*       - DetallePréstamo (detalle)                                      */
/*                                                                        */
/*     Tablas relacionales:                                               */
/*       - ObraAutor (muchos a muchos)                                    */
/*                                                                        */
/*     NOTA IMPORTANTE:                                                   */
/*       - Ustedes alquilan LIBROS, no Obras.                             */
/* ====================================================================== */
-- tabla Autor
CREATE TABLE Autor (
    AutorID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Autor PRIMARY KEY (AutorID),
    nombre_autor VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Autor_nombre UNIQUE (nombre_autor)
);
-- tabla Área
CREATE TABLE Área (
    ÁreaID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Área PRIMARY KEY (ÁreaID),
    nombre_área VARCHAR(70) NOT NULL,
    CONSTRAINT UQ_Área_nombre UNIQUE (nombre_área)
);  
-- tabla Obra
CREATE TABLE Obra (
    ObraID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Obra PRIMARY KEY (ObraID),
    nombre_obra VARCHAR(70) NOT NULL, 
    ÁreaID INT NOT NULL,
    CONSTRAINT UQ_nombre_obra UNIQUE (nombre_obra),
    CONSTRAINT FK_Obra_Área FOREIGN KEY (ÁreaID) REFERENCES Área(ÁreaID)
);
-- tabla ObraAutor
CREATE TABLE ObraAutor (
    ObraAutorID INT GENERATED ALWAYS AS IDENTITY,
    ObraID INT NOT NULL   ,
    AutorID INT NOT NULL,
    foreign key (ObraID) references Obra(ObraID),
    foreign key (AutorID) references Autor(AutorID),
    CONSTRAINT PK_ObraAutor PRIMARY KEY (ObraID,AutorID)
);
-- tabla Libro
CREATE TABLE Libro (
    LibroID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Libro PRIMARY KEY (LibroID),
    código VARCHAR(30) NOT NULL,
    ObraID INT NOT NULL,
    estado VARCHAR(30) DEFAULT 'disponible' CHECK (estado IN ('disponible', 'préstado')) NOT NULL,
    CONSTRAINT UQ_código UNIQUE (código),
    CONSTRAINT FK_Libro_Obra FOREIGN KEY (ObraID) REFERENCES Obra(ObraID)
);
-- tabla Usuario
CREATE TABLE Usuario (
    UsuarioID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Usuario PRIMARY KEY (UsuarioID),
    nombre_usuario VARCHAR(15) NOT NULL,
    CONSTRAINT UQ_nombre_usuario UNIQUE (nombre_usuario)
);
-- tabla Préstamo
CREATE TABLE Préstamo (
    PréstamoID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Préstamo PRIMARY KEY (PréstamoID),
    UsuarioID int NOT  NULL,
    fecha_préstamo TIMESTAMP NOT NULL,
    fecha_devolución TIMESTAMP NOT NULL,
    CONSTRAINT UQ_fecha_préstamo UNIQUE (fecha_préstamo),
    CONSTRAINT FK_Préstamo_Usuario FOREIGN KEY (UsuarioID) REFERENCES Usuario(UsuarioID)
    );
-- tabla DetallePréstamo
CREATE TABLE DetallePréstamo(
    DetallePréstamoID INT GENERATED ALWAYS AS IDENTITY,
    PréstamoID int NOT NULL,
    LibroID int NOT NULL,
    CONSTRAINT FK_DetallePréstamo_Préstamo FOREIGN KEY (PréstamoID) REFERENCES Préstamo(PréstamoID),
    CONSTRAINT FK_DetallePréstamo_Libro FOREIGN KEY (LibroID) REFERENCES Libro(LibroID),
    CONSTRAINT PK_DetallePréstamo PRIMARY KEY (PréstamoID,LibroID)
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
/*       Préstamo: factura + detalle                                      */
/* ====================================================================== */
--Insertar datos de prueba en la tabla Autor
WITH Src_Autor AS (
    SELECT  * FROM  (
        VALUES
        ( 'Gabriel García Márquez'),
        ( 'J. K. Rowling'),
        ( 'Rómulo Gallegos'),
        ( 'Miguel Otero Silva'),
        ( 'Miguel de Cervantes'),
        ( 'Jorge Luis Borges'),
        ( 'Julio Cortázar'),
        ( 'Mario Vargas Llosa')
    ) AS v(nombre_autor)
)
INSERT INTO Autor (nombre_autor)
SELECT a.nombre_autor
FROM Src_Autor a
ON CONFLICT (nombre_autor) DO NOTHING;
SELECT * FROM Autor;
--Insertar datos de prueba en la tabla Área
WITH Src_Área AS (
    SELECT  * FROM  (
        VALUES
        ('Realismo Mágico'),
        ('Literatura Fantástica y Juvenil'),
        ('Criollismo y Regionalismo'),
        ('Narrativa Social y Política'),
        ('Literatura Clásica del Siglo de Oro'),
        ('Ficción Metafísica y Ensayos'),
        ('Surrealismo y Nueva Novela'),
        ('Narrativa Contemporánea y Crítica')
    ) AS v(nombre_área)
)
INSERT INTO Área (nombre_área)
SELECT a.nombre_área
FROM Src_Área a
ON CONFLICT (nombre_área) DO NOTHING;
SELECT * FROM Área;
-- Insertar datos de prueba en la tabla Obra
WITH Src_Obra AS (
    SELECT * FROM (
        VALUES
        ('Cien años de soledad', 'Realismo Mágico'),
        ('Harry Potter y la piedra filosofal', 'Literatura Fantástica y Juvenil'),
        ('Doña Bárbara', 'Criollismo y Regionalismo'),
        ('Casas Muertas', 'Narrativa Social y Política'),
        ('Don Quijote de la Mancha', 'Literatura Clásica del Siglo de Oro'),
        ('El Aleph', 'Ficción Metafísica y Ensayos'),
        ('Rayuela', 'Surrealismo y Nueva Novela'),
        ('La ciudad y los perros', 'Narrativa Contemporánea y Crítica')
    ) AS v(nombre_obra, nombre_área)
)
INSERT INTO Obra (nombre_obra, ÁreaID) 
SELECT 
    o.nombre_obra, 
    a.ÁreaID 
FROM Src_Obra o 
JOIN Área a ON o.nombre_área = a.nombre_área 
WHERE a.ÁreaID IS NOT NULL AND o.nombre_obra IS NOT NULL
ON CONFLICT (nombre_obra) DO NOTHING;
SELECT * FROM Obra;
--Insertar datos de prueba en la tabla ObraAutor
WITH Src_ObraAutor AS (
    SELECT * FROM (
        VALUES
        ('Cien años de soledad', 'Gabriel García Márquez'),
        ('Harry Potter y la piedra filosofal', 'J. K. Rowling'),
        ('Doña Bárbara', 'Rómulo Gallegos'),
        ('Casas Muertas', 'Miguel Otero Silva'),
        ('Don Quijote de la Mancha', 'Miguel de Cervantes'),
        ('El Aleph', 'Jorge Luis Borges'),
        ('Rayuela', 'Julio Cortázar'),
        ('La ciudad y los perros', 'Mario Vargas Llosa')
    ) AS v(nombre_obra, nombre_autor)
)
INSERT INTO ObraAutor (ObraID, AutorID) 
SELECT o.ObraID, a.AutorID
FROM Src_ObraAutor oa 
JOIN Obra o ON oa.nombre_obra = o.nombre_obra 
JOIN Autor a ON oa.nombre_autor = a.nombre_autor 
WHERE o.ObraID IS NOT NULL AND a.AutorID IS NOT NULL
ON CONFLICT (ObraID, AutorID) DO NOTHING;
--Insertar datos de prueba en la tabla Libro
WITH Src_Libro AS (
    SELECT  * FROM  (
        VALUES
        ( 'GAB-CAS-001', 'cien años de soledad', 'disponible'),
        ( 'JKR-HPP-002', 'Harry Potter y la piedra filosofal', 'préstado'),
        ( 'RGA-DBA-003', 'Doña Bárbara', 'disponible'),
        ( 'MOS-CMU-004', 'Casas Muertas', 'disponible'),
        ( 'MCE-DQU-005', 'Don Quijote de la Mancha', 'préstado'),
        ( 'JLB-ALE-006', 'El Aleph', 'disponible'),
        ( 'JCO-RAY-007', 'Rayuela', 'préstado'),
        ( 'MVL-LCP-008', 'La ciudad y los perros', 'disponible')
    ) AS v( código,nombre_obra,estado)
)
INSERT INTO Libro ( código,ObraID,estado)
SELECT l. código,o.ObraID,l.estado
FROM Src_Libro l 
JOIN Obra o 
ON l.nombre_obra = o.nombre_obra
WHERE o.ObraID IS NOT NULL
ON CONFLICT ( código) DO NOTHING;
SELECT * FROM Libro;
--Insertar datos de prueba en la tabla Usuario
WITH Src_Usuario AS (
    SELECT  * FROM  (
        VALUES
        ( 'Juan Pérez'),
        ( 'María García'),
        ( 'Carlos Ruiz'),
        ( 'Ana López'),
        ( 'Luis Gómez'),
        ( 'Elena Sanz'),
        ( 'Pedro Duarte'),
        ( 'Sofía Castro')
    )AS v(nombre_usuario)
)
INSERT INTO Usuario (nombre_usuario)
SELECT usrc.nombre_usuario
FROM Src_Usuario usrc
ON CONFLICT (nombre_usuario) DO NOTHING;
SELECT * FROM Usuario;
--Insertar datos de prueba en la tabla Préstamo
WITH Src_Préstamo AS (
    SELECT  * FROM  (
        VALUES
        ( '2026-02-10 10:30:00'::TIMESTAMP,'2026-02-10 10:30:00'::TIMESTAMP,'Juan Pérez'),
        ( '2026-02-11 11:00:00'::TIMESTAMP,'2026-02-11 11:00:00'::TIMESTAMP,'María García'),
        ( '2026-02-12 14:15:00'::TIMESTAMP,'2026-02-12 14:15:00'::TIMESTAMP,'Carlos Ruiz'),
        ( '2026-02-13 09:45:00'::TIMESTAMP,'2026-02-13 09:45:00'::TIMESTAMP,'Ana López'),
        ( '2026-02-14 16:20:00'::TIMESTAMP,'2026-02-14 16:20:00'::TIMESTAMP,'Luis Gómez'),
        ( '2026-02-15 10:00:00'::TIMESTAMP,'2026-02-15 10:00:00'::TIMESTAMP,'Elena Sanz'),
        ( '2026-02-16 12:30:00'::TIMESTAMP,'2026-02-16 12:30:00'::TIMESTAMP,'Pedro Duarte'),
        ( '2026-02-17 15:50:00'::TIMESTAMP,'2026-02-17 15:50:00'::TIMESTAMP,'Sofía Castro')
    )AS v(fecha_préstamo,fecha_devolución,nombre_usuario)
)
INSERT INTO Préstamo (fecha_préstamo,fecha_devolución,UsuarioID)
SELECT srcp.fecha_préstamo,srcp.fecha_devolución,u.UsuarioID
FROM Src_Préstamo srcp
JOIN Usuario u ON srcp.nombre_usuario = u.nombre_usuario
ON CONFLICT (fecha_préstamo) DO NOTHING;
SELECT * FROM Préstamo;
--Insertar datos de prueba en la tabla DetallePréstamo
WITH Src_DetallePréstamo AS (
    SELECT  * FROM  (
        VALUES
        ('2026-02-10 10:30:00'::TIMESTAMP,'GAB-CAS-001'),
        ('2026-02-11 11:00:00'::TIMESTAMP,'JKR-HPP-002'), 
        ('2026-02-12 14:15:00'::TIMESTAMP,'RGA-DBA-003'),
        ('2026-02-13 09:45:00'::TIMESTAMP,'MOS-CMU-004'),
        ('2026-02-14 16:20:00'::TIMESTAMP,'MCE-DQU-005'), 
        ('2026-02-15 10:00:00'::TIMESTAMP,'JLB-ALE-006'),
        ('2026-02-16 12:30:00'::TIMESTAMP,'JCO-RAY-007'), 
        ('2026-02-17 15:50:00'::TIMESTAMP,'MVL-LCP-008')
    )AS v(fecha_préstamo, código)
)
INSERT INTO DetallePréstamo (PréstamoID,LibroID)
SELECT p.PréstamoID,l.LibroID
FROM Src_DetallePréstamo AS srcdp 
JOIN Préstamo p 
ON srcdp.fecha_préstamo = p.fecha_préstamo
LEFT JOIN Libro l 
ON srcdp. código = l. código
WHERE l.LibroID IS NOT NULL AND p.PréstamoID IS NOT NULL
ON CONFLICT (PréstamoID,LibroID) DO NOTHING;
SELECT * FROM DetallePréstamo;
/* ====================================================================== */
/*  4. CONSULTAS Y JOINS                                                  */
/*     - INNER JOIN                                                       */
/*     - LEFT JOIN                                                        */
/*     - RIGHT JOIN                                                       */
/*     - FULL JOIN (si aplica)                                            */
/*     - Consultas de verificación                                        */
/*     - Consultas de préstamos activos / vencidos                        */
/* ====================================================================== */
-- Consultas para combinar autores, obras, libros, áreas y usuarios.
--INNER JOIN 
--Autor y Obra
SELECT a.nombre_autor AS autor, o.nombre_obra AS obra 
FROM autor a
INNER JOIN  ObraAutor oa
ON a.AutorID=oa.AutorID
INNER JOIN Obra o
ON oa.ObraID=o.ObraID;
--LEFT JOIN 
--Obra y Libro
SELECT o.nombre_obra AS obra,l. código AS libro
FROM Obra o 
LEFT JOIN Libro l 
ON o.ObraID=l.ObraID;
--RIGHT JOIN
--Libro, Obra y Área
SELECT o.nombre_obra AS obra,l. código,ar.nombre_área As área
FROM  Libro l
RIGHT JOIN Obra o 
ON l.ObraID=o.ObraID
RIGHT JOIN Área ar
ON o.ÁreaID=ar.ÁreaID;
--FULL JOIN
--Libro y Usuario
SELECT l. código, l.estado, u.nombre_usuario AS usuario
FROM Libro l
FULL JOIN DetallePréstamo dp 
ON l.LibroID=dp.LibroID
FULL JOIN Préstamo p
ON dp.PréstamoID=p.PréstamoID
FULL JOIN Usuario u
ON p.UsuarioID=u.UsuarioID;
-- Consultas de préstamos activos/vencidos
SELECT p.fecha_préstamo, (
    CASE  
        WHEN NOW() < p.fecha_devolución
        THEN 'activo'
        WHEN NOW() > p.fecha_devolución
        THEN 'vencido'
        END) AS estado_préstamo
FROM Préstamo p
INNER JOIN DetallePréstamo dp
ON p.PréstamoID=dp.PréstamoID
INNER JOIN Libro l
ON dp.LibroID=l.LibroID
WHERE l.estado='préstado' ;
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
-- Vista 1: Libros extendidos                                         
CREATE OR REPLACE VIEW libros_extendidos AS 
SELECT o.nombre_obra AS obra,ar.nombre_área 
AS área,l. código,l.estado ,COUNT(a.nombre_autor)
AS cantidad_autores FROM Obra o
RIGHT JOIN Área ar ON o.ÁreaID=ar.ÁreaID
RIGHT JOIN ObraAutor oa ON o.ObraID=oa.ObraID
RIGHT JOIN Autor a ON oa.AutorID=a.AutorID
RIGHT JOIN Libro l ON o.ObraID=l.ObraID
GROUP BY o.nombre_obra,ar.nombre_área,l. código,l.estado;
-- Vista 2: Préstamos extendidos                                
CREATE OR REPLACE VIEW préstamos_extendidos AS
SELECT u.nombre_usuario AS usuario,p.fecha_préstamo, (
    CASE  
        WHEN l.estado='préstado' AND 
        NOW() > p.fecha_devolución
        THEN 'vencido'
        ELSE 'activo'
    END) AS estado_préstamo
    FROM Usuario u
    INNER JOIN Préstamo p ON u.UsuarioID=p.UsuarioID
    INNER JOIN DetallePréstamo dp ON p.PréstamoID=dp.PréstamoID
    INNER JOIN Libro l ON dp.LibroID=l.LibroID
    WHERE l.estado='préstado';
/* ====================================================================== */
/*  6. CTE (COMMON TABLE EXPRESSIONS)                                     */
/*     - CTE para libros más solicitados                                  */
/*     - CTE para préstamos vencidos                                      */
/*     - CTE encadenados                                                  */
/* ====================================================================== */
-- CTE para libros más solicitados
WITH libros_más_solicitados AS (
    SELECT o.nombre_obra,l. código,l.estado FROM obra o
INNER JOIN Libro l ON o.ObraID=l.ObraID
WHERE l.estado='préstado'
GROUP BY o.nombre_obra,l. código,l.estado
)
SELECT * FROM libros_más_solicitados;
--  CTE para préstamos vencidos 
--  estado de los libros
WITH estado_libro AS (
    SELECT l.estado, p.fecha_préstamo, (
        CASE  WHEN p.fecha_devolución < NOW()
            THEN 'vencido'
            ELSE  'activo'
        END) AS estado_préstamo
    FROM Préstamo p
    INNER JOIN DetallePréstamo dp ON p.PréstamoID=dp.PréstamoID
    INNER JOIN Libro l ON dp.LibroID=l.LibroID 
   ),
--estado préstamos
libro_préstado AS (
    SELECT estado_libro.fecha_préstamo, estado_libro.estado_préstamo
    FROM estado_libro
    WHERE estado_libro.estado='préstado' ),
--préstamos vencidos
préstamos_vencidos AS (
    SELECT libro_préstado.fecha_préstamo, libro_préstado.estado_préstamo
    FROM libro_préstado
    WHERE libro_préstado.estado_préstamo='vencido' )
SELECT * FROM préstamos_vencidos;
/* ====================================================================== */
/*  7. TABLAS TEMPORALES                                                  */
/*     - Crear tabla temporal                                             */
/*     - Usarla en una consulta                                           */
/*     - Eliminarla                                                       */
/* ====================================================================== */
CREATE TEMP TABLE UsuarioDeuda AS 
    SELECT * FROM préstamos_extendidos AS pe
    WHERE pe.estado_préstamo='vencido' 
    ORDER BY pe.fecha_préstamo DESC;
SELECT * FROM UsuarioDeuda;
DROP TABLE UsuarioDeuda;
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
--SP 1: Registrar nuevo libro  
CREATE OR REPLACE PROCEDURE registrarlibronuevo(
    código_nuevo TEXT,
    nombre_obra_nuevo TEXT,
    -- Parametros de salida 
    OUT exito BOOLEAN,
    OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
BEGIN 
    -- Validaciones de manera burbujeante para juntar los errores
    IF EXISTS (SELECT 1 FROM Libro 
        WHERE Libro.código=código_nuevo ) THEN
        exito:=FALSE;
        mensaje:='el libro ya existe' ;
        RAISE NOTICE 'Validacion fallida:%',mensaje;
        RETURN;  
    ELSIF NOT EXISTS (SELECT 1 FROM Obra 
        WHERE Obra.nombre_obra=nombre_obra_nuevo) THEN
        exito:=FALSE;
        mensaje:='obra no encontrada' ;
        RAISE NOTICE 'Validacion fallida:%',mensaje;
        RETURN;  
    END IF;
    -- Insertar el libro
    INSERT INTO Libro ( código, ObraID)
    SELECT  código_nuevo, o.ObraID
    FROM Obra o 
    WHERE o.nombre_obra = nombre_obra_nuevo
    ON CONFLICT ( código) DO NOTHING;
    exito:=TRUE;
    mensaje:='libro ha sido registrado exitosamente' ;
    RETURN;   
END;
$$; 
--SP 2: Registrar préstamo
CREATE OR REPLACE PROCEDURE validarpréstamonuevo(
    código_libro TEXT,
    nombre_usuario_préstamo TEXT,
    fecha_préstamo_nuevo TIMESTAMP,
    fecha_devolución_nuevo TIMESTAMP,
    -- Parametros de salida 
    OUT exito BOOLEAN,
    OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
BEGIN
    -- Validaciones de manera burbujeante para juntar los errores 
    IF NOT EXISTS (SELECT 1 FROM Libro 
        WHERE Libro.código= código_libro AND Libro.estado='disponible') THEN
        exito:=FALSE;
        mensaje:='Libro no encontrado o no disponible' ;
        RAISE NOTICE 'Validacion fallida:%',mensaje;
        RETURN;  
    ELSIF NOT EXISTS (SELECT 1 FROM Usuario 
        WHERE Usuario.nombre_usuario=nombre_usuario_préstamo) THEN
        exito:=FALSE;
        mensaje:='El usuario no existe' ;
        RAISE NOTICE 'Validacion fallida:%',mensaje;
        RETURN;   
    END IF;   
    INSERT INTO Préstamo (fecha_préstamo, fecha_devolución, UsuarioID)
    SELECT fecha_préstamo_nuevo, fecha_devolución_nuevo, u.UsuarioID
    FROM Usuario u
    WHERE u.nombre_usuario=nombre_usuario_préstamo;
    exito:=TRUE;
    UPDATE Libro
    SET estado='préstado'
    WHERE  código= código_libro;
    INSERT INTO DetallePréstamo (PréstamoID,LibroID)
    SELECT p.PréstamoID,l.LibroID
    FROM Préstamo p
    INNER JOIN Usuario u ON p.UsuarioID = u.UsuarioID
    INNER JOIN DetallePréstamo dp ON p.PréstamoID = dp.PréstamoID
    INNER JOIN Libro l ON dp.LibroID = l.LibroID
    WHERE p.fecha_préstamo = fecha_préstamo_nuevo 
    AND u.nombre_usuario = nombre_usuario_préstamo
    ON CONFLICT DO NOTHING;
    mensaje:='préstamo ha sido registrado exitosamente' ;
    RETURN;   
END;
$$; 
--SP 3: Devolver libro
CREATE OR REPLACE PROCEDURE validarpréstamodevolución(
     código_libro_dev TEXT,
    nombre_usuario_dev TEXT,
    OUT exito BOOLEAN,
    OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
BEGIN 
    -- 1. Validar que el libro exista y esté prestado
    IF NOT EXISTS (SELECT 1 FROM Libro 
        WHERE  código =  código_libro_dev AND estado = 'préstado') THEN
        exito:=FALSE;
        mensaje:='Libro no encontrado o no está prestado' ;
        RAISE NOTICE 'Validacion fallida: %',mensaje;
        RETURN;  
    -- 2. Validar que realmente este usuario tenga prestado ese libro en el historial
    ELSIF NOT EXISTS (SELECT 1 FROM DetallePréstamo dp
        JOIN Préstamo p ON dp.PréstamoID = p.PréstamoID  
        JOIN Usuario u ON p.UsuarioID = u.UsuarioID
        JOIN Libro l ON dp.LibroID = l.LibroID
        WHERE u.nombre_usuario = nombre_usuario_dev AND l. código =  código_libro_dev) THEN
        exito:=FALSE;
        mensaje:='El usuario no tiene registrado este préstamo' ;
        RAISE NOTICE 'Validacion fallida: %',mensaje;
        RETURN;
    END IF;   
    UPDATE Libro
    SET estado='disponible'
    WHERE  código= código_libro_dev;
    exito:=TRUE;
    mensaje:='El libro ha sido devuelto exitosamente, actualizando a disponible' ;
    RETURN;   
END;
$$;     
/* ====================================================================== */
/*  9. TRIGGERS                                                           */
/*     - Evitar préstamos duplicados del mismo libro                      */
/*     - Evitar marcar libro como disponible si tiene préstamos activos   */
/*     - Validar fechas de préstamo y devolución                          */
/*     - Usar inserted y deleted                                          */
/* ====================================================================== */
--Evitar préstamos duplicados del mismo libro
CREATE OR REPLACE FUNCTION validarpréstamo() 
RETURNS TRIGGER AS $$
DECLARE
    estado_actual VARCHAR(30);
BEGIN
    -- Valida si el libro ya está prestado buscando en la tabla Libro
    SELECT estado INTO estado_actual FROM Libro WHERE LibroID = new.LibroID;
    IF estado_actual = 'préstado' THEN
        RAISE EXCEPTION 'El libro con ID % ya se encuentra prestado.', new.LibroID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--En postgresql se usa CREATE TRIGGER para crear el trigger
--y se asocia con la función creada anteriormente
CREATE TRIGGER validarpréstamoduplicado 
BEFORE INSERT OR  UPDATE ON DetallePréstamo
FOR EACH ROW
EXECUTE FUNCTION validarpréstamo();
--Evitar marcar libro como disponible si tiene préstamos activos
CREATE OR REPLACE FUNCTION validardisponibilidad() 
RETURNS TRIGGER AS $$
BEGIN
    IF new.estado = 'disponible' AND old.estado = 'préstado' THEN
        IF EXISTS (SELECT 1 FROM DetallePréstamo dp
                   JOIN Préstamo p ON dp.PréstamoID = p.PréstamoID
                   WHERE dp.LibroID = new.LibroID AND p.fecha_devolución > NOW()) THEN
            RAISE EXCEPTION 'El libro % no se puede marcar como disponible porque tiene préstamos activos futuros', new. código ;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--En postgresql se usa CREATE TRIGGER para crear el trigger y se asocia con la función creada anteriormente
CREATE TRIGGER  validarlibrodisponible
BEFORE INSERT OR  UPDATE ON Libro
FOR EACH ROW
EXECUTE FUNCTION validardisponibilidad();
--  Validar fechas de préstamo y devolución
CREATE OR REPLACE FUNCTION validarfechas() 
RETURNS TRIGGER AS $$
BEGIN
    IF new.fecha_devolución < new.fecha_préstamo THEN
        RAISE EXCEPTION 'La fecha de devolución no puede ser menor a la fecha de préstamo';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--En postgresql se usa CREATE TRIGGER para crear el trigger y se asocia con la función creada anteriormente
CREATE TRIGGER validarfechas 
BEFORE INSERT OR  UPDATE ON Préstamo
FOR EACH ROW
EXECUTE FUNCTION validarfechas();
/* ====================================================================== */
/* 10. TRANSACCIONES                                                      */
/*     - BEGIN TRAN                                                       */
/*     - COMMIT                                                           */
/*     - ROLLBACK                                                         */
/*     - XACT_ABORT                                                       */
/* ====================================================================== */
--Transacciones por medio de Wrappers
-- Transacción 1
CREATE OR REPLACE PROCEDURE validarregistrolibro(
    nombre_obra_nuevo TEXT,
    código_nuevo TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
    BEGIN 
        RAISE NOTICE 'Iniciando registro de libro...';
        Call registrarlibronuevo( código_nuevo,
                                nombre_obra_nuevo,
                                exito,
                                mensaje);
        IF NOT exito THEN
            RAISE NOTICE 'Abortando transacción..., %',mensaje;
        END IF;
        RAISE NOTICE 'Transacción completada exitosamente';
    EXCEPTION WHEN OTHERS THEN 
        RAISE WARNING 'Error al registrar el libro: %', SQLERRM;
END;
$$; 
-- Transacion 2
CREATE OR REPLACE PROCEDURE registrarpréstamo(
    código_libro TEXT,
    nombre_usuario TEXT,
    fecha_préstamo TIMESTAMP,
    fecha_devolución TIMESTAMP
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
BEGIN 
    RAISE NOTICE 'Iniciando registro de préstamo...';
    Call validarpréstamonuevo( código_libro,
                                nombre_usuario,
                                fecha_préstamo,
                                fecha_devolución,
                                exito,
                                mensaje);
    IF NOT exito THEN
        RAISE NOTICE 'Abortando transacción..., %',mensaje;
    END IF;
    RAISE NOTICE 'Transacción completada exitosamente';
EXCEPTION WHEN OTHERS THEN 
    RAISE WARNING 'Error al registrar el préstamo: %', SQLERRM;
END;
$$; 
-- Trasanccion 3
CREATE OR REPLACE PROCEDURE devolverlibro(
     código_libro TEXT,
    nombre_usuario TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
BEGIN 
    RAISE NOTICE 'Iniciando devolución de libro...';
    CALL validarpréstamodevolución( código_libro,
                            nombre_usuario,
                            exito,
                            mensaje);
    IF NOT exito THEN
        RAISE NOTICE 'Abortando transacción..., %',mensaje;
    END IF;
    RAISE NOTICE 'Transacción completada exitosamente';
EXCEPTION WHEN OTHERS THEN 
    RAISE WARNING 'Error al devolver el libro: %', SQLERRM;
END;
$$; 
/* ====================================================================== */
/* 11. DATA WAREHOUSE (DW) – MODELO ANALÍTICO                             */
/*     - Dimensiones: Libro, Obra, Autor, Área, Usuario, Fecha            */
/*     - HechoPréstamo                                                    */
/*     - Métricas: cantidad, días, atraso                                 */
/* ====================================================================== */
-- tabla Dim_Autor
CREATE TABLE Dim_Autor (
    AutorID INT GENERATED ALWAYS AS IDENTITY,
    nombre_autor VARCHAR(100) NOT NULL
);
-- tabla Dim_Area
CREATE TABLE Dim_Area (
    ÁreaID INT GENERATED ALWAYS AS IDENTITY,
    nombre_área VARCHAR(70) NOT NULL
);
-- tabla Dim_Obra
CREATE TABLE Dim_Obra (
    ObraID INT GENERATED ALWAYS AS IDENTITY,
    nombre_obra VARCHAR(70) NOT NULL, 
    ÁreaID INT NOT NULL
);
-- tabla Dim_Libro
CREATE TABLE Dim_Libro (
    LibroID INT GENERATED ALWAYS AS IDENTITY,
     código VARCHAR(30) NOT NULL,
    ObraID INT NOT NULL,
    estado VARCHAR(30) DEFAULT 'disponible' CHECK (estado IN ('disponible', 'préstado')) NOT NULL
);
-- tabla Dim_Usuario
CREATE TABLE Dim_Usuario (
    UsuarioID INT GENERATED ALWAYS AS IDENTITY,
    nombre_usuario VARCHAR(15) NOT NULL
);
-- tabla Dim_Préstamo
CREATE TABLE Dim_Préstamo (
    PréstamoID INT GENERATED ALWAYS AS IDENTITY,
    UsuarioID int NOT NULL
);  
-- tabla Dim_Fecha
CREATE TABLE Dim_Fecha (
    FechaID INT GENERATED ALWAYS AS IDENTITY,
    fecha DATE NOT NULL
);
-- tabla Hecho_Préstamo
CREATE TABLE Hecho_Préstamo (
    HechoPréstamoID INT GENERATED ALWAYS AS IDENTITY,
    PréstamoID INT NOT NULL,
    LibroID INT NOT NULL,
    FechaID INT NOT NULL,
    cantidad INT NOT NULL,
    dias INT NOT NULL,
    atraso INT NOT NULL
);
/* ====================================================================== */
/* 12. ETL CONCEPTUAL                                                     */
/*     - Extracción desde OLTP                                            */
/*     - Transformación (limpieza, claves surrogate, métricas)            */
/*     - Carga en dimensiones y hechos                                    */
/* ====================================================================== */
INSERT INTO Dim_Autor (nombre_autor)
SELECT DISTINCT a.nombre_autor
FROM Autor a
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Autor da 
    WHERE da.nombre_autor = a.nombre_autor
);
INSERT INTO Dim_Area (nombre_área)
SELECT DISTINCT ar.nombre_área
FROM Área ar
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Area da 
    WHERE da.nombre_área = ar.nombre_área
);
INSERT INTO Dim_Obra (nombre_obra, ÁreaID)
SELECT DISTINCT o.nombre_obra, o.ÁreaID
FROM Obra o
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Obra dimo 
    WHERE dimo.nombre_obra = o.nombre_obra
);
INSERT INTO Dim_Libro ( código, ObraID, estado)
SELECT DISTINCT l. código, l.ObraID, l.estado
FROM Libro l
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Libro dl 
    WHERE dl. código = l. código
);
INSERT INTO Dim_Usuario (nombre_usuario)
SELECT DISTINCT u.nombre_usuario
FROM Usuario u
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Usuario du 
    WHERE du.nombre_usuario = u.nombre_usuario
);
INSERT INTO Dim_Fecha (fecha)
SELECT DISTINCT p.fecha_préstamo::DATE
FROM Préstamo p
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Fecha df 
    WHERE df.fecha = p.fecha_préstamo::DATE
);
INSERT INTO Hecho_Préstamo (PréstamoID, LibroID, FechaID, cantidad, dias, atraso)
SELECT 
    p.PréstamoID,
    dp.LibroID,
    df.FechaID,
    1 AS cantidad, 
    EXTRACT(DAY FROM (p.fecha_devolución - p.fecha_préstamo)) AS dias, 
    CASE 
        WHEN NOW() > p.fecha_devolución AND l.estado = 'préstado' THEN 
            EXTRACT(DAY FROM (NOW() - p.fecha_devolución)) 
        ELSE 0 
    END AS atraso 
FROM Préstamo p
JOIN DetallePréstamo dp ON p.PréstamoID = dp.PréstamoID
JOIN Dim_Fecha df ON df.fecha = p.fecha_préstamo::DATE
JOIN Libro l ON dp.LibroID = l.LibroID
WHERE NOT EXISTS (
    SELECT 1 FROM Hecho_Préstamo hp 
    WHERE hp.PréstamoID = p.PréstamoID AND hp.LibroID = dp.LibroID
);
/* ====================================================================== */
/* 13. CONSULTAS ANALÍTICAS                                               */
/*     - Libros más prestados                                             */
/*     - Obras más consultadas                                            */
/*     - Áreas más demandadas                                             */
/*     - Autores más leídos                                               */
/*     - Usuarios con mayor actividad                                     */
/*     - Préstamos por periodo                                            */
/* ====================================================================== */
-- libros más prestados
SELECT l.código, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Libro AS l ON hp.LibroID = l.LibroID
GROUP BY l.código
ORDER BY cantidad DESC;
-- obras más consultadas
SELECT o.nombre_obra, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Libro AS l ON hp.LibroID = l.LibroID
JOIN Dim_Obra AS o ON l.ObraID = o.ObraID
GROUP BY o.nombre_obra
ORDER BY cantidad DESC;
-- áreas más demandadas
SELECT a.nombre_área, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Libro AS l ON hp.LibroID = l.LibroID
JOIN Dim_Obra AS o ON l.ObraID = o.ObraID
JOIN Dim_Area AS a ON o.ÁreaID = a.ÁreaID
GROUP BY a.nombre_área
ORDER BY cantidad DESC;
-- autores más leídos
SELECT au.nombre_autor, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Libro AS l ON hp.LibroID = l.LibroID
JOIN ObraAutor oa ON l.ObraID = oa.ObraID
JOIN Dim_Autor AS au ON oa.AutorID = au.AutorID
GROUP BY au.nombre_autor
ORDER BY cantidad DESC;
-- usuarios con mayor actividad
SELECT u.nombre_usuario, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Préstamo p ON hp.PréstamoID = p.PréstamoID
JOIN Dim_Usuario AS u ON p.UsuarioID = u.UsuarioID
GROUP BY u.nombre_usuario
ORDER BY cantidad DESC;
-- préstamos por periodo
SELECT df.fecha, COUNT(*) AS cantidad FROM Hecho_Préstamo AS hp
JOIN Dim_Fecha AS df ON hp.FechaID = df.FechaID
GROUP BY df.fecha
ORDER BY cantidad DESC;
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
-- 1. Insertar Datos (Uso Correcto de Procedimientos)
-- Registramos varios libros nuevos que no existen en el catálogo
CALL validarregistrolibro('Cien años de soledad', 'GGM-CAS-001');
CALL validarregistrolibro('Cien años de soledad', 'GGM-CAS-002');
CALL validarregistrolibro('Ficción Metafísica y Ensayos', 'FME-AAA-001');
-- Probamos el blindaje contra registros duplicados
CALL validarregistrolibro('Cien años de soledad', 'GGM-CAS-001');

-- 2. Registrar préstamos (Prueba de Éxito)
-- Múltiples usuarios pidiendo préstamos en fechas diferentes
CALL registrarpréstamo('JLB-ALE-006'::TEXT, 'Juan Pérez'::TEXT, '2026-02-18 09:00:00'::TIMESTAMP, '2026-03-04 09:00:00'::TIMESTAMP);
CALL registrarpréstamo('MOS-CMU-004'::TEXT, 'Ana López'::TEXT, '2026-02-19 14:30:00'::TIMESTAMP, '2026-03-05 14:30:00'::TIMESTAMP);
CALL registrarpréstamo('GGM-CAS-001'::TEXT, 'Sofía Castro'::TEXT, '2026-02-21 11:15:00'::TIMESTAMP, '2026-03-07 11:15:00'::TIMESTAMP);

-- 3. Validar Triggers y Restricciones (PRUEBAS DE ERROR INTENCIONAL)
-- ERROR: Fecha de devolución es menor que la fecha de préstamo (Viaje en el tiempo)
CALL registrarpréstamo('GGM-CAS-002'::TEXT, 'María García'::TEXT, '2026-02-20 10:00:00'::TIMESTAMP, '2026-02-10 10:00:00'::TIMESTAMP);

-- ERROR: Intentar prestar un libro que YA se prestó en nuestra prueba anterior
CALL registrarpréstamo('JLB-ALE-006'::TEXT, 'Carlos Ruiz'::TEXT, '2026-02-25 10:00:00'::TIMESTAMP, '2026-03-10 10:00:00'::TIMESTAMP);

-- ERROR: Usuario no registrado en el sistema intentando sacar un libro
CALL registrarpréstamo('GGM-CAS-002'::TEXT, 'Usuario Fantasma'::TEXT, '2026-02-26 09:00:00'::TIMESTAMP, '2026-03-10 09:00:00'::TIMESTAMP);

-- 4. Devolver libros
-- Un usuario devuelve el libro para que vuelva a estar disponible
CALL devolverlibro('JKR-HPP-002', 'María García');
-- 5. Ejecutar Vistas
SELECT * FROM libros_extendidos;
SELECT * FROM préstamos_extendidos;
-- 6. Ejecutar CTE 
WITH libros_más_solicitados AS (
    SELECT o.nombre_obra, l.código, l.estado 
    FROM Obra o
    INNER JOIN Libro l ON o.ObraID = l.ObraID
    WHERE l.estado = 'préstado'
)
SELECT * FROM libros_más_solicitados;
-- Consultas de verificación de integridad
-- TIPO 1: Teoría de la Orfandad
SELECT LibroID, código 
FROM Libro 
WHERE ObraID IS NULL;

SELECT PréstamoID,fecha_préstamo 
FROM Préstamo 
WHERE UsuarioID IS NULL;

-- TIPO 2: Teoría del Cruce Parcial
SELECT a.AutorID,a.nombre_autor 
FROM Autor a 
LEFT JOIN ObraAutor oa ON a.AutorID = oa.AutorID 
WHERE oa.AutorID IS NULL;
SELECT ar.ÁreaID,ar.nombre_área 
FROM Área ar 
LEFT JOIN Obra o ON ar.ÁreaID = o.ÁreaID 
WHERE o.ÁreaID IS NULL;
-- TIPO 3: Teoría del Conteo de Simetría (Balance de Volúmenes)
SELECT 'Tabla Autor' AS Entidad, COUNT(*) AS Total_Registros FROM Autor
UNION ALL 
SELECT 'Tabla Área', COUNT(*) FROM Área
UNION ALL 
SELECT 'Tabla Obra', COUNT(*) FROM Obra
UNION ALL 
SELECT 'Tabla Libro', COUNT(*) FROM Libro;
SELECT 'Tabla Usuario' AS Modulo, COUNT(*) AS Total_Registros FROM Usuario
UNION ALL 
SELECT 'Cabeceras Préstamo', COUNT(*) FROM Préstamo
UNION ALL 
SELECT 'Detalle Préstamo', COUNT(*) FROM DetallePréstamo;
-- Ejecutar Consultas Analíticas (Data Warehouse)
-- 1. Los 5 Libros más prestados (Top)
SELECT l.código, COUNT(*) AS cantidad 
FROM Hecho_Préstamo hp
JOIN Dim_Libro l ON hp.LibroID = l.LibroID
GROUP BY l.código
ORDER BY cantidad DESC LIMIT 5;
-- 2. Análisis de Atrasos: 
SELECT du.nombre_usuario, SUM(hp.atraso) AS total_dias_atraso
FROM Hecho_Préstamo hp
JOIN Dim_Préstamo dp ON hp.PréstamoID = dp.PréstamoID
JOIN Dim_Usuario du ON dp.UsuarioID = du.UsuarioID
WHERE hp.atraso > 0
GROUP BY du.nombre_usuario
ORDER BY total_dias_atraso DESC;
/* ====================================================================== */
/* 15. FIN DEL PROYECTO                                                   */
/* ====================================================================== */
