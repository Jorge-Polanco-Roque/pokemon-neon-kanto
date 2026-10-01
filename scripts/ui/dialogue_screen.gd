extends "res://scripts/ui/team_screen.gd"
## Dialogues share the controller's text and actions; presentation never awards progress.
var actions:Array=[]
func sync_frame():
 visible=game.mode in ["dialogue","air_dialogue"]
 if not visible: signature=""; return
 var next=JSON.stringify([game.mode,game.message,game.air_dialogue,game.air_quest,game.interior_id,game.campaign_save_error,shell.settings.values.ui_scale,get_viewport().get_visible_rect().size])
 if next==signature: return
 signature=next
 rebuild()
func dispatch(action_id:String):
 if game.mode not in ["dialogue","air_dialogue"]: return
 if not buttons_by_action.has(action_id): return
 game.action(action_id)
func build_contents():
 actions=[]
 note(content,"AIRE PARA LOS QUE QUEDAN" if game.mode=="air_dialogue" else "TRANSMISIÓN / NEÓN KANTO",true)
 var view=game.interior_view if game.interior_id!="" else game.modern_view
 if view:
  var preview=TextureRect.new()
  preview.texture=view.get_texture()
  preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  preview.custom_minimum_size.y=180
  content.add_child(preview)
 var text=note(content,game.air_dialogue_text() if game.mode=="air_dialogue" else game.message)
 text.focus_mode=Control.FOCUS_ALL
 if game.mode=="dialogue":
  button(footer,"CONTINUAR [E]","continue")
  return
 if game.campaign_save_error!="": note(content,game.campaign_save_error).modulate=Color("ff9eae")
 if game.air_dialogue!="objective":
  if game.interior_id=="clinic":
   if game.air_quest==0: option("Ayudar a la clínica","air_accept")
   elif game.air_quest==3: option("Instalar filtro y guardar","air_install")
   option("Recuperar equipo · gratis","air_heal")
  elif game.air_quest==1: option("Recibir membrana y localizar el dron","air_filter")
 actions.append("air_close")
 button(footer,"VOLVER [Esc]","air_close")
func option(caption:String,action_id:String):
 actions.append(action_id)
 button(content,str(actions.size())+" · "+caption,action_id)
func handle_key(key:int)->bool:
 if game.mode=="dialogue" and key in [KEY_E,KEY_ESCAPE]: dispatch("continue"); return true
 if game.mode=="air_dialogue":
  if key==KEY_ESCAPE: dispatch("air_close"); return true
  if key>=KEY_1 and key<=KEY_6:
   var index=key-KEY_1
   if index<actions.size(): dispatch(actions[index])
   return true
 return false
