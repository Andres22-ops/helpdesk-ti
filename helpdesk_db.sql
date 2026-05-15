-- ===========================================================
--  HelpDesk TI — Script SQL completo
--  Universidad ECCI · Gestión en Base de Datos
--  Autores: Santiago Rodriguez, Yeimmy Sandoval, Andrés Arias
-- ===========================================================

CREATE DATABASE IF NOT EXISTS HelpDesk_DB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE HelpDesk_DB;

SET FOREIGN_KEY_CHECKS = 0;

-- ===========================================================
--  SECCIÓN 1: TABLAS (DDL)
--  9 tablas normalizadas hasta 3FN
-- ===========================================================

-- 1. Departamentos (tabla maestra)
CREATE TABLE IF NOT EXISTS Departamentos (
    id_dep      INT          PRIMARY KEY AUTO_INCREMENT,
    nombre_dep  VARCHAR(50)  NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 2. Usuarios (tabla maestra)
CREATE TABLE IF NOT EXISTS Usuarios (
    id_usuario  INT           PRIMARY KEY AUTO_INCREMENT,
    nombre      VARCHAR(100)  NOT NULL,
    correo      VARCHAR(100)  NOT NULL UNIQUE,
    password    VARCHAR(255)  NOT NULL,                     -- hash bcrypt
    rol         ENUM('Cliente','Agente','Admin') NOT NULL,
    activo      TINYINT(1)    NOT NULL DEFAULT 1            -- eliminación lógica (Regla 6)
) ENGINE=InnoDB;

-- 3. Agentes (especialización de Usuarios)
CREATE TABLE IF NOT EXISTS Agentes (
    id_agente   INT          PRIMARY KEY,
    id_dep      INT          NOT NULL,
    especialidad VARCHAR(50),
    FOREIGN KEY (id_agente) REFERENCES Usuarios(id_usuario)  ON DELETE CASCADE,
    FOREIGN KEY (id_dep)    REFERENCES Departamentos(id_dep)  ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 4. Categorias (tabla maestra)
CREATE TABLE IF NOT EXISTS Categorias (
    id_cat      INT          PRIMARY KEY AUTO_INCREMENT,
    nombre_cat  VARCHAR(50)  NOT NULL UNIQUE,
    descripcion VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB;

-- 5. Prioridades (tabla maestra)
CREATE TABLE IF NOT EXISTS Prioridades (
    id_prio          INT         PRIMARY KEY AUTO_INCREMENT,
    nivel_prio       VARCHAR(20) NOT NULL UNIQUE,
    tiempo_estimado  INT         NOT NULL CHECK (tiempo_estimado > 0)  -- horas
) ENGINE=InnoDB;

-- 6. Ciclo_Vida (motor de reglas del workflow)
CREATE TABLE IF NOT EXISTS Ciclo_Vida (
    id_ciclo          INT         PRIMARY KEY AUTO_INCREMENT,
    nombre_etapa      VARCHAR(50) NOT NULL UNIQUE,
    orden             INT         NOT NULL UNIQUE,
    descripcion_etapa TEXT        DEFAULT NULL
) ENGINE=InnoDB;

-- 7. Estados (conectada a Ciclo_Vida — elimina dependencia transitiva, 3FN)
CREATE TABLE IF NOT EXISTS Estados (
    id_estado      INT         PRIMARY KEY AUTO_INCREMENT,
    nombre_estado  VARCHAR(30) NOT NULL UNIQUE,
    id_ciclo       INT         NOT NULL,
    FOREIGN KEY (id_ciclo) REFERENCES Ciclo_Vida(id_ciclo) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. Tickets (tabla central — núcleo del sistema)
CREATE TABLE IF NOT EXISTS Tickets (
    id_ticket        INT           PRIMARY KEY AUTO_INCREMENT,
    titulo           VARCHAR(100)  NOT NULL,
    descripcion      TEXT          NOT NULL,
    fecha_creacion   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- Regla 1
    fecha_asignacion DATETIME      DEFAULT NULL,
    fecha_cierre     DATETIME      DEFAULT NULL,                         -- Regla 4
    id_usuario       INT           NOT NULL,
    id_agente        INT           DEFAULT NULL,                         -- Regla 3: NULL si no asignado
    id_estado        INT           NOT NULL,
    id_prio          INT           NOT NULL,
    id_cat           INT           NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)  ON DELETE RESTRICT,
    FOREIGN KEY (id_agente)  REFERENCES Agentes(id_agente)    ON DELETE SET NULL,
    FOREIGN KEY (id_estado)  REFERENCES Estados(id_estado)    ON DELETE RESTRICT,
    FOREIGN KEY (id_prio)    REFERENCES Prioridades(id_prio)  ON DELETE RESTRICT,
    FOREIGN KEY (id_cat)     REFERENCES Categorias(id_cat)    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 9. Historial_Transferencias (log de auditoría — Regla 5)
CREATE TABLE IF NOT EXISTS Historial_Transferencias (
    id_historial     INT      PRIMARY KEY AUTO_INCREMENT,
    id_ticket        INT      NOT NULL,
    id_agente_origen INT      DEFAULT NULL,
    id_agente_dest   INT      NOT NULL,
    fecha_trans      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo           TEXT     NOT NULL,
    FOREIGN KEY (id_ticket)        REFERENCES Tickets(id_ticket)   ON DELETE CASCADE,
    FOREIGN KEY (id_agente_origen) REFERENCES Agentes(id_agente),
    FOREIGN KEY (id_agente_dest)   REFERENCES Agentes(id_agente)
) ENGINE=InnoDB;

-- Índices en claves foráneas (RNF-06 Rendimiento)
CREATE INDEX idx_tickets_estado   ON Tickets(id_estado);
CREATE INDEX idx_tickets_agente   ON Tickets(id_agente);
CREATE INDEX idx_tickets_usuario  ON Tickets(id_usuario);
CREATE INDEX idx_historial_ticket ON Historial_Transferencias(id_ticket);

SET FOREIGN_KEY_CHECKS = 1;


-- ===========================================================
--  SECCIÓN 2: DATOS INICIALES (DML)
-- ===========================================================

INSERT INTO Departamentos (nombre_dep) VALUES
    ('Soporte Nivel 1'),
    ('Redes'),
    ('Seguridad'),
    ('Infraestructura');

INSERT INTO Ciclo_Vida (nombre_etapa, orden, descripcion_etapa) VALUES
    ('Inicial',      1, 'El ticket acaba de ser creado y está pendiente de asignación.'),
    ('En Proceso',   2, 'El ticket está siendo atendido por un agente técnico.'),
    ('Finalización', 3, 'El ticket ha sido resuelto o cerrado por el sistema.');

INSERT INTO Estados (nombre_estado, id_ciclo) VALUES
    ('Abierto',    1),
    ('Asignado',   2),
    ('En Proceso', 2),
    ('Resuelto',   3),
    ('Cerrado',    3);

INSERT INTO Prioridades (nivel_prio, tiempo_estimado) VALUES
    ('Baja',    72),
    ('Media',   24),
    ('Alta',     8),
    ('Crítica',  2);

INSERT INTO Categorias (nombre_cat, descripcion) VALUES
    ('Hardware',  'Fallas físicas en equipos o periféricos.'),
    ('Software',  'Problemas con aplicaciones o sistemas operativos.'),
    ('Accesos',   'Solicitudes de permisos, cuentas o contraseñas.'),
    ('Red',       'Problemas de conectividad o infraestructura de red.');

-- Usuarios de prueba (contraseñas hasheadas con bcrypt en la app Flask)
-- Aquí se insertan con un hash de ejemplo; Flask los reemplaza al registrar
INSERT INTO Usuarios (nombre, correo, password, rol) VALUES
    ('Admin Sistema',   'admin@helpdesk.com',   '$2b$12$HASH_ADMIN_PLACEHOLDER',   'Admin'),
    ('Ana Técnica',     'ana@helpdesk.com',     '$2b$12$HASH_AGENTE_PLACEHOLDER',  'Agente'),
    ('Carlos Técnico',  'carlos@helpdesk.com',  '$2b$12$HASH_AGENTE2_PLACEHOLDER', 'Agente'),
    ('Juan Cliente',    'juan@helpdesk.com',    '$2b$12$HASH_CLIENTE_PLACEHOLDER', 'Cliente');

INSERT INTO Agentes (id_agente, id_dep, especialidad) VALUES
    (2, 1, 'Sistemas Operativos'),
    (3, 2, 'Redes y Conectividad');


-- ===========================================================
--  SECCIÓN 3: TRIGGERS (auditoría y validación)
-- ===========================================================

DELIMITER $$

-- TRIGGER 1: Validar que "En Proceso" requiere agente asignado (Regla 3)
CREATE TRIGGER trg_validar_estado_proceso
BEFORE UPDATE ON Tickets
FOR EACH ROW
BEGIN
    DECLARE v_nombre_estado VARCHAR(30);

    SELECT nombre_estado INTO v_nombre_estado
    FROM Estados
    WHERE id_estado = NEW.id_estado;

    -- Si intenta pasar a "En Proceso" sin tener agente asignado, bloquea
    IF v_nombre_estado = 'En Proceso' AND NEW.id_agente IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un ticket no puede estar En Proceso sin un agente asignado.';
    END IF;
END$$

-- TRIGGER 2: Validar que "Resuelto"/"Cerrado" requiere fecha_cierre (Regla 4)
CREATE TRIGGER trg_validar_cierre
BEFORE UPDATE ON Tickets
FOR EACH ROW
BEGIN
    DECLARE v_nombre_estado VARCHAR(30);

    SELECT nombre_estado INTO v_nombre_estado
    FROM Estados
    WHERE id_estado = NEW.id_estado;

    IF v_nombre_estado IN ('Resuelto', 'Cerrado') AND NEW.fecha_cierre IS NULL THEN
        SET NEW.fecha_cierre = NOW();  -- la asigna automáticamente si no viene
    END IF;
END$$

-- TRIGGER 3: Registrar automáticamente el cambio de agente en el historial (Regla 5)
CREATE TRIGGER trg_historial_transferencia
AFTER UPDATE ON Tickets
FOR EACH ROW
BEGIN
    -- Solo dispara si el agente cambió y hay un agente destino
    IF OLD.id_agente <> NEW.id_agente AND NEW.id_agente IS NOT NULL THEN
        INSERT INTO Historial_Transferencias
            (id_ticket, id_agente_origen, id_agente_dest, fecha_trans, motivo)
        VALUES
            (NEW.id_ticket, OLD.id_agente, NEW.id_agente, NOW(),
             'Transferencia automática registrada por el sistema.');
    END IF;
END$$

-- TRIGGER 4: Registrar fecha_asignacion automáticamente al asignar agente
CREATE TRIGGER trg_fecha_asignacion
BEFORE UPDATE ON Tickets
FOR EACH ROW
BEGIN
    -- Si antes no había agente y ahora sí, registra la fecha de asignación
    IF OLD.id_agente IS NULL AND NEW.id_agente IS NOT NULL THEN
        SET NEW.fecha_asignacion = NOW();
    END IF;
END$$

DELIMITER ;


-- ===========================================================
--  SECCIÓN 4: STORED PROCEDURES (lógica de negocio + COMMIT/ROLLBACK)
-- ===========================================================

DELIMITER $$

-- PROCEDURE 1: Crear un ticket nuevo con transacción
CREATE PROCEDURE sp_crear_ticket(
    IN p_titulo       VARCHAR(100),
    IN p_descripcion  TEXT,
    IN p_id_usuario   INT,
    IN p_id_prio      INT,
    IN p_id_cat       INT,
    OUT p_id_ticket   INT,
    OUT p_mensaje     VARCHAR(255)
)
BEGIN
    DECLARE v_id_estado_abierto INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al crear el ticket. Transacción revertida.';
        SET p_id_ticket = -1;
    END;

    START TRANSACTION;

        -- Obtener el id del estado "Abierto"
        SELECT id_estado INTO v_id_estado_abierto
        FROM Estados
        WHERE nombre_estado = 'Abierto'
        LIMIT 1;

        INSERT INTO Tickets (titulo, descripcion, id_usuario, id_estado, id_prio, id_cat)
        VALUES (p_titulo, p_descripcion, p_id_usuario, v_id_estado_abierto, p_id_prio, p_id_cat);

        SET p_id_ticket = LAST_INSERT_ID();
        SET p_mensaje   = CONCAT('Ticket #', p_id_ticket, ' creado exitosamente.');

    COMMIT;
END$$

-- PROCEDURE 2: Asignar agente a un ticket con transacción
CREATE PROCEDURE sp_asignar_agente(
    IN  p_id_ticket   INT,
    IN  p_id_agente   INT,
    OUT p_mensaje     VARCHAR(255)
)
BEGIN
    DECLARE v_id_estado_asignado INT;
    DECLARE v_ticket_existe      INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al asignar agente. Transacción revertida.';
    END;

    START TRANSACTION;

        -- Verificar que el ticket existe y está en estado Abierto (con lock para concurrencia)
        SELECT COUNT(*) INTO v_ticket_existe
        FROM Tickets
        WHERE id_ticket = p_id_ticket
        FOR UPDATE;                                          -- lock de fila (concurrencia)

        IF v_ticket_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ticket no encontrado.';
        END IF;

        SELECT id_estado INTO v_id_estado_asignado
        FROM Estados
        WHERE nombre_estado = 'Asignado'
        LIMIT 1;

        UPDATE Tickets
        SET id_agente = p_id_agente,
            id_estado = v_id_estado_asignado
        WHERE id_ticket = p_id_ticket;

        SET p_mensaje = CONCAT('Ticket #', p_id_ticket, ' asignado correctamente.');

    COMMIT;
END$$

-- PROCEDURE 3: Transferir ticket entre agentes con transacción y registro de motivo
CREATE PROCEDURE sp_transferir_ticket(
    IN  p_id_ticket        INT,
    IN  p_id_agente_dest   INT,
    IN  p_motivo           TEXT,
    OUT p_mensaje          VARCHAR(255)
)
BEGIN
    DECLARE v_agente_actual INT;
    DECLARE v_ticket_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error en la transferencia. Transacción revertida.';
    END;

    START TRANSACTION;

        -- Bloquea la fila para evitar transferencias simultáneas (Regla 2 + concurrencia)
        SELECT id_agente INTO v_agente_actual
        FROM Tickets
        WHERE id_ticket = p_id_ticket
        FOR UPDATE;

        IF v_agente_actual IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede transferir un ticket sin agente origen.';
        END IF;

        -- Actualiza el agente (el trigger trg_historial_transferencia registra automáticamente)
        UPDATE Tickets
        SET id_agente = p_id_agente_dest
        WHERE id_ticket = p_id_ticket;

        -- Actualiza el motivo en el registro del historial que acaba de insertar el trigger
        UPDATE Historial_Transferencias
        SET motivo = p_motivo
        WHERE id_ticket = p_id_ticket
          AND id_agente_dest = p_id_agente_dest
        ORDER BY fecha_trans DESC
        LIMIT 1;

        SET p_mensaje = CONCAT('Ticket #', p_id_ticket, ' transferido exitosamente.');

    COMMIT;
END$$

-- PROCEDURE 4: Cerrar un ticket con transacción
CREATE PROCEDURE sp_cerrar_ticket(
    IN  p_id_ticket   INT,
    OUT p_mensaje     VARCHAR(255)
)
BEGIN
    DECLARE v_id_estado_cerrado INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al cerrar el ticket. Transacción revertida.';
    END;

    START TRANSACTION;

        SELECT id_estado INTO v_id_estado_cerrado
        FROM Estados
        WHERE nombre_estado = 'Cerrado'
        LIMIT 1;

        -- fecha_cierre la pone automáticamente el trigger trg_validar_cierre
        UPDATE Tickets
        SET id_estado = v_id_estado_cerrado,
            fecha_cierre = NOW()
        WHERE id_ticket = p_id_ticket;

        SET p_mensaje = CONCAT('Ticket #', p_id_ticket, ' cerrado. Fecha: ', NOW());

    COMMIT;
END$$

DELIMITER ;


-- ===========================================================
--  SECCIÓN 5: FUNCIONES (cálculos y consultas reutilizables)
-- ===========================================================

DELIMITER $$

-- FUNCIÓN 1: Contar tickets activos de un agente
CREATE FUNCTION fn_tickets_por_agente(p_id_agente INT)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total INT;

    SELECT COUNT(*) INTO v_total
    FROM Tickets t
    JOIN Estados e ON t.id_estado = e.id_estado
    WHERE t.id_agente = p_id_agente
      AND e.nombre_estado NOT IN ('Resuelto', 'Cerrado');

    RETURN v_total;
END$$

-- FUNCIÓN 2: Calcular tiempo de resolución en horas
CREATE FUNCTION fn_tiempo_resolucion(p_id_ticket INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_horas DECIMAL(10,2);

    SELECT TIMESTAMPDIFF(HOUR, fecha_creacion, COALESCE(fecha_cierre, NOW()))
    INTO v_horas
    FROM Tickets
    WHERE id_ticket = p_id_ticket;

    RETURN COALESCE(v_horas, -1);   -- -1 si el ticket no existe
END$$

-- FUNCIÓN 3: Verificar si un usuario tiene permiso sobre un ticket
CREATE FUNCTION fn_puede_ver_ticket(p_id_usuario INT, p_id_ticket INT)
RETURNS TINYINT(1)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_rol     VARCHAR(20);
    DECLARE v_puede   TINYINT(1) DEFAULT 0;

    SELECT rol INTO v_rol FROM Usuarios WHERE id_usuario = p_id_usuario;

    IF v_rol = 'Admin' THEN
        SET v_puede = 1;
    ELSEIF v_rol = 'Agente' THEN
        SELECT COUNT(*) INTO v_puede
        FROM Tickets
        WHERE id_ticket = p_id_ticket AND id_agente = p_id_usuario;
    ELSEIF v_rol = 'Cliente' THEN
        SELECT COUNT(*) INTO v_puede
        FROM Tickets
        WHERE id_ticket = p_id_ticket AND id_usuario = p_id_usuario;
    END IF;

    RETURN v_puede;
END$$

DELIMITER ;


-- ===========================================================
--  SECCIÓN 6: CONTROL DE CONCURRENCIA
--
--  Motor InnoDB usa bloqueo a nivel de fila (row-level locking).
--  En los procedures anteriores se usa SELECT ... FOR UPDATE para
--  garantizar que dos agentes no puedan asignarse el mismo ticket
--  simultáneamente. Mientras una transacción tenga el lock, las
--  demás esperan hasta que se haga COMMIT o ROLLBACK.
--
--  Ejemplo ilustrativo (NO ejecutar, solo para documentación):
--
--  Sesión A                         Sesión B
--  START TRANSACTION;               START TRANSACTION;
--  SELECT * FROM Tickets            -- espera porque A tiene el lock
--    WHERE id_ticket = 1
--    FOR UPDATE;
--  UPDATE Tickets SET ...;
--  COMMIT;                          -- ahora B puede continuar
-- ===========================================================


-- ===========================================================
--  SECCIÓN 7: ROLES Y PERMISOS (seguridad a nivel de SGBD)
-- ===========================================================

-- Usuario de solo lectura para reportes
CREATE USER IF NOT EXISTS 'helpdesk_reader'@'%' IDENTIFIED BY 'Reader#2025!';
GRANT SELECT ON HelpDesk_DB.* TO 'helpdesk_reader'@'%';

-- Usuario de aplicación (Flask se conecta con este)
CREATE USER IF NOT EXISTS 'helpdesk_app'@'%' IDENTIFIED BY 'App#Secure2025!';
GRANT SELECT, INSERT, UPDATE ON HelpDesk_DB.* TO 'helpdesk_app'@'%';
GRANT EXECUTE ON HelpDesk_DB.* TO 'helpdesk_app'@'%';   -- puede llamar procedures y functions

FLUSH PRIVILEGES;


-- ===========================================================
--  SECCIÓN 8: CONSULTAS DE VERIFICACIÓN
-- ===========================================================

-- Ver todos los tickets con su información completa
SELECT
    t.id_ticket                AS 'N° Ticket',
    t.titulo                   AS 'Asunto',
    u.nombre                   AS 'Cliente',
    COALESCE(ua.nombre, '—')   AS 'Técnico Asignado',
    d.nombre_dep               AS 'Departamento',
    p.nivel_prio               AS 'Prioridad',
    e.nombre_estado            AS 'Estado',
    t.fecha_creacion           AS 'Creado',
    fn_tiempo_resolucion(t.id_ticket) AS 'Horas transcurridas'
FROM Tickets t
JOIN Usuarios u       ON t.id_usuario = u.id_usuario
LEFT JOIN Agentes a   ON t.id_agente  = a.id_agente
LEFT JOIN Usuarios ua ON a.id_agente  = ua.id_usuario
LEFT JOIN Departamentos d ON a.id_dep = d.id_dep
JOIN Prioridades p    ON t.id_prio    = p.id_prio
JOIN Estados e        ON t.id_estado  = e.id_estado;

-- Probar el procedure de crear ticket
CALL sp_crear_ticket(
    'Falla de Office 365',
    'No abre Word ni Excel en el equipo del área contable.',
    4,   -- id del cliente Juan
    2,   -- prioridad Media
    2,   -- categoría Software
    @id_nuevo,
    @msg
);
SELECT @id_nuevo AS nuevo_ticket, @msg AS mensaje;

-- Probar asignación de agente
CALL sp_asignar_agente(1, 2, @msg);
SELECT @msg AS resultado;

-- Probar función de tickets por agente
SELECT fn_tickets_por_agente(2) AS tickets_activos_ana;

-- Ver historial de transferencias
SELECT
    h.id_historial,
    h.id_ticket,
    uo.nombre AS 'Agente origen',
    ud.nombre AS 'Agente destino',
    h.fecha_trans,
    h.motivo
FROM Historial_Transferencias h
LEFT JOIN Agentes ao ON h.id_agente_origen = ao.id_agente
LEFT JOIN Usuarios uo ON ao.id_agente = uo.id_usuario
JOIN Agentes ad ON h.id_agente_dest = ad.id_agente
JOIN Usuarios ud ON ad.id_agente = ud.id_usuario;
