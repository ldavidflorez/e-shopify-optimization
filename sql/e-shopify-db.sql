-- ============================================================================
-- BASE DE DATOS E-SHOPIFY - IMPLEMENTACIÓN NORMALIZADA (3FN/BCNF)
-- Sistema de Gestión de Comercio Electrónico
-- ============================================================================

-- Crear la base de datos
CREATE DATABASE e_shopify_db;

-- Conectar a la base de datos
\c e_shopify_db;

-- ============================================================================
-- TABLAS DE CATÁLOGO (Dominios de Valores)
-- ============================================================================

-- Tabla: ESTADO_PEDIDO
CREATE TABLE estado_pedido (
    estado_pedido_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    orden INT NOT NULL,
    CONSTRAINT chk_nombre_estado_pedido CHECK (nombre != '')
);

-- Tabla: ESTADO_PAGO
CREATE TABLE estado_pago (
    estado_pago_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    CONSTRAINT chk_nombre_estado_pago CHECK (nombre != '')
);

-- Tabla: METODO_PAGO
CREATE TABLE metodo_pago (
    metodo_pago_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_nombre_metodo_pago CHECK (nombre != '')
);

-- Tabla: CATEGORIA
CREATE TABLE categoria (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_nombre_categoria CHECK (nombre != '')
);

-- ============================================================================
-- TABLAS PRINCIPALES
-- ============================================================================

-- Tabla: USUARIO
CREATE TABLE usuario (
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

-- Tabla: VENDEDOR
CREATE TABLE vendedor (
    vendedor_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    nombre_tienda VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vendedor_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE,
    CONSTRAINT chk_nombre_tienda CHECK (nombre_tienda != '')
);

-- Tabla: DIRECCION
CREATE TABLE direccion (
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

-- Tabla: PRODUCTO
CREATE TABLE producto (
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

-- Tabla: INVENTARIO
CREATE TABLE inventario (
    inventario_id SERIAL PRIMARY KEY,
    producto_id INT NOT NULL UNIQUE,
    cantidad_disponible INT NOT NULL DEFAULT 0,
    cantidad_reservada INT NOT NULL DEFAULT 0,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventario_producto FOREIGN KEY (producto_id) REFERENCES producto(producto_id) ON DELETE CASCADE,
    CONSTRAINT chk_cantidad_disponible CHECK (cantidad_disponible >= 0),
    CONSTRAINT chk_cantidad_reservada CHECK (cantidad_reservada >= 0)
);

-- Tabla: DETALLES_ENVIO
CREATE TABLE detalles_envio (
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

-- Tabla: RESENA
CREATE TABLE resena (
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

-- Tabla: CARRITO
CREATE TABLE carrito (
    carrito_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrito_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id) ON DELETE CASCADE
);

-- Tabla: CARRITO_ITEM
CREATE TABLE carrito_item (
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

-- Tabla: PEDIDO
CREATE TABLE pedido (
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

-- Tabla: PEDIDO_ITEM
CREATE TABLE pedido_item (
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

-- Tabla: PAGO
CREATE TABLE pago (
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

-- Tabla: NOTIFICACION
CREATE TABLE notificacion (
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

-- Tabla: HISTORIAL_ESTADO_PEDIDO
CREATE TABLE historial_estado_pedido (
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
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ============================================================================

CREATE INDEX idx_usuario_email ON usuario(email);
CREATE INDEX idx_producto_vendedor ON producto(vendedor_id);
CREATE INDEX idx_producto_categoria ON producto(categoria_id);
CREATE INDEX idx_pedido_usuario ON pedido(usuario_id);
CREATE INDEX idx_pedido_estado ON pedido(estado_pedido_id);
CREATE INDEX idx_pedido_fecha ON pedido(fecha_pedido);
CREATE INDEX idx_pago_pedido ON pago(pedido_id);
CREATE INDEX idx_resena_producto ON resena(producto_id);
CREATE INDEX idx_resena_usuario ON resena(usuario_id);
CREATE INDEX idx_carrito_usuario ON carrito(usuario_id);
CREATE INDEX idx_notificacion_usuario ON notificacion(usuario_id);
CREATE INDEX idx_notificacion_leida ON notificacion(leida);

-- ============================================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ============================================================================

-- Insertar estados de pedido
INSERT INTO estado_pedido (nombre, descripcion, orden) VALUES
('Pendiente', 'Pedido creado, esperando confirmación de pago', 1),
('Confirmado', 'Pago confirmado, preparando envío', 2),
('Enviado', 'Pedido enviado al cliente', 3),
('Entregado', 'Pedido entregado al cliente', 4),
('Cancelado', 'Pedido cancelado por el cliente o vendedor', 5),
('Devuelto', 'Pedido devuelto por el cliente', 6);

-- Insertar estados de pago
INSERT INTO estado_pago (nombre, descripcion) VALUES
('Pendiente', 'Pago pendiente de procesar'),
('Procesando', 'Pago en proceso'),
('Completado', 'Pago completado exitosamente'),
('Fallido', 'Pago rechazado'),
('Reembolsado', 'Pago reembolsado al cliente');

-- Insertar métodos de pago
INSERT INTO metodo_pago (nombre, descripcion, activo) VALUES
('Tarjeta de Crédito', 'Visa, Mastercard, American Express', TRUE),
('Tarjeta de Débito', 'Débito directo de cuenta bancaria', TRUE),
('PayPal', 'Pago a través de PayPal', TRUE),
('Transferencia Bancaria', 'Transferencia directa a cuenta bancaria', TRUE),
('Billetera Digital', 'Pago con billetera digital', TRUE);

-- Insertar categorías
INSERT INTO categoria (nombre, descripcion, activo) VALUES
('Electrónica', 'Dispositivos electrónicos y accesorios', TRUE),
('Ropa y Moda', 'Prendas de vestir y accesorios de moda', TRUE),
('Hogar y Jardín', 'Artículos para el hogar y jardín', TRUE),
('Deportes', 'Equipos y accesorios deportivos', TRUE),
('Libros', 'Libros físicos y digitales', TRUE),
('Juguetes', 'Juguetes y juegos para todas las edades', TRUE);

-- Insertar usuarios (compradores)
INSERT INTO usuario (nombre, email, contrasena, telefono) VALUES
('Juan Pérez', 'juan.perez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN1', '3001234567'),
('María García', 'maria.garcia@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN2', '3012345678'),
('Carlos López', 'carlos.lopez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN3', '3023456789'),
('Ana Martínez', 'ana.martinez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN4', '3034567890'),
('Pedro Rodríguez', 'pedro.rodriguez@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN5', '3045678901');

-- Insertar usuarios (vendedores)
INSERT INTO usuario (nombre, email, contrasena, telefono) VALUES
('TechStore Admin', 'techstore@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN6', '3056789012'),
('Fashion Hub Admin', 'fashionhub@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN7', '3067890123'),
('Home Essentials Admin', 'homeessentials@example.com', '$2b$10$abcdefghijklmnopqrstuvwxABCDEFGHIJKLMN8', '3078901234');

-- Insertar vendedores
INSERT INTO vendedor (usuario_id, nombre_tienda, descripcion, activo) VALUES
(6, 'TechStore', 'Tienda especializada en electrónica y gadgets', TRUE),
(7, 'Fashion Hub', 'Tienda de ropa y accesorios de moda', TRUE),
(8, 'Home Essentials', 'Tienda de artículos para el hogar', TRUE);

-- Insertar direcciones
INSERT INTO direccion (usuario_id, direccion, ciudad, codigo_postal, pais, es_principal) VALUES
(1, 'Calle 123 #45-67', 'Cartagena', '130001', 'Colombia', TRUE),
(1, 'Carrera 50 #12-34', 'Cartagena', '130001', 'Colombia', FALSE),
(2, 'Avenida Principal 789', 'Bogotá', '110001', 'Colombia', TRUE),
(3, 'Calle 5 #10-20', 'Medellín', '050001', 'Colombia', TRUE),
(4, 'Carrera 7 #25-30', 'Cali', '760001', 'Colombia', TRUE),
(5, 'Avenida 19 #50-60', 'Barranquilla', '080001', 'Colombia', TRUE);

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
(1, 1, 'Monitor LG 27 pulgadas', 'Monitor 4K con panel IPS', 399.99, 'monitor_lg.jpg', TRUE);

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
(10, 25, 2);

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
(10, 5.0, '65x50x10 cm', 30.00, 3);

-- Insertar reseñas
INSERT INTO resena (usuario_id, producto_id, calificacion, comentario, util) VALUES
(1, 1, 5, 'Excelente laptop, muy rápida y ligera', 12),
(2, 1, 4, 'Buena calidad, pero un poco cara', 8),
(3, 2, 5, 'El mejor mouse que he usado', 15),
(4, 4, 4, 'Camiseta cómoda y de buena calidad', 6),
(5, 5, 3, 'Los jeans son buenos pero se destiñen', 4),
(1, 7, 5, 'Lámpara perfecta para trabajar', 10),
(2, 8, 4, 'Almohada muy cómoda', 7),
(3, 10, 5, 'Monitor excelente para diseño gráfico', 14);

-- Insertar carritos
INSERT INTO carrito (usuario_id) VALUES
(1), (2), (3), (4), (5);

-- Insertar items en carrito
INSERT INTO carrito_item (carrito_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 1299.99),
(1, 2, 2, 99.99),
(2, 4, 3, 29.99),
(2, 5, 1, 79.99),
(3, 7, 2, 45.99),
(4, 10, 1, 399.99),
(5, 6, 1, 199.99);

-- Insertar pedidos
INSERT INTO pedido (usuario_id, direccion_id, estado_pedido_id, monto_subtotal, monto_impuesto, monto_envio, monto_total) VALUES
(1, 1, 2, 1299.99, 194.99, 25.00, 1519.98),
(2, 3, 3, 89.97, 13.49, 6.00, 109.46),
(3, 4, 4, 45.99, 6.89, 6.00, 58.88),
(4, 5, 2, 399.99, 59.99, 30.00, 489.98),
(5, 6, 1, 199.99, 29.99, 15.00, 244.98);

-- Insertar items de pedido
INSERT INTO pedido_item (pedido_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 1, 1299.99, 1299.99),
(2, 4, 3, 29.99, 89.97),
(3, 7, 1, 45.99, 45.99),
(4, 10, 1, 399.99, 399.99),
(5, 6, 1, 199.99, 199.99);

-- Insertar pagos
INSERT INTO pago (pedido_id, metodo_pago_id, estado_pago_id, monto, referencia_pago) VALUES
(1, 1, 3, 1519.98, 'REF-001-2024'),
(2, 1, 3, 109.46, 'REF-002-2024'),
(3, 3, 3, 58.88, 'REF-003-2024'),
(4, 1, 2, 489.98, 'REF-004-2024'),
(5, 2, 1, 244.98, 'REF-005-2024');

-- Insertar notificaciones
INSERT INTO notificacion (usuario_id, tipo, asunto, mensaje, leida) VALUES
(1, 'PEDIDO', 'Pedido Confirmado', 'Tu pedido #1 ha sido confirmado y está siendo preparado', TRUE),
(2, 'PEDIDO', 'Pedido Enviado', 'Tu pedido #2 ha sido enviado', TRUE),
(3, 'PEDIDO', 'Pedido Entregado', 'Tu pedido #3 ha sido entregado', TRUE),
(4, 'PAGO', 'Pago Pendiente', 'Tu pago para el pedido #4 está pendiente de procesar', FALSE),
(5, 'SISTEMA', 'Bienvenida', 'Bienvenido a e-Shopify', TRUE);

-- Insertar historial de estados de pedido
INSERT INTO historial_estado_pedido (pedido_id, estado_anterior_id, estado_nuevo_id, usuario_id, razon) VALUES
(1, 1, 2, 6, 'Pago confirmado'),
(2, 1, 2, 7, 'Pago confirmado'),
(2, 2, 3, 7, 'Pedido enviado'),
(3, 1, 2, 8, 'Pago confirmado'),
(3, 2, 3, 8, 'Pedido enviado'),
(3, 3, 4, 8, 'Pedido entregado');

-- ============================================================================
-- CONSULTAS DE VALIDACIÓN Y PRUEBA
-- ============================================================================

-- Consulta 1: Obtener todos los productos de una categoría específica
SELECT p.producto_id, p.nombre, p.precio, c.nombre as categoria
FROM producto p
JOIN categoria c ON p.categoria_id = c.categoria_id
WHERE c.nombre = 'Electrónica'
ORDER BY p.precio DESC;

-- Consulta 2: Obtener los detalles de un pedido y los productos asociados
SELECT 
    p.pedido_id,
    u.nombre as cliente,
    p.fecha_pedido,
    ep.nombre as estado,
    pi.producto_id,
    pr.nombre as producto,
    pi.cantidad,
    pi.precio_unitario,
    pi.subtotal
FROM pedido p
JOIN usuario u ON p.usuario_id = u.usuario_id
JOIN estado_pedido ep ON p.estado_pedido_id = ep.estado_pedido_id
JOIN pedido_item pi ON p.pedido_id = pi.pedido_id
JOIN producto pr ON pi.producto_id = pr.producto_id
ORDER BY p.pedido_id;

-- Consulta 3: Encontrar el producto más caro
SELECT producto_id, nombre, precio
FROM producto
WHERE precio = (SELECT MAX(precio) FROM producto);

-- Consulta 4: Obtener la cantidad total de productos en el carrito de un usuario
SELECT 
    u.usuario_id,
    u.nombre,
    COUNT(ci.carrito_item_id) as cantidad_items,
    SUM(ci.cantidad) as cantidad_total_productos
FROM usuario u
JOIN carrito c ON u.usuario_id = c.usuario_id
JOIN carrito_item ci ON c.carrito_id = ci.carrito_id
GROUP BY u.usuario_id, u.nombre;

-- Consulta 5: Obtener los productos con calificaciones superiores a 4
SELECT 
    p.producto_id,
    p.nombre,
    AVG(r.calificacion) as calificacion_promedio,
    COUNT(r.resena_id) as cantidad_resenas
FROM producto p
LEFT JOIN resena r ON p.producto_id = r.producto_id
GROUP BY p.producto_id, p.nombre
HAVING AVG(r.calificacion) > 4
ORDER BY calificacion_promedio DESC;

-- Consulta 6: Encontrar los vendedores con más productos vendidos
SELECT 
    v.vendedor_id,
    v.nombre_tienda,
    SUM(pi.cantidad) as total_productos_vendidos
FROM vendedor v
JOIN producto p ON v.vendedor_id = p.vendedor_id
JOIN pedido_item pi ON p.producto_id = pi.producto_id
GROUP BY v.vendedor_id, v.nombre_tienda
ORDER BY total_productos_vendidos DESC;

-- Consulta 7: Obtener el historial de cambios de estado de un pedido
SELECT 
    h.historial_id,
    h.fecha_cambio,
    ep_anterior.nombre as estado_anterior,
    ep_nuevo.nombre as estado_nuevo,
    u.nombre as usuario_que_cambio,
    h.razon
FROM historial_estado_pedido h
LEFT JOIN estado_pedido ep_anterior ON h.estado_anterior_id = ep_anterior.estado_pedido_id
JOIN estado_pedido ep_nuevo ON h.estado_nuevo_id = ep_nuevo.estado_pedido_id
LEFT JOIN usuario u ON h.usuario_id = u.usuario_id
WHERE h.pedido_id = 3
ORDER BY h.fecha_cambio DESC;

-- Consulta 8: Obtener ingresos totales por vendedor
SELECT 
    v.nombre_tienda,
    COUNT(DISTINCT p.pedido_id) as cantidad_pedidos,
    SUM(pi.subtotal) as ingresos_totales,
    AVG(pi.subtotal) as ingreso_promedio_por_item
FROM vendedor v
JOIN producto pr ON v.vendedor_id = pr.vendedor_id
JOIN pedido_item pi ON pr.producto_id = pi.producto_id
JOIN pedido p ON pi.pedido_id = p.pedido_id
GROUP BY v.vendedor_id, v.nombre_tienda
ORDER BY ingresos_totales DESC;

-- Consulta 9: Obtener usuarios con más de un pedido
SELECT 
    u.usuario_id,
    u.nombre,
    u.email,
    COUNT(p.pedido_id) as cantidad_pedidos,
    SUM(p.monto_total) as gasto_total,
    MAX(p.fecha_pedido) as ultimo_pedido
FROM usuario u
JOIN pedido p ON u.usuario_id = p.usuario_id
GROUP BY u.usuario_id, u.nombre, u.email
HAVING COUNT(p.pedido_id) > 1
ORDER BY gasto_total DESC;

-- Consulta 10: Obtener productos con bajo inventario (menos de 30 unidades)
SELECT 
    p.producto_id,
    p.nombre,
    inv.cantidad_disponible,
    inv.cantidad_reservada,
    (inv.cantidad_disponible - inv.cantidad_reservada) as cantidad_neta,
    v.nombre_tienda,
    p.precio
FROM producto p
JOIN inventario inv ON p.producto_id = inv.producto_id
JOIN vendedor v ON p.vendedor_id = v.vendedor_id
WHERE inv.cantidad_disponible < 30
ORDER BY inv.cantidad_disponible ASC;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================