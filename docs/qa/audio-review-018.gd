extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("review")
func listen_for(seconds:float):
 await get_tree().create_timer(seconds).timeout
func review():
 get_window().mode=Window.MODE_WINDOWED
 get_window().size=Vector2i(1280,720)
 reset_game()
 party=[mon(7,14)]
 mode="world"
 muted=false
 AudioServer.set_bus_mute(0,true)
 var bus=AudioServer.get_bus_index("Music")
 var recorder=AudioEffectRecord.new()
 AudioServer.add_bus_effect(bus,recorder)
 recorder.set_recording_active(true)
 await listen_for(2)
 assert(music_director.current=="world")
 assert(music_director.players[music_director.active_slot].get_playback_position()>0)
 start_battle(mon(25,14))
 await listen_for(2)
 assert(music_director.current=="wild")
 trainer="AZUL"
 await listen_for(2)
 assert(music_director.current=="trainer")
 active_warden=1
 await listen_for(2)
 assert(music_director.current=="warden")
 enemy.hp=0
 music_director.result()
 await listen_for(2)
 assert(music_director.current=="victory")
 end_battle()
 await listen_for(6)
 assert(music_director.current=="world")
 assert(AudioServer.is_bus_mute(0))
 recorder.set_recording_active(false)
 var recorded=recorder.get_recording()
 assert(recorded!=null and recorded.get_length()>12)
 recorded.save_to_wav("user://qa/Neon-018-Transiciones-Godot.wav")
 screen_root.open_settings()
 screen_root.settings.values.ui_scale=1.5
 screen_root.update_layout()
 await listen_for(.3)
 RenderingServer.force_draw()
 get_viewport().get_texture().get_image().save_png("user://qa/Modern-018-Audio-Settings.png")
 var f=FileAccess.open("user://qa/qa-audio-018.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"route":["world","wild","trainer","warden","victory","world"],"mute_preserved":true,"native_playback_advances":true,"capture_seconds":recorded.get_length()}))
 f.close()
 get_tree().quit()
