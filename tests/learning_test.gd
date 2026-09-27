extends "res://campaign_game.gd"
func _ready():
 super._ready()
 Engine.time_scale=30.0
 call_deferred("run_learning_tests")
func run_learning_tests():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 assert(not CombatRules.valid_technique("affinity/AGUA/invalid"))
 assert(not CombatRules.valid_technique("unknown"))
 reset_game()
 party=[mon(25,5),mon(123,14)]
 mode="party"
 action("techniques")
 assert(mode=="techniques" and party[0].techniques.size()==4)
 assert(not "precision" in party[0].known_techniques)
 action("tech_pick:precision")
 assert(pending_technique=="","Locked techniques cannot be selected")
 # Training and combat leveling both unlock through the same normalization path.
 mode="party"
 action("train")
 assert(party[0].level==6 and "precision" in party[0].known_techniques)
 action("techniques")
 party[0].pp[0]=7
 action("tech_pick:precision")
 action("tech_cancel")
 assert(party[0].techniques[0]=="strike" and party[0].pp[0]==7)
 action("tech_pick:precision")
 action("tech_replace:0")
 assert(party[0].techniques[0]=="precision" and party[0].pp[0]==25)
 party[0].pp[0]=3
 action("tech_pick:strike")
 action("tech_replace:0")
 assert(party[0].pp[0]==7,"Re-equipping cannot refill spent PP")
 action("tech_pick:precision")
 action("tech_replace:0")
 assert(party[0].pp[0]==3)
 assert(not CombatRules.equip(party[0],"ELÉCTRICO","precision",2),"Cannot equip duplicates")
 assert(not CombatRules.equip(party[0],"ELÉCTRICO","burst/ELÉCTRICO",2),"Cannot equip locked techniques")
 assert(not CombatRules.equip(party[0],"ELÉCTRICO","strike",99),"Reject invalid slots")
 mode="world"
 assert(save_game())
 party=[]
 load_game()
 assert(party[0].techniques[0]=="precision" and party[0].pp[0]==3)
 assert(CombatRules.equip(party[0],"ELÉCTRICO","strike",0))
 assert(party[0].pp[0]==7,"Reserve PP survive a save/load")
 # Clinic restores both equipped and unequipped techniques.
 heal_party()
 assert(CombatRules.equip(party[0],"ELÉCTRICO","precision",0))
 assert(party[0].pp[0]==25)
 # Evolution preserves exact move identities and unlocks the new affinity.
 var old_keys=party[1].techniques.duplicate()
 party[1].pp[1]=2
 apply_evolution(1,212)
 assert(party[1].techniques==old_keys and party[1].pp[1]==2)
 assert(move_set(party[1])[1].type=="BICHO")
 assert("affinity/ACERO" in party[1].known_techniques)
 # Storage and withdrawal retain technique state.
 mode="party"
 action("deposit:1")
 assert(archive[0].techniques==old_keys)
 action("withdraw:0")
 assert(party[1].pp[1]==2)
 # Real combat consumes PP of the selected custom technique.
 active=0
 start_battle(mon(7,30))
 var before=party[0].pp[0]
 await perform_move(party[0],enemy,0,true)
 assert(party[0].pp[0]==before-1 and "LÁSER DE PRECISIÓN" in battle_text)
 action("techniques")
 assert(mode=="battle","Cannot edit moves during battle")
 end_battle()
 # Existing v0.9 creatures migrate without touching health, status or spent PP.
 var legacy={"id":7,"level":12,"hp":4,"maxhp":32,"xp":0,"pp":[0,3,4,8],"status":"burn","implant":2}
 CombatRules.normalize(legacy,"AGUA")
 assert(legacy.pp==[0,3,4,8] and legacy.hp==4 and legacy.status=="burn" and legacy.implant==2)
 assert("burst/AGUA" in legacy.known_techniques and not "pierce/AGUA" in legacy.known_techniques)
 # Higher-level combat awards make new moves available even off the active slot.
 party=[mon(25,9)]
 party[0].xp=107
 active=0
 battle_participants=[0]
 enemy=mon(7,1)
 award_battle_experience()
 assert(party[0].level==10 and "burst/ELÉCTRICO" in party[0].known_techniques)
 print("LEARNING PASS: level unlocks; cancel/replace; no PP refill exploit; persistence; healing reserves; evolution identity; storage; custom move in combat; legacy migration; combat unlocks")
 get_tree().quit()
