extends RefCounted
## Shared mechanical artwork for battle sprites and native portraits.
const CYAN=Color("53e8eb")
const PINK=Color("ee70c7")
static func draw(canvas:CanvasItem,id:int,at:Vector2,size:float,back:bool,alpha:float,clock:float):
 # These six designs use high-resolution illustrated bases with bespoke live
 # mechanical geometry. The augmentations animate, rotate and emit light.
 var origin=at+Vector2(size if back else 0,0)
 canvas.draw_set_transform(origin,0,Vector2(-size if back else size,size)/475.0)
 var c=CYAN
 var pink=PINK
 c.a=alpha
 pink.a=alpha
 var steel=Color(.16,.24,.34,alpha)
 var rim=Color(.52,.66,.73,alpha)
 if id==6:
  for pts in [PackedVector2Array([Vector2(34,210),Vector2(126,124),Vector2(158,192),Vector2(208,216),Vector2(134,226)]),PackedVector2Array([Vector2(296,214),Vector2(370,141),Vector2(430,190),Vector2(442,236),Vector2(367,229)])]:
   canvas.draw_colored_polygon(pts,Color(.15,.70,.85,.48*alpha))
   for i in range(pts.size()):
    canvas.draw_line(pts[i],pts[(i+1)%pts.size()],c,3,true)
    canvas.draw_line(pts[i],pts[0].lerp(pts[2],.5),Color(.49,.9,1,.45*alpha),1,true)
  canvas.draw_arc(Vector2(248,278),29,0,TAU,40,steel,12,true)
  canvas.draw_arc(Vector2(248,278),25,0,TAU,40,c,3,true)
  canvas.draw_circle(Vector2(248,278),13,steel,true,-1.0,true)
  canvas.draw_circle(Vector2(248,278),7,c,true,-1.0,true)
  glow(canvas,Vector2(248,278),28,CYAN,.11)
  canvas.draw_line(Vector2(229,91),Vector2(252,94),c,5,true)
  for q in [Vector2(143,244),Vector2(345,245)]:
   canvas.draw_circle(q,13,steel,true,-1.0,true)
   canvas.draw_arc(q,10,0,TAU,24,rim,2,true)
   canvas.draw_circle(q,4,c,true,-1.0,true)
 elif id==9:
  var plate=PackedVector2Array([Vector2(94,151),Vector2(194,125),Vector2(254,141),Vector2(273,236),Vector2(214,335),Vector2(91,353),Vector2(70,267)])
  canvas.draw_colored_polygon(plate,steel)
  for i in range(plate.size()): canvas.draw_line(plate[i],plate[(i+1)%plate.size()],rim,5,true)
  var center=Vector2(167,244)
  for q in plate:
   canvas.draw_line(q,center,c,2,true)
  canvas.draw_circle(center,48,Color("14283a"),true,-1.0,true)
  canvas.draw_arc(center,41,0,TAU,40,c,5,true)
  canvas.draw_arc(center,31,clock,clock+PI*1.6,32,pink,3,true)
  canvas.draw_circle(center,15,c,true,-1.0,true)
  glow(canvas,center,48,CYAN,.10)
  panel(canvas,Rect2(328,133,57,43),steel,rim)
  canvas.draw_line(Vector2(331,147),Vector2(381,141),c,5,true)
  canvas.draw_line(Vector2(331,163),Vector2(381,156),c,3,true)
  canvas.draw_circle(Vector2(382,148),10,Color("173a50"),true,-1.0,true)
  canvas.draw_arc(Vector2(382,148),9,0,TAU,24,c,3,true)
 elif id==25:
  canvas.draw_colored_polygon(PackedVector2Array([Vector2(126,273),Vector2(202,269),Vector2(249,293),Vector2(270,369),Vector2(142,378)]),steel)
  canvas.draw_line(Vector2(142,290),Vector2(157,364),c,4,true)
  canvas.draw_line(Vector2(237,292),Vector2(254,365),pink,4,true)
  canvas.draw_circle(Vector2(193,328),15,rim,true,-1.0,true)
  canvas.draw_circle(Vector2(193,328),10,c,true,-1.0,true)
  canvas.draw_circle(Vector2(182,204),20,steel,true,-1.0,true)
  canvas.draw_arc(Vector2(182,204),16,0,TAU,32,pink,4,true)
  canvas.draw_circle(Vector2(182,204),6,pink,true,-1.0,true)
  for i in range(4): canvas.draw_line(Vector2(89,100+i*10),Vector2(116,92+i*10),rim,5,true)
  for i in range(3):
   var q=Vector2(345+i*25,192-i*15)
   canvas.draw_line(q,q+Vector2(5,29),steel,8,true)
   canvas.draw_line(q+Vector2(3,0),q+Vector2(8,29),c,3,true)
 elif id==26:
  for q in [Vector2(81,162),Vector2(176,156)]:
   canvas.draw_circle(q,19,steel,true,-1.0,true)
   canvas.draw_arc(q,16,clock,clock+PI*1.7,32,Color("f5c574"),3,true)
   canvas.draw_circle(q,7,c,true,-1.0,true)
  for i in range(5):
   canvas.draw_line(Vector2(200+i*6,106-i*7),Vector2(213+i*5,112-i*7),rim,5,true)
  canvas.draw_arc(Vector2(129,256),32,0,TAU,32,steel,10,true)
  canvas.draw_arc(Vector2(129,256),28,0,TAU,32,pink,3,true)
  for i in range(4):
   var q=Vector2(313+i*27,244+i*11)
   canvas.draw_line(q,q+Vector2(9,25),steel,7,true)
   canvas.draw_line(q+Vector2(3,0),q+Vector2(12,25),c,2,true)
  var previous=Vector2(248,245)
  for i in range(7):
   var q=Vector2(254+i*13,245+sin(i*2+clock*17)*8)
   canvas.draw_line(previous,q,c,2,true)
   previous=q
 elif id==93:
  for q in [Vector2(80,239),Vector2(275,355)]:
   canvas.draw_arc(q,31,0,TAU,36,pink,3,true)
   for i in range(3):
    var start=q+Vector2((i-1)*14,0)
    canvas.draw_line(start,start+Vector2(-7,24),steel,12,true)
    canvas.draw_line(start+Vector2(-7,24),start+Vector2(-15,37),rim,7,true)
    canvas.draw_circle(start,5,c,true,-1.0,true)
  for i in range(9):
   var q=Vector2(160+(i*37)%222,114+(i*51)%207)
   canvas.draw_rect(Rect2(q+Vector2(sin(clock*3+i)*8,0),Vector2(15,3)),Color(.59,.45,.92,.5*alpha))
  canvas.draw_line(Vector2(259,241),Vector2(329,206),c,3,true)
  canvas.draw_circle(Vector2(298,207),7,steel,true,-1.0,true)
  canvas.draw_circle(Vector2(298,207),3,c,true,-1.0,true)
 elif id==137:
  var vertices=[Vector2(60,205),Vector2(202,109),Vector2(275,196),Vector2(369,230),Vector2(253,342),Vector2(138,327),Vector2(157,208)]
  for i in range(vertices.size()):
   canvas.draw_line(vertices[i],vertices[(i+1)%vertices.size()],c,3,true)
   canvas.draw_circle(vertices[i],5,steel,true,-1.0,true)
   canvas.draw_circle(vertices[i],2,pink,true,-1.0,true)
  canvas.draw_arc(Vector2(187,155),22,0,TAU,32,steel,8,true)
  canvas.draw_circle(Vector2(187,155),9,c,true,-1.0,true)
  var center=Vector2(293,269)
  canvas.draw_arc(center,24,clock,clock+TAU*.8,32,pink,4,true)
  for i in range(5):
   var q=center+Vector2(cos(clock+i*TAU/5),sin(clock+i*TAU/5))*43
   canvas.draw_line(center,q,Color(.37,.82,.98,.4),1,true)
   canvas.draw_circle(q,5,c,true,-1.0,true)
 canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

static func glow(canvas:CanvasItem,p:Vector2,r:float,c:Color,strength=0.12):
 for i in range(5,0,-1):
  var cc=c
  cc.a=strength*(1.0-float(i)/6.0)
  canvas.draw_circle(p,r*i/3.0,cc,true,-1.0,true)
static func panel(canvas:CanvasItem,r:Rect2,c:Color,border:Color):
 var style=StyleBoxFlat.new()
 style.bg_color=c
 style.border_color=border
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 canvas.draw_style_box(style,r)
