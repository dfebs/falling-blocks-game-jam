shader_type canvas_item;

uniform sampler2D noise_texture : hint_default_white;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float burn_size : hint_range(0.0, 0.1) = 0.05;
uniform vec4 burn_color : source_color = vec4(1.0, 0.4, 0.1, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float noise_val = texture(noise_texture, UV).r;
    
    // Check if the pixel should be burned away
    if (noise_val < progress) {
        discard;
    } else if (noise_val < progress + burn_size) {
        // Blend burn color at the edge
        COLOR = burn_color;
        COLOR.a = tex_color.a;
    } else {
        COLOR = tex_color;
    }
}