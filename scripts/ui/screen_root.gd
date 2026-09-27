extends CanvasLayer
## Responsive UI and a temporary, aspect-preserving adapter for legacy screens.
const Settings=preload("res://scripts/ui/settings_service.gd")
var settings=Settings.new()
var game
var root:Control
var world_texture:TextureRect
var title_screen:Control
var world_screen:VBoxContainer
var settings_screen:Control
var zone_label:Label
var status_label:Label
var objective_label:Label
var notice_label:Label
var controls:FlowContainer
var return_mode="title"
var last_layout=Vector2.ZERO
var last_mode=""
var battle_hud
var team_screen
var settings_note:Label
var theme_resource:Theme
func setup(controller):
 game=controller
 layer=20
 process_priority=10
 settings.load_settings()
 settings.apply_audio()
 settings.apply_display(get_viewport())
 game.muted=settings.values.muted
 root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root)
 theme_resource=Theme.new()
 theme_resource.default_font_size=18
 var normal=StyleBoxFlat.new()
 normal.bg_color=Color("14293a")
 normal.border_color=Color("3d6877")
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(8)
 normal.content_margin_left=16
 normal.content_margin_right=16
 normal.content_margin_top=10
 normal.content_margin_bottom=10
 theme_resource.set_stylebox("normal","Button",normal)
 var hover=normal.duplicate()
 hover.bg_color=Color("245367")
 hover.border_color=Color("68ead8")
 theme_resource.set_stylebox("hover","Button",hover)
 theme_resource.set_stylebox("focus","Button",hover)
 root.theme=theme_resource
 build_title()
 build_world()
 battle_hud=preload("res://scripts/ui/battle_hud.gd").new()
 root.add_child(battle_hud)
 battle_hud.setup(game,self)
 team_screen=preload("res://scripts/ui/team_screen.gd").new()
 root.add_child(team_screen)
 team_screen.setup(game,self)
 update_layout()
func full(node:Control):
 node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func label(parent:Node,text_value:String,size_value=18)->Label:
 var item=Label.new()
 item.text=text_value
 item.add_theme_font_size_override("font_size",size_value)
 parent.add_child(item)
 return item
func button(parent:Node,caption:String,callback:Callable)->Button:
 var item=Button.new()
 item.text=caption
 item.focus_mode=Control.FOCUS_ALL
 item.pressed.connect(callback)
 parent.add_child(item)
 return item
func background(parent:Node):
 var bg=ColorRect.new()
 bg.color=Color("081421")
 bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(bg)
 full(bg)
func build_title():
 title_screen=Control.new()
 root.add_child(title_screen)
 full(title_screen)
 background(title_screen)
 var margin=MarginContainer.new()
 title_screen.add_child(margin)
 full(margin)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,48)
 var center=CenterContainer.new()
 margin.add_child(center)
 var column=VBoxContainer.new()
 column.custom_minimum_size.x=620
 column.add_theme_constant_override("separation",18)
 center.add_child(column)
 label(column,"NEÓN KANTO / EDICIÓN 0.17",18).modulate=Color("64dfd3")
 label(column,"La deuda del aire",48)
 var description=label(column,"Un mundo roto. Un compañero. Una señal que todavía puede responder.",20)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button(column,"CONTINUAR",func():game.action("load"))
 button(column,"INICIAR PROTOCOLO",func():game.action("new"))
 button(column,"AJUSTES",open_settings)
 label(column,"F11 · Pantalla completa     M · Silenciar",16).modulate=Color("94aebf")
func build_world():
 world_screen=VBoxContainer.new()
 world_screen.add_theme_constant_override("separation",0)
 root.add_child(world_screen)
 full(world_screen)
 world_screen.offset_left=16
 world_screen.offset_right=-16
 world_screen.offset_top=8
 world_screen.offset_bottom=-10
 var header=HBoxContainer.new()
 header.add_theme_constant_override("separation",20)
 world_screen.add_child(header)
 zone_label=label(header,"",26)
 zone_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 status_label=label(header,"",16)
 button(header,"AJUSTES [F10]",open_settings).focus_mode=Control.FOCUS_NONE
 world_texture=TextureRect.new()
 world_texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 world_texture.stretch_mode=TextureRect.STRETCH_SCALE
 world_texture.size_flags_vertical=Control.SIZE_EXPAND_FILL
 world_texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 world_screen.add_child(world_texture)
 var minimap=preload("res://scripts/ui/world_minimap.gd").new()
 minimap.game=game
 world_texture.add_child(minimap)
 minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 minimap.position=Vector2(-202,14)
 minimap.size=Vector2(188,118)
 objective_label=label(world_screen,"",16)
 objective_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 notice_label=label(world_screen,"",16)
 notice_label.modulate=Color("65e2c9")
 notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 controls=HFlowContainer.new()
 controls.add_theme_constant_override("h_separation",8)
 controls.add_theme_constant_override("v_separation",6)
 world_screen.add_child(controls)
 for data in [["EQUIPO [P]","party"],["BOLSA [B]","bag"],["CÓDEX [N]","dex"],["IMPLANTES","workshop"],["RED [K]","campaign"],["ARCHIVOS","journal"],["AUXILIO [L]","field"],["CHIPS [J]","chips"],["MISIÓN","air_journal"],["GUARDAR","save"]]:
  var action_id:String=data[1]
  button(controls,data[0],func():game.action(action_id)).focus_mode=Control.FOCUS_NONE
func handles_mode()->bool:
 return game.mode in ["title","settings","party","techniques"] or (game.mode=="world" and game.modern_view!=null and game.interior_id=="")
func legacy_transform(size_value:Vector2)->Transform2D:
 var factor=minf(size_value.x/960.0,size_value.y/720.0)
 return Transform2D(0,Vector2.ONE*factor,0,(size_value-Vector2(960,720)*factor)*.5)
func update_layout():
 var size_value=get_viewport().get_visible_rect().size
 game.transform=legacy_transform(size_value)
 var scale_value:float=settings.values.ui_scale
 theme_resource.default_font_size=int(18*scale_value)
 zone_label.add_theme_font_size_override("font_size",int(26*scale_value))
 objective_label.add_theme_font_size_override("font_size",int(16*scale_value))
 status_label.add_theme_font_size_override("font_size",int(16*scale_value))
 notice_label.add_theme_font_size_override("font_size",int(16*scale_value))
 last_layout=size_value
func _process(_delta):
 if not is_instance_valid(game): return
 if get_viewport().get_visible_rect().size!=last_layout: update_layout()
 var changed=last_mode!=game.mode
 last_mode=game.mode
 title_screen.visible=game.mode=="title"
 world_screen.visible=game.mode=="world" and game.modern_view!=null and game.interior_id==""
 if settings_screen: settings_screen.visible=game.mode=="settings"
 battle_hud.sync_frame()
 team_screen.sync_frame()
 if changed:
  if game.mode!="battle":
   game.battle_canvas_width=960.0
   game.transform=legacy_transform(get_viewport().get_visible_rect().size)
  if game.mode=="title":
   var candidates=title_screen.find_children("*","Button",true,false)
   candidates[0].disabled=not game.save_exists
   (candidates[0] if game.save_exists else candidates[1]).grab_focus()

 if not world_screen.visible: return
 zone_label.text=["Paleta / Refugio 07","La Brecha","Distrito Cromo"][game.zone]
 status_label.text="CORRUPCIÓN %d%%   /   ₽%d"%[game.corruption(game.zone),game.money]
 objective_label.text="E · Interactuar   /   WASD · Mover   /   "+game.AIR_OBJECTIVES[game.air_quest]
 notice_label.text=game.notice if game.notice_time>0 else (game.radio_text if game.radio_seconds>0 else "Red de auxilio: %d/3 instalaciones restauradas"%game.restored_sites.size())
 world_texture.texture=game.modern_view.get_texture()
 var pixel_ratio=Vector2(get_viewport().size)/get_viewport().get_visible_rect().size
 var resolution=Vector2i(world_texture.size*pixel_ratio)
 if resolution.x>0 and resolution.y>0: game.modern_view.size=resolution
func open_settings():
 if game.mode not in ["title","world"]: return
 return_mode=game.mode
 game.mode="settings"
 build_settings()
func close_settings():
 game.mode=return_mode
 if settings_screen:
  settings_screen.queue_free()
  settings_screen=null
func commit():
 settings.apply_audio()
 game.muted=settings.values.muted
 update_layout()
 if game.modern_view: game.modern_view.reduced_motion=settings.values.reduced_motion
 var saved=settings.save_settings()
 if is_instance_valid(settings_note): settings_note.text="Ajustes guardados." if saved else "No se pudo guardar. Los ajustes se aplican sólo a esta sesión."
func build_settings():
 if settings_screen: settings_screen.queue_free()
 settings_screen=Control.new()
 root.add_child(settings_screen)
 full(settings_screen)
 background(settings_screen)
 var margin=MarginContainer.new()
 settings_screen.add_child(margin)
 full(margin)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,36)
 var body=VBoxContainer.new()
 body.add_theme_constant_override("separation",16)
 margin.add_child(body)
 var scroll=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.follow_focus=true
 body.add_child(scroll)
 var column=VBoxContainer.new()
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",14)
 scroll.add_child(column)
 label(column,"AJUSTES / PANTALLA Y SONIDO",30)
 label(column,"Las preferencias se guardan por separado de tu partida.",18)
 var fullscreen=CheckButton.new()
 fullscreen.text="Pantalla completa [F11]"
 fullscreen.button_pressed=settings.values.fullscreen
 column.add_child(fullscreen)
 fullscreen.toggled.connect(func(value):settings.values.fullscreen=value;settings.apply_display(get_viewport());commit())
 var sizes=OptionButton.new()
 column.add_child(sizes)
 var options=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440)]
 for i in range(options.size()):
  sizes.add_item("Ventana · %d × %d"%[options[i].x,options[i].y])
  if options[i]==settings.values.window_size: sizes.select(i)
 sizes.item_selected.connect(func(index):settings.values.window_size=options[index];settings.values.fullscreen=false;settings.apply_display(get_viewport());fullscreen.set_pressed_no_signal(false);commit())
 var scale_picker=OptionButton.new()
 column.add_child(scale_picker)
 for value in [100,125,150]: scale_picker.add_item("Interfaz adaptable · %d%%"%value)
 scale_picker.select(roundi((settings.values.ui_scale-1.0)/.25))
 scale_picker.item_selected.connect(func(index):settings.values.ui_scale=1.0+index*.25;commit())
 label(column,"Los menús clásicos mantienen su encuadre; su migración es la siguiente entrega.",16)
 label(column,"Volumen general",20)
 var volume=HSlider.new()
 volume.min_value=0
 volume.max_value=100
 volume.step=1
 volume.value=settings.values.volume*100
 volume.custom_minimum_size.y=32
 column.add_child(volume)
 volume.value_changed.connect(func(value):settings.values.volume=value/100;commit())
 var mute=CheckButton.new()
 mute.text="Silenciar [M]"
 mute.button_pressed=settings.values.muted
 column.add_child(mute)
 mute.toggled.connect(func(value):settings.values.muted=value;commit())
 var motion=CheckButton.new()
 motion.text="Reducir movimiento ambiental y suavizado de cámara"
 motion.button_pressed=settings.values.reduced_motion
 column.add_child(motion)
 motion.toggled.connect(func(value):settings.values.reduced_motion=value;commit())
 settings_note=label(column,"F11 cambia de modo de pantalla. Esc vuelve al juego.",16)
 button(body,"VOLVER [ESC]",close_settings).grab_focus()
func _input(event):
 if not event is InputEventKey or not event.pressed or event.echo: return
 if game.mode in ["party","techniques"] and team_screen.handle_key(event.physical_keycode):
  get_viewport().set_input_as_handled()
  return
 if game.mode=="battle" and battle_hud.handle_key(event.physical_keycode):
  get_viewport().set_input_as_handled()
  return
 if event.physical_keycode==KEY_F11:
  settings.values.fullscreen=not settings.values.fullscreen
  settings.apply_display(get_viewport())
  commit()
  if game.mode=="settings": build_settings()
  get_viewport().set_input_as_handled()
 elif event.physical_keycode==KEY_M:
  settings.values.muted=not settings.values.muted
  commit()
  if game.mode=="settings": build_settings()
  get_viewport().set_input_as_handled()
 elif event.physical_keycode==KEY_ESCAPE and game.mode=="settings":
  close_settings()
  get_viewport().set_input_as_handled()
 elif event.physical_keycode==KEY_F10 and game.mode in ["world","title"]:
  open_settings()
  get_viewport().set_input_as_handled()
