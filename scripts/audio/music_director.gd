extends Node
## Two bounded players crossfade composed loops; never touches the gameplay RNG.
var game
var players:Array[AudioStreamPlayer]=[]
var streams={}
var current=""
var active_slot=0
var gains=[0.0,0.0]
var victory_left=0.0
static func ensure_buses():
 for name in ["Music","SFX","Cries","Ambience"]:
  if AudioServer.get_bus_index(name)<0:
   AudioServer.add_bus()
   var index=AudioServer.bus_count-1
   AudioServer.set_bus_name(index,name)
   AudioServer.set_bus_send(index,"Master")
func setup(controller):
 game=controller
 ensure_buses()
 for key in ["title","world","wild","trainer","warden","victory"]:
  var stream=load("res://assets/audio/music/"+key+".wav").duplicate()
  stream.loop_mode=AudioStreamWAV.LOOP_DISABLED if key=="victory" else AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin=0
  stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
  streams[key]=stream
 for i in range(2):
  var player=AudioStreamPlayer.new()
  player.bus="Music"
  player.volume_db=-80
  add_child(player)
  players.append(player)
 game.audio.bus="SFX"
 game.cry_player.bus="Cries"
func result():
 victory_left=streams.victory.get_length()-.25
 request("victory")
func desired_track()->String:
 if game.mode=="battle" and not game.enemy.is_empty() and game.enemy.hp>0:
  victory_left=0
  if game.active_warden>=0 or game.trainer=="BROCK": return "warden"
  return "wild" if game.trainer=="" else "trainer"
 if game.mode in ["title","starter","prologue"]: return "title"
 if game.mode=="settings" and game.screen_root and game.screen_root.return_mode=="title": return "title"
 if victory_left>0: return "victory"
 return "world"
func request(key:String):
 if key==current: return
 current=key
 active_slot=1-active_slot
 players[active_slot].stop()
 players[active_slot].stream=streams[key]
 gains[active_slot]=0.0
 players[active_slot].volume_db=-80
 players[active_slot].play()
func _process(delta):
 if not game or players.is_empty(): return
 var unfocused=DisplayServer.get_name()!="headless" and not get_window().has_focus()
 for player in players: player.stream_paused=unfocused
 if unfocused: return
 victory_left=maxf(0,victory_left-delta)
 request(desired_track())
 var duck=.48 if game.cry_player.playing else 1.0
 for i in range(2):
  var target=duck if i==active_slot and not game.muted else 0.0
  gains[i]=move_toward(gains[i],target,delta/0.65)
  players[i].volume_db=linear_to_db(maxf(.0001,gains[i]))-4.0
  if i!=active_slot and gains[i]<=0: players[i].stop()
