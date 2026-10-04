extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("review")
func review():
 reset_game()
 party=[mon(7,8)]
 mode="world"
 muted=false
 var fx=interaction_audio
 assert(fx.players.size()==4)
 for key in fx.streams:
  assert(fx.streams[key].loop_mode==AudioStreamWAV.LOOP_DISABLED)
  assert(fx.streams[key].get_length()>0)
 for player in fx.players: assert(player.bus=="SFX")
 pos=Vector2i(13,11)
 var count=fx.step_count
 move_player(Vector2i.UP)
 assert(pos==Vector2i(13,10) and fx.step_count==count+1)
 pos=Vector2i(4,7)
 move_player(Vector2i.UP)
 assert(fx.step_count==count+1,"Blocked steps must be silent")
 enter_interior("clinic")
 move_player(Vector2i.UP)
 assert(fx.step_count==count+2)
 party[0].hp=1
 heal_party()
 assert(party[0].hp==party[0].maxhp)
 assert(fx.players[fx.cursor].stream==fx.streams.heal)
 var healing=fx.players[fx.cursor]
 fx.play_event("step")
 assert(healing.stream==fx.streams.heal)
 leave_interior()
 begin_hack()
 assert(fx.players[fx.cursor].stream==fx.streams.terminal)
 muted=true
 count=fx.step_count
 fx.play_event("step")
 assert(fx.step_count==count)
 for key in music_director.streams:
  assert(music_director.streams[key].loop_mode==(AudioStreamWAV.LOOP_DISABLED if key=="victory" else AudioStreamWAV.LOOP_FORWARD))
 print("INTERACTIONS PASS: bus, finite pool, one-shots, valid and blocked steps, interiors, healing, terminal, mute, preserved music loops")
 get_tree().quit()
