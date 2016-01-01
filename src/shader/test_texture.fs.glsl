varying vec2 vUv;
uniform sampler2D tSource;

void main() {

    vec3 v = texture2D( tSource, vUv ).rgb;
    gl_FragColor = vec4( v.r , v.g , v.b , 1.0 );

}