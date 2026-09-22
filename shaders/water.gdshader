shader_type spatial;
uniform vec3 tint : source_color = vec3(0.03,0.27,0.31);
void fragment() {
 float wave = sin(UV.x*63.0+TIME*.8)*cos(UV.y*71.0-TIME*.6);
 ALBEDO = tint*(0.8+wave*.12);
 ROUGHNESS = 0.22;
 METALLIC = 0.65;
 NORMAL_MAP = vec3(0.5+sin(UV.x*73.0+TIME)*.07,0.5+cos(UV.y*71.0+TIME)*.07,1.0);
}
