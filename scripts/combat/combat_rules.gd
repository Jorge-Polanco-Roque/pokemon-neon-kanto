extends RefCounted
## Battle data and deterministic calculations; no scenes, timers or save access.
const SPEED = {1:45,2:60,3:80,4:65,5:80,6:100,7:43,8:58,9:78,25:90,26:110,133:55,134:65,135:130,92:80,93:95,94:110,123:105,212:65,137:40}
const SPECIAL = {1:65,2:80,3:100,4:60,5:80,6:109,7:50,8:65,9:85,25:50,26:90,133:45,134:110,135:110,92:100,93:115,94:130,123:55,212:55,137:85}
const SPECIAL_DEF = {1:65,2:80,3:100,4:50,5:65,6:85,7:64,8:80,9:105,25:50,26:80,133:65,134:95,135:95,92:35,93:55,94:75,123:80,212:80,137:75}
const STATUS_NAMES = {"":"ESTABLE","burn":"QUEMADO","sleep":"DORMIDO","paralysis":"PARALIZADO"}
static func move_data(name_value:String,kind:String,power:int,pp:int,accuracy:int,effect="",chance=0,special=false)->Dictionary:
 return {"name":name_value,"type":kind,"power":power,"max_pp":pp,"accuracy":accuracy,"effect":effect,"chance":chance,"special":special}
static func moves(id:int,kind:String,level:int)->Array:
 var typed={"PLANTA":"LÁTIGO FOTÓNICO","FUEGO":"ASCUAS DE PLASMA","AGUA":"PULSO REFRIGERANTE","ELÉCTRICO":"ARCO VOLTAICO","NORMAL":"PULSO CINÉTICO","FANTASMA":"ECO ESPECTRAL","BICHO":"CORTE MONOFILO","ACERO":"PINZA MAGNÉTICA"}.get(kind,"PULSO")
 var effect={"PLANTA":"sleep","FUEGO":"burn","ELÉCTRICO":"paralysis","FANTASMA":"sleep"}.get(kind,"weaken")
 var control={"sleep":"ESPORAS DE SUEÑO" if kind=="PLANTA" else "SEÑAL HIPNÓTICA","burn":"FUGA TÉRMICA","paralysis":"PULSO EMP","weaken":"INTERFERENCIA"}[effect]
 return [move_data("PLACAJE","NORMAL",40,35,100),move_data(typed,kind,60 if level>=8 else 40,20,100,"",0,kind not in ["PLANTA","BICHO","ACERO"]),move_data(control,kind,0,10,75 if effect=="sleep" else 90,effect,100),move_data("BLINDAJE ADAPTATIVO","ACERO",0,15,100,"guard",100)]
const CHIP_MOVES={
 "chip/emp":["PULSO CERO","ELÉCTRICO",60,15,95,"paralysis",30,true],
 "chip/cryo":["INYECTOR CRIOGÉNICO","AGUA",60,15,100,"weaken",30,true],
 "chip/plasma":["IGNICIÓN DE PLASMA","FUEGO",70,10,90,"burn",20,true],
 "chip/ghost":["PAQUETE FANTASMA","FANTASMA",75,10,100,"",0,true],
 "chip/rail":["ACELERADOR RAIL","ACERO",90,5,90,"",0,false],
 "chip/drone":["MICROMÁQUINAS","BICHO",80,10,95,"weaken",30,true]
}
const TECH_TYPES=["PLANTA","FUEGO","AGUA","ELÉCTRICO","NORMAL","FANTASMA","BICHO","ACERO"]
static func defaults(kind:String)->Array:
 return ["strike","affinity/"+kind,"control/"+kind,"armor"]
static func valid_technique(key:String)->bool:
 if key in CHIP_MOVES or key in ["strike","armor","precision"]: return true
 return key.split("/").size()==2 and key.get_slice("/",0) in ["affinity","control","burst","pierce"] and key.get_slice("/",1) in TECH_TYPES
static func technique(key:String,level:int)->Dictionary:
 if key in CHIP_MOVES:
  var d=CHIP_MOVES[key]
  return move_data(d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7])
 if key=="strike": return move_data("PLACAJE","NORMAL",40,35,100)
 if key=="armor": return move_data("BLINDAJE ADAPTATIVO","ACERO",0,15,100,"guard",100)
 if key=="precision": return move_data("LÁSER DE PRECISIÓN","NORMAL",55,25,100,"",0,true)
 var family=key.get_slice("/",0)
 var kind=key.get_slice("/",1)
 if family=="burst":
  var title={"PLANTA":"FLORACIÓN LÁSER","FUEGO":"ESTALLIDO SOLAR","AGUA":"TORRENTE CRIOGÉNICO","ELÉCTRICO":"DESCARGA IÓNICA","NORMAL":"CAÑÓN DE IMPULSO","FANTASMA":"RUPTURA ESPECTRAL","BICHO":"ENJAMBRE DE DRONES","ACERO":"CAÑÓN FERROVIARIO"}[kind]
  return move_data(title,kind,95,5,85,"",0,true)
 if family=="pierce":
  var title={"PLANTA":"ESPINA MONOFILO","FUEGO":"GARRA DE PLASMA","AGUA":"HOJA HIDRÁULICA","ELÉCTRICO":"COLMILLO DE ARCO","NORMAL":"ARIETE CINÉTICO","FANTASMA":"CUCHILLA UMBRAL","BICHO":"GUADAÑA DE QUITINA","ACERO":"FILO DE TUNGSTENO"}[kind]
  return move_data(title,kind,75,10,100)
 return moves(1,kind,level)[1 if family=="affinity" else 2]
static func unlocks(kind:String)->Dictionary:
 return {"strike":1,"affinity/"+kind:1,"control/"+kind:1,"armor":1,"precision":6,"burst/"+kind:10,"pierce/"+kind:14}
static func normalize(p:Dictionary,kind:String):
 var initial=defaults(kind)
 if not p.get("techniques",null) is Array or p.techniques.size()!=4: p["techniques"]=initial.duplicate()
 var used=[]
 for i in range(4):
  var key=str(p.techniques[i])
  if not valid_technique(key) or key in used:
   for fallback in initial:
    if not fallback in used: key=fallback; break
  p.techniques[i]=key
  used.append(key)
 if not p.get("known_techniques",null) is Array: p["known_techniques"]=[]
 p.known_techniques=p.known_techniques.filter(func(key):return key is String and valid_technique(key))
 for key in p.techniques:
  if not key in p.known_techniques: p.known_techniques.append(key)
 var learned=unlocks(kind)
 for key in learned:
  if int(p.level)>=int(learned[key]) and not key in p.known_techniques: p.known_techniques.append(key)
 if not p.get("technique_pp",null) is Dictionary: p["technique_pp"]={}
 if not p.get("pp",null) is Array or p.pp.size()!=4:
  p["pp"]=p.techniques.map(func(key):return technique(key,int(p.level)).max_pp)
 for i in range(4):
  p.pp[i]=clampi(int(p.pp[i]),0,int(technique(p.techniques[i],int(p.level)).max_pp))
  p.technique_pp[p.techniques[i]]=p.pp[i]
 if not p.get("status","") in STATUS_NAMES: p["status"]=""
 if not p.has("status"): p["status"]=""
 p["sleep_turns"]=clampi(int(p.get("sleep_turns",0)),0,3)
static func equipped_moves(p:Dictionary,kind:String)->Array:
 if not p.has("techniques"): normalize(p,kind)
 return p.techniques.map(func(key):return technique(key,int(p.level)))
static func equip(p:Dictionary,kind:String,key:String,slot:int)->bool:
 normalize(p,kind)
 if slot<0 or slot>=4 or not key in p.known_techniques or key in p.techniques: return false
 p.techniques[slot]=key
 p.pp[slot]=clampi(int(p.technique_pp.get(key,technique(key,int(p.level)).max_pp)),0,int(technique(key,int(p.level)).max_pp))
 p.technique_pp[key]=p.pp[slot]
 return true
static func restore_pp(p:Dictionary,kind:String):
 normalize(p,kind)
 for key in p.known_techniques: p.technique_pp[key]=technique(key,int(p.level)).max_pp
 for i in range(4): p.pp[i]=p.technique_pp[p.techniques[i]]
static func stat(base:int,level:int)->int:
 return int(2.0*base*level/100.0)+5
static func speed(p:Dictionary)->int:
 var value=stat(SPEED.get(int(p.id),55),int(p.level))
 return maxi(1,value/2) if p.get("status","")=="paralysis" else value
static func can_status(p:Dictionary,effect:String,kind:String)->bool:
 if p.get("status","")!="": return false
 if effect=="burn" and kind=="FUEGO": return false
 if effect=="paralysis" and kind=="ELÉCTRICO": return false
 return effect in ["burn","sleep","paralysis"]

static func apply_secondary(defender:Dictionary,move:Dictionary,kind:String,roll:int)->bool:
 if int(defender.hp)<=0 or roll>int(move.chance) or int(move.chance)<=0: return false
 if move.effect=="weaken":
  if int(defender.get("weaken",0))>=2: return false
  defender["weaken"]=int(defender.get("weaken",0))+1
  return true
 if can_status(defender,move.effect,kind):
  defender.status=move.effect
  defender.sleep_turns=3 if move.effect=="sleep" else 0
  return true
 return false
