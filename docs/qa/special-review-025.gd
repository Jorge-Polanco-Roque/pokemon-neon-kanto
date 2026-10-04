extends "res://campaign_game.gd"
var fail_save=false
func save_game():
 if fail_save:
  campaign_save_error="No se pudo guardar. Prueba de reversión."
  return false
 return super.save_game()
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func settle(frames=8):
 for i in range(frames): await get_tree().process_frame
func shot(tag):
 await settle()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-025-"+tag+".png")
func review():
 var ui=screen_root.special_screen
 for i in range(4):
  reset_game()
  mode="starter"
  await settle()
  ui.handle_key(KEY_1+i)
  assert(party[0].id==[1,4,7,25][i] and party[0].level==5)
 mode="world"
 zone=0
 begin_hack()
 await settle()
 assert(ui.buttons_by_action["node:0"].disabled)
 ui.handle_key(KEY_1)
 assert(hacking_input.is_empty())
 hack_reveal_until=clock-1
 await settle()
 ui.dispatch("node:"+str((hacking_sequence[0]+1)%4))
 await settle()
 assert(hack_error!="" and ui.buttons_by_action["node:0"].disabled)
 ui.dispatch("retry_hack")
 hack_reveal_until=clock-1
 await settle()
 var balance=money
 for symbol in hacking_sequence.duplicate():
  ui.dispatch("node:"+str(symbol))
  await settle()
 assert(mode=="world" and 0 in unlocked_nodes and money==balance+150)
 party=[mon(25,10)]
 party[0].implant=1
 party[0].pp[0]=2
 var known=party[0].known_techniques.duplicate()
 await evolve(0,26,"party")
 assert(party[0].id==26 and party[0].implant==1 and party[0].pp[0]==2 and mode=="party")
 for technique in known: assert(technique in party[0].known_techniques)
 wardens_down=[0]
 pending_core=0
 pending_fate=""
 mode="core_choice"
 await settle()
 assert(not ui.buttons_by_action.has("fate_confirm"))
 ui.handle_key(KEY_2)
 await settle()
 assert(pending_fate=="release" and core_fates.is_empty())
 ui.handle_key(KEY_ESCAPE)
 await settle()
 assert(pending_fate=="" and core_fates.is_empty())
 ui.dispatch("fate:release")
 await settle()
 fail_save=true
 ui.dispatch("fate_confirm")
 await settle()
 assert(mode=="core_choice" and core_fates.is_empty() and campaign_save_error!="")
 fail_save=false
 ui.dispatch("fate_confirm")
 assert(core_fates["0"]=="release" and mode=="world")
 load_game()
 assert(core_fates["0"]=="release")
 var layouts=0
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1440,900),Vector2i(2560,1080)]:
  get_window().size=dimensions
  for scale_value in [1.0,1.25,1.5]:
   screen_root.settings.values.ui_scale=scale_value
   screen_root.update_layout()
   for state in ui.MODES:
    mode=state
    if state=="core_choice": pending_core=1; pending_fate="reactivate"
    if state=="evolution": evolving={"old":25,"new":26,"start":clock}
    if state=="hacking": hacking_sequence=[0,1,2,3,0]; hacking_input=[]; hack_error=""; hack_reveal_until=clock-1
    if state=="ending": ending_id="sanctuary"
    await settle()
    var bounds=Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size)
    assert(bounds.encloses(ui.footer.get_global_rect()),state+" footer")
    assert(ui.content.size.x<=ui.scroll.size.x+1,state+" width")
    for control in ui.buttons_by_action.values():
     if control.disabled: continue
     control.grab_focus()
     await settle(4)
     assert(bounds.encloses(control.get_global_rect()),state+" focus")
    layouts+=1
 get_window().size=Vector2i(1280,720)
 mode="starter"
 await shot("Starters-150")
 mode="core_choice"
 await shot("Decision-150")
 mode="hacking"
 await shot("Hacking-150")
 mode="evolution"
 evolving={"old":25,"new":26,"start":clock-2}
 await shot("Evolution-150")
 mode="ending"
 for ending in ["rebirth","sanctuary","ashes"]:
  ending_id=ending
  await shot("Ending-"+ending)
 ui.handle_key(KEY_ESCAPE)
 assert(mode=="world")
 var report=FileAccess.open("user://qa/qa-special-025.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"layouts":layouts,"four_starters":true,"hack_guards":true,"evolution_preserves_data":true,"choice_cancel":true,"save_rollback":true,"save_reload":true,"three_endings":true}))
 report.close()
 get_tree().quit()
