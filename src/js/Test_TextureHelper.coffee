THREE = require 'three'
$ = require 'jquery'

TextureHelper = require './helpers/TextureHelper'

t = new TextureHelper {}
t.setRenderTarget()
t.setSize(512,512)
t.renderer.render t.scene , t.camera

renderer = new THREE.WebGLRenderer
renderer.setSize(512,512)
scene = new THREE.Scene
camera = new THREE.OrthographicCamera -0.5, 0.5, 0.5, -0.5, -1000, 1000

plane = new THREE.PlaneGeometry 1 , 1
mat = new THREE.ShaderMaterial
	uniforms: { tSource : {type: "t", value: undefined} }
	vertexShader: require './../shader/standard.vs.glsl'
	fragmentShader: require './../shader/test_texture.fs.glsl'
solid = t.getSolid 0 , 0 , 1
mat.uniforms.tSource.value = solid.texture
mesh = new THREE.Mesh plane , mat

scene.add mesh
$('body').append( renderer.domElement )

renderer.render( scene , camera )