extends "res://campaign_game.gd"
func _ready():
 super._ready()
 muted=true
 call_deferred("review")
func settle():
 for i in range(25): await get_tree().process_frame
func capture(label):
 await settle()
 RenderingServer.force_draw()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-016-"+label+".png")
func review():
 get_window().mode=Window.MODE_WINDOWED
 get_window().size=Vector2i(1280,720)
 screen_root.settings.values.ui_scale=1.0
 screen_root.update_layout()
 reset_game()
 party=[mon(7,14),mon(25,14),mon(133,14),mon(6,14),mon(123,14),mon(92,14)]
 active=0
 mode="party"
 await capture("Team")
 var ui=screen_root.team_screen
 assert(ui.buttons_by_action.has("evolve:2:134") and ui.buttons_by_action.has("evolve:2:135"))
 assert(ui.buttons_by_action["lead:0"].disabled)
 ui.buttons_by_action["lead:1"].pressed.emit()
 await settle()
 assert(active==1)
 ui.buttons_by_action["techniques"].pressed.emit()
 await settle()
 assert(mode=="techniques" and technique_subject==1)
 party[1].pp[0]=7
 await capture("Library")
 ui.buttons_by_action["tech_pick:precision"].pressed.emit()
 await capture("Replace")
 ui.handle_key(KEY_ESCAPE)
 await settle()
 assert(pending_technique=="" and party[1].pp[0]==7)
 ui.buttons_by_action["tech_pick:precision"].pressed.emit()
 await settle()
 ui.handle_key(KEY_1)
 await settle()
 assert(party[1].techniques[0]=="precision")
 ui.buttons_by_action["tech_pick:strike"].pressed.emit()
 await settle()
 ui.handle_key(KEY_1)
 await settle()
 assert(party[1].pp[0]==7,"UI replacement cannot refill spent PP")
 var cases=0
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1440,900),Vector2i(2560,1080)]:
  get_window().size=dimensions
  for scale_value in [1.0,1.25,1.5]:
   screen_root.settings.values.ui_scale=scale_value
   screen_root.update_layout()
   for screen in ["party","techniques","replace"]:
    mode="party" if screen=="party" else "techniques"
    pending_technique="precision" if screen=="replace" else ""
    await settle()
    var bounds=get_viewport().get_visible_rect()
    for control in ui.footer.get_children(): assert(bounds.encloses(control.get_global_rect()),"Footer clipped")
    assert(ui.content.size.x<=ui.scroll.size.x+1,"Horizontal overflow")
    for control in ui.buttons_by_action.values():
     assert(control.get_global_rect().end.x<=bounds.end.x,"Button extends horizontally")
     if not control.disabled:
      control.grab_focus()
      for i in range(3): await get_tree().process_frame
      if control.get_parent()!=ui.footer: assert(ui.scroll.get_global_rect().encloses(control.get_global_rect()),"Focused button not scrolled into view")
    cases+=1
 get_window().size=Vector2i(1280,720)
 mode="party"
 await capture("Team-150")
 mode="techniques"
 pending_technique="precision"
 await capture("Replace-150")
 pending_technique=""
 await capture("Library-150")
 ui.handle_key(KEY_ESCAPE)
 await settle()
 assert(mode=="party")
 ui.handle_key(KEY_ESCAPE)
 await settle()
 assert(mode=="world" and not ui.visible)
 var f=FileAccess.open("user://qa/qa-team-016.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"layout_cases":cases,"footer_visible":true,"focus_scroll":true,"replacement_preserves_pp":true,"cancel_preserves_moves":true,"return_to_world":true}))
 f.close()
 get_tree().quit()
