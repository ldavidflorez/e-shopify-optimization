import psycopg2
import psycopg2.extras
from faker import Faker
import random
import sys


def connect_db():
    """Conectar a la base de datos"""
    try:
        conn = psycopg2.connect(
            host="postgres",
            port=5432,
            user="postgres",
            password="password",
            dbname="e_shopify_db",
        )
        return conn
    except Exception as e:
        print(f"Error conectando a BD: {e}")
        sys.exit(1)


def populate_categories(conn, fake):
    """Poblar categorías"""
    categories = [
        ("Electrónica", "Dispositivos electrónicos y accesorios"),
        ("Ropa y Moda", "Prendas de vestir y accesorios de moda"),
        ("Hogar y Jardín", "Artículos para el hogar y jardín"),
        ("Deportes", "Equipos y accesorios deportivos"),
        ("Libros", "Libros físicos y digitales"),
        ("Juguetes", "Juguetes y juegos para todas las edades"),
        ("Belleza", "Productos de belleza y cuidado personal"),
        ("Automotriz", "Accesorios y repuestos para vehículos"),
        ("Música", "Instrumentos musicales y audio"),
        ("Oficina", "Artículos de oficina y papelería"),
    ]

    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO categoria (nombre, descripcion, activo) VALUES (%s, %s, %s) ON CONFLICT (nombre) DO NOTHING",
            [(name, desc, True) for name, desc in categories],
        )
    conn.commit()
    print("Categorías pobladas")


def populate_users(conn, fake, num_users=1000):
    """Poblar usuarios"""
    users = []
    existing_emails = set()

    # Obtener emails existentes
    with conn.cursor() as cursor:
        cursor.execute("SELECT email FROM usuario")
        existing_emails = set(row[0] for row in cursor.fetchall())

    for _ in range(num_users):
        email = fake.email()
        while email in existing_emails:
            email = fake.email()
        existing_emails.add(email)

        users.append(
            (
                fake.name(),
                email,
                "$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN"
                + str(random.randint(1, 1000)),
                fake.phone_number()[:20],  # Limitar longitud
                fake.date_time_between(start_date="-2y", end_date="now"),
            )
        )

    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO usuario (nombre, email, contrasena, telefono, fecha_registro) VALUES (%s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
            users,
        )
    conn.commit()
    print(f"{len(users)} usuarios poblados (posiblemente algunos ya existían)")


def populate_vendors(conn, fake, num_vendors=50):
    """Poblar vendedores"""
    # Obtener IDs de usuarios que no son vendedores aún
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT usuario_id FROM usuario WHERE usuario_id > 5 ORDER BY RANDOM() LIMIT %s",
            (num_vendors,),
        )
        user_ids = [row[0] for row in cursor.fetchall()]

    vendors = []
    existing_stores = set()

    # Obtener tiendas existentes
    with conn.cursor() as cursor:
        cursor.execute("SELECT nombre_tienda FROM vendedor")
        existing_stores = set(row[0] for row in cursor.fetchall())

    for user_id in user_ids:
        store_name = fake.company() + " Store"
        while store_name in existing_stores:
            store_name = fake.company() + " Store"
        existing_stores.add(store_name)

        vendors.append(
            (
                user_id,
                store_name,
                fake.text(max_nb_chars=200),
                random.choice([True, False]),
            )
        )

    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO vendedor (usuario_id, nombre_tienda, descripcion, activo) VALUES (%s, %s, %s, %s) ON CONFLICT (usuario_id) DO NOTHING",
            vendors,
        )
    conn.commit()
    print(f"{len(vendors)} vendedores poblados (posiblemente algunos ya existían)")


def populate_addresses(conn, fake, num_addresses=800):
    """Poblar direcciones"""
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT usuario_id FROM usuario ORDER BY RANDOM() LIMIT %s",
            (num_addresses,),
        )
        user_ids = [row[0] for row in cursor.fetchall()]

    addresses = []
    for user_id in user_ids:
        addresses.append(
            (
                user_id,
                fake.street_address(),
                fake.city(),
                str(random.randint(10000, 99999))[:20],  # Código postal aleatorio
                fake.country(),
                random.choice([True, False]),
            )
        )

    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO direccion (usuario_id, direccion, ciudad, codigo_postal, pais, es_principal) VALUES (%s, %s, %s, %s, %s, %s)",
            addresses,
        )
    conn.commit()
    print(f"{num_addresses} direcciones pobladas")


def populate_products(conn, fake, num_products=5000):
    """Poblar productos"""
    # Obtener categorías y vendedores
    with conn.cursor() as cursor:
        cursor.execute("SELECT categoria_id FROM categoria")
        category_ids = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT vendedor_id FROM vendedor")
        vendor_ids = [row[0] for row in cursor.fetchall()]

    products = []
    product_names = [
        "Laptop",
        "Mouse",
        "Teclado",
        "Monitor",
        "Smartphone",
        "Tablet",
        "Audífonos",
        "Camiseta",
        "Pantalón",
        "Zapatos",
        "Chaqueta",
        "Vestido",
        "Bolso",
        "Silla",
        "Mesa",
        "Lámpara",
        "Cortinas",
        "Almohada",
        "Sábanas",
        "Pelota",
        "Raqueta",
        "Bicicleta",
        "Pesas",
        "Colchoneta",
        "Novela",
        "Texto",
        "Cómic",
        "Libro infantil",
        "Muñeca",
        "Auto de juguete",
        "Lego",
        "Puzzle",
        "Crema",
        "Shampoo",
        "Perfume",
        "Maquillaje",
        "Aceite",
        "Filtros",
        "Llantas",
        "Batería",
        "Guitarra",
        "Piano",
        "Micrófono",
        "Altavoces",
        "Escritorio",
        "Silla ergonómica",
        "Archivador",
        "Impresora",
    ]

    for _ in range(num_products):
        name = random.choice(product_names) + " " + fake.word().capitalize()
        products.append(
            (
                random.choice(vendor_ids),
                random.choice(category_ids),
                name[:255],  # Limitar longitud
                fake.text(max_nb_chars=500),
                round(random.uniform(10, 2000), 2),
                fake.image_url()[:255],
                random.choice([True, True, True, False]),  # 75% activos
            )
        )

    # Insertar en lotes para mejor rendimiento
    batch_size = 1000
    with conn.cursor() as cursor:
        for i in range(0, len(products), batch_size):
            batch = products[i : i + batch_size]
            cursor.executemany(
                "INSERT INTO producto (vendedor_id, categoria_id, nombre, descripcion, precio, imagen, activo) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                batch,
            )
    conn.commit()
    print(f"{num_products} productos poblados")


def populate_inventory(conn, fake):
    """Poblar inventario para todos los productos"""
    with conn.cursor() as cursor:
        cursor.execute("SELECT producto_id FROM producto")
        product_ids = [row[0] for row in cursor.fetchall()]

    inventory = []
    for product_id in product_ids:
        inventory.append(
            (
                product_id,
                random.randint(0, 1000),  # cantidad_disponible
                random.randint(0, 50),  # cantidad_reservada
            )
        )

    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO inventario (producto_id, cantidad_disponible, cantidad_reservada) VALUES (%s, %s, %s) ON CONFLICT (producto_id) DO NOTHING",
            inventory,
        )
    conn.commit()
    print(
        f"Inventario poblado para {len(inventory)} productos (posiblemente algunos ya existían)"
    )


def populate_reviews(conn, fake, num_reviews=10000):
    """Poblar reseñas"""
    # Obtener productos y usuarios
    with conn.cursor() as cursor:
        cursor.execute("SELECT producto_id FROM producto")
        product_ids = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT usuario_id FROM usuario")
        user_ids = [row[0] for row in cursor.fetchall()]

    reviews = []
    for _ in range(num_reviews):
        reviews.append(
            (
                random.choice(user_ids),
                random.choice(product_ids),
                random.randint(1, 5),
                fake.text(max_nb_chars=300),
                random.randint(0, 100),
            )
        )

    # Insertar en lotes
    batch_size = 2000
    with conn.cursor() as cursor:
        for i in range(0, len(reviews), batch_size):
            batch = reviews[i : i + batch_size]
            cursor.executemany(
                "INSERT INTO resena (usuario_id, producto_id, calificacion, comentario, util) VALUES (%s, %s, %s, %s, %s)",
                batch,
            )
    conn.commit()
    print(f"{num_reviews} reseñas pobladas")


def populate_carts_and_orders(conn, fake, num_orders=2000):
    """Poblar carritos y pedidos"""
    # Obtener usuarios y direcciones
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT usuario_id FROM usuario ORDER BY RANDOM() LIMIT %s", (num_orders,)
        )
        user_ids = [row[0] for row in cursor.fetchall()]

        cursor.execute("SELECT direccion_id, usuario_id FROM direccion")
        address_map = {row[1]: row[0] for row in cursor.fetchall()}

    # Crear carritos
    carts = [(user_id,) for user_id in user_ids[: len(user_ids) // 2]]
    with conn.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO carrito (usuario_id) VALUES (%s) ON CONFLICT (usuario_id) DO NOTHING",
            carts,
        )
    conn.commit()

    # Obtener productos
    with conn.cursor() as cursor:
        cursor.execute("SELECT producto_id, precio FROM producto WHERE activo = true")
        products = cursor.fetchall()

    # Crear pedidos
    orders = []

    for i, user_id in enumerate(user_ids):
        address_id = address_map.get(user_id, 1)
        order_date = fake.date_time_between(start_date="-1y", end_date="now")

        # Crear pedido
        subtotal = 0
        num_items = random.randint(1, 5)
        items = random.sample(products, num_items)

        for product_id, price in items:
            quantity = random.randint(1, 3)
            price_float = float(price)
            subtotal += price_float * quantity

        tax = subtotal * 0.19  # 19% IVA
        shipping = random.uniform(5, 50)
        total = subtotal + tax + shipping

        orders.append(
            (
                user_id,
                address_id,
                random.randint(1, 6),  # estado_pedido_id
                order_date,
                subtotal,
                tax,
                shipping,
                total,
            )
        )

    # Insertar pedidos uno por uno para manejar conflictos y obtener IDs reales
    order_items = []
    payments = []

    for i, order_data in enumerate(orders):
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO pedido (usuario_id, direccion_id, estado_pedido_id, fecha_pedido, monto_subtotal, monto_impuesto, monto_envio, monto_total) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING RETURNING pedido_id",
                    order_data,
                )
                result = cursor.fetchone()
                if result:
                    pedido_id = result[0]

                    # Agregar items para este pedido
                    num_items = random.randint(1, 5)
                    items = random.sample(products, num_items)
                    for product_id, price in items:
                        quantity = random.randint(1, 3)
                        price_float = float(price)
                        order_items.append(
                            (
                                pedido_id,
                                product_id,
                                quantity,
                                price_float,
                                price_float * quantity,
                            )
                        )

                    # Agregar pago para este pedido
                    total = order_data[7]  # monto_total
                    payments.append(
                        (
                            pedido_id,
                            random.randint(1, 5),  # metodo_pago_id
                            random.randint(1, 5),  # estado_pago_id
                            total,
                            f"REF-{pedido_id:04d}-2024",
                        )
                    )
        except Exception as e:
            print(f"Error insertando pedido {i + 1}: {e}")
            continue

    # Insertar items y pagos
    if order_items:
        with conn.cursor() as cursor:
            cursor.executemany(
                "INSERT INTO pedido_item (pedido_id, producto_id, cantidad, precio_unitario, subtotal) VALUES (%s, %s, %s, %s, %s)",
                order_items,
            )
            cursor.executemany(
                "INSERT INTO pago (pedido_id, metodo_pago_id, estado_pago_id, monto, referencia_pago) VALUES (%s, %s, %s, %s, %s)",
                payments,
            )

    conn.commit()
    print(f"{len(payments)} pedidos con {len(order_items)} items y pagos poblados")


def main():
    fake = Faker("es_CO")  # Datos en español colombiano

    print("Conectando a la base de datos...")
    conn = connect_db()

    print("Iniciando población masiva de datos...")

    try:
        populate_categories(conn, fake)
        populate_users(conn, fake, 1000)
        populate_vendors(conn, fake, 50)
        populate_addresses(conn, fake, 800)
        populate_products(conn, fake, 5000)
        populate_inventory(conn, fake)
        populate_reviews(conn, fake, 10000)
        populate_carts_and_orders(conn, fake, 2000)

        print("¡Población completada exitosamente!")

        # Mostrar estadísticas finales
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT 'usuarios' as tabla, COUNT(*) as cantidad FROM usuario UNION ALL SELECT 'productos', COUNT(*) FROM producto UNION ALL SELECT 'pedidos', COUNT(*) FROM pedido UNION ALL SELECT 'reseñas', COUNT(*) FROM resena"
            )
            stats = cursor.fetchall()

        print("\nEstadísticas finales:")
        for tabla, cantidad in stats:
            print(f"- {tabla}: {cantidad}")

    except Exception as e:
        print(f"Error durante la población: {e}")
        conn.rollback()
    finally:
        conn.close()


if __name__ == "__main__":
    main()
