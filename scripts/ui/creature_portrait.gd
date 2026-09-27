extends Control
## Draw the original illustration and its live augmentation in one native canvas.
const Augmentation=preload("res://scripts/presentation/cyber_augmentation.gd")
var game
var species_id=25
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _process(_delta):
 if is_visible_in_tree() and species_id in game.native_augmented: queue_redraw()
func _draw():
 if not game or not game.sprites.has(str(species_id)): return
 var edge=minf(size.x,size.y)
 var origin=(size-Vector2.ONE*edge)*.5
 draw_texture_rect(game.sprites[str(species_id)],Rect2(origin,Vector2.ONE*edge),false)
 if species_id in game.native_augmented:
  Augmentation.draw(self,species_id,origin,edge,false,1.0,game.clock)
