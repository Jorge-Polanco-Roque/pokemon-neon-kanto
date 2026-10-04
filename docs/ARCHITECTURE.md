# Presentación 3D · versión 0.7

El proyecto activo está en la raíz del repositorio. La escena de entrada sigue siendo `main.tscn`.

## Responsabilidades

- `campaign_game.gd` coordina la campaña, las decisiones, el guardado y la interfaz existente. Mantiene compatibilidad con las reglas anteriores de `story_game.gd`, `neon_city.gd`, `cyber_game.gd` y `base_game.gd`.
- `scenes/world/modern_world.tscn` contiene un `SubViewport` con su propio mundo 3D. Su script recibe datos de terrenos, edificios, registros y posiciones. No conoce la partida, los Pokémon ni las reglas de combate.
- `scenes/actors/citizen.tscn` es un personaje reutilizable con nodos y pistas guardados en el `.tscn`, editables en Godot: rig articulado, materiales y `AnimationPlayer` con ciclos `walk` e `idle`. Expone métodos de pose y desplazamiento y una señal de llegada. Mara, Lía y los habitantes usan esta escena con distintas apariencias.
- `shaders/wet_surface.gdshader` y `shaders/water.gdshader` crean superficies húmedas y agua animada sin imágenes externas.

La lógica conserva colisiones en cuadrícula; los cuerpos 3D representan esas posiciones. Lía recorre caminos calculados con `AStarGrid2D`, usando los mismos límites y obstáculos del prólogo. Los peatones ambientales tienen rutas locales; no añaden colisiones que bloqueen la aventura.

La geometría estática se agrupa por material con `MultiMeshInstance3D`; se construye al cambiar de distrito, no en cada frame. La cámara y los actores se actualizan por separado. Los mapas se renderizan con MSAA en GL Compatibility. La corrupción cambia la niebla; la liberación de un núcleo conserva además sus efectos jugables.

La UI heredada continúa dibujándose en 2D, sobre la textura del `SubViewport`. Esta actualización separa la presentación del mundo y los actores; no pretende haber migrado todos los menús a escenas `Control`.

## Referencias de diseño

Se usa la recomendación de Godot de mantener escenas autocontenidas, con responsabilidades acotadas y datos proporcionados por el controlador: [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html).

El mundo 3D se integra en la interfaz mediante [SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html). Las pistas de animación se gestionan mediante [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html); los materiales emplean [StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).

## Comprobaciones

Ejecuta `python3 tests/run_story_tests.py --suite presentation --godot /ruta/al/binario/Godot`. Las suites disponibles son `presentation`, `story`, `campaign`, `city` y `cyber`. El ejecutor usa copias temporales y un archivo de guardado aislado.

Las pruebas de presentación comprueban la construcción de los tres distritos, la reutilización de geometría, las pistas del personaje y el desplazamiento de Lía. La revisión visual requiere ejecutar Godot con render gráfico: el modo `--headless` utiliza el renderizador simulado y no valida la imagen final.


## Versión 0.9: combate e interiores

`CombatRules` (`scripts/combat/combat_rules.gd`) contiene datos de movimientos, estadísticas por especie/nivel, normalización de partidas y reglas de estado sin dependencias de escena. El controlador mantiene el orden de turnos, animaciones y los efectos térmicos existentes. Cada criatura conserva cuatro valores de PP y su estado; las cargas de blindaje/interferencia son temporales. El guardado v7 añade `exploration`, conservando las coordenadas exteriores por separado de las interiores. Los lectores anteriores no se invocan para escribir encima del guardado atómico.

`clinic.tscn` y `archive.tscn` son escenas independientes de SubViewport, con `interior_world.gd` como presentación común. Se instancian sólo al entrar y se liberan al salir. El controlador es dueño de las colisiones y el estado de misión; no hay encuentros aleatorios dentro. La misión mantiene cinco estados, exige presencia junto a los personajes/relé, y revierte dinero, objetos y finalización si falla la escritura atómica.

Limitaciones: sets de movimientos predeterminados; sin IV/EV/naturalezas, sin MT, sin tabla completa de 18 tipos; interiores aún construidos por geometría en código; una misión secundaria completa. La herencia del controlador sigue siendo deuda técnica para una futura separación en componentes.


## Versión 0.10: identidad y aprendizaje de técnicas

Cada criatura guarda `techniques` (cuatro IDs estables), `known_techniques` (biblioteca) y `technique_pp` (PP de reserva). `pp` sigue siendo el contador de las cuatro ranuras usado por el controlador de combate. Antes de reemplazar, normalizar o curar, se sincronizan los contadores equipados; así no se recuperan PP al alternar técnicas. La migración asigna IDs a los cuatro movimientos anteriores conservando sus PP.

Los desbloqueos se incorporan al entrenar, ganar niveles, evolucionar y abrir el editor. Las técnicas se definen por ID y tipo original; una evolución no sustituye silenciosamente el tipo de los movimientos conocidos. La interfaz de biblioteca sólo puede abrirse fuera del combate. El guardado v8 serializa estos campos dentro de cada criatura, tanto en equipo como en caja.

## Edición 0.12

`NeuralChips` define licencias, costes, desbloqueos y compatibilidad. `CombatRules` conserva identidad, PP y datos de los seis ataques; también resuelve efectos secundarios mediante una tirada explícita. `campaign_game.gd` controla la tienda, enseñanza y transacciones de guardado con reversión. Las licencias viven en el guardado v9 y los ataques aprendidos viajan con cada criatura.

`BattleArena` dibuja tres fondos por distrito, usando exclusivamente el reloj para animación; nunca consume el generador aleatorio del combate. Las plataformas respetan los anclajes (716,291) y (238,455).

## Edición 0.13

`FieldProtocols` define posiciones y compatibilidad de tres instalaciones. El controlador de campaña valida proximidad, nivel y PS, aplica recompensas y guarda con reversión completa si falla. `restored_sites` se filtra al cargar el guardado v10. La restauración reduce corrupción sin alterar las decisiones de núcleo ni sus finales.

`modern_world.build_district` recibe estados restaurados como argumento opcional y construye las instalaciones. Al reparar/cargar/reiniciar se invalida la escena para reconstruir su estado visual. La presentación no modifica progreso ni recompensas.

## Edición 0.14 — primera entrega P1

`SettingsService` valida y persiste preferencias en `user://neon_settings.cfg` mediante archivo temporal. No escribe partidas. Aplica volumen/mute en Master y reestablece la ventana después de la transición de pantalla completa de macOS; una revisión invalida restauraciones diferidas antiguas.

`ScreenRoot` es un CanvasLayer separado: controles nativos para título, ajustes y HUD exterior, y adaptador uniforme centrado para las pantallas heredadas. La transformación del Node2D conserva el uso de `get_global_mouse_position()` en coordenadas locales. `WorldMinimap` mantiene marcadores de jugador, terminal y auxilio. El SubViewport exterior recibe dimensiones físicas del área de mapa; interiores y combate siguen pendientes de migración. Los ajustes no se abren durante combate y la escala 100/125/150 % sólo afecta a la UI nueva.


## Edición 0.15 — presentación de combate

`BattleHUD` es un Control bajo `ScreenRoot`. Contenedores distribuyen tarjetas de estado, área de escenario, registro desplazable y cuadrícula de acciones. Los botones comparten despacho con atajos y respetan bloqueo de turnos; la lógica de combate sigue en el controlador. El HUD no consume RNG ni modifica guardados.

`draw_battle_scene()` separa arena/criaturas/efectos del HUD heredado. `battle_point()` proyecta anclajes y trayectorias al ancho lógico del área de escenario; su transformación uniforme conserva proporciones de sprites y pivotes. Al salir del combate se restaura el adaptador de las pantallas restantes. El fondo de arena amplía su geometría horizontalmente; la escala de texto no deforma criaturas.

La suite `battle_ui` verifica restricciones, Forcejeo, teclado, cambio de equipo con coste real de turno y contacto de pivotes. La revisión nativa comprueba 54 layouts; la matriz no sustituye una revisión completa de ratón/gamepad ni de todos los nombres personalizados.


## Edición 0.16 — equipo y biblioteca

`TeamScreen` bajo `ScreenRoot` presenta `party` y `techniques`, con un estado de reemplazo exclusivo cuando existe `pending_technique`. Usa ScrollContainer con seguimiento de foco y un pie fuera del área desplazable. Los controles se reconstruyen cuando cambian estado, datos, resolución o escala, restaurando el foco por identificador de acción cuando sigue disponible.

Todas las mutaciones pasan por `game.action`; las reglas de evolución, entrenamiento, aprendizaje y PP se conservan en sus controladores. La biblioteca muestra los PP equipados directamente y los PP de reserva de `technique_pp`. No modifica la partida para dibujar. Los menús de caja y chips siguen usando el adaptador al abrirse desde estos controles.

La revisión gráfica de 0.16 activa señales de botones reales y atajos, valida reemplazo/cancelación y recorre foco por cada acción habilitada. Comprueba 54 configuraciones de layout y que los controles enfocados entren en el área desplazable. No constituye una revisión de mando ni de todas las combinaciones de nombres personalizados.


## Edición 0.17 — una composición compartida para criaturas

`CyberAugmentation.draw()` contiene la geometría mecánica que antes vivía en `cyber_game.gd`. El combate delega en ese recurso y `CreaturePortrait` lo invoca desde su propio `_draw()`, después del PNG base. Así las fichas no pierden la capa cibernética. La presentación no instancia un segundo controlador ni renderiza retratos a una textura intermedia de baja resolución.

Las ilustraciones conservan sus archivos fuente y compresión sin pérdida. Sus importaciones generan mipmaps; el controlador y los retratos usan `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. Las vistas traseras con arte propio siguen evitando la superposición frontal, tal como antes.

## Edición 0.18 — música programática y mezcla

`tools/audio/build_soundtrack.py` renderiza cinco partituras originales a PCM estéreo con NumPy. La generación es previa a la ejecución y su ruido tiene semilla independiente. `MusicDirector` carga las pistas, configura loops y usa dos AudioStreamPlayer con envolventes lineales de 650 ms; un cambio rápido reutiliza un slot y no acumula tweens/reproductores. No consume el RNG de encuentros o combate.

El controlador de campaña notifica victoria, mientras el director resuelve los demás estados a partir de modo, entrenador y guardián. Los gritos atenúan la música; perder foco pausa ambos reproductores. Buses Music/SFX/Cries envían a Master; SettingsService crea buses de forma idempotente y persiste niveles individuales con valores por defecto para preferencias antiguas. Ninguna transición del director modifica mute/volumen de Master.

`audio_test.gd` verifica selección de temas, loops, fanfarria, buses y persistencia. La QA nativa captura el bus Music antes de Master para medir transiciones sin reproducir sonido en la sesión de prueba. El catálogo de ambientes/efectos de P3 permanece pendiente.


## Edición 0.19 — ambientes independientes

`build_ambience.py` sintetiza ruido periódico mediante FFT, zumbidos de ciclos enteros y eventos con colas circulares. No usa samples ni el RNG del juego. Cinco WAV PCM de 24 segundos alimentan `AmbienceDirector`, con dos reproductores, fundidos de 1,2 segundos y bus Ambience → Master. La selección usa distrito e interior; combate/título/prólogo/evolución retiran la capa. La música no se sustituye ni se modifica.

SettingsService conserva un nivel `ambience_volume` por defecto de 0,6 para ajustes antiguos. La suite de audio comprueba selección, silencio en combate, retorno, persistencia y mute. La QA nativa verifica los cinco empalmes reproduciendo desde el final real y graba el bus de ambiente antes de Master.


## Edición 0.22 — mercados y almacenamiento

`CommerceScreen` reutiliza el contenedor, pie fijo, botones y restauración de foco de `TeamScreen`, cuya construcción se separa en `build_contents()`. `ScreenRoot` enruta los modos archive/shop/chips a controles nativos. Las mutaciones pasan por las acciones existentes; no cambia el formato de partida. Chips mantienen sus transacciones automáticas; suministros y caja muestran recordatorios de guardado manual F5. Los retratos usan `CreaturePortrait` y sus aumentos cibernéticos.

La revisión nativa verifica 54 layouts, desplazamiento al foco, equipo lleno, último compañero consciente, conservación de datos/PP, compras, compatibilidad, enseñanza y recarga. La suite chips cubre regresión de transacciones y aprendizaje. No sustituye una revisión completa con mando.


## Edición 0.23 — conversaciones e interiores

`DialogueScreen` reutiliza el contenedor desplazable de TeamScreen. El texto narrativo de la misión vive en `campaign_game.air_dialogue_text()`, compartido con el dibujado heredado. Todas las opciones despachan las acciones existentes. ScreenRoot presenta clínica/archivo usando su SubViewport a resolución física, oculta el minimapa exterior y añade salida. La cámara interior conserva altura y amplía encuadre en relaciones estrechas.

La QA nativa cubre 54 layouts, texto largo al 150 %, curación, aceptación, membrana y retorno a posición exterior. No completa la migración de los demás menús ni una revisión de mando.


## Edición 0.24 — paneles de exploración

`ExplorationScreen` deriva de TeamScreen y presenta bag/dex/detail/workshop/campaign/journal/field. Las acciones existentes conservan autoridad sobre PS, módulos, registros y reparaciones. La interfaz bloquea acciones no disponibles y muestra motivos/contexto. Códex y ficha usan CreaturePortrait para conservar aumentos cibernéticos y mipmaps; la cuadrícula elige dos o cuatro columnas según ancho y escala.

TeamScreen revela el foco después de que los contenedores calculen su geometría. Evita dejar fuera del área visible un botón cuyo foco se conserva al reconstruir la interfaz. Los menús no cambian la versión ni la política de guardado; suministros/implantes siguen siendo manuales y auxilio mantiene transacciones automáticas.


## Edición 0.25 — pantallas especiales

`SpecialScreen` reutiliza el contenedor y restauración de foco de TeamScreen. ScreenRoot enruta starter/hacking/evolution/core_choice/ending. El estado visual del hackeo se reconstruye al cambiar lectura, entrada o error; la cuenta atrás actualiza una etiqueta. Evolution actualiza progreso y species_id del retrato sin reconstrucción por frame, conserva el temporizador del controlador y no añade flashes. Los atajos globales de audio/pantalla siguen disponibles.

Las consecuencias y narrativa final se consultan en core_choice_descriptions()/ending_text(), compartidas con el render heredado. Selección y confirmación despachan acciones distintas; no se aplica ni guarda una elección por enfocarla. commit_fate conserva la reversión ante error. No se modifica el formato de partida ni las pistas de audio.


## Edición 0.26 — kit de Paleta

`PaletaKit` recibe el viewport de presentación para emitir geometría agrupada mediante sus helpers. Solo se aplica al distrito 0, fuera del prólogo. Fachadas usan las huellas y puertas existentes; pavimento se omite en agua, vegetación y obstáculos. Charcos recortados usan ShaderMaterial independiente sin animación ni RNG. No cambia colisiones, guardados ni lógica de interacción. La geometría permanece ligada a scene_key y no se reconstruye por frame.


## Edición 0.27 — refinamiento del rig y hojas

Citizen.refine_model conserva nombres del rig base y añade Knee bajo cada pierna; recoloca bota y pantorrilla. Duplica AnimationLibrary antes de extender walk/idle para evitar mutación cruzada entre instancias. No altera posición lógica ni navegación. El constructor procedural y la escena guardada comparten refinamiento.

Los batches de ModernWorld aceptan mesh opcional; por defecto siguen usando BoxMesh. PaletaKit agrupa todas las hojas en dos SphereMesh de pocos segmentos mediante MultiMesh, sin nodos por hoja ni RNG. La utilería nueva permanece en cubiertas.


## Edición 0.28 — efectos de interacción

InteractionAudio usa cuatro AudioStreamPlayer en SFX: uno exclusivo para pasos y tres rotatorios para eventos. No consume RNG. La UI limita disparos a uno cada 55 ms; pasos alternan pitch 0.94/1.06. Campaign conecta movimiento exitoso, begin_hack y heal_party; beep con parámetros por defecto se sustituye por UI, conservando otros tonos heredados. Los efectos no se repiten y se pausan con pérdida de foco/mute. El generador build_interactions.py conserva procedencia, semilla y picos en manifest.json.

ModernWorld atenúa texto y contorno de rótulos contextuales por distancia horizontal. Paleta baja torres del primer plano derecho; no altera colisiones ni geometría jugable.
