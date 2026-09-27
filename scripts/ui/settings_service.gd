extends RefCounted
const PATH="user://neon_settings.cfg"
var path=PATH
var values={"fullscreen":false,"window_size":Vector2i(1600,900),"ui_scale":1.0,"volume":0.8,"muted":false,"reduced_motion":false}
func load_settings():
 var cfg=ConfigFile.new()
 if cfg.load(path)!=OK: return
 for key in values:
  var value=cfg.get_value("settings",key,values[key])
  if typeof(value)==typeof(values[key]): values[key]=value
 values.ui_scale=clampf(values.ui_scale,1.0,1.5)
 values.volume=clampf(values.volume,0.0,1.0)
 values.window_size=Vector2i(clampi(values.window_size.x,1280,3840),clampi(values.window_size.y,720,2160))
func save_settings()->bool:
 var cfg=ConfigFile.new()
 for key in values: cfg.set_value("settings",key,values[key])
 if cfg.save(path+".tmp")!=OK: return false
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func apply_audio():
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.0001,values.volume)))
 AudioServer.set_bus_mute(0,values.muted or values.volume<=0)
func fitted_window_size(available:Vector2i)->Vector2i:
 var desired:Vector2i=values.window_size
 var fit=minf(1.0,minf(float(available.x)/desired.x,float(available.y)/desired.y))
 return Vector2i(Vector2(desired)*fit)
var display_revision=0
func restore_window_geometry(window:Window):
 var usable=DisplayServer.screen_get_usable_rect(window.current_screen)
 window.size=fitted_window_size(usable.size-Vector2i(48,80))
 window.position=usable.position+(usable.size-window.size)/2
func apply_display(window:Window):
 if DisplayServer.get_name()=="headless": return
 display_revision+=1
 var revision=display_revision
 var was_fullscreen=window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
 if values.fullscreen:
  window.mode=Window.MODE_FULLSCREEN
 else:
  window.mode=Window.MODE_WINDOWED
  restore_window_geometry(window)
  # macOS finishes its native fullscreen animation after changing the mode flag.
  if was_fullscreen:
   for delay in [.6,.8]:
    await window.get_tree().create_timer(delay).timeout
    if revision!=display_revision or values.fullscreen: return
    restore_window_geometry(window)
