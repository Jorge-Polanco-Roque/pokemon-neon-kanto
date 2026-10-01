# Dirección musical — Neón Kanto 0.18

## Referencias consultadas

- **Battle! (Wild Pokémon), Red & Blue — Junichi Masuda / GAME FREAK:** [ficha oficial de la grabación en Apple Music](https://music.apple.com/us/song/741200192). Referencia de identidad de batalla portátil, no fuente de samples.
- **Trainer Battle, Red/Blue:** [interpretación publicada por L'Orchestra Cinématique](https://www.youtube.com/watch?v=sfcQhtKxius). Es una versión, no la grabación del cartucho. Referencia para distinguir la energía de entrenador de la de encuentro salvaje.
- **Gym Leader Battle, Red/Blue/Yellow:** [estudio de Rose Bridges en USC](https://scalar.usc.edu/works/video-game-music-transcription/generation-1-gym-leader-battle-theme) y [partitura de Bespinben/NinSheetMusic alojada allí](https://scalar.usc.edu/works/video-game-music-transcription/media/Pokemon%20RBY%20Gym%20Leader%20Battle%20NinSheetMusic%20Piano.pdf). La transcripción indica carácter intenso y tempo de 180; se consultó como referencia de contraste/tensión, sin transcribir sus notas al generador.
- **Arquitectura del audio Game Boy:** [Pan Docs](https://gbdev.io/pandocs/Audio.html), dos canales de pulso, uno de onda y uno de ruido.

La búsqueda y consulta documental no equivalen a una escucha comparativa completa. Las composiciones nuevas no reproducen melodías, MIDI ni grabaciones de Pokémon.

## Propuesta y realización

Composición original programática: melodía de pulso, segunda voz arpegiada, bajo FM y percusión de ruido. Ecos estéreo discretos, timbres metálicos y batería electrónica aportan el carácter cibernético. Es una interpretación moderna, no emulación exacta del chip ni arreglo literal de la banda sonora.

| Archivo | Función | BPM | Duración |
|---|---|---:|---:|
| world.wav | Refugio / exploración y menús | 100 | 38,4 s |
| wild.wav | Contacto en la red — batalla salvaje | 156 | 49,2 s |
| trainer.wav | Protocolo de duelo — entrenador | 164 | 46,8 s |
| warden.wav | Núcleo hostil — guardián/Brock | 176 | 43,6 s |
| victory.wav | Señal recuperada — victoria | 136 | 7,1 s |

`python3 tools/audio/build_soundtrack.py` requiere NumPy. Genera WAV PCM estéreo de 16 bits / 44,1 kHz, y `assets/audio/music/manifest.json` con procedencia, tempo, duración, pico, RMS y medición del empalme. El RNG de percusión tiene semilla propia y se ejecuta fuera del juego. La partitura vive en el código, con motivos explícitos y variaciones de arreglo.

Se eligió render previo a archivos en vez de síntesis pesada por frame: resultados reproducibles y reproducción estable. Los loops incorporan las colas de delay circularmente y un suavizado de 2 ms en el empalme. No se descargaron pistas, soundfonts ni samples externos. Los PNG, criaturas y partida no cambian.

## Integración

`MusicDirector` usa dos reproductores como máximo, con fundidos de 650 ms. Selecciona mundo/salvaje/entrenador/guardián, y sostiene la fanfarria al ganar antes de volver al mundo. Un nuevo rival cancela la fanfarria. Los menús conservan la música de mundo. La música se pausa al perder el foco y atenúa su nivel durante los gritos.

Buses Music/SFX/Cries → Master. F10 muestra volúmenes independientes persistentes, además del volumen general y M para silenciar. Cambiar de tema nunca desactiva el mute. Los efectos provisionales y los 20 gritos existentes siguen presentes.

## Validación y límites

Las cinco pistas tienen pico -6,74 dBFS, cero muestras recortadas y extremos del loop sin salto de amplitud. Esto no es una medición de sonoridad LUFS ni una garantía de ausencia de fatiga auditiva. Las suites `audio` y `settings` verifican selección, loops, persistencia y mute; la revisión nativa registra una secuencia mundo → salvaje → entrenador → guardián → victoria → mundo desde el bus Music.

Pendientes de P3: escucha crítica con el usuario en auriculares/altavoces, ambientes por distrito/interior, tema propio de título, derrota/captura, reemplazo de pitidos, prioridades de efectos y mezcla del recorrido completo con gritos. No se marca P3 terminada.


## Loops completos — revisión del 2026-09-28

Las muestras MP3 iniciales duraban 24 segundos y terminaban con un fade de dos segundos. Ese cierre no pertenece a los WAV que reproduce Godot. Se entregan ahora los WAV completos y demostraciones de dos ciclos concatenados a nivel PCM, sin silencio insertado ni fades de muestra.

- Salvaje: 2.171.077 frames a 44.100 Hz, 49,230771 s por vuelta.
- Guardián: 1.924.364 frames a 44.100 Hz, 43,636372 s por vuelta.
- Godot: inicio 0, final exclusivo en el total de frames, LOOP_FORWARD. El reproductor continúa después del salto; ver `docs/qa/qa-loops-godot.json`.
- La unión PCM tiene diferencia de amplitud cero entre último y primer frame. Se conserva el suavizado anticlic de 2 ms del sintetizador y las colas circulares de delay. No se cambia la composición aprobada.

Para repetir fuera del juego, usar el WAV completo con la función repetir del reproductor. La vista previa del chat no necesariamente repite automáticamente: las demostraciones contienen dos vueltas ya unidas.


## Ambientes 0.19

Se suman cinco loops ambientales de 24 s, sintetizados con NumPy por `tools/audio/build_ambience.py`: viento/goteos de Paleta, maquinaria de Brecha, escáneres de Cromo, ventilación médica y servidores del archivo. Ruido periódico de banda limitada, osciladores con ciclos enteros y colas circulares evitan un reinicio aleatorio en cada vuelta. Picos fuente de -13,98 dBFS; reproducción a -8 dB adicionales y volumen de bus configurable.

Dos reproductores ambientales como máximo y fundidos de 1,2 s, independientes de las pistas musicales aprobadas. Se retiran en batalla, regresan al mundo, respetan mute y se pausan sin foco. El ambiente no sustituye a efectos posicionales asociados a objetos, pendientes de una siguiente entrega.

QA 0.19: los cinco loops se verificaron con audio nativo. La copia de pruebas desactiva temporalmente la pausa al perder foco para grabar en segundo plano; la versión entregada mantiene esa pausa. Captura sin saturación en `docs/qa/qa-ambience-019.json`.


## Revisión oscura 0.20

A petición del usuario, la capa ambiental tiene mayor presencia y tensión: drones cercanos desafinados, tritono, resonancias de ataque lento y ecos cruzados de 317/731 ms. Los osciladores usan ciclos enteros y los ecos son circulares para conservar el loop de 24 s. No hay sustos súbitos añadidos.

Fuente: pico -11,06 dBFS; reproductor a -4 dB, conservando preferencias del usuario. El nivel de pico aumenta 6,9 dB frente a 0.19. Las músicas de batalla aprobadas permanecen iguales. Los ejemplos de dos vueltas son concatenación PCM exacta, sin fades de demostración.


## Título y auditoría de loops 0.21

Nuevo `title.wav`: 84 BPM, 16 compases, 45,714286 s, síntesis original con pulsos, bajo FM y campanas metálicas de ataque suave. Se reutilizan motivos de la partitura original del proyecto para coherencia, con tonalidad, ritmo y arreglo más lento. Las otras cinco pistas musicales se comprobaron mediante SHA-256 antes/después: no cambiaron.

Título, prólogo y selector inicial usan este tema; ajustes desde el título lo conservan. Hay diez loops de fondo (cinco musicales y cinco ambientales). La prueba nativa avanza hasta 0,3 s antes del final de cada pista y comprueba que el cursor vuelve al inicio sin detenerse. Se desactiva el control automático de los directores exclusivamente en la copia QA para evitar que la pausa por falta de foco interfiera con la prueba. La victoria conserva reproducción única.
