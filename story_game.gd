extends "res://neon_city.gd"

const STORY_ORIGIN = Vector2(48,144)
const CORE_CELLS = [Vector2i(6,3),Vector2i(14,7),Vector2i(22,3)]
const RELAY_CELL = Vector2i(20,5)
const ARCHIVE_CELL = Vector2i(19,5)
const INTRO_SHOTS = [
 {"phase":0,"seconds":8.0,"title":"DESPUÉS DEL ÚLTIMO BOSQUE","voice":"MARA","text":"Cuando el cielo se volvió ceniza, NEXUS nos prometió aire. A cambio, dejamos que pusiera precio a cada respiración.","from":Vector2(5,8),"to":Vector2(9,8)},
 {"phase":0,"seconds":8.0,"title":"SECTOR 07 · 2096","voice":"MARA","text":"Mi hermana guardaba semillas en una caja de filtros vacíos. «Algún día», decía, «lloverá algo que podamos beber».","from":Vector2(10,8),"to":Vector2(14,8)},
 {"phase":1,"seconds":7.0,"title":"CUOTA VENCIDA","voice":"NEXUS / AVISO AUTOMÁTICO","text":"Saldo insuficiente. Suministro suspendido. Sector 07: cero habitantes registrados.","from":Vector2(16,8),"to":Vector2(18,8)},
 {"phase":1,"seconds":9.0,"title":"LOS QUE NO FIGURABAN","voice":"MARA","text":"La clínica estaba llena. Lía trabó la compuerta con su brazo mecánico. Mientras la red borraba nuestros nombres, ella sostuvo el aire.","from":Vector2(18,8),"to":Vector2(18,8)},
 {"phase":1,"seconds":7.0,"title":"ÚLTIMA TRANSMISIÓN","voice":"LÍA","text":"Mara… no vuelvas por mí. Lleva las semillas. Prométeme que algo nuestro crecerá fuera de esta ciudad.","from":Vector2(15,8),"to":Vector2(11,8)},
 {"phase":2,"seconds":8.0,"title":"EL ARCHIVO VIVO","voice":"OAK","text":"NEXUS conserva especies extintas dentro de cuerpos reparados. Estos cuatro Pokémon lograron escapar de su red. Como tú, necesitan a alguien.","from":Vector2(14,8),"to":Vector2(17,8)},
 {"phase":2,"seconds":7.0,"title":"UNA VIDA SIN DUEÑO","voice":"OAK","text":"No puedo devolverte lo que perdiste. Pero puedes elegir con quién seguir. Acércate, Mara. Esta decisión es tuya.","from":Vector2(17,8),"to":Vector2(17,8)}
]
var intro_shot = 0
var intro_elapsed = 0.0
var intro_paused = false
var prologue_phase = 0
var story_pos = Vector2i(3,8)
var story_visual = Vector2(3,8)
var rescued_cores: Array = []
var story_step = 0.0
var skip_prompt = false
var prologue_complete = false
var prologue_skipped = false
var records: Array = []
var found_records: Array = []
var selected_record = ""
var story_line = ""
var detail_memory = true

func _ready():
 super._ready()
 records=JSON.parse_string(FileAccess.get_file_as_string("res://assets/story/records.json"))

func reset_game():
 super.reset_game()
 found_records=[]
 selected_record=""
 prologue_complete=false
 prologue_skipped=false
 rescued_cores=[]
 skip_prompt=false

func action(a:String):
 if a=="new" and mode=="title":
  super.action(a)
  if mode=="starter": begin_prologue()
 elif a=="continue" and mode=="dialogue" and after_dialogue=="starter_new":
  super.action(a)
  begin_prologue()
 elif a=="story_pause" and mode=="prologue": intro_paused=not intro_paused
 elif a=="story_skip" and mode=="prologue": finish_prologue(true)
 elif a=="story_resume" and mode=="prologue": skip_prompt=false
 elif a=="story_confirm_skip" and mode=="prologue" and skip_prompt:
  finish_prologue(true)
 elif a=="journal" and mode=="world":
  mode="journal"
  if selected_record=="" and not found_records.is_empty(): selected_record=found_records[0]
 elif a.begins_with("record:") and mode=="journal":
  var id=a.get_slice(":",1)
  if id in found_records: selected_record=id
 elif a=="journal_close" and mode=="journal": mode="world"
 elif a=="detail_tab" and mode=="detail": detail_memory=not detail_memory
 elif a.begins_with("starter:"):
  super.action(a)
  message="OAK / ARCHIVO VIVO\n"+SPECIES[int(party[0].id)][0]+" conserva la memoria de una especie perdida. Ya no es propiedad de NEXUS. Busca registros en la ciudad [E] y reléelos en tu archivo [J]. Te acompañarán 25 Balls y 5 pociones."
 else: super.action(a)

func begin_prologue():
 mode="prologue"
 intro_shot=0
 intro_elapsed=0.0
 intro_paused=false
 prologue_phase=0
 story_pos=Vector2i(3,8)
 story_visual=Vector2(story_pos)
 rescued_cores=[]
 skip_prompt=false
 story_line="LÍA / TU HERMANA\nMara, no mires el contador. Mamá necesita un filtro y solo nos queda aire hasta el amanecer. Ven al dispensador. Si caminamos juntas, gastaré menos."

func finish_prologue(skipped:bool):
 prologue_complete=not skipped
 prologue_skipped=skipped
 skip_prompt=false
 mode="starter"
 notice_time=0

func _process(delta):
 super._process(delta)
 if mode!="prologue": return
 advance_intro(delta)

func advance_intro(delta:float):
 if mode!="prologue" or intro_paused: return
 intro_elapsed+=delta
 while intro_elapsed>=float(INTRO_SHOTS[intro_shot].seconds):
  intro_elapsed-=float(INTRO_SHOTS[intro_shot].seconds)
  intro_shot+=1
  if intro_shot>=INTRO_SHOTS.size():
   finish_prologue(false)
   return
 var shot=INTRO_SHOTS[intro_shot]
 prologue_phase=int(shot.phase)
 var progress=clampf(intro_elapsed/float(shot.seconds),0,1)
 story_visual=shot.from.lerp(shot.to,smoothstep(0.0,1.0,progress))
 story_pos=Vector2i(story_visual)
 facing=Vector2i.RIGHT if shot.to.x>=shot.from.x else Vector2i.LEFT
 walking=shot.from!=shot.to
 story_line=shot.voice+"\n"+shot.text


func story_walkable(cell:Vector2i)->bool:
 if cell.x<1 or cell.x>25 or cell.y<1 or cell.y>10: return false
 if cell.y==5 and cell.x in [7,8,9,16,17]: return false
 return true

func move_story(direction:Vector2i):
 if mode!="prologue" or skip_prompt: return
 facing=direction
 story_step=.14
 if story_walkable(story_pos+direction): story_pos+=direction

func interact_prologue():
 if prologue_phase==0:
  if story_pos.distance_to(RELAY_CELL)>1.5:
   story_line="LÍA\nEl dispensador está al este, junto a la clínica. Camina conmigo. Pulsa E cuando estemos cerca. Todavía podemos llegar antes del corte."
   return
  prologue_phase=1
  story_pos=Vector2i(3,8)
  story_visual=Vector2(story_pos)
  story_line="NEXUS / RECAUDACIÓN\nDeuda impagada. Habitantes registrados: cero.\nLÍA: ¡Hay gente en la clínica! Abre las tres válvulas. Yo sujetaré la compuerta. No pueden borrarnos así."
  beep(110,.35)
 elif prologue_phase==1:
  for i in range(CORE_CELLS.size()):
   if story_pos.distance_to(CORE_CELLS[i])<=1.5 and not i in rescued_cores:
    rescued_cores.append(i)
    beep(440+i*170,.15)
    story_line=["PRIMERA VÁLVULA / PRESIÓN ESTABLE\nLÍA: Ya los oigo respirar. Mamá tenía razón: una ciudad no está vacía mientras alguien cuide de otro.","SEGUNDA VÁLVULA / BYPASS ABIERTO\nLÍA: El seguro está quemado. Si suelto la compuerta, vuelve a cerrarse. Sigue, Mara. No vengas por mí.","TERCERA VÁLVULA / CLÍNICA CONECTADA\nLÍA: Llévate lo que guardaba Oak. Que algo de nosotras llegue a vivir sin pedir permiso."][i]
    if rescued_cores.size()==3:
     prologue_phase=2
     story_pos=Vector2i(3,8)
     story_visual=Vector2(story_pos)
     story_line="OAK / DESPUÉS DEL SILENCIO\nTu hermana mantuvo el aire hasta el final. NEXUS borró su nombre; no a quienes salvó. Estos núcleos guardan vida del mundo anterior. Despierta uno. No vuelvas a caminar sola."
    return
 elif story_pos.distance_to(ARCHIVE_CELL)<=1.5:
  finish_prologue(false)

func _unhandled_input(event):
 if mode=="prologue":
  if event is InputEventKey and event.pressed and not event.echo:
   if event.physical_keycode==KEY_ESCAPE: finish_prologue(true)
   elif event.physical_keycode in [KEY_ENTER,KEY_SPACE]: intro_paused=not intro_paused
   elif event.physical_keycode==KEY_M:
    muted=not muted
    if muted and cry_player: cry_player.stop()
  elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
   for b in buttons:
    if b.rect.has_point(get_global_mouse_position()): action(b.action); return
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_J and mode=="world": action("journal"); return
  if event.physical_keycode in [KEY_J,KEY_ESCAPE] and mode=="journal": mode="world"; return
 super._unhandled_input(event)

func save_game():
 super.save_game()
 if party.is_empty() or not FileAccess.file_exists(SAVE): return
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 data["version"]=5
 data["story"]={"prologue_complete":prologue_complete,"prologue_skipped":prologue_skipped,"found_records":found_records}
 var file=FileAccess.open(SAVE,FileAccess.WRITE)
 if file: file.store_string(JSON.stringify(data))

func load_game():
 super.load_game()
 if mode!="world": return
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 var story=data.get("story",{})
 prologue_complete=story.get("prologue_complete",false)
 prologue_skipped=story.get("prologue_skipped",false)
 found_records=[]
 for id in story.get("found_records",[]):
  if record_by_id(str(id))!={} and not id in found_records: found_records.append(id)
 selected_record=found_records[0] if not found_records.is_empty() else ""

func record_by_id(id:String)->Dictionary:
 for record in records:
  if record.id==id: return record
 return {}

func discover_record(id:String):
 if record_by_id(id).is_empty(): return
 if not id in found_records:
  found_records.append(id)
  beep(550,.13)
 selected_record=id
 mode="journal"

func interact():
 if mode=="world":
  for record in records:
   if int(record.zone)==zone and pos.distance_to(Vector2i(int(record.x),int(record.y)))<=1.5:
    discover_record(record.id)
    return
 super.interact()

func _draw():
 if mode=="prologue":
  buttons=[]
  draw_prologue()
  return
 super._draw()
 if mode=="journal": draw_journal()

func draw_title():
 super.draw_title()
 box(Rect2(56,290,433,45),Color("0b1324"))
 label_at("LA DEUDA DEL AIRE",Vector2(61,316),22,CYAN)
 box(Rect2(55,670,414,30),Color("0b1324"))
 label_at("EDICIÓN 0.5 / ARCHIVOS DE LA EXTINCIÓN",Vector2(60,690),12,Color("8da7bb"))

func draw_world():
 super.draw_world()
 for record in records:
  if int(record.zone)!=zone: continue
  var q=ORIGIN+Vector2(record.x,record.y)*32
  var collected=record.id in found_records
  draw_line(q+Vector2(16,13),q+Vector2(16,28),Color("789aac"),2)
  panel(Rect2(q+Vector2(5,-3),Vector2(23,19)),Color("193548"),CYAN if collected else GOLD)
  for i in range(3): draw_line(q+Vector2(9,2+i*4),q+Vector2(24,2+i*4),CYAN if collected else GOLD,1)
  if not collected: glow(q+Vector2(16,5),14,GOLD,.055)
  if pos.distance_to(Vector2i(record.x,record.y))<=1.5:
   holo_sign(q+Vector2(-12,-26),"E / REGISTRO",GOLD)
 button(Rect2(550,689,186,27),"ARCHIVOS [J] "+str(found_records.size())+"/6","journal")

func draw_journal():
 overlay("ARCHIVOS DE LA EXTINCIÓN",str(found_records.size())+" / "+str(records.size())+" registros recuperados · E junto a una baliza dorada para leer")
 buttons=[]
 for i in range(records.size()):
  var record=records[i]
  var found=record.id in found_records
  if found: button(Rect2(53,141+i*66,274,54),"%02d  " % (i+1)+record.short_title,"record:"+record.id)
  else:
   panel(Rect2(53,141+i*66,274,54),Color("132337"),Color("2e4053"))
   label_at("%02d  SEÑAL DESCONOCIDA" % (i+1),Vector2(65,173+i*66),13,Color("708699"))
 var record=record_by_id(selected_record)
 if record.is_empty():
  paragraph("La ciudad conserva lo que NEXUS intentó borrar. Busca las balizas doradas junto al laboratorio, en el corredor industrial y en Distrito Cromo.",Vector2(366,204),495,22,WHITE)
 else:
  label_at(record.date+" / "+record.author,Vector2(364,164),13,CYAN)
  paragraph(record.title,Vector2(364,207),489,25,WHITE)
  paragraph(record.body,Vector2(364,284),489,19,Color("c1d0dc"))
  label_at("ORIGEN / "+["NEO PALETA","LA BRECHA","DISTRITO CROMO"][int(record.zone)],Vector2(365,580),12,PINK)
 button(Rect2(53,626,847,38),"VOLVER A LA CIUDAD [J / ESC]","journal_close")

func draw_detail():
 var id=dex_selected
 var row=catalog[id]
 overlay(SPECIES[id][0],row.concept+" · "+SPECIES[id][1]+(" · REGISTRADO" if id in captured else " · POR DESCUBRIR"))
 glow(Vector2(259,349),130,CYAN,.04)
 sprite(id,Vector2(66,168+sin(clock*1.5)*3),369)
 label_at("MEMORIA DE LA ESPECIE" if detail_memory else "ARQUITECTURA SINTÉTICA",Vector2(488,165),14,PINK)
 paragraph(row.get("memory",row.description) if detail_memory else row.description,Vector2(488,205),374,19,WHITE)
 var evolution="Forma final de esta familia."
 if EVOLUTIONS.has(id):
  evolution="Evoluciona al nivel "+str(EV_LEVEL[id])+" en "+SPECIES[EVOLUTIONS[id][0]][0]
  if EVOLUTIONS[id].size()>1: evolution+=" o "+SPECIES[EVOLUTIONS[id][1]][0]+". Elige su ruta desde EQUIPO."
 paragraph(evolution,Vector2(488,422),374,17,Color("9dbbd0"))
 button(Rect2(488,504,375,38),"VER "+("DISEÑO" if detail_memory else "MEMORIA"),"detail_tab")
 button(Rect2(488,551,375,38),"ESCUCHAR VOZ SINTÉTICA","cry:"+str(id))
 button(Rect2(488,601,255,37),"VOLVER AL CÓDEX","dex")

func draw_prologue():
 var accent=[CYAN,Color("ff9574"),Color("a9e5b8")][prologue_phase]
 draw_skyline(Rect2(0,0,960,720))
 box(Rect2(0,0,960,720),Color(.01,.02,.045,.82))
 label_at("LA ÚLTIMA SINAPSIS / PRÓLOGO",Vector2(48,40),14,accent)
 label_at(["01  La última cuota","02  Nadie figura aquí","03  Una respiración más"][prologue_phase],Vector2(48,87),32)
 label_at(["2096 / SECTOR 07","2096 / CUOTA DE OXÍGENO","2096 / ARCHIVO OAK"][prologue_phase],Vector2(49,119),13,Color("a5bbc8"))
 panel(Rect2(42,138,877,370),Color("101e30"),accent.darkened(.45))
 for y in range(11):
  for x in range(27):
   var q=STORY_ORIGIN+Vector2(x,y)*32
   var color=Color("1c3144") if prologue_phase!=1 else Color("302b35")
   box(Rect2(q,Vector2(31,31)),color)
   if (x+y)%4==0: draw_line(q+Vector2(8,28),q+Vector2(24,28),Color(accent,.12),1)
 for x in [7,8,9,16,17]:
  var q=STORY_ORIGIN+Vector2(x,5)*32
  panel(Rect2(q-Vector2(0,18),Vector2(31,49)),Color("334558"),Color("61798a"))
  draw_line(q+Vector2(5,-9),q+Vector2(26,-9),accent,2)
  for i in range(4): draw_line(q+Vector2(6,i*6),q+Vector2(24,i*6),Color("142234"),2)
 if prologue_phase==0:
  var center=STORY_ORIGIN+Vector2(RELAY_CELL)*32+Vector2(16,-26)
  draw_line(center,center+Vector2(0,57),Color("637f90"),3)
  for i in range(3): draw_arc(center,26+i*12,clock*.2+i,clock*.2+i+TAU*.83,48,PINK if i==0 else Color(CYAN,.32),2,true)
  draw_circle(center,11,PINK)
  draw_line(center-Vector2(6,0),center+Vector2(6,0),Color("151b31"),3)
  for i in range(7):
   var q=Vector2(87+i*57,184)
   panel(Rect2(q,Vector2(43,44)),Color("183a4b"),CYAN.darkened(.5))
   label_at("0"+str(i),q+Vector2(11,28),16,CYAN)
  draw_story_target(RELAY_CELL,"E / DISPENSADOR",accent)
 elif prologue_phase==1:
  for i in range(24):
   var q=Vector2(62+fmod(i*137+clock*7,826),154+fmod(i*83-clock*29+10000,340))
   draw_line(q,q+Vector2(-3,6),Color(1,.53,.34,.3),1)
  for i in range(CORE_CELLS.size()):
   var q=STORY_ORIGIN+Vector2(CORE_CELLS[i])*32
   panel(Rect2(q-Vector2(24,38),Vector2(80,76)),Color("1c3843"),CYAN if not i in rescued_cores else Color("415364"))
   if not i in rescued_cores:
    sprite([1,4,7][i],q-Vector2(12,28),58,false,.75)
    draw_story_target(CORE_CELLS[i],"E / ABRIR VÁLVULA",CYAN)
   else: label_at("ABIERTA",q+Vector2(-14,8),12,CYAN)
 else:
  var q=STORY_ORIGIN+Vector2(ARCHIVE_CELL)*32
  for i in range(3):
   var p=q+Vector2((i-1)*63,-22)
   panel(Rect2(p-Vector2(22,37),Vector2(51,82)),Color("23414a"),accent.darkened(.4))
   sprite([1,4,7][i],p-Vector2(21,18),49,false,.55+sin(clock*2)*.1)
  draw_story_target(ARCHIVE_CELL,"E / DESPERTAR EL ARCA",accent)
 draw_person(STORY_ORIGIN+story_visual*32,PINK,true)
 panel(Rect2(43,522,875,145),Color("0d1c2f"),accent.darkened(.5))
 paragraph(story_line,Vector2(62,549),831,18,WHITE)
 label_at("WASD / FLECHAS · caminar     E · interactuar"+("     VÁLVULAS "+str(rescued_cores.size())+"/3" if prologue_phase==1 else ""),Vector2(47,697),13,accent)
 button(Rect2(741,678,176,31),"OMITIR [ESC]","story_skip")
 if skip_prompt:
  box(Rect2(0,0,960,720),Color(0,0,0,.75))
  panel(Rect2(194,229,572,230),Color("14263b"),CYAN)
  label_at("¿Omitir el prólogo?",Vector2(223,275),28)
  paragraph("Pasarás a elegir compañero. Tu partida guardada no se reemplaza hasta que guardes la nueva aventura.",Vector2(223,315),512,18,Color("b5c8d6"))
  buttons=[]
  button(Rect2(223,394,241,39),"SEGUIR JUGANDO [E]","story_resume")
  button(Rect2(477,394,259,39),"OMITIR PRÓLOGO","story_confirm_skip")

func draw_story_target(cell:Vector2i,text_value:String,color:Color):
 var q=STORY_ORIGIN+Vector2(cell)*32+Vector2(16,16)
 draw_arc(q,21+sin(clock*3)*2,0,TAU,36,Color(color,.6),1,true)
 var target=cell if prologue_phase==1 else cell+Vector2i(0,1)
 if story_pos.distance_to(cell)<=1.5: holo_sign(q+Vector2(-42,-57),text_value,color)
 else:
  var direction=(Vector2(target)-Vector2(story_pos)).normalized()
  var marker=STORY_ORIGIN+story_visual*32+Vector2(16,16)+direction*26
  draw_line(marker,marker+direction*10,color,3,true)
