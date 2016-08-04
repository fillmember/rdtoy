varying vec2 vUv;
uniform vec2 step;
uniform sampler2D tSource;
uniform sampler2D tEnv;
uniform float delta;
uniform float feedFactor;
uniform float killFactor;
uniform vec2 brush;
uniform vec2 brushColor;
uniform float brushSize;

void main() {

    vec3 vEnv = texture2D( tEnv, vUv ).rgb;
    float feed = vEnv.r * feedFactor;
    float kill = vEnv.g * killFactor;
    float sx = step.x * vEnv.b * 10.0;
    float sy = step.y * vEnv.b * 10.0;

    vec2 uv  = texture2D( tSource, vUv ).rg;
    vec2 lapl =
         + 0.05 * (
            texture2D( tSource, vUv + vec2( -sx, -sy ) ).rg +
            texture2D( tSource, vUv + vec2(  sx, -sy ) ).rg +
            texture2D( tSource, vUv + vec2( -sx,  sy ) ).rg +
            texture2D( tSource, vUv + vec2(  sx,  sy ) ).rg
         )
         + 0.20 * (
         // + 0.25 * (
            texture2D( tSource, vUv + vec2( -sx, 0.0 ) ).rg +
            texture2D( tSource, vUv + vec2(  sx, 0.0 ) ).rg +
            texture2D( tSource, vUv + vec2( 0.0, -sy ) ).rg +
            texture2D( tSource, vUv + vec2( 0.0,  sy ) ).rg
         )
         - uv;
    float reaction = uv.r * uv.g * uv.g;
    float du = 1.0 * lapl.r - reaction +  feed * (1.0 - uv.r);
    float dv = 0.5 * lapl.g + reaction - (feed + kill) * uv.g;
    vec2 dst = uv + delta * vec2(du, dv);

    if (brush.x > 0.0) {
        vec2 diff = (vUv - brush) / step;
        float dist = dot(diff, diff);
        dst = dist < brushSize ? brushColor : dst.rg;
    }
    
    gl_FragColor = vec4(dst, 0.0, 1.0);

}