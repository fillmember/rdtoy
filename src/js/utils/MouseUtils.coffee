defaultFunction = () -> return


class MouseEventManager
	constructor: ({
		dom
		up
		down
		move
		leave
		enter
	}) ->

		@listeners = []

		@setDOM dom
		
		@bind "mouseup"    , => @mouseButtonPressed = false
		@bind "mousedown"  , => @mouseButtonPressed = true

		if up?    then @bind "mouseup"    , up
		if down?  then @bind "mousedown"  , down
		if move?  then @bind "mousemove"  , move
		if leave? then @bind "mouseleave" , leave
		if enter? then @bind "mouseenter" , enter
		
		@mouseButtonPressed = false
		
		return this

	setDOM: (dom) ->
		@targetDOM = dom

	bind: (event , fn) ->
		@targetDOM.addEventListener event , (evt) => fn evt , this
		@listeners.push event: event , fn: fn

	unbind: () ->
		@targetDOM.removeEventListener obj.event , obj.fn for obj in @listeners


lib =

	getPos : ( dom , x , y ) ->
		rect = dom.getBoundingClientRect()
		console.log x , y , rect.left , rect.top , dom.width
		return {
			x: x - rect.left
			y: y - rect.top
		}

	getRelativePos : ( dom , x , y ) ->
		rect = dom.getBoundingClientRect()
		return {
			x: (x - rect.left) / (rect.width),
			y: (y - rect.top ) / (rect.height)
		}

	posToUV : ( vec ) ->
		vec.y = 1 - vec.y
		return vec

	getMouseUV : ( dom , x , y ) ->
		return @posToUV @getRelativePos dom , x , y

	bind : (args) ->
		manager = new MouseEventManager args
		return manager


module.exports = lib