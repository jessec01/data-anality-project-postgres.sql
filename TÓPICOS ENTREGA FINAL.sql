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
--DROP TRIGGER IF EXISTS chequearprestamo ON Prestamo CASCADE;
--DROP FUNCTION IF EXISTS validarmonto() CASCADE;
DROP TRIGGER IF EXISTS validarestadolibro ON Libro CASCADE;
DROP TRIGGER IF EXISTS validarprestamodisponible ON DetallePréstamo CASCADE;
DROP TRIGGER IF EXISTS validarfechas ON DetallePréstamo CASCADE;
DROP FUNCTION IF EXISTS validarestadolibro() CASCADE;
DROP FUNCTION IF EXISTS validarprestamodisponible() CASCADE;
DROP FUNCTION IF EXISTS validarfechas() CASCADE;
DROP PROCEDURE IF EXISTS validarregistrolibro(TEXT,TEXT,BOOLEAN,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS registrarlibronuevo(TEXT,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS validarprestamonuevo(TEXT,TEXT,DATE,BOOLEAN,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS registrarprestamo(TEXT,TEXT,DATE) CASCADE;
DROP PROCEDURE IF EXISTS validarprestamodevolucion(TEXT,TEXT,BOOLEAN,TEXT) CASCADE;
DROP PROCEDURE IF EXISTS devolverlibro(TEXT,TEXT) CASCADE;
--DROP PROCEDURE IF EXISTS validarprestamonuevo(TEXT, DECIMAL, INTEGER) CASCADE;
DROP VIEW IF EXISTS libros_extendidos CASCADE;
DROP VIEW IF EXISTS prestamos_extendidos CASCADE;
DROP TABLE IF EXISTS DetallePréstamo CASCADE;
DROP TABLE IF EXISTS Préstamo CASCADE;
DROP TABLE IF EXISTS Usuario CASCADE;
DROP TABLE IF EXISTS Libro CASCADE;
DROP TABLE IF EXISTS ObraAutor CASCADE;
DROP TABLE IF EXISTS Obra CASCADE;
DROP TABLE IF EXISTS Área CASCADE;
DROP TABLE IF EXISTS Autor CASCADE;
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
-- tabla autor
CREATE TABLE Autor (
    AutorID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Autor PRIMARY KEY (AutorID),
    nombre_autor VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Autor_nombre UNIQUE (nombre_autor)
);
-- tabla area
CREATE TABLE Área (
    ÁreaID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Área PRIMARY KEY (ÁreaID),
    nombre_área VARCHAR(70) NOT NULL,
    CONSTRAINT UQ_Área_nombre UNIQUE (nombre_área)
);
-- tabla obra
CREATE TABLE Obra (
    ObraID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Obra PRIMARY KEY (ObraID),
    nombre_obra VARCHAR(70) NOT NULL, 
    ÁreaID INT NOT NULL,
    CONSTRAINT UQ_nombre_obra UNIQUE (nombre_obra),
    CONSTRAINT FK_Obra_Área FOREIGN KEY (ÁreaID) REFERENCES Área(ÁreaID)
);
-- tabla obraautor
CREATE TABLE ObraAutor (
    ObraAutorID INT GENERATED ALWAYS AS IDENTITY,
    ObraID INT NOT NULL   ,
    AutorID INT NOT NULL,
    foreign key (ObraID) references Obra(ObraID),
    foreign key (AutorID) references Autor(AutorID),
    CONSTRAINT PK_ObraAutor PRIMARY KEY (ObraID,AutorID)
);
-- tabla libro
CREATE TABLE Libro (
    LibroID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Libro PRIMARY KEY (LibroID),
    codigo VARCHAR(30) NOT NULL,
    ObraID INT NOT NULL,
    estado VARCHAR(30) DEFAULT 'disponible' CHECK (estado IN ('disponible', 'préstado')) NOT NULL,
    CONSTRAINT UQ_codigo UNIQUE (codigo),
    CONSTRAINT FK_Libro_Obra FOREIGN KEY (ObraID) REFERENCES Obra(ObraID)
);
-- tabla usuarios
CREATE TABLE Usuario (
    UsuarioID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Usuario PRIMARY KEY (UsuarioID),
    nombre_usuario VARCHAR(15) NOT NULL,
    CONSTRAINT UQ_nombre_usuario UNIQUE (nombre_usuario)
);
-- tabla prestamo
CREATE TABLE Préstamo (
    PréstamoID INT GENERATED ALWAYS AS IDENTITY,
    CONSTRAINT PK_Préstamo PRIMARY KEY (PréstamoID),
    UsuarioID int NOT  NULL,
    fecha_préstamo TIMESTAMP NOT NULL,
    fecha_devolución TIMESTAMP NOT NULL,
    CONSTRAINT UQ_fecha_préstamo UNIQUE (fecha_préstamo),
    CONSTRAINT FK_Préstamo_Usuario FOREIGN KEY (UsuarioID) REFERENCES Usuario(UsuarioID)
    );
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
/*       Prestamo: factura + detalle                                      */
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
-- CORRECCIÓN: Debes incluir ÁreaID en la lista de columnas a insertar
INSERT INTO Obra (nombre_obra, ÁreaID) 
SELECT 
    o.nombre_obra, 
    a.ÁreaID -- CORRECCIÓN: Aquí mapeas el ID automático que encontró el JOIN
FROM Src_Obra o 
JOIN Área a ON o.nombre_área = a.nombre_área -- Rastreo del ID mediante el nombre [cite: 101]
WHERE a.ÁreaID IS NOT NULL AND o.nombre_obra IS NOT NULL
ON CONFLICT (nombre_obra) DO NOTHING; -- Requiere que nombre_obra sea UNIQUE [cite: 5]

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
INSERT INTO ObraAutor (ObraID, AutorID) -- ObraAutorID se genera solo si es IDENTITY
SELECT o.ObraID, a.AutorID
FROM Src_ObraAutor oa 
JOIN Obra o ON oa.nombre_obra = o.nombre_obra -- Mapeo dinámico de ObraID
JOIN Autor a ON oa.nombre_autor = a.nombre_autor -- Mapeo dinámico de AutorID
WHERE o.ObraID IS NOT NULL AND a.AutorID IS NOT NULL
ON CONFLICT (ObraID, AutorID) DO NOTHING; -- Valida la integridad referencial [cite: 82]
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
    ) AS v(codigo,nombre_obra,estado)
)
INSERT INTO Libro (codigo,ObraID,estado)
SELECT l.codigo,o.ObraID,l.estado
FROM Src_Libro l 
JOIN Obra o 
ON l.nombre_obra = o.nombre_obra
WHERE o.ObraID IS NOT NULL
ON CONFLICT (codigo) DO NOTHING;
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
    )AS v(fecha_préstamo,codigo)
)
INSERT INTO DetallePréstamo (PréstamoID,LibroID)
SELECT p.PréstamoID,l.LibroID
FROM Src_DetallePréstamo AS srcdp 
JOIN Préstamo p 
ON srcdp.fecha_préstamo = p.fecha_préstamo
LEFT JOIN Libro l 
ON srcdp.codigo = l.codigo
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
SELECT o.nombre_obra AS obra,l.codigo AS libro
FROM Obra o 
LEFT JOIN Libro l 
ON o.ObraID=l.ObraID;
--RIGHT JOIN
--Libro, Obra y Área
SELECT o.nombre_obra AS obra,l.codigo,ar.nombre_área As área
FROM  Libro l
RIGHT JOIN Obra o 
ON l.ObraID=o.ObraID
RIGHT JOIN Área ar
ON o.ÁreaID=ar.ÁreaID;
--FULL JOIN
--Libro y Usuario
SELECT l.codigo, l.estado, u.nombre_usuario AS usuario
FROM Libro l
FULL JOIN DetallePréstamo dp 
ON l.LibroID=dp.LibroID
FULL JOIN Préstamo p
ON dp.PréstamoID=p.PréstamoID
FULL JOIN Usuario u
ON p.UsuarioID=u.UsuarioID;
-- Consultas de verificación de integridad
-- TIPO 1: Teoría de la Orfandad (Verificación de Claves Foráneas Nulas)
-- Consulta 1: ¿Existe algún Libro registrado físicamente que no pertenezca a ninguna Obra literaria? (Debe dar 0)
SELECT LibroID,codigo 
FROM Libro 
WHERE ObraID IS NULL;
-- Consulta 2: ¿Existe algún Préstamo transaccional que no esté asociado a ningún Usuario registrado? (Debe dar 0)
SELECT PréstamoID,fecha_préstamo 
FROM Préstamo 
WHERE UsuarioID IS NULL;
-- TIPO 2: Teoría del Cruce Parcial (Anti-JOIN para detectar Catálogo Muerto)
-- Consulta 3: ¿Tenemos Autores en el catálogo que no hayan escrito ninguna de las Obras que poseemos?
SELECT a.AutorID,a.nombre_autor 
FROM Autor a 
LEFT JOIN ObraAutor oa ON a.AutorID = oa.AutorID 
WHERE oa.AutorID IS NULL;
-- Consulta 4: ¿Tenemos Áreas temáticas creadas que actualmente están vacías (sin Obras)?
SELECT ar.ÁreaID,ar.nombre_área 
FROM Área ar 
LEFT JOIN Obra o ON ar.ÁreaID = o.ÁreaID 
WHERE o.ÁreaID IS NULL;
-- TIPO 3: Teoría del Conteo de Simetría (Balance de Volúmenes)
-- Consulta 5: Auditoría masiva de volumen de entidades fuertes (Catálogo)
SELECT 'Tabla Autor' AS Entidad, COUNT(*) AS Total_Registros FROM Autor
UNION ALL 
SELECT 'Tabla Área', COUNT(*) FROM Área
UNION ALL 
SELECT 'Tabla Obra', COUNT(*) FROM Obra
UNION ALL 
SELECT 'Tabla Libro', COUNT(*) FROM Libro;
-- Consulta 6: Auditoría masiva de volumen transaccional (Movimientos)
SELECT 'Tabla Usuario' AS Modulo, COUNT(*) AS Total_Registros FROM Usuario
UNION ALL 
SELECT 'Cabeceras Préstamo', COUNT(*) FROM Préstamo
UNION ALL 
SELECT 'Detalle Préstamo', COUNT(*) FROM DetallePréstamo;
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
/*     Vista 1: Libros extendidos                                         */
CREATE OR REPLACE VIEW libros_extendidos AS 
SELECT o.nombre_obra AS obra,ar.nombre_área 
AS área,l.codigo,l.estado ,COUNT(a.nombre_autor)
AS cantidad_autores FROM Obra o
RIGHT JOIN Área ar ON o.ÁreaID=ar.ÁreaID
RIGHT JOIN ObraAutor oa ON o.ObraID=oa.ObraID
RIGHT JOIN Autor a ON oa.AutorID=a.AutorID
RIGHT JOIN Libro l ON o.ObraID=l.ObraID
GROUP BY o.nombre_obra,ar.nombre_área,l.codigo,l.estado;
-- Se llama la vistas
SELECT * FROM libros_extendidos;
/*     Vista 2: Préstamos extendidos                                */
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
-- Se llama la vistas
SELECT * FROM préstamos_extendidos;
/* ====================================================================== */
/*  6. CTE (COMMON TABLE EXPRESSIONS)                                     */
/*     - CTE para libros más solicitados                                  */
/*     - CTE para préstamos vencidos                                      */
/*     - CTE encadenados                                                  */
/* ====================================================================== */
-- CTE para libros más solicitados
WITH libros_más_solicitados AS (
    SELECT o.nombre_obra,l.codigo,l.estado FROM obra o
INNER JOIN Libro l ON o.ObraID=l.ObraID
WHERE l.estado='préstado'
GROUP BY o.nombre_obra,l.codigo,l.estado
)
--se llama al CTE
SELECT * FROM libros_más_solicitados;
--  CTE para préstamos vencidos 
--estado de los libros
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
--prestamos vencidos
prestamos_vencidos AS (
    SELECT libro_préstado.fecha_préstamo, libro_préstado.estado_préstamo
    FROM libro_préstado
    WHERE libro_préstado.estado_préstamo='vencido' )
--se llama al CTE
SELECT * FROM prestamos_vencidos ;
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
--se llama a la tabla temporal
SELECT * FROM UsuarioDeuda;
--eliminar la tabla temporal
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
   codigo_nuevo TEXT,
   nombre_obra_nuevo TEXT,
   OUT exito BOOLEAN,
   OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE 
    local_libro_encontrado BOOLEAN;
    local_obra_encontrado BOOLEAN;    local_obra_id INT;
BEGIN 
    IF EXISTS (SELECT 1 FROM Libro 
        WHERE Libro.codigo=codigo_nuevo ) THEN
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
    INSERT INTO Libro (codigo, ObraID)
    SELECT codigo_nuevo, o.ObraID
    FROM Obra o 
    WHERE o.nombre_obra = nombre_obra_nuevo
    ON CONFLICT (codigo) DO NOTHING;
    exito:=TRUE;
    mensaje:='libro ha sido registrado exitosamente' ;
    RETURN;   
END;
$$; 
CREATE OR REPLACE PROCEDURE validarregistrolibro(
   nombre_obra_nuevo TEXT,
   codigo_nuevo TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
    BEGIN 
        RAISE NOTICE 'Iniciando registro de libro...';
        Call validarregistrolibro(codigo_nuevo,
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
--SP 2: Registrar préstamo
CREATE OR REPLACE PROCEDURE validarprestamonuevo(
    codigo_libro TEXT,
    nombre_usuario_préstamo TEXT,
    fecha_préstamo_nuevo DATE,
    OUT exito BOOLEAN,
    OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE
    local_libro_encontrado BOOLEAN;
    local_usuario_encontrado BOOLEAN;
    local_libro_disponible BOOLEAN;
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM Libro 
        WHERE Libro.codigo=codigo_libro AND Libro.estado='disponible') THEN
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
    INSERT INTO Préstamo (fecha_préstamo,UsuarioID)
    SELECT fecha_préstamo_nuevo,u.UsuarioID
    FROM Usuario u
    WHERE u.nombre_usuario=nombre_usuario_préstamo;
    exito:=TRUE;
    UPDATE Libro
    SET estado='préstado'
    WHERE codigo=codigo_libro;
    INSERT INTO DetallePréstamo (PréstamoID,LibroID)
    SELECT p.PréstamoID,l.LibroID
    FROM Préstamo p
    INNER JOIN Usuario u ON p.UsuarioID = u.UsuarioID
    INNER JOIN DetallePrestamo dp ON p.PrestamoID = dp.PrestamoID
    INNER JOIN Libro l ON dp.LibroID = l.LibroID
    WHERE p.fecha_préstamo = fecha_préstamo_nuevo 
    AND u.nombre_usuario = nombre_usuario_préstamo
    ON CONFLICT DO NOTHING;
    mensaje:='prestamo ha sido registrado exitosamente' ;
    RETURN;   
END;
$$; 
CREATE OR REPLACE PROCEDURE registrarprestamo(
    codigo_libro TEXT,
    nombre_usuario TEXT,
    fecha_prestamo DATE
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
BEGIN 
    RAISE NOTICE 'Iniciando registro de prestamo...';
    Call validarprestamonuevo(codigo_libro,
                                nombre_usuario,
                                fecha_prestamo,
                                exito,
                                mensaje);
    IF NOT exito THEN
        RAISE NOTICE 'Abortando transacción..., %',mensaje;
    END IF;
    RAISE NOTICE 'Transacción completada exitosamente';
EXCEPTION WHEN OTHERS THEN 
    RAISE WARNING 'Error al registrar el prestamo: %', SQLERRM;
END;
$$; 
-- Devolver libro
CREATE OR REPLACE PROCEDURE validarprestamodevolucion(
    codigo_libro_dev TEXT,
    nombre_usuario_dev TEXT,
    OUT exito BOOLEAN,
    OUT mensaje TEXT
)
LANGUAGE plpgsql AS $$ 
BEGIN 
    -- 1. Validar que el libro exista y esté prestado
    IF NOT EXISTS (SELECT 1 FROM Libro 
        WHERE codigo = codigo_libro_dev AND estado = 'préstado') THEN
        exito:=FALSE;
        mensaje:='Libro no encontrado o no está prestado' ;
        RAISE NOTICE 'Validacion fallida: %',mensaje;
        RETURN;  
    -- 2. Validar que realmente este usuario tenga prestado ese libro en el historial
    ELSIF NOT EXISTS (SELECT 1 FROM DetallePréstamo dp
        JOIN Préstamo p ON dp.PréstamoID = p.PréstamoID  
        JOIN Usuario u ON p.UsuarioID = u.UsuarioID
        JOIN Libro l ON dp.LibroID = l.LibroID
        WHERE u.nombre_usuario = nombre_usuario_dev AND l.codigo = codigo_libro_dev) THEN
        exito:=FALSE;
        mensaje:='El usuario no tiene registrado este préstamo' ;
        RAISE NOTICE 'Validacion fallida: %',mensaje;
        RETURN;
    END IF;   
    
    -- 3. Actualizamos el estado del libro (No hacemos DELETE para no destruir el Data Warehouse)
    UPDATE Libro
    SET estado='disponible'
    WHERE codigo=codigo_libro_dev;
    
    exito:=TRUE;
    mensaje:='El libro ha sido devuelto exitosamente, actualizando a disponible' ;
    RETURN;   
END;
$$;     

CREATE OR REPLACE PROCEDURE devolverlibro(
    codigo_libro TEXT,
    nombre_usuario TEXT
)
LANGUAGE plpgsql AS $$ 
DECLARE
    exito BOOLEAN;
    mensaje TEXT;
BEGIN 
    RAISE NOTICE 'Iniciando devolucion de libro...';
    CALL validarprestamodevolucion(codigo_libro,
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
/*  9. TRIGGERS                                                           */
/*     - Evitar préstamos duplicados del mismo libro                      */
/*     - Evitar marcar libro como disponible si tiene préstamos activos   */
/*     - Validar fechas de préstamo y devolución                          */
/*     - Usar inserted y deleted                                          */
/* ====================================================================== */
CREATE OR REPLACE FUNCTION validarprestamo() 
RETURNS TRIGGER AS $$
DECLARE
    estado_actual VARCHAR(30);
BEGIN
    -- Validamos si el libro ya está prestado buscando en la tabla Libro
    SELECT estado INTO estado_actual FROM Libro WHERE LibroID = new.LibroID;
    IF estado_actual = 'préstado' THEN
        RAISE EXCEPTION 'El libro con ID % ya se encuentra prestado.', new.LibroID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--En postgresql se usa CREATE TRIGGER para crear el trigger y se asocia con la función creada anteriormente
CREATE TRIGGER validarprestamoduplicado 
BEFORE INSERT OR  UPDATE ON DetallePréstamo
FOR EACH ROW
EXECUTE FUNCTION validarprestamo();
--  - Evitar marcar libro como disponible si tiene préstamos activos
CREATE OR REPLACE FUNCTION validardisponibilidad() 
RETURNS TRIGGER AS $$
BEGIN
    -- Chequear que se use "=" y que las variables correspondan a la tabla Libro (NEW.codigo, no NEW.codigo_libro)
    IF new.estado = 'disponible' AND old.estado = 'préstado' THEN
        -- Lógica: Si alguien trata de devolverlo (pasarlo a disponible), validamos que no tenga un préstamo futuro activo
        IF EXISTS (SELECT 1 FROM DetallePréstamo dp
                   JOIN Préstamo p ON dp.PréstamoID = p.PréstamoID
                   WHERE dp.LibroID = new.LibroID AND p.fecha_devolución > NOW()) THEN
            RAISE EXCEPTION 'El libro % no se puede marcar como disponible porque tiene préstamos activos futuros', new.codigo ;
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
--  - Validar fechas de préstamo y devolución
CREATE OR REPLACE FUNCTION validarfechas() 
RETURNS TRIGGER AS $$
BEGIN
    -- Se deben usar las tildes porque así fueron creadas las columnas en Préstamo
    IF new.fecha_devolución < new.fecha_préstamo THEN
        RAISE EXCEPTION 'La fecha de devolucion no puede ser menor a la fecha de prestamo';
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
