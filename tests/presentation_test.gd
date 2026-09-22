extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("test_presentation")
func test_presentation():
 var view=preload("res://scenes/world/modern_world.tscn").instantiate()
 add_child(view)
 reset_game()
 action("starter:7")
 for district in range(3):
  zone=district
  var tiles=[]
  for y in range(16):
   var row=[]
   for x in range(28): row.append(terrain(x,y))
   tiles.append(row)
  view.build_district(zone,tiles,buildings(),[TERMINALS[zone]],records,npc_position())
  assert(view.district_root.get_child_count()>40)
  assert(view.visitors.size()==2 and view.vehicles.size()>=2)
  var old_root=view.district_root
  view.build_district(zone,tiles,buildings(),[TERMINALS[zone]],records,npc_position())
  assert(view.district_root==old_root,"Static geometry must not rebuild every frame")
  view.sync_player(Vector2(13,12),Vector2.DOWN,true)
  view.player.motion.advance(0)
  await get_tree().create_timer(.2).timeout
  assert(absf(view.player.get_node("Rig/LeftLeg").rotation.x)>.1)
  assert(view.player.motion.current_animation=="walk")
  view.sync_player(Vector2(13,12),Vector2.DOWN,false)
  assert(view.player.motion.current_animation=="idle")
 view.build_prologue(0,[])
 assert(view.partner.visible)
 view.sync_player(Vector2(7,8),Vector2.RIGHT,true)
 var old_partner=view.partner.position
 await get_tree().create_timer(.25).timeout
 assert(view.partner.position!=old_partner,"Lia must move through the scene")
 view.build_prologue(1,[0])
 assert(view.prologue_act==1)
 view.build_prologue(2,[0,1,2])
 view.sync_player(Vector2(3,8),Vector2.DOWN,false)
 assert(not view.partner.visible and view.npc.visible)
 view.queue_free()
 for room in ["clinic","archive"]:
  var interior=load("res://scenes/world/"+room+".tscn").instantiate()
  add_child(interior)
  assert(interior.scene_key=="interior:"+room)
  assert(interior.district_root.get_child_count()>10 and interior.npc.visible)
  interior.sync_player(Vector2(8,7),Vector2.UP,true)
  assert(interior.player.motion.current_animation=="walk")
  interior.queue_free()
 print("PRESENTATION PASS: 3 district scenes; batched persistent geometry; residents and traffic; articulated AnimationPlayer walk/idle; moving Lia; three post-apocalyptic story stages; clinic and archive interior scenes")
 get_tree().quit()
