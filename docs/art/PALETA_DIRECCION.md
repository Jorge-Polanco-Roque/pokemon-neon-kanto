# Paleta — refugio reparado · referencia 0.26

El refugio sigue funcionando gracias al mantenimiento comunitario. La arquitectura expresa usos concretos: oxígeno compartido en la clínica, conservación de semillas y memorias en Oak. La tecnología visible debe servir a esas funciones.

## Paleta y materiales

- Clínica: cerámica desaturada #b5b9a6, acero oscuro #263b45 y cobre #a27553; accesos cálidos #e5b779.
- Oak: paneles verde grisáceo #364e52, conducciones #75dcc8 y equipos oscuros.
- Pavimento: losas #40505a, vía central #243943; juntas y drenajes discretos. Charcos localizados con rugosidad 0.16, no brillo uniforme en toda la plaza.
- Reservar emisión para ventanas, indicadores y guías de entrada. La iluminación no debe borrar el material ni convertir toda superficie en neón.

## Kit implementado

`PaletaKit` contiene fachada modular, panel, rejilla, vidrio retranqueado con parasol, bajante con abrazaderas, cubierta con pretil, depósito de oxígeno, módulo de conservación, puerta con terminal y marquesina iluminada. Pavimento modular con juntas, drenajes, marcas de cruce y luminarias empotradas. `paleta_puddle.gdshader` recorta charcos irregulares sobre celdas seleccionadas.

Las piezas de caja se agrupan con el MultiMesh existente por material. Colores, posiciones y variaciones son deterministas, sin consumir el RNG de combate. Se conserva el perímetro jugable original: ningún adorno añade colisiones y las puertas siguen alineadas con la cuadrícula del controlador. La marquesina queda elevada.

## Reglas de composición

1. La vía central y las dos puertas deben leerse antes que las azoteas.
2. Clínica cálida al oeste, archivo verde al este: distinguir funciones sin depender de leer carteles.
3. Equipos grandes dentro de la huella de edificios; cruces, terminales y auxilio permanecen despejados.
4. Los brillos de charcos son respuesta material a iluminación; no se prometen reflejos de escena mediante SSR en el render Compatibility.
5. Probar desde la plaza y frente a ambas entradas, en 1600×900 y 1280×720 con UI150.

## Pendiente antes de congelar el estilo

Personajes Mara/NPC, vegetación menos geométrica, utilería narrativa adicional, refinamiento del borde del distrito y revisión de oclusión completa. Esta entrega es el primer kit de Paleta, no una renovación terminada del juego. El rediseño solicitado de Pikachu permanece bloqueado y no se considera realizado.

## Iteración 0.27

Mara y habitantes comparten una silueta de supervivientes con abrigo, respirador, mochila y protección de rodillas; el color distingue a cada actor. Cabeza y extremidades usan volúmenes redondeados de pocos polígonos, conservando detalles rígidos de equipo. Caminar añade flexión de rodilla y balanceo leve; reposo restablece articulaciones. Vegetación de Paleta emplea hojas en dos MultiMesh por material. Suministros en cubiertas añaden función narrativa sin ocupar rutas. Quedan acabado artístico final, borde urbano y revisión de oclusión.

## Iteración 0.28

Torres del primer plano derecho de Paleta al 45 % de su altura previa para despejar la entrada de Oak. Rótulos de interacción opacos hasta 2.5 unidades, atenuados hasta desaparecer a 6.5; texto y contorno comparten opacidad. Pasos discretos, conexión ascendente al terminal y acorde de recuperación son originales y no repetitivos. Permanecen pendientes escucha de mezcla y recorrido visual completo.
