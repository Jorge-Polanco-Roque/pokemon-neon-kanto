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
