extends RefCounted
## Reference architecture; no collisions or gameplay mutations.
const DARK=Color("263b45")
const COPPER=Color("a27553")
const AQUA=Color("75dcc8")
const AMBER=Color("e5b779")
static func facade(v,data:Array):
 var r:Rect2i=data[0]
 var clinic=data[1]=="CASA"
 var c=Vector3(r.position.x+r.size.x*.5,0,r.position.y+r.size.y*.5)
 var w=float(r.size.x)
 var d=float(r.size.y)
 var front=r.end.y
 var color=AMBER if clinic else AQUA
 var shell=Color("b5b9a6") if clinic else Color("364e52")
 v.box(c+Vector3(0,1.5,0),Vector3(w,3,d),DARK)
 v.box(c+Vector3(0,.18,0),Vector3(w+.06,.36,d+.06),Color("182c34"))
 v.box(c+Vector3(0,1.7,d/2+.01),Vector3(w-.18,2.45,.06),Color("142a32"))
 for i in range(int(w)):
  var x=r.position.x+i+.5
  v.box(Vector3(x,2.48,front+.08),Vector3(.88,.63,.12),shell)
  v.box(Vector3(x,1.97,front+.06),Vector3(.76,.26,.08),Color("53968e") if not clinic else Color("977e58"),true)
  v.box(Vector3(x,2.18,front+.19),Vector3(.91,.08,.34),DARK)
  for slat in range(3): v.box(Vector3(x,2.38+slat*.13,front+.17),Vector3(.68,.028,.05),DARK)
 for z in range(r.position.y,r.end.y):
  v.box(Vector3(r.end.x+.035,1.48,z+.5),Vector3(.12,2.42,.84),shell)
  for slat in range(4): v.box(Vector3(r.end.x+.11,.7+slat*.13,z+.5),Vector3(.05,.04,.57),DARK)
 for x in [r.position.x+.15,r.end.x-.15]:
  v.box(Vector3(x,1.51,front+.17),Vector3(.19,2.95,.29),COPPER)
  for y in [.5,1.4,2.3]: v.box(Vector3(x,y,front+.2),Vector3(.29,.1,.35),DARK)
 v.box(c+Vector3(0,3.04,0),Vector3(w+.26,.18,d+.26),shell)
 v.box(c+Vector3(0,3.17,0),Vector3(w-.25,.12,d-.25),Color("1c3037"))
 for z in [-d/2+.1,d/2-.1]: v.box(c+Vector3(0,3.28,z),Vector3(w,.23,.15),shell)
 for x in [-w/2+.1,w/2-.1]: v.box(c+Vector3(x,3.28,0),Vector3(.15,.23,d),shell)
 for i in range(3):
  var q=c+Vector3(-1.3+i*1.05,3.6,-.3)
  if clinic:
   v.cylinder(q,.3,.85,Color("819e9d"))
   for h in [-.28,.28]: v.cylinder(q+Vector3(0,h,0),.32,.08,COPPER)
   v.box(q+Vector3(0,0,.31),Vector3(.07,.42,.025),AQUA,true)
  else:
   v.box(q,Vector3(.87,.58,1.35),Color("597772"))
   for z in range(4): v.box(q+Vector3(0,.31,-.45+z*.3),Vector3(.74,.035,.075),AQUA,true)
 v.box(c+Vector3(.2,3.35,.75),Vector3(w*.6,.15,.1),COPPER)
 var door=float(r.position.x+int(r.size.x/2))+.5
 v.box(Vector3(door,.65,front+.08),Vector3(.96,1.3,.1),Color("091d27"))
 for x in [-.51,.51]: v.box(Vector3(door+x,.7,front+.16),Vector3(.1,1.4,.15),shell)
 v.box(Vector3(door,.67,front+.15),Vector3(.035,1.22,.03),color,true)
 v.box(Vector3(door,1.57,front+.38),Vector3(2.15,.14,.9),DARK)
 v.box(Vector3(door,1.55,front+.84),Vector3(2,.045,.035),color,true)
 v.box(Vector3(door+.73,.88,front+.17),Vector3(.22,.31,.08),DARK)
 v.box(Vector3(door+.73,.89,front+.22),Vector3(.15,.19,.025),AQUA,true)
 v.text_sign("CLÍNICA / AIRE COMÚN" if clinic else "OAK / ARCHIVO VIVO",Vector3(door,1.83,front+.3),color,23)
 v.text_sign("OXÍGENO COMPARTIDO" if clinic else "SEMILLAS · MEMORIAS",Vector3(c.x,3.55,front-.1),color,17)
 v.light(Vector3(door,1.25,front+.8),color,1.5,3.5)
static func paving(v,q:Vector3,kind:String,x:int,y:int):
 if kind in ["tree","water","grass","flowers"]: return
 var tone=Color("243943") if kind=="path" else Color("40505a")
 if (x*7+y*11)%5==0: tone=tone.lightened(.06)
 v.box(q+Vector3(0,.037,0),Vector3(.965,.035,.965),tone)
 if kind=="path" and x in [13,14]:
  v.box(q+Vector3(-.43 if x==13 else .43,.061,0),Vector3(.045,.02,.8),AMBER)
 if (x+2*y)%7==0:
  for i in range(4): v.box(q+Vector3(-.24+i*.16,.059,.29),Vector3(.07,.01,.23),Color("172b33"))
 if (x*3+y*7)%11==0:
  var instance=MeshInstance3D.new()
  var plane=PlaneMesh.new()
  plane.size=Vector2(.78,.61)
  instance.mesh=plane
  var wet=ShaderMaterial.new()
  wet.shader=preload("res://shaders/paleta_puddle.gdshader")
  instance.material_override=wet
  instance.position=q+Vector3(.04,.066,-.04)
  instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  v.district_root.add_child(instance)
static func plaza(v):
 for x in range(11,17):
  for z in [8.15,9.85]: v.box(Vector3(x+.5,.075,z),Vector3(.55,.014,.16),Color("9daba4"))
 for x in [12.1,15.9]:
  for z in [7.7,10.3]:
   v.box(Vector3(x,.065,z),Vector3(.25,.055,.45),DARK)
   v.box(Vector3(x,.1,z),Vector3(.09,.022,.29),AQUA,true)
 v.text_sign("07 / REFUGIO",Vector3(14,1.65,1),AMBER,32)

static func vegetation(v,q:Vector3,x:int,y:int):
 # Broad low-poly leaves; clusters vary deterministically and fit encounter cells.
 v.box(q,Vector3(.96,.09,.96),Color("263f3b"))
 for i in range(3):
  var cluster=q+Vector3((i-1)*.25,.09,((x+y+i)%3-1)*.22)
  for leaf in range(4):
   var color=Color("527c62") if (leaf+i)%2 else Color("769075")
   var key="leaf:"+color.to_html()
   if not v.batches.has(key):
    var mesh=SphereMesh.new()
    mesh.radius=.18
    mesh.height=.36
    mesh.radial_segments=6
    mesh.rings=3
    v.batches[key]={"mesh":mesh,"material":v.material(color),"transforms":[],"glow":false}
   var basis=Basis.from_euler(Vector3(.5,leaf*TAU/4+i,.35)).scaled(Vector3(.40,1.3,.22))
   var at=cluster+Vector3(sin(leaf*TAU/4)*.1,.16,cos(leaf*TAU/4)*.1)
   v.batches[key].transforms.append(Transform3D(basis,at))
 if (x+y)%4==0: v.box(q+Vector3(.1,.28,.1),Vector3(.06,.1,.06),AMBER,true)
static func maintenance(v):
 # Supplies stay on rooftops, so decorative props cannot obstruct routes.
 for x in [4.8,5.35]:
  v.box(Vector3(x,3.5,4),Vector3(.45,.5,.55),Color("586b63"))
  v.box(Vector3(x,3.76,4),Vector3(.48,.04,.58),COPPER)
  v.box(Vector3(x,3.53,4.29),Vector3(.28,.035,.025),AMBER)
 for x in [23,23.6]:
  v.box(Vector3(x,3.48,4),Vector3(.47,.4,.7),Color("59736c"))
  for i in range(3): v.box(Vector3(x,3.72,3.8+i*.18),Vector3(.30,.06,.08),Color("6d9b79"))
