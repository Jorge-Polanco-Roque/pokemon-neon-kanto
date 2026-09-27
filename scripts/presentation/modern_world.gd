extends SubViewport
## Presentation only: receives map data and poses; does not own saves or combat.
const ACTOR = preload("res://scenes/actors/citizen.tscn")
var stage: Node3D
var camera: Camera3D
var player: Node3D
var partner: Node3D
var npc: Node3D
var district_root: Node3D
var batches = {}
var materials = {}
var visitors: Array = []
var vehicles: Array = []
var markers = {}
var focus=Vector3(13.5,0,9)
var elapsed=0.0
var field_rotors:Array=[]
var scene_key=""
var prologue_mode=false
var prologue_act=0
var accent=Color("5bd9df")
var simulation_enabled=true
var reduced_motion=false
var atmosphere: Environment
var companion_grid: AStarGrid2D
var companion_path: Array = []
var companion_goal=Vector2i(-100,-100)

func _ready():
 stage=Node3D.new()
 stage.name="World"
 add_child(stage)
 var environment=WorldEnvironment.new()
 var settings=Environment.new()
 settings.background_mode=Environment.BG_COLOR
 settings.background_color=Color("0b1622")
 settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color=Color("829cad")
 settings.ambient_light_energy=.48
 settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 settings.fog_enabled=true
 settings.fog_light_color=Color("172b3a")
 settings.fog_density=.007
 atmosphere=settings
 environment.environment=settings
 stage.add_child(environment)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-55,-28,0)
 sun.light_color=Color("b9d7e1")
 sun.light_energy=.95
 sun.shadow_enabled=true
 sun.directional_shadow_max_distance=70
 stage.add_child(sun)
 var rim=DirectionalLight3D.new()
 rim.rotation_degrees=Vector3(-22,139,0)
 rim.light_color=Color("ad647c")
 rim.light_energy=.45
 stage.add_child(rim)
 camera=Camera3D.new()
 camera.name="Camera"
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=17.5
 camera.far=120
 camera.current=true
 stage.add_child(camera)
 player=ACTOR.instantiate()
 player.name="Mara"
 stage.add_child(player)
 var tracker=Label3D.new()
 tracker.text="MARA"
 tracker.position=Vector3(0,1.97,0)
 tracker.font_size=18
 tracker.pixel_size=.008
 tracker.modulate=Color("93e8e7")
 tracker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 tracker.no_depth_test=true
 player.add_child(tracker)
 partner=ACTOR.instantiate()
 partner.name="Lia"
 partner.coat_color=Color("c69153")
 partner.accent_color=Color("ffdd9a")
 partner.actor_scale=.9
 stage.add_child(partner)
 partner.visible=false
 npc=ACTOR.instantiate()
 npc.name="Resident"
 npc.coat_color=Color("c1b7a2")
 npc.accent_color=Color("88f1c5")
 stage.add_child(npc)
 update_camera(1.0)

func material(color:Color,emission=false)->StandardMaterial3D:
 var key=color.to_html()+str(emission)
 if materials.has(key): return materials[key]
 var result=StandardMaterial3D.new()
 result.albedo_color=color
 result.roughness=.38 if emission else .68
 result.metallic=.3
 if emission:
  result.emission_enabled=true
  result.emission=color
  result.emission_energy_multiplier=1.5
 materials[key]=result
 return result

func box(at:Vector3,dimensions:Vector3,color:Color,emission=false,rotation_y=0.0):
 var key=color.to_html()+str(emission)
 if not batches.has(key): batches[key]={"material":material(color,emission),"transforms":[],"glow":emission}
 var transform=Transform3D(Basis(Vector3.UP,rotation_y).scaled(dimensions),at)
 batches[key].transforms.append(transform)

func cylinder(at:Vector3,radius:float,height:float,color:Color,emission=false):
 var item=MeshInstance3D.new()
 var shape=CylinderMesh.new()
 shape.top_radius=radius
 shape.bottom_radius=radius
 shape.height=height
 shape.radial_segments=16
 item.mesh=shape
 item.material_override=material(color,emission)
 item.position=at
 district_root.add_child(item)
 return item

func text_sign(text_value:String,at:Vector3,color:Color,size_value=34):
 var label=Label3D.new()
 label.text=text_value
 label.position=at
 label.font_size=size_value
 label.pixel_size=.017
 label.modulate=color
 label.outline_size=3
 label.outline_modulate=Color("101d2b")
 label.no_depth_test=false
 label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 district_root.add_child(label)
 return label

func light(at:Vector3,color:Color,power=1.5,radius=5.0):
 var lamp=OmniLight3D.new()
 lamp.position=at
 lamp.light_color=color
 lamp.light_energy=power
 lamp.omni_range=radius
 lamp.omni_attenuation=1.2
 district_root.add_child(lamp)

func flush_geometry():
 for key in batches:
  var batch=batches[key]
  var mesh=BoxMesh.new()
  mesh.size=Vector3.ONE
  var multimesh=MultiMesh.new()
  multimesh.transform_format=MultiMesh.TRANSFORM_3D
  multimesh.mesh=mesh
  multimesh.instance_count=batch.transforms.size()
  for i in range(batch.transforms.size()): multimesh.set_instance_transform(i,batch.transforms[i])
  var item=MultiMeshInstance3D.new()
  item.multimesh=multimesh
  item.material_override=batch.material
  if batch.glow: item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  district_root.add_child(item)
 batches.clear()

func begin_build(key:String):
 scene_key=key
 if district_root:
  stage.remove_child(district_root)
  district_root.queue_free()
 district_root=Node3D.new()
 district_root.name="District"
 stage.add_child(district_root)
 visitors=[]
 vehicles=[]
 markers={}
 field_rotors=[]
 batches={}

func set_corruption(value:int):
 if atmosphere:
  atmosphere.fog_density=.004+value*.00006
  atmosphere.fog_light_color=Color("1c3844").lerp(Color("3b3045"),value/100.0)

func add_rain():
 var rain=CPUParticles3D.new()
 rain.amount=160
 rain.lifetime=1.4
 rain.preprocess=1.4
 rain.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
 rain.emission_box_extents=Vector3(15,.1,8)
 rain.position=Vector3(14,7,8)
 rain.direction=Vector3(.1,-1,.05)
 rain.spread=3
 rain.gravity=Vector3(0,-5,0)
 rain.initial_velocity_min=4
 rain.initial_velocity_max=6
 var mesh=BoxMesh.new()
 mesh.size=Vector3(.012,.20,.012)
 rain.mesh=mesh
 var surface=StandardMaterial3D.new()
 surface.albedo_color=Color(.65,.82,.86,.28)
 surface.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 surface.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 rain.material_override=surface
 rain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 district_root.add_child(rain)

func ground():
 var plane=MeshInstance3D.new()
 var mesh=BoxMesh.new()
 mesh.size=Vector3(28,.25,16)
 plane.mesh=mesh
 var wet=ShaderMaterial.new()
 wet.shader=preload("res://shaders/wet_surface.gdshader")
 plane.material_override=wet
 plane.position=Vector3(14,-.16,8)
 district_root.add_child(plane)
 box(Vector3(14,-.43,8),Vector3(28,.6,16),Color("182632"))
 add_rain()
 # The city continues beyond the playable district rather than ending in a frame.
 for side in [-1,1]:
  for i in range(9):
   var x=14+side*(17+(i%2)*3)
   var z=-5+i*3.6
   var height=4.0+(i*7)%9
   tower(Vector3(x,height/2,z),Vector3(3.7,height,3.1),i)
 for i in range(9):
  var height=5.0+(i*3)%8
  tower(Vector3(-3+i*4,height/2,-5),Vector3(3,height,3),i)

func tower(at:Vector3,dimensions:Vector3,variant:int):
 box(at,dimensions,Color("1d303f") if variant%2 else Color("233846"))
 box(at+Vector3(0,dimensions.y/2+.1,0),Vector3(dimensions.x+.15,.22,dimensions.z+.15),Color("456071"))
 for floor_index in range(int(dimensions.y/.8)):
  for xx in range(4):
   if (xx+floor_index+variant)%4==0: continue
   box(at+Vector3((xx-1.5)*.57,-dimensions.y/2+.45+floor_index*.8,dimensions.z/2+.015),Vector3(.28,.32,.035),Color("bd9770") if (xx+variant)%3==0 else Color("427d89"),true)

func build_district(index:int,tiles:Array,structures:Array,terminals:Array,logs:Array,npc_cell:Vector2i,restored:Array=[]):
 var key="district:"+str(index)
 if scene_key==key: return
 begin_build(key)
 prologue_mode=false
 partner.visible=false
 npc.visible=true
 accent=[Color("65d7d5"),Color("a790e4"),Color("f080b4")][index]
 ground()
 for y in range(16):
  for x in range(28):
   var kind=tiles[y][x]
   var q=Vector3(x+.5,0,y+.5)
   if kind=="tree":
    box(q+Vector3(0,.45,0),Vector3(.94,.9,.94),Color("2c4150"))
    if (x+y)%3==0: box(q+Vector3(0,.68,.48),Vector3(.6,.08,.035),accent,true)
   elif kind=="path":
    box(q+Vector3(0,.01,0),Vector3(1,.025,1),Color("142632"))
    if x==13: box(q+Vector3(-.46,.05,0),Vector3(.05,.025,1),accent.darkened(.2),true)
    if x==14: box(q+Vector3(.46,.05,0),Vector3(.05,.025,1),accent.darkened(.2),true)
    if x==13 and y%2==0: box(q+Vector3(.5,.05,0),Vector3(.035,.025,.42),Color("b9b4a2"))
   elif kind=="water":
    var surface=MeshInstance3D.new()
    var mesh=PlaneMesh.new()
    mesh.size=Vector2(1,1)
    surface.mesh=mesh
    var water=ShaderMaterial.new()
    water.shader=preload("res://shaders/water.gdshader")
    surface.material_override=water
    surface.position=q+Vector3(0,.04,0)
    district_root.add_child(surface)
    if (x+y)%5==0: box(q+Vector3(0,.06,0),Vector3(.52,.02,.025),Color("347381"),true)
   elif kind in ["grass","flowers"]:
    box(q,Vector3(.98,.08,.98),Color("203f3e"))
    for j in range(3):
     var at=q+Vector3((j-1)*.23,.22,.14-j*.13)
     box(at,Vector3(.06,.48,.07),Color("628c75"),false,.4*j)
     box(at+Vector3(.07,.13,0),Vector3(.25,.10,.08),Color("467568"),false,.7)
     if (x+y+j)%3==0: box(at+Vector3(0,.27,0),Vector3(.10,.10,.10),accent,true)
   else:
    if x%3==0: box(q+Vector3(-.48,.012,0),Vector3(.025,.016,1),Color("475966"))
    if y%2==0: box(q+Vector3(0,.012,-.48),Vector3(1,.016,.025),Color("475966"))
 for building_data in structures: building(building_data,index)
 for i in range(terminals.size()):
  var q=Vector3(terminals[i].x+.5,0,terminals[i].y+.5)
  kiosk(q,accent)
  text_sign("E / RED",q+Vector3(0,1.8,0),accent,22)
 for entry in logs:
  if int(entry.zone)==index:
   var q=Vector3(entry.x+.5,0,entry.y+.5)
   kiosk(q,Color("eec882"),.7)
   text_sign("ARCHIVO",q+Vector3(0,1.3,0),Color("eec882"),16)
 # Navigation is reflected in physical architecture; doors align with the grid.
 for x in [11,16]:
  lamp_post(Vector3(x,.0,8.7),accent)
 if index==0:
  kiosk(Vector3(14.5,0,9.5),Color("f6c876"))
  text_sign("REGULADOR / E",Vector3(14.5,1.65,9.5),Color("f6c876"),20)
  text_sign("PALÉTA / REFUGIO 07",Vector3(14,2.2,1),accent,34)
  for i in range(3):
   cylinder(Vector3(3.5+i*1.8,.4,12),.53,.6,Color("2e5661"))
   cylinder(Vector3(3.5+i*1.8,.73,12),.44,.06,accent,true)
  box(Vector3(5,1.7,10),Vector3(6,.17,.17),Color("63858c"))
 elif index==1:
  for i in range(3):
   cylinder(Vector3(19+i*2,.95,3),.72,1.9,Color("426579"))
   cylinder(Vector3(19+i*2,1.9,3),.75,.12,accent,true)
   cylinder(Vector3(19+i*2,2.2,3),.25,.5,Color("708e9a"))
  box(Vector3(7,2.2,7.8),Vector3(9,.3,1.1),Color("304757"))
  for x in [3,7,11]: box(Vector3(x,1.05,7.8),Vector3(.25,2.1,.3),Color("526573"))
  box(Vector3(7,2.42,7.35),Vector3(9,.05,.05),accent,true)
  vehicle(Vector3(3,2.6,7.8),true)
  text_sign("LA BRECHA / TRÁNSITO SUSPENDIDO",Vector3(12,2.8,1),accent,29)
 else:
  for i in range(3): stall(Vector3(19+i*2.5,0,13),i)
  text_sign("CROMO / EL AIRE SE PAGA",Vector3(14,3,1),accent,33)
 for i in range(2): vehicle(Vector3(10+i*7,3.4+i*.3,10),false)
 build_relief_site(index,index in restored)
 npc.set_pose(Vector3(npc_cell.x+.5,0,npc_cell.y+.5),Vector2.DOWN,false)
 add_visitor([Vector3(13.2,0,3),Vector3(13.2,0,12),Vector3(14.6,0,12),Vector3(14.6,0,3)],Color("a47d5d"))
 add_visitor([Vector3(11,0,8.7),Vector3(16.5,0,8.7),Vector3(16.5,0,9.3),Vector3(11,0,9.3)],Color("487b89"))
 flush_geometry()

func building(data:Array,index:int):
 var r:Rect2i=data[0]
 var center=Vector3(r.position.x+r.size.x*.5,0,r.position.y+r.size.y*.5)
 var w=float(r.size.x)
 var d=float(r.size.y)
 var height=3.3 if data[1]!="GIMNASIO" else 4.4
 var base=Color("344b5b")
 box(center+Vector3(0,height*.5,0),Vector3(w,height,d),base)
 # Recessed glass panes and structural ribs provide depth, not painted windows.
 box(center+Vector3(0,height*.5,d*.5+.02),Vector3(w-.35,height-.38,.08),Color("102b3a"))
 for level in range(3):
  for i in range(int(w*2)-1):
   var x=-w*.5+.45+i*.5
   box(center+Vector3(x,.5+level*.8,d*.5+.075),Vector3(.31,.47,.04),Color("4a7c8c") if i%4 else Color("bd9e78"),true)
 for i in range(int(w)+1):
  box(center+Vector3(-w*.5+i,height*.5,d*.5+.14),Vector3(.09,height,.20),Color("597382"))
 for level in range(1,4): box(center+Vector3(0,level*.84,d*.5+.18),Vector3(w,.13,.25),Color("283e50"))
 # Roof: bevel-like ledges, service equipment, gardens and industrial vents.
 box(center+Vector3(0,height+.08,0),Vector3(w+.34,.22,d+.34),Color("67818b"))
 box(center+Vector3(0,height+.21,0),Vector3(w-.16,.11,d-.16),Color("243d4c"))
 for i in range(3):
  var q=center+Vector3(-w*.3+i*1.15,height+.45,-.4)
  box(q,Vector3(.8,.45,.9),Color("759199"))
  cylinder(q+Vector3(0,.25,0),.26,.05,Color("243b49"))
  box(q+Vector3(0,.28,0),Vector3(.48,.025,.03),accent,true)
 var title={"CASA":"CLÍNICA / AIRE COMÚN" if not prologue_mode else "HABITAT 07","LAB. OAK":"OAK / ARCHIVO VIVO","CENTRO":"CLÍNICA / AIRE","GIMNASIO":"NEXUS / NODO CENTRAL"}.get(data[1],"ARCHIVO")
 box(center+Vector3(0,1.17,d*.5+.44),Vector3(w+.32,.15,.9),Color("42596b"))
 box(center+Vector3(0,1.18,d*.5+.91),Vector3(w+.3,.055,.035),accent,true)
 text_sign(title,center+Vector3(0,1.70,d*.5+.35),accent,25)
 var door_x=r.position.x+int(r.size.x/2)+.5
 box(Vector3(door_x,.53,r.end.y+.04),Vector3(.82,1.08,.07),Color("0d2639"))
 box(Vector3(door_x,.55,r.end.y+.09),Vector3(.055,1.02,.025),accent,true)
 light(Vector3(door_x,1.05,r.end.y+.75),accent,2.2,4)
 if data[1]=="GIMNASIO":
  text_sign("N X",center+Vector3(0,height+1.0,0),Color("ffa7be"),64)
  box(center+Vector3(0,height+.65,0),Vector3(.14,1.1,.14),Color("72949e"))
 elif data[1]=="LAB. OAK":
  for i in range(6):
   var q=center+Vector3(w*.32,height+.6+i*.19,0)
   box(q,Vector3(.7,.06,.09),accent,true,i*.45)

func kiosk(q:Vector3,color:Color,size_value=1.0):
 box(q+Vector3(0,.46*size_value,0),Vector3(.42,.92,.35)*size_value,Color("425d6d"))
 box(q+Vector3(0,.78*size_value,.19*size_value),Vector3(.32,.3,.035)*size_value,color,true)
 box(q+Vector3(0,.49*size_value,.23*size_value),Vector3(.32,.08,.23)*size_value,Color("162b3b"))

func lamp_post(q:Vector3,color:Color):
 box(q+Vector3(0,1.25,0),Vector3(.10,2.5,.10),Color("54727f"))
 box(q+Vector3(.28,2.5,0),Vector3(.65,.10,.16),Color("668692"))
 box(q+Vector3(.3,2.44,0),Vector3(.52,.03,.12),color,true)
 light(q+Vector3(.3,2.3,0),color,2,4)

func stall(q:Vector3,variation:int):
 box(q+Vector3(0,.44,0),Vector3(1.8,.88,1.0),Color("36495a"))
 box(q+Vector3(0,1.65,0),Vector3(2.1,.13,1.35),Color("82516c") if variation%2 else Color("366879"))
 for side in [-1,1]: box(q+Vector3(side*.85,1.15,-.4),Vector3(.07,1.1,.07),Color("85959c"))
 box(q+Vector3(0,1.55,.66),Vector3(1.9,.055,.055),Color("ffd49c"),true)
 for i in range(4): box(q+Vector3(-.6+i*.4,1,.22),Vector3(.22,.28,.28),accent,true)
 light(q+Vector3(0,1.1,.8),Color("ffba7a"),1.3,3)

func add_visitor(route:Array,color:Color):
 var actor=ACTOR.instantiate()
 actor.coat_color=color
 actor.actor_scale=.94
 district_root.add_child(actor)
 actor.position=route[0]
 visitors.append({"actor":actor,"route":route,"next":1})

func vehicle(q:Vector3,train:bool):
 var root=Node3D.new()
 root.position=q
 district_root.add_child(root)
 var mesh=MeshInstance3D.new()
 var shape=BoxMesh.new()
 shape.size=Vector3(3.7,.65,.85) if train else Vector3(1.6,.3,.8)
 mesh.mesh=shape
 mesh.material_override=material(Color("608398"))
 root.add_child(mesh)
 for i in range(3 if train else 2):
  var lamp=MeshInstance3D.new()
  var panel_mesh=BoxMesh.new()
  panel_mesh.size=Vector3(.65,.27,.035) if train else Vector3(.32,.04,.83)
  lamp.mesh=panel_mesh
  lamp.material_override=material(accent,true)
  lamp.position=Vector3(-1.25+i*1.15,.04,.44) if train else Vector3(-.5+i,.02,0)
  root.add_child(lamp)
 vehicles.append({"node":root,"base":q,"train":train})

func build_prologue(act:int,completed:Array):
 var key="prologue:"+str(act)+str(completed)
 if scene_key==key: return
 var changed_act=not prologue_mode or prologue_act!=act
 begin_build(key)
 prologue_mode=true
 prologue_act=act
 companion_grid=AStarGrid2D.new()
 companion_grid.region=Rect2i(0,0,28,16)
 companion_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
 companion_grid.update()
 for y in range(16):
  for x in range(28):
   companion_grid.set_point_solid(Vector2i(x,y),x<1 or x>25 or y<1 or y>10 or (y==5 and x in [7,8,9,16,17]))
 companion_path=[]
 companion_goal=Vector2i(-100,-100)
 partner.navigating=false
 partner.visible=true
 if changed_act: partner.position=Vector3(4.5,0,8.5) if act==0 else Vector3(9.5,0,8.5)
 npc.visible=act==2
 accent=Color("e9b576") if act==0 else (Color("ec758c") if act==1 else Color("7ee0dc"))
 ground()
 # A ruined residential street; same navigation coordinates as the story grid.
 building([Rect2i(1,0,7,3),"CASA",accent],0)
 building([Rect2i(19,0,7,3),"CENTRO",accent],0)
 for x in [7,8,9,16,17]:
  box(Vector3(x+.5,.75,5.5),Vector3(.94,1.5,.94),Color("465561"))
  box(Vector3(x+.5,1.53,5.5),Vector3(.85,.06,.85),accent,true)
 # Broken elevated service deck and cables over the rationing courtyard.
 box(Vector3(13,3.8,2.6),Vector3(7,.22,.7),Color("364e60"))
 for x in [10,16]: box(Vector3(x,1.9,2.6),Vector3(.18,3.8,.22),Color("5a6b76"))
 for i in range(8):
  box(Vector3(11+i*.7,3.3+sin(i*.45)*.4,2.65),Vector3(.74,.025,.025),Color("85939b"),false,-.2+sin(i*.45)*.14)
 for i in range(5):
  box(Vector3(1.5+i*2,.13,11.8),Vector3(1.3,.26,.6),Color("4c5358"),false,i*.23)
 lamp_post(Vector3(5,0,8),accent)
 lamp_post(Vector3(23,0,8),accent)
 if act==0:
  kiosk(Vector3(20.5,0,5.5),accent)
  text_sign("AIRE / SALDO INSUFICIENTE",Vector3(20.5,2.1,5.5),accent,26)
  text_sign("SECTOR 07 / CUOTA NOCTURNA",Vector3(12,3,2),accent,27)
 elif act==1:
  var points=[Vector2i(6,3),Vector2i(14,7),Vector2i(22,3)]
  for i in range(3):
   var q=Vector3(points[i].x+.5,0,points[i].y+.5)
   cylinder(q+Vector3(0,.55,0),.45,1.1,Color("465d69"))
   cylinder(q+Vector3(0,1.13,0),.34,.08,Color("74dfbe") if i in completed else accent,true)
   text_sign("ABIERTA" if i in completed else "VÁLVULA "+str(i+1),q+Vector3(0,1.8,0),accent,22)
  text_sign("HABITANTES REGISTRADOS: 0",Vector3(12,3,2),accent,30)
 else:
  for i in range(3):
   var q=Vector3(18+i,0,5.5)
   cylinder(q+Vector3(0,.6,0),.38,1.2,Color("345863"))
   cylinder(q+Vector3(0,1.25,0),.34,.09,accent,true)
  text_sign("ARCHIVO / UNA RESPIRACIÓN MÁS",Vector3(19.5,2.1,5.5),accent,25)
 npc.set_pose(Vector3(21,0,6),Vector2(-1,1),false)
 add_visitor([Vector3(12,0,7),Vector3(12,0,4),Vector3(13,0,4),Vector3(13,0,7)],Color("718290"))
 flush_geometry()

func sync_player(cell:Vector2,direction:Vector2,moving:bool):
 var at=Vector3(cell.x+.5,0,cell.y+.5)
 player.set_pose(at,direction,moving)
 focus=Vector3(clampf(at.x,10,18),0,clampf(at.z-4,4,8))
 if partner.visible:
  var goal=at+Vector3(-1,0,.7) if prologue_act==0 else (Vector3(18.5,0,7.0) if prologue_act==1 else Vector3(10.5,0,7))
  if prologue_act==2:
   partner.visible=false
  elif companion_grid:
   var destination_cell=Vector2i(roundi(goal.x-.5),roundi(goal.z-.5))
   if companion_grid.is_in_boundsv(destination_cell) and companion_grid.is_point_solid(destination_cell):
    destination_cell=Vector2i(roundi(at.x-.5),roundi(at.z-.5))
   var start=Vector2i(roundi(partner.position.x-.5),roundi(partner.position.z-.5))
   if destination_cell!=companion_goal and companion_grid.is_in_boundsv(start) and companion_grid.is_in_boundsv(destination_cell):
    companion_goal=destination_cell
    companion_path=Array(companion_grid.get_id_path(start,destination_cell))
    if not companion_path.is_empty(): companion_path.pop_front()

func update_camera(delta:float):
 var desired=focus+Vector3(8,17,19)
 camera.position=desired if reduced_motion else camera.position.lerp(desired,1.0-exp(-delta*5))
 camera.look_at(focus+Vector3(0,0,-1.1),Vector3.UP)

func _process(delta):
 if simulation_enabled and not reduced_motion:
  for rotor in field_rotors: rotor.rotate_y(delta*.8)
 if not is_instance_valid(camera) or not simulation_enabled: return
 elapsed+=delta
 if partner.visible and not partner.navigating and not companion_path.is_empty():
  var point:Vector2i=companion_path.pop_front()
  partner.navigate_to(Vector3(point.x+.5,0,point.y+.5))
 update_camera(delta)
 for visitor in visitors:
  var actor=visitor.actor
  if not actor.navigating and actor.position.distance_to(player.position)>.8:
   var target:Vector3=visitor.route[visitor.next]
   if target.distance_to(player.position)<.7: continue
   actor.navigate_to(target)
   visitor.next=(visitor.next+1)%visitor.route.size()
 for child in district_root.get_children():
  if child is CPUParticles3D: child.emitting=not reduced_motion
 for transport in vehicles:
  if reduced_motion: continue
  transport.node.position=transport.base+Vector3(sin(elapsed*.22)*3.0 if transport.train else sin(elapsed*.3)*6,0 if transport.train else sin(elapsed)*.08,0)

func build_relief_site(index:int,online:bool):
 var site=preload("res://scripts/combat/field_protocols.gd").SITES[index]
 var q=Vector3(site.cell.x+.5,0,site.cell.y+.5)
 var signal_color=Color("6cf5b7") if online else Color("ffbd70")
 box(q+Vector3(0,.09,0),Vector3(.92,.18,.92),Color("253b4d"))
 for side in [-1,1]:
  box(q+Vector3(side*.41,.20,0),Vector3(.035,.07,.78),signal_color,true)
 if index==0:
  cylinder(q+Vector3(0,.65,0),.34,1.05,Color("365d6a"))
  for y in [.24,.55,.91,1.19]: cylinder(q+Vector3(0,y,0),.37,.055,signal_color,online)
  cylinder(q+Vector3(0,1.34,0),.16,.25,Color("7e9aab"))
  box(q+Vector3(0,.77,.34),Vector3(.35,.40,.08),Color("091b2b"))
  box(q+Vector3(0,.77,.39),Vector3(.25,.22,.025),signal_color,true)
 elif index==1:
  for x in [-.24,.24]:
   box(q+Vector3(x,.49,0),Vector3(.40,.57,.64),Color("677882"))
   box(q+Vector3(x,.50,.33),Vector3(.30,.08,.035),signal_color,true)
  if not online:
   box(q+Vector3(0,.62,.36),Vector3(.9,.08,.06),Color("ec8a65"),true)
  else:
   cylinder(q+Vector3(0,1.05,0),.20,.09,signal_color,true)
 else:
  box(q+Vector3(0,.70,0),Vector3(.45,1.1,.44),Color("40536c"))
  cylinder(q+Vector3(0,1.49,0),.05,.63,Color("a0b4c6"))
  var dish=cylinder(q+Vector3(0,1.84,0),.39,.09,signal_color,online)
  dish.rotation_degrees.x=35
  if online: field_rotors.append(dish)
  for y in [.40,.63,.86]: box(q+Vector3(0,y,.23),Vector3(.31,.04,.02),signal_color,true)
 text_sign(("AUXILIO / ACTIVO" if online else "AUXILIO / E"),q+Vector3(0,2.13,0),signal_color,20)
 light(q+Vector3(0,1.3,.6),signal_color,.6 if online else .3,2.0)
