extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("run_rear_tests")
func run_rear_tests():
 reset_game()
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rear_art_manifest.json"))
 var completed=0
 for entry in manifest.creatures:
  var id=int(entry.id)
  assert(sprites.has(str(id)))
  if entry.status!="complete":
   assert(not back_sprites.has(id))
   continue
  completed+=1
  assert(back_sprites.has(id))
  var img=back_sprites[id].get_image()
  assert(img.get_used_rect().has_area())
  assert(img.get_pixel(0,0).a<0.01,"Rear sprite must have transparent background")
  assert(back_sprites[id]!=sprites[str(id)])
  var anchor=Vector2(238,455)
  var origin=ground_origin(id,anchor,282,true)
  assert((origin+back_ground_pivots[id]*282).distance_to(anchor)<.01)
  party=[mon(id,12)]
  active=0
  start_battle(mon(id,12))
  assert(int(party[active].id)==id and int(enemy.id)==id)
  queue_redraw()
  await get_tree().process_frame
  end_battle()
 assert(completed==back_sprites.size() and completed>0)
 print("REAR PASS: ",completed," separate rear textures, transparency, ground contact and same-species battles")
 get_tree().quit()
