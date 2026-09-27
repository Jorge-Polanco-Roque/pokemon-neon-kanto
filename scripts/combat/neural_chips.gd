extends RefCounted
## Reusable licenses: each creature still needs a compatible neural interface.
const CATALOG=[
 {"key":"chip/emp","name":"EMP / PULSO CERO","price":180,"tier":0,"types":["ELÉCTRICO","NORMAL","ACERO"],"description":"Descarga especial con 30% de parálisis."},
 {"key":"chip/cryo","name":"CRIO / REFRIGERANTE","price":180,"tier":0,"types":["AGUA","PLANTA","NORMAL"],"description":"Pulso de agua con 30% de interferencia."},
 {"key":"chip/plasma","name":"PLASMA / IGNICIÓN","price":260,"tier":0,"types":["FUEGO","ELÉCTRICO","ACERO"],"description":"Ráfaga de fuego con 20% de quemadura."},
 {"key":"chip/ghost","name":"UMBRAL / PAQUETE FANTASMA","price":320,"tier":1,"types":["FANTASMA","NORMAL","ELÉCTRICO"],"description":"Ataque espectral especial: atraviesa tipos distintos."},
 {"key":"chip/rail","name":"RAIL / ACELERADOR","price":360,"tier":1,"types":["ACERO","AGUA","BICHO"],"description":"Impacto físico de acero de gran potencia."},
 {"key":"chip/drone","name":"ENJAMBRE / MICROMÁQUINAS","price":420,"tier":2,"types":["BICHO","PLANTA","FANTASMA","NORMAL"],"description":"Drones de tipo Bicho: 30% de interferencia."}
]
static func find(key:String)->Dictionary:
 for entry in CATALOG:
  if entry.key==key: return entry
 return {}
static func compatible(key:String,kind:String)->bool:
 var entry=find(key)
 return not entry.is_empty() and kind in entry.types
