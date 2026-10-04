extends "res://campaign_game.gd"
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func settle():
 for i in range(35): await get_tree().process_frame
func capture(tag):
 await settle()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-026-"+tag+".png")
func review():
 reset_game()
 action("starter:7")
 mode="world"
 zone=0
 get_window().size=Vector2i(1600,900)
 pos=Vector2i(13,9)
 visual_pos=Vector2(pos)
 await capture("Plaza")
 pos=Vector2i(8,8)
 visual_pos=Vector2(pos)
 await capture("Clinic")
 enter_interior("clinic")
 await settle()
 assert(interior_id=="clinic")
 leave_interior()
 assert(pos==Vector2i(8,8))
 pos=Vector2i(21,8)
 visual_pos=Vector2(pos)
 await capture("Archive")
 enter_interior("archive")
 await settle()
 leave_interior()
 assert(pos==Vector2i(21,8))
 var previous=modern_view.district_root
 await settle()
 assert(previous==modern_view.district_root)
 get_window().size=Vector2i(1280,720)
 screen_root.settings.values.ui_scale=1.5
 screen_root.update_layout()
 pos=Vector2i(13,9)
 visual_pos=Vector2(pos)
 await capture("Plaza-720-150")
 var report=FileAccess.open("user://qa/qa-paleta-026.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"clinic_transition":true,"archive_transition":true,"geometry_stable":true,"resolutions":["1600x900","1280x720 UI150"]}))
 report.close()
 get_tree().quit()
