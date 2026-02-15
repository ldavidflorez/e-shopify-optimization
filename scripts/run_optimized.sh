#!/bin/bash

echo "=== EJECUTANDO BENCHMARK OPTIMIZED ==="
echo "Base de datos con optimizaciones avanzadas (índices compuestos, vistas materializadas, etc.)"
echo ""

# Cambiar al directorio raíz del proyecto
cd "$(dirname "$0")/.."

# Cambiar al directorio docker para usar docker-compose
cd docker

# Limpiar contenedores y volúmenes de esta aplicación únicamente
echo "Limpiando contenedores de la aplicación..."
docker-compose down -v 2>/dev/null || true
docker rm -f e-shopify-db e-shopify-pgadmin e-shopify-populate e-shopify-benchmark 2>/dev/null || true

# Levantar PostgreSQL
echo "Levantando PostgreSQL..."
docker-compose up -d postgres pgadmin

# Esperar a que PostgreSQL esté listo
echo "Esperando que PostgreSQL esté listo..."
sleep 15

# Verificar conexión
echo "Verificando conexión a la base de datos..."
docker-compose exec postgres pg_isready -h localhost -p 5432 -U postgres -d e_shopify_db

if [ $? -ne 0 ]; then
    echo "ERROR: No se pudo conectar a PostgreSQL"
    exit 1
fi

# Cargar schema optimizado
echo "Cargando schema optimizado..."
cat ../sql/e-shopify-db-optimized.sql | docker-compose exec -T postgres psql -U postgres -d postgres

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la carga del schema optimizado"
    exit 1
fi

# Poblar datos
echo "Poblando datos de prueba..."
docker-compose up populate

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la población de datos"
    exit 1
fi

# Ejecutar benchmark y capturar salida
echo "Ejecutando benchmark..."
benchmark_output=$(docker-compose up benchmark 2>&1)

echo ""
echo "=== RESULTADOS OPTIMIZADOS EN CSV ==="

# Crear archivo CSV con los resultados
echo "Operación/Consulta,Tiempo (ms),Filas,Descripción" > ../results/benchmark_optimized.csv

# Extraer cada línea de resultados y agregar al CSV
consulta1=$(echo "$benchmark_output" | grep "Consulta 1:" | sed 's/.*Consulta 1: Productos Electrónica - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
consulta2=$(echo "$benchmark_output" | grep "Consulta 2:" | sed 's/.*Consulta 2: Contar pedidos - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
operacion1=$(echo "$benchmark_output" | grep "Operación 1:" | sed 's/.*Operación 1: Insertar producto - \([0-9]*\) ms.*/\1,0/')
operacion2=$(echo "$benchmark_output" | grep "Operación 2:" | sed 's/.*Operación 2: Actualizar precio - \([0-9]*\) ms.*/\1,0/')
consulta3=$(echo "$benchmark_output" | grep "Consulta 3:" | sed 's/.*Consulta 3: Detalles pedidos - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
consulta4=$(echo "$benchmark_output" | grep "Consulta 4:" | sed 's/.*Consulta 4: Promedio calificaciones - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
consulta5=$(echo "$benchmark_output" | grep "Consulta 5:" | sed 's/.*Consulta 5: Ingresos vendedores - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
consulta_like=$(echo "$benchmark_output" | grep "Consulta LIKE" | sed 's/.*Consulta LIKE - \([0-9]*\) ms - \([0-9]*\) filas.*/\1,\2/')
delete_op=$(echo "$benchmark_output" | grep "DELETE producto" | sed 's/.*DELETE producto - \([0-9]*\) ms.*/\1,-/')

echo "Consulta 1,$consulta1,Buscar productos de la categoría \"Electrónica\"" >> ../results/benchmark_optimized.csv
echo "Consulta 2,$consulta2,Obtener el número total de pedidos" >> ../results/benchmark_optimized.csv
echo "Operación 1,$operacion1,Agregar un nuevo producto" >> ../results/benchmark_optimized.csv
echo "Operación 2,$operacion2,Actualizar el precio de un producto" >> ../results/benchmark_optimized.csv
echo "Consulta 3,$consulta3,Obtener detalles de pedidos con productos" >> ../results/benchmark_optimized.csv
echo "Consulta 4,$consulta4,Calcular promedio de calificaciones por producto" >> ../results/benchmark_optimized.csv
echo "Consulta 5,$consulta5,Reporte de ingresos por vendedor" >> ../results/benchmark_optimized.csv
echo "Consulta lenta,$consulta_like,Búsqueda de productos por nombre (LIKE)" >> ../results/benchmark_optimized.csv
echo "Operación DELETE,$delete_op,Eliminar producto de prueba" >> ../results/benchmark_optimized.csv

echo "Archivo CSV generado: ../results/benchmark_optimized.csv"
echo ""
echo "Contenido del CSV:"
cat ../results/benchmark_optimized.csv
echo ""
echo "Para comparar con baseline, ejecuta: ./run_baseline.sh"