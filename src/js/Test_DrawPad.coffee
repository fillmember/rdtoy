THREE = require 'three'
$ = require 'jquery'
dat = require './../vendor/dat.gui.js'

DrawPad = require './DrawPad'

$draw = $('canvas#draw')

drawpad = new DrawPad
	width: 512
	canvas: $draw.get(0)