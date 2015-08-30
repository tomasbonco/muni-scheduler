requirejs.config

	## By default load any module IDs from js/lib
	baseUrl: 'js',

	## except, if the module ID starts with "app",
	## load it from the js/app directory. paths
	## config is relative to the baseUrl, and
	## never includes a ".js" extension since
	## the paths config could be for a directory.
	paths: {}


data = [ 'require', 'core/db', 'assets/colors', 'core/render' ]

requirejs data, ( require, db, colors, render )->

	###
	data = [{
		code: 'MB103'
		name: 'Matematika a štatistika'

		lecture:
			room: 'D1'
			teacher: { name: 'Antonio Banderas', link: '#' }
			code: 'MB103'
			name: 'Matematika a štatistika'
			day: 1
			time: { from: 700, to: 830 }

		labs: [{

			subject: 'MB103'
			code: 'MB103/02'
			room: 'G101'
			teacher: { name: 'Antom Mráz', link: '#' }
			note: 'Musíš obrať zemiaky!'
			day: 2
			time: { from: 1000, to: 1250 }
		},
		{
			subject: 'MB103'
			code: 'MB103/03'
			room: 'G101'
			teacher: { name: 'Antom Mráz', link: '#' }
			day: 3
			time: { from: 1000, to: 1350 }
		}]
	},
	{
		code: 'IB000'
		name: 'Zemepán'
		lecture:
			code: 'IB000'
			name: 'Zemepán'
			room: 'D2'
			teacher: { name: 'Antonio Banderas', link: '#' }
			day: 0
			time: { from: 700, to: 830 }

		labs: [{

			subject: 'IB000'
			code: 'IB000/02'
			room: 'C201'
			teacher: { name: 'Marek Kohút', link: '#' }
			day: 0
			time: { from: 800, to: 1150 }
		},
		{
			subject: 'IB000'
			code: 'IB000/03'
			room: 'B110'
			teacher: { name: 'Martin Zuro', link: '#' }
			day: 3
			time: { from: 1000, to: 1350 }
		}]
	}]
	###


	insert = ( data )->

		for subject in data

			subject.color = colors[ Math.floor(Math.random() * (colors.length - 0)) ] if ! subject.color 
			subject.locked = false if ! subject.color 

			db.use( 'subjects' ).create subject


	###
	update = (data)->

		seconds = new Date().getTime() / 1000

		subjects = db.use( 'subjects' ).find ( s )-> s.timestamp < ( new Date().getTime() / 1000 ) - 3600  # Nájde všetky predmety, ktoré sa za poslednú hodinu neaktualizovali


		for subject in subjects

			$.post 'index.php', { action: 'read', classes:  }, ( response )->			
	###

	if window.show_schedule

		# setInterval 'update', 1000 * 60 * 60 * 1 	# 1 hodina

		render.classes()
		render.schedule()


	$(document).on 'click', '.lock', ()->

		if window.preview

			alert 'Najskôr vypni finálne zobrazenie!'
			return

		parent = $(@).parent()
		code = $(parent).attr 'data-class'


		# Zapíšeme do DB

		subject = db.use('subjects').findOne ( s )-> s.code == $.trim code
		seminar = subject.labs[ subject.labs.indexOf ( subject.labs.filter ( l )-> l.code == $.trim $(parent).attr('data-seminar') )[0]]

		
		seminar.locked = false if ! seminar.locked

		locked = seminar.locked

		seminar.locked = ! locked
		subject.locked = ! locked

		subject.save()


		# Upravíme HTML
		
		$( '[data-class="' + code + '"]' ).each ()->

			$(@).slideUp() if @ isnt parent[0] && ! locked
			$(@).slideDown() if @ isnt parent[0] && locked


	$(document).on 'click', '.remove', ()->

		code = $(@).attr 'data-code'
		subject = db.use('subjects').findOne ( s )-> s.code == code
		subject.remove()

		render.classes()
		render.schedule()


	$(document).on 'click', '.change-color', ()->

		code = $(@).attr 'data-code'
		subject = db.use('subjects').findOne ( s )-> s.code == code
		subject.color = colors[ Math.floor(Math.random() * (colors.length - 0)) ]
		subject.save()

		render.classes()
		render.schedule()


	$(document).on 'click', '#create', ()->

		$(@).val 'Loading ...'
		$(@).attr 'disabled', '1'

		_this = @


		# Pozrieme, ci uz dane predmety nemame nacitane

		classes = $('#class_input').val()
		new_classes = [] # tu si ulozime tie, ktore potom nacitame

		$('#class_input').val( '' )

		if ! classes

			$(_this).val 'Odoslať'
			$(_this).removeAttr 'disabled'

			return


		codes = classes.split ','


		for code in codes

			code = code.split(':')


			if code.length == 1

				render.error [ 'Predmet [' + code[0] + '] zadaný v nesprávnom tvare!' ]
				continue

			exists = db.use('subjects').findOne ( s )-> return s.code == $.trim code[1]

			new_classes.push $.trim code.join(':') if ! exists


		if new_classes.length > 0

			$.post 'index.php', { action: 'read', classes: new_classes.join(',') }, ( response )->

				console.log 'zemiaky'

				console.log response

				$(_this).val 'Odoslať'
				$(_this).removeAttr 'disabled'

				response = JSON.parse response

				insert response.classes
				render.schedule()
				render.classes()

				render.error response.errors


		else

			$(_this).val 'Odoslať'
			$(_this).removeAttr 'disabled'


	$(document).on 'click', '#signme', ()->

		person = db.use( 'person' ).findOne()
		person = person.uco if person

		$(@).val 'Loading ...'
		$(@).attr 'disabled', '1'

		_this = @

		$.post 'index.php', { action: 'sign_in', uco: $('#uco').val(), password: $('#password').val(), person: person }, ( response )->

			console.log response

			$(_this).val 'Odoslať'
			$(_this).removeAttr 'disabled'

			db.use('person').drop()
			db.use('person').create { uco: $('#uco').val() }

			response = JSON.parse response

			db.use('subjects').drop() if response.classes and response.classes.length > 0

			if response.classes

				db.use('subjects').drop()
				insert response.classes 


			document.location.reload() if response.classes || response.log_me_in


			alert error for error in response.error if response.error


	$(document).on 'click', '#sign_out', ()->

		$.post 'index.php', { action: 'sign_out' }, ( response )->

			document.location.reload()


	$(document).on 'click', '#final-view', ()->

		window.preview = false if ! window.preview
		window.preview = ! window.preview

		render.schedule()


	$(document).on 'click', '#errors .close', ()->

		$(@).parent().remove()
