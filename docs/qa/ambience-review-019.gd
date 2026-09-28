extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("review")
func review():
 AudioServer.set_bus_mute(0,true)
 muted=false
 reset_game()
 party=[mon(7,14)]
 mode="world"
 var recorder=AudioEffectRecord.new()
 AudioServer.add_bus_effect(AudioServer.get_bus_index("Ambience"),recorder)
 recorder.set_recording_active(true)
 var checked=[]
 for key in ["paleta","brecha","cromo","clinic","archive"]:
  interior_id=key if key in ["clinic","archive"] else ""
  if interior_id=="": zone=["paleta","brecha","cromo"].find(key)
  await get_tree().create_timer(2).timeout
  assert(ambience_director.current==key)
  var player=ambience_director.players[ambience_director.slot]
  print("AMBIENCE_DEBUG ",key," playing=",player.playing," position=",player.get_playback_position()," paused=",player.stream_paused," focus=",get_window().has_focus()," gains=",ambience_director.gains)
  for attempt in range(20):
   if player.playing and player.get_playback_position()>0: break
   await get_tree().create_timer(.2).timeout
  assert(player.playing and player.get_playback_position()>0)
  player.play(23.7)
  await get_tree().create_timer(.6).timeout
  assert(player.playing and player.get_playback_position()<1.2)
  checked.append(key)
 interior_id=""
 start_battle(mon(25,14))
 await get_tree().create_timer(1.5).timeout
 assert(ambience_director.current=="")
 assert(not ambience_director.players[0].playing and not ambience_director.players[1].playing)
 end_battle()
 await get_tree().create_timer(1.5).timeout
 assert(ambience_director.current=="cromo")
 assert(AudioServer.is_bus_mute(0))
 recorder.set_recording_active(false)
 var captured=recorder.get_recording()
 captured.save_to_wav("user://qa/Neon-019-Ambientes-Godot.wav")
 var f=FileAccess.open("user://qa/qa-ambience-019.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"focus_pause_disabled_in_harness":true,"native_loops_checked":checked,"combat_silence":true,"world_return":true,"mute_preserved":true,"captured_seconds":captured.get_length()}))
 f.close()
 get_tree().quit()
