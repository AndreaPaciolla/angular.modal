
# The provider to save templates

modal = angular.module('angular.modal', []).provider('$modalTemplates', [->

	available_templates = {
		default: "
			<div adapt-to-parent='centered'>
			    <div class='closer_overlay' 
			    	 ng-click='$modal.closeAll()'
			    	 ng-show='closable || true'></div>
			    <div class='window' ng-class='windowClass'>
			      <div  style='font-size: 2em;position: absolute;right: 0.5em;z-index: 1;cursor:pointer' 
			      		ng-click='$modal.closeAll()' 
			      		class='close_popup_x'
			      		ng-show='closable || true'>
			      	&times;
			      </div>
			      <div  class='content' 
						ng-class='contentClass' 
						ng-init='in_popup = true; data = popup.message'
						ng-transclude>
			      </div>
			    </div>
			  </div>
			"
	}

	@current_template = 'default'

	@getTemplate = (id)->
		available_templates[id]

	# - Push a template into the main object available_templates
	@push = (id, template)->
		available_templates[id] = template


	#  ============================================================================

	# FACTORY: $modal
	@$get = ['$timeout', ($timeout)->

		@
	]

	@
])


# Use the provider $modalProvider to .push popups and be sure to use this structure:

modal.provider('$modal', ['$modalTemplatesProvider', ($modalTemplatesProvider)->
	
	# All available popup statuses
	popup_statuses =
		visible: "active"
		hidden: "hidden"

	# The object with the configuration
	config = 
		dom_id_prefix: "modalized_"
		dom_class: "modal"
		dom_active_class: "active"

	# The object with all the modals. Initialized empty
	available_modals = {}

	# Get the current template
	@current_template = ->
		$modalTemplatesProvider.getTemplate $modalTemplatesProvider.current_template

	# DOM Manipulation methods ===================================================

	# - Generate an univoke id and give it to the element then return the id
	generateId = (elm)->
		date	= new Date()
		milli	= date.getMilliseconds()
		rand	= Math.random().toString().replace("0.", "")
		# Using only value of caused some issues - Duplicated ids
		stamp	= "#{date.valueOf()}#{milli}#{rand}"

		# the final id
		id 		= "#{config.dom_id_prefix}#{stamp}#{milli}"

		elm.attr('id', id)

		id

	# - Manage the dom related stuff of the element
	manipulateDom = (popup)->
		raw = document.getElementById(popup.elm_id) # Let's avoid jquery
		elm = angular.element(raw) # Get that element

		elm.addClass(config.dom_class)

		if popup.status == popup_statuses.active
			elm.addClass config.dom_active_class
		else
			elm.removeClass config.dom_active_class

	#  ============================================================================



	# Data manipulation methods ===================================================

	# TODO: We need a class for our modals in order to use them wisely

	# - Push a popup into the main object available_modals
	@push = (popup={})->
		if popup.type == "html"
			available_modals[popup.id] = {}
			available_modals[popup.id].type 	= popup.type
			available_modals[popup.id].id 		= popup.id
			available_modals[popup.id].elm_id	= generateId(popup.elm)
			available_modals[popup.id].status 	= popup_statuses.hidden

			manipulateDom(available_modals[popup.id])
		else if popup.type == "link"
			available_modals[popup.id] = {}
			available_modals[popup.id].type 	= popup.type
			available_modals[popup.id].id 		= popup.id
			available_modals[popup.id].elm_id	= generateId(popup.elm)
			available_modals[popup.id].status 	= popup_statuses.hidden

			manipulateDom(available_modals[popup.id])
			alert "fill here"

	#  ============================================================================


	# Configuration methods =======================================================

	@configSet = (property, value)->
		config[property] = value

	@configGet = (property)->
		config[property]

	#  ============================================================================

	# Event handler ===============================================================

	available_events = 
		modalWillAppear: "modalWillAppear"
		modalDidAppear: "modalDidAppear"
		modalWillDisappear: "modalWillDisappear"
		modalDidDisappear: "modalDidDisappear"

	ModalEventHandler = ->
		registered_events = {}

		@register = (event, callback)->
			unless registered_events[event] instanceof Array
				registered_events[event] = []

			registered_events[event].push callback

			true

		@call = (event)->
			if callbacks = registered_events[event]
				for callback in callbacks
					callback() # call the function - pass in something?

			true

	eventHandler = new ModalEventHandler()

	#  ============================================================================

	# FACTORY: $modal
	@$get = ['$timeout', ($timeout)->

		@closeAll = ->

			for modal_id of available_modals
				modal = available_modals[modal_id]
				console.log modal
				modal.status = popup_statuses.hidden
				manipulateDom(modal)


		@open = (id)->
			@closeAll()

			# eventHandler.call available_events.modalWillAppear

			$timeout(-> 
				# alert id
				console.log "=============================="
				console.log available_modals


				available_modals[id].status = popup_statuses.active
				manipulateDom(available_modals[id])

				# eventHandler.call available_events.modalDidAppear
				
			, 300)

		# @on = (event, callback)-> eventHandler.register(event, callback)

		@
	]

	@
])


# + The directive to register a modal - Data stuff
modal.directive("modalize", ['$modal', ($modal)->
	restrict: "A"
	link: (scope, elm, attr)->

		modal_id = attr.modalize
		type = "html"

		console.log modal_id
		console.log elm

		$modal.push({type: type, id: modal_id, elm: elm})

		true
])

# + The directive to register a modal - Data stuff
modal.directive("modalizeD", ['$modal', ($modal)->
	restrict: "A"
	scope:
		src: "@"
	template: "<div ng-include='src'></div>"
	link: (scope, elm, attr)->

		# LET NG-INCLUDE TO INHERIT THE PARENT SCOPE
		# USE AS $scope.binding TO REFER TO PARENT OBJECT
		scope.binding = scope.$parent

		# NG-INCLUDE DOES NOT INHERIT THE $rootScope SO WE'LL INJECT IT MANUALLY
		if $modal.configGet('inject_into_html') then scope.$modal = $modal

		modal_id = attr.modalizeD
		type = "html"

		if attr.src?
			type = "link"
		console.log modal_id
		console.log elm

		$modal.push({type: type, id: modal_id, elm: elm})

		true
])

# + The directive to generate the basic layout of a modal - Graphic stuff
modal.directive("modalize", ['$modal', ($modal)->
	restrict: "E"
	scope: 
		windowClass:	"@"
		contentClass:	"@"
		closable:		"@"
		centered:		"@"
	replace: true
	transclude: true
	controller: ['$scope', '$modal', ($scope, $modal)->
		# make the modal available
		$scope.$modal = $modal
	]
	template: $modal.current_template()
])

# + Adapt to the parent container
modal.directive("adaptToParent", ['$timeout', ($timeout)->
	restrict: "A"
	link: (scope, elm, attr)->


		time = window.setInterval(->
			if scope.centered != "false"
				elm.css "display", "table-cell"
				elm.css "vertical-align", "middle"

				parent = elm.offsetParent()
				height = parent.height()
				width  = parent.width()

				elm.height height
				elm.width width
			else
				console.log "Clear interval"
				window.clearInterval time

		, 100)

		true
])



modal.run(['$modal', '$modalTemplates', '$rootScope', ($modal, $modalTemplates, $rootScope)->

	if $modal.configGet('inject_into_html')
		$rootScope.$modal = $modal
		window.$modal = $modal

])