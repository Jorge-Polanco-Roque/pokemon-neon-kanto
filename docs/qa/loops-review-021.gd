extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("review")
func review():
 AudioServer.set_bus_mute(0,true)
 music_director.set_process(false)
 ambience_director.set_process(false)
 var checked=[]
 for layer in [music_director,ambience_director]:
  for player in layer.players: player.stop()
  for key in layer.streams:
   if key=="victory":
    assert(layer.streams[key].loop_mode==AudioStreamWAV.LOOP_DISABLED)
    continue
   layer.request(key)
   var slot_index=layer.active_slot if layer==music_director else layer.slot
   var player=layer.players[slot_index]
   var stream=player.stream
   assert(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_begin==0)
   assert(stream.loop_end==roundi(stream.get_length()*stream.mix_rate))
   player.stream_paused=false
   player.volume_db=-4
   player.play(stream.get_length()-.3)
   await get_tree().create_timer(.9).timeout
   var position=player.get_playback_position()
   assert(player.playing and position>0 and position<2,"Loop failed: "+key)
   checked.append({"track":key,"duration":stream.get_length(),"position_after_wrap":position})
   player.stop()
 assert(checked.size()==10)
 var f=FileAccess.open("user://qa/qa-loops-021.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"native_loops":checked,"victory_plays_once":true,"master_muted":AudioServer.is_bus_mute(0),"focus_pause_disabled_in_harness":true}))
 f.close()
 get_tree().quit()
