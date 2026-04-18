shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float diff = distance(color.rgb, vec3(1.0, 1.0, 1.0));
    if (diff < 0.1) { // Adjust 0.1 to control sensitivity
        discard; 
    }
    COLOR = color;
}