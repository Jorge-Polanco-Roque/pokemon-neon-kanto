extends "res://campaign_game.gd"
func _ready():
 super._ready()
 call_deferred("run_settings_tests")
func run_settings_tests():
 assert(SAVE.begins_with("/private/tmp/neon-story-"))
 var service=preload("res://scripts/ui/settings_service.gd").new()
 service.path=SAVE.get_base_dir()+"/settings.cfg"
 service.values.volume=.35
 service.values.ui_scale=1.25
 service.values.reduced_motion=true
 service.values.window_size=Vector2i(1920,1080)
 assert(service.save_settings())
 var loaded=preload("res://scripts/ui/settings_service.gd").new()
 loaded.path=service.path
 loaded.load_settings()
 assert(loaded.values.volume==.35 and loaded.values.ui_scale==1.25)
 assert(loaded.values.reduced_motion and loaded.values.window_size==Vector2i(1920,1080))
 var fitted=loaded.fitted_window_size(Vector2i(1300,780))
 assert(fitted.x<=1300 and fitted.y<=780)
 loaded.values.muted=true
 loaded.apply_audio()
 assert(AudioServer.is_bus_mute(0))
 loaded.values.muted=false
 loaded.values.volume=0
 loaded.apply_audio()
 assert(AudioServer.is_bus_mute(0))
 loaded.values.volume=.5
 loaded.apply_audio()
 assert(not AudioServer.is_bus_mute(0))
 assert(absf(AudioServer.get_bus_volume_db(0)-linear_to_db(.5))<.01)
 var cfg=ConfigFile.new()
 cfg.set_value("settings","ui_scale",7.0)
 cfg.set_value("settings","volume",-5.0)
 cfg.set_value("settings","fullscreen","wrong type")
 cfg.save(loaded.path)
 loaded.load_settings()
 assert(loaded.values.ui_scale==1.5 and loaded.values.volume==0 and not loaded.values.fullscreen)
 var adapter=preload("res://scripts/ui/screen_root.gd").new()
 for dimensions in [Vector2(1280,720),Vector2(1600,900),Vector2(1920,1080),Vector2(2560,1440),Vector2(1440,900),Vector2(3440,1440)]:
  var mapping=adapter.legacy_transform(dimensions)
  for point in [Vector2.ZERO,Vector2(960,720),Vector2(150,680),Vector2(850,100)]:
   var screen_point=mapping*point
   assert(screen_point.x>=-.01 and screen_point.x<=dimensions.x+.01)
   assert(screen_point.y>=-.01 and screen_point.y<=dimensions.y+.01)
   assert((mapping.affine_inverse()*screen_point).distance_to(point)<.01,"Legacy hit areas must round-trip")
 adapter.free()
 loaded.path=SAVE.get_base_dir()+"/missing/settings.cfg"
 assert(not loaded.save_settings())
 AudioServer.set_bus_mute(0,false)
 print("SETTINGS PASS: persistence, validation, window fit, mute/volume, six layout ratios and inverse input mapping")
 get_tree().quit()
