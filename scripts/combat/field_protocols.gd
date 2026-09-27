extends RefCounted
## Field abilities use the whole team without occupying a battle move slot.
const SITES=[
 {"cell":Vector2i(10,12),"name":"AGUA PARA LOS INVISIBLES","protocol":"BIOSELLADO","types":["PLANTA","AGUA"],"chip":"chip/cryo","brief":"La cisterna de Paleta pierde agua limpia. Sella sus conductos para abastecer a quienes no tienen una identidad en la red."},
 {"cell":Vector2i(16,10),"name":"LA ÚLTIMA ENTREGA","protocol":"CORTE TÉRMICO","types":["FUEGO","BICHO","ACERO"],"chip":"chip/plasma","brief":"Un cargamento de medicinas quedó retenido bajo un cierre corporativo. Abre el precinto sin destruir las cajas."},
 {"cell":Vector2i(10,9),"name":"NOMBRES QUE NO SE BORRAN","protocol":"ENLACE FANTASMA","types":["ELÉCTRICO","FANTASMA","NORMAL"],"chip":"chip/emp","brief":"La antena de Cromo aún conserva los nombres de las personas borradas por NEXUS. Reconéctala para devolverles una señal."}
]
static func supports(creature:Dictionary,kind:String,index:int)->bool:
 if index<0 or index>=SITES.size(): return false
 var site=SITES[index]
 return kind in site.types or site.chip in creature.get("known_techniques",[])
static func ready(creature:Dictionary,kind:String,index:int)->bool:
 return int(creature.get("hp",0))>0 and int(creature.get("level",0))>=6 and supports(creature,kind,index)
