extends "res://campaign_game.gd"

func _ready():
 super._ready()
 call_deferred("run_campaign_tests")

func fresh():
 reset_game()
 action("starter:7")
 mode="world"
 party=[mon(7,30)]
 active=0
 unlocked_nodes=[0,1,2]

func run_campaign_tests():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 fresh()
 contact_warden(2)
 assert(mode=="dialogue" and active_warden==-1,"Boss sequence must be gated")
 mode="world"
 contact_warden(0)
 assert(mode=="battle" and active_warden==0 and combat_name(enemy)=="VIGÍA")
 var count=balls
 await catch_mon()
 assert(balls==count and party.size()==1,"Machines cannot be captured")
 await run_away()
 assert(mode=="battle","Cannot flee a machine")
 enemy.hp=1
 await player_attack(false)
 assert(mode=="core_choice" and pending_core==0 and 0 in wardens_down)
 load_game()
 assert(mode=="core_choice" and pending_core==0,"Pending decision survives restart")
 action("fate:reactivate")
 assert(core_fates.is_empty() and party.size()==1,"Selecting is not confirming")
 # An unwritable temporary save must preserve both the old file and every reward.
 var previous_save=FileAccess.get_file_as_string(SAVE)
 assert(DirAccess.make_dir_absolute(SAVE+".tmp")==OK)
 action("fate_confirm")
 assert(mode=="core_choice" and core_fates.is_empty() and party.size()==1)
 assert(FileAccess.get_file_as_string(SAVE)==previous_save and campaign_save_error!="")
 DirAccess.remove_absolute(SAVE+".tmp")
 action("fate_confirm")
 assert(core_fates["0"]=="reactivate" and party.size()==2 and party[1].id==25)
 var party_count=party.size()
 action("fate_confirm")
 assert(party.size()==party_count,"Do not duplicate rewards")
 zone=1
 contact_warden(1)
 thermal=0
 await enemy_turn()
 assert(thermal==15 and mode=="battle")
 complete_warden(1)
 action("fate:release")
 action("fate_confirm")
 assert(corruption(1)==0 and biosphere_score()==3)
 mode="world"
 pos=Vector2i(13,10)
 party[active].hp=10
 steps=0
 for i in range(8): move_player(Vector2i.RIGHT if i%2==0 else Vector2i.LEFT)
 assert(party[active].hp==12,"Restored biome heals every eight steps")
 zone=2
 contact_warden(2)
 enemy.hp=1
 enemy_cycles=1
 await enemy_turn()
 assert(enemy.hp>1,"NEXUS must self-repair every second turn")
 complete_warden(2)
 var prior_money=money
 action("fate:sacrifice")
 action("fate_confirm")
 assert(mode=="ending" and ending_id=="sanctuary" and money==prior_money+500)
 load_game()
 assert(core_fates.size()==3 and ending_id=="sanctuary" and mode=="world")
 action("campaign")
 action("ending_review")
 assert(mode=="ending")
 # All 27 routes produce exactly one ending, with rewards and corruption intact.
 var endings={}
 for a in CHOICE_LABELS:
  for b in CHOICE_LABELS:
   for c in CHOICE_LABELS:
    fresh()
    var choices=[a,b,c]
    for i in range(3):
     complete_warden(i)
     pending_fate=choices[i]
     commit_fate()
    assert(core_fates.size()==3 and mode=="ending")
    assert(ending_id==ending_for_score(biosphere_score()))
    endings[ending_id]=true
 assert(endings.size()==3)
 # Full teams route a reactivated companion to storage, retaining its identity.
 fresh()
 party=[mon(1,5),mon(4,5),mon(7,5),mon(25,5),mon(92,5),mon(133,5)]
 complete_warden(0)
 pending_fate="reactivate"
 commit_fate()
 assert(party.size()==6 and archive.size()==1 and archive[0].id==25)
 # Defeat leaves a machine available for a retry.
 fresh()
 party=[mon(7,1)]
 party[0].hp=1
 contact_warden(0)
 enemy.pp=[35,0,0,0] # This test specifically exercises lethal damage, not AI status choice.
 await enemy_turn()
 assert(wardens_down.is_empty() and active_warden==-1 and mode=="dialogue")
 # A v0.5 save keeps creatures, memories, implants and hacked nodes without
 # inventing decisions or making the old badge bypass the new campaign.
 fresh()
 found_records=[records[0].id]
 party[0].implant=2
 badge=true
 save_game()
 var old=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 old.erase("campaign")
 old.version=5
 var file=FileAccess.open(SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(old))
 file.close()
 load_game()
 assert(wardens_down.is_empty() and core_fates.is_empty())
 assert(party[0].implant==2 and found_records.size()==1 and unlocked_nodes.size()==3)
 contact_warden(2)
 assert(mode=="dialogue")
 print("CAMPAIGN PASS: boss gates; real combat victory/defeat; three machine mechanics; no capture/flee; pending choices; failed-save rollback; no duplicate rewards; biome healing; all 27 routes / 3 endings; storage; v0.5 migration")
 get_tree().quit()
