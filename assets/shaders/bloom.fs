/**
 * Basic bloom shader.
 */
extern number threshold = 0.7;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    number brightness = (pixel.r + pixel.g + pixel.b) / 3.0;
    if (brightness > threshold) {
        return pixel * 1.2;
    }
    return pixel;
}