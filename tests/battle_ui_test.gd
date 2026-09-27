extends "res://campaign_game.gd"
func _ready():
 super._ready()
 Engine.time_scale=30
 call_deferred("run_battle_ui_tests")
func run_battle_ui_tests():
 reset_game()
 party=[mon(7,8),mon(25,8),mon(1,8),mon(4,8),mon(123,8),mon(92,8)]
 active=0
 start_battle(mon(94,8))
 var hud=preload("res://scripts/ui/battle_hud.gd").new()
 hud.game=self
 assert(hud.rows().size()==7)
 hud.handle_key(KEY_1)
 assert(battle_menu=="moves")
 party[0].pp[0]=0
 assert(not hud.rows()[0].enabled)
 hud.handle_key(KEY_1)
 assert(not turn_locked and battle_menu=="moves")
 party[0].pp=[0,0,0,0]
 assert(hud.rows()[0].text.contains("FORCEJEO") and hud.rows()[0].enabled)
 hud.handle_key(KEY_ESCAPE)
 assert(battle_menu=="main")
 turn_locked=true
 hud.handle_key(KEY_4)
 assert(battle_menu=="main" and hud.rows().is_empty())
 turn_locked=false
 hud.handle_key(KEY_4)
 assert(battle_menu=="switch" and hud.rows().size()==7)
 assert(not hud.rows()[0].enabled)
 party[2].hp=0
 assert(not hud.rows()[2].enabled)
 hud.handle_key(KEY_3)
 assert(active==0)
 hud.handle_key(KEY_2)
 assert(active==1 and turn_locked,"Switch dispatch uses the real turn-cost path")
 for frame in range(180):
  if not turn_locked: break
  await get_tree().process_frame
 assert(mode=="battle" and not turn_locked)
 battle_menu="main"
 trainer="TEST TRAINER"
 var rows=hud.rows()
 assert(not rows[1].enabled and not rows[6].enabled)
 var old_balls=balls
 hud.handle_key(KEY_2)
 assert(balls==old_balls)
 hud.handle_key(KEY_5)
 assert(mode=="battle")
 thermal=90
 overdrive=false
 hud.handle_key(KEY_O)
 assert(not overdrive)
 thermal=0
 battle_menu="moves"
 hud.handle_key(KEY_O)
 assert(overdrive,"Original O shortcut stays available from submenus")
 for width in [960.0,1280.0,2000.0]:
  battle_canvas_width=width
  var point=battle_point(Vector2(238,455))
  assert(is_equal_approx(point.x,width*238/960.0) and point.y==455)
  var origin=ground_origin(7,point,282,true)
  assert((origin+back_ground_pivots[7]*282).distance_to(point)<.01)
  assert(battle_point(Vector2(713,216)).x>point.x)
 hud.free()
 print("BATTLE_UI PASS: disabled PP, Forcejeo, locks, six-member switching, real turn cost, trainer restrictions, shortcuts and rear grounding")
 get_tree().quit()
