extends Node
## Bounded SFX pool; footsteps never consume battle RNG or change music streams.
var game
var streams={}
var players:Array[AudioStreamPlayer]=[]
var cursor=0
var step_count=0
var last_ui=-1000.0
func setup(controller):
 game=controller
 preload("res://scripts/audio/music_director.gd").ensure_buses()
 for key in ["step","ui","terminal","heal"]:
  var stream=load("res://assets/audio/interactions/"+key+".wav").duplicate()
  stream.loop_mode=AudioStreamWAV.LOOP_DISABLED
  streams[key]=stream
 for i in range(4):
  var player=AudioStreamPlayer.new()
  player.bus="SFX"
  add_child(player)
  players.append(player)
func play_event(key:String):
 if game.muted or not streams.has(key): return
 if DisplayServer.get_name()!="headless" and not get_window().has_focus(): return
 if key=="ui":
  if game.clock-last_ui<.055: return
  last_ui=game.clock
 # Dedicated footstep voice cannot cut off a healing sound.
 var slot=0
 if key!="step":
  cursor=1+cursor%3
  slot=cursor
 var player=players[slot]
 player.stop()
 player.stream=streams[key]
 player.pitch_scale=1.0
 if key=="step":
  step_count+=1
  player.pitch_scale=.94 if step_count%2 else 1.06
 player.volume_db=-3 if key=="step" else -1
 player.play()
func _process(_delta):
 var paused=game.muted or (DisplayServer.get_name()!="headless" and not get_window().has_focus())
 for player in players: player.stream_paused=paused
