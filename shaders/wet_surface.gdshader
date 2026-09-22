shader_type spatial;
uniform vec3 base_color : source_color = vec3(0.09,0.14,0.18);
void fragment() {
 float stripe = sin(UV.x*103.0 + sin(UV.y*69.0)*2.0)*sin(UV.y*91.0);
 float puddle = smoothstep(0.05,0.72,stripe);
 ALBEDO = mix(base_color,base_color*0.64,puddle);
 ROUGHNESS = mix(0.58,0.17,puddle);
 METALLIC = mix(0.15,0.7,puddle);
}
