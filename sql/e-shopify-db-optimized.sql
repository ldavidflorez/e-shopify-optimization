-- ============================================================================
-- BASE DE DATOS E-SHOPIFY - VERSIÓN OPTIMIZADA (ACTIVIDAD S4)
-- ============================================================================
-- Este archivo contiene la estructura base más las optimizaciones implementadas:
-- - Índices compuestos para consultas frecuentes.
-- - Desnormalización controlada (promedio de calificaciones).
-- - Vista materializada para reportes.
-- ============================================================================

-- Crear la base de datos (si no existe)
CREATE DATABASE IF NOT EXISTS e_shopify_db;

-- Conectar a la base de datos
\c e_shopify_db;

-- ============================================================================
-- ESTRUCTURA BASE (De e-shopify-db.sql original)
-- ============================================================================

-- Tablas de catálogo
CREATE TABLE IF NOT EXISTS estado_pedido (
    estado_pedido_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    orden INT NOT NULL,
    CONSTRAINT chk_nombre_estado_pedido CHECK (nombre != '')
);

CREATE TABLE IF NOT EXISTS estado_pago (
    estado_pago_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    CONSTRAINT chk_nombre_estado_pago CHECK (nombre != '')
);

CREATE TABLE IF NOT EXISTS metodo_pago (
    metodo_pago_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_nombre_metodo_pago CHECK (nombre != '')
);

CREATE TABLE IF NOT EXISTS categoria (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_nombre_categoria CHECK (nombre != '')
);

-- Tablas principales
CREATE TABLE IF NOT EXISTS usuario (
    usuario_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_email_usuario UNIQUE (email),
    CONSTRAINT chk_email_usuario CHECK (email LIKE '%@%'),
    CONSTRAINT chk_nombre_usuario CHECK (nombre != '')
);

CREATE TABLE IF NOT EXISTS vendedor (
    vendedor_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    nombre_tienda VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vendedor_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT chk_nombre_tienda CHECK (nombre_tienda != '')
);

CREATE TABLE IF NOT EXISTS direccion (
    direccion_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(20),
    pais VARCHAR(100) NOT NULL,
    es_principal BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_direccion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT chk_direccion CHECK (direccion != ''),
    CONSTRAINT chk_ciudad CHECK (ciudad != ''),
    CONSTRAINT chk_pais CHECK (pais != '')
);

CREATE TABLE IF NOT EXISTS producto (
    producto_id SERIAL PRIMARY KEY,
    vendedor_id INT NOT NULL,
    categoria_id INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    imagen VARCHAR(255),
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_producto_vendedor FOREIGN KEY (vendedor_id) REFERENCES vendedor(vendedor_id) ON DELETE CASCADE,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES categoria(categoria_id),
    CONSTRAINT chk_nombre_producto CHECK (nombre != ''),
    CONSTRAINT chk_precio_producto CHECK (precio > 0)
);

CREATE TABLE IF NOT EXISTS inventario (
    inventario_id SERIAL PRIMARY KEY,
    producto_id INT NOT NULL UNIQUE,
    cantidad_disponible INT NOT NULL DEFAULT 0,
    cantidad_reservada INT NOT NULL DEFAULT 0,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventario_producto FOREIGN KEY (producto_id) REFERENCES producto(producto_id) ON DELETE CASCADE,
    CONSTRAINT chk_cantidad_disponible CHECK (cantidad_disponible >= 0),
    CONSTRAINT chk_cantidad_reservada CHECK (cantidad_reservada >= 0)
);

CREATE TABLE IF NOT EXISTS detalles_envio (
    detalle_envio_id SERIAL PRIMARY KEY,
    inventario_id INT NOT NULL,
    peso DECIMAL(8, 2),
    dimensiones VARCHAR(100),
    costo_envio DECIMAL(10, 2),
    tiempo_estimado_dias INT,
    CONSTRAINT fk_detalles_envio_inventario FOREIGN KEY (inventario_id) REFERENCES inventario(inventario_id) ON DELETE CASCADE,
    CONSTRAINT chk_peso CHECK (peso > 0),
    CONSTRAINT chk_costo_envio CHECK (costo_envio >= 0),
    CONSTRAINT chk_tiempo_estimado CHECK (tiempo_estimado_dias > 0)
);

CREATE TABLE IF NOT EXISTS resena (
    resena_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    producto_id INT NOT NULL,
    calificacion INT NOT NULL,
    comentario TEXT,
    fecha_resena TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    util INT DEFAULT 0,
    CONSTRAINT fk_resena_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT fk_resena_producto FOREIGN KEY (producto_id) REFERENCES producto(producto_id) ON DELETE CASCADE,
    CONSTRAINT chk_calificacion CHECK (calificacion >= 1 AND calificacion <= 5),
    CONSTRAINT chk_util CHECK (util >= 0)
);

CREATE TABLE IF NOT EXISTS carrito (
    carrito_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrito_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS carrito_item (
    carrito_item_id SERIAL PRIMARY KEY,
    carrito_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrito_item_carrito FOREIGN KEY (carrito_id) REFERENCES carrito(carrito_id) ON DELETE CASCADE,
    CONSTRAINT fk_carrito_item_producto FOREIGN KEY (producto_id) REFERENCES producto(producto_id) ON DELETE CASCADE,
    CONSTRAINT chk_cantidad_carrito CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unitario_carrito CHECK (precio_unitario > 0),
    CONSTRAINT uk_carrito_producto UNIQUE (carrito_id, producto_id)
);

CREATE TABLE IF NOT EXISTS pedido (
    pedido_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    direccion_id INT NOT NULL,
    estado_pedido_id INT NOT NULL,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto_subtotal DECIMAL(10, 2) NOT NULL,
    monto_impuesto DECIMAL(10, 2) NOT NULL DEFAULT 0,
    monto_envio DECIMAL(10, 2) NOT NULL DEFAULT 0,
    monto_total DECIMAL(10, 2) NOT NULL,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_direccion FOREIGN KEY (direccion_id) REFERENCES direccion(direccion_id),
    CONSTRAINT fk_pedido_estado FOREIGN KEY (estado_pedido_id) REFERENCES estado_pedido(estado_pedido_id),
    CONSTRAINT chk_monto_subtotal CHECK (monto_subtotal >= 0),
    CONSTRAINT chk_monto_impuesto CHECK (monto_impuesto >= 0),
    CONSTRAINT chk_monto_envio CHECK (monto_envio >= 0),
    CONSTRAINT chk_monto_total CHECK (monto_total >= 0)
);

CREATE TABLE IF NOT EXISTS pedido_item (
    pedido_item_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_pedido_item_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_item_producto FOREIGN KEY (producto_id) REFERENCES producto(producto_id),
    CONSTRAINT chk_cantidad_pedido_item CHECK (cantidad > 0),
    CONSTRAINT chk_precio_unitario_pedido_item CHECK (precio_unitario > 0),
    CONSTRAINT chk_subtotal_pedido_item CHECK (subtotal > 0)
);

CREATE TABLE IF NOT EXISTS pago (
    pago_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL,
    metodo_pago_id INT NOT NULL,
    estado_pago_id INT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    referencia_pago VARCHAR(100),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id) ON DELETE CASCADE,
    CONSTRAINT fk_pago_metodo FOREIGN KEY (metodo_pago_id) REFERENCES metodo_pago(metodo_pago_id),
    CONSTRAINT fk_pago_estado FOREIGN KEY (estado_pago_id) REFERENCES estado_pago(estado_pago_id),
    CONSTRAINT chk_monto_pago CHECK (monto > 0)
);

CREATE TABLE IF NOT EXISTS notificacion (
    notificacion_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    asunto VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_lectura TIMESTAMP,
    CONSTRAINT fk_notificacion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT chk_tipo_notificacion CHECK (tipo IN ('PEDIDO', 'PAGO', 'PRODUCTO', 'RESENA', 'SISTEMA')),
    CONSTRAINT chk_asunto CHECK (asunto != ''),
    CONSTRAINT chk_mensaje CHECK (mensaje != '')
);

CREATE TABLE IF NOT EXISTS historial_estado_pedido (
    historial_id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL,
    estado_anterior_id INT,
    estado_nuevo_id INT NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario_id INT,
    razon TEXT,
    CONSTRAINT fk_historial_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id) ON DELETE CASCADE,
    CONSTRAINT fk_historial_estado_anterior FOREIGN KEY (estado_anterior_id) REFERENCES estado_pedido(estado_pedido_id),
    CONSTRAINT fk_historial_estado_nuevo FOREIGN KEY (estado_nuevo_id) REFERENCES estado_pedido(estado_pedido_id),
    CONSTRAINT fk_historial_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE SET NULL
);

-- ============================================================================
-- ÍNDICES ORIGINALES (De e-shopify-db.sql)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_usuario_email ON usuario(email);
CREATE INDEX IF NOT EXISTS idx_producto_vendedor ON producto(vendedor_id);
CREATE INDEX IF NOT EXISTS idx_producto_categoria ON producto(categoria_id);
CREATE INDEX IF NOT EXISTS idx_pedido_usuario ON pedido(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pedido_estado ON pedido(estado_pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedido_fecha ON pedido(fecha_pedido);
CREATE INDEX IF NOT EXISTS idx_pago_pedido ON pago(pedido_id);
CREATE INDEX IF NOT EXISTS idx_resena_producto ON resena(producto_id);
CREATE INDEX IF NOT EXISTS idx_resena_usuario ON resena(usuario_id);
CREATE INDEX IF NOT EXISTS idx_carrito_usuario ON carrito(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificacion_usuario ON notificacion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificacion_leida ON notificacion(leida);

-- ============================================================================
-- OPTIMIZACIONES (PASO 4, 5 Y 6)
-- ============================================================================

-- Índices compuestos para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_producto_categoria_precio ON producto(categoria_id, precio DESC);
CREATE INDEX IF NOT EXISTS idx_pedido_usuario_fecha ON pedido(usuario_id, fecha_pedido DESC);
CREATE INDEX IF NOT EXISTS idx_producto_nombre_lower ON producto(lower(nombre));

-- Desnormalización: Agregar columnas para promedio de calificaciones
ALTER TABLE producto ADD COLUMN IF NOT EXISTS promedio_calificacion DECIMAL(3, 2) DEFAULT 0;
ALTER TABLE producto ADD COLUMN IF NOT EXISTS total_resenas INT DEFAULT 0;

-- Función para actualizar promedio
CREATE OR REPLACE FUNCTION actualizar_promedio_calificacion()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE producto
    SET
        promedio_calificacion = (SELECT COALESCE(AVG(calificacion), 0) FROM resena WHERE producto_id = NEW.producto_id),
        total_resenas = (SELECT COUNT(*) FROM resena WHERE producto_id = NEW.producto_id)
    WHERE producto_id = NEW.producto_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para mantener consistencia
DROP TRIGGER IF EXISTS trg_actualizar_calificacion ON resena;
CREATE TRIGGER trg_actualizar_calificacion
AFTER INSERT OR UPDATE OR DELETE ON resena
FOR EACH ROW
EXECUTE FUNCTION actualizar_promedio_calificacion();

-- Vista materializada para reportes de vendedores
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_metricas_vendedor AS
SELECT
    v.vendedor_id,
    v.nombre_tienda,
    COUNT(DISTINCT pi.pedido_id) as total_pedidos,
    SUM(pi.cantidad) as total_items_vendidos,
    SUM(pi.subtotal) as ingresos_totales,
    MAX(p.fecha_pedido) as ultima_venta
FROM vendedor v
LEFT JOIN producto pr ON v.vendedor_id = pr.vendedor_id
LEFT JOIN pedido_item pi ON pr.producto_id = pi.producto_id
LEFT JOIN pedido p ON pi.pedido_id = p.pedido_id
GROUP BY v.vendedor_id, v.nombre_tienda;

-- Índice en la vista materializada
CREATE INDEX IF NOT EXISTS idx_mv_metricas_ingresos ON mv_metricas_vendedor(ingresos_totales DESC);

-- ============================================================================
-- DATOS DE PRUEBA (Iguales al original)
-- ============================================================================

-- Insertar estados de pedido
INSERT INTO estado_pedido (nombre, descripcion, orden) VALUES
('Pendiente', 'Pedido creado, esperando confirmación de pago', 1),
('Confirmado', 'Pago confirmado, preparando envío', 2),
('Enviado', 'Pedido enviado al cliente', 3),
('Entregado', 'Pedido entregado al cliente', 4),
('Cancelado', 'Pedido cancelado por el cliente o vendedor', 5),
('Devuelto', 'Pedido devuelto por el cliente', 6)
ON CONFLICT (nombre) DO NOTHING;

-- Insertar estados de pago
INSERT INTO estado_pago (nombre, descripcion) VALUES
('Pendiente', 'Pago pendiente de procesar'),
('Procesando', 'Pago en proceso'),
('Completado', 'Pago completado exitosamente'),
('Fallido', 'Pago rechazado'),
('Reembolsado', 'Pago reembolsado al cliente')
ON CONFLICT (nombre) DO NOTHING;

-- Insertar métodos de pago
INSERT INTO metodo_pago (nombre, descripcion, activo) VALUES
('Tarjeta de Crédito', 'Visa, Mastercard, American Express', TRUE),
('Tarjeta de Débito', 'Débito directo de cuenta bancaria', TRUE),
('PayPal', 'Pago a través de PayPal', TRUE),
('Transferencia Bancaria', 'Transferencia directa a cuenta bancaria', TRUE),
('Billetera Digital', 'Pago con billetera digital', TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- Insertar categorías
INSERT INTO categoria (nombre, descripcion, activo) VALUES
('Electrónica', 'Dispositivos electrónicos y accesorios', TRUE),
('Ropa y Moda', 'Prendas de vestir y accesorios de moda', TRUE),
('Hogar y Jardín', 'Artículos para el hogar y jardín', TRUE),
('Deportes', 'Equipos y accesorios deportivos', TRUE),
('Libros', 'Libros físicos y digitales', TRUE),
('Juguetes', 'Juguetes y juegos para todas las edades', TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- Insertar usuarios (compradores)
INSERT INTO usuario (nombre, email, contrasena, telefono) VALUES
('Juan Pérez', 'juan.perez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN1', '3001234567'),
('María García', 'maria.garcia@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN2', '3012345678'),
('Carlos López', 'carlos.lopez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN3', '3023456789'),
('Ana Martínez', 'ana.martinez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN4', '3034567890'),
('Pedro Rodríguez', 'pedro.rodriguez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN5', '3045678901')
ON CONFLICT (email) DO NOTHING;

-- Insertar usuarios (vendedores)
INSERT INTO usuario (nombre, email, contrasena, telefono) VALUES
('TechStore Admin', 'techstore@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN6', '3056789012'),
('Fashion Hub Admin', 'fashionhub@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN7', '3067890123'),
('Home Essentials Admin', 'homeessentials@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN8', '3078901234')
ON CONFLICT (email) DO NOTHING;

-- Insertar vendedores
INSERT INTO vendedor (usuario_id, nombre_tienda, descripcion, activo) VALUES
(6, 'TechStore', 'Tienda especializada en electrónica y gadgets', TRUE),
(7, 'Fashion Hub', 'Tienda de ropa y accesorios de moda', TRUE),
(8, 'Home Essentials', 'Tienda de artículos para el hogar', TRUE)
ON CONFLICT (usuario_id) DO NOTHING;

-- Insertar direcciones
INSERT INTO direccion (usuario_id, direccion, ciudad, codigo_postal, pais, es_principal) VALUES
(1, 'Calle 123 #45-67', 'Cartagena', '130001', 'Colombia', TRUE),
(1, 'Carrera 50 #12-34', 'Cartagena', '130001', 'Colombia', FALSE),
(2, 'Avenida Principal 789', 'Bogotá', '110001', 'Colombia', TRUE),
(3, 'Calle 5 #10-20', 'Medellín', '050001', 'Colombia', TRUE),
(4, 'Carrera 7 #25-30', 'Cali', '760001', 'Colombia', TRUE),
(5, 'Avenida 19 #50-60', 'Barranquilla', '080001', 'Colombia', TRUE)
ON CONFLICT DO NOTHING;

-- Insertar productos
INSERT INTO producto (vendedor_id, categoria_id, nombre, descripcion, precio, imagen, activo) VALUES
(1, 1, 'Laptop Dell XPS 13', 'Laptop ultradelgada con procesador Intel i7', 1299.99, 'laptop_dell.jpg', TRUE),
(1, 1, 'Mouse Logitech MX Master 3', 'Mouse inalámbrico de precisión', 99.99, 'mouse_logitech.jpg', TRUE),
(1, 1, 'Teclado Mecánico RGB', 'Teclado mecánico con iluminación RGB', 149.99, 'teclado_mecanico.jpg', TRUE),
(2, 2, 'Camiseta Básica Blanca', 'Camiseta de algodón 100% puro', 29.99, 'camiseta_blanca.jpg', TRUE),
(2, 2, 'Jeans Azul Oscuro', 'Jeans clásico de alta calidad', 79.99, 'jeans_azul.jpg', TRUE),
(2, 2, 'Chaqueta de Cuero', 'Chaqueta de cuero genuino', 199.99, 'chaqueta_cuero.jpg', TRUE),
(3, 3, 'Lámpara LED de Escritorio', 'Lámpara LED ajustable para escritorio', 45.99, 'lampara_led.jpg', TRUE),
(3, 3, 'Almohada Ergonómica', 'Almohada de espuma viscoelástica', 59.99, 'almohada_ergonomica.jpg', TRUE),
(3, 3, 'Cortinas Blackout', 'Cortinas opacas para oscurecer la habitación', 89.99, 'cortinas_blackout.jpg', TRUE),
(1, 1, 'Monitor LG 27 pulgadas', 'Monitor 4K con panel IPS', 399.99, 'monitor_lg.jpg', TRUE)
ON CONFLICT DO NOTHING;

-- Insertar inventario
INSERT INTO inventario (producto_id, cantidad_disponible, cantidad_reservada) VALUES
(1, 15, 2),
(2, 50, 5),
(3, 30, 3),
(4, 100, 10),
(5, 75, 8),
(6, 20, 2),
(7, 60, 6),
(8, 45, 4),
(9, 35, 3),
(10, 25, 2)
ON CONFLICT (producto_id) DO NOTHING;

-- Insertar detalles de envío
INSERT INTO detalles_envio (inventario_id, peso, dimensiones, costo_envio, tiempo_estimado_dias) VALUES
(1, 2.5, '35x25x2 cm', 25.00, 3),
(2, 0.3, '15x10x5 cm', 5.00, 2),
(3, 1.0, '45x15x3 cm', 8.00, 2),
(4, 0.2, '30x20x2 cm', 4.00, 2),
(5, 0.8, '35x30x5 cm', 6.00, 2),
(6, 1.5, '60x40x10 cm', 15.00, 3),
(7, 0.5, '25x20x8 cm', 6.00, 2),
(8, 0.6, '40x30x10 cm', 7.00, 2),
(9, 2.0, '200x150x5 cm', 20.00, 3),
(10, 5.0, '65x50x10 cm', 30.00, 3)
ON CONFLICT DO NOTHING;

-- Insertar reseñas
INSERT INTO resena (usuario_id, producto_id, calificacion, comentario, util) VALUES
(1, 1, 5, 'Excelente laptop, muy rápida y ligera', 12),
(2, 1, 4, 'Buena calidad, pero un poco cara', 8),
(3, 2, 5, 'El mejor mouse que he usado', 15),
(4, 4, 4, 'Camiseta cómoda y de buena calidad', 6),
(5, 5, 3, 'Los jeans son buenos pero se destiñen', 4),
(1, 7, 5, 'Lámpara perfecta para trabajar', 10),
(2, 8, 4, 'Almohada muy cómoda', 7),
(3, 10, 5, 'Monitor excelente para diseño gráfico', 14)
ON CONFLICT DO NOTHING;

-- Insertar carritos
INSERT INTO carrito (usuario_id) VALUES
(1), (2), (3), (4), (5)
ON CONFLICT (usuario_id) DO NOTHING;

-- Insertar items en carrito
INSERT INTO carrito_item (carrito_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 1299.99),
(1, 2, 2, 99.99),
(2, 4, 3, 29.99),
(2, 5, 1, 79.99),
(3, 7, 2, 45.99),
(4, 10, 1, 399.99),
(5, 6, 1, 199.99)
ON CONFLICT (carrito_id, producto_id) DO NOTHING;

-- Insertar pedidos
INSERT INTO pedido (usuario_id, direccion_id, estado_pedido_id, monto_subtotal, monto_impuesto, monto_envio, monto_total) VALUES
(1, 1, 2, 1299.99, 194.99, 25.00, 1519.98),
(2, 3, 3, 89.97, 13.49, 6.00, 109.46),
(3, 4, 4, 45.99, 6.89, 6.00, 58.88),
(4, 5, 2, 399.99, 59.99, 30.00, 489.98),
(5, 6, 1, 199.99, 29.99, 15.00, 244.98)
ON CONFLICT DO NOTHING;

-- Insertar items de pedido
INSERT INTO pedido_item (pedido_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 1, 1299.99, 1299.99),
(2, 4, 3, 29.99, 89.97),
(3, 7, 1, 45.99, 45.99),
(4, 10, 1, 399.99, 399.99),
(5, 6, 1, 199.99, 199.99)
ON CONFLICT DO NOTHING;

-- Insertar pagos
INSERT INTO pago (pedido_id, metodo_pago_id, estado_pago_id, monto, referencia_pago) VALUES
(1, 1, 3, 1519.98, 'REF-001-2024'),
(2, 1, 3, 109.46, 'REF-002-2024'),
(3, 3, 3, 58.88, 'REF-003-2024'),
(4, 1, 2, 489.98, 'REF-004-2024'),
(5, 2, 1, 244.98, 'REF-005-2024')
ON CONFLICT DO NOTHING;

-- Insertar notificaciones
INSERT INTO notificacion (usuario_id, tipo, asunto, mensaje, leida) VALUES
(1, 'PEDIDO', 'Pedido Confirmado', 'Tu pedido #1 ha sido confirmado y está siendo preparado', TRUE),
(2, 'PEDIDO', 'Pedido Enviado', 'Tu pedido #2 ha sido enviado', TRUE),
(3, 'PEDIDO', 'Pedido Entregado', 'Tu pedido #3 ha sido entregado', TRUE),
(4, 'PAGO', 'Pago Pendiente', 'Tu pago para el pedido #4 está pendiente de procesar', FALSE),
(5, 'SISTEMA', 'Bienvenida', 'Bienvenido a e-Shopify', TRUE)
ON CONFLICT DO NOTHING;

-- Insertar historial de estados de pedido
INSERT INTO historial_estado_pedido (pedido_id, estado_anterior_id, estado_nuevo_id, usuario_id, razon) VALUES
(1, 1, 2, 6, 'Pago confirmado'),
(2, 1, 2, 7, 'Pago confirmado'),
(2, 2, 3, 7, 'Pedido enviado'),
(3, 1, 2, 8, 'Pago confirmado'),
(3, 2, 3, 8, 'Pedido enviado'),
(3, 3, 4, 8, 'Pedido entregado')
ON CONFLICT DO NOTHING;

-- Recálculo inicial de promedios (después de insertar datos)
UPDATE producto p
SET
    promedio_calificacion = (SELECT COALESCE(AVG(calificacion), 0) FROM resena r WHERE r.producto_id = p.producto_id),
    total_resenas = (SELECT COUNT(*) FROM resena r WHERE r.producto_id = p.producto_id);

-- ============================================================================
-- CONSULTAS DE VALIDACIÓN OPTIMIZADAS
-- ============================================================================

-- 1. Productos por categoría ordenados por precio (Usa idx_producto_categoria_precio)
-- EXPLAIN ANALYZE
SELECT nombre, precio
FROM producto
WHERE categoria_id = 1
ORDER BY precio DESC;

-- 2. Historial de pedidos por usuario (Usa idx_pedido_usuario_fecha)
-- EXPLAIN ANALYZE
SELECT pedido_id, fecha_pedido, monto_total
FROM pedido
WHERE usuario_id = 1
ORDER BY fecha_pedido DESC;

-- 3. Búsqueda por nombre (Usa idx_producto_nombre_lower)
-- EXPLAIN ANALYZE
SELECT nombre, precio
FROM producto
WHERE lower(nombre) LIKE lower('%laptop%');

-- 4. Productos con calificaciones altas (Lectura directa, sin JOIN)
-- EXPLAIN ANALYZE
SELECT nombre, promedio_calificacion, total_resenas
FROM producto
WHERE promedio_calificacion > 4.0
ORDER BY promedio_calificacion DESC;

-- 5. Reporte de vendedores (Vista materializada)
-- EXPLAIN ANALYZE
SELECT * FROM mv_metricas_vendedor ORDER BY ingresos_totales DESC;

-- Para refrescar la vista materializada (ejecutar periódicamente)
-- REFRESH MATERIALIZED VIEW mv_metricas_vendedor;

-- ============================================================================
-- FIN DEL ARCHIVO OPTIMIZADO
-- ============================================================================