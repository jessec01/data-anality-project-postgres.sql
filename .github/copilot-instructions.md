# Copilot Instructions

## Project Context
- Proyecto: sistema de biblioteca académico con entregables OLTP + DW detallados en [init.sql](init.sql).
- `init.sql` funciona como guion maestro (15 secciones) describiendo desde creación de usuario/DB (`userrh` / `rrhh_db`) hasta ETL y pruebas finales.
- `prueba.sql` contiene la primera pasada del modelo físico; úsalo como punto de partida para todas las modificaciones reales.

## File Map & Ownership
- Mantén [init.sql](init.sql) como documento de arquitectura y checklist; cualquier decisión estructural nueva debe quedar reflejada ahí.
- Implementa DDL y lógica ejecutable en scripts separados como [prueba.sql](prueba.sql) para que el guion siga siendo legible.

## Dev Workflow
- Crear/actualizar el entorno ejecutando `psql -U userrh -d postgres -f init.sql`; el script crea el rol y `rrhh_db`, luego limpia artefactos (`DROP ... CASCADE`).
- Cargar el modelo activo dentro de la base con `psql -U userrh -d rrhh_db -f prueba.sql`.
- Tras cada cambio valida inventario con `\dt` y revisa constraints relevantes usando `\d+ Tabla`.
- Si usas nombres con acento o mayúsculas mixtas (ej. `Área`), referencia siempre con comillas dobles: `SELECT * FROM "Área";`.

## Modeling Patterns Observed
- Tablas principales: `Autor`, `Área`, `Obra`, `Libro`, `Usuario`, `Prestamo`, `ObraAutor`; claves primarias `SERIAL` y `FOREIGN KEY` explícitos.
- `Libro.estado` demuestra que se esperan `CHECK` sobre dominios pequeños; replica el enfoque para estados y tipos similares.
- Relaciones N:M se modelan mediante tablas puente (`ObraAutor`) con ambas llaves foráneas obligatorias.
- Scripts siguen estilo "una instrucción por bloque" sin `IF NOT EXISTS` en `CREATE TABLE`; usa secuencia `DROP ... IF EXISTS` antes si necesitas idempotencia.

## Business Logic & Future Work (per init.sql)
- Secciones 4-7 exigen consultas multi-join, vistas y CTE encadenados; ubícalos después del DDL dentro de cada script manteniendo el orden del guion.
- Sección 8 pide procedimientos almacenados para registrar libros, préstamos y devoluciones con validaciones y manejo de errores `BEGIN ... EXCEPTION`.
- Sección 9 requiere triggers para impedir préstamos duplicados y estados incoherentes; dispara sobre `Prestamo` y `Libro` una vez las tablas estén completas.
- Secciones 11-13 definen un DW dimensional (libro, obra, autor, área, usuario, fecha + hecho préstamo); mantén nombres en español y documenta surrogate keys.

## Testing Expectations
- Cada módulo nuevo debe tener ejemplos de inserción mínima (8 registros por tabla) y consultas de verificación inmediatas para que el docente pueda correrlas secuencialmente.
- Antes de cerrar una sección del guion, agrega consultas de smoke-test (por ejemplo, contar préstamos activos vs. total de libros) justo debajo del bloque que los necesita.

## Coordination Tips
- Siempre revisa los `DROP` al principio de [init.sql](init.sql) para asegurar que los objetos mencionados ya existen en tu script actual; ajusta nombres si introduces tablas nuevas.
- Documenta supuestos (ej. reglas de disponibilidad) con comentarios `--` cortos encima de cada bloque SQL; evita comentarios redundantes dentro de las definiciones mismos.
- Si introduces más scripts, menciona su orden de ejecución en [init.sql](init.sql) para mantener la narrativa única.
