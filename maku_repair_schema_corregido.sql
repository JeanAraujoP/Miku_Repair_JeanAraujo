-- =====================================================================
-- MAKU REPAIR - Script único y completo de base de datos
-- =====================================================================
-- Este es el ÚNICO archivo SQL del proyecto. Contiene, todo integrado
-- en un solo script:
--
-- 1) El esquema completo de 23 tablas del sistema (usuarios, roles,
--    permisos, dispositivos, tipos de dispositivo, servicios, solicitudes
--    de reparación, estados y su historial, diagnóstico, reparación,
--    notificaciones, sesión, registro de actividad, recuperación de
--    contraseña, autenticación con Google) con todas sus llaves foráneas.
--
-- 2) Hashes BCrypt reales y verificados en el INSERT de `usuario`. Con
--    la contraseña:
--
--        TechRepair2026!
--
--    puedes iniciar sesión con cualquiera de los 5 correos ya sembrados:
--        carlos.mendoza@gmail.com   (Administrador)
--        ana.gomez@gmail.com        (Técnico)
--        luis.rodriguez@hotmail.com (Técnico)
--        maria.fernandez@gmail.com  (Cliente)
--        jorge.torres@outlook.com   (Técnico)
--
--    El registro público (RegistroServlet) sigue funcionando normal
--    para crear cuentas nuevas con rol "Cliente".
--
-- 3) El sistema completo de precios y pagos, como parte nativa del
--    esquema:
--      - Columnas en `solicitud_reparacion` para la confirmación de
--        precio del cliente (estimado vs final) y para los abonos que
--        el admin configura (abono inicial requerido y segundo abono
--        opcional).
--      - Tabla `pago`: abonos/pagos con tipo (ABONO_INICIAL,
--        SEGUNDO_ABONO, PAGO_FINAL), método (Tarjeta, Pago Móvil,
--        Banesco, Banco Provincial, Banco de Venezuela, Pago Directo),
--        moneda, número de factura, identificador de transacción y
--        idempotency_key (con índices únicos para evitar pagos
--        duplicados), estado (pendiente, iniciado/en revisión, pagado,
--        fallido, cancelado) y relaciones con solicitud y usuario.
--      - Tabla `cuenta_pago`: cuentas receptoras configurables por el
--        admin, con 5 filas de ejemplo — reemplázalas con los datos
--        reales de la tienda desde el panel admin (Cuentas de pago).
--      - Tabla `factura`: se genera automáticamente para CADA pago que
--        queda aprobado (abono inicial, segundo abono o pago final) —
--        no espera a que la solicitud se cierre. `pago.factura_id_factura`
--        enlaza cada pago con su propia factura.
-- =====================================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema maku_repair
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `maku_reapair` DEFAULT CHARACTER SET utf8 ;
USE `maku_reapair` ;

-- -----------------------------------------------------
-- Table `maku_repair`.`rol`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`rol` (
  `id_rol` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(245) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  PRIMARY KEY (`id_rol`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`tipo_documento`   [AGREGADA - faltaba en el script original]
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`tipo_documento` (
  `id_documento` INT NOT NULL AUTO_INCREMENT,
  `nombre_document` VARCHAR(100) NOT NULL,
  `descripcion_documento` VARCHAR(245) NOT NULL,
  PRIMARY KEY (`id_documento`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`usuario`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`usuario` (
  `id_usuario` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(50) NOT NULL,
  `apellido` VARCHAR(50) NOT NULL,
  `numero_documento` VARCHAR(45) NOT NULL,
  `correo` VARCHAR(150) NOT NULL,
  `telefono` VARCHAR(45) NOT NULL,
  `password` VARCHAR(150) NOT NULL,
  `foto_perfil` VARCHAR(255) NOT NULL,
  `fecha_registro` DATE NOT NULL,
  `fecha_nacimiento` DATE NOT NULL,
  `ultimo_acceso` DATETIME NOT NULL,
  `tratamiento_datos` TINYINT NOT NULL,
  `check_autorizacion` TINYINT NOT NULL,
  `estado_cuenta` TINYINT NOT NULL,
  `rol_id_rol` INT NOT NULL,
  `tipo_documento_id_documento` INT NOT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE INDEX `uq_usuario_tipo_numero_documento` (`tipo_documento_id_documento`, `numero_documento`),
  INDEX `fk_usuario_rol1_idx` (`rol_id_rol`),
  INDEX `fk_usuario_tipo_documento1_idx` (`tipo_documento_id_documento`),
  CONSTRAINT `fk_usuario_rol1`
    FOREIGN KEY (`rol_id_rol`)
    REFERENCES `maku_repair`.`rol` (`id_rol`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_usuario_tipo_documento1`
    FOREIGN KEY (`tipo_documento_id_documento`)
    REFERENCES `maku_repair`.`tipo_documento` (`id_documento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`autenticacion_google`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`autenticacion_google` (
  `id_auth` INT NOT NULL AUTO_INCREMENT,
  `google_id` VARCHAR(245) NOT NULL,
  `correo_google` VARCHAR(200) NOT NULL,
  `fecha_vinculacion` DATETIME NOT NULL,
  `usuario_id_usuario` INT NOT NULL,
  PRIMARY KEY (`id_auth`),
  UNIQUE INDEX `uq_autenticacion_google_id` (`google_id`),
  INDEX `fk_autenticacion_google_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_autenticacion_google_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`servicios`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`servicios` (
  `id_servicios` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(245) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `precio_base` DECIMAL(10,2) NOT NULL,
  `tiempo_estimado` INT NOT NULL,
  `activos` TINYINT NOT NULL DEFAULT 1,
  `fecha_creacion` DATETIME NOT NULL,
  PRIMARY KEY (`id_servicios`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`tipo_dispositivo`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`tipo_dispositivo` (
  `id_tipo` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(245) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `activos` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_tipo`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`recuperacion_password`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`recuperacion_password` (
  `id_recuperacion` INT NOT NULL AUTO_INCREMENT,
  `token` VARCHAR(245) NOT NULL,
  `fecha_solicitud` DATETIME NOT NULL,
  `fecha_expiracion` DATETIME NOT NULL,
  `utilizada` TINYINT NOT NULL DEFAULT 0,
  `intentos` INT NOT NULL DEFAULT 0,
  `usuario_id_usuario` INT NOT NULL,
  PRIMARY KEY (`id_recuperacion`),
  INDEX `fk_recuperacion_password_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_recuperacion_password_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`dispositivos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`dispositivos` (
  `id_dispositivos` INT NOT NULL AUTO_INCREMENT,
  `marca` VARCHAR(245) NOT NULL,
  `modelo` VARCHAR(245) NOT NULL,
  `numero_serie` VARCHAR(245) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `fecha_registro` DATETIME NOT NULL,
  `estado` VARCHAR(245) NOT NULL,
  `usuario_id_usuario` INT NOT NULL,
  `tipo_dispositivo_id_tipo` INT NOT NULL,
  PRIMARY KEY (`id_dispositivos`),
  INDEX `fk_dispositivos_usuario1_idx` (`usuario_id_usuario`),
  INDEX `fk_dispositivos_tipo_dispositivo1_idx` (`tipo_dispositivo_id_tipo`),
  CONSTRAINT `fk_dispositivos_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_dispositivos_tipo_dispositivo1`
    FOREIGN KEY (`tipo_dispositivo_id_tipo`)
    REFERENCES `maku_repair`.`tipo_dispositivo` (`id_tipo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`sesion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`sesion` (
  `id_sesion` INT NOT NULL AUTO_INCREMENT,
  `token` VARCHAR(255) NOT NULL,
  `fecha_inicio` DATETIME NOT NULL,
  `fecha_expiracion` DATETIME NOT NULL,
  `activa` TINYINT NOT NULL DEFAULT 1,
  `usuario_id_usuario` INT NOT NULL,
  PRIMARY KEY (`id_sesion`),
  INDEX `fk_sesion_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_sesion_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`registro_actividad`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`registro_actividad` (
  `id_registro_actividad` INT NOT NULL AUTO_INCREMENT,
  `accion` VARCHAR(245) NOT NULL,
  `modulo` VARCHAR(45) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `fecha_hora` DATETIME NOT NULL,
  `direccion_ip` VARCHAR(45) NOT NULL,
  `usuario_id_usuario` INT NOT NULL,
  PRIMARY KEY (`id_registro_actividad`),
  INDEX `fk_registro_actividad_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_registro_actividad_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`estado_reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`estado_reparacion` (
  `id_estado` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(45) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `orden` INT NOT NULL,
  `activo` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_estado`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`permisos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`permisos` (
  `id_permisos` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(245) NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  PRIMARY KEY (`id_permisos`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`solicitud_reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`solicitud_reparacion` (
  `id_solicitud` INT NOT NULL AUTO_INCREMENT,
  `codigo_solicitud` VARCHAR(245) NOT NULL,
  `fecha_solicitud` DATETIME NOT NULL,
  `descripcion_falla` VARCHAR(245) NOT NULL,
  `observaciones` VARCHAR(245) NULL,
  `prioridad` VARCHAR(45) NOT NULL,
  `costo_estimado` DECIMAL(10,2) NOT NULL,
  `costo_final` DECIMAL(10,2) NULL,
  `fecha_entrega_estimada` DATE NOT NULL,
  `fecha_cierre` DATETIME NULL,
  `usuario_id_usuario` INT NOT NULL,
  `dispositivos_id_dispositivos` INT NOT NULL,
  `precio_confirmado_tipo` VARCHAR(20) NULL,
  `precio_confirmado_monto` DECIMAL(16,2) NULL,
  `precio_confirmado_monto_usd` DECIMAL(10,2) NULL,
  `precio_confirmado_tasa_usada` DECIMAL(12,4) NULL,
  `fecha_confirmacion_precio` DATETIME NULL,
  `abono_inicial_monto` DECIMAL(16,2) NULL,
  `segundo_abono_solicitado` TINYINT NOT NULL DEFAULT 0,
  `segundo_abono_monto` DECIMAL(16,2) NULL,
  PRIMARY KEY (`id_solicitud`),
  INDEX `fk_solicitud_reparacion_usuario1_idx` (`usuario_id_usuario`),
  INDEX `fk_solicitud_reparacion_dispositivos1_idx` (`dispositivos_id_dispositivos`),
  CONSTRAINT `fk_solicitud_reparacion_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_solicitud_reparacion_dispositivos1`
    FOREIGN KEY (`dispositivos_id_dispositivos`)
    REFERENCES `maku_repair`.`dispositivos` (`id_dispositivos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`factura`   [AGREGADA - factura/comprobante emitido por cada pago aprobado]
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`factura` (
  `id_factura` INT NOT NULL AUTO_INCREMENT,
  `numero_factura` VARCHAR(45) NOT NULL,
  `fecha_emision` DATETIME NOT NULL,
  `subtotal` DECIMAL(16,2) NOT NULL,
  `impuestos` DECIMAL(16,2) NOT NULL DEFAULT 0,
  `total` DECIMAL(16,2) NOT NULL,
  `moneda` VARCHAR(3) NOT NULL DEFAULT 'VES',
  `tasa_usada` DECIMAL(12,4) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'emitida',
  `observaciones` VARCHAR(245) NULL,
  `usuario_id_usuario` INT NOT NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  PRIMARY KEY (`id_factura`),
  UNIQUE INDEX `uq_factura_numero_factura` (`numero_factura`),
  INDEX `fk_factura_usuario1_idx` (`usuario_id_usuario`),
  INDEX `fk_factura_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  CONSTRAINT `fk_factura_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_factura_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`tasa_cambio`   [AGREGADA - fuente única de verdad para USD/VES]
-- -----------------------------------------------------
-- Cada fila es una tasa vigente en un momento dado. "activa" marca cuál es
-- la que se usa AHORA MISMO para calcular equivalentes nuevos — nunca se
-- borra ni se sobreescribe una fila existente, así queda un historial real
-- (requisito de no alterar operaciones ya creadas, que además congelan su
-- propia tasa por separado en `pago`/`solicitud_reparacion`).
CREATE TABLE IF NOT EXISTS `maku_reapair`.`tasa_cambio` (
  `id_tasa` INT NOT NULL AUTO_INCREMENT,
  `tasa_ves_por_usd` DECIMAL(12,4) NOT NULL,
  `fuente` VARCHAR(100) NOT NULL DEFAULT 'manual',
  `fecha_hora` DATETIME NOT NULL,
  `activa` TINYINT NOT NULL DEFAULT 1,
  `usuario_id_usuario` INT NULL,
  PRIMARY KEY (`id_tasa`),
  INDEX `fk_tasa_cambio_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_tasa_cambio_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`cuenta_pago`   [AGREGADA - cuentas receptoras configurables]
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`cuenta_pago` (
  `id_cuenta` INT NOT NULL AUTO_INCREMENT,
  `metodo` VARCHAR(50) NOT NULL,
  `banco` VARCHAR(60) NULL,
  `telefono` VARCHAR(20) NULL,
  `cedula_rif` VARCHAR(20) NULL,
  `titular` VARCHAR(100) NULL,
  `numero_cuenta` VARCHAR(40) NULL,
  `instrucciones` VARCHAR(255) NULL,
  `activo` TINYINT NOT NULL DEFAULT 1,
  `acepta_usd` TINYINT NOT NULL DEFAULT 0,
  `acepta_ves` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_cuenta`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`pago`   [AGREGADA - sistema de pagos/abonos]
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`pago` (
  `id_pago` INT NOT NULL AUTO_INCREMENT,
  `tipo` VARCHAR(20) NOT NULL DEFAULT 'ABONO',
  `monto` DECIMAL(16,2) NOT NULL,
  `moneda` VARCHAR(3) NOT NULL DEFAULT 'VES',
  `tasa_usada` DECIMAL(12,4) NULL,
  `monto_usd` DECIMAL(10,2) NULL,
  `monto_ves` DECIMAL(16,2) NULL,
  `fecha_pago` DATETIME NOT NULL,
  `fecha_actualizacion` DATETIME NULL,
  `fecha_aprobacion` DATETIME NULL,
  `metodo_pago` VARCHAR(50) NOT NULL,
  `banco` VARCHAR(60) NULL,
  `referencia` VARCHAR(100) NULL,
  `comprobante_url` VARCHAR(255) NULL,
  `identificador_transaccion` VARCHAR(150) NULL,
  `idempotency_key` VARCHAR(100) NULL,
  `numero_factura` VARCHAR(100) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  `observaciones` VARCHAR(245) NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  `usuario_id_usuario` INT NOT NULL,
  `cuenta_pago_id_cuenta` INT NULL,
  `factura_id_factura` INT NULL,
  PRIMARY KEY (`id_pago`),
  UNIQUE INDEX `uq_pago_identificador_transaccion` (`identificador_transaccion`),
  UNIQUE INDEX `uq_pago_idempotency_key` (`idempotency_key`),
  INDEX `fk_pago_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  INDEX `fk_pago_usuario1_idx` (`usuario_id_usuario`),
  INDEX `fk_pago_cuenta_pago1_idx` (`cuenta_pago_id_cuenta`),
  INDEX `fk_pago_factura1_idx` (`factura_id_factura`),
  CONSTRAINT `fk_pago_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pago_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pago_cuenta_pago1`
    FOREIGN KEY (`cuenta_pago_id_cuenta`)
    REFERENCES `maku_repair`.`cuenta_pago` (`id_cuenta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pago_factura1`
    FOREIGN KEY (`factura_id_factura`)
    REFERENCES `maku_repair`.`factura` (`id_factura`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`historial_reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`historial_reparacion` (
  `id_historial` INT NOT NULL AUTO_INCREMENT,
  `fecha_cambio` DATETIME NOT NULL,
  `observacion` VARCHAR(245) NULL,
  `estado_anterior` VARCHAR(245) NOT NULL,
  `estado_nuevo` VARCHAR(245) NOT NULL,
  `usuario_id_usuario` INT NOT NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  PRIMARY KEY (`id_historial`),
  INDEX `fk_historial_reparacion_usuario1_idx` (`usuario_id_usuario`),
  INDEX `fk_historial_reparacion_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  CONSTRAINT `fk_historial_reparacion_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_historial_reparacion_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`notificacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`notificacion` (
  `id_notificacion` INT NOT NULL AUTO_INCREMENT,
  `titulo` VARCHAR(100) NOT NULL,
  `mensaje` VARCHAR(245) NOT NULL,
  `tipo` VARCHAR(245) NOT NULL,
  `fecha_creacion` DATETIME NOT NULL,
  `fecha_lectura` DATETIME NULL,
  `leida` TINYINT NOT NULL DEFAULT 0,
  `usuario_id_usuario` INT NOT NULL,
  PRIMARY KEY (`id_notificacion`),
  INDEX `fk_notificacion_usuario1_idx` (`usuario_id_usuario`),
  CONSTRAINT `fk_notificacion_usuario1`
    FOREIGN KEY (`usuario_id_usuario`)
    REFERENCES `maku_repair`.`usuario` (`id_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`diagnostico`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`diagnostico` (
  `id_diagnostico` INT NOT NULL AUTO_INCREMENT,
  `fecha_diagnostico` DATETIME NOT NULL,
  `descripcion` VARCHAR(245) NOT NULL,
  `falla_encontrada` VARCHAR(245) NOT NULL,
  `solucion_propuesta` VARCHAR(245) NOT NULL,
  `costo_diagnostico` DECIMAL(16,2) NOT NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  PRIMARY KEY (`id_diagnostico`),
  INDEX `fk_diagnostico_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  CONSTRAINT `fk_diagnostico_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`reparacion` (
  `id_reparacion` INT NOT NULL AUTO_INCREMENT,
  `fecha_inicio` DATETIME NOT NULL,
  `fecha_finalizacion` DATETIME NULL,
  `descripcion_trabajo` VARCHAR(245) NOT NULL,
  `costo_mano_obra` DECIMAL(16,2) NOT NULL,
  `observaciones_tecnicas` VARCHAR(245) NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  PRIMARY KEY (`id_reparacion`),
  INDEX `fk_reparacion_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  CONSTRAINT `fk_reparacion_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`rol_has_permisos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`rol_has_permisos` (
  `rol_id_rol` INT NOT NULL,
  `permisos_id_permisos` INT NOT NULL,
  PRIMARY KEY (`rol_id_rol`, `permisos_id_permisos`),
  INDEX `fk_rol_has_permisos_permisos1_idx` (`permisos_id_permisos`),
  INDEX `fk_rol_has_permisos_rol1_idx` (`rol_id_rol`),
  CONSTRAINT `fk_rol_has_permisos_rol1`
    FOREIGN KEY (`rol_id_rol`)
    REFERENCES `maku_repair`.`rol` (`id_rol`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_rol_has_permisos_permisos1`
    FOREIGN KEY (`permisos_id_permisos`)
    REFERENCES `maku_repair`.`permisos` (`id_permisos`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`historial_reparacion_has_estado_reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`historial_reparacion_has_estado_reparacion` (
  `historial_reparacion_id_historial` INT NOT NULL,
  `estado_reparacion_id_estado` INT NOT NULL,
  PRIMARY KEY (`historial_reparacion_id_historial`, `estado_reparacion_id_estado`),
  INDEX `fk_historial_reparacion_has_estado_reparacion_estado_repara_idx` (`estado_reparacion_id_estado`),
  INDEX `fk_historial_reparacion_has_estado_reparacion_historial_rep_idx` (`historial_reparacion_id_historial`),
  CONSTRAINT `fk_historial_reparacion_has_estado_reparacion_historial_repar1`
    FOREIGN KEY (`historial_reparacion_id_historial`)
    REFERENCES `maku_repair`.`historial_reparacion` (`id_historial`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_historial_reparacion_has_estado_reparacion_estado_reparaci1`
    FOREIGN KEY (`estado_reparacion_id_estado`)
    REFERENCES `maku_repair`.`estado_reparacion` (`id_estado`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maku_repair`.`servicios_has_solicitud_reparacion`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maku_reapair`.`servicios_has_solicitud_reparacion` (
  `servicios_id_servicios` INT NOT NULL,
  `solicitud_reparacion_id_solicitud` INT NOT NULL,
  PRIMARY KEY (`servicios_id_servicios`, `solicitud_reparacion_id_solicitud`),
  INDEX `fk_servicios_has_solicitud_reparacion_solicitud_reparacion1_idx` (`solicitud_reparacion_id_solicitud`),
  INDEX `fk_servicios_has_solicitud_reparacion_servicios1_idx` (`servicios_id_servicios`),
  CONSTRAINT `fk_servicios_has_solicitud_reparacion_servicios1`
    FOREIGN KEY (`servicios_id_servicios`)
    REFERENCES `maku_repair`.`servicios` (`id_servicios`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_servicios_has_solicitud_reparacion_solicitud_reparacion1`
    FOREIGN KEY (`solicitud_reparacion_id_solicitud`)
    REFERENCES `maku_repair`.`solicitud_reparacion` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- DATA INSERTS (5 registros por tabla)
-- -----------------------------------------------------

-- 1. Tabla: rol
INSERT INTO `rol` (`id_rol`, `nombre`, `descripcion`) VALUES
(1, 'Administrador', 'Acceso total al sistema y gestión de usuarios'),
(2, 'Técnico', 'Gestión de diagnósticos, reparaciones y estados'),
(3, 'Cliente', 'Solicitud de reparaciones y seguimiento de dispositivos'),
(4, 'Recepcionista', 'Atención al cliente y registro inicial de solicitudes'),
(5, 'SuperAdmin', 'Configuración avanzada e infraestructura del sistema');

-- 2. Tabla: tipo_documento
INSERT INTO tipo_documento (nombre_document, descripcion_documento) VALUES
('Cédula de Identidad', 'Documento de identidad para ciudadanos venezolanos mayores de edad'),
('Cédula de Extranjería', 'Documento de identidad para extranjeros residentes en Venezuela'),
('Pasaporte', 'Documento de viaje internacional emitido por el gobierno'),
('RIF', 'Registro de Información Fiscal emitido por el SENIAT'),
('Partida de Nacimiento', 'Documento que acredita el nacimiento y estado civil de una persona');

-- 3. Tabla: usuario
-- Contraseña para los 5 usuarios: TechRepair2026!  (hash BCrypt real, generado y verificado)
INSERT INTO `maku_reapair`.`usuario` (`id_usuario`, `nombre`, `apellido`, `numero_documento`, `correo`, `telefono`, `password`, `foto_perfil`, `fecha_registro`, `fecha_nacimiento`, `ultimo_acceso`, `tratamiento_datos`, `check_autorizacion`, `estado_cuenta`, `rol_id_rol`, `tipo_documento_id_documento`) VALUES 
(1, 'Carlos', 'Mendoza', '1012345678', 'carlos.mendoza@gmail.com', '3001234567', '$2a$12$J/q7Cc.JVfWRZS/QFkPlrOhuVTawD5mkAzTCY9ee72d5favdETqA.', 'profiles/carlos.jpg', '2026-01-10', '1995-01-01', '2026-08-18 16:45:00', 1, 1, 1, 1, 1),
(2, 'Ana', 'Gomez', '1023456789', 'ana.gomez@gmail.com', '3109876543', '$2a$12$ljnDRfwoT7TEvxAKQHy61.KTdMg17YBd1t7NZ.hTZgpvdfBH37nyu', 'profiles/ana.jpg', '2026-02-15', '1998-05-12', '2026-08-20 10:15:00', 1, 1, 1, 2, 1),
(3, 'Luis', 'Rodriguez', '1034567890', 'luis.rodriguez@hotmail.com', '3204567890', '$2a$12$Lx.eEGh/R3PIXWk6cGmEwOMwdkuQBMIapckeP0KYiDDJRbsp7OHx2', 'profiles/luis.jpg', '2026-03-01', '1990-11-23', '2026-08-22 14:30:00', 1, 1, 1, 2, 2),
(4, 'Maria', 'Fernandez', '1045678901', 'maria.fernandez@gmail.com', '3156789012', '$2a$12$.PlbHYP4McZnlmKaOD1heOxHDUNmgOdb/fGw71LEhbeQKLFBSLIVy', 'profiles/maria.jpg', '2026-04-18', '2001-03-30', '2026-08-25 09:00:00', 1, 1, 1, 3, 1),
(5, 'Jorge', 'Torres', '1056789012', 'jorge.torres@outlook.com', '3012345678', '$2a$12$Fum/fZESnRx2H0ar1ybhMumwqNT.zo4eaMfauAJt1DeAQRIJ29ByG', 'profiles/jorge.jpg', '2026-05-05', '1987-08-14', '2026-08-27 18:20:00', 1, 1, 1, 2, 3);

-- 4. Tabla: autenticacion_google (solo los usuarios cuyo correo sembrado es realmente @gmail.com)
INSERT INTO `autenticacion_google` (`id_auth`, `google_id`, `correo_google`, `fecha_vinculacion`, `usuario_id_usuario`) VALUES
(1, 'g_100123456789012345678', 'carlos.mendoza@gmail.com', '2026-01-10 08:30:00', 1),
(2, 'g_100987654321098765432', 'ana.gomez@gmail.com', '2026-01-12 10:15:00', 2),
(3, 'g_100456789012345678901', 'maria.fernandez@gmail.com', '2026-04-18 09:10:00', 4);

-- 5. Tabla: servicios
INSERT INTO `servicios` (`id_servicios`, `nombre`, `descripcion`, `precio_base`, `tiempo_estimado`, `activos`, `fecha_creacion`) VALUES
(1, 'Mantenimiento Preventivo Limpieza', 'Limpieza interna de polvo, cambio de pasta térmica y lubricación', 80000.00, 120, 1, '2026-01-01 08:00:00'),
(2, 'Cambio de Pantalla OLED', 'Reemplazo de módulo completo de pantalla táctil', 250000.00, 90, 1, '2026-01-01 08:00:00'),
(3, 'Reparación de Puerto de Carga', 'Sustitución de conector Type-C/Pin de carga dañado', 60000.00, 60, 1, '2026-01-05 09:00:00'),
(4, 'Rebaling / Reparación de Placa', 'Reparación a nivel de microcomponentes en tarjeta madre', 320000.00, 2880, 1, '2026-01-10 10:00:00'),
(5, 'Optimización y Reinstalación de SO', 'Formateo, instalación limpia de SO y controladores', 70000.00, 180, 1, '2026-01-15 11:00:00');

-- 6. Tabla: tipo_dispositivo
INSERT INTO `tipo_dispositivo` (`id_tipo`, `nombre`, `descripcion`, `activos`) VALUES
(1, 'Laptop / Portátil', 'Computadores portátiles de uso personal o empresarial', 1),
(2, 'Smartphone', 'Teléfonos móviles inteligentes', 1),
(3, 'Desktop / Computador de Mesa', 'Equipos de escritorio, torres y All-In-One', 1),
(4, 'Tablet', 'Dispositivos táctiles portátiles de formato mediano', 1),
(5, 'Consola de Videojuegos', 'Sistemas de entretenimiento como PlayStation, Xbox o Switch', 1);

-- 7. Tabla: recuperacion_password
INSERT INTO `recuperacion_password` (`id_recuperacion`, `token`, `fecha_solicitud`, `fecha_expiracion`, `utilizada`, `usuario_id_usuario`) VALUES
(1, 'tok_9f8e7d6c5b4a3123456789', '2026-03-01 10:00:00', '2026-03-01 11:00:00', 1, 2),
(2, 'tok_1a2b3c4d5e6f7890123456', '2026-04-10 15:30:00', '2026-04-10 16:30:00', 1, 4),
(3, 'tok_11223344556677889900aa', '2026-05-20 09:12:00', '2026-05-20 10:12:00', 0, 5),
(4, 'tok_aabbccddeeff0011223344', '2026-07-02 18:00:00', '2026-07-02 19:00:00', 0, 2),
(5, 'tok_99887766554433221100bb', '2026-08-01 11:20:00', '2026-08-01 12:20:00', 1, 4);

-- 8. Tabla: dispositivos
INSERT INTO `dispositivos` (`id_dispositivos`, `marca`, `modelo`, `numero_serie`, `descripcion`, `fecha_registro`, `estado`, `usuario_id_usuario`, `tipo_dispositivo_id_tipo`) VALUES
(1, 'Lenovo', 'ThinkPad T14 Gen 2', 'PF-3A9812X', 'Portátil color negro con chasis rayado', '2026-02-15 10:00:00', 'En Reparación', 3, 1),
(2, 'Samsung', 'Galaxy S23 Ultra', 'R5CT30129AB', 'Teléfono con cristal trasero roto', '2026-03-01 11:30:00', 'Ingresado', 3, 2),
(3, 'ASUS', 'ROG Strix G15', 'N123K456L789', 'Equipo de cómputo para gaming con sobrecalentamiento', '2026-03-10 14:15:00', 'Diagnóstico', 4, 1),
(4, 'Apple', 'iPad Pro 11"', 'DMPZ1234QJK', 'Sin imagen en pantalla tras caída', '2026-04-05 09:00:00', 'Listo para Entrega', 3, 4),
(5, 'Sony', 'PlayStation 5', 'AK1234567890', 'Consola presenta fallas de encendido y apagado repentino', '2026-05-12 16:45:00', 'Entregado', 4, 5);

-- 9. Tabla: sesion
INSERT INTO `sesion` (`id_sesion`, `token`, `fecha_inicio`, `fecha_expiracion`, `activa`, `usuario_id_usuario`) VALUES
(1, 'sess_abc123xyz7890123456789', '2026-08-19 07:00:00', '2026-08-19 15:00:00', 1, 1),
(2, 'sess_def456uvw0123456789012', '2026-08-19 07:10:00', '2026-08-19 15:10:00', 1, 2),
(3, 'sess_ghi789rst3456789012345', '2026-08-17 12:30:00', '2026-08-17 20:30:00', 0, 3),
(4, 'sess_jkl012mno6789012345678', '2026-08-15 18:20:00', '2026-08-16 02:20:00', 0, 4),
(5, 'sess_pqr345jkl9012345678901', '2026-08-10 09:15:00', '2026-08-10 17:15:00', 0, 5);

-- 10. Tabla: registro_actividad
INSERT INTO `registro_actividad` (`id_registro_actividad`, `accion`, `modulo`, `descripcion`, `fecha_hora`, `direccion_ip`, `usuario_id_usuario`) VALUES
(1, 'INICIO_SESION', 'Autenticación', 'Inicio de sesión exitoso vía Google OAuth', '2026-08-19 07:00:00', '192.168.1.10', 1),
(2, 'CREAR_SOLICITUD', 'Solicitudes', 'Registro de nueva solicitud de reparación #SOL-2026-002', '2026-08-19 07:30:00', '192.168.1.15', 2),
(3, 'ACTUALIZAR_DIAGNOSTICO', 'Técnico', 'Diagnóstico agregado al dispositivo ID 3', '2026-08-18 14:20:00', '192.168.1.20', 2),
(4, 'CAMBIO_ESTADO', 'Reparaciones', 'Cambio de estado a Listo para Entrega', '2026-08-17 11:00:00', '192.168.1.15', 2),
(5, 'MODIFICAR_USUARIO', 'Usuarios', 'Actualización del perfil de usuario ID 4', '2026-08-15 18:25:00', '192.168.1.10', 1);

-- 11. Tabla: estado_reparacion
INSERT INTO `estado_reparacion` (`id_estado`, `nombre`, `descripcion`, `orden`, `activo`) VALUES
(1, 'Recibido', 'Dispositivo recibido en el taller', 1, 1),
(2, 'En Diagnóstico', 'Técnico realizando evaluación del problema', 2, 1),
(3, 'Esperando Repuestos', 'En espera de llegada de refacciones necesarias', 3, 1),
(4, 'En Reparación', 'Intervención técnica en proceso', 4, 1),
(5, 'Finalizado / Listo', 'Reparación concluida exitosamente y probada', 5, 1);

-- 12. Tabla: permisos
INSERT INTO `permisos` (`id_permisos`, `nombre`, `descripcion`) VALUES
(1, 'CREAR_USUARIO', 'Permite registrar nuevos usuarios en la plataforma'),
(2, 'GESTIONAR_SOLICITUDES', 'Permite crear, editar y cancelar solicitudes de reparación'),
(3, 'REGISTRAR_DIAGNOSTICO', 'Permite agregar informes técnicos a las reparaciones'),
(4, 'GENERAR_REPORTES', 'Permite ver y exportar métricas operativas y financieras'),
(5, 'CONFIGURACION_SISTEMA', 'Permite modificar variables globales y roles del sistema');

-- 13. Tabla: solicitud_reparacion
INSERT INTO `solicitud_reparacion` (`id_solicitud`, `codigo_solicitud`, `fecha_solicitud`, `descripcion_falla`, `observaciones`, `prioridad`, `costo_estimado`, `costo_final`, `fecha_entrega_estimada`, `fecha_cierre`, `usuario_id_usuario`, `dispositivos_id_dispositivos`) VALUES
(1, 'SOL-2026-001', '2026-02-15 10:15:00', 'Portátil no enciende ni muestra luces de carga', 'Incluye cargador original', 'Alta', 320000.00, 350000.00, '2026-02-20', '2026-02-19 16:00:00', 3, 1),
(2, 'SOL-2026-002', '2026-03-01 11:45:00', 'Cristal roto y la pantalla no responde al tacto', 'Carcasa en buen estado', 'Media', 250000.00, NULL, '2026-03-05', NULL, 3, 2),
(3, 'SOL-2026-003', '2026-03-10 14:30:00', 'Laptops se apaga a los 10 minutos de iniciar un juego', 'Requiere limpieza urgente', 'Baja', 80000.00, 80000.00, '2026-03-12', '2026-03-12 11:00:00', 4, 3),
(4, 'SOL-2026-004', '2026-04-05 09:15:00', 'IPad no da imagen tras caída, emite sonidos', 'Pantalla intacta físicamente', 'Alta', 150000.00, 150000.00, '2026-04-08', '2026-04-07 17:30:00', 3, 4),
(5, 'SOL-2026-005', '2026-05-12 17:00:00', 'PS5 apaga de repente lanzando 3 pitidos', 'Sin sellos de garantía previosa', 'Urgente', 200000.00, 220000.00, '2026-05-16', '2026-05-16 10:20:00', 4, 5);

-- 14. Tabla: historial_reparacion
INSERT INTO `historial_reparacion` (`id_historial`, `fecha_cambio`, `observacion`, `estado_anterior`, `estado_nuevo`, `usuario_id_usuario`, `solicitud_reparacion_id_solicitud`) VALUES
(1, '2026-02-15 10:15:00', 'Creación e ingreso del equipo al taller', 'Ninguno', 'Recibido', 5, 1),
(2, '2026-02-16 09:00:00', 'Pasa a mesa de trabajo del técnico', 'Recibido', 'En Diagnóstico', 2, 1),
(3, '2026-03-01 11:45:00', 'Se recibe teléfono en recepción', 'Ninguno', 'Recibido', 5, 2),
(4, '2026-03-10 14:30:00', 'Se registra equipo gaming para mantenimiento', 'Ninguno', 'Recibido', 5, 3),
(5, '2026-04-05 09:15:00', 'Se valida estado físico inicial', 'Ninguno', 'Recibido', 5, 4);

-- 15. Tabla: notificacion
INSERT INTO `notificacion` (`id_notificacion`, `titulo`, `mensaje`, `tipo`, `fecha_creacion`, `fecha_lectura`, `leida`, `usuario_id_usuario`) VALUES
(1, 'Solicitud Creada', 'Su solicitud SOL-2026-001 ha sido registrada correctamente.', 'Informativa', '2026-02-15 10:15:00', '2026-02-15 10:20:00', 1, 3),
(2, 'Diagnóstico Listo', 'Se ha completado el diagnóstico para el equipo Lenovo ThinkPad.', 'Alerta', '2026-02-16 14:00:00', '2026-02-16 15:30:00', 1, 3),
(3, 'Reparación Finalizada', 'Su dispositivo iPad Pro está listo para ser retirado.', 'Éxito', '2026-04-07 17:35:00', '2026-04-07 18:00:00', 1, 3),
(4, 'Actualización de Estado', 'Su solicitud SOL-2026-002 pasó al estado En Diagnóstico.', 'Informativa', '2026-03-02 08:30:00', NULL, 0, 3),
(5, 'Encuesta de Satisfacción', 'Por favor califique el servicio de reparación del ticket SOL-2026-005.', 'Recordatorio', '2026-05-17 09:00:00', NULL, 0, 4);

-- 16. Tabla: diagnostico
INSERT INTO `diagnostico` (`id_diagnostico`, `fecha_diagnostico`, `descripcion`, `falla_encontrada`, `solucion_propuesta`, `costo_diagnostico`, `solicitud_reparacion_id_solicitud`) VALUES
(1, '2026-02-16 13:00:00', 'Revisión con multímetro y osciloscopio', 'Cortocircuito en la línea principal de 19V', 'Reemplazo de MOSFET y capacitor de entrada', 30000.00, 1),
(2, '2026-03-02 10:00:00', 'Inspección táctil y visual interna', 'Flex de pantalla rasgado e integrado flex táctil averiado', 'Cambio de módulo display completo', 20000.00, 2),
(3, '2026-03-11 09:30:00', 'Monitoreo de temperaturas bajo estrés térmico', 'Pasta térmica cristalizada y obstrucción por polvo en disipadores', 'Mantenimiento preventivo general y cambio de pasta', 20000.00, 3),
(4, '2026-04-05 15:00:00', 'Prueba de señales en la placa base', 'Conector FPC de pantalla desconectado tras el impacto', 'Reconexión, aseguramiento y pruebas de imagen', 25000.00, 4),
(5, '2026-05-13 11:00:00', 'Análisis de fuente de poder y APU', 'Sobrecalentamiento en la fuente por fallo en ventilador de extracción', 'Reemplazo de ventilador y aplicación de metal líquido', 35000.00, 5);

-- 17. Tabla: reparacion
INSERT INTO `reparacion` (`id_reparacion`, `fecha_inicio`, `fecha_finalizacion`, `descripcion_trabajo`, `costo_mano_obra`, `observaciones_tecnicas`, `solicitud_reparacion_id_solicitud`) VALUES
(1, '2026-02-17 09:00:00', '2026-02-19 15:00:00', 'Sustitución de MOSFET SMD en zona de carga y pruebas de voltaje', 120000.00, 'Equipo opera a voltajes normales de 19.5V', 1),
(2, '2026-03-03 08:30:00', NULL, 'Desmontaje de pantalla averiada y preparación de marco', 60000.00, 'A la espera del repuesto AMOLED', 2),
(3, '2026-03-11 11:00:00', '2026-03-12 10:00:00', 'Desarme completo, limpieza de disipador y aplicación de Arctic MX-4', 60000.00, 'Temperatura bajo carga se redujo de 95°C a 68°C', 3),
(4, '2026-04-06 10:00:00', '2026-04-07 16:00:00', 'Ajuste e inspección de conector FPC y sellado hermético', 80000.00, 'Pantalla y TrueTone funcionando al 100%', 4),
(5, '2026-05-14 09:00:00', '2026-05-15 18:00:00', 'Instalación de ventilador original y redistribución de Metal Líquido', 90000.00, 'Pruebas continuas de 4 horas de juego sin apague', 5);

-- 18. Tabla: rol_has_permisos
INSERT INTO `rol_has_permisos` (`rol_id_rol`, `permisos_id_permisos`) VALUES
(1, 1),
(1, 4),
(1, 5),
(2, 2),
(2, 3);

-- 19. Tabla: historial_reparacion_has_estado_reparacion
INSERT INTO `historial_reparacion_has_estado_reparacion` (`historial_reparacion_id_historial`, `estado_reparacion_id_estado`) VALUES
(1, 1),
(2, 2),
(3, 1),
(4, 1),
(5, 1);

-- 20. Tabla: servicios_has_solicitud_reparacion
INSERT INTO `servicios_has_solicitud_reparacion` (`servicios_id_servicios`, `solicitud_reparacion_id_solicitud`) VALUES
(4, 1),
(2, 2),
(1, 3),
(1, 4),
(4, 5);

-- 21. Tabla: cuenta_pago (edítala desde el panel admin con los datos reales de la tienda)
INSERT INTO `cuenta_pago` (`metodo`, `banco`, `telefono`, `cedula_rif`, `titular`, `numero_cuenta`, `instrucciones`, `activo`, `acepta_usd`, `acepta_ves`) VALUES
('Pago Móvil', 'Banesco', '0412-0000000', 'J-000000000', 'Maku Repair, C.A.', NULL, 'Envía el Pago Móvil y registra aquí la referencia de 4 dígitos.', 1, 0, 1),
('Banesco', 'Banesco', NULL, 'J-000000000', 'Maku Repair, C.A.', '0134-0000-00-0000000000', 'Transferencia a cuenta corriente. Registra el número de referencia del comprobante.', 1, 0, 1),
('Banco Provincial', 'BBVA Provincial', NULL, 'J-000000000', 'Maku Repair, C.A.', '0108-0000-00-0000000000', 'Transferencia a cuenta corriente Provincial. Sube el comprobante para agilizar la verificación.', 1, 0, 1),
('Banco de Venezuela', 'Banco de Venezuela', NULL, 'J-000000000', 'Maku Repair, C.A.', '0102-0000-00-0000000000', 'Transferencia a cuenta corriente BDV. Registra el número de referencia y adjunta el comprobante.', 1, 0, 1),
('Pago Directo', NULL, NULL, NULL, 'Maku Repair, C.A.', NULL, 'Pago directo en el local, en efectivo (Bs. o USD). Al momento de entregar tu equipo, presenta esta referencia al personal.', 1, 1, 1);

-- 22. Tabla: tasa_cambio
-- IMPORTANTE: este valor es un PLACEHOLDER de ejemplo, no una tasa real de
-- mercado — actualízala de inmediato desde el panel admin (Tasa de cambio)
-- antes de usar el sistema en producción.
INSERT INTO `tasa_cambio` (`tasa_ves_por_usd`, `fuente`, `fecha_hora`, `activa`, `usuario_id_usuario`) VALUES
(40.0000, 'manual (placeholder inicial — actualízala desde el panel)', NOW(), 1, 1);


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- =====================================================================
-- OPCIONAL: si ya tenías la base de datos cargada con los tipos de
-- documento en formato colombiano (Cédula de Ciudadanía, etc.), corre
-- esto una sola vez para actualizarlos al formato venezolano sin tener
-- que reimportar todo el script desde cero.
-- =====================================================================
-- UPDATE tipo_documento SET nombre_document = 'Cédula de Identidad', descripcion_documento = 'Documento de identidad para ciudadanos venezolanos mayores de edad' WHERE nombre_document = 'Cédula de Ciudadanía';
-- UPDATE tipo_documento SET descripcion_documento = 'Documento de identidad para extranjeros residentes en Venezuela' WHERE nombre_document = 'Cédula de Extranjería';
-- UPDATE tipo_documento SET nombre_document = 'RIF', descripcion_documento = 'Registro de Información Fiscal emitido por el SENIAT' WHERE nombre_document = 'Tarjeta de Identidad';
-- UPDATE tipo_documento SET nombre_document = 'Partida de Nacimiento' WHERE nombre_document = 'Registro Civil';