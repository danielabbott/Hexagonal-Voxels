shader_type spatial;
render_mode specular_disabled;

varying vec3 vpos;

void vertex() {
	vpos = (MODELVIEW_MATRIX * vec4(VERTEX.xyz, 1.0)).xyz;	
	NORMAL = vec3(0.0);
}

void fragment() {
	NORMAL = -normalize(cross(dFdx(vpos), dFdy(vpos)));
	ALBEDO = COLOR.rgb;
}
