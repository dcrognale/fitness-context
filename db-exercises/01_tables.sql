-- =====================================================================
-- Catálogo de Ejercicios - Musculación y CrossFit
-- PostgreSQL 16
-- =====================================================================

-- =====================================================================
-- Tabla: categorias
-- =====================================================================
CREATE TABLE categorias (
    id           BIGSERIAL   PRIMARY KEY,
    nombre       VARCHAR(80) NOT NULL,
    slug         VARCHAR(80) NOT NULL,
    descripcion  TEXT,
    activo       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_categorias_nombre UNIQUE (nombre),
    CONSTRAINT uq_categorias_slug   UNIQUE (slug),
    CONSTRAINT ck_categorias_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_categorias_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

COMMENT ON TABLE  categorias             IS 'Categorías o disciplinas a las que pertenece un ejercicio (Musculación, CrossFit, Powerlifting, etc.).';
COMMENT ON COLUMN categorias.id          IS 'Identificador único de la categoría.';
COMMENT ON COLUMN categorias.nombre      IS 'Nombre visible de la categoría.';
COMMENT ON COLUMN categorias.slug        IS 'Identificador legible en URL (minúsculas, guiones).';
COMMENT ON COLUMN categorias.descripcion IS 'Descripción opcional de la categoría.';
COMMENT ON COLUMN categorias.activo      IS 'Indica si la categoría está activa en el catálogo.';
COMMENT ON COLUMN categorias.created_at  IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN categorias.updated_at  IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_categorias_nombre ON categorias (nombre);
CREATE INDEX idx_categorias_slug   ON categorias (slug);


-- =====================================================================
-- Tabla: grupos_musculares
-- =====================================================================
CREATE TABLE grupos_musculares (
    id           BIGSERIAL   PRIMARY KEY,
    nombre       VARCHAR(80) NOT NULL,
    slug         VARCHAR(80) NOT NULL,
    descripcion  TEXT,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_grupos_musculares_nombre UNIQUE (nombre),
    CONSTRAINT uq_grupos_musculares_slug   UNIQUE (slug),
    CONSTRAINT ck_grupos_musculares_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_grupos_musculares_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

COMMENT ON TABLE  grupos_musculares             IS 'Grupos musculares generales (Pecho, Espalda, Piernas, etc.).';
COMMENT ON COLUMN grupos_musculares.id          IS 'Identificador único del grupo muscular.';
COMMENT ON COLUMN grupos_musculares.nombre      IS 'Nombre visible del grupo muscular.';
COMMENT ON COLUMN grupos_musculares.slug        IS 'Identificador legible en URL.';
COMMENT ON COLUMN grupos_musculares.descripcion IS 'Descripción opcional del grupo muscular.';
COMMENT ON COLUMN grupos_musculares.created_at  IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN grupos_musculares.updated_at  IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_grupos_musculares_nombre ON grupos_musculares (nombre);
CREATE INDEX idx_grupos_musculares_slug   ON grupos_musculares (slug);


-- =====================================================================
-- Tabla: musculos
-- =====================================================================
CREATE TABLE musculos (
    id                  BIGSERIAL   PRIMARY KEY,
    grupo_muscular_id   BIGINT      NOT NULL,
    nombre              VARCHAR(80) NOT NULL,
    nombre_en           VARCHAR(80),
    slug                VARCHAR(80) NOT NULL,
    descripcion         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_musculos_nombre UNIQUE (nombre),
    CONSTRAINT uq_musculos_slug   UNIQUE (slug),
    CONSTRAINT ck_musculos_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_musculos_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    CONSTRAINT fk_musculos_grupo_muscular
        FOREIGN KEY (grupo_muscular_id)
        REFERENCES grupos_musculares (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

COMMENT ON TABLE  musculos                   IS 'Músculos específicos que se trabajan en cada ejercicio. Cada músculo pertenece a un grupo muscular.';
COMMENT ON COLUMN musculos.id                IS 'Identificador único del músculo.';
COMMENT ON COLUMN musculos.grupo_muscular_id IS 'Grupo muscular al que pertenece el músculo.';
COMMENT ON COLUMN musculos.nombre            IS 'Nombre del músculo en español.';
COMMENT ON COLUMN musculos.nombre_en         IS 'Nombre del músculo en inglés.';
COMMENT ON COLUMN musculos.slug              IS 'Identificador legible en URL.';
COMMENT ON COLUMN musculos.descripcion       IS 'Descripción anatómica opcional.';
COMMENT ON COLUMN musculos.created_at        IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN musculos.updated_at        IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_musculos_nombre            ON musculos (nombre);
CREATE INDEX idx_musculos_slug              ON musculos (slug);
CREATE INDEX idx_musculos_grupo_muscular_id ON musculos (grupo_muscular_id);


-- =====================================================================
-- Tabla: equipamientos
-- =====================================================================
CREATE TABLE equipamientos (
    id           BIGSERIAL   PRIMARY KEY,
    nombre       VARCHAR(80) NOT NULL,
    nombre_en    VARCHAR(80),
    slug         VARCHAR(80) NOT NULL,
    descripcion  TEXT,
    activo       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_equipamientos_nombre UNIQUE (nombre),
    CONSTRAINT uq_equipamientos_slug   UNIQUE (slug),
    CONSTRAINT ck_equipamientos_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_equipamientos_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

COMMENT ON TABLE  equipamientos             IS 'Equipamientos utilizados en los ejercicios (Barra, Mancuerna, Kettlebell, etc.).';
COMMENT ON COLUMN equipamientos.id          IS 'Identificador único del equipamiento.';
COMMENT ON COLUMN equipamientos.nombre      IS 'Nombre del equipamiento en español.';
COMMENT ON COLUMN equipamientos.nombre_en   IS 'Nombre del equipamiento en inglés.';
COMMENT ON COLUMN equipamientos.slug        IS 'Identificador legible en URL.';
COMMENT ON COLUMN equipamientos.descripcion IS 'Descripción opcional del equipamiento.';
COMMENT ON COLUMN equipamientos.activo      IS 'Indica si el equipamiento está activo en el catálogo.';
COMMENT ON COLUMN equipamientos.created_at  IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN equipamientos.updated_at  IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_equipamientos_nombre ON equipamientos (nombre);
CREATE INDEX idx_equipamientos_slug   ON equipamientos (slug);


-- =====================================================================
-- Tabla: ejercicios
-- =====================================================================
CREATE TABLE ejercicios (
    id                 BIGSERIAL    PRIMARY KEY,
    nombre             VARCHAR(150) NOT NULL,
    nombre_en          VARCHAR(150),
    slug               VARCHAR(160) NOT NULL,
    descripcion        TEXT,
    categoria_id       BIGINT       NOT NULL,
    equipamiento_id    BIGINT,
    nivel              VARCHAR(20)  NOT NULL,
    tipo               VARCHAR(20)  NOT NULL,
    movimiento         VARCHAR(30)  NOT NULL,
    es_compuesto       BOOLEAN      NOT NULL DEFAULT FALSE,
    es_unilateral      BOOLEAN      NOT NULL DEFAULT FALSE,
    peso_corporal      BOOLEAN      NOT NULL DEFAULT FALSE,
    requiere_tecnica   BOOLEAN      NOT NULL DEFAULT FALSE,
    requiere_spotter   BOOLEAN      NOT NULL DEFAULT FALSE,
    video_url          VARCHAR(500),
    imagen_url         VARCHAR(500),
    gif_url            VARCHAR(500),
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ejercicios_nombre UNIQUE (nombre),
    CONSTRAINT uq_ejercicios_slug   UNIQUE (slug),
    CONSTRAINT ck_ejercicios_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_ejercicios_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    CONSTRAINT ck_ejercicios_nivel      CHECK (nivel      IN ('Principiante','Intermedio','Avanzado')),
    CONSTRAINT ck_ejercicios_tipo       CHECK (tipo       IN ('Compuesto','Aislamiento')),
    CONSTRAINT ck_ejercicios_movimiento CHECK (movimiento IN (
        'Empuje','Tracción','Sentadilla','Bisagra de cadera',
        'Carry','Rotación','Core','Cardio','Olímpico','Gimnasia'
    )),
    CONSTRAINT ck_ejercicios_tipo_compuesto CHECK (
        (tipo = 'Compuesto'   AND es_compuesto = TRUE) OR
        (tipo = 'Aislamiento' AND es_compuesto = FALSE)
    ),
    CONSTRAINT ck_ejercicios_video_url  CHECK (video_url  IS NULL OR video_url  ~* '^https?://'),
    CONSTRAINT ck_ejercicios_imagen_url CHECK (imagen_url IS NULL OR imagen_url ~* '^https?://'),
    CONSTRAINT ck_ejercicios_gif_url    CHECK (gif_url    IS NULL OR gif_url    ~* '^https?://'),
    CONSTRAINT fk_ejercicios_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES categorias (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_ejercicios_equipamiento
        FOREIGN KEY (equipamiento_id)
        REFERENCES equipamientos (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

COMMENT ON TABLE  ejercicios                  IS 'Catálogo principal de ejercicios de musculación, CrossFit y disciplinas relacionadas.';
COMMENT ON COLUMN ejercicios.id               IS 'Identificador único del ejercicio.';
COMMENT ON COLUMN ejercicios.nombre           IS 'Nombre del ejercicio en español.';
COMMENT ON COLUMN ejercicios.nombre_en        IS 'Nombre del ejercicio en inglés.';
COMMENT ON COLUMN ejercicios.slug             IS 'Identificador legible en URL.';
COMMENT ON COLUMN ejercicios.descripcion      IS 'Descripción general del ejercicio.';
COMMENT ON COLUMN ejercicios.categoria_id     IS 'Categoría a la que pertenece el ejercicio.';
COMMENT ON COLUMN ejercicios.equipamiento_id  IS 'Equipamiento principal utilizado (opcional).';
COMMENT ON COLUMN ejercicios.nivel            IS 'Nivel de dificultad: Principiante, Intermedio o Avanzado.';
COMMENT ON COLUMN ejercicios.tipo             IS 'Tipo de ejercicio: Compuesto o Aislamiento.';
COMMENT ON COLUMN ejercicios.movimiento       IS 'Patrón de movimiento principal del ejercicio.';
COMMENT ON COLUMN ejercicios.es_compuesto     IS 'Indica si el ejercicio involucra múltiples articulaciones.';
COMMENT ON COLUMN ejercicios.es_unilateral    IS 'Indica si el ejercicio se ejecuta de forma unilateral.';
COMMENT ON COLUMN ejercicios.peso_corporal    IS 'Indica si el ejercicio se realiza con peso corporal.';
COMMENT ON COLUMN ejercicios.requiere_tecnica IS 'Indica si el ejercicio requiere alta técnica de ejecución.';
COMMENT ON COLUMN ejercicios.requiere_spotter IS 'Indica si el ejercicio requiere un observador/spotter.';
COMMENT ON COLUMN ejercicios.video_url        IS 'URL de video demostrativo.';
COMMENT ON COLUMN ejercicios.imagen_url       IS 'URL de imagen ilustrativa.';
COMMENT ON COLUMN ejercicios.gif_url          IS 'URL de GIF animado demostrativo.';
COMMENT ON COLUMN ejercicios.activo           IS 'Indica si el ejercicio está activo en el catálogo.';
COMMENT ON COLUMN ejercicios.created_at       IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN ejercicios.updated_at       IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_ejercicios_nombre          ON ejercicios (nombre);
CREATE INDEX idx_ejercicios_slug            ON ejercicios (slug);
CREATE INDEX idx_ejercicios_categoria_id    ON ejercicios (categoria_id);
CREATE INDEX idx_ejercicios_equipamiento_id ON ejercicios (equipamiento_id);
CREATE INDEX idx_ejercicios_nivel           ON ejercicios (nivel);
CREATE INDEX idx_ejercicios_tipo            ON ejercicios (tipo);
CREATE INDEX idx_ejercicios_movimiento      ON ejercicios (movimiento);
CREATE INDEX idx_ejercicios_activo          ON ejercicios (activo);


-- =====================================================================
-- Tabla: ejercicio_musculos (N:M)
-- =====================================================================
CREATE TABLE ejercicio_musculos (
    id            BIGSERIAL  PRIMARY KEY,
    ejercicio_id  BIGINT     NOT NULL,
    musculo_id    BIGINT     NOT NULL,
    tipo          VARCHAR(20) NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ejercicio_musculos UNIQUE (ejercicio_id, musculo_id),
    CONSTRAINT ck_ejercicio_musculos_tipo CHECK (tipo IN ('Principal','Secundario','Estabilizador')),
    CONSTRAINT fk_ejercicio_musculos_ejercicio
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_ejercicio_musculos_musculo
        FOREIGN KEY (musculo_id)
        REFERENCES musculos (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

COMMENT ON TABLE  ejercicio_musculos              IS 'Relación N:M entre ejercicios y músculos, indicando el rol del músculo en el ejercicio.';
COMMENT ON COLUMN ejercicio_musculos.id           IS 'Identificador único del vínculo.';
COMMENT ON COLUMN ejercicio_musculos.ejercicio_id IS 'Ejercicio relacionado.';
COMMENT ON COLUMN ejercicio_musculos.musculo_id   IS 'Músculo relacionado.';
COMMENT ON COLUMN ejercicio_musculos.tipo         IS 'Rol del músculo: Principal, Secundario o Estabilizador.';
COMMENT ON COLUMN ejercicio_musculos.created_at   IS 'Fecha y hora de creación del registro.';

CREATE INDEX idx_ejercicio_musculos_ejercicio ON ejercicio_musculos (ejercicio_id);
CREATE INDEX idx_ejercicio_musculos_musculo   ON ejercicio_musculos (musculo_id);
CREATE INDEX idx_ejercicio_musculos_tipo      ON ejercicio_musculos (tipo);


-- =====================================================================
-- Tabla: ejercicio_instrucciones
-- =====================================================================
CREATE TABLE ejercicio_instrucciones (
    id            BIGSERIAL PRIMARY KEY,
    ejercicio_id  BIGINT    NOT NULL,
    orden         INTEGER   NOT NULL,
    instruccion   TEXT      NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ejercicio_instrucciones_orden UNIQUE (ejercicio_id, orden),
    CONSTRAINT ck_ejercicio_instrucciones_orden CHECK (orden > 0),
    CONSTRAINT ck_ejercicio_instrucciones_texto CHECK (char_length(trim(instruccion)) > 0),
    CONSTRAINT fk_ejercicio_instrucciones_ejercicio
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE  ejercicio_instrucciones              IS 'Pasos de ejecución de cada ejercicio. Una fila por paso, ordenables.';
COMMENT ON COLUMN ejercicio_instrucciones.id           IS 'Identificador único del paso.';
COMMENT ON COLUMN ejercicio_instrucciones.ejercicio_id IS 'Ejercicio al que pertenece el paso.';
COMMENT ON COLUMN ejercicio_instrucciones.orden        IS 'Orden secuencial del paso (1, 2, 3, ...).';
COMMENT ON COLUMN ejercicio_instrucciones.instruccion  IS 'Texto del paso o instrucción.';
COMMENT ON COLUMN ejercicio_instrucciones.created_at   IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN ejercicio_instrucciones.updated_at   IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_ejercicio_instrucciones_ejercicio ON ejercicio_instrucciones (ejercicio_id);


-- =====================================================================
-- Tabla: ejercicio_errores
-- =====================================================================
CREATE TABLE ejercicio_errores (
    id            BIGSERIAL PRIMARY KEY,
    ejercicio_id  BIGINT    NOT NULL,
    orden         INTEGER   NOT NULL DEFAULT 1,
    titulo        VARCHAR(200),
    descripcion   TEXT      NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_ejercicio_errores_orden CHECK (orden > 0),
    CONSTRAINT ck_ejercicio_errores_texto CHECK (char_length(trim(descripcion)) > 0),
    CONSTRAINT fk_ejercicio_errores_ejercicio
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE  ejercicio_errores              IS 'Errores comunes al ejecutar el ejercicio.';
COMMENT ON COLUMN ejercicio_errores.id           IS 'Identificador único del error.';
COMMENT ON COLUMN ejercicio_errores.ejercicio_id IS 'Ejercicio al que pertenece el error.';
COMMENT ON COLUMN ejercicio_errores.orden        IS 'Orden de presentación del error.';
COMMENT ON COLUMN ejercicio_errores.titulo       IS 'Título corto del error.';
COMMENT ON COLUMN ejercicio_errores.descripcion  IS 'Descripción detallada del error.';
COMMENT ON COLUMN ejercicio_errores.created_at   IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN ejercicio_errores.updated_at   IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_ejercicio_errores_ejercicio ON ejercicio_errores (ejercicio_id);


-- =====================================================================
-- Tabla: ejercicio_consejos
-- =====================================================================
CREATE TABLE ejercicio_consejos (
    id            BIGSERIAL PRIMARY KEY,
    ejercicio_id  BIGINT    NOT NULL,
    orden         INTEGER   NOT NULL DEFAULT 1,
    titulo        VARCHAR(200),
    descripcion   TEXT      NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_ejercicio_consejos_orden CHECK (orden > 0),
    CONSTRAINT ck_ejercicio_consejos_texto CHECK (char_length(trim(descripcion)) > 0),
    CONSTRAINT fk_ejercicio_consejos_ejercicio
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE  ejercicio_consejos              IS 'Consejos técnicos para mejorar la ejecución del ejercicio.';
COMMENT ON COLUMN ejercicio_consejos.id           IS 'Identificador único del consejo.';
COMMENT ON COLUMN ejercicio_consejos.ejercicio_id IS 'Ejercicio al que pertenece el consejo.';
COMMENT ON COLUMN ejercicio_consejos.orden        IS 'Orden de presentación del consejo.';
COMMENT ON COLUMN ejercicio_consejos.titulo       IS 'Título corto del consejo.';
COMMENT ON COLUMN ejercicio_consejos.descripcion  IS 'Descripción detallada del consejo.';
COMMENT ON COLUMN ejercicio_consejos.created_at   IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN ejercicio_consejos.updated_at   IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_ejercicio_consejos_ejercicio ON ejercicio_consejos (ejercicio_id);


-- =====================================================================
-- Tabla: ejercicio_variantes
-- =====================================================================
CREATE TABLE ejercicio_variantes (
    id                   BIGSERIAL PRIMARY KEY,
    ejercicio_id         BIGINT    NOT NULL,
    ejercicio_variante_id BIGINT   NOT NULL,
    descripcion          TEXT,
    created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ejercicio_variantes UNIQUE (ejercicio_id, ejercicio_variante_id),
    CONSTRAINT ck_ejercicio_variantes_distinto CHECK (ejercicio_id <> ejercicio_variante_id),
    CONSTRAINT fk_ejercicio_variantes_base
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_ejercicio_variantes_variante
        FOREIGN KEY (ejercicio_variante_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE  ejercicio_variantes                        IS 'Relación entre ejercicios y sus variantes. Cada variante referencia otro ejercicio.';
COMMENT ON COLUMN ejercicio_variantes.id                     IS 'Identificador único de la relación.';
COMMENT ON COLUMN ejercicio_variantes.ejercicio_id           IS 'Ejercicio base.';
COMMENT ON COLUMN ejercicio_variantes.ejercicio_variante_id  IS 'Ejercicio que actúa como variante del ejercicio base.';
COMMENT ON COLUMN ejercicio_variantes.descripcion            IS 'Descripción opcional de la relación entre ambos ejercicios.';
COMMENT ON COLUMN ejercicio_variantes.created_at             IS 'Fecha y hora de creación del registro.';

CREATE INDEX idx_ejercicio_variantes_base     ON ejercicio_variantes (ejercicio_id);
CREATE INDEX idx_ejercicio_variantes_variante ON ejercicio_variantes (ejercicio_variante_id);


-- =====================================================================
-- Tabla: tags
-- =====================================================================
CREATE TABLE tags (
    id           BIGSERIAL   PRIMARY KEY,
    nombre       VARCHAR(80) NOT NULL,
    slug         VARCHAR(80) NOT NULL,
    descripcion  TEXT,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tags_nombre UNIQUE (nombre),
    CONSTRAINT uq_tags_slug   UNIQUE (slug),
    CONSTRAINT ck_tags_nombre_no_vacio CHECK (char_length(trim(nombre)) > 0),
    CONSTRAINT ck_tags_slug_formato    CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

COMMENT ON TABLE  tags             IS 'Etiquetas descriptivas asociables a ejercicios (Hipertrofia, Fuerza, EMOM, AMRAP, etc.).';
COMMENT ON COLUMN tags.id          IS 'Identificador único de la etiqueta.';
COMMENT ON COLUMN tags.nombre      IS 'Nombre visible de la etiqueta.';
COMMENT ON COLUMN tags.slug        IS 'Identificador legible en URL.';
COMMENT ON COLUMN tags.descripcion IS 'Descripción opcional de la etiqueta.';
COMMENT ON COLUMN tags.created_at  IS 'Fecha y hora de creación del registro.';
COMMENT ON COLUMN tags.updated_at  IS 'Fecha y hora de última actualización del registro.';

CREATE INDEX idx_tags_nombre ON tags (nombre);
CREATE INDEX idx_tags_slug   ON tags (slug);


-- =====================================================================
-- Tabla: ejercicio_tags (N:M)
-- =====================================================================
CREATE TABLE ejercicio_tags (
    id            BIGSERIAL PRIMARY KEY,
    ejercicio_id  BIGINT    NOT NULL,
    tag_id        BIGINT    NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_ejercicio_tags UNIQUE (ejercicio_id, tag_id),
    CONSTRAINT fk_ejercicio_tags_ejercicio
        FOREIGN KEY (ejercicio_id)
        REFERENCES ejercicios (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_ejercicio_tags_tag
        FOREIGN KEY (tag_id)
        REFERENCES tags (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE  ejercicio_tags              IS 'Relación N:M entre ejercicios y etiquetas.';
COMMENT ON COLUMN ejercicio_tags.id           IS 'Identificador único del vínculo.';
COMMENT ON COLUMN ejercicio_tags.ejercicio_id IS 'Ejercicio relacionado.';
COMMENT ON COLUMN ejercicio_tags.tag_id       IS 'Etiqueta relacionada.';
COMMENT ON COLUMN ejercicio_tags.created_at   IS 'Fecha y hora de creación del registro.';

CREATE INDEX idx_ejercicio_tags_ejercicio ON ejercicio_tags (ejercicio_id);
CREATE INDEX idx_ejercicio_tags_tag       ON ejercicio_tags (tag_id);