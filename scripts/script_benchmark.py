import time
import psycopg2

print("SCRIPT BENCHMARK INICIADO")


def wait_for_db(host, port, user, password, dbname, max_attempts=30):
    """Espera a que la base de datos esté lista."""
    for attempt in range(max_attempts):
        try:
            conn = psycopg2.connect(
                host=host, port=port, user=user, password=password, dbname=dbname
            )
            conn.close()
            print("Base de datos lista.")
            return True
        except psycopg2.OperationalError:
            print(f"Esperando BD... intento {attempt + 1}/{max_attempts}")
            time.sleep(2)
    return False


def main():
    # Configuración de conexión - IP del contenedor postgres
    db_settings = {
        "host": "postgres",
        "port": 5432,
        "user": "postgres",
        "password": "password",
        "dbname": "e_shopify_db",
    }

    # Esperar a que la BD esté lista
    if not wait_for_db(**db_settings):
        print("No se pudo conectar a la base de datos.")
        return

    # Conectar con logging
    conn = psycopg2.connect(**db_settings)

    print("\n=== EVALUACIÓN DE RENDIMIENTO - PASO 3 ===")
    print("Ejecutando consultas frecuentes con medición manual de tiempos...\n")

    try:
        # Ejecutar consultas de prueba con medición manual
        with conn.cursor() as cursor:
            # Consulta 1: Productos de categoría Electrónica
            start = time.time()
            cursor.execute(
                "SELECT p.producto_id, p.nombre, p.precio, c.nombre as categoria FROM producto p JOIN categoria c ON p.categoria_id = c.categoria_id WHERE c.nombre = 'Electrónica' ORDER BY p.precio DESC;"
            )
            end = time.time()
            print(
                f"Consulta 1: Productos Electrónica - {int((end - start) * 1000)} ms - {cursor.rowcount} filas"
            )

            # Consulta 2: Contar pedidos
            start = time.time()
            cursor.execute("SELECT COUNT(*) FROM pedido;")
            end = time.time()
            result = cursor.fetchone()
            print(
                f"Consulta 2: Contar pedidos - {int((end - start) * 1000)} ms - {result[0]} filas"
            )

            # Operación 1: Insertar producto
            start = time.time()
            cursor.execute(
                "INSERT INTO producto (vendedor_id, categoria_id, nombre, descripcion, precio, activo) VALUES (1, 1, 'Producto de Prueba', 'Descripción', 99.99, TRUE);"
            )
            end = time.time()
            print(f"Operación 1: Insertar producto - {int((end - start) * 1000)} ms")

            # Operación 2: Actualizar precio
            start = time.time()
            cursor.execute(
                "UPDATE producto SET precio = 109.99 WHERE nombre = 'Producto de Prueba';"
            )
            end = time.time()
            print(f"Operación 2: Actualizar precio - {int((end - start) * 1000)} ms")

            # Consulta 3: Detalles de pedidos
            start = time.time()
            cursor.execute(
                "SELECT p.pedido_id, u.nombre as cliente, p.fecha_pedido, ep.nombre as estado, pi.producto_id, pr.nombre as producto, pi.cantidad, pi.precio_unitario, pi.subtotal FROM pedido p JOIN usuario u ON p.usuario_id = u.usuario_id JOIN estado_pedido ep ON p.estado_pedido_id = ep.estado_pedido_id JOIN pedido_item pi ON p.pedido_id = pi.pedido_id JOIN producto pr ON pi.producto_id = pr.producto_id ORDER BY p.pedido_id LIMIT 10;"
            )
            end = time.time()
            print(
                f"Consulta 3: Detalles pedidos - {int((end - start) * 1000)} ms - {cursor.rowcount} filas"
            )

            # Consulta 4: Promedio de calificaciones
            start = time.time()
            cursor.execute(
                "SELECT p.producto_id, p.nombre, AVG(r.calificacion) as promedio FROM producto p LEFT JOIN resena r ON p.producto_id = r.producto_id GROUP BY p.producto_id, p.nombre HAVING AVG(r.calificacion) > 4.0;"
            )
            end = time.time()
            print(
                f"Consulta 4: Promedio calificaciones - {int((end - start) * 1000)} ms - {cursor.rowcount} filas"
            )

            # Consulta 5: Ingresos por vendedor
            start = time.time()
            cursor.execute(
                "SELECT v.nombre_tienda, SUM(pi.subtotal) as ingresos_totales FROM vendedor v JOIN producto pr ON v.vendedor_id = pr.vendedor_id JOIN pedido_item pi ON pr.producto_id = pi.producto_id GROUP BY v.vendedor_id, v.nombre_tienda ORDER BY ingresos_totales DESC;"
            )
            end = time.time()
            print(
                f"Consulta 5: Ingresos vendedores - {int((end - start) * 1000)} ms - {cursor.rowcount} filas"
            )

            # Consulta lenta: LIKE search
            start = time.time()
            cursor.execute(
                "SELECT nombre, precio FROM producto WHERE nombre LIKE '%Laptop%';"
            )
            end = time.time()
            print(
                f"Consulta LIKE - {int((end - start) * 1000)} ms - {cursor.rowcount} filas"
            )

            # DELETE producto de prueba
            start = time.time()
            cursor.execute("DELETE FROM producto WHERE nombre = 'Producto de Prueba';")
            end = time.time()
            print(f"DELETE producto - {int((end - start) * 1000)} ms")

        conn.commit()
        print("\nDatos de prueba limpiados.")
    except Exception as e:
        print(f"Error: {e}")

    conn.close()
    print("Evaluación completada.")


if __name__ == "__main__":
    main()
