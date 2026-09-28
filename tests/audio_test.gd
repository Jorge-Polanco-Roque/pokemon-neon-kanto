extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("run_audio_tests")
func run_audio_tests():
 reset_game()
 party=[mon(7,14)]
 var director=music_director
 director.set_process(false)
 mode="world"
 assert(director.desired_track()=="world")
 start_battle(mon(25,10))
 cry_player.stop()
 assert(director.desired_track()=="wild")
 trainer="AZUL"
 assert(director.desired_track()=="trainer")
 active_warden=1
 assert(director.desired_track()=="warden")
 enemy.hp=0
 director.result()
 assert(director.desired_track()=="victory")
 mode="world"
 assert(director.desired_track()=="victory")
 director._process(8)
 assert(director.current=="world")
 var settings=preload("res://scripts/ui/settings_service.gd").new()
 settings.path=SAVE+".audio.cfg"
 settings.values.ambience_volume=.37
 settings.values.music_volume=.31
 settings.values.effects_volume=.52
 settings.values.cries_volume=.73
 settings.values.muted=true
 settings.apply_audio()
 assert(settings.save_settings())
 var restored=preload("res://scripts/ui/settings_service.gd").new()
 restored.path=settings.path
 restored.load_settings()
 assert(is_equal_approx(restored.values.ambience_volume,.37))
 assert(is_equal_approx(restored.values.music_volume,.31))
 assert(is_equal_approx(restored.values.effects_volume,.52))
 assert(is_equal_approx(restored.values.cries_volume,.73))
 director.request("trainer")
 director._process(.3)
 assert(AudioServer.is_bus_mute(0),"Changing music cannot unmute Master")
 for key in director.streams:
  var stream=director.streams[key]
  assert(stream.stereo and stream.mix_rate==44100)
  assert(stream.loop_mode==(AudioStreamWAV.LOOP_DISABLED if key=="victory" else AudioStreamWAV.LOOP_FORWARD))
  assert(stream.get_length()>7)
 assert(director.players.size()==2)
 assert(audio.bus=="SFX" and cry_player.bus=="Cries")
 var ambience=ambience_director
 ambience.set_process(false)
 mode="world"
 for i in range(3):
  zone=i
  assert(ambience.desired_track()==["paleta","brecha","cromo"][i])
 for room in ["clinic","archive"]:
  interior_id=room
  assert(ambience.desired_track()==room)
 interior_id=""
 zone=0
 muted=false
 ambience._process(2)
 assert(ambience.current=="paleta" and ambience.players[ambience.slot].playing)
 mode="battle"
 ambience._process(2)
 assert(ambience.current=="" and not ambience.players[0].playing and not ambience.players[1].playing)
 mode="world"
 ambience._process(2)
 assert(ambience.current=="paleta" and ambience.players[ambience.slot].playing)
 assert(AudioServer.is_bus_mute(0))
 for stream in ambience.streams.values():
  assert(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and is_equal_approx(stream.get_length(),24.0))
 print("AUDIO PASS: five environments, combat fade and return, ambience volume persistence; state selection, victory return, bounded crossfade players, loops, 44.1k stereo, separate buses, settings persistence and mute across transitions")
 get_tree().quit()
