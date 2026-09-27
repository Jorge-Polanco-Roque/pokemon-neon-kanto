extends RefCounted
## Deterministic layered arenas. Animation uses the game clock, never combat RNG.
static func draw(g, district:int, time:float):
 var accents=[Color("42e4bd"),Color("ff9b53"),Color("b797ff")]
 var accent=accents[clampi(district,0,2)]
 var zenith=[Color("081d28"),Color("231326"),Color("10122e")][clampi(district,0,2)]
 for y in range(50,490,2):
  g.draw_rect(Rect2(0,y,960,2),zenith.lerp(Color("182a40"),float(y-50)/440))
 # Distant towers: dark silhouettes, illuminated glass and roof beacons.
 for i in range(15):
  var x=float(i*73-20)
  var h=float(48+(i*43+district*29)%133)
  g.draw_rect(Rect2(x,269-h,57,h),Color("0b1627"))
  g.draw_rect(Rect2(x+4,272-h,49,3),Color(accent,0.28))
  for row in range(int(h/15)-1):
   for col in range(4):
    if (i+row*3+col)%5<2:
     g.draw_rect(Rect2(x+7+col*12,282-h+row*15,3,5),Color(accent,0.16+float((i+row)%3)*0.10))
  g.draw_circle(Vector2(x+28,264-h),2,Color(accent,0.5+0.3*sin(time*2+i)))
 if district==0:
  # Refuge conservatory: ribbed canopy and surviving plant beds.
  for i in range(5):
   var x=float(i*235-30)
   g.draw_line(Vector2(x,255),Vector2(x+40,62),Color("315a65"),6,true)
   g.draw_line(Vector2(x+40,62),Vector2(x+184,50),Color("487b83"),4,true)
  for i in range(10):
   var x=float(i*108+12)
   g.draw_rect(Rect2(x,244,72,26),Color("172e33"))
   for j in range(4):
    var root=Vector2(x+12+j*15,247)
    var tip=root+Vector2(sin(time*0.6+i+j)*4-9,-18-j%2*13)
    g.draw_line(root,tip,Color("397865"),3,true)
    g.draw_circle(tip,5,Color("2e7463"))
  g.draw_line(Vector2(0,268),Vector2(960,268),Color(accent,0.55),2)
 elif district==1:
  # Breach foundry: enormous heat exchanger, furnace slits and overhead ducts.
  g.draw_rect(Rect2(421,63,175,199),Color("241e30"))
  g.draw_rect(Rect2(433,72,151,182),Color("372638"))
  for i in range(6):
   var strength=0.45+0.2*sin(time*1.3+i*0.7)
   g.draw_rect(Rect2(445,90+i*25,126,10),Color(accent,strength))
   g.draw_line(Vector2(445,103+i*25),Vector2(570,103+i*25),Color("583948"),3)
  for x in [26,369,901]:
   g.draw_line(Vector2(x,50),Vector2(x,270),Color("313144"),22)
   g.draw_line(Vector2(x-5,50),Vector2(x-5,270),Color("596071"),3)
  for i in range(24):
   var x=float((i*79+410)%960)+sin(time+i)*8
   var y=270-fmod(time*(12+i%5*4)+i*31,220.0)
   g.draw_circle(Vector2(x,y),1.4,Color(accent,0.25+float(i%4)*0.1))
 else:
  # Chrome data cathedral: vertical servers and a rotating central hologram.
  for i in range(7):
   var x=float(24+i*143)
   g.draw_rect(Rect2(x,65,67,201),Color("161b37"))
   g.draw_rect(Rect2(x+5,70,57,192),Color("202541"))
   for j in range(13):
    g.draw_line(Vector2(x+12,80+j*13),Vector2(x+53,80+j*13),Color(accent,0.12+0.25*abs(sin(time*0.6+i+j))),2)
  var center=Vector2(484,177)
  g.draw_arc(center,72,0,TAU,64,Color(accent,0.28),2,true)
  g.draw_arc(center,58,time*0.5,time*0.5+PI*1.5,48,Color(accent,0.55),2,true)
  for i in range(6):
   var a=time*0.25+i*TAU/6
   g.draw_line(center,center+Vector2(cos(a),sin(a))*58,Color(accent,0.2),1,true)
 # Wet perspective floor, panel seams, puddle reflections and luminous conduits.
 g.draw_rect(Rect2(0,272,960,218),Color("0c1828"))
 for i in range(13):
  var near_x=float((i-6)*190+480)
  g.draw_line(Vector2(480+(i-6)*38,272),Vector2(near_x,490),Color("2c4051"),1,true)
 for i in range(9):
  var y=278+i*i*3.2
  g.draw_line(Vector2(0,y),Vector2(960,y),Color("293b4d"),1)
 for i in range(18):
  var x=float((i*137+district*23)%960)
  var y=float(285+(i*37)%198)
  g.draw_line(Vector2(x,y),Vector2(x+18+i%4*12,y),Color(accent,0.04+0.03*sin(time+i)),2,true)
 for side in [-1,1]:
  g.draw_line(Vector2(480+side*63,272),Vector2(480+side*315,490),Color(accent,0.16),7,true)
  g.draw_line(Vector2(480+side*63,272),Vector2(480+side*315,490),Color(accent,0.6),1,true)
 # Raised platforms, with the original combat ground anchors preserved.
 for platform in [Vector3(716,291,178),Vector3(238,455,192)]:
  var center=Vector2(platform.x,platform.y)
  var radius=Vector2(platform.z,31 if platform.x<400 else 34)
  g.ellipse_shape(center+Vector2(0,7),radius,Color("060d18"))
  g.ellipse_shape(center,radius,Color("304656"))
  g.ellipse_shape(center,radius-Vector2(4,3),Color("152a38"))
  for i in range(30):
   var a=float(i)*TAU/30
   var p=center+Vector2(cos(a)*radius.x,sin(a)*radius.y)
   var q=center+Vector2(cos(a+0.09)*radius.x,sin(a+0.09)*radius.y)
   g.draw_line(p,q,Color(accent,0.25+0.35*abs(sin(time*0.7+i*0.2))),2,true)
  g.ellipse_shape(center,Vector2(88 if platform.x<400 else 71,15),Color(0,0,0,0.5))
