extends "res://scripts/ui/team_screen.gd"
## Native exploration menus. Gameplay and persistence stay in campaign actions.
const MODES=["bag","dex","detail","workshop","campaign","journal","field"]
const Field=preload("res://scripts/combat/field_protocols.gd")
var last_mode=""
func sync_frame():
 visible=game.mode in MODES
 if not visible: signature=""; last_mode=""; return
 var next=JSON.stringify([game.mode,game.party,game.potions,game.balls,game.money,game.notice,game.dex_selected,game.detail_memory,game.seen,game.captured,game.workshop_index,game.unlocked_nodes,game.core_fates,game.wardens_down,game.radio_history,game.ending_id,game.selected_record,game.found_records,game.field_site,game.field_notice,game.restored_sites,game.pos,game.interior_id,game.zone,shell.settings.values.ui_scale,get_viewport().get_visible_rect().size])
 if next==signature: return
 signature=next
 if last_mode!=game.mode: scroll.scroll_vertical=0
 last_mode=game.mode
 rebuild()
func dispatch(action_id:String):
 if game.mode not in MODES: return
 if not buttons_by_action.has(action_id) or buttons_by_action[action_id].disabled: return
 game.action(action_id)
func portrait(parent,id:int,height=200):
 var item=preload("res://scripts/ui/creature_portrait.gd").new()
 item.game=game
 item.species_id=id
 item.custom_minimum_size.y=height*shell.settings.values.ui_scale
 parent.add_child(item)
func build_contents():
 match game.mode:
  "bag": build_bag()
  "dex": build_dex()
  "detail": build_detail()
  "workshop": build_workshop()
  "campaign": build_campaign()
  "journal": build_journal()
  "field": build_field()
 var action_id={"detail":"dex","workshop":"city_close","campaign":"campaign_close","journal":"journal_close","field":"field_close"}.get(game.mode,"world")
 button(footer,"VOLVER AL CÓDEX [Esc]" if game.mode=="detail" else "VOLVER AL MAPA [Esc]",action_id)
func build_bag():
 note(content,"BOLSA / SUMINISTROS",true)
 note(content,"₽%d · %d Poké Balls · %d pociones"%[game.money,game.balls,game.potions])
 note(content,"Una poción recupera hasta 20 PS. No revive a un compañero debilitado.")
 for i in range(game.party.size()):
  var p=game.party[i]
  var ready=game.potions>0 and p.hp>0 and p.hp<p.maxhp
  var reason="USAR POCIÓN" if ready else ("SIN POCIONES" if game.potions==0 else ("REQUIERE CLÍNICA" if p.hp==0 else "PS COMPLETOS"))
  button(content,"%s · %d/%d PS · %s"%[game.combat_name(p),p.hp,p.maxhp,reason],"potion:"+str(i),ready)
 note(content,game.notice)
 note(content,"Guarda con F5 al volver al mapa para conservar los cambios.")
func build_dex():
 note(content,"CÓDEX / FORMAS CIBERNÉTICAS",true)
 note(content,"%d vistas · %d registradas"%[game.seen.size(),game.captured.size()])
 var grid=GridContainer.new()
 grid.columns=4 if get_viewport().get_visible_rect().size.x/shell.settings.values.ui_scale>=1100 else 2
 grid.add_theme_constant_override("h_separation",16)
 grid.add_theme_constant_override("v_separation",20)
 content.add_child(grid)
 for id in game.SPECIES:
  var card=VBoxContainer.new()
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  grid.add_child(card)
  portrait(card,int(id),145)
  button(card,game.SPECIES[id][0]+(" · REGISTRADO" if id in game.captured else ""),"inspect:"+str(id))
func build_detail():
 var id=int(game.dex_selected)
 var row=game.catalog[id]
 note(content,game.SPECIES[id][0]+" / "+row.concept,true)
 note(content,game.SPECIES[id][1]+(" · REGISTRADO" if id in game.captured else " · POR DESCUBRIR"))
 portrait(content,id,230)
 note(content,"MEMORIA DE LA ESPECIE" if game.detail_memory else "ARQUITECTURA SINTÉTICA",true)
 note(content,row.get("memory",row.description) if game.detail_memory else row.description)
 var evolution="Forma final de esta familia."
 if game.EVOLUTIONS.has(id):
  var names=[]
  for target in game.EVOLUTIONS[id]: names.append(game.SPECIES[target][0])
  evolution="Evoluciona al nivel %d en %s. Elige la ruta desde Equipo."%[game.EV_LEVEL[id]," o ".join(names)]
 note(content,evolution)
 button(content,"VER "+("DISEÑO" if game.detail_memory else "MEMORIA"),"detail_tab")
 button(content,"ESCUCHAR VOZ SINTÉTICA","cry:"+str(id))
func build_workshop():
 note(content,"RIPPER LAB / IMPLANTES",true)
 for i in range(game.party.size()): button(content,("▸ " if i==game.workshop_index else "")+game.combat_name(game.party[i]),"subject:"+str(i))
 if game.party.is_empty(): return
 var creature=game.party[game.workshop_index]
 portrait(content,int(creature.id),180)
 for i in range(3):
  var locked=i>game.unlocked_nodes.size()
  var installed=int(creature.get("implant",0))==i
  note(content,game.MODULE_INFO[i])
  button(content,("BLOQUEADO · " if locked else ("INSTALADO · " if installed else "INSTALAR · "))+game.MODULES[i],"implant:"+str(i),not locked and not installed)
 note(content,"Red liberada: %d/3. Los módulos se conservan al evolucionar y usar la caja. Guarda con F5 al volver al mapa."%game.unlocked_nodes.size())
func build_campaign():
 note(content,"RED / LA ÚLTIMA SINAPSIS",true)
 note(content,"Biosfera restaurada: %d/6"%game.biosphere_score())
 for i in range(3):
  note(content,game.CORE_NAMES[i]+" / "+["Neo Paleta","La Brecha","Distrito Cromo"][i],true)
  var state="Hackea el terminal."
  if i in game.unlocked_nodes: state="Vuelve al nodo para combatir."
  if i>0 and not str(i-1) in game.core_fates: state="Resuelve el núcleo anterior."
  if i in game.wardens_down: state="Guardián derrotado."
  if str(i) in game.core_fates: state="Núcleo "+game.CHOICE_LABELS[game.core_fates[str(i)]].to_lower()+"."
  note(content,"Corrupción %d%% · %s\n%s"%[game.corruption(i),game.WARDENS[i],state])
 note(content,"ÚLTIMAS TRANSMISIONES",true)
 for transmission in game.radio_history.slice(maxi(0,game.radio_history.size()-3)): note(content,transmission)
 if game.ending_id!="": button(content,"VOLVER A VER EL DESENLACE","ending_review")
func build_journal():
 note(content,"ARCHIVOS DE LA EXTINCIÓN",true)
 note(content,"%d/%d registros. Busca balizas doradas y pulsa E junto a ellas."%[game.found_records.size(),game.records.size()])
 for entry in game.records:
  var found=entry.id in game.found_records
  button(content,entry.short_title if found else "SEÑAL DESCONOCIDA","record:"+entry.id,found)
 var entry=game.record_by_id(game.selected_record)
 if entry.is_empty(): note(content,"La ciudad conserva lo que NEXUS intentó borrar. Busca junto al laboratorio, en el corredor industrial y en Distrito Cromo.")
 else:
  note(content,entry.title,true)
  note(content,entry.date+" / "+entry.author)
  note(content,entry.body)
  note(content,"Origen: "+["Neo Paleta","La Brecha","Distrito Cromo"][int(entry.zone)])
func build_field():
 note(content,"RED DE AUXILIO / %d DE 3 INSTALACIONES"%game.restored_sites.size(),true)
 for i in range(3): button(content,["PALETA","BRECHA","CROMO"][i]+(" · RESTAURADA" if i in game.restored_sites else " · SIN SEÑAL"),"field_site:"+str(i))
 var site=Field.SITES[game.field_site]
 note(content,site.name,true)
 note(content,site.brief)
 note(content,site.protocol+" · NIVEL 6+ · "+", ".join(site.types))
 note(content,"También sirve conocer "+game.CombatRules.technique(site.chip,6).name+". No ocupa ranuras ni gasta PP.")
 var nearby=game.interior_id=="" and game.zone==game.field_site and game.pos.distance_to(site.cell)<=1.5
 note(content,"Instalación (%d, %d) · marcador ámbar. %s"%[site.cell.x,site.cell.y,"Estás junto a la instalación." if nearby else "Acércate en el mapa para reparar."])
 for i in range(game.party.size()):
  var creature=game.party[i]
  var ready=Field.ready(creature,game.SPECIES[int(creature.id)][1],game.field_site)
  var complete=game.field_site in game.restored_sites
  button(content,game.combat_name(creature)+" · "+("COMPLETADO" if complete else ("USAR PROTOCOLO" if ready and nearby else "NO DISPONIBLE")),"field_use:"+str(i),ready and nearby and not complete)
 note(content,game.field_notice if game.field_notice!="" else "Cada reparación: ₽180, una poción y menos corrupción. Las tres: ₽500 extra y licencia Enjambre. Guardado automático al reparar.")
func handle_key(key:int)->bool:
 if key==KEY_ESCAPE or (game.mode=="campaign" and key==KEY_K) or (game.mode=="journal" and key==KEY_J) or (game.mode=="field" and key==KEY_L):
  dispatch({"detail":"dex","workshop":"city_close","campaign":"campaign_close","journal":"journal_close","field":"field_close"}.get(game.mode,"world"))
  return true
 return false
