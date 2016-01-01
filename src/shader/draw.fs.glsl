varying vec2 vUv;

uniform sampler2D tSource;
uniform vec2 step;
uniform vec2 brush;
uniform vec4 brushColor;
uniform float brushSize;

void main() {

    vec2 dst = texture2D( tSource, vUv ).rgba;

    if (brush.x > 0.0) {
        vec2 v = (vUv - brush) / step;
        float d = dot(v, v);
        dst = d < brushSize ? brushColor : dst.rgba;
    }
    
    gl_FragColor = dst;

}