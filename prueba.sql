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
