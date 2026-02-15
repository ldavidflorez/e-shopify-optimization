# Scripts de Benchmark para E-Shopify

Este directorio contiene scripts automatizados para ejecutar benchmarks comparativos entre la base de datos baseline y la optimizada.

## Scripts Disponibles

### 1. `run_baseline.sh`
Ejecuta el benchmark completo con la base de datos que tiene únicamente índices básicos.
- Limpia contenedores anteriores
- Levanta PostgreSQL
- Carga el schema básico (`sql/e-shopify-db.sql`)
- Pobla datos de prueba
- Ejecuta el benchmark
- Muestra resultados

### 2. `run_optimized.sh`
Ejecuta el benchmark completo con la base de datos optimizada.
- Limpia contenedores anteriores
- Levanta PostgreSQL
- Carga el schema optimizado (`sql/e-shopify-db-optimized.sql`)
- Pobla datos de prueba
- Ejecuta el benchmark
- Muestra resultados

## Uso

```bash
# Ejecutar solo baseline
./run_baseline.sh

# Ejecutar solo optimizado
./run_optimized.sh
```

## Requisitos

- Docker y Docker Compose instalados
- Permisos de ejecución en los scripts
- Puerto 5432 disponible (PostgreSQL)
- Puerto 8080 disponible (pgAdmin)

## Resultados

Cada script mostrará los tiempos de ejecución para:
- Consulta 1: Productos por categoría
- Consulta 2: Contar pedidos totales
- Operación 1: Insertar producto
- Operación 2: Actualizar precio
- Consulta 3: Detalles de pedidos
- Consulta 4: Promedio de calificaciones
- Consulta 5: Ingresos por vendedor
- Consulta LIKE: Búsqueda de productos
- DELETE: Eliminar producto

## Notas

- Los scripts limpian automáticamente **solo los contenedores y volúmenes de esta aplicación** (`docker-compose down -v`)
- El dataset utilizado es idéntico en ambos casos (~5K productos, ~1K pedidos)
- Los tiempos pueden variar ligeramente entre ejecuciones debido a factores del sistema
- Los logs detallados se guardan en archivos `.log` para análisis posterior