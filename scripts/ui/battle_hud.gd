extends Control
## Battle controls are native UI; rules and animation stay in the game controller.
var game
var shell
var stage:Control
var heading:Label
var enemy_card:VBoxContainer
var own_card:VBoxContainer
var log_text:Label
var action_grid:GridContainer
var lower:HBoxContainer
var signature=""
var detail=""
var action_buttons:Array=[]
func setup(controller,screen):
 game=controller
 shell=screen
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin=MarginContainer.new()
 margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(margin)
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
 var column=VBoxContainer.new()
 column.mouse_filter=Control.MOUSE_FILTER_IGNORE
 column.add_theme_constant_override("separation",8)
 margin.add_child(column)
 heading=shell.label(column,"COMBATE",18)
 heading.modulate=Color("6de4d4")
 var status=HBoxContainer.new()
 status.add_theme_constant_override("separation",24)
 column.add_child(status)
 enemy_card=make_card(status,Color("eb85bd"))
 own_card=make_card(status,Color("6de4d4"))
 stage=Control.new()
 stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
 stage.custom_minimum_size.y=160
 column.add_child(stage)
 lower=HBoxContainer.new()
 lower.add_theme_constant_override("separation",20)
 column.add_child(lower)
 var scroll=ScrollContainer.new()
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.size_flags_stretch_ratio=.9
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 lower.add_child(scroll)
 log_text=Label.new()
 log_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 log_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 log_text.vertical_alignment=VERTICAL_ALIGNMENT_TOP
 scroll.add_child(log_text)
 action_grid=GridContainer.new()
 action_grid.columns=2
 action_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 action_grid.size_flags_stretch_ratio=1.1
 action_grid.add_theme_constant_override("h_separation",8)
 action_grid.add_theme_constant_override("v_separation",6)
 lower.add_child(action_grid)
func make_card(parent:Node,color:Color)->VBoxContainer:
 var card=VBoxContainer.new()
 card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(card)
 var name_label=shell.label(card,"",18)
 name_label.modulate=color
 var bar=ProgressBar.new()
 bar.custom_minimum_size.y=9
 bar.show_percentage=false
 var fill=StyleBoxFlat.new()
 fill.bg_color=color
 fill.set_corner_radius_all(3)
 bar.add_theme_stylebox_override("fill",fill)
 card.add_child(bar)
 shell.label(card,"",14)
 return card
func update_card(card:VBoxContainer,creature:Dictionary,own:bool):
 var title=game.combat_name(creature)
 if not own and game.active_warden>=0: title=game.WARDENS[game.active_warden].get_slice(" /",0)
 card.get_child(0).text=("TU EQUIPO · " if own else "RIVAL · ")+title+"  /  Nv. "+str(creature.level)
 card.get_child(0).add_theme_font_size_override("font_size",int(18*shell.settings.values.ui_scale))
 var bar=card.get_child(1)
 bar.max_value=creature.maxhp
 bar.value=game.player_hp_visual if own else game.enemy_hp_visual
 var state=game.CombatRules.STATUS_NAMES.get(creature.get("status",""),"ESTABLE")
 card.get_child(2).text="%d / %d PS · %s"%[creature.hp,creature.maxhp,state]+(" · CALOR %d%%"%game.thermal if own else "")
 card.get_child(2).add_theme_font_size_override("font_size",int(14*shell.settings.values.ui_scale))
func rows()->Array:
 if game.turn_locked: return []
 if game.battle_menu=="moves":
  if game.all_pp_empty(game.party[game.active]):
   return [{"text":"1  FORCEJEO\nSin PP · causa retroceso","action":"move:0","enabled":true},{"text":"VOLVER [ESC]","action":"battle_back","enabled":true}]
  var result=[]
  var moves=game.move_set(game.party[game.active])
  for i in range(4):
   var m=moves[i]
   var short_name=m.name if m.name.length()<=15 else m.name.left(14)+"…"
   result.append({"text":"%d  %s\n%d/%d PP · %d%%"%[i+1,short_name,game.party[game.active].pp[i],m.max_pp,m.accuracy],"action":"move:"+str(i),"enabled":game.party[game.active].pp[i]>0,"detail":move_description(m)})
  result.append({"text":"5  VOLVER [ESC]","action":"battle_back","enabled":true})
  return result
 if game.battle_menu=="switch":
  var result=[]
  for i in range(game.party.size()):
   var p=game.party[i]
   result.append({"text":"%d  %s\n%d/%d PS%s"%[i+1,game.combat_name(p),p.hp,p.maxhp," · ACTIVO" if i==game.active else ""],"action":"switch:"+str(i),"enabled":i!=game.active and p.hp>0})
  result.append({"text":"VOLVER [ESC]","action":"battle_back","enabled":true})
  return result
 return [
  {"text":"1  LUCHAR","action":"fight","enabled":true},
  {"text":"2  BALL ×"+str(game.balls),"action":"catch","enabled":game.balls>0 and game.trainer=="" and game.active_warden<0},
  {"text":"3  POCIÓN ×"+str(game.potions),"action":"battle_potion","enabled":game.potions>0 and game.party[game.active].hp<game.party[game.active].maxhp},
  {"text":"4  EQUIPO","action":"switch","enabled":game.party.size()>1},
  {"text":"[O] "+("OC ARMADA" if game.overdrive else "SOBRECARGA"),"action":"overdrive","enabled":game.thermal<=60},
  {"text":"[V] VENTILAR","action":"vent","enabled":true},
  {"text":"5  HUIR","action":"run","enabled":game.trainer=="" and game.active_warden<0}]
func move_description(move:Dictionary)->String:
 var effects={"guard":"Refuerza el blindaje (máximo 2 cargas).","weaken":"Reduce la potencia rival (máximo 2 cargas).","burn":"Quemadura: daño residual y menor ataque físico.","sleep":"Sueño: bloquea acciones temporalmente.","paralysis":"Parálisis: reduce velocidad y puede impedir actuar.","":""}
 var text_value=move.name+" / "+move.type+"\nPotencia %d · Precisión %d%% · %s"%[move.power,move.accuracy,"Especial" if move.special else "Físico"]
 if move.effect!="": text_value+="\n"+(str(move.chance)+"%: " if move.power>0 else "")+effects.get(move.effect,move.effect)
 return text_value
func dispatch(action_id:String):
 if game.mode!="battle" or game.turn_locked: return
 if action_id in ["overdrive","vent"]:
  if action_id=="vent" or game.thermal<=60: game.action(action_id)
  return
 for row in rows():
  if row.action==action_id and row.enabled:
   detail=""
   game.action(action_id)
   return
func rebuild():
 for child in action_grid.get_children():
  action_grid.remove_child(child)
  child.queue_free()
 action_buttons=[]
 detail=""
 for row in rows():
  var action_id:String=row.action
  var description:String=row.get("detail","")
  var control=shell.button(action_grid,row.text,func():dispatch(action_id))
  control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  control.clip_text=true
  control.disabled=not row.enabled
  control.tooltip_text=description if description!="" else row.text
  control.mouse_entered.connect(func():detail=description)
  control.mouse_exited.connect(func():detail="")
  control.focus_entered.connect(func():detail=description)
  control.focus_exited.connect(func():detail="")
  action_buttons.append(control)
 if not action_buttons.is_empty():
  for control in action_buttons:
   if not control.disabled:
    control.grab_focus()
    break
func sync_frame():
 visible=game.mode=="battle"
 if not visible: signature=""; return
 heading.text="COMBATE / "+("SEÑAL SALVAJE" if game.trainer=="" else game.trainer)+" · "+["PALETA","BRECHA","CROMO"][game.zone]
 heading.add_theme_font_size_override("font_size",int(16*shell.settings.values.ui_scale))
 log_text.add_theme_font_size_override("font_size",int(17*shell.settings.values.ui_scale))
 lower.custom_minimum_size.y=185*shell.settings.values.ui_scale
 update_card(enemy_card,game.enemy,false)
 update_card(own_card,game.party[game.active],true)
 var new_signature=JSON.stringify([game.battle_menu,game.turn_locked,game.party,game.balls,game.potions,game.overdrive,game.thermal,game.active_warden,game.trainer,shell.settings.values.ui_scale])
 if new_signature!=signature:
  signature=new_signature
  rebuild()
 var mechanics=""
 if game.active_warden>=0:
  mechanics=["Escudo inicial: primer golpe −25%.","Inyección térmica: +15 calor por turno.","Autorreparación: 12% PS cada 2 turnos."][game.active_warden]
 elif game.trainer=="" and game.corruption(game.zone)>=70: mechanics="Red corrupta: daño rival +15%."
 var pulse="Pulso rival en %d turno(s)."%[3-game.enemy_cycles%3]
 if (game.enemy_cycles+1)%3==0: pulse="¡Pulso rival +30% en su próximo turno!"
 log_text.text=("RESOLVIENDO TURNO…\n" if game.turn_locked else "")+(detail if detail!="" and not game.turn_locked else game.battle_text)+"\n\n"+mechanics+" "+pulse+"\nSobrecarga: ×1,65 daño + calor. Ventilar: −60 calor, cede turno."
 var own=game.party[game.active]
 log_text.text+="\n"+game.MODULES[int(own.get("implant",0))]+" · EXP %d/%d"%[own.xp,own.level*12]
 var bounds=stage.get_global_rect()
 var factor=maxf(.1,bounds.size.y/490.0)
 game.battle_canvas_width=bounds.size.x/factor
 game.transform=Transform2D(0,Vector2.ONE*factor,0,bounds.position)
func handle_key(code:int)->bool:
 if code==KEY_ESCAPE: dispatch("battle_back"); return true
 if code==KEY_O: dispatch("overdrive"); return true
 if code==KEY_V: dispatch("vent"); return true
 if code<KEY_1 or code>KEY_6: return false
 var index=code-KEY_1
 if game.battle_menu=="moves":
  if index<4: dispatch("move:"+str(index))
  elif index==4: dispatch("battle_back")
 elif game.battle_menu=="switch": dispatch("switch:"+str(index))
 elif index<5: dispatch(["fight","catch","battle_potion","switch","run"][index])
 return true
