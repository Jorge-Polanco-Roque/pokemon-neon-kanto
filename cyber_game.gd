extends "res://base_game.gd"

const CYAN = Color("53e8eb")
const PINK = Color("ee70c7")
const NAVY = Color("101a30")
const EVOLUTIONS = {1:[2],2:[3],4:[5],5:[6],7:[8],8:[9],25:[26],133:[134,135],92:[93],93:[94],123:[212]}
const EV_LEVEL = {1:8,2:12,4:8,5:12,7:8,8:12,25:10,133:8,92:8,93:12,123:10}
var archive: Array = []
var cry_player: AudioStreamPlayer
var voices = {}
var catalog = {}
var dex_selected = 0
var archive_page = 0
var evolving = {}
var map_weather = true
var native_augmented: Array = []
var defeated_trainers = 0

func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 super._ready()
 if FileAccess.file_exists("res://assets/art_manifest.json"):
  native_augmented=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art_manifest.json")).get("native_augmented",[])
 var rows = JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
 for row in rows: catalog[int(row.id)] = row
 cry_player = AudioStreamPlayer.new()
 cry_player.volume_db = -9
 add_child(cry_player)
 for id in SPECIES: voices[id] = load("res://assets/audio/"+str(id)+".wav")
 if "--cyber-test" in OS.get_cmdline_user_args(): call_deferred("test_cyber")

func cry(id: int):
 if muted or not voices.has(id): return
 cry_player.stop()
 cry_player.stream = voices[id]
 cry_player.play()

func _unhandled_input(event):
 if mode == "evolution": return
 super._unhandled_input(event)
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode == KEY_M and muted and cry_player: cry_player.stop()
  if event.physical_keycode == KEY_ESCAPE and mode in ["archive","detail"]:
   mode = "dex" if mode == "detail" else "world"
  if event.physical_keycode == KEY_N and mode == "world": mode = "dex"

func reset_game():
 super.reset_game()
 archive = []
 defeated_trainers = 0
 dex_selected = 0

func action(a: String):
 if mode == "evolution": return
 if a == "archive":
  archive_page=0
  mode="archive"
 elif a.begins_with("archive_page:"):
  archive_page=int(a.split(":")[1])
 elif a.begins_with("deposit:"):
  var i=int(a.split(":")[1])
  if party.size()<=1:
   toast("Conserva al menos un compañero en el equipo.")
   return
  if party[i].hp>0:
   var living=0
   for p in party:
    if p.hp>0: living+=1
   if living<=1:
    toast("Conserva un compañero con PS en el equipo.")
    return
  archive.append(party.pop_at(i))
  active=0
  if first_living()>=0: active=first_living()
 elif a.begins_with("withdraw:"):
  var i=int(a.split(":")[1])
  if party.size()>=6:
   toast("Deposita un Pokémon antes de retirar otro.")
   return
  party.append(archive.pop_at(i))
  archive_page=mini(archive_page,maxi(0,(archive.size()-1)/6))
 elif a.begins_with("inspect:"):
  dex_selected=int(a.split(":")[1])
  mode="detail"
  cry(dex_selected)
 elif a.begins_with("cry:"): cry(int(a.split(":")[1]))
 elif a.begins_with("evolve:"):
  var parts=a.split(":")
  var i=int(parts[1])
  var target=int(parts[2])
  var id=int(party[i].id)
  if EVOLUTIONS.has(id) and target in EVOLUTIONS[id] and party[i].level>=EV_LEVEL[id]:
   await evolve(i,target,"party")
 elif a == "train":
  if money<80: toast("Necesitas ₽80 para el simulador.")
  else:
   money-=80
   var p=party[active]
   p.level+=1
   p.maxhp+=3
   p.hp=mini(p.maxhp,p.hp+3)
   cry(int(p.id))
   toast("Simulación completa · nivel "+str(p.level))
 elif a == "rain": map_weather=not map_weather
 elif a == "dex": mode="dex"
 else:
  super.action(a)
  if a.begins_with("starter:") or a.begins_with("lead:"):
   if not party.is_empty(): cry(int(party[active].id))

func start_battle(wild: Dictionary,opponent=""):
 super.start_battle(wild,opponent)
 if mode=="battle": cry(int(enemy.id))

func switch_mon(i: int):
 if i!=active and party[i].hp>0: cry(int(party[i].id))
 await super.switch_mon(i)

func accept_capture(p: Dictionary):
 if party.size()<6: party.append(p)
 else:
  archive.append(p)
  toast("Enviado a tu caja digital.")
 cry(int(p.id))

func save_game():
 if party.is_empty(): return
 var data={"version":3,"party":party,"archive":archive,"active":active,"zone":zone,"x":pos.x,"y":pos.y,"balls":balls,"potions":potions,"money":money,"rival":rival_done,"badge":badge,"seen":seen,"captured":captured}
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 if not f:
  toast("No se pudo guardar.")
  return
 f.store_string(JSON.stringify(data))
 save_exists=true
 toast("SINCRONIZACIÓN COMPLETA · partida guardada")

func load_game():
 super.load_game()
 if mode=="world":
  var d=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
  archive=d.get("archive",[])
  for p in party+archive:
   p.id=int(p.id)
   p.level=int(p.level)
  cry(int(party[active].id))

func evolve_after_victory():
 var id=int(party[active].id)
 if EVOLUTIONS.has(id) and EVOLUTIONS[id].size()==1 and party[active].level>=EV_LEVEL[id]:
  await evolve(active,EVOLUTIONS[id][0],"battle")
 elif id==133 and party[active].level>=8:
  toast("Eevee puede evolucionar: elige su ruta desde EQUIPO.")

func apply_evolution(i: int,target: int):
 var p=party[i]
 var oldmax=int(p.maxhp)
 var newmax=mon(target,int(p.level)).maxhp
 p.id=target
 p.maxhp=newmax
 p.hp=mini(newmax,int(p.hp)+maxi(0,newmax-oldmax))
 if not target in seen: seen.append(target)
 if not target in captured: captured.append(target)

func evolve(i: int,target: int,return_mode: String):
 evolving={"old":int(party[i].id),"new":target,"start":clock}
 mode="evolution"
 cry(int(party[i].id))
 await get_tree().create_timer(1.5).timeout
 apply_evolution(i,target)
 cry(target)
 await get_tree().create_timer(1.5).timeout
 mode=return_mode
 if return_mode=="battle": player_hp_visual=party[active].hp
 toast("¡Evolución completada! "+SPECIES[target][0])
 evolving={}

func type_factor(at: String,def: String)->float:
 if at=="FANTASMA": return 0.0 if def=="NORMAL" else (2.0 if def=="FANTASMA" else 1.0)
 if at=="NORMAL" and def=="FANTASMA": return 0.0
 if at=="ACERO": return 0.5 if def in ["AGUA","FUEGO","ACERO"] else 1.0
 if def=="ACERO": return 2.0 if at=="FUEGO" else (0.5 if at in ["PLANTA","NORMAL","BICHO"] else 1.0)
 return super.type_factor(at,def)

func terrain(x:int,y:int)->String:
 var t=super.terrain(x,y)
 if zone==0 and x>=18 and x<=25 and y>=10 and y<=13: return "grass"
 if zone==2 and x>=3 and x<=10 and y>=12 and y<=14: return "grass"
 return t

func move_player(dir:Vector2i):
 super.move_player(dir)

func buildings()->Array:
 if zone==0: return [[Rect2i(4,3,6,4),"CASA",CYAN],[Rect2i(18,3,7,4),"LAB. OAK",PINK]]
 if zone==2: return [[Rect2i(3,3,7,5),"CENTRO",CYAN],[Rect2i(18,2,7,5),"GIMNASIO",PINK]]
 return []

func interact():
 if mode=="world" and zone==0 and (pos+facing).distance_to(npc_position())<=1.1:
  say("OAK / LABORATORIO 2096\nLos implantes evolucionan junto a su compañero. La primera mejora llega al nivel 8; la segunda, al 12. En EQUIPO puedes elegir la ruta de Eevee o usar el simulador.")
  return
 super.interact()

func _draw():
 buttons=[]
 box(Rect2(0,0,960,720),Color("080e1c"))
 if mode=="title": draw_title()
 elif mode=="starter": draw_starter()
 elif mode=="evolution": draw_evolution()
 elif mode=="battle": draw_battle()
 else:
  draw_world()
  if mode=="dialogue": draw_dialogue()
  elif mode=="party": draw_party()
  elif mode=="bag": draw_bag()
  elif mode=="dex": draw_dex()
  elif mode=="detail": draw_detail()
  elif mode=="archive": draw_archive()
  elif mode=="shop": draw_shop()
 if notice_time>0:
  panel(Rect2(160,11,640,40),Color("122a3b"),CYAN)
  label_at(notice,Vector2(177,38),16,CYAN)

func glow(p:Vector2,r:float,c:Color,strength=0.12):
 for i in range(5,0,-1):
  var cc=c
  cc.a=strength*(1.0-float(i)/6.0)
  draw_circle(p,r*i/3.0,cc)

func panel(r:Rect2,c:Color,border:Color):
 var style=StyleBoxFlat.new()
 style.bg_color=c
 style.border_color=border
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 draw_style_box(style,r)

func button(r:Rect2,title:String,a:String,color=INK):
 var hover=r.has_point(get_global_mouse_position())
 panel(r,Color("243d55") if hover else Color("142338"),CYAN if hover else Color("31475f"))
 draw_line(r.position+Vector2(1,9),r.position+Vector2(1,r.size.y-9),CYAN if hover else Color("426f86"),2)
 label_at(title,r.position+Vector2(12,r.size.y/2+5),15,WHITE)
 buttons.append({"rect":r,"action":a})

func sprite(id:int,at:Vector2,size:float,back=false,alpha=1.0):
 if not sprites.has(str(id)): return
 var texture=sprites[str(id)]
 var rect=Rect2(at,Vector2(size,size))
 if back:
  rect.position.x+=size
  rect.size.x=-size
 draw_texture_rect(texture,rect,false,Color(1,1,1,alpha))
 # Legacy-only sprites get an animated holographic augmentation layer.
 if id in native_augmented: draw_cyber_overlay(id,at,size,back,alpha)

func draw_cyber_overlay(id:int,at:Vector2,size:float,back:bool,alpha:float):
 # These six designs use high-resolution illustrated bases with bespoke live
 # mechanical geometry. The augmentations animate, rotate and emit light.
 var origin=at+Vector2(size if back else 0,0)
 draw_set_transform(origin,0,Vector2(-size if back else size,size)/475.0)
 var c=CYAN
 var pink=PINK
 c.a=alpha
 pink.a=alpha
 var steel=Color(.16,.24,.34,alpha)
 var rim=Color(.52,.66,.73,alpha)
 if id==6:
  for pts in [PackedVector2Array([Vector2(34,210),Vector2(126,124),Vector2(158,192),Vector2(208,216),Vector2(134,226)]),PackedVector2Array([Vector2(296,214),Vector2(370,141),Vector2(430,190),Vector2(442,236),Vector2(367,229)])]:
   draw_colored_polygon(pts,Color(.15,.70,.85,.48*alpha))
   for i in range(pts.size()):
    draw_line(pts[i],pts[(i+1)%pts.size()],c,3)
    draw_line(pts[i],pts[0].lerp(pts[2],.5),Color(.49,.9,1,.45*alpha),1)
  draw_arc(Vector2(248,278),29,0,TAU,40,steel,12)
  draw_arc(Vector2(248,278),25,0,TAU,40,c,3)
  draw_circle(Vector2(248,278),13,steel)
  draw_circle(Vector2(248,278),7,c)
  glow(Vector2(248,278),28,CYAN,.11)
  draw_line(Vector2(229,91),Vector2(252,94),c,5)
  for q in [Vector2(143,244),Vector2(345,245)]:
   draw_circle(q,13,steel)
   draw_arc(q,10,0,TAU,24,rim,2)
   draw_circle(q,4,c)
 elif id==9:
  var plate=PackedVector2Array([Vector2(94,151),Vector2(194,125),Vector2(254,141),Vector2(273,236),Vector2(214,335),Vector2(91,353),Vector2(70,267)])
  draw_colored_polygon(plate,steel)
  for i in range(plate.size()): draw_line(plate[i],plate[(i+1)%plate.size()],rim,5)
  var center=Vector2(167,244)
  for q in plate:
   draw_line(q,center,c,2)
  draw_circle(center,48,Color("14283a"))
  draw_arc(center,41,0,TAU,40,c,5)
  draw_arc(center,31,clock,clock+PI*1.6,32,pink,3)
  draw_circle(center,15,c)
  glow(center,48,CYAN,.10)
  panel(Rect2(328,133,57,43),steel,rim)
  draw_line(Vector2(331,147),Vector2(381,141),c,5)
  draw_line(Vector2(331,163),Vector2(381,156),c,3)
  draw_circle(Vector2(382,148),10,Color("173a50"))
  draw_arc(Vector2(382,148),9,0,TAU,24,c,3)
 elif id==25:
  draw_colored_polygon(PackedVector2Array([Vector2(126,273),Vector2(202,269),Vector2(249,293),Vector2(270,369),Vector2(142,378)]),steel)
  draw_line(Vector2(142,290),Vector2(157,364),c,4)
  draw_line(Vector2(237,292),Vector2(254,365),pink,4)
  draw_circle(Vector2(193,328),15,rim)
  draw_circle(Vector2(193,328),10,c)
  draw_circle(Vector2(182,204),20,steel)
  draw_arc(Vector2(182,204),16,0,TAU,32,pink,4)
  draw_circle(Vector2(182,204),6,pink)
  for i in range(4): draw_line(Vector2(89,100+i*10),Vector2(116,92+i*10),rim,5)
  for i in range(3):
   var q=Vector2(345+i*25,192-i*15)
   draw_line(q,q+Vector2(5,29),steel,8)
   draw_line(q+Vector2(3,0),q+Vector2(8,29),c,3)
 elif id==26:
  for q in [Vector2(81,162),Vector2(176,156)]:
   draw_circle(q,19,steel)
   draw_arc(q,16,clock,clock+PI*1.7,32,Color("f5c574"),3)
   draw_circle(q,7,c)
  for i in range(5):
   draw_line(Vector2(200+i*6,106-i*7),Vector2(213+i*5,112-i*7),rim,5)
  draw_arc(Vector2(129,256),32,0,TAU,32,steel,10)
  draw_arc(Vector2(129,256),28,0,TAU,32,pink,3)
  for i in range(4):
   var q=Vector2(313+i*27,244+i*11)
   draw_line(q,q+Vector2(9,25),steel,7)
   draw_line(q+Vector2(3,0),q+Vector2(12,25),c,2)
  var previous=Vector2(248,245)
  for i in range(7):
   var q=Vector2(254+i*13,245+sin(i*2+clock*17)*8)
   draw_line(previous,q,c,2)
   previous=q
 elif id==93:
  for q in [Vector2(80,239),Vector2(275,355)]:
   draw_arc(q,31,0,TAU,36,pink,3)
   for i in range(3):
    var start=q+Vector2((i-1)*14,0)
    draw_line(start,start+Vector2(-7,24),steel,12)
    draw_line(start+Vector2(-7,24),start+Vector2(-15,37),rim,7)
    draw_circle(start,5,c)
  for i in range(9):
   var q=Vector2(160+(i*37)%222,114+(i*51)%207)
   box(Rect2(q+Vector2(sin(clock*3+i)*8,0),Vector2(15,3)),Color(.59,.45,.92,.5*alpha))
  draw_line(Vector2(259,241),Vector2(329,206),c,3)
  draw_circle(Vector2(298,207),7,steel)
  draw_circle(Vector2(298,207),3,c)
 elif id==137:
  var vertices=[Vector2(60,205),Vector2(202,109),Vector2(275,196),Vector2(369,230),Vector2(253,342),Vector2(138,327),Vector2(157,208)]
  for i in range(vertices.size()):
   draw_line(vertices[i],vertices[(i+1)%vertices.size()],c,3)
   draw_circle(vertices[i],5,steel)
   draw_circle(vertices[i],2,pink)
  draw_arc(Vector2(187,155),22,0,TAU,32,steel,8)
  draw_circle(Vector2(187,155),9,c)
  var center=Vector2(293,269)
  draw_arc(center,24,clock,clock+TAU*.8,32,pink,4)
  for i in range(5):
   var q=center+Vector2(cos(clock+i*TAU/5),sin(clock+i*TAU/5))*43
   draw_line(center,q,Color(.37,.82,.98,.4),1)
   draw_circle(q,5,c)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)


func draw_title():
 draw_skyline(Rect2(0,0,960,720))
 box(Rect2(0,0,530,720),Color(0.025,0.04,0.09,.75))
 label_at("POKÉMON  /  AÑO 2096",Vector2(60,81),17,CYAN)
 label_at("NEÓN",Vector2(55,185),83,WHITE)
 label_at("KANTO",Vector2(55,268),83,PINK)
 label_at("La evolución encontró el futuro.",Vector2(61,315),21,Color("a4b9d1"))
 glow(Vector2(737,342),175,CYAN,.07)
 sprite(6,Vector2(492,115+sin(clock)*5),450)
 label_at("20 FORMAS · 8 FAMILIAS · EVOLUCIONES",Vector2(61,379),14,CYAN)
 button(Rect2(60,420,342,52),"INICIAR PROTOCOLO   →","new")
 if save_exists: button(Rect2(60,485,342,52),"CONTINUAR PARTIDA","load")
 label_at("WASD / flechas · caminar    E · interactuar",Vector2(60,600),16)
 label_at("P · equipo    N · códex    F5 · guardar    M · sonido",Vector2(60,630),15,Color("94a9c0"))
 label_at("NEÓN KANTO  /  EDICIÓN CYBER 0.3",Vector2(60,686),12,Color("648499"))

func draw_starter():
 draw_skyline(Rect2(0,0,960,720))
 box(Rect2(0,0,960,720),Color(0.02,.03,.08,.75))
 label_at("OAK INDUSTRIES / PROTOCOLO DE VÍNCULO",Vector2(46,58),15,CYAN)
 label_at("Elige tu primer compañero.",Vector2(46,108),36)
 label_at("Tres especies. Tres maneras de reescribir el futuro.",Vector2(46,148),19,Color("9daec5"))
 for i in range(3):
  var id=[1,4,7][i]
  var x=46+i*300
  var accent=[Color("91e6ad"),Color("ff9d70"),CYAN][i]
  panel(Rect2(x,189,270,409),Color("142135"),accent.darkened(.4))
  glow(Vector2(x+135,332),87,accent,.08)
  sprite(id,Vector2(x+10,210+sin(clock*2+i)*3),250)
  label_at(SPECIES[id][0],Vector2(x+19,468),24)
  label_at(catalog.get(id,{}).get("concept",""),Vector2(x+19,497),17,accent)
  label_at("NIVEL 5 → 8 → 12",Vector2(x+19,527),13,Color("8fa7c0"))
  button(Rect2(x+18,547,234,36),"VINCULAR   ["+str(i+1)+"]","starter:"+str(id))
 label_at("Cada forma posee una voz sintética propia y mejoras cibernéticas distintas.",Vector2(46,653),17,Color("9daec5"))

func draw_world():
 var names=["NEO PALETA","CORREDOR DE DATOS","DISTRITO CROMO"]
 label_at("NEÓN KANTO   /   2096",Vector2(32,30),13,CYAN)
 label_at(names[zone],Vector2(32,73),29)
 label_at("◉  RED ACTIVA",Vector2(774,30),12,PINK)
 var goal="Explora y entrena · rival al norte" if not rival_done else ("Gimnasio del Distrito Cromo" if not badge else "Medalla Circuito · explora las 20 formas")
 label_at(goal,Vector2(439,69),17,Color("9eb3ca"))
 panel(Rect2(26,98,908,526),Color("0b1423"),Color("294458"))
 for y in range(16):
  for x in range(28): draw_tile(x,y,terrain(x,y))
 draw_map_details()
 for b in buildings(): draw_building(b)
 draw_person(ORIGIN+Vector2(npc_position())*32,Color("aa77c9") if zone else Color("acbcd4"),false)
 draw_person(ORIGIN+visual_pos*32,Color("eb68a9"),true)
 draw_foreground_details()
 label_at("E · conectar / hablar",Vector2(33,650),15,Color("8faac2"))
 label_at("₽"+str(money)+"   ◉ "+str(balls)+" Balls",Vector2(33,681),16,CYAN)
 button(Rect2(250,642,124,42),"EQUIPO [P]","party")
 button(Rect2(384,642,124,42),"MOCHILA [B]","bag")
 button(Rect2(518,642,124,42),"CÓDEX [N]","dex")
 button(Rect2(652,642,124,42),"CAJA DIGITAL","archive")
 button(Rect2(786,642,141,42),"GUARDAR [F5]","save")

func draw_tile(x:int,y:int,kind:String):
 var p=ORIGIN+Vector2(x,y)*32
 box(Rect2(p,Vector2(32,32)),Color("162536") if (x+y)%2 else Color("18293b"))
 if kind=="path":
  box(Rect2(p,Vector2(32,32)),Color("202c40"))
  draw_line(p+Vector2(0,31),p+Vector2(32,31),Color("28364b"),1)
  if x in [13,14]:
   if x==13:
    draw_line(p+Vector2(2,0),p+Vector2(2,32),Color("2b7e90"),2)
    if y%2==0: box(Rect2(p+Vector2(30,9),Vector2(2,14)),Color("7b7890"))
   if x==14: draw_line(p+Vector2(30,0),p+Vector2(30,32),Color("2b7e90"),2)
  elif terrain(x,y-1)!="path": draw_line(p+Vector2(0,2),p+Vector2(32,2),Color("456278"),2)
  elif terrain(x,y+1)!="path": draw_line(p+Vector2(0,29),p+Vector2(32,29),Color("456278"),2)
  # Rain-polished little pools in the asphalt.
  if (x*3+y*7)%9==0:
   ellipse_shape(p+Vector2(19,21),Vector2(12,3),Color(.22,.54,.63,.14))
   draw_line(p+Vector2(11,21),p+Vector2(26,21),Color(.40,.76,.86,.16),1)
 elif kind=="water":
  box(Rect2(p,Vector2(32,32)),Color("103647"))
  for j in range(3):
   var xx=fmod(clock*8+x*7+j*11,30)
   draw_line(p+Vector2(xx,7+j*9),p+Vector2(minf(32,xx+9),7+j*9),Color(.17,.66,.73,.45),1)
  if terrain(x,y-1)!="water":
   box(Rect2(p,Vector2(32,4)),Color("32475a"))
   draw_line(p+Vector2(0,4),p+Vector2(32,4),CYAN,1)
  if terrain(x-1,y)!="water": box(Rect2(p,Vector2(4,32)),Color("32475a"))
  if terrain(x+1,y)!="water": box(Rect2(p+Vector2(28,0),Vector2(4,32)),Color("32475a"))
  if terrain(x,y+1)!="water": box(Rect2(p+Vector2(0,28),Vector2(32,4)),Color("32475a"))
 elif kind=="tree": draw_tree(p,x+y)
 elif kind=="grass":
  box(Rect2(p,Vector2(32,32)),Color("173239"))
  for i in range(4):
   var q=p+Vector2(5+i*7,25-i%2*7)
   var sway=sin(clock*1.5+x+i)*2
   draw_line(q,q+Vector2(sway,-11),Color("44776c"),2)
   draw_line(q+Vector2(0,-4),q+Vector2(4+sway,-8),Color("649c82"),2)
   draw_circle(q+Vector2(sway,-12),2,Color("67cbb2") if (x+y+i)%3 else PINK)
  if (x+y)%4==0: glow(p+Vector2(16,15),9,CYAN,.045)
 elif kind=="flowers":
  draw_circle(p+Vector2(16,16),9,Color("24474f"))
  for i in range(5):
   var q=p+Vector2(16,16)+Vector2(cos(i*TAU/5),sin(i*TAU/5))*6
   draw_circle(q,3,PINK)
  draw_circle(p+Vector2(16,16),2,CYAN)
 else:
  draw_line(p+Vector2(0,31),p+Vector2(32,31),Color("213549"),1)
  draw_line(p+Vector2(31,0),p+Vector2(31,32),Color("213549"),1)
  if (x*7+y*3)%11==0:
   draw_line(p+Vector2(7,16),p+Vector2(25,16),Color("345066"),1)
   draw_circle(p+Vector2(8,16),1,CYAN.darkened(.45))

func draw_tree(p:Vector2,variation:int):
 # Border towers: clean vector geometry, layered materials and lit window bands.
 var h=25+variation%3*3
 box(Rect2(p+Vector2(3,4),Vector2(27,28)),Color("0b1828"))
 box(Rect2(p+Vector2(1,3),Vector2(25,h)),Color("263950"))
 box(Rect2(p+Vector2(3,1),Vector2(23,5)),Color("41546a"))
 box(Rect2(p+Vector2(23,8),Vector2(4,h-7)),Color("162a3e"))
 for i in range(3):
  var c=Color("456076") if (variation+i)%3 else CYAN.darkened(.22)
  box(Rect2(p+Vector2(6,10+i*6),Vector2(13,2)),c)
 if variation%4==0: draw_line(p+Vector2(3,28),p+Vector2(25,28),PINK,1)

func draw_building(b:Array):
 var r:Rect2i=b[0]
 var p=ORIGIN+Vector2(r.position)*32
 var size_value=Vector2(r.size)*32
 var accent:Color=b[2]
 var h=size_value.y
 # Cast shadow, elevated roof, bevels and dark glass façade.
 var shadow=PackedVector2Array([p+Vector2(8,20),p+Vector2(size_value.x+16,24),p+size_value+Vector2(23,13),p+Vector2(13,h+13)])
 draw_colored_polygon(shadow,Color(0,.025,.06,.42))
 panel(Rect2(p+Vector2(0,21),size_value-Vector2(0,21)),Color("17283e"),Color("496175"))
 box(Rect2(p+Vector2(7,47),Vector2(size_value.x-14,h-53)),Color("122135"))
 for xx in range(12,int(size_value.x)-20,24):
  for yy in range(53,int(h)-32,21):
   var lit=(xx+yy+zone)%4!=0
   panel(Rect2(p+Vector2(xx,yy),Vector2(17,15)),Color("28485c") if lit else Color("1b3249"),Color("35566b"))
   if lit: draw_line(p+Vector2(xx+3,yy+3),p+Vector2(xx+13,yy+3),Color(.40,.79,.89,.45),1)
 panel(Rect2(p+Vector2(-4,-8),Vector2(size_value.x+8,52)),Color("34465e"),Color("5a7088"))
 panel(Rect2(p+Vector2(4,-3),Vector2(size_value.x-8,37)),Color("202f48"),Color("3f536b"))
 draw_line(p+Vector2(-2,44),p+Vector2(size_value.x+2,44),accent,3)
 for i in range(3):
  var q=p+Vector2(14+i*28,6)
  panel(Rect2(q,Vector2(22,15)),Color("193443"),Color("4a677a"))
  for z in range(4): draw_line(q+Vector2(4+z*4,3),q+Vector2(4+z*4,12),Color("568391"),1)
 # Roof utility block and antenna dish.
 panel(Rect2(p+Vector2(size_value.x-53,0),Vector2(39,25)),Color("46586d"),Color("6d8094"))
 draw_circle(p+Vector2(size_value.x-33,12),8,Color("263b50"))
 draw_arc(p+Vector2(size_value.x-33,12),5,clock,clock+PI*1.4,16,accent,1)
 var dx=int(r.size.x/2)*32
 panel(Rect2(p+Vector2(dx-3,h-39),Vector2(35,39)),Color("193c4e"),accent)
 box(Rect2(p+Vector2(dx+3,h-33),Vector2(23,31)),Color("214e62"))
 draw_line(p+Vector2(dx+15,h-32),p+Vector2(dx+15,h-3),accent,1)
 draw_line(p+Vector2(dx-8,h+2),p+Vector2(dx+38,h+2),accent,2)
 glow(p+Vector2(dx+15,h+3),22,accent,.10)
 # Holographic marquees, different silhouettes for the main buildings.
 var title={"CASA":"HABITAT 07","LAB. OAK":"OAK / BIO LAB","CENTRO":"REPAIR / CLINIC","GIMNASIO":"CHROME ARENA"}[b[1]]
 var sign_y=51 if h>130 else 54
 panel(Rect2(p+Vector2(21,sign_y),Vector2(size_value.x-42,25)),Color("15253b"),accent.darkened(.5))
 label_at(title,p+Vector2(29,sign_y+17),12,accent)
 if b[1]=="GIMNASIO":
  for xx in [-6,int(size_value.x)-2]:
   panel(Rect2(p+Vector2(xx,48),Vector2(10,h-48)),Color("344055"),PINK.darkened(.5))
   draw_line(p+Vector2(xx+4,53),p+Vector2(xx+4,h-5),PINK,2)
  draw_line(p+Vector2(size_value.x/2,-10),p+Vector2(size_value.x/2,-35),Color("7393ad"),2)
  glow(p+Vector2(size_value.x/2,-35),8,PINK,.18)
  draw_circle(p+Vector2(size_value.x/2,-35),3,PINK)

func draw_map_details():
 # Crosswalks and inset light rails organize the streets.
 for y in ([8,9] if zone==0 else ([7,8] if zone==1 else [10,11])):
  for x in [12,15]:
   var q=ORIGIN+Vector2(x,y)*32
   for i in range(4): box(Rect2(q+Vector2(5+i*6,3),Vector2(3,26)),Color("668191"))
 if zone==0:
  holo_sign(ORIGIN+Vector2(11*32,2*32),"↑ DATA",CYAN)
  holo_sign(ORIGIN+Vector2(17*32,10*32),"BIO GARDEN",PINK)
  draw_lamp(ORIGIN+Vector2(10*32,7*32))
  draw_lamp(ORIGIN+Vector2(16*32,7*32))
  # Canal filtration rings.
  for i in range(3):
   var q=ORIGIN+Vector2(4*32+i*46,12*32)
   draw_arc(q,17,clock*.2+i,clock*.2+i+TAU*.8,28,CYAN.darkened(.25),1)
   draw_circle(q,3,Color("4b95a0"))
 elif zone==1:
  holo_sign(ORIGIN+Vector2(11*32,12*32),"WILD SIGNAL",CYAN)
  holo_sign(ORIGIN+Vector2(16*32,2*32),"↑ CHROME",PINK)
  for x in [4,7,10]: server_rack(ORIGIN+Vector2(x*32,10*32))
  for x in [18,21,24]: server_rack(ORIGIN+Vector2(x*32,6*32))
  var drone=ORIGIN+Vector2(21*32+sin(clock*.6)*60,6*32+cos(clock*.8)*12)
  ellipse_shape(drone+Vector2(0,28),Vector2(12,3),Color(0,0,0,.20))
  panel(Rect2(drone-Vector2(11,5),Vector2(22,10)),Color("59798c"),CYAN)
  for dx in [-14,14]:
   draw_line(drone+Vector2(dx-5,-2),drone+Vector2(dx+5,-2),CYAN,2)
  glow(drone,13,CYAN,.08)
 else:
  holo_sign(ORIGIN+Vector2(11*32,3*32),"UPGRADE / 2096",PINK)
  holo_sign(ORIGIN+Vector2(18*32,12*32),"NIGHT MARKET",CYAN)
  for x in [3,9,16,25]: draw_lamp(ORIGIN+Vector2(x*32,9*32))
  # Vendor kiosk awning and landing pad.
  var q=ORIGIN+Vector2(17*32,11*32)
  panel(Rect2(q+Vector2(-8,-17),Vector2(49,13)),Color("624076"),PINK)
  draw_line(q+Vector2(-7,-14),q+Vector2(39,-14),PINK,2)
  var center=ORIGIN+Vector2(22*32,13*32)
  draw_arc(center,42,0,TAU,48,Color("3d617c"),2)
  label_at("H",center+Vector2(-9,10),29,Color("527990"))

func server_rack(q:Vector2):
 panel(Rect2(q,Vector2(25,35)),Color("25364b"),Color("4b6277"))
 for i in range(4):
  box(Rect2(q+Vector2(4,5+i*7),Vector2(15,4)),Color("0e2135"))
  draw_circle(q+Vector2(19,7+i*7),1,CYAN if int(clock*2+i)%3 else PINK)

func holo_sign(p:Vector2,title:String,c:Color):
 draw_line(p+Vector2(14,14),p+Vector2(14,28),Color("476079"),2)
 glow(p+Vector2(15,7),18,c,.045)
 var width=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+14
 panel(Rect2(p-Vector2(4,10),Vector2(width,22)),Color(.05,.14,.24,.88),Color(c.r,c.g,c.b,.6))
 label_at(title,p+Vector2(3,5),10,c)
 draw_line(p+Vector2(0,9),p+Vector2(width-9,9),Color(c.r,c.g,c.b,.25),1)

func draw_lamp(p:Vector2):
 draw_line(p+Vector2(15,0),p+Vector2(15,31),Color("4a667f"),3)
 draw_line(p+Vector2(15,0),p+Vector2(25,0),Color("66869b"),3)
 draw_line(p+Vector2(19,2),p+Vector2(26,2),CYAN,3)
 glow(p+Vector2(23,7),18,CYAN,.08)
 ellipse_shape(p+Vector2(24,32),Vector2(14,5),Color(.3,.82,.9,.08))

func draw_person(p:Vector2,c:Color,player:bool):
 # Keep readable directional animation; add luminous visor and jacket seams.
 super.draw_person(p,c,player)
 var q=p+Vector2(0,-8-(1 if walking and player and int(walk_phase)%2 else 0))
 if not player or facing!=Vector2i.UP:
  draw_line(q+Vector2(10,12),q+Vector2(23,12),CYAN,2)
  glow(q+Vector2(17,12),5,CYAN,.05)
 if player:
  draw_line(q+Vector2(11,24),q+Vector2(21,24),PINK,1)
  draw_circle(q+Vector2(7,25),2,CYAN)

func draw_foreground_details():
 if map_weather:
  for i in range(45):
   var x=fmod(i*137+clock*23,890)+35
   var y=fmod(i*79+clock*125,495)+112
   draw_line(Vector2(x,y),Vector2(x-3,y+9),Color(.56,.77,.88,.12),1)
 # Drifting signals are limited to gardens and remain subtle.
 for i in range(9):
  var q=ORIGIN+Vector2(19*32+sin(clock*.3+i)*73,11*32+cos(clock*.4+i*2)*48)
  if zone==0:
   draw_circle(q,1.3,Color(.5,1,.9,.45))

func draw_skyline(r:Rect2):
 box(r,Color("0d1429"))
 glow(r.position+Vector2(r.size.x*.70,r.size.y*.28),r.size.y*.34,PINK,.045)
 glow(r.position+Vector2(r.size.x*.35,r.size.y*.55),r.size.y*.40,CYAN,.025)
 for layer in range(2):
  for i in range(18):
   var width=37+i%3*12
   var h=75+(i*67+layer*113)%240
   var x=r.position.x+i*62-layer*27
   var y=r.end.y-h-(45 if layer==0 else 0)
   var c=Color("152039") if layer==0 else Color("1b2a40")
   box(Rect2(x,y,width,h+45),c)
   for yy in range(int(y)+12,int(r.end.y)-10,16):
    for xx in range(int(x)+7,int(x+width)-5,12):
     if (xx+yy)%5!=0: box(Rect2(xx,yy,3,5),Color("3c647e") if layer==0 else Color("488193"))
   if i%3==0: draw_line(Vector2(x,y),Vector2(x,y+h),Color("804b86") if i%2 else Color("2e7990"),2)

func draw_dialogue():
 buttons=[]
 panel(Rect2(43,430,874,179),Color("101f34"),CYAN.darkened(.35))
 paragraph(message,Vector2(65,461),825,18,WHITE)
 button(Rect2(733,558,162,34),"CONTINUAR [E]","continue")

func overlay(title:String,sub:String):
 buttons=[]
 box(Rect2(0,0,960,720),Color(.015,.025,.065,.94))
 panel(Rect2(30,32,900,651),Color("101d32"),Color("385570"))
 label_at(title,Vector2(56,80),29,WHITE)
 label_at(sub,Vector2(56,112),16,CYAN)
 button(Rect2(763,627,137,35),"VOLVER [Esc]","world")

func draw_party():
 overlay("EQUIPO / IMPLANTES",str(party.size())+" de 6 · mejoras: nivel 8 / 12 · Pikachu y Scyther: nivel 10")
 for i in range(party.size()):
  var p=party[i]
  var id=int(p.id)
  var x=53+(i%2)*432
  var y=133+int(i/2)*147
  panel(Rect2(x,y,415,136),Color("182b42"),CYAN.darkened(.4) if i==active else Color("2a425c"))
  sprite(id,Vector2(x+1,y+2),112)
  label_at(SPECIES[id][0],Vector2(x+118,y+24),20)
  label_at("Nv. "+str(p.level)+" · "+str(p.hp)+"/"+str(p.maxhp)+" PS",Vector2(x+118,y+46),14,CYAN)
  hp_bar(Rect2(x+118,y+56,276,5),p)
  button(Rect2(x+118,y+74,126,26),"LÍDER" if active==i else "AL FRENTE","lead:"+str(i))
  button(Rect2(x+254,y+74,140,26),"ESCUCHAR","cry:"+str(id))
  if EVOLUTIONS.has(id):
   var ready=p.level>=EV_LEVEL[id]
   if ready:
    var targets=EVOLUTIONS[id]
    for j in range(targets.size()):
     var target=targets[j]
     button(Rect2(x+118+j*141,y+105,135,24),"→ "+SPECIES[target][0],"evolve:"+str(i)+":"+str(target))
   else: label_at("Evolución disponible: Nv. "+str(EV_LEVEL[id]),Vector2(x+118,y+121),13,Color("8ca4bd"))
  else: label_at("CONFIGURACIÓN FINAL",Vector2(x+118,y+121),12,PINK)
 button(Rect2(54,627,290,35),"SIMULADOR +1 NIVEL / ₽80","train")
 label_at("Entrena al líder · saldo ₽"+str(money),Vector2(362,650),15,Color("91abc3"))

func draw_dex():
 overlay("CÓDEX / 20 FORMAS CIBERNÉTICAS",str(seen.size())+" vistas · "+str(captured.size())+" registradas · pulsa una ficha para explorar el diseño y escucharla")
 var ids=SPECIES.keys()
 for i in range(20):
  var id=ids[i]
  var x=54+(i%5)*173
  var y=135+int(i/5)*116
  var rect=Rect2(x,y,161,106)
  panel(rect,Color("192d44"),CYAN.darkened(.4) if id in captured else Color("2d405b"))
  sprite(id,Vector2(x+42,y-1),84)
  label_at(SPECIES[id][0],Vector2(x+9,y+94),13)
  label_at("%02d" % (i+1),Vector2(x+9,y+20),12,Color("82a1ba"))
  if id in captured: draw_circle(Vector2(x+147,y+13),3,CYAN)
  buttons.append({"rect":rect,"action":"inspect:"+str(id)})

func draw_detail():
 var id=dex_selected
 var row=catalog[id]
 overlay(SPECIES[id][0]+" / "+row.concept,"ARCHIVO DE DISEÑO · "+SPECIES[id][1]+(" · REGISTRADO" if id in captured else " · POR DESCUBRIR"))
 glow(Vector2(265,340),145,CYAN,.04)
 sprite(id,Vector2(69,153+sin(clock*1.5)*3),387)
 paragraph(row.description,Vector2(491,201),373,22,WHITE)
 var text_value="Forma final de esta familia."
 if EVOLUTIONS.has(id):
  text_value="Evoluciona al nivel "+str(EV_LEVEL[id])+" en "+SPECIES[EVOLUTIONS[id][0]][0]
  if EVOLUTIONS[id].size()>1: text_value+=" o "+SPECIES[EVOLUTIONS[id][1]][0]+". Tú eliges la ruta desde EQUIPO."
 paragraph(text_value,Vector2(491,345),366,18,Color("9dbbd0"))
 button(Rect2(491,472,351,43),"▶  ESCUCHAR VOZ SINTÉTICA","cry:"+str(id))
 button(Rect2(491,531,351,43),"VOLVER AL CÓDEX","dex")

func draw_archive():
 overlay("CAJA DIGITAL",str(archive.size())+" en almacenamiento · deposita o retira compañeros sin perder sus niveles")
 label_at("EQUIPO ACTIVO",Vector2(55,155),15,CYAN)
 label_at("ALMACENAMIENTO / "+str(archive_page+1),Vector2(500,155),15,PINK)
 for i in range(party.size()):
  var p=party[i]
  button(Rect2(53,174+i*62,409,49),SPECIES[int(p.id)][0]+" · Nv."+str(p.level)+"   → GUARDAR","deposit:"+str(i))
 for j in range(6):
  var i=archive_page*6+j
  if i>=archive.size(): break
  var p=archive[i]
  button(Rect2(494,174+j*62,409,49),"← "+SPECIES[int(p.id)][0]+" · Nv."+str(p.level),"withdraw:"+str(i))
 if archive_page>0: button(Rect2(496,562,180,35),"← ANTERIORES","archive_page:"+str(archive_page-1))
 if archive.size()>(archive_page+1)*6: button(Rect2(690,562,210,35),"SIGUIENTES →","archive_page:"+str(archive_page+1))

func draw_evolution():
 var t=clock-evolving.start
 draw_skyline(Rect2(0,0,960,720))
 box(Rect2(0,0,960,720),Color(.01,.02,.06,.7))
 var center=Vector2(480,348)
 glow(center,160,PINK,.075)
 for j in range(4):
  var r=130+j*26+sin(t*4+j)*5
  draw_arc(center,r,t*(1 if j%2 else -1),t*(1 if j%2 else -1)+TAU*.82,64,CYAN if j%2 else PINK,1.5)
 var id=evolving.old if t<1.5 else evolving.new
 sprite(id,Vector2(305,172),350)
 for i in range(32):
  var a=i*TAU/32+t
  var r=80+fmod(t*58+i*13,140)
  draw_circle(center+Vector2(cos(a),sin(a))*r,2,CYAN if i%2 else PINK)
 if t>1.3 and t<1.7: box(Rect2(0,0,960,720),Color(.75,1,1,(1-abs(t-1.5)*5)*.65))
 label_at("EVOLUCIÓN / SINCRONIZACIÓN",Vector2(266,87),22,CYAN)
 var title="RECONFIGURANDO IMPLANTES…" if t<1.5 else "¡"+SPECIES[int(evolving.new)][0]+"!"
 label_at(title,Vector2(250,605),28,WHITE)

func status_panel(r:Rect2,p:Dictionary,own:bool):
 panel(r,Color("102236"),Color("48667e"))
 label_at(SPECIES[int(p.id)][0],r.position+Vector2(16,29),22,WHITE)
 label_at("Nv. "+str(p.level),r.position+Vector2(r.size.x-80,28),18,CYAN)
 label_at("PS",r.position+Vector2(17,55),13,Color("9ab3c9"))
 var visual_hp=p.duplicate()
 visual_hp.hp=player_hp_visual if own else enemy_hp_visual
 hp_bar(Rect2(r.position+Vector2(47,43),Vector2(r.size.x-64,9)),visual_hp)
 if own:
  label_at(str(p.hp)+" / "+str(p.maxhp),r.position+Vector2(r.size.x-94,79),16,Color("aac2d5"))
  box(Rect2(r.position+Vector2(17,94),Vector2(r.size.x-34,3)),Color("213d53"))
  box(Rect2(r.position+Vector2(17,94),Vector2((r.size.x-34)*float(p.xp)/(p.level*12),3)),PINK)

func draw_battle():
 draw_skyline(Rect2(0,0,960,490))
 for i in range(12):
  var y=300+i*i*1.4
  draw_line(Vector2(0,y),Vector2(960,y),Color("244054"),1)
 for i in range(13): draw_line(Vector2(480+(i-6)*27,280),Vector2(480+(i-6)*170,490),Color("244054"),1)
 ellipse_shape(Vector2(716,291),Vector2(178,37),Color("13354a"))
 draw_arc(Vector2(716,287),132,0,TAU,64,CYAN.darkened(.4),1)
 ellipse_shape(Vector2(238,455),Vector2(192,31),Color("213247"))
 glow(Vector2(720,237),99,CYAN,.025)
 glow(Vector2(235,380),103,PINK,.02)
 draw_battle_pokemon()
 draw_attack_effects()
 status_panel(Rect2(38,80,378,78),enemy,false)
 status_panel(Rect2(522,345,395,107),party[active],true)
 box(Rect2(0,0,960,50),Color("091426"))
 label_at("COMBATE / "+("SEÑAL SALVAJE" if trainer=="" else trainer),Vector2(30,32),15,CYAN)
 box(Rect2(0,490,960,230),Color("0a1425"))
 panel(Rect2(24,511,464,181),Color("122239"),Color("385972"))
 paragraph(battle_text,Vector2(44,548),419,20,WHITE)
 if turn_locked:
  for i in range(3): draw_circle(Vector2(677+i*22,600+sin(clock*6+i)*4),3,CYAN)
  return
 if battle_menu=="moves":
  var move=MOVES[SPECIES[int(party[active].id)][1]]
  button(Rect2(510,513,425,49),"1  PLACAJE / CINÉTICO","attack")
  button(Rect2(510,575,425,49),"2  "+move[0]+" / "+move[1],"special")
  button(Rect2(510,637,425,49),"3  VOLVER","battle_back")
 elif battle_menu=="switch":
  for i in range(party.size()): button(Rect2(510,509+i*29,425,26),str(i+1)+"  "+SPECIES[int(party[i].id)][0]+" · "+str(party[i].hp)+" PS","switch:"+str(i))
  label_at("Esc: volver",Vector2(800,708),12,CYAN)
 else:
  button(Rect2(510,513,205,49),"1  LUCHAR","fight")
  button(Rect2(730,513,205,49),"2  BALL ×"+str(balls),"catch")
  button(Rect2(510,575,205,49),"3  POCIÓN ×"+str(potions),"battle_potion")
  button(Rect2(730,575,205,49),"4  EQUIPO","switch")
  button(Rect2(510,637,425,49),"5  HUIR","run")

func draw_attack_effects():
 if not attack_fx.is_empty() and attack_fx.kind in ["FANTASMA","ACERO"]:
  var t=fx_progress()
  if t<0 or t>1: return
  var source=Vector2(260,343) if attack_fx.own else Vector2(706,201)
  var target=Vector2(713,216) if attack_fx.own else Vector2(235,365)
  var q=source.lerp(target,clampf(t/.55,0,1))
  if attack_fx.kind=="FANTASMA":
   glow(q,29,PINK,.17)
   for i in range(7):
    var v=q+Vector2(cos(clock*8+i),sin(clock*8+i))*17
    draw_circle(v,5,Color("a477dd"))
  else:
   for i in range(3):
    var v=q+Vector2(i*9,0)
    draw_line(v-Vector2(8,18),v+Vector2(8,-18),CYAN,4)
 else: super.draw_attack_effects()

func test_cyber():
 assert(SPECIES.size()==20 and voices.size()==20 and catalog.size()==20)
 for id in SPECIES:
  assert(sprites.has(str(id)),"Missing sprite "+str(id))
  assert(voices[id]!=null and voices[id].get_length()>0.5)
 reset_game()
 action("starter:7")
 assert(party.size()==1 and party[0].id==7)
 for id in EVOLUTIONS:
  for target in EVOLUTIONS[id]:
   party=[mon(id,EV_LEVEL[id])]
   active=0
   var hp=party[0].hp
   apply_evolution(0,target)
   assert(party[0].id==target and party[0].hp>=hp and target in captured)
 party=[mon(7,8)]
 active=0
 await evolve(0,8,"world")
 assert(party[0].id==8 and mode=="world")
 party=[mon(1,5),mon(4,5),mon(7,5),mon(25,5),mon(92,5),mon(133,5)]
 archive=[]
 accept_capture(mon(137,5))
 assert(party.size()==6 and archive.size()==1)
 action("deposit:5")
 assert(party.size()==5 and archive.size()==2)
 action("withdraw:0")
 assert(party.size()==6 and party[5].id==137)
 assert(type_factor("NORMAL","FANTASMA")==0)
 assert(type_factor("FUEGO","ACERO")==2)
 zone=0
 pos=Vector2i(13,0)
 move_player(Vector2i.UP)
 assert(zone==1 and pos.y==14)
 assert(not walkable(Vector2i(0,3)))
 var backup=FileAccess.get_file_as_string(SAVE) if FileAccess.file_exists(SAVE) else ""
 money=777
 save_game()
 archive=[]
 money=1
 load_game()
 assert(money==777 and archive.size()==1 and party.size()==6)
 if backup!="":
  var f=FileAccess.open(SAVE,FileAccess.WRITE)
  f.store_string(backup)
 else: DirAccess.remove_absolute(SAVE)
 party=[mon(7,20)]
 active=0
 trainer_queue=[]
 start_battle(mon(4,3))
 await player_attack(true)
 assert(mode=="world" and party[0].id==8)
 party=[mon(1,5)]
 start_battle(mon(137,4))
 enemy.hp=1
 seed(8)
 await catch_mon()
 if mode=="battle": await catch_mon()
 assert(party.size()==2)
 print("CYBER PASS: 20 sprites, 20 cries, 12 evolution paths, animated evolution, storage, type chart, navigation, save/load, battle evolution, capture")
 get_tree().quit()

func player_attack(special:bool):
 cry(int(party[active].id))
 await super.player_attack(special)

func enemy_turn():
 cry(int(enemy.id))
 await super.enemy_turn()

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
 sprite(int(enemy.id),Vector2(593,86)+enemy_offset,265,false,enemy_alpha)
 sprite(int(party[active].id),Vector2(69,204)+own_offset,282,true,own_alpha)


func _exit_tree():
 if cry_player:
  cry_player.stop()
  cry_player.stream=null
 if audio:
  audio.stop()
  audio.stream=null
 oscillator=null
 voices.clear()
 sprites.clear()
