extends "res://campaign_game.gd"
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func settle(frames=8):
 for i in range(frames): await get_tree().process_frame
func shot(tag):
 await settle()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-024-"+tag+".png")
func review():
 reset_game()
 party=[mon(7,8),mon(25,8),mon(1,8),mon(4,8),mon(123,8),mon(92,8)]
 active=0
 var ui=screen_root.exploration_screen
 mode="bag"
 potions=3
 party[0].hp=1
 await settle()
 assert(ui.buttons_by_action["potion:1"].disabled)
 var hp=party[0].hp
 ui.buttons_by_action["potion:0"].emit_signal("pressed")
 assert(potions==2 and party[0].hp==mini(hp+20,party[0].maxhp))
 await shot("Bag")
 mode="dex"
 await settle()
 ui.buttons_by_action["inspect:25"].emit_signal("pressed")
 await settle()
 assert(mode=="detail" and dex_selected==25)
 var old=detail_memory
 ui.buttons_by_action.detail_tab.emit_signal("pressed")
 assert(detail_memory!=old)
 await shot("Pikachu")
 ui.handle_key(KEY_ESCAPE)
 assert(mode=="dex")
 mode="world"
 action("workshop")
 await settle()
 assert(ui.buttons_by_action["implant:2"].disabled)
 unlocked_nodes=[0]
 await settle()
 ui.buttons_by_action["subject:1"].emit_signal("pressed")
 await settle()
 ui.buttons_by_action["implant:1"].emit_signal("pressed")
 assert(party[1].implant==1)
 mode="journal"
 await settle()
 assert(ui.buttons_by_action["record:"+records[0].id].disabled)
 found_records.append(records[0].id)
 await settle()
 ui.buttons_by_action["record:"+records[0].id].emit_signal("pressed")
 assert(selected_record==records[0].id)
 mode="world"
 action("field")
 await settle()
 assert(ui.buttons_by_action["field_use:0"].disabled)
 pos=FieldProtocols.SITES[0].cell+Vector2i.RIGHT
 await settle()
 ui.buttons_by_action["field_use:0"].emit_signal("pressed")
 assert(0 in restored_sites)
 await settle()
 assert(ui.buttons_by_action["field_use:0"].disabled)
 assert(save_game())
 party[1].implant=0
 load_game()
 assert(party[1].implant==1 and 0 in restored_sites)
 var layouts=0
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1440,900),Vector2i(2560,1080)]:
  get_window().size=dimensions
  for scale_value in [1.0,1.25,1.5]:
   screen_root.settings.values.ui_scale=scale_value
   screen_root.update_layout()
   for state in ui.MODES:
    mode=state
    await settle()
    var bounds=Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size)
    assert(bounds.encloses(ui.footer.get_global_rect()),state+" footer")
    assert(ui.content.size.x<=ui.scroll.size.x+1,state+" width")
    for control in ui.buttons_by_action.values():
     if control.disabled: continue
     control.grab_focus()
     await settle(5)
     assert(bounds.encloses(control.get_global_rect()),state+" focus "+str(dimensions)+" scale "+str(scale_value)+" "+control.text+" "+str(control.get_global_rect())+" "+str(bounds))
    layouts+=1
 get_window().size=Vector2i(1280,720)
 mode="dex"
 await settle()
 ui.scroll.scroll_vertical=0
 await shot("Codex-150")
 mode="campaign"
 await shot("Network-150")
 mode="field"
 await shot("Field-150")
 ui.handle_key(KEY_ESCAPE)
 assert(mode=="world")
 var report=FileAccess.open("user://qa/qa-exploration-024.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"layouts":layouts,"potion":true,"codex_memory":true,"implant":true,"record_access":true,"field_guards":true,"save_reload":true}))
 report.close()
 get_tree().quit()
