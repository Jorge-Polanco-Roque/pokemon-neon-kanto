extends "res://campaign_game.gd"
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func settle():
 for i in range(10): await get_tree().process_frame
func shot(tag):
 await settle()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-023-"+tag+".png")
func review():
 reset_game()
 action("starter:25")
 mode="world"
 var outside=pos
 enter_interior("clinic")
 await settle()
 air_dialogue="clinic"
 mode="air_dialogue"
 await settle()
 screen_root.dialogue_screen.buttons_by_action.air_accept.emit_signal("pressed")
 assert(air_quest==1)
 party[0].hp=1
 await settle()
 screen_root.dialogue_screen.buttons_by_action.air_heal.emit_signal("pressed")
 assert(party[0].hp==party[0].maxhp)
 await shot("Dialogue")
 action("air_close")
 await shot("Clinic")
 action("interior_exit")
 assert(pos==outside and interior_id=="")
 enter_interior("archive")
 air_dialogue="archive"
 mode="air_dialogue"
 await settle()
 screen_root.dialogue_screen.buttons_by_action.air_filter.emit_signal("pressed")
 assert(air_quest==2)
 action("air_close")
 await shot("Archive")
 var layouts=0
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1440,900),Vector2i(2560,1080)]:
  get_window().size=dimensions
  for scale_value in [1.0,1.25,1.5]:
   screen_root.settings.values.ui_scale=scale_value
   screen_root.update_layout()
   for state in ["world","dialogue","air_dialogue"]:
    mode=state
    message="La red perdió mi nombre, pero todavía recuerdo a quienes mantuvieron encendida la clínica. ".repeat(18)
    await settle()
    var bounds=Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size)
    if state=="world":
     assert(bounds.encloses(screen_root.world_texture.get_global_rect()))
     assert(interior_view.size.x>900)
    else:
     var ui=screen_root.dialogue_screen
     assert(bounds.encloses(ui.footer.get_global_rect()))
     assert(ui.content.size.x<=ui.scroll.size.x+1)
     for button in ui.buttons_by_action.values():
      button.grab_focus()
      await settle()
      assert(bounds.encloses(button.get_global_rect()))
    layouts+=1
 get_window().size=Vector2i(1280,720)
 mode="dialogue"
 await shot("Long-150")
 screen_root.dialogue_screen.handle_key(KEY_E)
 assert(mode==after_dialogue)
 var report=FileAccess.open("user://qa/qa-dialogue-023.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"layouts":layouts,"quest_actions":true,"healing":true,"exit_position":true,"long_text":true}))
 report.close()
 get_tree().quit()
