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
static func normalize(p:Dictionary,kind:String):
 var set=moves(int(p.id),kind,int(p.level))
 if not p.get("pp",null) is Array or p.pp.size()!=4: p["pp"]=set.map(func(m):return m.max_pp)
 for i in range(4): p.pp[i]=clampi(int(p.pp[i]),0,int(set[i].max_pp))
 if not p.get("status","") in STATUS_NAMES: p["status"]=""
 if not p.has("status"): p["status"]=""
 p["sleep_turns"]=clampi(int(p.get("sleep_turns",0)),0,3)
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
