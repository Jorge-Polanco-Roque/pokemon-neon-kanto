extends "res://campaign_game.gd"

func _ready():
 super._ready()
 call_deferred("run_story_tests")

func path_to(start:Vector2i,goal:Vector2i,prologue:bool)->Array:
 var queue=[start]
 var previous={start:start}
 while not queue.is_empty():
  var cell:Vector2i=queue.pop_front()
  if cell==goal:
   var path=[]
   while cell!=start:
    var before:Vector2i=previous[cell]
    path.push_front(cell-before)
    cell=before
   return path
  for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next=cell+direction
   if not previous.has(next) and (story_walkable(next) if prologue else walkable(next)):
    previous[next]=cell
    queue.append(next)
 return []

func walk_story_to(cell:Vector2i):
 var route=path_to(story_pos,cell,true)
 assert(not route.is_empty() or story_pos==cell,"Unreachable prologue objective")
 for direction in route: move_story(direction)
 assert(story_pos==cell)

func last_text_baseline(text_value:String,width:float,size:int,start_y:float)->float:
 var baseline=start_y
 var lines=0
 for paragraph_text in text_value.split("\n"):
  var line=""
  for word in paragraph_text.split(" "):
   if font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
    lines+=1
    line=""
   line+=word+" "
  lines+=1
 return baseline+(lines-1)*(size+8)

func run_story_tests():
 # The runner changes SAVE only in a temporary test copy, never in the project.
 assert(SAVE.begins_with("/private/tmp/neon-story-"),"Use tests/run_story_tests.py to isolate saved games")
 save_exists=false
 mode="title"
 action("new")
 assert(mode=="prologue" and party.is_empty())
 var prior=story_pos
 var key=InputEventKey.new()
 key.physical_keycode=KEY_E
 key.pressed=true
 _unhandled_input(key)
 assert(story_pos==prior and intro_shot==0,"Interaction must not advance the cinematic")
 action("story_pause")
 advance_intro(10.0)
 assert(intro_elapsed==0.0,"Pause must freeze narrative time")
 action("story_pause")
 for shot in INTRO_SHOTS:
  assert(last_text_baseline(shot.text,840,22,587)<665,"Subtitle overlaps playback controls")
  advance_intro(float(shot.seconds))
 assert(mode=="starter" and prologue_complete and party.is_empty())
 for id in [1,4,7,25]:
  action("starter:"+str(id))
  assert(party[0].id==id and party[0].level==5)
  action("continue")
  assert(mode=="world")
 mode="starter"
 action("starter:1")
 action("continue")
 assert(mode=="world" and party.size()==1)
 assert(records.size()==6)
 for record in records:
  assert(last_text_baseline(record.body,489,19,284)<563,"Journal text overflows: "+record.id)
 for record in records:
  zone=int(record.zone)
  var cell=Vector2i(record.x,record.y)
  assert(not path_to(Vector2i(13,14),cell,false).is_empty(),"Unreachable record "+record.id)
  pos=cell
  mode="world"
  interact()
  assert(mode=="journal" and selected_record==record.id)
  action("journal_close")
 assert(found_records.size()==6)
 discover_record(records[0].id)
 assert(found_records.size()==6)
 for id in SPECIES:
  assert(catalog[id].has("memory") and catalog[id].memory.length()>140)
  assert(catalog[id].description.length()>30,"Keep original design text")
  assert(last_text_baseline(catalog[id].memory,374,19,205)<408,"Memory overlaps evolution: "+str(id))
 mode="world"
 save_game()
 var saved=FileAccess.get_file_as_string(SAVE)
 reset_game()
 load_game()
 assert(mode=="world" and found_records.size()==6 and prologue_complete)
 # A new game and skipping never overwrite the existing save.
 mode="title"
 action("new")
 assert(mode=="dialogue")
 action("continue")
 assert(mode=="prologue")
 action("story_skip")
 assert(mode=="starter" and prologue_skipped and not prologue_complete)
 assert(FileAccess.get_file_as_string(SAVE)==saved)
 # Loading a pre-story save bypasses the prologue and starts with no discovered logs.
 var legacy=JSON.parse_string(saved)
 legacy.erase("story")
 legacy.version=4
 var file=FileAccess.open(SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy))
 file.close()
 load_game()
 assert(mode=="world" and found_records.is_empty())
 print("STORY PASS: automatic seven-shot cinematic; pause; subtitle bounds; four starters including Pikachu; direct skip; six reachable records; 20 memories; persistence; legacy migration; existing-save preservation")
 get_tree().quit()
