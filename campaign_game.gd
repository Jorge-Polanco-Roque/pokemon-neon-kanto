extends "res://story_game.gd"

const WARDENS = ["VIGÍA / CONTROL DE RAÍCES", "MANTIS / HORNO DE DATOS", "NEXUS / ÚLTIMA SINAPSIS"]
const WARDEN_IDS = [137,212,94]
const WARDEN_LEVELS = [7,10,13]
const RESTORED_IDS = [25,123,92]
const CORE_NAMES = ["SEMILLA", "BRASA", "MAREA"]
const CHOICE_LABELS = {"reactivate":"REACTIVADO", "release":"LIBERADO", "sacrifice":"SACRIFICADO"}
var wardens_down: Array = []
var core_fates: Dictionary = {}
var active_warden = -1
var pending_core = -1
var pending_fate = ""
var ending_id = ""
var radio_history: Array = []
var radio_last_zone = -1
var radio_seconds = 0.0
var radio_text = ""
var campaign_save_error = ""
var modern_view: SubViewport
var interior_view: SubViewport
var interior_id=""
var exterior_pos=Vector2i(13,12)
var air_quest=0
var air_dialogue=""
var air_drone_battle=false
const AIR_RELAY=Vector2i(14,9)
const AIR_OBJECTIVES=["Visita la clínica de Paleta (edificio oeste).","Consulta a Oak en el archivo (edificio este).","Recupera el regulador: patio central de Paleta, junto al relé.","Lleva el regulador y el filtro a la médica de la clínica.","Aire compartido: la clínica vuelve a respirar."]

func _ready():
 var bindings={"move_north":[KEY_W,KEY_UP],"move_south":[KEY_S,KEY_DOWN],"move_west":[KEY_A,KEY_LEFT],"move_east":[KEY_D,KEY_RIGHT]}
 for action_name in bindings:
  if not InputMap.has_action(action_name):
   InputMap.add_action(action_name)
   for code in bindings[action_name]:
    var event=InputEventKey.new()
    event.physical_keycode=code
    InputMap.action_add_event(action_name,event)
 super._ready()
 if DisplayServer.get_name()!="headless":
  modern_view=preload("res://scenes/world/modern_world.tscn").instantiate()
  add_child(modern_view)

func sync_modern_view():
 if interior_view:
  var interior_shown=interior_id!="" and mode not in ["battle","evolution","title","starter"]
  interior_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if interior_shown else SubViewport.UPDATE_DISABLED
  interior_view.simulation_enabled=interior_shown
  if interior_shown:
   interior_view.sync_player(visual_pos,Vector2(facing),walking)
   interior_view.set_restored(air_quest==4)
 if not modern_view: return
 var shown=interior_id=="" and mode not in ["title","starter","battle","evolution","ending","core_choice"]
 modern_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if shown else SubViewport.UPDATE_DISABLED
 modern_view.simulation_enabled=shown
 if not shown: return
 if mode=="prologue":
  modern_view.size=Vector2i(1280,568)
  modern_view.camera.size=lerpf(12.0,10.5,clampf(intro_elapsed/float(INTRO_SHOTS[intro_shot].seconds),0,1))
  modern_view.set_corruption(85 if prologue_phase==1 else 45)
  modern_view.build_prologue(prologue_phase,rescued_cores)
  modern_view.sync_player(story_visual,Vector2(facing),walking)
 else:
  modern_view.size=Vector2i(1280,696)
  modern_view.camera.size=14.5
  modern_view.set_corruption(corruption(zone))
  if modern_view.scene_key!="district:"+str(zone):
   var tiles=[]
   for y in range(16):
    var row=[]
    for x in range(28): row.append(terrain(x,y))
    tiles.append(row)
   modern_view.build_district(zone,tiles,buildings(),[TERMINALS[zone]],records,npc_position())
  modern_view.sync_player(visual_pos,Vector2(facing),walking)


func reset_game():
 if interior_view:
  interior_view.queue_free()
  interior_view=null
 interior_id=""
 air_quest=0
 air_dialogue=""
 air_drone_battle=false
 super.reset_game()
 wardens_down=[]
 core_fates={}
 active_warden=-1
 pending_core=-1
 pending_fate=""
 ending_id=""
 radio_history=[]
 radio_last_zone=-1

func transmit(text_value:String):
 radio_text=text_value
 radio_seconds=7.0
 if radio_history.is_empty() or radio_history.back()!=text_value:
  radio_history.append(text_value)
  if radio_history.size()>12: radio_history.pop_front()

func _process(delta):
 super._process(delta)
 sync_modern_view()
 radio_seconds=maxf(0,radio_seconds-delta)
 if mode=="world" and not party.is_empty() and zone!=radio_last_zone:
  radio_last_zone=zone
  transmit(["NEXUS: Ese bosque pertenece a mi red. Devuelve el núcleo.","NEXUS: Cada grado de calor es un recuerdo que puedes perder.","NEXUS: Has llegado a mi cuerpo. ¿Cuánto de ti sigue siendo tuyo?"][zone] if not str(zone) in core_fates else "OAK: El distrito recuerda tu decisión. Consulta la red con K.")

func corruption(district:int)->int:
 var fate=core_fates.get(str(district),"")
 return {"":85,"reactivate":35,"release":0,"sacrifice":70}.get(fate,85)

func biosphere_score()->int:
 var result=0
 for fate in core_fates.values(): result+=2 if fate=="release" else (1 if fate=="reactivate" else 0)
 return result

func ending_for_score(score:int)->String:
 return "rebirth" if score>=5 else ("sanctuary" if score>=2 else "ashes")

func action(a:String):
 if a=="air_close":
  mode="world"
  air_dialogue=""
  campaign_save_error=""
  return
 if a=="air_accept" and mode=="air_dialogue" and air_quest==0:
  air_quest=1
  air_dialogue="request"
  return
 if a=="air_heal" and mode=="air_dialogue" and interior_id=="clinic":
  heal_party()
  air_dialogue="healed"
  toast("PS, PP y estados restablecidos.")
  return
 if a=="air_filter" and mode=="air_dialogue" and interior_id=="archive" and air_quest==1:
  air_quest=2
  air_dialogue="filter"
  return
 if a=="air_install" and mode=="air_dialogue" and interior_id=="clinic" and air_quest==3:
  air_quest=4
  money+=250
  potions+=2
  if not save_game():
   air_quest=3
   money-=250
   potions-=2
   return
  air_dialogue="restored"
  return
 if a=="air_journal" and mode=="world":
  air_dialogue="objective"
  mode="air_dialogue"
  return
 if a=="interior_exit" and mode=="world" and interior_id!="":
  leave_interior()
  return
 if a=="campaign" and mode=="world": mode="campaign"
 elif a=="campaign_close" and mode=="campaign": mode="world"
 elif a=="ending_close" and mode=="ending": mode="world"
 elif a=="ending_review" and mode=="campaign" and ending_id!="": mode="ending"
 elif a.begins_with("fate:") and mode=="core_choice":
  var fate=a.get_slice(":",1)
  if fate in CHOICE_LABELS: pending_fate=fate
 elif a=="fate_cancel" and mode=="core_choice": pending_fate=""
 elif a=="fate_confirm" and mode=="core_choice": commit_fate()
 else: super.action(a)


func interact():
 if mode=="world" and interior_id!="":
  if pos.distance_to(Vector2i(8,10))<=1.5:
   leave_interior()
  elif pos.distance_to(Vector2i(8,5))<=1.5 or (pos+facing).distance_to(Vector2i(8,5))<=1.1:
   air_dialogue="clinic" if interior_id=="clinic" else "archive"
   mode="air_dialogue"
  else: toast("Acércate a la persona o a la salida y pulsa E.")
  return
 if mode=="world":
  if zone==0:
   for index in range(buildings().size()):
    var structure=buildings()[index][0]
    var door=Vector2i(structure.position.x+structure.size.x/2,structure.end.y-1)
    if pos.distance_to(door)<=1.1 or (pos+facing).distance_to(door)<=1.1:
     enter_interior("clinic" if index==0 else "archive")
     return
   if air_quest==2 and pos.distance_to(AIR_RELAY)<=1.5:
    air_drone_battle=true
    trainer_queue=[]
    start_battle(mon(137,5),"DRON RECAUDADOR")
    return
  if pos.distance_to(TERMINALS[zone])<=1.5 and zone in unlocked_nodes:
   contact_warden(zone)
   return
  # The old arena now hosts the final machine instead of a conventional leader.
  if zone==2:
   var arena=buildings()[1][0]
   var door=Vector2i(arena.position.x+arena.size.x/2,arena.end.y-1)
   if pos.distance_to(door)<=1.1 or (pos+facing).distance_to(door)<=1.1:
    contact_warden(2)
    return
  if (pos+facing).distance_to(npc_position())<=1.1:
   if zone==0:
    say("OAK / RESISTENCIA\nHackea el terminal de cada distrito y vuelve a conectarte para atraer a su guardián. Derrótalo y decide el destino del núcleo. K muestra la red, su corrupción y el objetivo actual.")
    return
   if zone==1:
    say("AZUL / RASTREADOR\nLos guardianes protegen los núcleos en orden: Neo Paleta, La Brecha y Cromo. Sus ataques no son iguales. MANTIS eleva el calor; NEXUS puede repararse. Lleva pociones y revisa tus implantes.")
    return
 super.interact()

func contact_warden(district:int):
 if district in wardens_down:
  if not str(district) in core_fates:
   pending_core=district
   pending_fate=""
   mode="core_choice"
  else:
   mode="campaign"
  return
 if not district in unlocked_nodes:
  say("CANAL CERRADO\nPrimero libera el terminal de este distrito. Después vuelve a conectarte al nodo o a la arena.")
  return
 if district>0 and not str(district-1) in core_fates:
  say("NEXUS / CORTAFUEGOS\nEl guardián anterior aún sostiene la red. Resuelve el núcleo de "+["Neo Paleta","La Brecha"][district-1]+" antes de continuar.")
  return
 if first_living()<0:
  say("OAK\nRecupera a tu equipo en casa o en la clínica antes de iniciar el asalto.")
  return
 active_warden=district
 trainer_queue=[]
 start_battle(mon(WARDEN_IDS[district],WARDEN_LEVELS[district]),"NEXUS / "+CORE_NAMES[district])
 transmit("NEXUS: Guardián "+CORE_NAMES[district]+" activado. Tu vínculo no es una autorización.")

func hack_press(index:int):
 var prior=unlocked_nodes.size()
 super.hack_press(index)
 if unlocked_nodes.size()>prior:
  transmit("NEXUS: Intrusión registrada. Vuelve al terminal si quieres enfrentarme.")

func start_battle(wild:Dictionary,opponent=""):
 if not opponent.begins_with("NEXUS /"): active_warden=-1
 super.start_battle(wild,opponent)

func combat_name(p:Dictionary)->String:
 if active_warden>=0 and p==enemy: return WARDENS[active_warden].get_slice(" /",0)
 return super.combat_name(p)

func damage(attacker:Dictionary,defender:Dictionary,power:int,kind:String)->int:
 var hit=super.damage(attacker,defender,power,kind)
 if hit>0 and resolving_enemy and active_warden<0 and trainer=="" and corruption(zone)>=70:
  hit=maxi(1,roundi(hit*1.15))
 return hit

func move_player(direction:Vector2i):
 if interior_id!="":
  facing=direction
  step_cool=.14
  var next=pos+direction
  if next==Vector2i(8,11):
   leave_interior()
  elif interior_walkable(next): pos=next
  return
 var previous=steps
 super.move_player(direction)
 if steps!=previous and mode=="world" and core_fates.get(str(zone),"")=="release" and steps%8==0 and not party.is_empty():
  party[active].hp=mini(party[active].maxhp,party[active].hp+2)

func enemy_turn():
 var boss=active_warden
 await super.enemy_turn()
 if mode!="battle" or active_warden!=boss or boss<0: return
 if boss==1:
  thermal=mini(100,thermal+15)
  battle_text+="\nMANTIS inyecta +15 de calor."
 elif boss==2 and enemy_cycles%2==0 and enemy.hp>0:
  var repair=maxi(1,roundi(enemy.maxhp*.12))
  enemy.hp=mini(enemy.maxhp,enemy.hp+repair)
  battle_text+="\nNEXUS repara "+str(repair)+" PS."

func end_battle():
 super.end_battle()
 air_drone_battle=false
 active_warden=-1

func win_battle():
 if air_drone_battle:
  air_drone_battle=false
  await super.win_battle()
  air_quest=3
  mode="world"
  say("REGULADOR RECUPERADO\nEl dron soltó la pieza. Vuelve a la médica: el filtro de Oak ya puede sostener el aire de la clínica.")
  return
 if active_warden<0:
  await super.win_battle()
  return
 var boss=active_warden
 battle_text=WARDENS[boss].get_slice(" /",0)+" desconectado.\n"+award_battle_experience()
 await get_tree().create_timer(.9).timeout
 await evolve_after_victory()
 complete_warden(boss)

func complete_warden(boss:int):
 if boss<0 or boss>2 or boss in wardens_down: return
 wardens_down.append(boss)
 end_battle()
 pending_core=boss
 pending_fate=""
 mode="core_choice"
 # Saving the pending choice prevents re-fighting a defeated machine after closing.
 save_game()
 notice_time=0
 transmit("OAK: El núcleo "+CORE_NAMES[boss]+" está libre. Lee las consecuencias antes de decidir.")

func commit_fate():
 if pending_core<0 or not pending_core in wardens_down or str(pending_core) in core_fates or not pending_fate in CHOICE_LABELS: return
 var checkpoint={"party":party.duplicate(true),"archive":archive.duplicate(true),"captured":captured.duplicate(),"seen":seen.duplicate(),"money":money,"balls":balls,"rival":rival_done,"badge":badge,"fates":core_fates.duplicate(),"ending":ending_id,"radio":radio_history.duplicate(),"pending":pending_core,"fate":pending_fate}
 var key=str(pending_core)
 core_fates[key]=pending_fate
 if pending_fate=="reactivate":
  var id=RESTORED_IDS[pending_core]
  accept_capture(mon(id,WARDEN_LEVELS[pending_core]))
  if not id in seen: seen.append(id)
  if not id in captured: captured.append(id)
 elif pending_fate=="sacrifice":
  money+=500
  balls+=5
 if pending_core==0: rival_done=true
 if core_fates.size()==3:
  badge=true
  ending_id=ending_for_score(biosphere_score())
  mode="ending"
 else: mode="world"
 transmit("OAK: Núcleo "+CORE_NAMES[pending_core]+" "+CHOICE_LABELS[pending_fate].to_lower()+". La ciudad conservará esa decisión.")
 pending_core=-1
 pending_fate=""
 if not save_game():
  party=checkpoint.party
  archive=checkpoint.archive
  captured=checkpoint.captured
  seen=checkpoint.seen
  money=checkpoint.money
  balls=checkpoint.balls
  rival_done=checkpoint.rival
  badge=checkpoint.badge
  core_fates=checkpoint.fates
  ending_id=checkpoint.ending
  radio_history=checkpoint.radio
  pending_core=checkpoint.pending
  pending_fate=checkpoint.fate
  radio_seconds=0
  mode="core_choice"
 notice_time=0

func save_game():
 campaign_save_error=""
 if party.is_empty(): return false
 var data={"version":7,"party":party,"archive":archive,"active":active,"zone":zone,"x":exterior_pos.x if interior_id!="" else pos.x,"y":exterior_pos.y if interior_id!="" else pos.y,"balls":balls,"potions":potions,"money":money,"rival":rival_done,"badge":badge,"seen":seen,"captured":captured,"unlocked_nodes":unlocked_nodes,
  "story":{"prologue_complete":prologue_complete,"prologue_skipped":prologue_skipped,"found_records":found_records},
  "exploration":{"air_quest":air_quest,"interior":interior_id,"room_x":pos.x,"room_y":pos.y},
  "campaign":{"wardens_down":wardens_down,"core_fates":core_fates,"ending":ending_id,"radio_history":radio_history}}
 var target=ProjectSettings.globalize_path(SAVE)
 var temporary=target+".tmp"
 var file=FileAccess.open(temporary,FileAccess.WRITE)
 if not file:
  campaign_save_error="No se pudo guardar. Se conserva la partida anterior; vuelve a intentarlo."
  toast(campaign_save_error)
  return false
 file.store_string(JSON.stringify(data))
 file.flush()
 var error=file.get_error()
 file.close()
 if error!=OK or DirAccess.rename_absolute(temporary,target)!=OK:
  campaign_save_error="No se pudo reemplazar la partida. No se aplicó la recompensa; vuelve a intentarlo."
  toast(campaign_save_error)
  return false
 save_exists=true
 toast("SINCRONIZACIÓN COMPLETA · partida guardada")
 return true

func load_game():
 super.load_game()
 if mode!="world": return
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 if interior_view:
  interior_view.queue_free()
  interior_view=null
 interior_id=""
 air_drone_battle=false
 var exploration=data.get("exploration",{})
 air_quest=clampi(int(exploration.get("air_quest",0)),0,4)
 if exploration.get("interior","") in ["clinic","archive"]:
  enter_interior(exploration.interior)
  var room_pos=Vector2i(int(exploration.get("room_x",8)),int(exploration.get("room_y",9)))
  if interior_walkable(room_pos):
   pos=room_pos
   visual_pos=Vector2(pos)
 var campaign=data.get("campaign",{})
 wardens_down=[]
 core_fates={}
 for value in campaign.get("wardens_down",[]):
  var index=int(value)
  if index>=0 and index<=2 and not index in wardens_down: wardens_down.append(index)
 for key in campaign.get("core_fates",{}):
  if key in ["0","1","2"] and campaign.core_fates[key] in CHOICE_LABELS and int(key) in wardens_down: core_fates[key]=campaign.core_fates[key]
 ending_id=ending_for_score(biosphere_score()) if core_fates.size()==3 else ""
 radio_history=campaign.get("radio_history",[])
 active_warden=-1
 pending_core=-1
 pending_fate=""
 radio_last_zone=-1
 for index in wardens_down:
  if not str(index) in core_fates:
   pending_core=index
   mode="core_choice"
   break

func _draw():
 super._draw()
 if mode=="campaign": draw_campaign()
 elif mode=="core_choice": draw_core_choice()
 elif mode=="ending": draw_ending()
 elif mode=="air_dialogue": draw_air_dialogue()

func draw_title():
 super.draw_title()
 box(Rect2(55,670,450,30),Color("0b1324"))
 label_at("EDICIÓN 0.9 / LA DEUDA DEL AIRE",Vector2(60,690),12,Color("8da7bb"))

func draw_world():
 if interior_id!="":
  draw_interior()
  return
 if not modern_view:
  super.draw_world()
  return
 box(Rect2(0,0,960,720),Color("08111c"))
 var names=["Paleta / Refugio 07","La Brecha","Distrito Cromo"]
 label_at("NEÓN KANTO / LA DEUDA DEL AIRE",Vector2(28,29),12,CYAN)
 label_at(names[zone],Vector2(27,73),30)
 label_at("CORRUPCIÓN "+str(corruption(zone))+"%   /   ₽"+str(money),Vector2(638,70),15,PINK)
 draw_texture_rect(modern_view.get_texture(),Rect2(0,97,960,522),false)
 draw_minimap()
 label_at("E  INTERACTUAR    WASD / FLECHAS  MOVER",Vector2(28,648),12,Color("94bac9"))
 button(Rect2(28,666,117,37),"EQUIPO [P]","party")
 button(Rect2(154,666,108,37),"BOLSA [B]","bag")
 button(Rect2(271,666,107,37),"CÓDEX [N]","dex")
 button(Rect2(387,666,108,37),"IMPLANTES","workshop")
 button(Rect2(504,666,94,37),"RED [K]","campaign")
 button(Rect2(607,666,100,37),"ARCHIVOS","journal")
 button(Rect2(716,666,93,37),"MISIÓN","air_journal")
 button(Rect2(818,666,114,37),"GUARDAR","save")
 var hint="Paleta: clínica oeste / archivo este / MISIÓN" if zone==0 and air_quest<4 else "Libera el terminal y enfrenta a su guardián."
 if zone in wardens_down: hint="Decisión: "+CHOICE_LABELS.get(core_fates.get(str(zone),""),"PENDIENTE")
 label_at(hint,Vector2(473,648),13,CYAN)
 if radio_seconds>0 and mode=="world":
  panel(Rect2(296,4,637,43),Color("172333"),PINK.darkened(.4))
  paragraph(radio_text,Vector2(307,21),615,11,Color("efb1c5"))

func draw_prologue():
 buttons=[]
 box(Rect2(0,0,960,720),Color("050910"))
 var shot=INTRO_SHOTS[mini(intro_shot,INTRO_SHOTS.size()-1)]
 if modern_view:
  draw_texture_rect(modern_view.get_texture(),Rect2(0,90,960,426),false)
 else:
  draw_skyline(Rect2(0,90,960,426))
 var fade=maxf(1.0-intro_elapsed/.8,1.0-(float(shot.seconds)-intro_elapsed)/.8)
 box(Rect2(0,90,960,426),Color(0,0,0,clampf(fade,0,1)))
 label_at("LA DEUDA DEL AIRE",Vector2(40,40),14,Color("92acbd"))
 label_at(shot.title,Vector2(40,73),22,WHITE)
 label_at(shot.voice,Vector2(58,553),14,CYAN)
 paragraph(shot.text,Vector2(58,587),840,22,WHITE)
 label_at("CINEMÁTICA  /  "+str(mini(intro_shot+1,7))+" DE 7",Vector2(40,697),12,Color("92acbd"))
 button(Rect2(379,672,230,33),"REANUDAR [ESPACIO]" if intro_paused else "PAUSA [ESPACIO]","story_pause")
 button(Rect2(622,672,300,33),"ELEGIR POKÉMON [ESC]","story_skip")


func draw_battle():
 super.draw_battle()
 label_at(CombatRules.STATUS_NAMES.get(enemy.get("status",""),"ESTABLE"),Vector2(280,171),12,PINK)
 label_at(CombatRules.STATUS_NAMES.get(party[active].get("status",""),"ESTABLE"),Vector2(800,336),12,CYAN)
 if active_warden>=0:
  box(Rect2(47,89,303,30),Color("112333"))
  label_at(WARDENS[active_warden].get_slice(" /",0),Vector2(49,109),22,PINK)
  label_at(["ESCUDO INICIAL · primer golpe −25%","INYECCIÓN TÉRMICA · +15 calor por turno","AUTORREPARACIÓN · 12% PS cada 2 turnos"][active_warden],Vector2(40,203),12,CYAN)
 elif trainer=="" and corruption(zone)>=70:
  label_at("RED CORRUPTA · daño rival +15%",Vector2(40,203),12,PINK)

func draw_campaign():
 overlay("RED / LA ÚLTIMA SINAPSIS","BIOSFERA RESTAURADA  "+str(biosphere_score())+" / 6 · Tres núcleos, una decisión por distrito")
 buttons=[]
 for i in range(3):
  var x=53+i*286
  panel(Rect2(x,139,269,237),Color("172b3d"),CYAN if corruption(i)==0 else PINK.darkened(.4))
  label_at(CORE_NAMES[i],Vector2(x+16,170),22,CYAN)
  label_at(["Neo Paleta","La Brecha","Distrito Cromo"][i],Vector2(x+16,198),15)
  label_at("CORRUPCIÓN  "+str(corruption(i))+"%",Vector2(x+16,236),15,PINK)
  var state="Hackea el terminal."
  if i in unlocked_nodes: state="Vuelve al nodo para combatir."
  if i>0 and not str(i-1) in core_fates: state="Resuelve el núcleo anterior."
  if i in wardens_down: state="Guardián derrotado."
  if str(i) in core_fates: state="Núcleo "+CHOICE_LABELS[core_fates[str(i)]].to_lower()+"."
  paragraph(state,Vector2(x+16,272),237,17,WHITE)
  label_at(WARDENS[i].get_slice(" /",0),Vector2(x+16,350),13,Color("8fadc1"))
 label_at("ÚLTIMAS TRANSMISIONES",Vector2(54,411),14,PINK)
 var recent=radio_history.slice(maxi(0,radio_history.size()-3))
 for i in range(recent.size()): paragraph(recent[i],Vector2(55,445+i*49),845,14,Color("bbccd8"))
 if ending_id!="": button(Rect2(55,610,378,43),"VOLVER A VER EL DESENLACE","ending_review")
 button(Rect2(449,610,449,43),"VOLVER [K / ESC]","campaign_close")

func draw_core_choice():
 box(Rect2(0,0,960,720),Color("080f20"))
 buttons=[]
 label_at("ARCHIVO VIVO / DECISIÓN PERMANENTE",Vector2(43,43),14,PINK)
 label_at("¿Qué será del núcleo "+CORE_NAMES[maxi(0,pending_core)]+"?",Vector2(43,89),30)
 paragraph("Has detenido a su guardián. Puedes devolverle un cuerpo, dejar que restaure el distrito o consumir su energía. La decisión se guarda al confirmarla.",Vector2(44,128),861,18,Color("b3c9d7"))
 var keys=["reactivate","release","sacrifice"]
 var titles=["REACTIVAR","LIBERAR","SACRIFICAR"]
 var descriptions=["Despierta a "+SPECIES[RESTORED_IDS[maxi(0,pending_core)]][0]+" como compañero. Si el equipo está lleno, irá a la caja.\n\nBiosfera +1. Corrupción baja a 35%.","Devuelve la memoria al ecosistema. No recibes compañero.\n\nBiosfera +2. Corrupción 0%. Caminar 8 pasos en el distrito recupera 2 PS del líder.","Consume el núcleo para obtener ₽500 y 5 Balls. Esa memoria no podrá regresar.\n\nBiosfera +0. La corrupción queda en 70%; los encuentros conservan +15% de daño."]
 for i in range(3):
  var x=43+i*294
  panel(Rect2(x,211,279,340),Color("16283c"),CYAN if pending_fate==keys[i] else Color("3e5368"))
  label_at(titles[i],Vector2(x+17,245),21,CYAN if i<2 else PINK)
  paragraph(descriptions[i],Vector2(x+17,287),244,17,WHITE)
  button(Rect2(x+16,490,247,42),str(i+1)+"  ELEGIR","fate:"+keys[i])
 if pending_fate!="":
  label_at("SELECCIÓN: "+CHOICE_LABELS[pending_fate]+" · no se puede deshacer en esta partida",Vector2(44,586),15,PINK)
  button(Rect2(44,616,330,48),"CAMBIAR DE IDEA [ESC]","fate_cancel")
  button(Rect2(389,616,526,48),"CONFIRMAR Y GUARDAR","fate_confirm")
 else: label_at("Lee las consecuencias y elige una opción. Todavía no has decidido.",Vector2(45,600),17,CYAN)

 if campaign_save_error!="": label_at(campaign_save_error,Vector2(44,698),13,PINK)

func draw_ending():
 var score=biosphere_score()
 var color=Color("91dfb1") if ending_id=="rebirth" else (CYAN if ending_id=="sanctuary" else PINK)
 draw_skyline(Rect2(0,0,960,720))
 box(Rect2(0,0,960,720),Color(.025,.04,.065,.85))
 buttons=[]
 label_at("LA ÚLTIMA SINAPSIS / DESENLACE",Vector2(60,68),15,color)
 label_at({"rebirth":"Un bosque sin dueño","sanctuary":"El refugio de las voces","ashes":"La ciudad de las cenizas"}.get(ending_id,"La última sinapsis"),Vector2(59,132),36,color)
 var text_value={"rebirth":"NEXUS pierde el control de una biosfera que ya no cabe en sus órdenes. Las memorias liberadas germinan entre el metal. No has recuperado el mundo de Sena: has permitido que nazca otro, sin dueño.","sanctuary":"NEXUS calla, pero la ciudad conserva sus cicatrices. Algunas memorias regresan al ecosistema; otras caminan junto a ti. La vida vuelve despacio, protegida por vínculos que ninguna red puede imponer.","ashes":"Has silenciado a NEXUS consumiendo casi todas las memorias que custodiaba. La ciudad tiene energía y las calles siguen iluminadas. Bajo el neón, sin embargo, ya no queda suficiente vida para reconstruir el bosque."}.get(ending_id,"")
 paragraph(text_value,Vector2(62,214),822,23,WHITE)
 label_at("BIOSFERA RESTAURADA  "+str(score)+" / 6",Vector2(62,398),18,color)
 for i in range(3):
  label_at(CORE_NAMES[i]+"  /  "+CHOICE_LABELS.get(core_fates.get(str(i),""),"PENDIENTE"),Vector2(63,449+i*37),17,Color("bccedb"))
 label_at("Partida guardada. Puedes seguir explorando y consultarlo en RED [K].",Vector2(62,586),17,color)
 button(Rect2(61,623,839,49),"VOLVER A LA CIUDAD [ESC]","ending_close")

func ground_origin(id:int,anchor:Vector2,size:float,mirrored:bool)->Vector2:
 if mode=="battle" and active_warden>=0 and not mirrored and id==int(enemy.id):
  return anchor-Vector2(.5,.95)*size
 return super.ground_origin(id,anchor,size,mirrored)

func sprite(id:int,at:Vector2,size:float,back=false,alpha=1.0):
 if mode=="battle" and active_warden>=0 and not back and id==int(enemy.id):
  draw_machine(active_warden,at,size,alpha)
 else: super.sprite(id,at,size,back,alpha)

func draw_machine(index:int,at:Vector2,size:float,alpha:float):
 draw_set_transform(at,0,Vector2.ONE*size/240.0)
 var metal=Color(Color("526a80"),alpha)
 var edge=Color(Color("a4bdc8"),alpha)
 var dark=Color(Color("14233a"),alpha)
 var light=Color(PINK if index!=1 else Color("ffc68f"),alpha)
 var cyan=Color(CYAN,alpha)
 if index==0:
  # Tripod surveillance reactor: a single optical core and three articulated legs.
  for i in range(3):
   var side=i-1
   var hip=Vector2(120+side*27,130)
   var knee=Vector2(120+side*61,181)
   var foot=Vector2(120+side*81,228)
   draw_line(hip,knee,metal,13,true)
   draw_line(knee,foot,edge,8,true)
   draw_circle(knee,10,dark)
   draw_circle(knee,5,cyan)
   draw_line(foot-Vector2(12,0),foot+Vector2(12,0),metal,7,true)
  draw_circle(Vector2(120,95),62,dark)
  draw_arc(Vector2(120,95),59,0,TAU,64,metal,8,true)
  draw_arc(Vector2(120,95),48,clock*.4,clock*.4+PI*1.6,64,cyan,3,true)
  draw_circle(Vector2(120,95),29,light)
  draw_circle(Vector2(120+sin(clock)*9,95),14,dark)
  draw_circle(Vector2(127+sin(clock)*9,90),4,edge)
  for side in [-1,1]:
   draw_line(Vector2(120+side*48,59),Vector2(120+side*80,22),metal,6,true)
   draw_circle(Vector2(120+side*80,22),5,light)
 elif index==1:
  # Industrial cutter, with heat vents and independently oscillating blade arms.
  for side in [-1,1]:
   var hip=Vector2(120+side*24,157)
   var knee=Vector2(120+side*43,195)
   var foot=Vector2(120+side*54,225)
   draw_line(hip,knee,metal,17,true)
   draw_line(knee,foot,edge,10,true)
   draw_line(foot-Vector2(13,0),foot+Vector2(13,0),dark,9,true)
   var elbow=Vector2(120+side*79,109+sin(clock*2)*4)
   draw_line(Vector2(120+side*30,79),elbow,metal,12,true)
   draw_line(elbow,Vector2(120+side*92,52),edge,8,true)
   draw_line(Vector2(120+side*92,52),Vector2(120+side*68,12),light,7,true)
   draw_line(Vector2(120+side*92,52),Vector2(120+side*112,30),cyan,5,true)
   draw_circle(elbow,8,dark)
   draw_circle(elbow,4,light)
  draw_colored_polygon(PackedVector2Array([Vector2(90,70),Vector2(150,70),Vector2(159,149),Vector2(120,173),Vector2(81,149)]),dark)
  for side in [-1,1]: draw_line(Vector2(120+side*28,80),Vector2(120+side*33,141),metal,10,true)
  for i in range(5): draw_line(Vector2(100,91+i*11),Vector2(140,91+i*11),light,4,true)
  draw_colored_polygon(PackedVector2Array([Vector2(98,35),Vector2(142,35),Vector2(151,61),Vector2(120,79),Vector2(89,61)]),metal)
  draw_line(Vector2(102,55),Vector2(138,55),light,6,true)
 else:
  # NEXUS core: an orbiting polyhedron tethered to its projection pedestal.
  var center=Vector2(120,104+sin(clock*1.5)*4)
  for i in range(3):
   draw_arc(center,68+i*12,clock*(.3+i*.13)+i,clock*(.3+i*.13)+i+PI*1.6,64,cyan if i%2 else metal,2,true)
  var vertices=PackedVector2Array([center+Vector2(0,-65),center+Vector2(52,-12),center+Vector2(35,46),center+Vector2(0,68),center+Vector2(-35,46),center+Vector2(-52,-12)])
  draw_colored_polygon(vertices,dark)
  for i in range(vertices.size()):
   draw_line(vertices[i],vertices[(i+1)%vertices.size()],edge,3,true)
   draw_line(vertices[i],center,cyan,2,true)
  draw_circle(center,19,light)
  draw_circle(center,9,dark)
  for i in range(4):
   var angle=clock*.7+i*TAU/4
   var q=center+Vector2(cos(angle)*99,sin(angle)*63)
   draw_line(center,q,Color(cyan,.3*alpha),1,true)
   draw_circle(q,9,metal)
   draw_circle(q,4,light)
  for y in range(181,220,8): draw_line(Vector2(115,y),Vector2(125,y),cyan,2,true)
  draw_line(Vector2(91,228),Vector2(149,228),metal,7,true)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)


func draw_minimap():
 panel(Rect2(808,108,140,96),Color(.025,.055,.085,.91),Color("496476"))
 for b in buildings():
  var r:Rect2i=b[0]
  box(Rect2(Vector2(817,116)+Vector2(r.position)*4.2,Vector2(r.size)*4.2),Color("567581"))
 draw_line(Vector2(873,116),Vector2(873,180),Color("4a6976"),3)
 var node=Vector2(817,116)+Vector2(TERMINALS[zone])*4.2
 draw_circle(node,3,PINK)
 draw_circle(Vector2(817,116)+Vector2(pos)*4.2,3,CYAN)
 label_at("N ↑   /   E · conectar",Vector2(819,195),10,Color("adc5cd"))


func interior_walkable(cell:Vector2i)->bool:
 if cell.x<2 or cell.x>14 or cell.y<2 or cell.y>10: return false
 if cell==Vector2i(8,5): return false
 for x in [3,11]:
  for y in [3,6]:
   if Rect2i(x,y,2,2).has_point(cell): return false
 if Rect2i(7,3,3,1).has_point(cell): return false
 return true

func enter_interior(room:String):
 if interior_id=="": exterior_pos=pos
 interior_id=room
 pos=Vector2i(8,9)
 visual_pos=Vector2(pos)
 facing=Vector2i.UP
 if interior_view: interior_view.queue_free()
 interior_view=null
 if DisplayServer.get_name()!="headless":
  interior_view=load("res://scenes/world/"+room+".tscn").instantiate()
  add_child(interior_view)
 mode="world"
 encounter_grace=8

func leave_interior():
 interior_id=""
 pos=exterior_pos
 visual_pos=Vector2(pos)
 facing=Vector2i.DOWN
 if interior_view:
  interior_view.queue_free()
  interior_view=null
 mode="world"
 encounter_grace=8

func draw_interior():
 box(Rect2(0,0,960,720),Color("08111c"))
 label_at("PALETA / REFUGIO 07",Vector2(28,30),13,CYAN)
 label_at("Clínica / Aire común" if interior_id=="clinic" else "Oak / Archivo vivo",Vector2(28,76),30)
 if interior_view: draw_texture_rect(interior_view.get_texture(),Rect2(0,97,960,522),false)
 paragraph(AIR_OBJECTIVES[air_quest],Vector2(28,644),900,17,CYAN)
 button(Rect2(28,671,211,34),"EQUIPO [P]","party")
 button(Rect2(250,671,211,34),"MISIÓN","air_journal")
 button(Rect2(472,671,211,34),"GUARDAR [F5]","save")
 button(Rect2(694,671,238,34),"SALIR A PALETA","interior_exit")

func draw_air_dialogue():
 draw_world()
 box(Rect2(0,0,960,720),Color(0,0,0,.78))
 panel(Rect2(110,155,740,432),Color("142738"),CYAN)
 label_at("AIRE PARA LOS QUE QUEDAN",Vector2(141,203),25,CYAN)
 var text_value=AIR_OBJECTIVES[air_quest]
 if air_dialogue!="objective":
  if interior_id=="clinic":
   text_value=["DRA. SENA: Lía sostuvo esta clínica cuando NEXUS nos borró. Ahora el filtro se está agotando. Oak conserva una membrana viva. ¿Nos ayudas a que su sacrificio siga dando aire?","SENA: Oak está en el edificio al este. Pregúntale por la membrana viva. Tu equipo puede descansar aquí antes de salir.","SENA: El filtro necesita un regulador. Un dron recauda piezas en el patio central. Oak marcó el relé para ti.","SENA: Trajiste ambas piezas. Podemos devolver el aire a toda la sala. Instalar el filtro completa la misión: ₽250 y dos pociones.","SENA: Escucha… los respiradores ya no están forzados. El nombre de Lía queda en el registro de quienes mantuvieron viva esta clínica."][air_quest]
  else:
   text_value=["OAK: Sena necesita manos en la clínica del oeste. Ve a escucharla. Algunas reparaciones importan más que vencer a NEXUS.","OAK: Esta membrana se cultivó a partir de una semilla de Lía. Puedo entregártela, pero falta un regulador. El dron del patio central lo confiscó: tendrás que desactivarlo.","OAK: Ya llevas la membrana. Busca el regulador en el patio central, cerca de (14,9). Pulsa E junto al relé; prepara a tu compañero antes de combatir.","OAK: El regulador está intacto. Vuelve con Sena; puedes llevar oxígeno donde NEXUS solo ve una deuda.","OAK: Guardaré una copia del registro. Mientras recordemos a Lía por lo que hizo, la red no podrá reducirla a una cifra."][air_quest]
 if air_dialogue=="healed": text_value="SENA: Tu equipo ya recuperó todos sus PS y PP. También eliminé las quemaduras, el sueño y la parálisis.\n"+AIR_OBJECTIVES[air_quest]
 paragraph(text_value,Vector2(141,249),675,21,WHITE)
 if campaign_save_error!="": paragraph(campaign_save_error,Vector2(141,390),675,13,PINK)
 buttons=[]
 var next_y=420
 if air_dialogue!="objective":
  if interior_id=="clinic":
   if air_quest==0: button(Rect2(140,next_y,678,36),"AYUDAR A LA CLÍNICA","air_accept"); next_y+=43
   elif air_quest==3: button(Rect2(140,next_y,678,36),"INSTALAR FILTRO Y GUARDAR","air_install"); next_y+=43
   button(Rect2(140,next_y,678,36),"RECUPERAR EQUIPO · GRATIS","air_heal")
   next_y+=43
  elif air_quest==1:
   button(Rect2(140,next_y,678,36),"RECIBIR MEMBRANA Y LOCALIZAR EL DRON","air_filter")
   next_y+=43
 button(Rect2(140,next_y,678,36),"VOLVER","air_close")

func _unhandled_input(event):
 if mode=="air_dialogue":
  if event is InputEventKey and event.pressed and not event.echo:
   if event.physical_keycode==KEY_ESCAPE: action("air_close")
   elif event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_6:
    var index=event.physical_keycode-KEY_1
    if index<buttons.size(): action(buttons[index].action)
  elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
   for b in buttons:
    if b.rect.has_point(get_global_mouse_position()): action(b.action); return
  return
 if event is InputEventKey and event.pressed and not event.echo:
  if mode=="core_choice" and event.physical_keycode==KEY_ESCAPE:
   pending_fate=""
   return
  if event.physical_keycode==KEY_K and mode=="world": action("campaign"); return
  if event.physical_keycode in [KEY_K,KEY_ESCAPE] and mode=="campaign": mode="world"; return
  if event.physical_keycode==KEY_ESCAPE and mode=="ending": mode="world"; return
 super._unhandled_input(event)
