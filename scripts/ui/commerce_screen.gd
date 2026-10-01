extends "res://scripts/ui/team_screen.gd"
## Shared adaptive shell; purchases and storage still use campaign rules.
var last_mode=""
var message=""
func dispatch(action_id:String):
 if game.mode not in ["archive","shop","chips"]: return
 if not buttons_by_action.has(action_id) or buttons_by_action[action_id].disabled: return
 if action_id=="box_prev": game.action("archive_page:"+str(maxi(0,game.archive_page-1)))
 elif action_id=="box_next": game.action("archive_page:"+str(game.archive_page+1))
 else:
  game.action(action_id)
  if action_id in ["buy_ball","buy_potion"]: message=game.notice
  elif action_id.begins_with("deposit:"): message="Compañero depositado. Guarda con F5 al volver al mapa."
  elif action_id.begins_with("withdraw:"): message="Compañero retirado. Guarda con F5 al volver al mapa."
func sync_frame():
 visible=game.mode in ["archive","shop","chips"]
 if not visible: signature=""; last_mode=""; return
 if last_mode!=game.mode: message=""; last_mode=game.mode
 var next=JSON.stringify([game.mode,game.party,game.archive,game.archive_page,game.active,game.money,game.balls,game.potions,game.chip_selected,game.technique_subject,game.chip_licenses,game.wardens_down,game.chip_notice,message,shell.settings.values.ui_scale,get_viewport().get_visible_rect().size])
 if next==signature: return
 signature=next
 rebuild()
func build_contents():
 if game.mode=="archive": build_archive()
 elif game.mode=="shop": build_shop()
 else: build_chips()
func build_shop():
 note(content,"SUMINISTROS / MERCADO",true)
 note(content,"Saldo disponible: ₽%d"%game.money)
 note(content,"Poké Ball · captura de criaturas salvajes\nDebilita al rival antes de lanzarla. Inventario: %d."%game.balls)
 button(content,"Comprar Poké Ball · ₽100","buy_ball",game.money>=100)
 note(content,"Poción · recuperación de PS\nInventario: %d. La clínica cura al equipo gratuitamente."%game.potions)
 button(content,"Comprar poción · ₽150","buy_potion",game.money>=150)
 note(content,message if message!="" else "Las compras de suministros se conservan al guardar la partida con F5 en el mapa.")
 button(footer,"Volver al mapa [Esc]","world")
func build_archive():
 note(content,"CAJA DIGITAL / TRANSFERENCIA",true)
 note(content,"Equipo %d/6 · Almacenados %d. Conserva al menos un compañero y, si lo hay, uno con PS."%[game.party.size(),game.archive.size()])
 if message!="": note(content,message)
 var columns=HBoxContainer.new()
 columns.add_theme_constant_override("separation",24)
 content.add_child(columns)
 var team=VBoxContainer.new()
 team.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 team.add_theme_constant_override("separation",10)
 columns.add_child(team)
 var stored=VBoxContainer.new()
 stored.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stored.add_theme_constant_override("separation",10)
 columns.add_child(stored)
 note(team,"EQUIPO",true)
 var living=0
 for p in game.party:
  if p.hp>0: living+=1
 for i in range(game.party.size()):
  var p=game.party[i]
  note(team,"%s · Nv. %d\n%d/%d PS"%[game.combat_name(p),p.level,p.hp,p.maxhp])
  var enabled=game.party.size()>1 and (p.hp<=0 or living>1)
  button(team,"Depositar" if enabled else "Debe permanecer en el equipo","deposit:"+str(i),enabled)
 var pages=maxi(1,ceili(game.archive.size()/6.0))
 game.archive_page=clampi(game.archive_page,0,pages-1)
 note(stored,"CAJA · %d/%d"%[game.archive_page+1,pages],true)
 if game.archive.is_empty(): note(stored,"La caja está vacía. Deposita un compañero para guardarlo aquí.")
 for i in range(game.archive_page*6,mini(game.archive_page*6+6,game.archive.size())):
  var p=game.archive[i]
  note(stored,"%s · Nv. %d\n%d/%d PS"%[game.combat_name(p),p.level,p.hp,p.maxhp])
  button(stored,"Retirar" if game.party.size()<6 else "Equipo lleno","withdraw:"+str(i),game.party.size()<6)
 button(footer,"← Anterior","box_prev",game.archive_page>0)
 button(footer,"Siguiente →","box_next",game.archive_page<pages-1)
 button(footer,"Equipo","party")
 button(footer,"Volver [Esc]","world")
func build_chips():
 note(content,"NEURAL EXCHANGE / LICENCIAS",true)
 note(content,"Saldo ₽%d · Guardianes liberados: %d. Cada licencia se compra una vez y se reutiliza."%[game.money,game.wardens_down.size()])
 var subjects=GridContainer.new()
 subjects.columns=3
 subjects.add_theme_constant_override("h_separation",8)
 subjects.add_theme_constant_override("v_separation",8)
 content.add_child(subjects)
 for i in range(game.party.size()):
  button(subjects,str(i+1)+" · "+game.combat_name(game.party[i]).capitalize(),"chip_subject:"+str(i))
 note(content,"CATÁLOGO",true)
 for i in range(game.NeuralChips.CATALOG.size()):
  var item=game.NeuralChips.CATALOG[i]
  var status="Licencia activa" if item.key in game.chip_licenses else ("Requiere %d guardianes"%item.tier if game.wardens_down.size()<item.tier else "₽%d"%item.price)
  button(content,("▸ " if i==game.chip_selected else "")+item.name+" · "+status,"chip_select:"+str(i))
 var entry=game.NeuralChips.CATALOG[game.chip_selected]
 var p=game.party[game.technique_subject]
 var kind=game.SPECIES[int(p.id)][1]
 var compatible=game.NeuralChips.compatible(entry.key,kind)
 var owned=entry.key in game.chip_licenses
 var learned=entry.key in p.known_techniques
 var unlocked=game.wardens_down.size()>=entry.tier
 note(content,entry.name,true)
 var portrait=preload("res://scripts/ui/creature_portrait.gd").new()
 portrait.game=game
 portrait.species_id=int(p.id)
 portrait.custom_minimum_size.y=130*shell.settings.values.ui_scale
 content.add_child(portrait)
 note(content,game.combat_name(p)+" · "+kind+" · "+("Compatible" if compatible else "Incompatible"))
 note(content,entry.description+"\nInterfaces: "+", ".join(entry.types))
 var move=game.CombatRules.technique(entry.key,int(p.level))
 note(content,"%s · Potencia %d · Precisión %d%% · %d PP máximos"%[move.type,move.power,move.accuracy,move.max_pp])
 if game.chip_notice!="": note(content,game.chip_notice)
 else: note(content,"Compra y aprendizaje se guardan automáticamente. Después de enseñar elegirás la ranura; los PP gastados se conservan.")
 button(footer,"Volver [Esc]","chips_close")
 if owned: button(footer,"Ya aprendida" if learned else ("Enseñar técnica" if compatible else "Incompatible"),"chip_teach",compatible and not learned)
 else: button(footer,"Comprar · ₽%d"%entry.price if unlocked else "Licencia bloqueada","chip_buy",unlocked and game.money>=entry.price)
func handle_key(code:int)->bool:
 if code==KEY_ESCAPE:
  dispatch("chips_close" if game.mode=="chips" else "world")
  return true
 if game.mode=="chips" and code>=KEY_1 and code<=KEY_6:
  dispatch("chip_subject:"+str(code-KEY_1))
  return true
 return false
