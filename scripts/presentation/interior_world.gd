extends "res://scripts/presentation/modern_world.gd"
## Reusable cutaway interiors; cells match the gameplay collision rectangles.
var oxygen_label: Label3D
@export_enum("clinic", "archive") var room_id="clinic"
func _ready():
 super._ready()
 begin_build("interior:"+room_id)
 atmosphere.fog_enabled=false
 accent=Color("80ead8") if room_id=="clinic" else Color("d6bbff")
 camera.size=12.8
 box(Vector3(8,-.2,6),Vector3(13,.4,10),Color("142431"))
 for x in range(2,15):
  for z in range(2,11):
   box(Vector3(x+.5,.015,z+.5),Vector3(.96,.03,.96),Color("283b49") if (x+z)%2==0 else Color("24333f"))
 box(Vector3(8,1.4,1.7),Vector3(13,2.8,.25),Color("334c60"))
 box(Vector3(1.7,.65,6),Vector3(.25,1.3,9),Color("334c60"))
 box(Vector3(8,2.5,1.9),Vector3(12,.045,.035),accent,true)
 var title_label=text_sign("CLÍNICA / AIRE COMÚN" if room_id=="clinic" else "OAK / ARCHIVO VIVO",Vector3(8,2,2.5),accent,32)
 title_label.no_depth_test=true
 for x in [3.5,12.5]: light(Vector3(x,3,6),accent,2.0,6.0)
 if room_id=="clinic":
  for x in [3,11]:
   for z in [3,6]:
    box(Vector3(x+1,.35,z+1),Vector3(1.8,.7,1.8),Color("324e61"))
    box(Vector3(x+1,.77,z+1),Vector3(1.65,.15,1.75),Color("b0d1d1"))
    box(Vector3(x+1,.9,z+.5),Vector3(1.4,.2,.5),Color("ebeee0"))
    cylinder(Vector3(x+.15,.85,z+.4),.12,1.7,Color("77a5ba"))
    box(Vector3(x+.15,1.6,z+.4),Vector3(.5,.4,.15),accent,true)
  kiosk(Vector3(8.5,0,3.5),accent)
  oxygen_label=text_sign("FILTRO AGOTADO",Vector3(8.5,1.9,3.5),Color("ffb193"),18)
  npc.coat_color=Color("cde4de")
 else:
  for x in [3,11]:
   for z in [3,6]:
    box(Vector3(x+1,.9,z+1),Vector3(1.8,1.8,1.8),Color("293548"))
    for level in range(4):
     box(Vector3(x+1,.3+level*.4,z+1.93),Vector3(1.6,.08,.04),accent,true)
  for x in [7,8,9]:
   cylinder(Vector3(x,.6,3.5),.3,1.2,Color("55717c"))
   cylinder(Vector3(x,1.25,3.5),.24,.1,accent,true)
  text_sign("SEMILLAS / MEMORIAS / FILTROS",Vector3(8,1.8,3.5),accent,19)
 npc.set_pose(Vector3(8.5,0,5.5),Vector2.DOWN,false)
 text_sign("SENA / E" if room_id=="clinic" else "OAK / E",Vector3(8.5,2.1,5.5),accent,18)
 text_sign("SALIDA",Vector3(8.5,.5,10.7),accent,20)
 box(Vector3(8.5,.03,10.5),Vector3(1.8,.05,.8),accent,true)
 flush_geometry()
 focus=Vector3(8,0,6)
 update_camera(1.0)
func sync_player(cell:Vector2,direction:Vector2,moving:bool):
 player.set_pose(Vector3(cell.x+.5,0,cell.y+.5),direction,moving)
 focus=Vector3(8,0,6)
func update_camera(delta:float):
 camera.position=focus+Vector3(5.5,12.5,15)
 camera.look_at(focus,Vector3.UP)

func set_restored(restored:bool):
 if not oxygen_label: return
 oxygen_label.text="OXÍGENO ESTABLE" if restored else "FILTRO AGOTADO"
 oxygen_label.modulate=Color("80ead8") if restored else Color("ffb193")
