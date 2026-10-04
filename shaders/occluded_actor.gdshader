shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.30,0.9,0.9,0.38);
void fragment() {
 ALBEDO=tint.rgb;
 ALPHA=tint.a;
}
