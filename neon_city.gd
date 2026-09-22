extends "res://cyber_game.gd"

# District systems are separate from the creature catalogue and classic rules.
const TERMINALS = [Vector2i(11,10),Vector2i(16,6),Vector2i(11,12)]
const MODULES = ["REACTOR", "BLINDAJE", "REGENERADOR"]
const MODULE_INFO = ["Ataques +20%. Sobrecarga genera 10 menos de calor.","Reduce un 25% el daño recibido.","Recupera un 10% de PS después de cada turno enemigo."]
var unlocked_nodes: Array = []
var hacking_sequence: Array = []
var hacking_input: Array = []
var hack_reveal_until = 0.0
var hack_error = ""
var thermal = 0
var overdrive = false
var resolving_enemy = false
var enemy_cycles = 0
var workshop_index = 0
var cyber_attack_boost = false

func _ready():
 super._ready()
 if "--city-test" in OS.get_cmdline_user_args(): call_deferred("test_city")

func reset_game():
 super.reset_game()
 unlocked_nodes=[]
 thermal=0
 overdrive=false

func save_game():
 super.save_game()
 if party.is_empty() or not FileAccess.file_exists(SAVE): return
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 data["version"]=4
 data["unlocked_nodes"]=unlocked_nodes
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(data))

func load_game():
 super.load_game()
 if mode=="world":
  var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  unlocked_nodes=data.get("unlocked_nodes",[]).map(func(v):return int(v))

func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_ESCAPE and mode in ["hacking","workshop"]:
   mode="world"
   return
  if event.physical_keycode==KEY_I and mode=="world":
   action("workshop")
   return
  if mode=="battle" and not turn_locked:
   if event.physical_keycode==KEY_O: action("overdrive"); return
   if event.physical_keycode==KEY_V: action("vent"); return
 super._unhandled_input(event)

func action(a:String):
 if a=="workshop" and mode=="world":
  workshop_index=active
  mode="workshop"
 elif a.begins_with("subject:") and mode=="workshop":
  workshop_index=int(a.get_slice(":",1))
 elif a.begins_with("implant:") and mode=="workshop":
  var selected=int(a.get_slice(":",1))
  if selected<=unlocked_nodes.size():
   party[workshop_index]["implant"]=selected
   beep(720,.12)
   toast(MODULES[selected]+" instalado en "+SPECIES[int(party[workshop_index].id)][0])
 elif a=="overdrive" and mode=="battle" and not turn_locked:
  if thermal>60:
   battle_text="SISTEMA CALIENTE · ventila antes de activar la sobrecarga."
  else:
   overdrive=not overdrive
   battle_text="SOBRECARGA "+("ARMADA · próximo ataque ×1.65; aumenta el calor." if overdrive else "desactivada.")
 elif a=="vent" and mode=="battle" and not turn_locked:
  turn_locked=true
  overdrive=false
  thermal=maxi(0,thermal-60)
  battle_text="PURGA CRIOGÉNICA · −60 calor. El rival conserva su turno."
  beep(150,.3)
  await get_tree().create_timer(.7).timeout
  await enemy_turn()
 elif a.begins_with("node:") and mode=="hacking":
  hack_press(int(a.get_slice(":",1)))
 elif a=="retry_hack" and mode=="hacking": begin_hack()
 elif a=="city_close" and mode in ["hacking","workshop"]: mode="world"
 else: super.action(a)

func interact():
 if mode=="world" and pos.distance_to(TERMINALS[zone])<=1.5:
  if zone in unlocked_nodes:
   say("NODO LIBERADO\nEsta red ya es tuya. Los implantes están disponibles en el taller [I].")
  else: begin_hack()
  return
 super.interact()

func walkable(p:Vector2i)->bool:
 if p==TERMINALS[zone]: return false
 return super.walkable(p)

func begin_hack():
 hacking_sequence=[]
 hacking_input=[]
 hack_error=""
 for i in range(3+zone): hacking_sequence.append(randi_range(0,3))
 hack_reveal_until=clock+3.5+zone*.6
 mode="hacking"

func hack_press(index:int):
 if clock<hack_reveal_until or hack_error!="": return
 if index!=int(hacking_sequence[hacking_input.size()]):
  hack_error="TRAZA DETECTADA · vuelve a intentarlo; no pierdes recursos."
  beep(100,.3)
  return
 hacking_input.append(index)
 beep(350+index*160,.1)
 if hacking_input.size()==hacking_sequence.size():
  if not zone in unlocked_nodes:
   unlocked_nodes.append(zone)
   money+=150
  mode="world"
  if unlocked_nodes.size()==3:
   balls+=5
   potions+=3
   toast("RED LIBERADA · +₽150 · +5 Balls · +3 pociones · refrigeración mejorada")
  else: toast("NODO LIBERADO · +₽150 · nuevo implante disponible [I]")

func start_battle(wild:Dictionary,opponent=""):
 thermal=0
 overdrive=false
 enemy_cycles=0
 resolving_enemy=false
 super.start_battle(wild,opponent)

func damage(attacker:Dictionary,defender:Dictionary,power:int,kind:String)->int:
 var hit=super.damage(attacker,defender,power,kind)
 if hit==0: return 0
 if resolving_enemy:
  if int(defender.get("implant",0))==1: hit=maxi(1,roundi(hit*.75))
  if enemy_cycles%3==0: hit=roundi(hit*1.3)
 else:
  if int(attacker.get("implant",0))==0: hit=roundi(hit*1.2)
  if cyber_attack_boost: hit=roundi(hit*1.65)
  if int(defender.id) in [9,212,137] and enemy_cycles==0: hit=maxi(1,roundi(hit*.75))
 return hit

func player_attack(special:bool):
 cyber_attack_boost=overdrive
 if overdrive:
  thermal=mini(100,thermal+(25 if int(party[active].get("implant",0))==0 else 35)-(5 if unlocked_nodes.size()==3 else 0))
 else: thermal=maxi(0,thermal-10)
 overdrive=false
 await super.player_attack(special)
 cyber_attack_boost=false

func enemy_turn():
 enemy_cycles+=1
 resolving_enemy=true
 await super.enemy_turn()
 resolving_enemy=false
 if mode=="battle" and party[active].hp>0 and int(party[active].get("implant",0))==2:
  party[active].hp=mini(party[active].maxhp,party[active].hp+maxi(1,roundi(party[active].maxhp*.1)))

func _draw():
 super._draw()
 if mode=="hacking": draw_hacking()
 elif mode=="workshop": draw_workshop()

func draw_hacking():
 box(Rect2(0,0,960,720),Color(0.01,.025,.06,.89))
 panel(Rect2(150,115,660,488),Color("0b1829"),CYAN)
 label_at("NETRUN / NODO 0"+str(zone+1),Vector2(184,156),14,CYAN)
 label_at("Rompe el cifrado",Vector2(184,200),32)
 var revealing=clock<hack_reveal_until
 label_at("Memoriza la secuencia. Después repítela." if revealing else "Introduce los símbolos en el mismo orden.",Vector2(184,239),18,Color("aac1d1"))
 var symbols=["01","10","11","00"]
 for i in range(hacking_sequence.size()):
  var r=Rect2(185+i*106,269,87,69)
  panel(r,Color("18344a"),CYAN if revealing or i<hacking_input.size() else Color("344256"))
  label_at(symbols[int(hacking_sequence[i])] if revealing or i<hacking_input.size() else "??",r.position+Vector2(23,45),25,CYAN)
 if revealing: label_at("LECTURA · "+str(ceili(hack_reveal_until-clock))+" s",Vector2(185,372),15,PINK)
 else: label_at(hack_error if hack_error!="" else "SEÑAL ESTABLE · "+str(hacking_input.size())+" / "+str(hacking_sequence.size()),Vector2(185,372),14,PINK)
 for i in range(4): button(Rect2(185+i*145,402,129,58),str(i+1)+"  [ "+symbols[i]+" ]","node:"+str(i))
 label_at("RECOMPENSA   ₽150 + "+("refrigeración y suministros" if unlocked_nodes.size()==2 else "acceso a un implante"),Vector2(185,501),16,CYAN)
 button(Rect2(185,532,270,42),"REINICIAR SECUENCIA","retry_hack")
 button(Rect2(470,532,305,42),"DESCONECTAR [ESC]","city_close")
 # Only modal controls can receive clicks or number shortcuts.
 buttons=buttons.slice(buttons.size()-6)

func draw_workshop():
 box(Rect2(0,0,960,720),Color(.01,.025,.06,.94))
 label_at("RIPPER LAB / IMPLANTES",Vector2(40,53),16,CYAN)
 label_at("Evoluciona tu estrategia",Vector2(40,95),33)
 for i in range(party.size()):
  button(Rect2(40,123+i*62,210,52),SPECIES[int(party[i].id)][0],"subject:"+str(i))
 var p=party[workshop_index]
 sprite(int(p.id),Vector2(277,166),210)
 label_at("MÓDULOS PERMANENTES",Vector2(512,158),15,PINK)
 for i in range(3):
  var locked=i>unlocked_nodes.size()
  panel(Rect2(512,178+i*109,407,99),Color("14273b"),CYAN if int(p.get("implant",0))==i else Color("34455b"))
  button(Rect2(523,188+i*109,383,36),("BLOQUEADO · " if locked else ("INSTALADO · " if int(p.get("implant",0))==i else "INSTALAR · "))+MODULES[i],"implant:"+str(i))
  paragraph(MODULE_INFO[i],Vector2(529,246+i*109),359,14,Color("afc7d7"))
 paragraph("Los implantes se conservan al evolucionar y al depositar en la caja. Libera nodos en la ciudad para desbloquearlos.",Vector2(284,420),203,17,Color("9db6c9"))
 label_at("RED LIBERADA  "+str(unlocked_nodes.size())+" / 3",Vector2(40,576),18,CYAN)
 button(Rect2(40,622,879,51),"VOLVER A LA CIUDAD [ESC]","city_close")
 buttons=buttons.slice(buttons.size()-(party.size()+4))

func draw_battle():
 super.draw_battle()
 panel(Rect2(523,458,395,27),Color("0d1e30"),Color("38536a"))
 label_at(("OC ARMADA" if overdrive else MODULES[int(party[active].get("implant",0))])+" / CALOR "+str(thermal)+"%",Vector2(536,477),12,CYAN if thermal<=60 else PINK)
 box(Rect2(770,468,133,6),Color("233a51"))
 box(Rect2(770,468,133*thermal/100.0,6),PINK if thermal>60 else CYAN)
 label_at("RIVAL / "+("PULSO +30% EN SU PRÓXIMO TURNO" if (enemy_cycles+1)%3==0 else "PULSO EN "+str(3-enemy_cycles%3)+" TURNOS"),Vector2(40,181),11,PINK)
 if not turn_locked and battle_menu=="main":
  box(Rect2(501,500,459,220),Color("0a1425"))
  buttons=[]
  button(Rect2(510,513,205,39),"1  LUCHAR","fight")
  button(Rect2(730,513,205,39),"2  BALL ×"+str(balls),"catch")
  button(Rect2(510,559,205,39),"3  POCIÓN ×"+str(potions),"battle_potion")
  button(Rect2(730,559,205,39),"4  EQUIPO","switch")
  button(Rect2(510,651,425,39),"5  HUIR","run")
  button(Rect2(510,605,205,39),"[O] "+("OC ARMADA" if overdrive else "SOBRECARGA"),"overdrive")
  button(Rect2(730,605,205,39),"[V] VENTILAR","vent")
 label_at("Sobrecarga: daño ×1.65 + calor. Ventilar: −60 calor, cede turno.",Vector2(28,712),12,Color("91aebf"))

func draw_world():
 var accent=[CYAN,Color("a495ff"),PINK][zone]
 var titles=["Neo Paleta", "La Brecha", "Distrito Cromo"]
 label_at("N E O N   K A N T O",Vector2(32,30),13,accent)
 label_at(titles[zone],Vector2(32,73),32)
 label_at(["01 / JARDINES SINTÉTICOS","02 / INFRAESTRUCTURA VIVA","03 / PODER CORPORATIVO"][zone],Vector2(560,31),13,Color("8ea9bb"))
 label_at("NODOS  "+str(unlocked_nodes.size())+"/3    |    ₽"+str(money),Vector2(670,70),17,accent)
 panel(Rect2(26,98,908,526),Color("0a1625"),Color("314a5c"))
 for y in range(16):
  for x in range(28): draw_tile(x,y,terrain(x,y))
 draw_map_details()
 draw_district_props()
 # Depth order uses ground contact, so actors can pass behind façades.
 var actors=[]
 for b in buildings(): actors.append({"y":b[0].end.y*32.0,"b":b})
 actors.append({"y":npc_position().y*32.0+30,"npc":true})
 actors.append({"y":visual_pos.y*32+30,"player":true})
 actors.sort_custom(func(a,b):return a.y<b.y)
 for item in actors:
  if item.has("b"): draw_building(item.b)
  elif item.has("player"): draw_person(ORIGIN+visual_pos*32,PINK,true)
  else: draw_person(ORIGIN+Vector2(npc_position())*32,CYAN,false)
 var q=ORIGIN+Vector2(TERMINALS[zone])*32
 ellipse_shape(q+Vector2(16,29),Vector2(22,7),Color(0,0,0,.4))
 panel(Rect2(q+Vector2(4,-4),Vector2(24,33)),Color("213b4f"),accent)
 panel(Rect2(q+Vector2(7,-1),Vector2(18,18)),Color("071c2d"),accent.darkened(.45))
 label_at("✓" if zone in unlocked_nodes else ">_",q+Vector2(8,12),11,accent)
 glow(q+Vector2(16,8),22,accent,.09)
 if pos.distance_to(TERMINALS[zone])<=2:
  holo_sign(q+Vector2(-19,-32),"E / CONECTAR",accent)
 draw_foreground_details()
 # Atmosphere and traffic stay inside the playfield.
 for i in range(3):
  var x=fmod(clock*(18+i*7)+i*307,820)+60
  var y=125+i*152
  draw_line(Vector2(x-32,y+10),Vector2(x+12,y+10),Color(accent,.08),7,true)
  ellipse_shape(Vector2(x,y+22),Vector2(20,4),Color(0,0,0,.15))
  panel(Rect2(x,y,24,7),Color("617b90"),accent.darkened(.4))
  draw_line(Vector2(x+5,y+8),Vector2(x+20,y+8),accent,2,true)
 label_at("E  CONECTAR     I  IMPLANTES",Vector2(32,647),13,accent)
 label_at("Libera el nodo de este distrito" if not zone in unlocked_nodes else "Red liberada · implantes disponibles",Vector2(32,671),12,Color("8ea9bb"))
 button(Rect2(351,639,112,43),"EQUIPO [P]","party")
 button(Rect2(473,639,103,43),"BOLSA [B]","bag")
 button(Rect2(586,639,101,43),"CÓDEX [N]","dex")
 button(Rect2(697,639,100,43),"IMPLANTES","workshop")
 button(Rect2(807,639,122,43),"GUARDAR","save")
 label_at("WASD / FLECHAS  mover    ·    N  códex    ·    M  sonido",Vector2(33,707),12,Color("647f94"))
 button(Rect2(748,689,181,27),"CAJA DIGITAL","archive")

func draw_tile(x:int,y:int,kind:String):
 if kind in ["tree","water","grass","flowers"]:
  super.draw_tile(x,y,kind)
  if kind=="grass":
   var p=ORIGIN+Vector2(x,y)*32
   if terrain(x,y+1)!="grass":
    box(Rect2(p+Vector2(0,28),Vector2(32,5)),Color("364d54"))
    draw_line(p+Vector2(1,28),p+Vector2(31,28),Color("64bca2"),1,true)
  return
 var p=ORIGIN+Vector2(x,y)*32
 var tone=Color("1a2938") if kind=="path" else Color("203444")
 box(Rect2(p,Vector2(32,32)),tone)
 # Large slabs, subtle joints and polished asphalt instead of checkerboard tiles.
 if kind!="path":
  if y%2==0: draw_line(p,p+Vector2(32,0),Color("324858"),1)
  if (x+y/2)%3==0: draw_line(p,p+Vector2(0,32),Color("324858"),1)
  if (x*31+y*7)%13==0:
   for i in range(5): draw_line(p+Vector2(8,12+i*2),p+Vector2(24,12+i*2),Color("101f30"),1)
 else:
  if x==13: draw_line(p+Vector2(2,0),p+Vector2(2,32),CYAN.darkened(.35),2)
  if x==14: draw_line(p+Vector2(30,0),p+Vector2(30,32),CYAN.darkened(.35),2)
  if x==13 and y%2==0: box(Rect2(p+Vector2(31,5),Vector2(2,16)),Color("678892"))
  if terrain(x,y-1)!="path": draw_line(p,p+Vector2(32,0),Color("435a68"),3)
  if terrain(x,y+1)!="path": draw_line(p+Vector2(0,31),p+Vector2(32,31),Color("435a68"),3)
 if (x*7+y*3)%5==0:
  ellipse_shape(p+Vector2(16,25),Vector2(15,3),Color(.20,.68,.76,.065))
  draw_line(p+Vector2(8,26),p+Vector2(27,26),Color(.35,.8,.91,.07),1)

func draw_tree(p:Vector2,variation:int):
 # A continuous perimeter of utility architecture, with emissive glass strips.
 box(Rect2(p,Vector2(32,32)),Color("101e30"))
 box(Rect2(p+Vector2(1,2),Vector2(28,25)),Color("293e50"))
 draw_colored_polygon(PackedVector2Array([p+Vector2(1,2),p+Vector2(24,2),p+Vector2(29,7),p+Vector2(6,7)]),Color("496171"))
 box(Rect2(p+Vector2(5,9),Vector2(22,16)),Color("11283c"))
 for i in range(3):
  draw_line(p+Vector2(7,11+i*5),p+Vector2(24,11+i*5),Color("356075") if (i+variation)%3 else CYAN.darkened(.25),2)
 draw_line(p+Vector2(2,29),p+Vector2(28,29),PINK.darkened(.5) if zone==2 else CYAN.darkened(.6),1)

func draw_building(b:Array):
 var r:Rect2i=b[0]
 var ground=ORIGIN+Vector2(r.position)*32
 var w=r.size.x*32.0
 var h=r.size.y*32.0
 var p=ground-Vector2(0,26)
 var c:Color=b[2]
 var is_lab=b[1]=="LAB. OAK"
 var is_arena=b[1]=="GIMNASIO"
 var roof_height=36.0 if is_arena else 24.0
 # Directional long shadow establishes height and a consistent night light source.
 draw_colored_polygon(PackedVector2Array([ground+Vector2(2,12),ground+Vector2(w,12),ground+Vector2(w+25,h+17),ground+Vector2(24,h+17)]),Color(0,.01,.025,.48))
 panel(Rect2(p+Vector2(0,roof_height),Vector2(w,h+26-roof_height)),Color("152b3f"),Color("567383"))
 # Lit glass curtain wall, graduated cyan reflections and vertical mullions.
 for yy in range(int(roof_height)+5,int(h)+13):
  var f=float(yy-roof_height)/(h+13-roof_height)
  draw_line(p+Vector2(7,yy),p+Vector2(w-7,yy),Color("294e65").lerp(Color("0e2135"),f),1)
 for xx in range(12,int(w)-12,23):
  for yy in range(int(roof_height)+9,int(h)-6,21):
   var color=Color("52a8b4") if (xx*3+yy)%5 else Color("d0bc97")
   box(Rect2(p+Vector2(xx,yy),Vector2(14,8)),Color(color,.22))
  draw_line(p+Vector2(xx+17,roof_height+4),p+Vector2(xx+17,h+15),Color("536f80"),2,true)
 # Diagonal reflections in the façade, with strong floor bands.
 for i in range(3):
  var q=p+Vector2(w*.52+i*13,roof_height+4)
  draw_colored_polygon(PackedVector2Array([q,q+Vector2(9,0),q+Vector2(-25,h-roof_height-1),q+Vector2(-34,h-roof_height-1)]),Color(.55,.9,1,.065))
 for yy in range(int(roof_height)+28,int(h),36):
  box(Rect2(p+Vector2(0,yy),Vector2(w,5)),Color("233e53"))
  draw_line(p+Vector2(1,yy),p+Vector2(w-1,yy),Color("64828d"),1)
 # Roof slab in oblique perspective, inset rooftop garden or mechanical plant.
 draw_colored_polygon(PackedVector2Array([p+Vector2(-6,roof_height),p+Vector2(8,-9),p+Vector2(w-4,-9),p+Vector2(w+7,roof_height)]),Color("425c6d"))
 draw_colored_polygon(PackedVector2Array([p+Vector2(6,roof_height-5),p+Vector2(15,-3),p+Vector2(w-11,-3),p+Vector2(w-3,roof_height-5)]),Color("233e50"))
 draw_line(p+Vector2(-6,roof_height),p+Vector2(w+7,roof_height),c,3,true)
 for i in range(4):
  var q=p+Vector2(20+i*31,3)
  if is_lab or b[1]=="CASA":
   ellipse_shape(q+Vector2(10,8),Vector2(12,5),Color("172e38"))
   draw_circle(q+Vector2(10,1),7,Color("396d64"))
   draw_circle(q+Vector2(7,-2),5,Color("5a9780"))
   draw_circle(q+Vector2(10,-3),2,c)
  else:
   panel(Rect2(q,Vector2(23,16)),Color("69808c"),Color("90a2a7"))
   draw_circle(q+Vector2(11,8),6,Color("284557"))
   draw_arc(q+Vector2(11,8),4,clock,clock+PI,12,c,1,true)
 # Extruded marquee and stepped entrance precisely on its collision footprint.
 var dx=int(r.size.x/2)*32
 panel(Rect2(ground+Vector2(dx-6,h-29),Vector2(43,29)),Color("0e2b40"),c)
 draw_line(ground+Vector2(dx+15,h-26),ground+Vector2(dx+15,h-1),c,2)
 for i in range(3):
  draw_line(ground+Vector2(dx-12,h+i*3),ground+Vector2(dx+45,h+i*3),Color("70919b").darkened(i*.16),2)
 var title={"CASA":"HABITAT / 07","LAB. OAK":"OAK • BIO SYSTEMS","CENTRO":"REPAIR CLINIC","GIMNASIO":"CHROME / ARENA"}[b[1]]
 panel(Rect2(p+Vector2(-7,h-35),Vector2(w+14,30)),Color("182e43"),c.darkened(.35))
 label_at(title,p+Vector2(14,h-15),13,c)
 draw_line(p+Vector2(-7,h-4),p+Vector2(w+7,h-4),c,2,true)
 # Broken, stretched neon reflections on wet paving below the entrance.
 for i in range(9):
  var a=.13*(1.0-float(i)/9)
  draw_line(ground+Vector2(12+i%3*13,h+12+i*3),ground+Vector2(w-18-i%4*11,h+12+i*3),Color(c,a),2,true)
 glow(ground+Vector2(w/2,h+4),w*.45,c,.035)
 if is_arena:
  var center=p+Vector2(w*.65,-17)
  draw_line(center+Vector2(0,19),center+Vector2(0,-29),Color("627c91"),3)
  draw_arc(center,21,clock*.25,TAU+clock*.25,48,PINK,2,true)
  draw_arc(center,14,-clock*.4,PI*1.5-clock*.4,32,CYAN,2,true)
  glow(center,30,PINK,.09)
  label_at("C",center+Vector2(-8,8),21,PINK)
 if is_lab:
  var q=p+Vector2(w-37,5)
  draw_line(q,q+Vector2(0,-25),Color("4f8e9b"),2)
  for i in range(7):
   var y=-27+i*5
   var x=sin(clock+i*.9)*10
   draw_line(q+Vector2(-x,y),q+Vector2(x,y),Color(CYAN,.65),1,true)
   draw_circle(q+Vector2(x,y),2,CYAN)
   draw_circle(q+Vector2(-x,y),2,PINK)

func draw_district_props():
 if zone==0:
  # Reservoir with luminous koi-like maintenance drones and pressure pipework.
  for i in range(4):
   var q=ORIGIN+Vector2(92+i*39+sin(clock*.5+i)*10,385+cos(clock*.7+i)*23)
   draw_arc(q,12,0,PI,18,Color(CYAN,.23),1,true)
   draw_colored_polygon(PackedVector2Array([q+Vector2(-7,0),q+Vector2(0,-3),q+Vector2(9,0),q+Vector2(0,3)]),Color("77babf"))
   draw_line(q+Vector2(-8,0),q+Vector2(-13,sin(clock*3+i)*4),CYAN,2,true)
  holo_sign(ORIGIN+Vector2(78,309),"AQUA / RECYCLING",CYAN)
  for i in range(3):
   var q=ORIGIN+Vector2(620+i*45,454)
   ellipse_shape(q,Vector2(18,6),Color("324f56"))
   draw_line(q,q-Vector2(0,20),Color("83bfa4"),2)
   draw_circle(q-Vector2(0,20),8,Color("426f65"))
   glow(q-Vector2(0,20),12,PINK,.06)
 elif zone==1:
  # Elevated transit line across the industrial district; transparent piers.
  for y in [302,328]: draw_line(Vector2(57,y),Vector2(391,y),Color("445e72"),5,true)
  for x in [85,202,350]:
   draw_line(Vector2(x,323),Vector2(x+11,359),Color("344c5f"),6,true)
   draw_line(Vector2(x,304),Vector2(x,326),CYAN.darkened(.25),1)
  var train_x=78+fmod(clock*31,210)
  panel(Rect2(train_x,299,78,28),Color("557a91"),CYAN)
  for i in range(4): panel(Rect2(train_x+7+i*17,303,12,13),Color("13283c"),Color("8bc4ca"))
  draw_line(Vector2(train_x+5,324),Vector2(train_x+73,324),PINK,2)
  holo_sign(Vector2(110,386),"MAGLEV / SECTOR 02",Color("ab9bfc"))
  # Cooling towers with curved translucent vessels.
  for i in range(3):
   var q=Vector2(669+i*58,203)
   panel(Rect2(q,Vector2(40,71)),Color("244558"),Color("567987"))
   ellipse_shape(q+Vector2(20,2),Vector2(20,8),Color("507c8c"))
   ellipse_shape(q+Vector2(20,66),Vector2(19,7),Color("122d42"))
   draw_line(q+Vector2(8,12),q+Vector2(8,56),CYAN,2)
   for j in range(3): draw_circle(q+Vector2(22+sin(clock+j)*7,14+fmod(clock*10+j*17,43)),2,Color(CYAN,.5))
 else:
  # Night market: contrasting warm stall lights, energy cells and holograms.
  for i in range(3):
   var q=Vector2(630+i*88,542)
   ellipse_shape(q+Vector2(25,18),Vector2(35,12),Color(0,0,0,.22))
   panel(Rect2(q+Vector2(0,-15),Vector2(67,31)),Color("28384b"),Color("987286"))
   draw_colored_polygon(PackedVector2Array([q+Vector2(-5,-14),q+Vector2(3,-35),q+Vector2(63,-35),q+Vector2(72,-14)]),Color("774867") if i%2 else Color("416c7b"))
   draw_line(q+Vector2(-5,-14),q+Vector2(72,-14),Color("ffc895"),2)
   for j in range(3):
    panel(Rect2(q+Vector2(8+j*18,-5),Vector2(10,13)),Color("4e7381"),CYAN if j%2 else PINK)
   glow(q+Vector2(32,0),24,Color("ffbc87"),.075)
 # Ambient district hologram: recognisable creature silhouette over a projector.
 var center=Vector2(350,535) if zone!=1 else Vector2(544,218)
 ellipse_shape(center+Vector2(0,29),Vector2(26,8),Color("44697a"))
 draw_colored_polygon(PackedVector2Array([center+Vector2(-8,28),center+Vector2(8,28),center+Vector2(29,-40),center+Vector2(-29,-40)]),Color(CYAN,.07))
 sprite([137,25,133][zone],center-Vector2(28,44+sin(clock)*3),56,false,.45)
 for i in range(7): draw_line(center+Vector2(-24,-36+i*7),center+Vector2(24,-36+i*7),Color(CYAN,.12),1)

func draw_person(p:Vector2,c:Color,player:bool):
 var q=p+Vector2(16,16)
 var step=sin(walk_phase*PI)*3 if walking and player else 0.0
 var bob=absf(step)*.3
 ellipse_shape(q+Vector2(0,14),Vector2(10,4),Color(0,0,0,.45))
 for side in [-1,1]:
  var foot=q+Vector2(side*4,10+step*side)
  draw_line(q+Vector2(side*3,3),foot,Color("17283a"),5,true)
  draw_line(foot,foot+Vector2(3,1),Color("8dabb7"),3,true)
 var body=q+Vector2(0,-bob)
 draw_colored_polygon(PackedVector2Array([body+Vector2(-7,-12),body+Vector2(7,-12),body+Vector2(9,5),body+Vector2(-9,5)]),Color("334b62"))
 draw_line(body+Vector2(-7,-10),body+Vector2(-10,1+step*.5),c,4,true)
 draw_line(body+Vector2(7,-10),body+Vector2(10,1-step*.5),c.darkened(.3),4,true)
 draw_line(body+Vector2(-5,3),body+Vector2(5,3),c,2,true)
 draw_circle(body+Vector2(0,-17),7,Color("d7b5a0"))
 draw_arc(body+Vector2(0,-18),6,PI,TAU,16,Color("192a3d"),6,true)
 if not player or facing!=Vector2i.UP:
  draw_line(body+Vector2(-5,-17),body+Vector2(6,-17),CYAN,3,true)
 else: draw_circle(body+Vector2(0,-18),6,Color("203549"))
 if player:
  draw_line(body+Vector2(-3,-9),body+Vector2(-3,0),CYAN,1,true)
  glow(body+Vector2(0,-17),7,CYAN,.04)

func test_city():
 reset_game()
 action("starter:7")
 # Every transparent sprite has the same mathematical ground contact after mirroring.
 for id in SPECIES:
  for mirrored in [false,true]:
   var anchor=Vector2(238,455)
   var origin=ground_origin(id,anchor,282,mirrored)
   var pivot:Vector2=ground_pivots[id]
   if mirrored: pivot.x=1.0-pivot.x
   assert((origin+pivot*282).distance_to(anchor)<.01)
 # All nodes are reachable from district entrances, no decoration changes navigation.
 for z in range(3):
  zone=z
  var visited={Vector2i(13,14):true}
  var queue=[Vector2i(13,14)]
  var reachable=false
  while not queue.is_empty():
   var cell:Vector2i=queue.pop_front()
   if cell.distance_to(TERMINALS[z])<=1.5: reachable=true
   for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
    var next=cell+dir
    if not visited.has(next) and walkable(next):
     visited[next]=true
     queue.append(next)
  assert(reachable)
  var before=money
  begin_hack()
  hack_reveal_until=clock-1
  hack_press((int(hacking_sequence[0])+1)%4)
  assert(hack_error!="" and money==before)
  begin_hack()
  hack_reveal_until=clock-1
  for symbol in hacking_sequence.duplicate(): hack_press(int(symbol))
  assert(z in unlocked_nodes and money==before+150)
 mode="world"
 action("workshop")
 action("implant:1")
 assert(party[0].implant==1)
 apply_evolution(0,8)
 assert(party[0].implant==1)
 var backup=FileAccess.get_file_as_string(SAVE) if FileAccess.file_exists(SAVE) else ""
 save_game()
 unlocked_nodes=[]
 party[0].implant=0
 load_game()
 assert(unlocked_nodes.size()==3 and party[0].implant==1)
 if backup!="":
  var f=FileAccess.open(SAVE,FileAccess.WRITE)
  f.store_string(backup)
 else: DirAccess.remove_absolute(SAVE)
 party=[mon(7,15)]
 start_battle(mon(1,25))
 seed(100)
 var normal=damage(party[0],enemy,40,"NORMAL")
 cyber_attack_boost=true
 seed(100)
 assert(damage(party[0],enemy,40,"NORMAL")>normal)
 cyber_attack_boost=false
 resolving_enemy=true
 enemy_cycles=1
 seed(100)
 normal=damage(enemy,party[0],40,"NORMAL")
 party[0].implant=1
 seed(100)
 assert(damage(enemy,party[0],40,"NORMAL")<normal)
 resolving_enemy=false
 thermal=70
 action("overdrive")
 assert(not overdrive)
 thermal=0
 action("overdrive")
 assert(overdrive)
 await player_attack(false)
 assert(thermal==30 and not overdrive and not turn_locked)
 action("vent")
 await get_tree().create_timer(1.8).timeout
 assert(thermal==0 and not turn_locked)
 print("CITY PASS: 40 grounded pivots; 3 reachable terminals; hack failure/success; module persistence and evolution; save migration; damage modifiers; heat and vent turns")
 get_tree().quit()
