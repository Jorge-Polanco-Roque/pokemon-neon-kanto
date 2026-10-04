extends "res://campaign_game.gd"
func _ready():
 super._ready()
 AudioServer.set_bus_mute(0,true)
 call_deferred("review")
func settle():
 for i in range(25): await get_tree().process_frame
func shot(tag):
 await settle()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-027-"+tag+".png")
func review():
 reset_game()
 action("starter:7")
 mode="world"
 pos=Vector2i(13,9)
 visual_pos=Vector2(pos)
 get_window().size=Vector2i(1600,900)
 await shot("Paleta")
 var actor=modern_view.player
 actor.motion.play("walk")
 actor.motion.seek(.175,true)
 assert(absf(actor.get_node("Rig/LeftLeg/Knee").rotation.x)>.3)
 actor.motion.play("idle",0)
 actor.motion.advance(0)
 assert(absf(actor.get_node("Rig/LeftLeg/Knee").rotation.x)<.01)
 assert(actor.motion.get_animation("walk")!=modern_view.npc.motion.get_animation("walk"))
 var leaves=0
 for item in modern_view.district_root.get_children():
  if item is MultiMeshInstance3D and item.multimesh.mesh is SphereMesh: leaves+=1
 assert(leaves==2)
 # Close-up uses the actual actor/lighting, with a temporary QA camera.
 set_process(false)
 modern_view.set_process(false)
 modern_view.simulation_enabled=false
 modern_view.camera.size=3.5
 modern_view.camera.position=actor.position+Vector3(2,1.7,3)
 modern_view.camera.look_at(actor.position+Vector3(0,.8,0),Vector3.UP)
 actor.set_pose(actor.position,Vector2.DOWN,false)
 await shot("Mara")
 var npc_actor=modern_view.npc
 modern_view.camera.position=npc_actor.position+Vector3(2,1.7,3)
 modern_view.camera.look_at(npc_actor.position+Vector3(0,.8,0),Vector3.UP)
 await shot("Resident")
 set_process(true)
 modern_view.set_process(true)
 modern_view.simulation_enabled=true
 modern_view.camera.size=17.5
 get_window().size=Vector2i(1280,720)
 await shot("Paleta-720")
 var report=FileAccess.open("user://qa/qa-actors-027.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"knee_flexion":true,"idle_reset":true,"independent_animations":true,"leaf_batches":leaves,"native_views":4}))
 report.close()
 get_tree().quit()
