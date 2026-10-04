extends "res://scripts/ui/team_screen.gd"
## Special sequences keep their controller timers, rewards and confirmation rules.
const MODES=["starter","hacking","evolution","core_choice","ending"]
const STARTERS=[1,4,7,25]
const FATES=["reactivate","release","sacrifice"]
var progress:ProgressBar
var timer_label:Label
var evolution_portrait
var last_mode=""
func sync_frame():
 visible=game.mode in MODES
 if not visible: signature=""; last_mode=""; return
 var revealing=game.clock<game.hack_reveal_until
 var next=JSON.stringify([game.mode,game.zone,game.hacking_sequence,game.hacking_input,game.hack_error,revealing,game.pending_core,game.pending_fate,game.campaign_save_error,game.core_fates,game.ending_id,game.evolving,shell.settings.values.ui_scale,get_viewport().get_visible_rect().size])
 if next!=signature:
  signature=next
  if last_mode!=game.mode: scroll.scroll_vertical=0
  last_mode=game.mode
  rebuild()
 if game.mode=="hacking" and is_instance_valid(timer_label):
  timer_label.text="LECTURA · %d s"%maxi(0,ceili(game.hack_reveal_until-game.clock)) if revealing else (game.hack_error if game.hack_error!="" else "SEÑAL ESTABLE · %d/%d"%[game.hacking_input.size(),game.hacking_sequence.size()])
 if game.mode=="evolution" and not game.evolving.is_empty() and is_instance_valid(progress):
  var elapsed=maxf(0,game.clock-game.evolving.start)
  progress.value=minf(100,elapsed/3.0*100)
  var id=int(game.evolving.old if elapsed<1.5 else game.evolving.new)
  if evolution_portrait.species_id!=id:
   evolution_portrait.species_id=id
   evolution_portrait.queue_redraw()
  timer_label.text="RECONFIGURANDO IMPLANTES…" if elapsed<1.5 else "¡"+game.SPECIES[id][0]+"!"
func dispatch(action_id:String):
 if game.mode not in MODES or game.mode=="evolution": return
 if not buttons_by_action.has(action_id) or buttons_by_action[action_id].disabled: return
 game.action(action_id)
func portrait(parent,id:int,height:float):
 var item=preload("res://scripts/ui/creature_portrait.gd").new()
 item.game=game
 item.species_id=id
 item.custom_minimum_size.y=height*shell.settings.values.ui_scale
 parent.add_child(item)
 return item
func build_contents():
 progress=null
 timer_label=null
 evolution_portrait=null
 match game.mode:
  "starter": build_starter()
  "hacking": build_hacking()
  "evolution": build_evolution()
  "core_choice": build_choice()
  "ending": build_ending()
func build_starter():
 note(content,"ARCHIVO OAK / CUATRO VIDAS FUERA DE LA RED",true)
 note(content,"¿Con quién vas a cambiar el futuro? Tu aventura comienza al elegir un compañero.")
 var grid=GridContainer.new()
 grid.columns=4 if get_viewport().get_visible_rect().size.x/shell.settings.values.ui_scale>=1400 else 2
 grid.add_theme_constant_override("h_separation",18)
 grid.add_theme_constant_override("v_separation",20)
 content.add_child(grid)
 for i in range(4):
  var id=STARTERS[i]
  var card=VBoxContainer.new()
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  grid.add_child(card)
  portrait(card,id,180)
  note(card,game.SPECIES[id][0],true)
  note(card,["PLANTA / VENENO","FUEGO","AGUA","ELÉCTRICO"][i])
  note(card,"Raichu · nivel 10" if id==25 else "Evoluciones · niveles 8 y 12")
  button(card,"ELEGIR [%d]"%(i+1),"starter:"+str(id))
 note(footer,"Nivel 5 · voz propia · capacidad de evolución. Todos pueden completar la aventura.")
func build_hacking():
 note(content,"NETRUN / NODO %02d"%(game.zone+1),true)
 var revealing=game.clock<game.hack_reveal_until
 note(content,"Memoriza la secuencia. Después repítela." if revealing else "Introduce los símbolos en el mismo orden.")
 var symbols=["01","10","11","00"]
 var sequence=[]
 for i in range(game.hacking_sequence.size()): sequence.append(symbols[int(game.hacking_sequence[i])] if revealing or i<game.hacking_input.size() else "??")
 note(content,"   →   ".join(sequence),true)
 timer_label=note(content,"")
 var grid=GridContainer.new()
 grid.columns=2
 grid.add_theme_constant_override("h_separation",16)
 grid.add_theme_constant_override("v_separation",16)
 content.add_child(grid)
 for i in range(4): button(grid,"%d · [ %s ]"%[i+1,symbols[i]],"node:"+str(i),not revealing and game.hack_error=="")
 note(content,"Recompensa: ₽150 + "+("refrigeración y suministros" if game.unlocked_nodes.size()==2 else "acceso a un implante")+". Guarda con F5 al volver al mapa.")
 button(footer,"REINICIAR SECUENCIA","retry_hack")
 button(footer,"DESCONECTAR [Esc]","city_close")
func build_evolution():
 if game.evolving.is_empty(): return
 note(content,"EVOLUCIÓN / SINCRONIZACIÓN",true)
 evolution_portrait=portrait(content,int(game.evolving.old),240)
 timer_label=note(content,"RECONFIGURANDO IMPLANTES…",true)
 progress=ProgressBar.new()
 progress.show_percentage=false
 progress.custom_minimum_size.y=20
 content.add_child(progress)
 note(footer,"La sincronización termina automáticamente. Tus técnicas e implantes se conservan.")
func build_choice():
 note(content,"ARCHIVO VIVO / DECISIÓN PERMANENTE",true)
 note(content,"¿Qué será del núcleo "+game.CORE_NAMES[maxi(0,game.pending_core)]+"?")
 note(content,"Elegir una opción permite revisarla. La decisión solo se aplica al confirmar y guardar.")
 var descriptions=game.core_choice_descriptions()
 for i in range(3):
  note(content,game.CHOICE_LABELS[FATES[i]],true)
  note(content,descriptions[i])
  button(content,("SELECCIONADA · " if game.pending_fate==FATES[i] else "ELEGIR · ")+str(i+1),"fate:"+FATES[i])
 if game.campaign_save_error!="": note(content,game.campaign_save_error).modulate=Color("ff9eae")
 if game.pending_fate!="":
  note(content,"Selección: "+game.CHOICE_LABELS[game.pending_fate]+". No se puede deshacer en esta partida.")
  button(footer,"CAMBIAR DE IDEA [Esc]","fate_cancel")
  button(footer,"CONFIRMAR Y GUARDAR","fate_confirm")
 else: note(footer,"Lee las consecuencias. Todavía no has decidido.")
func build_ending():
 note(content,"LA ÚLTIMA SINAPSIS / DESENLACE",true)
 note(content,{"rebirth":"Un bosque sin dueño","sanctuary":"El refugio de las voces","ashes":"La ciudad de las cenizas"}.get(game.ending_id,"La última sinapsis"),true)
 note(content,game.ending_text())
 note(content,"Biosfera restaurada: %d/6"%game.biosphere_score(),true)
 for i in range(3): note(content,game.CORE_NAMES[i]+" / "+game.CHOICE_LABELS.get(game.core_fates.get(str(i),""),"PENDIENTE"))
 note(content,"Partida guardada. Puedes seguir explorando y consultarlo en Red [K].")
 button(footer,"VOLVER A LA CIUDAD [Esc]","ending_close")
func handle_key(key:int)->bool:
 if game.mode=="evolution": return false
 if key==KEY_ESCAPE:
  if game.mode=="hacking": dispatch("city_close")
  elif game.mode=="ending": dispatch("ending_close")
  elif game.mode=="core_choice" and game.pending_fate!="": dispatch("fate_cancel")
  return true
 if key>=KEY_1 and key<=KEY_4:
  var index=key-KEY_1
  if game.mode=="starter": dispatch("starter:"+str(STARTERS[index]))
  elif game.mode=="hacking": dispatch("node:"+str(index))
  elif game.mode=="core_choice" and index<3: dispatch("fate:"+FATES[index])
  return true
 return false
