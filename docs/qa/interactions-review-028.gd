extends "res://campaign_game.gd"
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func shot(tag):
 for i in range(30): await get_tree().process_frame
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-028-"+tag+".png")
func review():
 reset_game()
 action("starter:7")
 mode="world"
 pos=Vector2i(13,9)
 visual_pos=Vector2(pos)
 await shot("Plaza")
 pos=Vector2i(21,8)
 visual_pos=Vector2(pos)
 await shot("Oak")
 pos=Vector2i(14,9)
 visual_pos=Vector2(pos)
 for i in range(30): await get_tree().process_frame
 var faded=false
 var readable=false
 for node in modern_view.district_root.get_children():
  if node is Label3D and node.has_meta("nearby_hint"):
   if node.modulate.a<.5: faded=true
   if node.modulate.a>.9: readable=true
 assert(faded and readable)
 var report=FileAccess.open("user://qa/qa-interactions-028.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"nearby_hints":true,"distant_hints_fade":true,"native_views":2}))
 report.close()
 get_tree().quit()
