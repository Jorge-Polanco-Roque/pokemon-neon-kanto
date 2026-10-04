shader_type spatial;
render_mode cull_disabled;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float edge=length(p*vec2(1.0,1.18))+0.09*sin(p.x*16.0)*sin(p.y*12.0);
 if(edge>0.91) discard;
 ALBEDO=vec3(0.075,0.14,0.16);
 ROUGHNESS=0.16;
 METALLIC=0.65;
}
