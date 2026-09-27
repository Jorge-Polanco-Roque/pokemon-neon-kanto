extends "res://campaign_game.gd"
var fail_save=false
var force_secondary=false
func move_set(p:Dictionary)->Array:
 var result=super.move_set(p)
 if force_secondary:
  result=result.duplicate(true)
  result[1].chance=100
 return result
func _ready():
 super._ready()
 Engine.time_scale=30.0
 call_deferred("run_chip_tests")
func save_game():
 if fail_save: return false
 return super.save_game()
func run_chip_tests():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 reset_game()
 party=[mon(25,8),mon(7,8)]
 active=0
 money=1000
 mode="world"
 action("chips")
 assert(mode=="chips")
 # Locked licenses cannot be bought; insufficient funds cannot create a license.
 action("chip_select:3")
 action("chip_buy")
 assert(chip_licenses.is_empty() and money==1000)
 action("chip_select:0")
 money=0
 action("chip_buy")
 assert(chip_licenses.is_empty() and money==0)
 money=1000
 fail_save=true
 action("chip_buy")
 assert(chip_licenses.is_empty() and money==1000)
 fail_save=false
 action("chip_buy")
 assert(chip_licenses==["chip/emp"] and money==820)
 action("chip_buy")
 assert(money==820,"Duplicate purchase must not spend credits")
 action("chip_subject:1")
 action("chip_teach")
 assert(not "chip/emp" in party[1].known_techniques)
 action("chip_subject:0")
 fail_save=true
 action("chip_teach")
 assert(not "chip/emp" in party[0].known_techniques and mode=="chips")
 fail_save=false
 action("chip_teach")
 assert(mode=="techniques" and pending_technique=="chip/emp")
 action("tech_replace:0")
 assert(party[0].techniques[0]=="chip/emp")
 party[0].pp[0]=3
 mode="world"
 assert(save_game())
 load_game()
 assert(chip_licenses==["chip/emp"] and party[0].pp[0]==3)
 action("chips")
 action("chip_teach")
 assert(mode=="chips" and party[0].pp[0]==3,"Repeated teaching cannot refill PP")
 apply_evolution(0,26)
 assert(party[0].techniques[0]=="chip/emp" and party[0].pp[0]==3)
 # Cross-type coverage: Pikachu learns a fire attack, usable by the normal battle system.
 wardens_down=[0,1]
 action("chip_select:2")
 action("chip_buy")
 action("chip_teach")
 action("tech_replace:1")
 assert(move_set(party[0])[1].type=="FUEGO")
 assert(move_set(party[0])[1].effect=="burn")
 mode="world"
 start_battle(mon(1,8))
 action("chips")
 assert(mode=="battle","Market is unavailable in combat")
 enemy.hp=10000
 enemy.maxhp=10000
 force_secondary=true
 await perform_move(party[0],enemy,1,true)
 force_secondary=false
 assert(enemy.hp<10000 and enemy.status=="burn","Chip deals damage AND applies its secondary effect")
 for entry in NeuralChips.CATALOG:
  assert(CombatRules.valid_technique(entry.key))
  var move=CombatRules.technique(entry.key,8)
  assert(move.power>0 and move.max_pp>0)
 var target=mon(7,8)
 var emp=CombatRules.technique("chip/emp",8)
 assert(not CombatRules.apply_secondary(target,emp,"AGUA",31))
 assert(CombatRules.apply_secondary(target,emp,"AGUA",30))
 assert(target.status=="paralysis")
 assert(not CombatRules.apply_secondary(target,emp,"AGUA",1),"Cannot overwrite a status")
 target=mon(25,8)
 assert(not CombatRules.apply_secondary(target,emp,"ELÉCTRICO",1),"Type immunity applies")
 var cryo=CombatRules.technique("chip/cryo",8)
 assert(CombatRules.apply_secondary(target,cryo,"ELÉCTRICO",1))
 assert(CombatRules.apply_secondary(target,cryo,"ELÉCTRICO",1))
 assert(not CombatRules.apply_secondary(target,cryo,"ELÉCTRICO",1),"Debuff is capped")
 target.hp=0
 assert(not CombatRules.apply_secondary(target,cryo,"ELÉCTRICO",1))
 # Old saves without licenses migrate to an empty list.
 mode="world"
 assert(save_game())
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 data.erase("chip_licenses")
 data.version=8
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
 load_game()
 assert(chip_licenses.is_empty())
 assert(party[0].techniques[1]=="chip/plasma","Learned moves stay with their creature")
 reset_game()
 assert(chip_licenses.is_empty())
 print("CHIPS PASS: purchase, unlocks, compatibility, save rollback, teaching, PP, evolution, migration and combat lock")
 get_tree().quit()
