extends "res://campaign_game.gd"
func _ready():
 super._ready()
 Engine.time_scale=30.0
 call_deferred("run_checks")
func fresh():
 reset_game()
 party=[mon(25,8),mon(7,8)]
 active=0
 mode="world"
func route_to(goal:Vector2i):
 var queue=[pos]
 var previous={pos:pos}
 while not queue.is_empty():
  var cell=queue.pop_front()
  if cell==goal: break
  for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next=cell+dir
   if not previous.has(next) and (interior_walkable(next) if interior_id!="" else walkable(next)):
    previous[next]=cell
    queue.append(next)
 assert(previous.has(goal),"Quest location must be reachable: "+str(goal))
 var path=[]
 var cell=goal
 while cell!=pos:
  path.push_front(cell-previous[cell])
  cell=previous[cell]
 encounter_grace=999
 for dir in path: move_player(dir)
 assert(pos==goal)
func run_checks():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 fresh()
 for id in SPECIES:
  var creature=mon(id,5)
  assert(creature.pp.size()==4 and move_set(creature).size()==4)
  assert(move_set(creature)[1].power==40)
  creature.level=8
  assert(move_set(creature)[1].power==60)
 # Old saves gain a move set without losing HP, identity, or implants.
 var old={"id":25,"level":5,"hp":3,"maxhp":18,"xp":0,"implant":2}
 CombatRules.normalize(old,"ELÉCTRICO")
 assert(old.hp==3 and old.implant==2 and old.pp.size()==4)
 assert(not CombatRules.can_status(mon(4,5),"burn","FUEGO"))
 assert(not CombatRules.can_status(mon(25,5),"paralysis","ELÉCTRICO"))
 old.status="paralysis"
 var slowed=CombatRules.speed(old)
 old.status=""
 assert(CombatRules.speed(old)>slowed)
 start_battle(mon(7,20))
 enemy.pp=[35,0,0,0]
 var spent=party[active].pp[0]
 await perform_move(party[active],enemy,0,true)
 assert(party[active].pp[0]==spent-1)
 party[active].pp[0]=0
 var cycles=enemy_cycles
 action("move:0")
 assert(enemy_cycles==cycles and not turn_locked,"Empty PP should reject without spending a turn")
 party[active].status="sleep"
 party[active].sleep_turns=2
 spent=party[active].pp[1]
 await perform_move(party[active],enemy,1,true)
 assert(party[active].pp[1]==spent and party[active].sleep_turns==1)
 await perform_move(party[active],enemy,1,true)
 assert(party[active].status=="" and party[active].pp[1]==spent-1)
 party[active].status="burn"
 var hp=party[active].hp
 residual_damage()
 assert(party[active].hp<hp)
 heal_party()
 assert(party[0].status=="" and party[0].pp[0]==35)
 var switch_cycles=enemy_cycles
 await switch_mon(1)
 assert(active==1 and enemy_cycles==switch_cycles+1,"Voluntary switch spends an enemy turn")
 # Experience is shared only among living participants, and stages reset on withdrawal.
 party[active]["guard"]=2
 await switch_mon(0)
 assert(party[1].guard==0)
 party[0]=mon(25,5)
 party[1]=mon(7,5)
 enemy.level=5
 battle_participants=[0,1]
 award_battle_experience()
 assert(party[0].xp==55 and party[1].xp==55)
 party[0].maxhp=999
 party[0].hp=999
 award_battle_experience()
 assert(party[0].maxhp>=999 and party[0].hp>=999,"Legacy HP must not shrink on level-up")
 # A faster lethal opponent prevents the fainted creature's queued attack.
 fresh()
 start_battle(mon(135,50))
 enemy.pp=[0,20,0,0]
 party[0].hp=1
 spent=party[0].pp[0]
 await player_attack(false)
 assert(party[0].hp==0 and party[0].pp[0]==spent and active==1)
 # Four empty slots must still allow an action, with recoil.
 fresh()
 start_battle(mon(7,20))
 party[0].pp=[0,0,0,0]
 hp=party[0].hp
 await perform_move(party[0],enemy,0,true)
 assert(party[0].hp<hp and enemy.hp<enemy.maxhp)
 # Complete mission through real door/proximity interactions, and retain location.
 fresh()
 route_to(Vector2i(7,7))
 facing=Vector2i.UP
 interact()
 assert(interior_id=="clinic")
 route_to(Vector2i(8,6))
 interact()
 assert(mode=="air_dialogue")
 action("air_accept")
 assert(air_quest==1)
 action("air_close")
 assert(save_game())
 load_game()
 assert(interior_id=="clinic" and pos==Vector2i(8,6) and air_quest==1)
 leave_interior()
 route_to(Vector2i(21,7))
 facing=Vector2i.UP
 interact()
 assert(interior_id=="archive")
 route_to(Vector2i(8,6))
 interact()
 action("air_filter")
 assert(air_quest==2)
 action("air_close")
 leave_interior()
 route_to(AIR_RELAY)
 interact()
 assert(mode=="battle" and air_drone_battle)
 party[0]=mon(25,30)
 enemy.hp=1
 await player_attack(false)
 assert(air_quest==3 and mode=="dialogue")
 action("continue")
 route_to(Vector2i(7,7))
 facing=Vector2i.UP
 interact()
 route_to(Vector2i(8,6))
 interact()
 var reward_money=money
 var reward_potions=potions
 # Simulate failed atomic save; installation and rewards must roll back.
 assert(DirAccess.make_dir_absolute(SAVE+".tmp")==OK)
 action("air_install")
 assert(air_quest==3 and money==reward_money and potions==reward_potions)
 DirAccess.remove_absolute(SAVE+".tmp")
 action("air_install")
 assert(air_quest==4 and money==reward_money+250 and potions==reward_potions+2)
 action("air_install")
 assert(money==reward_money+250 and potions==reward_potions+2)
 load_game()
 assert(air_quest==4 and interior_id=="clinic")
 # Exterior coordinates remain correct after loading and leaving the room.
 leave_interior()
 assert(pos==Vector2i(7,7) and zone==0)
 print("TACTICS PASS: 20 four-move sets; PP and migration; statuses; speed; switching; struggle; reachable 3D interiors; complete air quest; save rollback; unique reward; room persistence")
 get_tree().quit()
