extends Control
var game
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta): queue_redraw()
func _draw():
 if not game: return
 draw_style_box(_panel(),Rect2(Vector2.ZERO,size))
 var origin=Vector2(12,12)
 var unit=Vector2((size.x-24)/28.0,(size.y-24)/16.0)
 draw_line(origin+Vector2(13.5*unit.x,0),origin+Vector2(13.5*unit.x,16*unit.y),Color("456774"),3)
 for structure in game.buildings():
  var rect:Rect2i=structure[0]
  draw_rect(Rect2(origin+Vector2(rect.position)*unit,Vector2(rect.size)*unit),Color("527681"))
 draw_circle(origin+Vector2(game.TERMINALS[game.zone])*unit,3,Color("ef82be"))
 var site=origin+Vector2(game.FieldProtocols.SITES[game.zone].cell)*unit
 draw_rect(Rect2(site-Vector2(3,3),Vector2(6,6)),Color("78efba") if game.zone in game.restored_sites else Color("ffd08a"))
 draw_circle(origin+Vector2(game.pos)*unit,4,Color("65efe1"))
func _panel()->StyleBoxFlat:
 var panel=StyleBoxFlat.new()
 panel.bg_color=Color(.025,.06,.09,.9)
 panel.border_color=Color("496d7c")
 panel.set_border_width_all(1)
 panel.set_corner_radius_all(8)
 return panel
