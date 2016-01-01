varying vec2 vUv;
uniform sampler2D tSource;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;
uniform vec4 color5;

void main() {

    float value = texture2D(tSource, vUv).g;
    float a;
    vec3 col;
    
    if (value <= color1.a) { col = color1.rgb; }
    if (value > color1.a && value <= color2.a) {
        a   = (value - color1.a) / (color2.a - color1.a);
        col = mix(color1.rgb, color2.rgb, a);
    }
    if (value > color2.a && value <= color3.a) {
        a   = (value - color2.a) / (color3.a - color2.a);
        col = mix(color2.rgb, color3.rgb, a);
    }
    if(value > color3.a && value <= color4.a) {
        a   = (value - color3.a) / (color4.a - color3.a);
        col = mix(color3.rgb, color4.rgb, a);
    }
    if(value > color4.a && value <= color5.a) {
        a   = (value - color4.a) / (color5.a - color4.a);
        col = mix(color4.rgb, color5.rgb, a);
    }
    if(value > color5.a) { col = color5.rgb; }
    
    gl_FragColor = vec4(col.r, col.g, col.b, 1.0);

}