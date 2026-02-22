CREATE TABLE Autor (
    id_autor          INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Autor PRIMARY KEY (id_autor)
    nombre VARCHAR(255) NOT NULL
    CONSTRAINT UQ_Autor_nombre UNIQUE (nombre)  
);
CREATE TABLE Área (
    id_area INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Área PRIMARY KEY (id_area)
    nombre VARCHAR(255) NOT NULL
    CONSTRAINT UQ_Área_nombre UNIQUE (nombre)
);
CREATE TABLE Obra (
    id_obra INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Obra PRIMARY KEY (id_obra)
    nombre VARCHAR(255) NOT NULL, 
    id_area INT NOT NULL,
    CONSTRAINT UQ_Obra_nombre UNIQUE (nombre),
    foreign key (id_area) references Área(id_area)
);
CREATE TABLE ObraAutor (
    id_obraAutor INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_ObraAutor PRIMARY KEY (id_obraAutor), 
    id_obra int NOT NULL,
    id_autor int NOT NULL,
    foreign key (id_obra) references obra(id_obra),
    foreign key (id_autor) references autor(id_autor)
);

CREATE TABLE Libro (
    id_libro INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Libro PRIMARY KEY (id_libro),
    codigo VARCHAR(255) NOT NULL,
    id_obra int NOT NULL,
    estado VARCHAR(255) CHECK (estado IN ('disponible', 'prestado')) NOT NULL,
    CONSTRAINT UQ_Libro_codigo UNIQUE (codigo),
    foreign key (id_obra) references obra(id_obra)

);

CREATE TABLE Usuario (
    id_usuario INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
    nombre VARCHAR(255) NOT NULL
    CONSTRAINT UQ_Usuario_nombre UNIQUE (nombre)
);
CREATE TABLE Préstamo (
    id_préstamo INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_Préstamo PRIMARY KEY (id_préstamo),
    id_usuario int NOT  NULL,
    fecha_préstamo TIMESTAMP NOT NULL,
    foreign key (id_usuario) references usuario(id_usuario)
    );
CREATE TABLE DetallePréstamo (
    id_detallePréstamo INT GENERATED ALWAYS AS IDENTITY,
        CONSTRAINT PK_DetallePréstamo PRIMARY KEY (id_detallePréstamo),
    id_préstamo int NOT NULL,
    id_libro int NOT NULL,  
    foreign key (id_préstamo) references préstamo(id_préstamo),
    foreign key (id_libro) references libro(id_libro)
);
-- Insertar datos de prueba en sucursal
WITH SRCAutor AS (
    SELECT * FROM (VALUES
        ('J.K. Rowling'),
        ('George R.R. Martin'),
        ('J.R.R. Tolkien'),
        ('Agatha Christie'),
        ('Stephen King'),
        ('Isaac Asimov'),
        ('Arthur C. Clarke'),
        ('H.P. Lovecraft'),
        ('Jane Austen'),
        ('Mark Twain')   
    ) v(nombre)
)
INSERT INTO Autor (nombre)
SELECT nombre
FROM SRCAutor
ON CONFLICT (nombre) DO NOTHING;
SELECT * FROM Autor;
# Insertar datos de prueba en área
WITH SRCArea AS (
    SELECT * FROM (VALUES
        ('Fantasía'),
        ('Ciencia Ficción'),
        ('Misterio'),
        ('Terror'),
        ('Clásicos'),
        ('Aventura'),
        ('Romance'),
        ('Histórica'),
        ('Filosofía'),
        ('Biografía')   
    ) v(nombre)
)
INSERT INTO Área (nombre)
SELECT nombre
FROM SRCArea
ON CONFLICT (nombre) DO NOTHING;
SELECT * FROM Área;
-- Insertar datos de prueba en obra
WITH SRCObra AS (
    SELECT * FROM (VALUES
        ('Harry Potter y la Piedra Filosofal', 1),
        ('Juego de Tronos', 1),
        ('El Señor de los Anillos', 1),
        ('Asesinato en el Orient Express', 3),
        ('El Resplandor', 4),
        ('Fundación', 2),
        ('2001: Una Odisea del Espacio', 2),
        ('La Llamada de Cthulhu', 4),
        ('Orgullo y Prejuicio', 5),
        ('Las Aventuras de Tom Sawyer', 6)
    ) v(nombre, id_area)
)
INSERT INTO Obra (nombre, id_area)
SELECT nombre, id_area
FROM SRCObra AS obr 
JOIN Área ar
  ON ar.id_area = obr.id_area
WHERE ar.id_area IS NOT NULL
ON CONFLICT (nombre) DO NOTHING;
SELECT * FROM Obra; 

-- Insertar datos de prueba en obraautor
WITH SRCObraAutor AS (
    SELECT * FROM (VALUES
        (1, 1),
        (2, 1),
        (3, 1),
        (4, 3),
        (5, 4),
        (6, 2),
        (7, 2),
        (8, 4),
        (9, 5),
        (10, 6)
    ) v(id_obra, id_autor)
)
INSERT INTO ObraAutor (id_obra, id_autor)
SELECT id_obra, id_autor
FROM SRCObraAutor AS o 
JOIN Obra ob
  ON ob.id_obra = o.id_obra
LEFT JOIN Autor aut
    ON aut.id_autor = o.id_autor
    WHERE ob.id_obra IS NOT NULL AND aut.id_autor IS NOT NULL  
ON CONFLICT (id_obra, id_autor) DO NOTHING;
SELECT * FROM ObraAutor;
-- Insertar datos de prueba en libro
WITH SRCLibro AS (
    SELECT * FROM (VALUES
        ('HP001', 1, 'disponible'),
        ('GT001', 2, 'disponible'),
        ('SA001', 3, 'disponible'),
        ('OE001', 4, 'disponible'),
        ('RE001', 5, 'disponible'),
        ('FU001', 6, 'disponible'),
        ('OD001', 7, 'disponible'), 
        ('CT001', 8, 'disponible'),
        ('PP001', 9, 'disponible'),
        ('TS001', 10, 'disponible')
    ) v(codigo, id_obra, estado)
)
INSERT INTO Libro (codigo, id_obra, estado)
SELECT codigo, id_obra, estado
FROM SRCLibro
LEFT JOIN Obra o
  ON o.id_obra = SRCLibro.id_obra
WHERE o.id_obra IS NOT NULL
ON CONFLICT (codigo) DO NOTHING;
SELECT * FROM Libro;
-- Insertar datos de prueba en usuario
WITH SRCUsuario AS (
    SELECT * FROM (VALUES
        ('Alice'),
        ('Bob'),
        ('Charlie'),
        ('David'),
        ('Eve'),
        ('Frank'),
        ('Grace'),
        ('Heidi'),
        ('Ivan'),
        ('Judy')
    ) v(nombre)     
)
INSERT INTO Usuario (nombre)
SELECT nombre
FROM SRCUsuario
ON CONFLICT (nombre) DO NOTHING;
SELECT * FROM Usuario;  
# Insertar datos de prueba en préstamo y detallepréstamo
WITH SRCPréstamo AS (
    SELECT * FROM (VALUES   
        (1, '2024-01-01 10:00:00'),
        (2, '2024-01-02 11:00:00'),
        (3, '2024-01-03 12:00:00'),
        (4, '2024-01-04 13:00:00'),
        (5, '2024-01-05 14:00:00')
    ) v(id_usuario, fecha_préstamo)
)
INSERT INTO Préstamo (id_usuario, fecha_préstamo)
SELECT id_usuario, fecha_préstamo
FROM SRCPréstamo AS prt 
JOIN Usuario usr
  ON usr.id_usuario = prt.id_usuario
LEFT JOIN Préstamo prt2
    ON prt2.id_usuario = prt.id_usuario AND prt2.fecha_préstamo = prt.fecha_préstamo    
WHERE usr.id_usuario IS NOT NULL AND prt.fecha_préstamo IS NOT NULL AND prt2.id_préstamo IS NULL
ON CONFLICT (id_usuario, fecha_préstamo) DO NOTHING;
SELECT * FROM Préstamo;
# Insertar datos de prueba en detallepréstamo
WITH SRCDetallePréstamo AS (    
    SELECT * FROM (VALUES
        (1, 1),
        (1, 2),
        (2, 3),
        (3, 4),
        (4, 5)
    ) v(id_préstamo, id_libro)
)
INSERT INTO DetallePréstamo (id_préstamo, id_libro)
SELECT id_préstamo, id_libro
FROM SRCDetallePréstamo
ON CONFLICT (id_préstamo, id_libro) DO NOTHING;
SELECT * FROM DetallePréstamo;

