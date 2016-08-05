lib = {}

template = 
	col: '<div class="col" />'
	btnGroup: '<div class="col btnGroup" />'
	item: '<div class="item" />'
	itemHeader: '<h4 class="itemHeader" />'
	itemLabel: '<h5 class="itemLabel" />'
	aButton: '<a class="button" />'
	icon: '<i class="fa" />'
	spanText: '<span class="text" />'
	button: '<button />'
	slider: '<input type="range" />'
	toggle: '<input type="checkbox" class="toggle" />'
	label: '<label />'

factory = (html) ->
	return (->
		# args = id , classes , child
		args = Array.prototype.slice.call arguments
		child = args.pop()
		classes = args.pop()
		id = args.pop()
		# dom
		dom = $ html
		if classes then dom.addClass classes
		if child? then dom.append child
		if id? then dom.prop 'id' , id
		# return
		return dom
	)

# container type
lib.itemHeader = factory template.itemHeader
lib.item       = factory template.item
lib.col        = factory template.col
lib.btnGroup   = factory template.btnGroup
lib.spanText   = factory template.spanText
lib.itemLabel  = factory template.itemLabel
lib._button    = factory template.button
lib._aButton   = factory template.aButton

# non-container type
lib.icon = (icon) -> $(template.icon).addClass icon
lib.label = (id) -> $(template.label).prop 'for' , id

lib.animate =
	sliderText: ({
		dom
		durationIn = 100
		durationOut = 150
		reverse = false
		callback
	}) ->
		dom.stop()
		dom.css 'position' , 'relative'
		delta = dom.height()
		animIn =
			top: if reverse then -delta else delta
		animOut =
			top: 0
		# options
		optOut = 
			duration : durationOut
			complete : ->
				dom.css 'position' , ''
				dom.css 'top' , ''
		optIn =
			duration : durationIn
			complete : ->
				dom.css 'top' , if reverse then delta else -delta
				if callback? then callback()
				dom.animate animOut , optOut
		# animate
		dom.animate animIn , optIn

lib.sectionHeader = ({
	icon
	name
}) ->
	dom = $ '<h3 class="sectionHeader" />'
	if icon then dom.append @icon icon
	if name then dom.append @spanText name
	return dom

lib.section = ({
	icon
	name
	child = []
}) ->
	dom = $ '<section class="section" />'
	dom.addClass name
	phaseButton = @button
		link: true
		classes: 'section-minimize-button'
		name: 'minimize'
		icon: 'fa-angle-up'
	# Animation Setting
	t = 0.75
	halfT = t / 2
	ease = Power2.easeInOut
	# Styles
	buttonNormal  = rotationZ :    0 , y : 0.0 , ease : ease
	buttonMinimal = rotationZ :  -90 , y : 2.5 , ease : ease
	buttonFolded  = rotationZ : -180 , y : 5.0 , ease : ease
	sectionFoldHeight = 24
	sectionHeaderFoldHeight = 14
	borderBottom0 = '0px solid #CCC'
	borderBottom1 = '1px solid #CCC'
	iconTextFoldHeight = 3.5
	sliderLabelNormalWidth = '31.2%'
	sliderLabelMinimalWidth = '10%'
	# Phase
	phase = 0
	# 0 = normal
	# 1 = minimal
	# 2 = fold
	phaseButton.click ->
		phase = (phase+1) % 3
		switch phase
			when 0
				sectionHeader = dom.find('.sectionHeader')
				sliderLabel = dom.find('.sliderLabel')
				# get height
				TweenLite.set sectionHeader , {height:'auto'}
				iconText = dom.find('i.fa + span.text')
					.each ->
						$this = $(this)
						$this.data 'foldHeight' , $this.height()
						TweenLite.set this , height : 'auto'
						$this.data 'normalHeight' , $this.height()
				fromHeight = dom.height()
				TweenLite.set dom , {height: 'auto'}
				toHeight = dom.height()
				# animation
				TweenLite.to phaseButton , halfT , buttonNormal
				TweenLite.fromTo dom , t , {height: fromHeight} , {
					height:toHeight
					borderBottom: borderBottom0
					ease : ease
				}
				iconText.each ->
					$this = $ this
					TweenLite.fromTo this , halfT , {
						height: $this.data('foldHeight')
					} , {
						height: $this.data('normalHeight')
						alpha: 1
						scale: 1
						ease : ease
					}
				TweenLite.to sliderLabel , halfT , width: sliderLabelNormalWidth
			when 1
				TweenLite.set dom , height : 'auto'
				TweenLite.to phaseButton , halfT , buttonMinimal
				#
				iconText = dom.find('i.fa + span.text')
				TweenLite.to iconText , halfT , {alpha: 0, scale: 0, height: iconTextFoldHeight , ease : ease}
				#
				sectionHeader = dom.find('.sectionHeader')
				TweenLite.to sectionHeader , halfT , {height: sectionHeaderFoldHeight, ease : ease}
				#
				sliderLabel = dom.find('.sliderLabel')
				TweenLite.fromTo sliderLabel , halfT , {width: sliderLabelNormalWidth} , {width: sliderLabelMinimalWidth , ease : ease}
			when 2
				TweenLite.to phaseButton , halfT , buttonFolded
				TweenLite.to dom , t , {
					height : sectionFoldHeight
					borderBottom : borderBottom1
					ease : ease
				}
	child.unshift phaseButton
	child.unshift @sectionHeader
		icon: icon
		name: name
	dom.append child
	return dom

lib.slider = ({
	name = 'slider'
	icon = 'fa-smile-o'
	object = {n:0}
	property = 'n'
	min
	max
	step

	onInput
	onChange
	display = (v) -> v
	transform = (v) -> v
}) ->
	# DOM
	slider = $ template.slider
	span = @spanText name
	label = @itemLabel 'sliderLabel' , [
		@icon(icon).addClass('fa-fw')
		span
	]
	# PROP
	if min? then slider.prop 'min' , min
	if max? then slider.prop 'max' , max
	if step? then slider.prop 'step' , step
	slider.prop 'value' , object[property]
	# change target values
	slider.on 'input change' , ->
		object[property] = transform parseFloat this.value
	# span.text change
	slider.on 'input' , -> span.text display transform parseFloat this.value
	slider.on 'mousedown' , ->
		lib.animate.sliderText
			dom: span
			callback: => span.text display transform parseFloat this.value
	slider.on 'mouseup' , ->
		lib.animate.sliderText
			dom: span
			reverse: true
			callback: => span.text name
	# events
	if onInput? then slider.on 'input' , (event) ->
		onInput.call this , (transform parseFloat this.value)
	if onChange? then slider.on 'change' , (event) ->
		onChange.call this , (transform parseFloat this.value)
	# return dom
	return @col 'sliderContainer' , [ label, slider ]

lib.display = ({
	name = 'display'
	icon = 'fa-smile-o'
	object
	property
	eventEmitter
	eventName
	eventNames
	display = (v)->v
})->
	label = @itemLabel 'displayLabel' , [
		if icon then @icon(icon).addClass('fa-fw')
		@spanText name
	]
	span = @spanText 'display' , ''
	update = (value) ->
		if value?
			span.text display value
		else if object? and property?
			span.text display object[property]
		else
			span.text display ''
	if eventEmitter?
		handler = ->
			if arguments.length > 0
				if name is arguments[0]
					update arguments[1]
			else
				update()
		if eventName then eventEmitter.on eventName , handler
		if eventNames
			eventNames.forEach (n) -> eventEmitter.on n , handler
	update()
	col = @col 'displayContainer' , [ label , span ]
	col.data update: update
	return col

lib.button = ({
	id = undefined
	classes = undefined
	link = false
	name = 'button'
	icon = 'fa-smile-o'
	disabled = false
	action = ->
	solo = false
	group = undefined
	root = undefined
	checkbox = false
	checked = undefined
}) ->
	element = if link then @_aButton else @_button
	btn = element id , classes , [
		if icon then @icon icon
		@spanText name
	]
	btn.prop 'disabled' , disabled
	# Store Data
	btn.data 'ui' , {
		group: group
		solo: solo
		checkbox: checkbox
		checked: checked
		update: ( bool = false ) ->
			data.checked = bool
			btn.toggleClass 'checked' , bool
	}
	data = btn.data('ui')
	data.update checked
	# More
	# Checkbox
	if checkbox
		btn.click ->
			data.update solo or not data.checked
	# checkbox & group :
	# 1. when you are solo, when you activate, other activated buttons uncheck.
	# 2. when you are not solo, when you activate, other activated solos uncheck.
	if group and checkbox
		btn.click ->
			# only affect others when this is checked
			if data.checked is false then return
			others = root
				.find "button, .button"
				# exclude self
				.not this
				# find members of my group
				.filter ->
					otherData = $(this).data('ui')
					if not otherData? then return false
					activated = otherData.checked
					mygroup = otherData.group is group
					return activated and mygroup
				# each
				.each ->
					other = $(this)
					otherData = other.data('ui')
					if solo or otherData.solo is true
						otherData.update false
	# Finally, user's action
	btn.click (e) ->
		if checkbox
			action.call( btn.get(0) , data.checked , btn , e )
		else
			action.call( btn.get(0) , btn , e )
	# return btn
	return btn

lib.toggle = ({
	name = 'toggle'
	icon
	action = ->
	checked = false
}) ->
	id = 'toggle' + ('0000000' + parseInt( Math.random() * 9999999999 )).slice(10)
	input = $( template.toggle ).prop( 'id' , id )
	label = @label id
	input.on 'change' , ->
		action( this.checked )
	input.get(0).checked = checked
	if checked then input.trigger 'change'
	return @col 'toggleContainer' , [
		@itemLabel [ (if icon? then @icon(icon)) , name ]
		input
		label
	]

lib.option = (value,name = value) ->
	option = $ '<option />'
	option.prop 'value' , value
	option.text name
	return option

lib.select = ({
	name = 'untitled'
	options = []
	onInput = ->
	onChange = ->
}) ->
	select = $ '<select />'
	select.prop 'name' , name
	select.append @option o[1] , o[0] for o in options
	select.on 'input' , -> onInput this.value
	select.on 'change' , -> onChange this.value
	return select


module.exports = lib