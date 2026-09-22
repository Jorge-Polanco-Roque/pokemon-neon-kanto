extends Node3D
## A self-contained visual actor. Grid collision belongs to the game controller;
## this scene owns its appearance, facing and AnimationPlayer, not gameplay state.
signal destination_reached
@export var coat_color: Color = Color("913957")
@export var accent_color: Color = Color("63e5ed")
@export var actor_scale: float = 1.0
var motion: AnimationPlayer
var torso: Node3D
var destination = Vector3.ZERO
var navigating = false
var speed = 1.3
var materials = {}

func material(color:Color,emissive=false)->StandardMaterial3D:
 var key=str(color)+str(emissive)
 if materials.has(key): return materials[key]
 var result=StandardMaterial3D.new()
 result.albedo_color=color
 result.roughness=.48
 if emissive:
  result.emission_enabled=true
  result.emission=color
  result.emission_energy_multiplier=1.7
 materials[key]=result
 return result

func part(parent:Node3D,label:String,at:Vector3,dimensions:Vector3,color:Color,emissive=false)->MeshInstance3D:
 var item=MeshInstance3D.new()
 item.name=label
 var mesh=BoxMesh.new()
 mesh.size=dimensions
 item.mesh=mesh
 item.material_override=material(color,emissive)
 item.position=at
 parent.add_child(item)
 return item

func _ready():
 scale=Vector3.ONE*actor_scale
 if has_node("Rig") and has_node("AnimationPlayer"):
  torso=get_node("Rig")
  motion=get_node("AnimationPlayer")
  for item in find_children("*","MeshInstance3D",true,false):
   if item.name in ["Coat","Sleeve","Hem","Visor","Zipper","Battery"]:
    var surface=item.material_override.duplicate()
    var color=coat_color.darkened(.2) if item.name=="Hem" else coat_color
    if item.name in ["Visor","Zipper","Battery"]:
     color=accent_color
     surface.emission=accent_color
    surface.albedo_color=color
    item.material_override=surface
  motion.play("idle")
  return
 torso=Node3D.new()
 torso.name="Rig"
 add_child(torso)
 part(torso,"Coat",Vector3(0,.89,0),Vector3(.42,.61,.25),coat_color)
 part(torso,"Hem",Vector3(0,.62,0),Vector3(.48,.20,.3),coat_color.darkened(.2))
 part(torso,"Chest",Vector3(0,.99,.14),Vector3(.22,.29,.06),Color("172434"))
 part(torso,"Zipper",Vector3(-.08,.99,.18),Vector3(.025,.24,.025),accent_color,true)
 part(torso,"Pack",Vector3(0,.92,-.22),Vector3(.3,.42,.17),Color("263d4c"))
 part(torso,"Battery",Vector3(.11,.94,-.315),Vector3(.06,.22,.035),accent_color,true)
 part(torso,"Neck",Vector3(0,1.26,0),Vector3(.14,.13,.15),Color("b78a6d"))
 part(torso,"Head",Vector3(0,1.42,.015),Vector3(.31,.32,.3),Color("ca9c7d"))
 part(torso,"Hair",Vector3(0,1.58,-.025),Vector3(.35,.12,.32),Color("15222c"))
 part(torso,"HairBack",Vector3(0,1.42,-.14),Vector3(.34,.27,.10),Color("15222c"))
 part(torso,"Mask",Vector3(0,1.35,.18),Vector3(.27,.13,.12),Color("354c57"))
 part(torso,"Visor",Vector3(0,1.47,.178),Vector3(.31,.075,.05),accent_color,true)
 for side in [-1,1]:
  var arm=Node3D.new()
  arm.name="LeftArm" if side<0 else "RightArm"
  arm.position=Vector3(side*.30,1.16,0)
  torso.add_child(arm)
  part(arm,"Sleeve",Vector3(0,-.16,0),Vector3(.15,.37,.19),coat_color)
  part(arm,"Glove",Vector3(0,-.39,.02),Vector3(.13,.13,.15),Color("192b38"))
  var leg=Node3D.new()
  leg.name="LeftLeg" if side<0 else "RightLeg"
  leg.position=Vector3(side*.12,.60,0)
  torso.add_child(leg)
  part(leg,"Trousers",Vector3(0,-.23,0),Vector3(.15,.47,.18),Color("182936"))
  part(leg,"Boot",Vector3(0,-.54,.05),Vector3(.20,.14,.32),Color("3d5260"))
 motion=AnimationPlayer.new()
 motion.name="AnimationPlayer"
 add_child(motion)
 var library=AnimationLibrary.new()
 var walk=Animation.new()
 walk.length=.7
 walk.loop_mode=Animation.LOOP_LINEAR
 for limb in ["LeftLeg","RightLeg","LeftArm","RightArm"]:
  var track=walk.add_track(Animation.TYPE_VALUE)
  walk.track_set_path(track,NodePath("Rig/"+limb+":rotation:x"))
  var direction=1.0 if limb in ["LeftLeg","RightArm"] else -1.0
  for i in range(5): walk.track_insert_key(track,i*.175,sin(i*PI*.5)*.55*direction)
 var bob=walk.add_track(Animation.TYPE_VALUE)
 walk.track_set_path(bob,NodePath("Rig:position:y"))
 for i in range(5): walk.track_insert_key(bob,i*.175,.025 if i%2 else 0.0)
 library.add_animation("walk",walk)
 var idle=Animation.new()
 idle.length=2.4
 idle.loop_mode=Animation.LOOP_LINEAR
 var breath=idle.add_track(Animation.TYPE_VALUE)
 idle.track_set_path(breath,NodePath("Rig:position:y"))
 idle.track_insert_key(breath,0.0,0.0)
 idle.track_insert_key(breath,1.2,.02)
 idle.track_insert_key(breath,2.4,0.0)
 for limb in ["LeftLeg","RightLeg","LeftArm","RightArm"]:
  var track=idle.add_track(Animation.TYPE_VALUE)
  idle.track_set_path(track,NodePath("Rig/"+limb+":rotation:x"))
  idle.track_insert_key(track,0.0,0.0)
 library.add_animation("idle",idle)
 motion.add_animation_library("",library)
 motion.play("idle")

func set_pose(at:Vector3,direction:Vector2,moving:bool):
 position=at
 if direction.length()>.01: rotation.y=atan2(direction.x,direction.y)
 if motion:
  var desired="walk" if moving else "idle"
  if motion.current_animation!=desired: motion.play(desired,.12)

func navigate_to(at:Vector3):
 destination=at
 navigating=true

func _physics_process(delta):
 if not navigating: return
 var direction=destination-position
 if direction.length()<.04:
  navigating=false
  set_pose(destination,Vector2.ZERO,false)
  destination_reached.emit()
 else:
  set_pose(position.move_toward(destination,speed*delta),Vector2(direction.x,direction.z),true)
