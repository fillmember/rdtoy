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

    vec2 envValue = texture2D( tEnv, vUv ).rg;
    float feed = envValue.r * feedFactor;
    float kill = envValue.g * killFactor;
    // gl_FragColor = vec4( envValue , 0.0 , 1.0 );
    // float feed = 0.035;
    // float kill = 0.060;

    vec2 uv  = texture2D( tSource, vUv ).rg;
    vec2 uv0 = texture2D( tSource, vUv + vec2( -step.x, 0.0 ) ).rg;
    vec2 uv1 = texture2D( tSource, vUv + vec2(  step.x, 0.0 ) ).rg;
    vec2 uv2 = texture2D( tSource, vUv + vec2( 0.0, -step.y ) ).rg;
    vec2 uv3 = texture2D( tSource, vUv + vec2( 0.0,  step.y ) ).rg;

    vec2 lapl = 0.25 * ( uv0 + uv1 + uv2 + uv3 ) - uv;
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