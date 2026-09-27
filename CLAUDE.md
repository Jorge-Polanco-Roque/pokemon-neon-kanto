# Pokémon Neón Kanto — Plan de producción

Actualizado: 2026-09-26. Base auditada: edición 0.13, Godot 4.6.2, guardado v10.
Estado: P1 en curso. 0.16 añade equipo, biblioteca y reemplazo adaptables al HUD de combate de 0.15. Interiores y los demás menús heredados todavía usan el adaptador.

## 1. Mandato y forma de trabajar

El objetivo es convertir el prototipo en una aventura cyberpunk coherente y cuidada: mejor imagen, pantalla amplia, sonido con identidad y un mundo que merezca explorarse. La calidad se evaluará jugando, viendo y escuchando el resultado, además de ejecutar pruebas.

- Proyecto autoritativo: la raíz del repositorio. Trabajar siempre aquí. Las copias de QA son temporales y no sustituyen esta carpeta.
- Este archivo es el plan activo solicitado por el usuario. `README.md` conserva el historial y las instrucciones para jugar; `docs/ARCHITECTURE.md` explica la implementación vigente. Ante contradicciones, verificar el código y actualizar ambos documentos.
- Conservar los pendientes terminados como `- [x] ~~Texto original.~~`, con versión y evidencia. No borrarlos ni marcar una fase completa cuando sólo hay un avance parcial.
- Al recibir «continúa», avanzar por la siguiente fase pendiente y cerrar una entrega comprobable. No saltar repetidamente a pequeñas funcionalidades ajenas a estas prioridades.
- Mantener una versión ejecutable al terminar cada entrega. Conservar partidas, técnicas, PP, criaturas, decisiones, recompensas y progreso de misiones.
- No ampliar la cadena de herencia existente ni añadir sistemas nuevos indiscriminadamente a `campaign_game.gd`. Extraer responsabilidades conforme se intervengan; evitar una reescritura total de una vez.
- No comprometer cambios ajenos ni crear commits sin que se solicite. No reiniciar una partida real para probar. No cerrar la aplicación del usuario si puede tener progreso sin guardar.
- Pedir información sólo cuando bloquee una decisión real. Las decisiones de diseño de este plan son supuestos de trabajo revisables; no requieren una aprobación adicional para tareas reversibles ya autorizadas.
- No cambiar Unity/Unreal por Godot: continuar en Godot. Blender será herramienta de creación de modelos cuando aporte calidad; exportar recursos utilizables por el juego.
- Prioridad de calidad: pantalla legible → dirección artística consistente → audio completo → expansión con contenido → pulido y rendimiento.

## 2. Diagnóstico comprobado

| Área | Estado en 0.13 | Problema que hay que resolver |
|---|---|---|
| Pantalla | Base y ventana 960×720, `canvas_items`; UI dibujada en coordenadas absolutas | Aumentar el tamaño no reorganiza menús ni aprovecha una pantalla panorámica |
| Mundo | Tres distritos de 28×16; terrenos, límites, entradas y encuentros codificados por índice | Tamaño pequeño y dependencias que impiden crecer con seguridad |
| Presentación | Mundo 3D en `SubViewport`, geometría modular por código, `MultiMesh`, lluvia, agua y superficies húmedas | Edificios y utilería demasiado repetidos; siluetas simples; poca variedad de materiales y composición |
| Combate | Tres fondos 2D por distrito, sprites ilustrados y efectos simples | Diferencia de acabado entre escenario, UI, personajes y criaturas |
| Criaturas | 20 formas; 12 espaldas reales, ocho pendientes; Pikachu sin rediseñar | Inconsistencia de estilo y falta de la vista correcta en varias especies |
| Audio | 20 WAV de gritos, generador de pitidos y mute general | Sin mezcla por buses, paisaje sonoro ni banda sonora terminada |
| Código | Cadena `campaign → story → neon_city → cyber → base`; controladores de cientos/miles de líneas | Presentación, interacción y estado demasiado acoplados |
| Guardado | v10, escritura temporal y reemplazo; misiones y recompensas persistentes | La migración a mapas identificados por nombre necesita reglas explícitas |
| Validación | Suites aisladas, revisión gráfica y exportación macOS | Falta matriz de pantallas, escucha sistemática y mediciones de rendimiento |

Estos son hallazgos del repositorio, no una medición de rendimiento. FPS, memoria, tiempos de carga y latencia de audio siguen sin establecerse.

## 3. Dirección del producto

### Imagen

Dirección elegida: 3D estilizado de perspectiva elevada, legible, con materiales trabajados y contraste controlado. Mantener el mundo postapocalíptico: reparaciones, vegetación superviviente, infraestructura reciclada y diferencias entre zonas habitadas y corporativas.

- Paleta: refugio cálido, agua recuperada, cobre, verde medicinal y luces de viviendas.
- Brecha: acero oxidado, ámbar industrial, humo localizado, vías suspendidas y maquinaria.
- Cromo: superficies frías, violeta, vidrio, vigilancia y publicidad controlada.
- Puerto Niebla, nuevo distrito: agua oscura, balizas, contenedores habitados y tecnología marítima reutilizada.
- Reservar colores brillantes para interacción, navegación y focos narrativos. Reducir la iluminación uniforme y los carteles que compiten con el personaje.
- Tres escalas de detalle: siluetas reconocibles a distancia; puertas, ventanas y maquinaria a media distancia; desgaste, cables y señalización cerca.
- La cámara debe mostrar rutas y entradas. Ajustar el encuadre antes de añadir decoración; edificios cercanos deben ocultarse o atenuarse si tapan al jugador.
- No basar el acabado en un filtro de brillo global. Materiales, sombras, composición y animación deben sostener la imagen incluso en el perfil gráfico bajo.

### Pantalla y lectura

Objetivo: diseño lógico 1280×720, ventana inicial 1600×900 sólo si cabe en el área útil del monitor; si no, escoger un tamaño que quepa. Compatibilidad mínima 1280×720, objetivo de revisión 1920×1080 y 2560×1440; incluir 16:10 y ultrapanorámico.

- Ventana redimensionable y pantalla completa, con opción persistente y atajo configurable.
- Probar entrada/salida de pantalla completa y cambio de monitor en macOS. No cambiar la resolución del monitor del sistema.
- UI mediante `Control`, anclajes, contenedores y un `Theme` común. Mantener paneles de lectura con ancho máximo; expandir principalmente el área del mundo.
- Escala de interfaz: 100/125/150 %. En 720p, usar desplazamiento/reflujo si no caben listas. Nunca permitir botones fuera de pantalla.
- Texto de lectura objetivo ≥18 unidades lógicas; metadatos ≥14. Contraste y estado no deben depender sólo del color.
- La resolución del mundo 3D se ajusta al área visible y al perfil de calidad; no dejarla fijada a una textura pequeña que luego se estira.
- Migración incremental: adaptador temporal para pantallas heredadas con aspecto preservado y coordenadas de clic correctas. Retirarlo a medida que cada pantalla se migre. No presentar el adaptador como la UI final.

### Sonido

Identidad: ambiente industrial y orgánico, electrónica contenida y criaturas con rasgos vocales propios. Los sonidos informan, no deben convertirse en una sucesión de alarmas.

- Buses propuestos: Master, Music, Ambience, SFX, UI y Creatures. Voz reservada para una fase posterior si se produce material narrado.
- Volumen y mute independientes, restauración de valores por defecto y persistencia en ajustes separados de la partida.
- Ambientes por distrito, interiores con mezcla propia, fundidos al entrar/salir y transición musical de exploración a combate sin cortes bruscos.
- Ducking suave de música/ambiente al sonar gritos importantes; limitar voces simultáneas y prioridad de eventos. Limitar el master como protección, no como sustituto de una mezcla correcta.
- Efectos mínimos: UI, pasos por superficie, puertas, terminales, captura, curación, daño, estados, evolución, compra, reparación y victoria/derrota.
- Al menos tres variantes de pasos e impactos frecuentes; variación pequeña de tono/volumen y límites de repetición.
- Biblioteca objetivo: tres ambientes de distrito, dos de rutas, dos de interiores, seis piezas musicales funcionales —título, refugio, industria/rutas, Cromo, combate y jefe— y stingers de resultado. Puerto añade su ambiente al abrirse.
- Revisar los 20 gritos por identidad, equilibrio y fatiga; sonidos evolutivos relacionados sin ser sólo el mismo archivo acelerado.
- WAV para efectos cortos; formato comprimido adecuado para música/ambientes largos. Objetivo de producción 48 kHz cuando la fuente lo permita; no remuestrear por apariencia de calidad.
- Probar mezcla durante al menos diez minutos con auriculares y altavoces. Verificar clipping, clics de loop, silencios incorrectos y eventos duplicados. Registrar nivel medido, sin afirmar que la escucha subjetiva por sí sola demuestra ausencia de picos.
- Registrar fuente, licencia, autor, método y ediciones de cada asset. La producción final de música y nuevos gritos depende de disponer de fuentes o herramientas adecuadas; un beep temporal debe figurar como temporal.

## 4. Arquitectura de la ampliación

Separar datos de mapa, navegación, estado del mundo y presentación. Hacerlo manteniendo adaptadores para el contenido actual.

Componentes propuestos, nombres orientativos:

| Componente | Responsabilidad |
|---|---|
| `SettingsService` | Vídeo, audio, UI y entrada; archivo de configuración separado |
| `ScreenRoot` / escenas UI | Layout, foco, navegación y adaptación a pantalla |
| `AudioDirector` | Buses, reproducción, prioridades, loops y transiciones |
| `MapDefinition` | ID estable, dimensiones, entradas, colisiones, escenas, encuentros e interacciones |
| `WorldRouter` | Carga de área, punto de llegada, transición y retorno de interiores |
| `WorldState` | Reparaciones, decisiones y objetos persistentes por ID estable |
| `WorldPresentation` | Escenas, iluminación y actores; sin autoridad sobre recompensas |
| `BattlePresentation` | Escenario, cámara y VFX; reglas de combate permanecen separadas |

Reglas técnicas:

1. Sustituir dimensiones mágicas 28/16 y condiciones `zone == n` sólo mediante una migración probada. Auditar también minimapa, entradas, colisiones, encuentros, cámara, terminales y pruebas.
2. IDs de mapas e interacciones estables. No usar posiciones o índices de arrays como identidad persistente de recompensas.
3. Partidas v10: conservar las tres zonas antiguas y sus coordenadas mediante un adaptador. Si una celda deja de ser válida, trasladar al punto seguro más cercano de ese mapa, sin resetear la campaña.
4. Copia de respaldo antes de migración, escritura atómica y prueba de ida/carga. Si falla la migración, conservar el archivo anterior y mostrar un error recuperable.
5. Cargar áreas por escena y portales. Un mundo continuo con streaming es una optimización futura, no un requisito inicial.
6. Mantener colisión en cuadrícula durante la expansión. Navegación libre sólo si una fase posterior justifica su coste; no cambiar al mismo tiempo controles, guardado y geometría.
7. Geometría estática agrupada cuando sea rentable; elementos interactivos con escenas propias y colisiones que coincidan con lo que se ve.
8. Mantener GL Compatibility como referencia inicial. Evaluar otro renderizador con comparación visual y de rendimiento en el Mac real antes de adoptar efectos dependientes de él.
9. El render y el audio no consumen el RNG usado por las reglas de combate.

## 5. Mundo objetivo y contenido

Red propuesta:

```text
Paleta — Viaducto de las Luces — Brecha — Jardines de Ceniza — Cromo
                                                               |
                                                        Canal de Retorno
                                                               |
                                                          Puerto Niebla
```

| Área | Tamaño lógico objetivo | Identidad y contenido obligatorio |
|---|---:|---|
| Paleta ampliada | 48×32 | Plaza habitable, clínica, archivo, mercado, cisterna y salida clara |
| Viaducto de las Luces | 32×24 | Ruta entre Paleta/Brecha, transporte detenido, refugio corto y un atajo desbloqueable |
| Brecha ampliada | 48×32 | Taller visitable, patios de carga, medicinas y acceso al guardián |
| Jardines de Ceniza | 32×24 | Vegetación bajo infraestructura rota, encuentros propios y una historia ambiental |
| Cromo ampliado | 48×32 | Contraste entre vigilancia y habitantes, antena, archivo corporativo y NEXUS |
| Canal de Retorno | 32×24 | Pasarelas, agua, compuertas y conexión con Puerto |
| Puerto Niebla | 48×32 | Nuevo centro habitado, dos interiores, dos NPC con función y misión propia |

La huella lógica propuesta suma 8.448 celdas frente a las 1.344 actuales, unas 6,3 veces más. **No equivale a seis veces más contenido ni a superficie caminable**: medir rutas, puntos de interés y tiempo de juego después del diseño de colisiones.

Cada área debe tener entrada/salida reconocible, orientación visual, un hito propio y motivo para volver. No aceptar cuadrículas grandes vacías. Objetivos de ritmo iniciales, pendientes de playtest: un hallazgo o decisión cada 30–60 segundos de exploración y al menos dos rutas posibles en áreas grandes. Evitar encuentros que interrumpan cada pocos pasos.

Primera expansión: Paleta + Viaducto. Validar el sistema y el ritmo antes de construir las otras cinco áreas. Conservar Red de auxilio y las decisiones de los núcleos; no reescribir sus recompensas sólo para rellenar el nuevo mundo.

## 6. Criaturas, personajes y combate

- Prioridad de arte pendiente: Pikachu frontal y espalda; después Ivysaur, Charmander, Blastoise, Raichu, Eevee, Haunter y Porygon de espalda.
- Estado real: hay 12 espaldas integradas. El generador rechazó varias solicitudes anteriores; Haunter también encontró un límite de uso. Ninguna vista frontal reflejada cuenta como espalda terminada.
- Crear una hoja de referencia por familia: silueta, materiales, proporciones, detalle cibernético, paleta y orientación frontal/trasera. No integrar imágenes aisladas con estilos contradictorios.
- Pikachu: conservar lectura de orejas, mejillas y cola; sustituir piezas superpuestas improvisadas por un diseño cibernético integrado, con materiales y detalle acordes al resto. Evaluar primero a tamaño real de batalla.
- Vista propia de espaldas, rival de frente; pivotes separados y contacto real con la sombra. Verificar evoluciones, cambios de equipo y combates de la misma especie.
- Animación mínima: reposo, anticipación, ataque, impacto y caída. Para sprites, usar capas/rig o secuencias reales cuando proceda; no confundir mover la imagen completa con una animación terminada de la criatura.
- Mara/NPCs: mejorar proporciones, manos, pies y siluetas de vestuario; direcciones de caminar, giros y reposo coherentes. Revisar deslizamiento de pies y escala contra puertas.
- Mantener personajes y criaturas distinguibles sobre fondos claros/oscuros. Más resolución no reemplaza una silueta clara.
- Si la producción de un asset falla, conservar la versión anterior y documentar el bloqueo. No insistir en eludir una restricción ni marcar la tarea completa. Valorar otro flujo de producción autorizado o assets propios con procedencia clara.

## 7. Entregas y dependencias

### P0 — Auditoría y plan

- [x] ~~Revisar pantalla, mapas, audio, arquitectura y pendientes de 0.13.~~ Evidencia: configuración y scripts del repositorio, auditados el 2026-09-26.
- [x] ~~Crear este plan con fases, criterios de salida y continuidad.~~ Entrega documental; no modifica el juego.
- [ ] Medir una línea base de FPS, frame time, memoria, carga y mezcla en el equipo real. Guardar hardware, resolución y escena usados.

### P1 — Pantalla, ajustes y base de UI · en curso

Dependencia: auditoría P0; no necesita nuevos assets.

- [x] ~~Crear `SettingsService` y escena de ajustes: ventana/completa, tamaño, escala UI, volumen y reducción de movimiento.~~ 0.14: interfaz Control, preferencias atómicas separadas, volumen general, cámara/ambiente reducido. Suite `settings` y revisión gráfica.
- [x] ~~Añadir diseño panorámico con adaptador temporal para los menús heredados. Migrar título, opciones, HUD de exploración y panel de combate primero.~~ 0.15 completa el panel de combate con controles nativos, escala UI, PP, estados y equipo de seis criaturas.
- [ ] Ajustar cámara y resolución de `SubViewport` al rectángulo disponible; preservar clics y proporciones. **Parcial 0.14:** ~~exterior a resolución física disponible y transformación inversa del adaptador~~; ~~combate proyectado al área disponible con criaturas sin deformación~~ en 0.15; falta revisar interiores migrados.
- [ ] Revisar listas de seis criaturas, nombres largos, PP, diálogos y notificaciones. **Parcial 0.15:** ~~selector de seis criaturas en combate, PP y acciones bloqueadas~~; 0.16 completa ~~equipo fuera de combate, biblioteca y reemplazo con foco/desplazamiento y PP restantes~~; faltan los demás menús y diálogos.
- [ ] Probar 1280×720, 1600×900, 1920×1080, 2560×1440, 16:10 y una ventana ultrapanorámica; escalas 100/125/150 %. **Parcial 0.14:** 18 combinaciones del HUD verificadas con render real; opciones revisadas al 150 %, ida/vuelta de pantalla completa en macOS y seis transformaciones inversas de input. 0.15 añade 54 combinaciones de combate (tres menús × seis tamaños solicitados × tres escalas), con render real y controles dentro del viewport. 0.16 añade 54 combinaciones de equipo/biblioteca/reemplazo, pie visible y desplazamiento al control enfocado. Falta aplicar la matriz al resto de menús que se migren.

Salida: ventana amplia y utilizable, preferencias persistentes, cero controles cortados, retorno correcto de pantalla completa, guardado intacto. Adjuntar capturas comparables; no basta editar `project.godot`.

### P2 — Zona de referencia visual y sonora

Dependencia: P1. Alcance acotado: plaza de Paleta, una entrada interior y un combate.

- [ ] Hoja de dirección artística y kit modular: fachada, puerta, ventana, cubierta, borde de acera, suelo, tuberías, luminarias y señalización.
- [ ] Rehacer la plaza con composición, materiales coherentes, superficies húmedas selectivas y decoración con función narrativa.
- [ ] Mejorar Mara y un NPC de referencia; caminar y reposo comprobados.
- [ ] Implementar la infraestructura de buses y un ambiente de Paleta con pasos, UI, terminal y curación.
- [ ] Trabajar Pikachu como criatura de referencia; si el asset sigue bloqueado, señalarlo y usar una criatura existente para validar la integración, sin dar Pikachu por resuelto.
- [ ] Revisar encuadre, lectura de entradas, oclusión y escena de batalla con el nuevo HUD.

Salida: una porción pequeña con el acabado objetivo y evidencia visual/sonora. Congelar sus reglas de estilo antes de replicarla. No extender decoración de baja calidad por todo el mapa.

### P3 — Audio completo y mezcla

Dependencia: infraestructura P2; independiente de la expansión de mapas.

- [ ] Construir catálogo de eventos y assets con procedencia; reemplazar pitidos temporales del flujo principal.
- [ ] Ambientes, música y transiciones por estado; interiores, pausa, pérdida de foco y regreso al mundo.
- [ ] Revisar los 20 gritos y efectos de combate con prioridad y control de repetición.
- [ ] Mezcla por buses, volumen persistente y mute real; un estado nuevo no debe reactivar canales silenciados.
- [ ] Captura de audio de un recorrido completo y medición de picos/loops; escucha en auriculares y altavoces.

Salida: título → exploración → interior → combate → victoria → exploración sin cortes, duplicados ni clipping; controles independientes comprobados.

### P4 — Mapas definidos por datos y migración

Dependencia: P1; emplea la referencia P2 sin exigir todo el catálogo artístico.

- [ ] Extraer `MapDefinition`, router, entradas, colisiones e IDs de interacción.
- [ ] Convertir las tres zonas actuales sin cambiar primero sus tamaños ni su contenido.
- [ ] Migrar guardado y mantener coordenadas, interiores, decisiones, chips y reparaciones.
- [ ] Añadir pruebas de portales, retorno de interiores, puntos seguros, mapa inválido y guardados antiguos.

Salida: mismo juego funcional sobre datos de mapas; ninguna pérdida de progreso y ninguna recompensa duplicada. No ampliar áreas antes de superar esta puerta de calidad.

### P5 — Expansión por bloques jugables

Dependencia: P2 y P4.

- [ ] P5.1: Paleta 48×32 + Viaducto; orientación, primer atajo y un interior nuevo.
- [ ] P5.2: Brecha 48×32 + Jardines de Ceniza; taller, encuentros y misión local.
- [ ] P5.3: Cromo 48×32 + Canal; archivo corporativo y acceso legible a NEXUS.
- [ ] P5.4: Puerto Niebla 48×32; dos interiores, personajes y misión con retorno al resto de la red.
- [ ] P5.5: mapa regional, destinos descubiertos, leyenda de marcadores y seguimiento de objetivo.

Cada bloque se entrega exportado, con rutas probadas, encuentros ajustados y un recorrido real. El acceso principal nunca debe depender de poseer una especie rara; ofrecer alternativas de protocolo o una adquisición asegurada.

### P6 — Consistencia del elenco y efectos

Dependencia: estilo P2 y UI P1. Puede intercalarse entre bloques P5 según disponibilidad de assets.

- [ ] Completar las 20 parejas frontal/espalda y normalizar escala/materiales.
- [ ] Estados animados de criaturas y VFX con anticipación, impacto y disipación.
- [ ] Variantes de habitantes y acciones ambientales que no bloqueen el camino.
- [ ] Revisar las 20 formas y sus rutas de evolución existentes, sonidos y transiciones; no aumentar el roster antes de terminar su presentación.

Salida: ninguna especie usa un frente reflejado como resultado final; coherencia visible entre selección, códex y batalla.

### P7 — Rendimiento, accesibilidad y demo consolidada

Dependencia: bloques anteriores incluidos en el alcance de la demo.

- [ ] Perfiles bajo/medio/alto con diferencias reales de sombras, efectos, lluvia y resolución 3D.
- [ ] Medir recorrido de diez minutos, cambios de área y varias batallas. No permitir crecimiento continuo de memoria tras repetir transiciones.
- [ ] Objetivo inicial: 60 FPS a 1080p en el equipo de referencia documentado; medir percentil 95 de frame time con meta ≤20 ms. Son metas, no garantías actuales.
- [ ] Medir cargas en frío y con caché; meta orientativa de cambio de área ≤1,5 s en el equipo de referencia, con fundido y feedback si tarda más.
- [ ] Reducción de destellos/movimiento, contraste, escala UI, foco visible y control completo por teclado; gamepad después de estabilizar navegación de UI.
- [ ] Recorrido de inicio a un final, sin debug ni ayudas de pruebas. Revisar guardado/reinicio y todos los contenidos que la demo anuncie.
- [ ] Exportación macOS reproducible, versión, créditos de assets y problemas conocidos. Otras plataformas son una entrega posterior, no una promesa implícita.

## 8. Verificación y definición de terminado

Una entrega está terminada cuando:

1. El cambio funciona en el proyecto autoritativo y en la exportación de la misma revisión.
2. Pasan las suites afectadas, sin errores de scripts nuevos. Las advertencias existentes se registran; no se presenta una ejecución con advertencias como «sin errores» de forma absoluta.
3. Se revisó con render real todo cambio visual. `--headless` valida lógica, no calidad de imagen ni audio.
4. Se probó el sonido cuando el cambio incluye audio; revisar archivos o nombres de buses no sustituye escucharlo.
5. Se conserva una partida anterior y se verifican las transacciones relevantes con archivos temporales.
6. `README.md`, este plan y la arquitectura reflejan el estado real. Se tachan sólo tareas comprobadas, con versión, prueba y captura/audio cuando corresponda.
7. Se explica brevemente qué cambió, cómo probarlo y qué queda pendiente.

Pruebas existentes: `story`, `city`, `cyber`, `campaign`, `presentation`, `tactics`, `learning`, `rear`, `chips`, `field`.

Ejemplo de prueba aislada:

```sh
python3 tests/run_story_tests.py --suite field --godot /ruta/a/Godot
```

Añadir suites de ajustes/layout, audio y transición de mapas al introducir esos sistemas. Ejecutar las que cubran la entrega y regresiones relacionadas; evitar repetir toda la batería sin motivo. Para Godot en este entorno, usar `--log-file` en una ruta temporal escribible.

Evidencia por entrega: resumen del alcance, resultados de pruebas, capturas antes/después a la misma resolución, audio si aplica, registro de versión exportada y pendientes. Las pruebas nunca usan la partida real como fixture.

## 9. Riesgos y decisiones pendientes

| Riesgo | Respuesta prevista |
|---|---|
| Abrir la pantalla revela UI rígida | Adaptador transitorio + migración de escenas; validar clics, no sólo imagen |
| Mapas mayores rompen guardados/encuentros | Migrar primero el modelo de datos conservando mapas originales |
| Más luces y detalle reducen FPS | Medir la zona de referencia; perfiles de calidad antes de multiplicar assets |
| Arte nuevo incoherente o generación bloqueada | Hoja de estilo, revisión en juego y lista explícita de pendientes; conservar fallback sin confundirlo con final |
| Música/sonidos sin fuentes disponibles | Resolver producción y procedencia; separar infraestructura lista de assets pendientes |
| Expansión grande pero vacía | Entregar por pares distrito/ruta y validar ritmo antes de ampliar el siguiente |
| La refactorización consume todo el trabajo | Extraer únicamente responsabilidades necesarias para cada entrega; mantener el juego funcional |

No hay presupuesto, fecha límite ni hardware mínimo formal acordados. No inventar un compromiso de calendario. Registrar mediciones P0 y ajustar alcance por evidencia. Tampoco se considera completado un hito por crear un archivo o escribir un plan.

## 10. Punto de reanudación

**Próximo trabajo: continuar P1 con mercados, caja, diálogos e interiores adaptables.**

Primera entrega 0.14 completada: ajustes persistentes, ventana panorámica ajustada al monitor, título/HUD adaptables y adaptador clásico. Segunda entrega 0.15: HUD de combate nativo con escenario adaptable, poses, efectos, PP y controles escalables. Tercera entrega 0.16: equipo, biblioteca y reemplazo adaptables, con PP preservados. Próximo lote: mercados y caja; después diálogos e interiores. No mezclar la migración con expansión del mapa. P0 conserva pendientes medición prolongada, cargas, memoria del proceso y escucha de mezcla.

Registro de entregas del plan:

- 2026-09-27 — 0.17 / corrección visual: restaurada la capa cibernética compartida en retratos de seis especies; filtrado lineal/mipmaps y PNG originales preservados. No avanza fases de arte nuevo.
- 2026-09-27 — 0.16 / P1 equipo: suite `learning` y 54 layouts nativos, foco/desplazamiento, botones y reemplazo sin recarga de PP; evidencia en `docs/qa/qa-team-016.json`.
- 2026-09-27 — 0.15 / P1 combate: suites `battle_ui` y `tactics`; revisión gráfica de 54 layouts, guardianes y efectos; informe en `docs/qa/qa-battle-015.json`. P1 permanece abierta.
- 2026-09-26 — 0.14 / P1 primera entrega: suites `settings`, `field`, `presentation`; revisión gráfica 720p/1080p, 18 layouts, pantalla completa y muestra breve de rendimiento en `docs/qa/benchmark-014.json`. P1 permanece abierta.
- 2026-09-26 — P0 documental: auditoría y creación de `CLAUDE.md`. Juego base permanece en 0.13; no se marca P1 iniciada.

## 11. Referencias técnicas verificadas

Son referencias de implementación; la dirección artística, dimensiones, precios y metas de este documento son decisiones del proyecto.

- [Godot: múltiples resoluciones](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html): base lógica, relación de aspecto, escalado y adaptación de interfaz.
- [Godot: buses de audio](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html): ruteo, mezcla y efectos por bus.
- [Godot: organización de escenas](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html): escenas autocontenidas y responsabilidades acotadas.

Consultar la documentación correspondiente a la versión instalada antes de adoptar APIs nuevas; los enlaces `stable` pueden cambiar de versión con el tiempo.
