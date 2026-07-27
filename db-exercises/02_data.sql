-- =====================================================================
-- 01_catalogos.sql
-- Carga de catálogos base: categorias, grupos_musculares, musculos,
-- equipamientos y tags.
-- IDs asignados explícitamente para permitir referencias deterministas
-- desde archivos posteriores (ejercicios y relaciones).
-- PostgreSQL 16
-- =====================================================================

-- ---------------------------------------------------------------------
-- categorias
-- ---------------------------------------------------------------------
INSERT INTO categorias (id, nombre, slug, descripcion, activo) VALUES
 (1, 'Musculación',  'musculacion',  'Entrenamiento orientado a hipertrofia y desarrollo muscular con cargas externas.', TRUE),
 (2, 'CrossFit',     'crossfit',     'Entrenamiento funcional de alta intensidad que combina halterofilia, gimnasia y cardio.', TRUE),
 (3, 'Powerlifting', 'powerlifting', 'Deporte de fuerza máxima centrado en sentadilla, press de banca y peso muerto.', TRUE),
 (4, 'Weightlifting','weightlifting','Halterofilia olímpica: arranque (snatch) y envión (clean & jerk) y sus derivados.', TRUE),
 (5, 'Strongman',    'strongman',    'Entrenamiento con objetos pesados y de forma irregular: piedras, yugos, farmers, sleds.', TRUE),
 (6, 'Calistenia',   'calistenia',   'Entrenamiento con el propio peso corporal, incluyendo elementos de gimnasia.', TRUE),
 (7, 'Cardio',       'cardio',       'Trabajo cardiovascular y de acondicionamiento metabólico.', TRUE),
 (8, 'Movilidad',    'movilidad',    'Trabajo de amplitud articular, control motor y calentamiento específico.', TRUE);

SELECT setval(pg_get_serial_sequence('categorias','id'), (SELECT MAX(id) FROM categorias));

-- ---------------------------------------------------------------------
-- grupos_musculares
-- ---------------------------------------------------------------------
INSERT INTO grupos_musculares (id, nombre, slug, descripcion) VALUES
 (1, 'Pecho',    'pecho',    'Musculatura pectoral y estabilizadores escapulares anteriores.'),
 (2, 'Espalda',  'espalda',  'Musculatura dorsal, escapular y erectora del tronco.'),
 (3, 'Piernas',  'piernas',  'Musculatura del tren inferior: cadera, muslo y pantorrilla.'),
 (4, 'Hombros',  'hombros',  'Complejo del hombro: deltoides y manguito rotador.'),
 (5, 'Brazos',   'brazos',   'Flexores y extensores del codo y musculatura del antebrazo.'),
 (6, 'Core',     'core',     'Musculatura profunda y superficial del tronco encargada de la estabilidad.');

SELECT setval(pg_get_serial_sequence('grupos_musculares','id'), (SELECT MAX(id) FROM grupos_musculares));

-- ---------------------------------------------------------------------
-- musculos
-- ---------------------------------------------------------------------
INSERT INTO musculos (id, grupo_muscular_id, nombre, nombre_en, slug, descripcion) VALUES
 -- Pecho (grupo 1)
 ( 1, 1, 'Pectoral mayor',         'Pectoralis major',        'pectoral-mayor',         'Músculo principal del pecho; flexiona, aduce y rota internamente el hombro.'),
 ( 2, 1, 'Pectoral menor',         'Pectoralis minor',        'pectoral-menor',         'Músculo profundo del pecho; estabiliza la escápula.'),
 ( 3, 1, 'Serrato anterior',       'Serratus anterior',       'serrato-anterior',       'Protrae y estabiliza la escápula sobre la caja torácica.'),

 -- Espalda (grupo 2)
 ( 4, 2, 'Dorsal ancho',           'Latissimus dorsi',        'dorsal-ancho',           'Extensor, aductor y rotador interno del hombro; motor principal en tracciones.'),
 ( 5, 2, 'Trapecio superior',      'Upper trapezius',         'trapecio-superior',      'Elevación y rotación superior de la escápula.'),
 ( 6, 2, 'Trapecio medio',         'Middle trapezius',        'trapecio-medio',         'Retracción escapular.'),
 ( 7, 2, 'Trapecio inferior',      'Lower trapezius',         'trapecio-inferior',      'Depresión y rotación superior de la escápula.'),
 ( 8, 2, 'Romboides',              'Rhomboids',               'romboides',              'Retracción y rotación inferior de la escápula.'),
 ( 9, 2, 'Redondo mayor',          'Teres major',             'redondo-mayor',          'Aductor y rotador interno del hombro; auxiliar del dorsal.'),
 (10, 2, 'Redondo menor',          'Teres minor',             'redondo-menor',          'Componente del manguito rotador; rotador externo del hombro.'),
 (11, 2, 'Infraespinoso',          'Infraspinatus',           'infraespinoso',          'Componente del manguito rotador; rotador externo del hombro.'),
 (12, 2, 'Erectores espinales',    'Erector spinae',          'erectores-espinales',    'Extensores del raquis; sostienen la columna en carga.'),

 -- Hombros (grupo 4)
 (13, 4, 'Deltoides anterior',     'Anterior deltoid',        'deltoides-anterior',     'Flexor y rotador interno del hombro.'),
 (14, 4, 'Deltoides lateral',      'Lateral deltoid',         'deltoides-lateral',      'Abductor principal del hombro.'),
 (15, 4, 'Deltoides posterior',    'Posterior deltoid',       'deltoides-posterior',    'Extensor y rotador externo del hombro.'),
 (16, 4, 'Supraespinoso',          'Supraspinatus',           'supraespinoso',          'Componente del manguito rotador; inicia la abducción del hombro.'),
 (17, 4, 'Subescapular',           'Subscapularis',           'subescapular',           'Componente del manguito rotador; rotador interno del hombro.'),

 -- Brazos (grupo 5)
 (18, 5, 'Bíceps braquial',        'Biceps brachii',          'biceps-braquial',        'Flexor del codo y supinador del antebrazo.'),
 (19, 5, 'Braquial',               'Brachialis',              'braquial',               'Flexor puro del codo.'),
 (20, 5, 'Braquiorradial',         'Brachioradialis',         'braquiorradial',         'Flexor del codo en posición neutra.'),
 (21, 5, 'Tríceps cabeza larga',   'Triceps long head',       'triceps-cabeza-larga',   'Extensor del codo y aductor del hombro.'),
 (22, 5, 'Tríceps cabeza lateral', 'Triceps lateral head',    'triceps-cabeza-lateral', 'Extensor del codo.'),
 (23, 5, 'Tríceps cabeza medial',  'Triceps medial head',     'triceps-cabeza-medial',  'Extensor del codo, activo en todos los rangos.'),
 (24, 5, 'Flexores del antebrazo', 'Forearm flexors',         'flexores-antebrazo',     'Flexión de muñeca y dedos; agarre.'),
 (25, 5, 'Extensores del antebrazo','Forearm extensors',      'extensores-antebrazo',   'Extensión de muñeca y dedos.'),

 -- Core (grupo 6)
 (26, 6, 'Recto abdominal',        'Rectus abdominis',        'recto-abdominal',        'Flexor del tronco.'),
 (27, 6, 'Oblicuo externo',        'External oblique',        'oblicuo-externo',        'Flexión lateral y rotación contralateral del tronco.'),
 (28, 6, 'Oblicuo interno',        'Internal oblique',        'oblicuo-interno',        'Flexión lateral y rotación ipsilateral del tronco.'),
 (29, 6, 'Transverso abdominal',   'Transversus abdominis',   'transverso-abdominal',   'Estabilizador profundo; genera presión intraabdominal.'),
 (30, 6, 'Cuadrado lumbar',        'Quadratus lumborum',      'cuadrado-lumbar',        'Estabilizador lumbar; flexor lateral del tronco.'),

 -- Piernas (grupo 3)
 (31, 3, 'Glúteo mayor',           'Gluteus maximus',         'gluteo-mayor',           'Extensor y rotador externo de cadera.'),
 (32, 3, 'Glúteo medio',           'Gluteus medius',          'gluteo-medio',           'Abductor y estabilizador pélvico.'),
 (33, 3, 'Glúteo menor',           'Gluteus minimus',         'gluteo-menor',           'Abductor y rotador interno de cadera.'),
 (34, 3, 'Recto femoral',          'Rectus femoris',          'recto-femoral',          'Componente del cuádriceps; extensor de rodilla y flexor de cadera.'),
 (35, 3, 'Vasto medial',           'Vastus medialis',         'vasto-medial',           'Componente del cuádriceps; extensor de rodilla.'),
 (36, 3, 'Vasto lateral',          'Vastus lateralis',        'vasto-lateral',          'Componente del cuádriceps; extensor de rodilla.'),
 (37, 3, 'Vasto intermedio',       'Vastus intermedius',      'vasto-intermedio',       'Componente del cuádriceps; extensor de rodilla.'),
 (38, 3, 'Bíceps femoral',         'Biceps femoris',          'biceps-femoral',         'Isquiotibial lateral; flexor de rodilla y extensor de cadera.'),
 (39, 3, 'Semitendinoso',          'Semitendinosus',          'semitendinoso',          'Isquiotibial medial; flexor de rodilla y extensor de cadera.'),
 (40, 3, 'Semimembranoso',         'Semimembranosus',         'semimembranoso',         'Isquiotibial medial; flexor de rodilla y extensor de cadera.'),
 (41, 3, 'Aductores',              'Hip adductors',           'aductores',              'Aductores de cadera; contribuyen a la extensión.'),
 (42, 3, 'Gemelos',                'Gastrocnemius',           'gemelos',                'Flexores plantares; activos con rodilla extendida.'),
 (43, 3, 'Sóleo',                  'Soleus',                  'soleo',                  'Flexor plantar; activo con rodilla flexionada.'),
 (44, 3, 'Tibial anterior',        'Tibialis anterior',       'tibial-anterior',        'Dorsiflexor del tobillo.'),
 (45, 3, 'Psoas ilíaco',           'Iliopsoas',               'psoas-iliaco',           'Flexor principal de cadera.');

SELECT setval(pg_get_serial_sequence('musculos','id'), (SELECT MAX(id) FROM musculos));

-- ---------------------------------------------------------------------
-- equipamientos
-- ---------------------------------------------------------------------
INSERT INTO equipamientos (id, nombre, nombre_en, slug, descripcion, activo) VALUES
 ( 1, 'Barra olímpica',         'Olympic barbell',    'barra-olimpica',        'Barra estándar de 20 kg (h) / 15 kg (m), 2,20 m, con rodamientos.', TRUE),
 ( 2, 'Barra Z',                'EZ curl bar',        'barra-z',               'Barra en zigzag para trabajo de brazos.', TRUE),
 ( 3, 'Barra de dominadas',     'Pull-up bar',        'barra-dominadas',       'Barra fija para trabajo de tracción vertical.', TRUE),
 ( 4, 'Barra hip thrust',       'Hip thrust bar',     'barra-hip-thrust',      'Barra específica con almohadillado para empuje de cadera.', TRUE),
 ( 5, 'Trap Bar',               'Trap bar',           'trap-bar',              'Barra hexagonal con agarres neutros para peso muerto y farmers.', TRUE),
 ( 6, 'Mancuernas',             'Dumbbells',          'mancuernas',            'Pesas cortas de agarre unilateral.', TRUE),
 ( 7, 'Kettlebell',             'Kettlebell',         'kettlebell',            'Pesa rusa con asa; utilizada en balísticos y grinds.', TRUE),
 ( 8, 'Polea alta',             'High pulley',        'polea-alta',            'Estación de polea con punto de anclaje alto.', TRUE),
 ( 9, 'Polea baja',             'Low pulley',         'polea-baja',            'Estación de polea con punto de anclaje bajo.', TRUE),
 (10, 'Máquina Smith',          'Smith machine',      'maquina-smith',         'Barra guiada verticalmente sobre raíles.', TRUE),
 (11, 'Máquina de press',       'Chest press machine','maquina-press',         'Máquina de empuje horizontal para pecho.', TRUE),
 (12, 'Máquina de remo',        'Row machine',        'maquina-remo',          'Máquina para tracción horizontal.', TRUE),
 (13, 'Hack squat',             'Hack squat machine', 'hack-squat',            'Máquina de sentadilla con espalda apoyada.', TRUE),
 (14, 'Prensa de piernas',      'Leg press',          'prensa-piernas',        'Máquina de empuje para tren inferior.', TRUE),
 (15, 'Extensión de piernas',   'Leg extension',      'extension-piernas',     'Máquina de aislamiento para cuádriceps.', TRUE),
 (16, 'Curl femoral',           'Leg curl',           'curl-femoral',          'Máquina de aislamiento para isquiotibiales.', TRUE),
 (17, 'Peso corporal',          'Bodyweight',         'peso-corporal',         'Sin equipamiento externo; carga por el propio cuerpo.', TRUE),
 (18, 'TRX',                    'TRX suspension',     'trx',                   'Sistema de correas de suspensión.', TRUE),
 (19, 'Anillas',                'Gymnastic rings',    'anillas',               'Anillas de gimnasia suspendidas.', TRUE),
 (20, 'Caja pliométrica',       'Plyo box',           'caja-pliometrica',      'Cajón para saltos y step-ups.', TRUE),
 (21, 'Balón medicinal',        'Medicine ball',      'balon-medicinal',       'Pelota lastrada para lanzamientos y trabajo de core.', TRUE),
 (22, 'Wall Ball',              'Wall ball',          'wall-ball',             'Balón blando para lanzamientos a diana.', TRUE),
 (23, 'Disco',                  'Weight plate',       'disco',                 'Disco olímpico (bumper o de hierro).', TRUE),
 (24, 'Bandas elásticas',       'Resistance bands',   'bandas-elasticas',      'Bandas de resistencia progresiva.', TRUE),
 (25, 'Air Bike',               'Air bike',           'air-bike',              'Bicicleta de ventilador (Assault, Rogue Echo).', TRUE),
 (26, 'Concept2 Rower',         'Rower',              'rower',                 'Remoergómetro de aire/agua.', TRUE),
 (27, 'Ski Erg',                'Ski erg',            'ski-erg',               'Máquina de esquí de fondo indoor.', TRUE),
 (28, 'Cuerda para saltar',     'Jump rope',          'cuerda-saltar',         'Cuerda de velocidad para saltos.', TRUE),
 (29, 'Cuerda de escalada',     'Climbing rope',      'cuerda-escalada',       'Cuerda vertical para trepar.', TRUE),
 (30, 'Yoke',                   'Yoke',               'yoke',                  'Estructura pesada para carry en Strongman.', TRUE),
 (31, 'Sled',                   'Sled',               'sled',                  'Trineo para empujar/arrastrar carga.', TRUE),
 (32, 'Sandbag',                'Sandbag',            'sandbag',               'Saco de arena para carries y cargadas.', TRUE),
 (33, 'Atlas Stone',            'Atlas stone',        'atlas-stone',           'Piedra de hormigón para cargas verticales en Strongman.', TRUE),
 (34, 'Farmer''s Handles',      'Farmer''s handles',  'farmers-handles',       'Asas pesadas para carries de Strongman.', TRUE),
 (35, 'Log',                    'Log bar',            'log',                   'Tronco metálico grueso para press en Strongman.', TRUE),
 (36, 'Axle Bar',               'Axle bar',           'axle-bar',              'Barra de gran diámetro sin rodamientos.', TRUE),
 (37, 'Foam Roller',            'Foam roller',        'foam-roller',           'Rulo de espuma para liberación miofascial.', TRUE),
 (38, 'Banco plano',            'Flat bench',         'banco-plano',           'Banco horizontal para press y accesorios.', TRUE),
 (39, 'Banco inclinable',       'Adjustable bench',   'banco-inclinable',      'Banco con inclinación regulable.', TRUE),
 (40, 'Banco declinado',        'Decline bench',      'banco-declinado',       'Banco con declinación negativa.', TRUE),
 (41, 'Rack de sentadilla',     'Squat rack',         'rack-sentadilla',       'Soportes para sentadilla y press.', TRUE),
 (42, 'Jaula de potencia',      'Power rack',         'jaula-potencia',        'Jaula cerrada con topes de seguridad.', TRUE),
 (43, 'Plataforma de halterofilia','Lifting platform','plataforma',            'Plataforma de madera y goma para levantamientos olímpicos.', TRUE),
 (44, 'Cinturón de lastre',     'Dip belt',           'cinturon-lastre',       'Cinturón con cadena para añadir carga en dominadas o fondos.', TRUE),
 (45, 'Chaleco lastrado',       'Weight vest',        'chaleco-lastrado',      'Chaleco con pesos para calistenia y cardio.', TRUE),
 (46, 'GHD',                    'Glute Ham Developer','ghd',                   'Máquina para extensiones y sit-ups.', TRUE),
 (47, 'Paralelas',              'Parallel bars',      'paralelas',             'Barras paralelas para fondos e isométricos.', TRUE),
 (48, 'Barra fija baja',        'Low bar',            'barra-fija-baja',       'Barra fija a baja altura para remos australianos.', TRUE);

SELECT setval(pg_get_serial_sequence('equipamientos','id'), (SELECT MAX(id) FROM equipamientos));

-- ---------------------------------------------------------------------
-- tags
-- ---------------------------------------------------------------------
INSERT INTO tags (id, nombre, slug, descripcion) VALUES
 ( 1, 'Hipertrofia',       'hipertrofia',       'Adaptación orientada al crecimiento muscular.'),
 ( 2, 'Fuerza',            'fuerza',            'Adaptación de fuerza máxima.'),
 ( 3, 'Potencia',          'potencia',          'Producción de fuerza a alta velocidad.'),
 ( 4, 'Explosivo',         'explosivo',         'Ejercicios de carácter balístico.'),
 ( 5, 'EMOM',              'emom',              'Every Minute On the Minute.'),
 ( 6, 'AMRAP',             'amrap',             'As Many Rounds/Reps As Possible.'),
 ( 7, 'For Time',          'for-time',          'Formato cronometrado.'),
 ( 8, 'MetCon',            'metcon',            'Metabolic conditioning.'),
 ( 9, 'Funcional',         'funcional',         'Movimientos multiarticulares transferibles.'),
 (10, 'CrossFit Open',     'crossfit-open',     'Movimientos característicos del Open de CrossFit.'),
 (11, 'Resistencia',       'resistencia',       'Trabajo de resistencia muscular/aeróbica.'),
 (12, 'Cardio',            'cardio',            'Trabajo cardiovascular.'),
 (13, 'Movilidad',         'movilidad',         'Amplitud articular y control motor.'),
 (14, 'Estabilidad',       'estabilidad',       'Control postural y estabilización articular.'),
 (15, 'Core',              'core',              'Trabajo específico del tronco.'),
 (16, 'Unilateral',        'unilateral',        'Trabajo a una sola extremidad.'),
 (17, 'Bilateral',         'bilateral',         'Trabajo simétrico a dos extremidades.'),
 (18, 'Isométrico',        'isometrico',        'Contracción sin cambio de longitud muscular.'),
 (19, 'Pliométrico',       'pliometrico',       'Ciclo estiramiento-acortamiento.'),
 (20, 'Halterofilia',      'halterofilia',      'Movimientos olímpicos y derivados.'),
 (21, 'Powerlifting',      'powerlifting-tag',  'Movimientos de powerlifting.'),
 (22, 'Calistenia',        'calistenia-tag',    'Trabajo con peso corporal.'),
 (23, 'Gimnasia',          'gimnasia',          'Elementos gimnásticos aplicados al fitness.'),
 (24, 'Fundamental',       'fundamental',       'Movimiento base o fundacional.'),
 (25, 'Correctivo',        'correctivo',        'Ejercicio con fin correctivo postural.'),
 (26, 'Prehabilitación',   'prehabilitacion',   'Prevención de lesiones.'),
 (27, 'Calentamiento',     'calentamiento',     'Uso en preparación previa.'),
 (28, 'Accesorio',         'accesorio',         'Ejercicio complementario.'),
 (29, 'Skill',             'skill',             'Requiere aprendizaje técnico específico.'),
 (30, 'WOD',               'wod',               'Workout of the Day.'),
 (31, 'Benchmark',         'benchmark',         'WOD referencia de CrossFit.'),
 (32, 'Hero WOD',          'hero-wod',          'WOD dedicados a caídos en servicio.'),
 (33, 'Girls WOD',         'girls-wod',         'WOD clásicos denominados con nombres de mujer.'),
 (34, 'Peso corporal',     'peso-corporal-tag', 'Sin cargas externas.'),
 (35, 'Odd Object',        'odd-object',        'Objetos irregulares (sandbag, atlas stone, log).'),
 (36, 'Estiramiento',      'estiramiento',      'Trabajo de flexibilidad activa/pasiva.'),
 (37, 'Rehabilitación',    'rehabilitacion',    'Recuperación funcional.'),
 (38, 'Empuje',            'empuje',            'Patrón de empuje.'),
 (39, 'Tracción',          'traccion',          'Patrón de tracción.'),
 (40, 'Bisagra',           'bisagra',           'Patrón de bisagra de cadera.');

SELECT setval(pg_get_serial_sequence('tags','id'), (SELECT MAX(id) FROM tags));
