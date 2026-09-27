extends "res://campaign_game.gd"
var fail_save=false
func _ready():
 super._ready()
 call_deferred("run_field_tests")
func save_game():
 if fail_save: return false
 return super.save_game()
func run_field_tests():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 reset_game()
 money=100
 var initial_potions=potions
 party=[mon(7,6),mon(4,6),mon(25,6)]
 active=0
 mode="world"
 # All new installations have reachable adjacent cells and occupy their own cell.
 for district in range(3):
  zone=district
  var target=FieldProtocols.SITES[district].cell
  assert(not walkable(target))
  var open=[Vector2i(13,8)]
  var visited={Vector2i(13,8):true}
  var reachable=false
  while not open.is_empty():
   var cell=open.pop_front()
   if cell.distance_to(target)<=1.5: reachable=true
   for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
    var next=cell+step
    if not visited.has(next) and walkable(next):
     visited[next]=true
     open.append(next)
  assert(reachable,"Field site must be reachable")
 zone=0
 pos=Vector2i(13,8)
 action("field")
 action("field_use:0")
 assert(restored_sites.is_empty() and money==100,"Remote repairs are forbidden")
 pos=Vector2i(11,12)
 action("field_use:1")
 assert(restored_sites.is_empty(),"Wrong interface rejected")
 party[0].level=5
 action("field_use:0")
 assert(restored_sites.is_empty())
 party[0].level=6
 party[0].hp=0
 action("field_use:0")
 assert(restored_sites.is_empty())
 party[0].hp=party[0].maxhp
 fail_save=true
 action("field_use:0")
 assert(restored_sites.is_empty() and money==100 and potions==initial_potions)
 fail_save=false
 for district in range(3):
  zone=district
  pos=FieldProtocols.SITES[district].cell+Vector2i.RIGHT
  mode="world"
  interact()
  assert(mode=="field" and field_site==district)
  if district==2:
   fail_save=true
   var old_money=money
   action("field_use:2")
   assert(restored_sites.size()==2 and money==old_money and not "chip/drone" in chip_licenses)
   fail_save=false
  action("field_use:"+str(district))
  assert(district in restored_sites)
  assert(corruption(district)==65)
  var balance=money
  action("field_use:"+str(district))
  assert(money==balance,"Cannot duplicate rewards")
 assert(money==1140 and potions==initial_potions+3)
 assert(chip_licenses==["chip/drone"])
 restored_sites=[]
 chip_licenses=[]
 mode="world"
 load_game()
 assert(restored_sites.size()==3 and chip_licenses==["chip/drone"])
 # A learned compatible chip supplies the field interface even when unequipped.
 var custom=mon(25,6)
 assert(not FieldProtocols.ready(custom,"ELÉCTRICO",1))
 custom.known_techniques.append("chip/plasma")
 assert(FieldProtocols.ready(custom,"ELÉCTRICO",1))
 # Old saves acquire no accidental rewards or restoration flags.
 var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
 data.erase("restored_sites")
 data.version=9
 var f=FileAccess.open(SAVE,FileAccess.WRITE)
 f.store_string(JSON.stringify(data))
 f.close()
 load_game()
 assert(restored_sites.is_empty())
 reset_game()
 assert(restored_sites.is_empty())
 print("FIELD PASS: reachability, proximity, compatibility, level, HP, save rollback, unique rewards, corruption, final license and migration")
 get_tree().quit()
