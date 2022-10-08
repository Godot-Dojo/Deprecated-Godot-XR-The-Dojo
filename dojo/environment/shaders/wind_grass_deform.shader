/** A grass shader by Toadile for Godot 3.x
 * Copies, modififications, and redistrubitions are allowed and encouranged.
 * For best effect, make sure that the quad/geometry is twice the width that is 
 * normal. In most cases, a quad that is 2 by 1 will be sufficient for the grass
 * -object interaction effect to be convincing. 
 *
 * Since the grass bending uses screen space, to use SSAO and other post 
 * processing on it, the displacement portion would have to be commented out in 
 * the fragment function to enable SSAO
 */

shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

// general parameters
uniform float y_offset = 0.5;
uniform vec4 base_color : hint_color = vec4(1.0);
uniform vec4 end_color : hint_color = vec4(1.0);
uniform float specular: hint_range(0,1) = 0.1;
uniform float metallic: hint_range(0,1) = 0.0;
uniform float roughness : hint_range(0,1) = 1.0;
uniform float rim: hint_range(0,1) = 0.01;
uniform float transmission: hint_range(0,1) = 0.5;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_wind_noise : hint_albedo;
uniform vec2 uv_scale = vec2(1.0,1.0);
uniform vec2 uv_offset = vec2(0.0,0.0);

// wind parameters
uniform float wind_noise_scale = 2.0;
uniform vec2 wind_direction = vec2(0.0, 1.0);
uniform float wind_speed : hint_range(0,10) = 1.0;
uniform float wind_strength : hint_range(0,10) = 1.0;

// grass properties
uniform float color_variatiion : hint_range(0, 2) = 0.5;
uniform float height : hint_range(0, 10) = 1.0;
uniform float height_variation : hint_range(0, 2) = 0.3;
uniform float flatness : hint_range(0,2) = 0.2;

// rendering settings
uniform float fade_out_distance = 30.0;
uniform float fade_out_transition = 20.0;
uniform bool y_billboard = false;
uniform float displace_intensity : hint_range(0, 2) = 1.0;
uniform float proximity_distance : hint_range(0, 2) = 1.0;
uniform bool displace = true;
uniform float alpha_scissors : hint_range(0, 1) = 0.9;
uniform bool use_normal_map_alpha = false;

// variables
varying float bend_uv_direction;
varying vec3 instance_offset;
varying float fade;

void vertex() {
	// set up grass
	VERTEX.y *= height;
	VERTEX.y += y_offset*height;
	float inverse_uv_y = 1.0-UV.y;
	COLOR = base_color*vec4(UV.y) + end_color*vec4(inverse_uv_y);
	
	// "h" means height
	float h_variation = float(INSTANCE_ID % 3)*height_variation*0.5;
	float inv_h_stiff = (h_variation + height+1.0) * 2.0;
	float h_stiff = 1.0/inv_h_stiff;
	
	// wind noise animation
	vec2 world_xy = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xz*0.2*wind_noise_scale + wind_direction*TIME*wind_speed*0.51*h_stiff;
	vec4 noise_tex = texture(texture_wind_noise, world_xy);
	
	// y billboard adjustment
	if (y_billboard)
	{
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), CAMERA_MATRIX[2].xyz)),0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(CAMERA_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))),0.0),
			WORLD_MATRIX[3]);
	}
	
	// animate the grass
	vec4 local_wind_direction;
	if (y_billboard)
	{
		local_wind_direction = vec4(wind_direction.x, 1.0, wind_direction.y, 0.0)*CAMERA_MATRIX;
	} else
	{
		local_wind_direction = vec4(wind_direction.x, 1.0, wind_direction.y, 0.0)*WORLD_MATRIX;
	}
	float flat_x = sin(MODELVIEW_MATRIX[2].x)*flatness*h_stiff;
	float flat_y = cos(MODELVIEW_MATRIX[2].z)*flatness*h_stiff;
	float bend = pow(inverse_uv_y, 2);
	float n = (noise_tex.r-0.5*2.0)*bend*wind_strength;
	VERTEX.x += n*flat_x + sin(TIME*0.01*h_stiff+float(INSTANCE_ID))*n*0.1*inv_h_stiff + local_wind_direction.x*wind_strength*bend*height;
	VERTEX.z += n*flat_y + cos(TIME*0.01*h_stiff+float(INSTANCE_ID))*n*0.1*inv_h_stiff + local_wind_direction.z*wind_strength*bend*height;
	VERTEX.y += h_variation*inverse_uv_y;
	VERTEX.y -= inverse_uv_y * flatness * 0.15;
	
	// introduce variation per grass instance
	if (INSTANCE_ID % 2 == 0) bend_uv_direction = 1.0; else bend_uv_direction = -1.0;
	
	if (INSTANCE_ID % 2 == 0) instance_offset = vec3(color_variatiion*0.1); 
	else instance_offset = vec3(-color_variatiion*0.1);
	
	// fade out grass by shrinking it
	float view_distance = length(VERTEX - vec3(MODELVIEW_MATRIX[3].x, MODELVIEW_MATRIX[3].y, MODELVIEW_MATRIX[3].z));
	if (view_distance > fade_out_distance + fade_out_transition) fade = 1.0f; else fade = 0.0f;
	if (view_distance > fade_out_distance)
	{
		float offset = (fade_out_distance + fade_out_transition - view_distance) / fade_out_transition;
		VERTEX.y *= offset;
	}
}

render_mode depth_draw_always; // comment out this if not wanting to use displacement and wanting SSAO

void fragment() {
	if (fade >= 0.5f) discard;
	vec2 base_uv = UV;
	base_uv.x *= 2.0;
	base_uv.x -= 0.5;
	base_uv *= uv_scale;
	base_uv += uv_offset;
	float prox = 1.0;
	
	// comment out this if-block if not wanting to use displacement and wanting SSAO
	if (displace)
	{
		float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
		vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex*2.0-1.0,1.0);
		world_pos.xyz/=world_pos.w;
		float stuff = clamp(1.0-smoothstep(world_pos.z+0.5,world_pos.z,VERTEX.z), 0.3, 1.1);
		prox = clamp(1.0-smoothstep(world_pos.z+proximity_distance,world_pos.z,VERTEX.z) + UV.y*proximity_distance,0.0,1.0);
		base_uv.x += (1.0-prox)*0.2*displace_intensity * bend_uv_direction;
		base_uv.y -= (1.0-prox)*0.5*displace_intensity;
	}
	vec4 albedo_tex = texture(texture_albedo,vec2(base_uv.x, base_uv.y));
	vec4 normal_tex = texture(texture_normal,vec2(base_uv.x, base_uv.y));
	
	// discard distant grass
	if (!use_normal_map_alpha && albedo_tex.a < alpha_scissors)
	{
		discard;
	} else if (use_normal_map_alpha && normal_tex.a < alpha_scissors)
	{
		discard;
	}
	
	ALBEDO = COLOR.rgb * albedo_tex.rgb * (1.0 + instance_offset) * prox;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	RIM = rim;
	TRANSMISSION = vec3(transmission);
	NORMALMAP = normal_tex.rgb;
}