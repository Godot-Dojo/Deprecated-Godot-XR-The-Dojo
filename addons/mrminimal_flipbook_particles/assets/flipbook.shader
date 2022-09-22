shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded,shadows_disabled,ambient_light_disabled;

uniform sampler2D flipbook : hint_albedo;
uniform float progress = 0;					// [0.0, 1.0] progress of animation
uniform float frames_per_second = 25.0;
uniform int rows = 8;
uniform int columns = 8;


void vertex() {	
	// FLIPBOOK
	float frame_size_x = 1.0 / float(columns);
	float frame_size_y = 1.0 / float(rows);
	
	float x_offset = (frame_size_x * floor(progress * frames_per_second));
	UV.x = (UV.x * frame_size_x) + x_offset;
	
	float y_offset = (frame_size_y * floor(progress * frames_per_second / float(columns)));
	UV.y = (UV.y * frame_size_y) + y_offset;

	// FACE CAMERA
	// Always turn vertical axis towards camera
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],WORLD_MATRIX[1],vec4(normalize(cross(CAMERA_MATRIX[0].xyz,WORLD_MATRIX[1].xyz)), 0.0),WORLD_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(WORLD_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, 1.0, 0.0, 0.0),vec4(0.0, 0.0, length(WORLD_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}


void fragment() {
	vec4 albedo_tex = texture(flipbook, UV);
	ALBEDO = albedo_tex.rgb;
	EMISSION = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
}
