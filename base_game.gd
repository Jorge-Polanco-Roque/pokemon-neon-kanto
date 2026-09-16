extends Node2D

const SAVE = "user://neon_kanto_v3.json"
const INK = Color("192e43")
const WHITE = Color("f5f4df")
const MINT = Color("8fe0b0")
const GOLD = Color("ffd779")
const BLUE = Color("4fb7d6")
const TILE = 32
const ORIGIN = Vector2(32, 104)
const SPECIES = {
 1: ["BULBASAUR", "PLANTA", 45, 49, 49],
 2: ["IVYSAUR", "PLANTA", 60, 62, 63],
 3: ["VENUSAUR", "PLANTA", 80, 82, 83],
 4: ["CHARMANDER", "FUEGO", 39, 52, 43],
 5: ["CHARMELEON", "FUEGO", 58, 64, 58],
 6: ["CHARIZARD", "FUEGO", 78, 84, 78],
 7: ["SQUIRTLE", "AGUA", 44, 48, 65],
 8: ["WARTORTLE", "AGUA", 59, 63, 80],
 9: ["BLASTOISE", "AGUA", 79, 83, 100],
 25: ["PIKACHU", "ELÉCTRICO", 35, 55, 40],
 26: ["RAICHU", "ELÉCTRICO", 60, 90, 55],
 133: ["EEVEE", "NORMAL", 55, 55, 50],
 134: ["VAPOREON", "AGUA", 130, 65, 60],
 135: ["JOLTEON", "ELÉCTRICO", 65, 65, 60],
 92: ["GASTLY", "FANTASMA", 30, 35, 30],
 93: ["HAUNTER", "FANTASMA", 45, 50, 45],
 94: ["GENGAR", "FANTASMA", 60, 65, 60],
 123: ["SCYTHER", "BICHO", 70, 110, 80],
 212: ["SCIZOR", "ACERO", 70, 130, 100],
 137: ["PORYGON", "NORMAL", 65, 60, 70]
}
const MOVES = {
 "PLANTA": ["LÁTIGO CEPA", "PLANTA", 45], "FUEGO": ["ASCUAS", "FUEGO", 40],
 "AGUA": ["BURBUJA", "AGUA", 40], "BICHO": ["PICOTAZO", "BICHO", 35],
 "NORMAL": ["ATAQUE RÁPIDO", "NORMAL", 40], "ELÉCTRICO": ["IMPACTRUENO", "ELÉCTRICO", 40],
 "ROCA": ["LANZARROCAS", "ROCA", 45],
 "FANTASMA": ["PULSO ESPECTRAL", "FANTASMA", 45],
 "ACERO": ["PINZA MAGNÉTICA", "ACERO", 50]
}
var font: Font = ThemeDB.fallback_font
var sprites: Dictionary = {}
var buttons: Array = []
var mode = "title"
var zone = 0
var pos = Vector2i(13, 12)
var visual_pos = Vector2(13, 12)
var facing = Vector2i.DOWN
var step_cool = 0.0
var clock = 0.0
var steps = 0
var party: Array = []
var active = 0
var balls = 25
var potions = 5
var money = 500
var rival_done = false
var badge = false
var seen: Array = []
var captured: Array = []
var message = ""
var after_dialogue = "world"
var enemy: Dictionary = {}
var trainer = ""
var trainer_queue: Array = []
var battle_text = ""
var turn_locked = false
var battle_end = false
var battle_menu = "main"
var attack_fx = {}
var enemy_hp_visual = 0.0
var player_hp_visual = 0.0
var walk_phase = 0.0
var walking = false
var flash = 0.0
var enemy_flash = 0.0
var encounter_grace = 6
var notice = ""
var notice_time = 0.0
var save_exists = false
var smoke = false
var audio: AudioStreamPlayer
var oscillator: AudioStreamGeneratorPlayback
var phase = 0.0
var sound_time = 0.0
var frequency = 440.0
var muted = false

func _ready():
 randomize()
 for id in SPECIES:
  var path = "res://assets/creatures/"+str(id)+".png"
  if ResourceLoader.exists(path): sprites[str(id)] = load(path)
 save_exists = FileAccess.file_exists(SAVE)
 audio = AudioStreamPlayer.new()
 var stream = AudioStreamGenerator.new()
 stream.mix_rate = 22050
 stream.buffer_length = 0.12
 audio.stream = stream
 add_child(audio)
 audio.play()
 oscillator = audio.get_stream_playback()
 smoke = "--smoke-test" in OS.get_cmdline_user_args()
 if smoke:
  call_deferred("run_smoke_tests")
 elif "--preview-world" in OS.get_cmdline_user_args():
  reset_game()
  action("starter:7")
  mode = "world"
 elif "--preview-battle" in OS.get_cmdline_user_args():
  reset_game()
  action("starter:7")
  start_battle(mon(4,5))
 elif "--integration-test" in OS.get_cmdline_user_args():
  call_deferred("run_integration_tests")

func beep(hz = 660.0, duration = 0.08):
 frequency = hz
 sound_time = duration

func _process(delta):
 clock += delta
 if mode == "battle" and not party.is_empty():
  enemy_hp_visual = move_toward(enemy_hp_visual,float(enemy.hp),delta*35.0)
  player_hp_visual = move_toward(player_hp_visual,float(party[active].hp),delta*35.0)
 step_cool = maxf(0, step_cool - delta)
 flash = maxf(0, flash - delta)
 enemy_flash = maxf(0, enemy_flash - delta)
 notice_time = maxf(0, notice_time - delta)
 walking = visual_pos.distance_to(Vector2(pos)) > 0.025
 if walking: walk_phase += delta * 12.0
 visual_pos = visual_pos.move_toward(Vector2(pos), delta * 8.0)
 if oscillator:
  var count = oscillator.get_frames_available()
  for i in range(count):
   var amp = 0.0
   if sound_time > 0 and not muted:
    amp = (0.035 if sin(phase) > 0 else -0.035) * minf(1.0, sound_time * 30)
    phase += TAU * frequency / 22050.0
    sound_time -= 1.0 / 22050.0
   oscillator.push_frame(Vector2(amp, amp))
 if mode == "world" and step_cool <= 0:
  var dir = Vector2i.ZERO
  if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W): dir = Vector2i.UP
  elif Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S): dir = Vector2i.DOWN
  elif Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): dir = Vector2i.LEFT
  elif Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): dir = Vector2i.RIGHT
  if dir != Vector2i.ZERO: move_player(dir)
 queue_redraw()

func _unhandled_input(event):
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  for b in buttons:
   if b.rect.has_point(get_global_mouse_position()):
    action(b.action)
    return
 if event is InputEventKey and event.pressed and not event.echo:
  var key = event.physical_keycode
  if key == KEY_M:
   muted = not muted
   toast("SONIDO " + ("DESACTIVADO" if muted else "ACTIVADO"))
  if key == KEY_ESCAPE:
   if mode in ["party", "bag", "dex", "shop"]: mode = "world"
   elif mode == "battle" and not turn_locked: battle_menu = "main"
  if key in [KEY_Z, KEY_E, KEY_ENTER, KEY_SPACE]:
   if mode == "dialogue": action("continue")
   elif mode == "world": interact()
   elif mode == "title": action("new")
  if mode == "world":
   if key == KEY_P: mode = "party"
   if key == KEY_B: mode = "bag"
   if key == KEY_F5: save_game()
  elif key >= KEY_1 and key <= KEY_6:
   var idx = key - KEY_1
   if idx < buttons.size(): action(buttons[idx].action)

func mon(id: int, level: int) -> Dictionary:
 var hp = int(SPECIES[id][2] * 2 * level / 100.0) + level + 10
 return {"id": id, "level": level, "hp": hp, "maxhp": hp, "xp": 0}

func reset_game():
 zone = 0
 pos = Vector2i(13,12)
 visual_pos = Vector2(pos)
 party = []
 active = 0
 balls = 25
 potions = 5
 money = 500
 rival_done = false
 badge = false
 seen = []
 captured = []
 mode = "starter"

func action(a: String):
 beep()
 if a == "new":
  if save_exists and mode == "title":
   message = "Tu partida guardada se conservará hasta que guardes la nueva aventura."
   after_dialogue = "starter_new"
   mode = "dialogue"
  else: reset_game()
 elif a == "load": load_game()
 elif a.begins_with("starter:"):
  var id = int(a.split(":")[1])
  party = [mon(id, 5)]
  captured = [id]
  seen = [id]
  say("PROF. OAK\n¡" + SPECIES[id][0] + " será tu compañero! Te doy 25 Poké Balls y 5 pociones. Explora la Corredor de Datos al norte. En Distrito Cromo puedes curarte y desafiar a Brock.")
 elif a == "continue":
  if after_dialogue == "starter_new": reset_game()
  else: mode = after_dialogue
 elif a == "world": mode = "world"
 elif a == "party": mode = "party"
 elif a == "bag": mode = "bag"
 elif a == "dex": mode = "dex"
 elif a == "save": save_game()
 elif a == "interact": interact()
 elif a == "heal":
  heal_party()
  say("CENTRO POKÉMON\n¡Tu equipo está completamente recuperado! Te esperamos cuando lo necesites.")
 elif a == "buy_ball":
  if money >= 100:
   money -= 100
   balls += 1
   toast("+1 POKÉ BALL")
  else: toast("No tienes suficientes ₽.")
 elif a == "buy_potion":
  if money >= 150:
   money -= 150
   potions += 1
   toast("+1 POCIÓN")
  else: toast("No tienes suficientes ₽.")
 elif a.begins_with("lead:"):
  var i = int(a.split(":")[1])
  if party[i].hp > 0:
   active = i
   toast(SPECIES[int(party[i].id)][0] + " lidera tu equipo.")
 elif a.begins_with("potion:"):
  use_potion(int(a.split(":")[1]))
 elif mode == "battle" and not turn_locked:
  if a == "fight": battle_menu = "moves"
  elif a == "attack": player_attack(false)
  elif a == "special": player_attack(true)
  elif a == "catch": catch_mon()
  elif a == "run": run_away()
  elif a == "battle_potion": battle_potion()
  elif a == "switch": battle_menu = "switch"
  elif a.begins_with("switch:"): switch_mon(int(a.split(":")[1]))
  elif a == "battle_back": battle_menu = "main"

func say(s: String):
 message = s
 after_dialogue = "world"
 mode = "dialogue"

func toast(s: String):
 notice = s
 notice_time = 3.0

func terrain(x: int, y: int) -> String:
 if x < 0 or x >= 28 or y < 0 or y >= 16: return "wall"
 if (x == 0 or x == 27): return "tree"
 if y == 0 or y == 15:
  if x in [13,14] and ((y == 0 and zone < 2) or (y == 15 and zone > 0)): return "path"
  return "tree"
 if zone == 0:
  if x >= 2 and x <= 8 and y >= 10 and y <= 14: return "water"
  if x >= 18 and x <= 25 and y >= 10 and y <= 13: return "flowers"
  if x in [13,14] or y in [8,9]: return "path"
  if (x < 3 or x > 24) and y < 8: return "tree"
 elif zone == 1:
  if x in [13,14] or y in [7,8]: return "path"
  if (x >= 3 and x <= 11 and y >= 2 and y <= 6) or (x >= 17 and x <= 24 and y >= 9 and y <= 13): return "grass"
  if (x >= 18 and x <= 24 and y >= 2 and y <= 5): return "water"
  if (x in [2,25] and y % 3 != 0): return "tree"
 elif zone == 2:
  if x in [13,14] or y in [10,11]: return "path"
  if x >= 2 and x <= 7 and y >= 12: return "flowers"
 return "lawn"

func buildings() -> Array:
 if zone == 0:
  return [[Rect2i(4,3,6,4),"CASA",Color("d87967")], [Rect2i(18,3,7,4),"LAB. OAK",Color("7e9ccc")]]
 if zone == 2:
  return [[Rect2i(3,3,7,5),"CENTRO",Color("df6d77")], [Rect2i(18,2,7,5),"GIMNASIO",Color("ad94cd")]]
 return []

func walkable(p: Vector2i) -> bool:
 if terrain(p.x,p.y) in ["wall","tree","water"]: return false
 for b in buildings():
  if b[0].has_point(p): return false
 if p == npc_position(): return false
 return true

func npc_position() -> Vector2i:
 if zone == 0: return Vector2i(17,9)
 if zone == 1: return Vector2i(14,6)
 return Vector2i(17,11)

func move_player(dir: Vector2i):
 facing = dir
 var next = pos + dir
 step_cool = 0.14
 if next.y < 0 and zone < 2:
  zone += 1
  pos = Vector2i(pos.x,14)
  visual_pos = Vector2(pos)
  encounter_grace = 5
  return
 if next.y > 15 and zone > 0:
  zone -= 1
  pos = Vector2i(pos.x,1)
  visual_pos = Vector2(pos)
  encounter_grace = 5
  return
 if not walkable(next): return
 pos = next
 steps += 1
 encounter_grace -= 1
 if terrain(pos.x,pos.y) == "grass" and encounter_grace <= 0 and randf() < 0.16:
  var pool = [1,4,7,133] if zone==0 else ([25,92,123,137] if zone==2 else [1,4,7,25,133,92,123,137])
  start_battle(mon(pool.pick_random(), randi_range(4,8)))

func interact():
 if mode != "world": return
 var target = pos + facing
 for b in buildings():
  var door = Vector2i(b[0].position.x + b[0].size.x / 2, b[0].end.y - 1)
  if target.distance_to(door) <= 1.1 or pos.distance_to(door) <= 1.1:
   if b[1] == "CASA" or b[1] == "CENTRO":
    heal_party()
    say("¡DESCANSA UN MOMENTO!\nTu equipo recuperó todos sus PS.")
   elif b[1] == "LAB. OAK": say("PROF. OAK\nPara capturar un Pokémon, debilítalo primero y luego lanza una Poké Ball. Revisa tus capturas en la Pokédex.")
   elif not rival_done: say("GIMNASIO\nBrock te espera. Antes, demuestra tu fuerza venciendo a tu rival en la Corredor de Datos.")
   elif badge: say("BROCK\nYa ganaste la Medalla Circuito. ¡Sigue explorando y completando tu colección!")
   else:
    trainer_queue = [mon(94,12)]
    start_battle(mon(212,11), "BROCK")
   return
 if target.distance_to(npc_position()) <= 1.1:
  if zone == 0: say("PROF. OAK\nLa Corredor de Datos está al norte. Busca Pokémon en la hierba alta y habla con tu rival. Guarda tu progreso con F5.")
  elif zone == 1:
   if rival_done: say("AZUL\n¡Bien hecho! Brock está en el gimnasio de Distrito Cromo, al norte.")
   else:
    var rival_id = 133
    trainer_queue = []
    start_battle(mon(rival_id,6), "AZUL")
  else:
   mode = "shop"
  return
 toast("Acércate a una puerta o a una persona y pulsa E.")

func heal_party():
 for p in party: p.hp = p.maxhp

func use_potion(i: int) -> bool:
 if potions <= 0:
  toast("No quedan pociones.")
  return false
 if party[i].hp <= 0:
  toast("Un Pokémon debilitado necesita el Centro Pokémon.")
  return false
 if party[i].hp == party[i].maxhp:
  toast("Este Pokémon ya tiene todos sus PS.")
  return false
 party[i].hp = mini(party[i].maxhp,party[i].hp + 20)
 potions -= 1
 toast("+20 PS · " + SPECIES[int(party[i].id)][0])
 return true

func start_battle(wild: Dictionary, opponent = ""):
 if not has_living():
  heal_party()
  pos = Vector2i(13,12)
  zone = 0
  visual_pos = Vector2(pos)
  return
 if party[active].hp <= 0: active = first_living()
 enemy = wild
 attack_fx = {}
 enemy_hp_visual = float(enemy.hp)
 player_hp_visual = float(party[active].hp)
 trainer = opponent
 if not int(enemy.id) in seen: seen.append(int(enemy.id))
 battle_text = ("¡Un " + SPECIES[int(enemy.id)][0] + " salvaje!") if trainer == "" else trainer + " envía a " + SPECIES[int(enemy.id)][0] + "."
 battle_menu = "main"
 battle_end = false
 turn_locked = false
 mode = "battle"
 beep(220,0.2)

func has_living() -> bool:
 return first_living() >= 0

func first_living() -> int:
 for i in range(party.size()):
  if party[i].hp > 0: return i
 return -1

func type_factor(attack_type: String, defender: String) -> float:
 if (attack_type == "AGUA" and defender in ["FUEGO","ROCA"]) or (attack_type == "PLANTA" and defender in ["AGUA","ROCA"]) or (attack_type == "FUEGO" and defender in ["PLANTA","BICHO"]) or (attack_type == "ELÉCTRICO" and defender == "AGUA"): return 2.0
 if (attack_type == "FUEGO" and defender in ["AGUA","ROCA","FUEGO"]) or (attack_type == "AGUA" and defender in ["AGUA","PLANTA"]) or (attack_type == "PLANTA" and defender in ["PLANTA","FUEGO","BICHO"]) or (attack_type == "NORMAL" and defender == "ROCA"): return 0.5
 if attack_type == "ELÉCTRICO" and defender == "ROCA": return 0.0
 return 1.0

func damage(attacker: Dictionary, defender: Dictionary, power: int, kind: String) -> int:
 var a = SPECIES[int(attacker.id)]
 var d = SPECIES[int(defender.id)]
 var attack = a[3] * 2.0 * attacker.level / 100 + 5
 var defense = d[4] * 2.0 * defender.level / 100 + 5
 var factor = type_factor(kind,d[1])
 if factor == 0: return 0
 return maxi(1,int(((2.0 * attacker.level / 5 + 2) * power * attack / defense / 50 + 2) * factor * randf_range(0.85,1.0)))

func player_attack(special: bool):
 turn_locked = true
 battle_menu = "main"
 var p = party[active]
 var move = MOVES[SPECIES[int(p.id)][1]] if special else ["PLACAJE","NORMAL",40]
 var hit = damage(p,enemy,move[2],move[1])
 attack_fx = {"start":clock, "kind":move[1], "own":true, "duration":0.95}
 enemy_flash = 0.0
 battle_text = SPECIES[int(p.id)][0] + " usa " + move[0] + ".  −" + str(hit) + " PS"
 var factor = type_factor(move[1],SPECIES[int(enemy.id)][1])
 if factor > 1: battle_text += "\n¡Es muy eficaz!"
 elif factor == 0: battle_text += "\nNo tiene efecto."
 elif factor < 1: battle_text += "\nNo es muy eficaz…"
 beep(330,0.16)
 await get_tree().create_timer(0.42).timeout
 enemy.hp = maxi(0,enemy.hp - hit)
 await get_tree().create_timer(0.63).timeout
 if enemy.hp <= 0: await win_battle()
 else: await enemy_turn()

func enemy_turn():
 var move = MOVES[SPECIES[int(enemy.id)][1]] if randf() < 0.5 else ["PLACAJE","NORMAL",40]
 var hit = damage(enemy,party[active],move[2],move[1])
 battle_text = SPECIES[int(enemy.id)][0] + " usa " + move[0] + ".  −" + str(hit) + " PS"
 attack_fx = {"start":clock, "kind":move[1], "own":false, "duration":0.8}
 flash = 0.0
 beep(180,0.12)
 await get_tree().create_timer(0.36).timeout
 party[active].hp = maxi(0,party[active].hp - hit)
 await get_tree().create_timer(0.49).timeout
 if party[active].hp <= 0:
  if has_living():
   active = first_living()
   battle_text = "¡Adelante, " + SPECIES[int(party[active].id)][0] + "!"
  else:
   end_battle()
   heal_party()
   zone = 0
   pos = Vector2i(13,12)
   visual_pos = Vector2(pos)
   money = maxi(0,money-100)
   say("TU EQUIPO NECESITA DESCANSAR\nVolviste a casa y recuperaste todos tus PS. Perdiste hasta ₽100. Puedes volver a intentarlo.")
 turn_locked = false

func win_battle():
 var reward = int(enemy.level) * 22
 var p = party[active]
 p.xp += reward
 battle_text = "¡" + SPECIES[int(enemy.id)][0] + " se debilitó!  +" + str(reward) + " EXP"
 while p.xp >= p.level * 12:
  p.xp -= p.level * 12
  p.level += 1
  p.maxhp += 3
  p.hp = mini(p.maxhp, p.hp + 6)
  battle_text += "\n¡" + SPECIES[int(p.id)][0] + " sube al nivel " + str(p.level) + "!"
 await get_tree().create_timer(1.3).timeout
 if has_method("evolve_after_victory"): await evolve_after_victory()
 if not trainer_queue.is_empty() and trainer != "":
  var next = trainer_queue.pop_front()
  start_battle(next,trainer)
  return
 if trainer == "AZUL":
  rival_done = true
  money += 300
  end_battle()
  say("AZUL\n¡Esta vez ganaste tú! Recibes ₽300. Sigue al norte: el gimnasio te espera en Distrito Cromo.")
 elif trainer == "BROCK":
  badge = true
  money += 800
  end_battle()
  save_game()
  say("BROCK\n¡Tu vínculo con tus Pokémon es fuerte! Recibes la MEDALLA CIRCUITO y ₽800. Completaste esta primera aventura. Puedes seguir capturando Pokémon. Partida guardada.")
 else:
  money += 25
  end_battle()
  toast("Victoria · +₽25")

func catch_mon():
 if trainer != "":
  battle_text = "¡No puedes capturar el Pokémon de otro entrenador!"
  return
 if balls <= 0:
  battle_text = "No quedan Poké Balls. Compra más en Distrito Cromo."
  return
 turn_locked = true
 balls -= 1
 battle_text = "Lanzas una Poké Ball…"
 attack_fx = {"start":clock, "kind":"BALL", "own":true, "duration":0.9}
 beep(800,0.2)
 await get_tree().create_timer(0.9).timeout
 if randf() < 0.3 + 0.6 * (1.0 - float(enemy.hp) / enemy.maxhp):
  accept_capture(enemy.duplicate())
  if not int(enemy.id) in captured: captured.append(int(enemy.id))
  battle_text = "¡" + SPECIES[int(enemy.id)][0] + " capturado!"
  await get_tree().create_timer(1.0).timeout
  end_battle()
  toast("Nuevo compañero · " + SPECIES[int(enemy.id)][0])
 else:
  battle_text = "¡Se escapó de la Poké Ball!"
  await get_tree().create_timer(0.7).timeout
  await enemy_turn()

func run_away():
 if trainer != "":
  battle_text = "No puedes huir de un combate de entrenador."
  return
 end_battle()
 toast("Escapaste sin problemas.")

func battle_potion():
 if use_potion(active):
  turn_locked = true
  battle_text = "Usaste una poción. Tu Pokémon recupera hasta 20 PS."
  await get_tree().create_timer(0.7).timeout
  await enemy_turn()

func switch_mon(i: int):
 if i == active or party[i].hp <= 0: return
 active = i
 battle_menu = "main"
 turn_locked = true
 battle_text = "¡Adelante, " + SPECIES[int(party[i].id)][0] + "!"
 await get_tree().create_timer(0.7).timeout
 await enemy_turn()

func end_battle():
 mode = "world"
 turn_locked = false
 attack_fx = {}
 trainer_queue = []
 encounter_grace = 7

func save_game():
 if party.is_empty(): return
 var data = {"version":1,"party":party,"active":active,"zone":zone,"x":pos.x,"y":pos.y,"balls":balls,"potions":potions,"money":money,"rival":rival_done,"badge":badge,"seen":seen,"captured":captured}
 var f = FileAccess.open(SAVE, FileAccess.WRITE)
 if not f:
  toast("No se pudo guardar la partida.")
  return
 f.store_string(JSON.stringify(data))
 save_exists = true
 toast("PARTIDA GUARDADA")

func load_game():
 if not FileAccess.file_exists(SAVE): return
 var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 if not data is Dictionary or not data.has("party") or data.party.is_empty():
  toast("No se pudo leer la partida.")
  return
 party = data.party
 active = int(data.active)
 zone = int(data.zone)
 pos = Vector2i(int(data.x),int(data.y))
 visual_pos = Vector2(pos)
 balls = int(data.balls)
 potions = int(data.potions)
 money = int(data.money)
 rival_done = data.rival
 badge = data.badge
 seen = data.seen
 captured = data.captured
 mode = "world"
 toast("¡Bienvenido de vuelta!")

# Drawing is native 2D, with nearest-filtered Pokémon sprites.
func box(r: Rect2, color: Color, border = Color.TRANSPARENT):
 draw_rect(r,color)
 if border.a > 0: draw_rect(r,border,false,2)

func label_at(s: String, p: Vector2, size = 18, color = WHITE):
 draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func paragraph(s: String, p: Vector2, width: float, size = 20, color = INK):
 var yy = p.y
 for para in s.split("\n"):
  var line = ""
  for word in para.split(" "):
   if font.get_string_size(line + word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width:
    label_at(line,Vector2(p.x,yy),size,color)
    yy += size + 8
    line = ""
   line += word + " "
  label_at(line,Vector2(p.x,yy),size,color)
  yy += size + 8

func button(r: Rect2, title: String, a: String, color = INK):
 var hover = r.has_point(get_global_mouse_position())
 box(Rect2(r.position + Vector2(0,4),r.size),Color("0b1b2e"))
 box(r,color.lightened(0.14) if hover else color,BLUE if hover else Color("456077"))
 label_at(title,r.position + Vector2(15,r.size.y / 2 + 6),17,WHITE)
 buttons.append({"rect":r,"action":a})

func sprite(id: int, at: Vector2, size: float, back = false, alpha = 1.0):
 var key = str(id) + ("_back" if back else "")
 draw_texture_rect(sprites[key],Rect2(at,Vector2(size,size)),false,Color(1,1,1,alpha))

func _draw():
 buttons = []
 box(Rect2(0,0,960,720),Color("0c1c30"))
 if mode == "title": draw_title()
 elif mode == "starter": draw_starter()
 elif mode == "battle": draw_battle()
 else:
  draw_world()
  if mode == "dialogue": draw_dialogue()
  elif mode == "party": draw_party()
  elif mode == "bag": draw_bag()
  elif mode == "dex": draw_dex()
  elif mode == "shop": draw_shop()
 if notice_time > 0:
  box(Rect2(240,15,480,40),INK,MINT)
  label_at(notice,Vector2(260,42),17,MINT)

func draw_title():
 for y in range(23):
  for x in range(30):
   var c = Color("112d46") if (x+y)%2 == 0 else Color("102a42")
   box(Rect2(x*32,y*32,32,32),c)
 for i in range(12):
  var p = Vector2(60+i*79,380+sin(clock*0.6+i)*12)
  draw_circle(p,2,Color("4a8d9d"))
 label_at("KANTO / UNA AVENTURA A TODO COLOR",Vector2(80,78),16,MINT)
 label_at("POKÉMON",Vector2(75,190),80,GOLD)
 label_at("AZUL COLOR",Vector2(81,252),45,BLUE)
 label_at("El primer viaje. Una nueva paleta.",Vector2(83,299),21,WHITE)
 draw_circle(Vector2(720,275),124,Color("173e55"))
 draw_circle(Vector2(720,275),108,Color("235366"))
 sprite(7,Vector2(568,113+sin(clock*2)*5),304)
 sprite(1,Vector2(503,356),128)
 sprite(4,Vector2(787,350),128)
 button(Rect2(82,395,320,54),"NUEVA AVENTURA   →","new",Color("256a76"))
 if save_exists: button(Rect2(82,465,320,54),"CONTINUAR PARTIDA","load")
 label_at("EXPLORA · COMBATE · CAPTURA",Vector2(83,568),18,MINT)
 label_at("Flechas / WASD: caminar    E / Z: interactuar",Vector2(83,615),17)
 label_at("P: equipo    B: mochila    F5: guardar    M: sonido",Vector2(83,644),17)
 label_at("RECREACIÓN FAN · DEMO 01 · GODOT 4",Vector2(83,688),12,Color("789aaa"))

func draw_starter():
 label_at("LABORATORIO DEL PROFESOR OAK",Vector2(48,60),16,MINT)
 label_at("Tu aventura empieza aquí.",Vector2(48,115),38)
 label_at("Elige al Pokémon que te acompañará por Kanto.",Vector2(48,157),20,Color("a8bdc6"))
 var ids = [1,4,7]
 var colors = [Color("315f51"),Color("754c42"),Color("305d78")]
 var copy = ["Tranquilo y resistente.","Pequeño, pero valiente.","Un compañero leal."]
 for i in range(3):
  var x = 48+i*298
  box(Rect2(x,204,270,391),colors[i],colors[i].lightened(0.3))
  label_at("0"+str(i+1)+" / "+SPECIES[ids[i]][1],Vector2(x+22,242),15,MINT)
  sprite(ids[i],Vector2(x+23,260+sin(clock*2+i)*4),224)
  label_at(SPECIES[ids[i]][0],Vector2(x+22,493),24)
  label_at(copy[i],Vector2(x+22,524),17)
  button(Rect2(x+18,547,234,40),"ELEGIR  ["+str(i+1)+"]","starter:"+str(ids[i]))
 label_at("Cada inicial tiene ventajas distintas. Todos pueden completar la aventura.",Vector2(48,648),18,Color("a8bdc6"))

func draw_world():
 var names = ["NEO PALETA", "CORREDOR DE DATOS", "DISTRITO CROMO"]
 label_at("POKÉMON / NEÓN KANTO",Vector2(32,32),14,MINT)
 label_at(names[zone],Vector2(32,75),30)
 var objective = "Explora la Corredor de Datos, al norte" if not rival_done else ("Desafía a Brock en el gimnasio" if not badge else "Medalla Circuito obtenida · ¡Sigue explorando!")
 label_at(objective,Vector2(414,72),18,GOLD)
 box(Rect2(28,100,904,520),Color("466b52"))
 for y in range(16):
  for x in range(28): draw_tile(x,y,terrain(x,y))
 draw_map_details()
 for b in buildings(): draw_building(b)
 var np = ORIGIN+Vector2(npc_position())*TILE
 draw_person(np,Color("eee3b7") if zone == 0 else (Color("ab79ba") if zone == 1 else Color("dd9c53")),false)
 var p = ORIGIN+visual_pos*TILE
 draw_person(p,Color("e96d65"),true)
 draw_foreground_details()
 if terrain(pos.x,pos.y) == "grass":
  for i in range(4):
   draw_line(p+Vector2(i*8,31),p+Vector2(i*8+3,24),Color("3b9361"),3)
 label_at("E · hablar / entrar",Vector2(38,648),16,Color("adc5c5"))
 label_at("₽"+str(money)+"    ● "+str(balls)+" Balls",Vector2(38,681),17,GOLD)
 button(Rect2(284,641,140,44),"EQUIPO [P]","party")
 button(Rect2(436,641,145,44),"MOCHILA [B]","bag")
 button(Rect2(593,641,140,44),"POKÉDEX","dex")
 button(Rect2(745,641,180,44),"GUARDAR [F5]","save")

func pixel_rect(p: Vector2, x: float, y: float, w: float, h: float, c: Color):
 box(Rect2(p+Vector2(x,y),Vector2(w,h)),c)

func draw_tile(x: int,y: int,kind: String):
 var p = ORIGIN+Vector2(x,y)*TILE
 var seed_value = (x*73+y*37)%101
 box(Rect2(p,Vector2(32,32)),Color("92bd79") if seed_value%3 else Color("96c17c"))
 if kind == "path":
  pixel_rect(p,0,0,32,32,Color("e6ce99"))
  for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if terrain(x+dir.x,y+dir.y) != "path":
    if dir == Vector2i.LEFT:
     pixel_rect(p,0,0,3,32,Color("b6b77d"))
     pixel_rect(p,3,0,2,32,Color("f2dfae"))
    elif dir == Vector2i.RIGHT:
     pixel_rect(p,29,0,3,32,Color("b6b77d"))
     pixel_rect(p,27,0,2,32,Color("cbb384"))
    elif dir == Vector2i.UP:
     pixel_rect(p,0,0,32,3,Color("a9af72"))
     pixel_rect(p,0,3,32,2,Color("f2dfae"))
    else: pixel_rect(p,0,29,32,3,Color("ceb687"))
  for i in range(3):
   var xx = 6+(seed_value+i*11)%21
   var yy = 6+(seed_value*3+i*7)%21
   pixel_rect(p,xx,yy,3,2,Color("c9b084"))
   pixel_rect(p,xx,yy-1,2,1,Color("f4e3b9"))
 elif kind == "water":
  pixel_rect(p,0,0,32,32,Color("479eb8"))
  pixel_rect(p,0,2,32,12,Color("50acc0"))
  for i in range(2):
   var xx = int(x*9+clock*9+i*11)%23
   var yy = 7+i*16
   pixel_rect(p,xx,yy,8,2,Color("8ed5d3"))
   pixel_rect(p,xx+3,yy+2,10,1,Color("72c5cb"))
  if terrain(x,y-1) != "water":
   pixel_rect(p,0,0,32,4,Color("d4cc94"))
   pixel_rect(p,0,4,32,3,Color("a2d4bb"))
   pixel_rect(p,2,7,12,2,Color("c7e6d0"))
  if terrain(x,y+1) != "water":
   pixel_rect(p,0,27,32,5,Color("cbd09a"))
   pixel_rect(p,0,25,32,2,Color("97ccad"))
  if terrain(x-1,y) != "water":
   pixel_rect(p,0,0,4,32,Color("c7ce93"))
   pixel_rect(p,4,3,2,24,Color("95d5c1"))
  if terrain(x+1,y) != "water":
   pixel_rect(p,28,0,4,32,Color("b2be85"))
   pixel_rect(p,26,3,2,24,Color("85c8b9"))
 elif kind == "tree":
  draw_tree(p,x+y)
 elif kind == "grass":
  pixel_rect(p,0,0,32,32,Color("6aa064"))
  for j in range(3):
   for i in range(4):
    var a = p+Vector2(3+i*8+(j%2)*2,9+j*10)
    var sway = int(sin(clock*1.7+x*0.4+y*0.3)*1.4)
    pixel_rect(a,-2,0,6,3,Color("4c8355"))
    draw_line(a+Vector2(0,1),a+Vector2(-3+sway,-6),Color("a0ce79"),2)
    draw_line(a+Vector2(1,1),a+Vector2(3+sway,-8),Color("b4db82"),2)
    draw_line(a+Vector2(0,1),a+Vector2(sway,-5),Color("3e7951"),2)
 elif kind == "flowers":
  for i in range(3):
   var a = p+Vector2(5+i*10,8+(x+y+i)%3*7)
   pixel_rect(a,1,3,2,7,Color("4f8957"))
   pixel_rect(a,-2,6,3,2,Color("669a5d"))
   var petal = Color("e989a1") if (x+y+i)%2 else Color("f0ce72")
   pixel_rect(a,-2,0,7,3,petal)
   pixel_rect(a,0,-2,3,7,petal.lightened(0.12))
   pixel_rect(a,0,0,3,2,Color("fff0c1"))
 else:
  for i in range(2):
   var xx = 3+(seed_value+i*13)%25
   var yy = 4+(seed_value*7+i*11)%23
   pixel_rect(p,xx,yy,2,3,Color("7fac69"))
   pixel_rect(p,xx+3,yy-2,2,4,Color("a6c985"))
  if seed_value%11 == 0:
   pixel_rect(p,17,20,3,2,Color("d6da9e"))

func draw_tree(p: Vector2,variation: int):
 ellipse_shape(p+Vector2(18,28),Vector2(15,5),Color(0.16,0.30,0.22,0.23))
 pixel_rect(p,12,19,9,13,Color("695c43"))
 pixel_rect(p,14,20,3,11,Color("a18556"))
 pixel_rect(p,3,11,27,14,Color("285443"))
 pixel_rect(p,0,10,29,10,Color("356b4c"))
 pixel_rect(p,4,2,24,18,Color("408154"))
 pixel_rect(p,8,-2,16,18,Color("4d925c"))
 pixel_rect(p,11,-4,10,6,Color("579e64"))
 pixel_rect(p,5,6,8,6,Color("69ac6a"))
 pixel_rect(p,11,0,8,5,Color("78b874"))
 pixel_rect(p,15,8,8,5,Color("599b5d"))
 pixel_rect(p,4,17,9,4,Color("438754"))
 pixel_rect(p,19,16,8,4,Color("2d6548"))
 pixel_rect(p,9,14,5,2,Color("7fb670"))
 if variation%7 == 0:
  pixel_rect(p,21,10,3,3,Color("dbb86b"))

func draw_map_details():
 # Short garden fences, stepping stones, signs and village furniture.
 if zone == 0:
  for x in [4,5,6,8,9]: draw_fence(ORIGIN+Vector2(x*32,7*32+17))
  for x in range(19,25): draw_fence(ORIGIN+Vector2(x*32,14*32+8))
  draw_sign(ORIGIN+Vector2(11*32,2*32),"↑ CORREDOR DE DATOS")
  draw_sign(ORIGIN+Vector2(16*32,11*32),"PALETA")
  draw_planter(ORIGIN+Vector2(4*32-8,7*32-12))
  draw_planter(ORIGIN+Vector2(10*32-12,7*32-12))
  draw_mailbox(ORIGIN+Vector2(10*32+8,6*32+3))
 elif zone == 1:
  draw_sign(ORIGIN+Vector2(11*32,13*32),"CORREDOR DE DATOS")
  draw_sign(ORIGIN+Vector2(15*32,2*32),"↑ VERDE")
  for x in [5,8,20,23]:
   var p = ORIGIN+Vector2(x*32, (10 if x<12 else 6)*32)
   pixel_rect(p,3,16,25,9,Color("658d69"))
   pixel_rect(p,5,10,21,12,Color("929e85"))
   pixel_rect(p,9,6,13,8,Color("b9ba99"))
   pixel_rect(p,8,10,6,3,Color("d3cfab"))
  # A butterfly follows a small loop beside the pond.
  var q = ORIGIN+Vector2(22*32+sin(clock*0.8)*22,6*32+cos(clock)*9)
  var wing = 4 if sin(clock*9)>0 else 2
  pixel_rect(q,-wing,-2,wing,4,Color("f6d879"))
  pixel_rect(q,2,-2,wing,4,Color("f0a36c"))
  pixel_rect(q,0,-2,2,6,INK)
 else:
  for x in range(3,10):
   for y in range(8,10):
    var p = ORIGIN+Vector2(x,y)*32
    pixel_rect(p,1,1,30,30,Color("cad0b5"))
    pixel_rect(p,2,2,28,1,Color("e4e2c8"))
    pixel_rect(p,2,29,28,2,Color("a5b29c"))
  draw_sign(ORIGIN+Vector2(11*32,12*32),"DISTRITO CROMO")
  draw_planter(ORIGIN+Vector2(3*32,9*32))
  draw_planter(ORIGIN+Vector2(9*32,9*32))
  draw_lamp(ORIGIN+Vector2(16*32,9*32))
  draw_lamp(ORIGIN+Vector2(11*32,5*32))
  draw_bench(ORIGIN+Vector2(20*32,12*32))

func draw_foreground_details():
 if walking and mode == "world" and terrain(pos.x,pos.y)=="path":
  var p = ORIGIN+visual_pos*32
  var f = fmod(walk_phase,1.0)
  pixel_rect(p,10-f*7,30+f*3,3-f*2,2,Color(0.94,0.86,0.68,(1-f)*0.7))
  pixel_rect(p,23+f*4,29+f*4,2,2,Color(0.94,0.86,0.68,(1-f)*0.6))

func draw_fence(p: Vector2):
 pixel_rect(p,0,9,32,4,Color("9a8763"))
 pixel_rect(p,0,7,32,3,Color("e0cc9a"))
 for x in [3,20]:
  pixel_rect(p,x,3,7,20,Color("aa9066"))
  pixel_rect(p,x,2,5,19,Color("eee0b2"))
  pixel_rect(p,x+1,0,3,2,Color("f5e8c1"))

func draw_sign(p: Vector2,text: String):
 pixel_rect(p,12,15,5,15,Color("8c7956"))
 pixel_rect(p,0,3,31,19,Color("6b684d"))
 pixel_rect(p,1,2,29,17,Color("e7d4a1"))
 pixel_rect(p,3,5,25,1,Color("fbebbf"))
 label_at(text,p+Vector2(3,15),7,Color("635c45"))

func draw_planter(p: Vector2):
 pixel_rect(p,4,15,23,10,Color("af785a"))
 pixel_rect(p,2,13,27,5,Color("d39a71"))
 for i in range(4):
  pixel_rect(p,4+i*6,7,5,8,Color("4e8755"))
  pixel_rect(p,4+i*6,5+(i%2)*2,5,4,Color("ed9ba3") if i%2 else GOLD)

func draw_mailbox(p: Vector2):
 pixel_rect(p,7,18,4,12,Color("877b5b"))
 pixel_rect(p,0,6,19,13,Color("528fa2"))
 pixel_rect(p,3,3,13,5,Color("76b5c2"))
 pixel_rect(p,2,11,12,2,Color("2d627a"))
 pixel_rect(p,17,3,3,10,Color("e77b6e"))

func draw_lamp(p: Vector2):
 pixel_rect(p,12,2,5,31,Color("465e61"))
 pixel_rect(p,8,29,13,4,Color("465e61"))
 pixel_rect(p,7,-7,15,15,Color("435966"))
 pixel_rect(p,10,-4,9,9,Color("f6df9c"))
 pixel_rect(p,8,-10,13,3,Color("617976"))
 pixel_rect(p,13,-13,3,4,Color("617976"))

func draw_bench(p: Vector2):
 for yy in [2,8,17]:
  pixel_rect(p,0,yy,50,5,Color("9c7858"))
  pixel_rect(p,1,yy,48,2,Color("d6ac76"))
 for xx in [6,40]: pixel_rect(p,xx,21,4,7,Color("52665a"))

func draw_building(b: Array):
 var r: Rect2i = b[0]
 var p = ORIGIN+Vector2(r.position)*TILE
 var sz = Vector2(r.size)*TILE
 var roof: Color = b[2]
 pixel_rect(p,8,sz.y-4,sz.x,13,Color(0.19,0.29,0.23,0.22))
 pixel_rect(p,5,37,sz.x-10,sz.y-37,Color("bcae8c"))
 pixel_rect(p,8,42,sz.x-16,sz.y-47,Color("eadcb4"))
 pixel_rect(p,8,sz.y-13,sz.x-16,9,Color("c1b598"))
 for yy in range(51,int(sz.y)-15,14):
  pixel_rect(p,8,yy,sz.x-16,1,Color("d5c5a1"))
  for xx in range(12,int(sz.x)-14,28):
   pixel_rect(p,xx+(7 if yy%2 else 0),yy,1,13,Color("dbcca8"))
 # Stepped eaves and staggered roof tiles.
 pixel_rect(p,-3,18,sz.x+6,33,roof.darkened(0.35))
 pixel_rect(p,1,5,sz.x-2,38,roof)
 pixel_rect(p,6,-1,sz.x-12,9,roof.lightened(0.2))
 for row in range(3):
  var yy = 10+row*11
  pixel_rect(p,2,yy+9,sz.x-4,2,roof.darkened(0.17))
  for xx in range(7,int(sz.x)-10,19):
   var offset = 8 if row%2 else 0
   pixel_rect(p,xx+offset,yy,2,9,roof.darkened(0.13))
   pixel_rect(p,xx+offset+3,yy,11,1,roof.lightened(0.16))
 pixel_rect(p,-1,44,sz.x+2,5,Color("73695a"))
 pixel_rect(p,4,49,sz.x-8,4,Color("aea084"))
 # Chimney with a brick cap.
 if b[1] == "CASA":
  pixel_rect(p,sz.x-44,-11,17,29,Color("b48b72"))
  pixel_rect(p,sz.x-47,-14,23,6,Color("d0ab89"))
  pixel_rect(p,sz.x-40,-11,10,2,Color("776553"))
  for yy in [-3,5,13]: pixel_rect(p,sz.x-43,yy,15,1,Color("956f5d"))
 var center = int(r.size.x/2)*32
 pixel_rect(p,center-4,sz.y-43,38,43,Color("b3a27f"))
 pixel_rect(p,center,sz.y-40,30,40,Color("3b5667"))
 pixel_rect(p,center+3,sz.y-37,24,34,Color("5b8090"))
 pixel_rect(p,center+6,sz.y-33,18,16,Color("9bd3d0"))
 pixel_rect(p,center+7,sz.y-31,3,12,Color("d1ece0"))
 pixel_rect(p,center+23,sz.y-13,3,3,GOLD)
 pixel_rect(p,center-5,sz.y-2,40,4,Color("ded6b6"))
 for xx in [20,int(sz.x)-49]:
  pixel_rect(p,xx-3,63,34,32,Color("aa9d81"))
  pixel_rect(p,xx,61,28,28,Color("f6ebc7"))
  pixel_rect(p,xx+3,64,22,21,Color("5c91a0"))
  pixel_rect(p,xx+4,65,20,10,Color("a8d6d0"))
  pixel_rect(p,xx+5,66,3,16,Color("d0e8db"))
  pixel_rect(p,xx+13,64,2,22,WHITE)
  pixel_rect(p,xx-3,89,34,4,Color("f0e3bb"))
 if b[1] == "CENTRO":
  pixel_rect(p,sz.x/2-29,65,58,24,Color("ce6d76"))
  draw_circle(p+Vector2(sz.x/2,77),9,WHITE)
  draw_line(p+Vector2(sz.x/2-9,77),p+Vector2(sz.x/2+9,77),Color("ce6d76"),3)
  draw_circle(p+Vector2(sz.x/2,77),3,WHITE)
 elif b[1] == "GIMNASIO":
  pixel_rect(p,sz.x/2-29,66,58,23,Color("665b82"))
  label_at("GYM",p+Vector2(sz.x/2-18,84),17,GOLD)
 elif b[1] == "LAB. OAK":
  pixel_rect(p,sz.x/2-34,64,68,24,Color("657a8d"))
  label_at("LAB. OAK",p+Vector2(sz.x/2-28,81),12,WHITE)

func draw_person(p: Vector2,c: Color,player: bool):
 # Pixel sprite built on a 16 × 20 grid. Alternating feet/arms follow distance.
 var moving = walking and player and mode == "world"
 var frame = int(walk_phase)%4 if moving else 0
 var foot = 2 if frame==1 else (-2 if frame==3 else 0)
 var bounce = 1 if frame in [1,3] else 0
 var base = p+Vector2(0,-8-bounce)
 var dir = facing if player else Vector2i.DOWN
 var skin = Color("f2c897")
 var shade = Color("ce976e")
 var hair = Color("4c4948")
 var outline = Color("344553")
 var pants = Color("54738b")
 ellipse_shape(p+Vector2(16,29),Vector2(10,3),Color(0.14,0.25,0.24,0.25))
 # Legs are separately animated, so each planted foot holds its position.
 pixel_rect(base,8,29+foot,6,8,outline)
 pixel_rect(base,18,29-foot,6,8,outline)
 pixel_rect(base,8,28+foot,6,5,pants)
 pixel_rect(base,18,28-foot,6,5,pants.lightened(0.1))
 pixel_rect(base,7,35+foot,8,3,Color("efe4c8"))
 pixel_rect(base,18,35-foot,8,3,Color("efe4c8"))
 pixel_rect(base,7,20,19,12,outline)
 pixel_rect(base,9,20,15,11,c)
 pixel_rect(base,10,21,4,8,c.lightened(0.22))
 if dir == Vector2i.DOWN or dir == Vector2i.UP:
  pixel_rect(base,4,21-foot,5,9,c.darkened(0.12))
  pixel_rect(base,24,21+foot,5,9,c.darkened(0.12))
  pixel_rect(base,4,28-foot,5,4,skin)
  pixel_rect(base,24,28+foot,5,4,skin)
 else:
  var arm_x = 19 if dir==Vector2i.RIGHT else 7
  pixel_rect(base,arm_x,22+foot,6,9,c.darkened(0.15))
  pixel_rect(base,arm_x,28+foot,6,4,skin)
 # Neck, face and cap.
 pixel_rect(base,13,17,8,5,shade)
 pixel_rect(base,7,5,19,15,hair)
 pixel_rect(base,9,8,15,12,skin)
 pixel_rect(base,8,16,4,3,shade)
 if dir == Vector2i.UP:
  pixel_rect(base,8,9,17,11,hair)
  pixel_rect(base,10,18,13,3,hair)
 else:
  if dir == Vector2i.DOWN:
   pixel_rect(base,11,13,2,3,outline)
   pixel_rect(base,20,13,2,3,outline)
   pixel_rect(base,15,18,5,1,shade)
  else:
   var eye_x = 21 if dir==Vector2i.RIGHT else 10
   pixel_rect(base,eye_x,12,2,3,outline)
   pixel_rect(base,24 if dir==Vector2i.RIGHT else 6,14,3,3,skin)
 var hat = c if player else Color("e5dec2")
 pixel_rect(base,6,5,21,5,hat.darkened(0.12))
 pixel_rect(base,9,1,15,7,hat)
 pixel_rect(base,12,0,10,3,hat.lightened(0.15))
 if player:
  pixel_rect(base,14,3,10,4,Color("f9edcc"))
  if dir == Vector2i.RIGHT: pixel_rect(base,23,7,6,3,hat.darkened(0.18))
  elif dir == Vector2i.LEFT: pixel_rect(base,3,7,6,3,hat.darkened(0.18))
  elif dir == Vector2i.DOWN: pixel_rect(base,12,8,14,3,hat.darkened(0.18))
  # Backpack rotates with the character.
  if dir == Vector2i.UP:
   pixel_rect(base,10,22,14,10,Color("a37a47"))
   pixel_rect(base,11,21,12,8,Color("dfbd6e"))
   pixel_rect(base,13,24,8,2,Color("f4dca0"))
  elif dir != Vector2i.DOWN:
   var bx = 5 if dir==Vector2i.RIGHT else 22
   pixel_rect(base,bx,21,6,11,Color("a37a47"))
   pixel_rect(base,bx,21,5,8,Color("dfbd6e"))
  else: pixel_rect(base,8,22,3,8,Color("dfbd6e"))

func ellipse_shape(center: Vector2, radius: Vector2,c: Color):
 var points = PackedVector2Array()
 for i in range(32):
  var a = TAU*i/32
  points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
 draw_colored_polygon(points,c)

func draw_dialogue():
 buttons = []
 box(Rect2(50,429,860,181),WHITE,INK)
 paragraph(message,Vector2(74,463),800,19)
 button(Rect2(711,550,175,40),"CONTINUAR  [E]","continue")

func overlay(title: String,sub: String):
 buttons = []
 box(Rect2(0,0,960,720),Color(0.02,0.06,0.11,0.86))
 box(Rect2(40,40,880,634),Color("152e43"),Color("446577"))
 label_at(title,Vector2(70,92),32)
 label_at(sub,Vector2(70,128),17,MINT)
 button(Rect2(739,605,150,42),"VOLVER [Esc]","world")

func draw_party():
 overlay("TU EQUIPO",str(party.size())+" / 6 compañeros · pulsa un Pokémon para ponerlo al frente")
 for i in range(party.size()):
  var p = party[i]
  var x = 68+(i%2)*414
  var y = 153+int(i/2)*140
  box(Rect2(x,y,394,124),Color("254759"),MINT if i == active else Color("426171"))
  sprite(int(p.id),Vector2(x-2,y+5),106)
  label_at(SPECIES[int(p.id)][0],Vector2(x+108,y+30),21)
  label_at("Nv. "+str(p.level)+"  ·  "+SPECIES[int(p.id)][1],Vector2(x+108,y+54),14,MINT)
  hp_bar(Rect2(x+108,y+66,258,7),p)
  label_at(str(p.hp)+" / "+str(p.maxhp)+" PS",Vector2(x+108,y+93),14)
  button(Rect2(x+243,y+87,132,28),"LÍDER" if i == active else "ELEGIR","lead:"+str(i))

func draw_bag():
 overlay("MOCHILA","₽"+str(money)+"  ·  "+str(balls)+" Poké Balls  ·  "+str(potions)+" pociones")
 label_at("POCIONES",Vector2(72,181),20,GOLD)
 label_at("Recuperan hasta 20 PS. Elige a quién curar.",Vector2(72,213),18)
 for i in range(party.size()):
  var p = party[i]
  var y = 239+i*54
  button(Rect2(72,y,790,43),SPECIES[int(p.id)][0]+"    "+str(p.hp)+" / "+str(p.maxhp)+" PS     ·     USAR POCIÓN","potion:"+str(i))

func draw_dex():
 overlay("POKÉDEX",str(seen.size())+" vistos  /  "+str(captured.size())+" capturados · 10 especies en esta demo")
 var ids = SPECIES.keys()
 for i in range(ids.size()):
  var id = ids[i]
  var x = 70+(i%5)*165
  var y = 164+int(i/5)*201
  box(Rect2(x,y,153,183),Color("254759"))
  if id in seen:
   sprite(id,Vector2(x+13,y+5),128)
   label_at(SPECIES[id][0],Vector2(x+10,y+143),16)
  else: label_at("?",Vector2(x+59,y+91),50,Color("6a8896"))
  label_at("#%03d" % id + ("  ●" if id in captured else ""),Vector2(x+12,y+168),14,MINT)

func draw_shop():
 overlay("TIENDA POKÉMON","Suministros para el viaje · saldo ₽"+str(money))
 paragraph("Las Poké Balls te permiten capturar Pokémon salvajes. Debilítalos primero para aumentar tus posibilidades.",Vector2(74,200),770,21,WHITE)
 button(Rect2(74,300,790,66),"POKÉ BALL      ₽100      ·      Tienes "+str(balls),"buy_ball")
 button(Rect2(74,386,790,66),"POCIÓN            ₽150      ·      Tienes "+str(potions),"buy_potion")
 label_at("El Centro Pokémon cura gratis a todo tu equipo.",Vector2(74,517),20,MINT)

func hp_bar(r: Rect2,p: Dictionary):
 box(r,Color("152f3c"))
 var ratio = float(p.hp)/p.maxhp
 box(Rect2(r.position,Vector2(r.size.x*ratio,r.size.y)),MINT if ratio > 0.5 else (GOLD if ratio > 0.2 else Color("ef7a75")))

func status_panel(r: Rect2,p: Dictionary,own: bool):
 box(Rect2(r.position+Vector2(0,5),r.size),Color("819787"))
 box(r,WHITE,INK)
 label_at(SPECIES[int(p.id)][0],r.position+Vector2(16,29),23,INK)
 label_at("Nv. "+str(p.level),r.position+Vector2(r.size.x-79,28),19,INK)
 label_at("PS",r.position+Vector2(17,55),14,INK)
 var visual_hp = p.duplicate()
 visual_hp.hp = player_hp_visual if own else enemy_hp_visual
 hp_bar(Rect2(r.position+Vector2(47,43),Vector2(r.size.x-64,10)),visual_hp)
 if own:
  label_at(str(p.hp)+" / "+str(p.maxhp),r.position+Vector2(r.size.x-94,80),17,INK)
  box(Rect2(r.position+Vector2(17,94),Vector2(r.size.x-34,4)),Color("c7d2c5"))
  box(Rect2(r.position+Vector2(17,94),Vector2((r.size.x-34)*float(p.xp)/(p.level*12),4)),BLUE)

func draw_battle():
 box(Rect2(0,0,960,490),Color("b8dace"))
 for i in range(15):
  box(Rect2(0,i*32,960,16),Color(0.5,0.7,0.62,0.055))
 box(Rect2(0,0,960,55),INK)
 label_at("COMBATE / "+("POKÉMON SALVAJE" if trainer == "" else trainer),Vector2(32,35),17,MINT)
 ellipse_shape(Vector2(713,285),Vector2(177,43),Color("8bb995"))
 ellipse_shape(Vector2(713,280),Vector2(155,32),Color("a0cda3"))
 ellipse_shape(Vector2(239,461),Vector2(193,37),Color("8bb995"))
 draw_battle_pokemon()
 draw_attack_effects()
 status_panel(Rect2(43,93,379,78),enemy,false)
 status_panel(Rect2(519,345,398,110),party[active],true)
 box(Rect2(0,490,960,230),Color("10283b"))
 box(Rect2(24,513,462,180),WHITE,Color("526d78"))
 paragraph(battle_text,Vector2(45,550),413,21)
 if turn_locked:
  label_at("●  ●  ●",Vector2(659,605),24,MINT)
  return
 if battle_menu == "moves":
  var special = MOVES[SPECIES[int(party[active].id)][1]]
  button(Rect2(510,513,425,49),"1  PLACAJE  ·  NORMAL","attack")
  button(Rect2(510,575,425,49),"2  "+special[0]+"  ·  "+special[1],"special",Color("256a76"))
  button(Rect2(510,637,425,49),"3  VOLVER","battle_back")
 elif battle_menu == "switch":
  for i in range(party.size()):
   button(Rect2(510,507+i*28,425,26),str(i+1)+"  "+SPECIES[int(party[i].id)][0]+"  "+str(party[i].hp)+" PS","switch:"+str(i))
  label_at("Esc: volver",Vector2(789,708),13,MINT)
 else:
  button(Rect2(510,513,205,49),"1  LUCHAR","fight",Color("256a76"))
  button(Rect2(730,513,205,49),"2  BALL ×"+str(balls),"catch")
  button(Rect2(510,575,205,49),"3  POCIÓN ×"+str(potions),"battle_potion")
  button(Rect2(730,575,205,49),"4  EQUIPO","switch")
  button(Rect2(510,637,425,49),"5  HUIR","run")

func run_smoke_tests():
 reset_game()
 action("starter:7")
 assert(party.size() == 1 and party[0].id == 7)
 mode = "world"
 assert(not walkable(Vector2i(4,4)))
 assert(not walkable(Vector2i(3,11)))
 assert(walkable(Vector2i(13,8)))
 assert(type_factor("AGUA","ROCA") == 2.0)
 assert(type_factor("ELÉCTRICO","ROCA") == 0.0)
 party[0].hp -= 5
 assert(use_potion(0) and party[0].hp == party[0].maxhp and potions == 4)
 zone = 1
 pos = Vector2i(13,0)
 move_player(Vector2i.UP)
 assert(zone == 2 and pos.y == 14)
 zone = 0
 pos = Vector2i(13,12)
 visual_pos = Vector2(pos)
 start_battle(mon(16,3))
 assert(mode == "battle")
 action("run")
 assert(mode == "world")
 var original_save = FileAccess.get_file_as_string(SAVE) if FileAccess.file_exists(SAVE) else ""
 save_game()
 money = 0
 load_game()
 assert(money == 500 and party.size() == 1)
 if original_save != "":
  var f = FileAccess.open(SAVE,FileAccess.WRITE)
  f.store_string(original_save)
 else: DirAccess.remove_absolute(SAVE)
 notice_time = 0
 await get_tree().process_frame
 await get_tree().process_frame
 if DisplayServer.get_name() != "headless":
  get_viewport().get_texture().get_image().save_png("res://screenshot-world.png")
 start_battle(mon(25,5))
 await get_tree().process_frame
 await get_tree().process_frame
 if DisplayServer.get_name() != "headless":
  get_viewport().get_texture().get_image().save_png("res://screenshot-battle.png")
 print("SMOKE PASS: starter, collisions, type chart, healing, map transition, battle, escape, save/load")
 get_tree().quit()

func run_integration_tests():
 reset_game()
 action("starter:7")
 mode = "world"
 party[0] = mon(7,20)
 start_battle(mon(19,3))
 await player_attack(false)
 assert(mode == "world" and money == 525)
 start_battle(mon(25,5))
 enemy.hp = 1
 seed(8)
 await catch_mon()
 if mode == "battle":
  enemy.hp = 1
  await catch_mon()
 assert(party.size() == 2 and 25 in captured and balls < 10)
 start_battle(mon(1,3),"AZUL")
 for attempt in range(8):
  if mode != "battle": break
  await player_attack(false)
 assert(rival_done and mode == "dialogue")
 mode = "world"
 trainer_queue = [mon(95,3)]
 start_battle(mon(74,3),"TEST_TRAINER")
 await player_attack(true)
 assert(mode == "battle" and enemy.id == 95)
 await player_attack(true)
 assert(mode == "world")
 party = [mon(7,5)]
 active = 0
 party[0].hp = 1
 start_battle(mon(25,50))
 await enemy_turn()
 assert(mode == "dialogue" and party[0].hp == party[0].maxhp and zone == 0)
 print("INTEGRATION PASS: attack, victory, capture, rival reward, trainer queue, defeat recovery")
 get_tree().quit()

func fx_progress() -> float:
 if attack_fx.is_empty(): return 2.0
 return (clock-attack_fx.start)/attack_fx.duration

func draw_battle_pokemon():
 var t = fx_progress()
 var enemy_offset = Vector2(0,sin(clock*2.5)*3)
 var own_offset = Vector2(0,sin(clock*2.0)*2)
 var enemy_alpha = 1.0
 var own_alpha = 1.0
 if t>=0 and t<=1:
  var own = attack_fx.own
  if attack_fx.kind == "NORMAL":
   var lunge = sin(clampf(t/0.42,0,1)*PI)*35
   if own: own_offset += Vector2(lunge,-lunge*0.35)
   else: enemy_offset += Vector2(-lunge,lunge*0.35)
  elif attack_fx.kind != "BALL":
   var charge = sin(clampf(t/0.35,0,1)*PI)*8
   if own: own_offset.x -= charge
   else: enemy_offset.x += charge
  if t>0.42 and t<0.86 and attack_fx.kind != "BALL":
   var shake = sin(t*90)*7*(1-t)
   var blink = 0.38 if int(t*22)%2 else 1.0
   if own:
    enemy_offset.x += shake
    enemy_alpha = blink
   else:
    own_offset.x += shake
    own_alpha = blink
 sprite(int(enemy.id),Vector2(569,83)+enemy_offset,280,false,enemy_alpha)
 sprite(int(party[active].id),Vector2(65,224)+own_offset,320,true,own_alpha)

func draw_attack_effects():
 var t = fx_progress()
 if t<0 or t>1: return
 var own = attack_fx.own
 var kind = attack_fx.kind
 var source = Vector2(260,343) if own else Vector2(706,201)
 var target = Vector2(713,216) if own else Vector2(235,365)
 var travel = clampf(t/0.48,0,1)
 var center = source.lerp(target,travel)
 var impact = clampf((t-0.43)/0.57,0,1)
 var fade = 1.0-impact
 var color = {"AGUA":Color("a7f2f0"),"FUEGO":Color("ffb361"),"PLANTA":Color("b5e381"),"ELÉCTRICO":Color("fff2a2"),"ROCA":Color("c5b499"),"BICHO":Color("c1dc80"),"NORMAL":WHITE,"BALL":WHITE}.get(kind,WHITE)
 if kind == "BALL":
  center = source.lerp(target,travel)+Vector2(0,-sin(travel*PI)*125)
  draw_circle(center+Vector2(3,5),12,Color(0.08,0.18,0.22,0.2))
  draw_circle(center,12,INK)
  draw_circle(center,10,WHITE)
  draw_arc(center,0.1,0,PI,2,WHITE)
  for yy in range(-9,0):
   var ww = sqrt(100-yy*yy)
   draw_line(center+Vector2(-ww,yy),center+Vector2(ww,yy),Color("ee7e77"),1)
  draw_line(center+Vector2(-10,0),center+Vector2(10,0),INK,3)
  draw_circle(center,4,INK)
  draw_circle(center,2,WHITE)
  if t>0.5: draw_arc(target,20+impact*42,0,TAU,32,Color(1,0.9,0.62,fade),3)
  return
 if kind == "NORMAL":
  if t<0.5:
   for i in range(5):
    var q = source.lerp(target,travel)+Vector2(-i*17,i*5)
    draw_line(q-Vector2(28,-8),q,Color(1,1,0.91,0.65-i*0.09),3)
 elif kind == "AGUA":
  if t<0.64:
   for i in range(8):
    var f = clampf(travel-i*0.05,0,1)
    var q = source.lerp(target,f)+Vector2(sin(t*19+i)*8,cos(t*17+i)*13)
    var radius = 5+i%3*3
    draw_circle(q,radius,Color("58bbd8"))
    draw_arc(q,radius,0,TAU,16,Color("c4faf2"),2)
    pixel_rect(q,-3,-4,3,3,WHITE)
 elif kind == "FUEGO":
  if t<0.65:
   for i in range(10):
    var q = source.lerp(target,clampf(travel-i*0.027,0,1))+Vector2(sin(i*3+t*20)*7,cos(i*2+t*13)*8)
    var size = 14-i*0.7
    pixel_rect(q,-size/2,-size/2,size,size,Color("e16a53"))
    pixel_rect(q,-size/3,-size/3,size*0.67,size*0.67,Color("ffb665"))
    pixel_rect(q,-2,-4,5,7,Color("ffe6a0"))
 elif kind == "PLANTA":
  if t<0.65:
   for i in range(7):
    var q = source.lerp(target,clampf(travel-i*0.055,0,1))+Vector2(sin(i*2+t*17)*15,cos(i*2+t*17)*20)
    var pts = PackedVector2Array([q+Vector2(-11,4),q+Vector2(-4,-7),q+Vector2(11,-4),q+Vector2(4,7)])
    draw_colored_polygon(pts,Color("6cab66"))
    draw_line(q+Vector2(-7,3),q+Vector2(7,-3),Color("d1ee96"),2)
 elif kind == "ELÉCTRICO":
  if t>0.12 and t<0.75:
   var previous = source
   for i in range(1,12):
    var q = source.lerp(target,float(i)/11)
    if i<11: q += Vector2(sin(i*5+int(t*20))*10,cos(i*7+int(t*20))*24)
    draw_line(previous,q,Color("e7b35c"),8)
    draw_line(previous,q,Color("fff3a1"),4)
    draw_line(previous,q,WHITE,1)
    previous=q
 elif kind == "ROCA":
  if t<0.65:
   for i in range(4):
    var f = clampf(travel-i*0.065,0,1)
    var q = source.lerp(target,f)+Vector2(i*9-15,-sin(f*PI)*95+i*7)
    pixel_rect(q,-9,-6,18,15,Color("7a7b6d"))
    pixel_rect(q,-7,-10,14,15,Color("b2ab8f"))
    pixel_rect(q,-5,-9,7,5,Color("e0d1ae"))
 else:
  if t<0.6:
   for i in range(5):
    var q = source.lerp(target,clampf(travel-i*0.045,0,1))
    draw_line(q-Vector2(15,-5),q+Vector2(5,-2),color,3)
 if t>0.43:
  # Pixel sparks and a brief expanding impact ring.
  for i in range(12):
   var angle = TAU*i/12+t*1.5
   var radius = 10+impact*(36+i%3*12)
   var q = target+Vector2(cos(angle),sin(angle))*radius
   var c = color
   c.a = fade
   pixel_rect(q,-2,-2,4+i%2*2,4+i%2*2,c)
  if impact<0.5:
   draw_arc(target,10+impact*55,0,TAU,16,Color(color.r,color.g,color.b,1-impact*2),3)
   draw_line(target-Vector2(0,20*fade),target+Vector2(0,20*fade),Color(1,1,0.94,fade),4)
   draw_line(target-Vector2(20*fade,0),target+Vector2(20*fade,0),Color(1,1,0.94,fade),4)

func evolve_after_victory():
 pass

func accept_capture(p: Dictionary):
 party.append(p)
