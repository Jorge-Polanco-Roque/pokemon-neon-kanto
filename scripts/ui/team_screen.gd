extends Control
## Presentation only: mutations pass through the existing campaign actions.
var game
var shell
var body:VBoxContainer
var content:VBoxContainer
var footer:HBoxContainer
var scroll:ScrollContainer
var signature=""
var buttons_by_action={}
func setup(controller,screen):
 game=controller
 shell=screen
 shell.full(self)
 shell.background(self)
 var margin=MarginContainer.new()
 add_child(margin)
 shell.full(margin)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
 body=VBoxContainer.new()
 body.add_theme_constant_override("separation",16)
 margin.add_child(body)
 scroll=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
 body.add_child(scroll)
 content=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",14)
 scroll.add_child(content)
 footer=HBoxContainer.new()
 footer.add_theme_constant_override("separation",12)
 body.add_child(footer)
func note(parent,text_value:String,large=false):
 var label=Label.new()
 label.text=text_value
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if large:
  label.add_theme_font_size_override("font_size",int(26*shell.settings.values.ui_scale))
  label.modulate=Color("6de4d4")
 parent.add_child(label)
 return label
func button(parent,text_value:String,action_id:String,enabled=true):
 var control=shell.button(parent,text_value,func():dispatch(action_id))
 control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 control.disabled=not enabled
 buttons_by_action[action_id]=control
 return control
func dispatch(action_id:String):
 if game.mode not in ["party","techniques"]: return
 if not buttons_by_action.has(action_id) or buttons_by_action[action_id].disabled: return
 game.action(action_id)
func sync_frame():
 visible=game.mode in ["party","techniques"]
 if not visible: signature=""; return
 var next=JSON.stringify([game.mode,game.party,game.active,game.money,game.technique_subject,game.pending_technique,game.technique_notice,shell.settings.values.ui_scale,get_viewport().get_visible_rect().size])
 if next==signature: return
 signature=next
 rebuild()
func rebuild():
 var focused=get_viewport().gui_get_focus_owner()
 var previous_action=""
 for key in buttons_by_action:
  if buttons_by_action[key]==focused: previous_action=key
 for parent in [content,footer]:
  for child in parent.get_children():
   parent.remove_child(child)
   child.queue_free()
 buttons_by_action={}
 build_contents()
 if buttons_by_action.has(previous_action) and not buttons_by_action[previous_action].disabled:
  buttons_by_action[previous_action].grab_focus()
 else:
  for control in buttons_by_action.values():
   if not control.disabled: control.grab_focus(); break
 call_deferred("reveal_focused_control")
func reveal_focused_control():
 # Container geometry settles after rebuilding; focus may already be unchanged.
 await get_tree().process_frame
 if not is_visible_in_tree(): return
 var focused=get_viewport().gui_get_focus_owner()
 if is_instance_valid(focused) and content.is_ancestor_of(focused):
  scroll.ensure_control_visible(focused)
func build_contents():
 if game.mode=="party": build_party()
 elif game.pending_technique!="": build_replacement()
 else: build_library()
func build_party():
 note(content,"EQUIPO / COMPAÑEROS AUMENTADOS",true)
 note(content,"%d / 6 compañeros · ₽%d · El simulador entrena al líder. Guarda con F5 al volver al mapa."%[game.party.size(),game.money])
 var grid=GridContainer.new()
 grid.columns=2 if get_viewport().get_visible_rect().size.x>=1100 else 1
 grid.add_theme_constant_override("h_separation",20)
 grid.add_theme_constant_override("v_separation",16)
 content.add_child(grid)
 for i in range(game.party.size()):
  var p=game.party[i]
  var id=int(p.id)
  var panel=PanelContainer.new()
  panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var style=StyleBoxFlat.new()
  style.bg_color=Color("102333")
  style.border_color=Color("63dacc") if i==game.active else Color("294959")
  style.set_border_width_all(1)
  style.set_corner_radius_all(12)
  for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,16)
  panel.add_theme_stylebox_override("panel",style)
  grid.add_child(panel)
  var card=VBoxContainer.new()
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.add_theme_constant_override("separation",8)
  panel.add_child(card)
  var portrait=preload("res://scripts/ui/creature_portrait.gd").new()
  portrait.game=game
  portrait.species_id=id
  portrait.custom_minimum_size.y=170*shell.settings.values.ui_scale
  card.add_child(portrait)
  note(card,game.combat_name(p)+(" / LÍDER" if i==game.active else ""),true)
  note(card,"Nv. %d · %d/%d PS · %s\n%s · EXP %d/%d"%[p.level,p.hp,p.maxhp,game.CombatRules.STATUS_NAMES.get(p.get("status",""),"ESTABLE"),game.MODULES[int(p.get("implant",0))],p.xp,p.level*12])
  var health=ProgressBar.new()
  health.max_value=p.maxhp
  health.value=p.hp
  health.show_percentage=false
  health.custom_minimum_size.y=7
  var fill=StyleBoxFlat.new()
  fill.bg_color=Color("6de4d4") if p.hp>p.maxhp*.25 else Color("eb85bd")
  fill.set_corner_radius_all(3)
  health.add_theme_stylebox_override("fill",fill)
  card.add_child(health)
  var actions=HBoxContainer.new()
  card.add_child(actions)
  button(actions,"Líder" if i==game.active else "Al frente","lead:"+str(i),p.hp>0 and i!=game.active)
  button(actions,"Escuchar","cry:"+str(id))
  if game.EVOLUTIONS.has(id):
   if p.level>=game.EV_LEVEL[id]:
    for target in game.EVOLUTIONS[id]: button(card,"Evolucionar → "+game.SPECIES[target][0],"evolve:%d:%d"%[i,target])
   else: note(card,"Evolución a partir del nivel "+str(game.EV_LEVEL[id]))
  else: note(card,"Evolución final")
 button(content,"Simulador · +1 nivel al líder / ₽80","train",game.money>=80)
 button(content,"Caja digital","archive")
 button(footer,"Volver [Esc]","world")
 button(footer,"Técnicas","techniques",not game.party.is_empty())
func move_text(move:Dictionary,pp:int)->String:
 return "%s\n%s · %d/%d PP · Potencia %d · Precisión %d%%"%[move.name,move.type,pp,move.max_pp,move.power,move.accuracy]
func build_library():
 var p=game.party[game.technique_subject]
 note(content,"BIBLIOTECA / "+game.combat_name(p),true)
 note(content,"Elige un compañero y una técnica. Cambiar de técnica conserva sus PP gastados.")
 var subjects=GridContainer.new()
 subjects.columns=3
 subjects.add_theme_constant_override("h_separation",8)
 subjects.add_theme_constant_override("v_separation",8)
 content.add_child(subjects)
 for i in range(game.party.size()):
  button(subjects,str(i+1)+" · "+game.combat_name(game.party[i]).capitalize(),"tech_subject:"+str(i),i!=game.technique_subject)
 note(content,"EQUIPADAS / CUATRO RANURAS",true)
 for i in range(4): note(content,str(i+1)+" · "+move_text(game.move_set(p)[i],p.pp[i]))
 note(content,"TÉCNICAS CONOCIDAS",true)
 for key in p.known_techniques:
  var move=game.CombatRules.technique(key,int(p.level))
  var equipped=key in p.techniques
  var pp=int(p.technique_pp.get(key,move.max_pp))
  if equipped: pp=p.pp[p.techniques.find(key)]
  note(content,move_text(move,pp))
  button(content,"Equipada" if equipped else "Equipar · "+move.name,"tech_pick:"+key,not equipped)
 note(content,"Nv. 6: Láser de precisión · Nv. 10: Descarga de afinidad · Nv. 14: Corte de afinidad. Las técnicas se conservan al evolucionar.")
 if game.technique_notice!="": note(content,game.technique_notice)
 button(content,"Mercado de chips","chips")
 button(footer,"Volver al equipo [Esc]","tech_close")
func build_replacement():
 var p=game.party[game.technique_subject]
 var move=game.CombatRules.technique(game.pending_technique,int(p.level))
 note(content,"EQUIPAR / "+move.name,true)
 note(content,move_text(move,int(p.technique_pp.get(game.pending_technique,move.max_pp))))
 note(content,"Elige la técnica que saldrá de las cuatro ranuras. Seguirá en la biblioteca con sus PP actuales. Esta operación no cura al compañero.")
 for i in range(4):
  var old=game.move_set(p)[i]
  note(content,move_text(old,p.pp[i]))
  button(content,"%d · Reemplazar %s"%[i+1,old.name],"tech_replace:"+str(i))
 button(footer,"Cancelar [Esc]","tech_cancel")
func handle_key(code:int)->bool:
 if code==KEY_ESCAPE:
  dispatch("world" if game.mode=="party" else ("tech_cancel" if game.pending_technique!="" else "tech_close"))
  return true
 if game.mode=="techniques" and code>=KEY_1 and code<=KEY_6:
  var index=code-KEY_1
  dispatch(("tech_replace:" if game.pending_technique!="" else "tech_subject:")+str(index))
  return true
 return false
