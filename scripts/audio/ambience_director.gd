extends Node
## Local environments crossfade independently from the music and never touch RNG.
var game
var streams={}
var players:Array[AudioStreamPlayer]=[]
var gains=[0.0,0.0]
var current=""
var slot=0
func setup(controller):
 game=controller
 preload("res://scripts/audio/music_director.gd").ensure_buses()
 for key in ["paleta","brecha","cromo","clinic","archive"]:
  var stream=load("res://assets/audio/ambience/"+key+".wav").duplicate()
  stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin=0
  stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
  streams[key]=stream
 for i in range(2):
  var player=AudioStreamPlayer.new()
  player.bus="Ambience"
  player.volume_db=-80
  add_child(player)
  players.append(player)
func desired_track()->String:
 if game.mode in ["title","starter","battle","evolution","prologue","opening","ending"]: return ""
 if game.interior_id in ["clinic","archive"]: return game.interior_id
 return ["paleta","brecha","cromo"][clampi(game.zone,0,2)]
func request(key:String):
 if key==current: return
 current=key
 if key=="": return
 slot=1-slot
 players[slot].stop()
 players[slot].stream=streams[key]
 gains[slot]=0.0
 players[slot].volume_db=-80
 players[slot].play()
func _process(delta):
 if not game or players.is_empty(): return
 var unfocused=DisplayServer.get_name()!="headless" and not get_window().has_focus()
 for player in players: player.stream_paused=unfocused
 if unfocused: return
 request(desired_track())
 var duck=.5 if game.cry_player.playing else 1.0
 for i in range(2):
  var target=duck if i==slot and current!="" and not game.muted else 0.0
  gains[i]=move_toward(gains[i],target,delta/1.2)
  players[i].volume_db=linear_to_db(maxf(.0001,gains[i]))-4.0
  if gains[i]<=0 and (i!=slot or current==""): players[i].stop()
