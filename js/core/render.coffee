define ['require', 'core/db'], ( require, db )->

	day_template: Handlebars.compile if $('#day-template').length == 0 then '' else $('#day-template').html()
	class_template: Handlebars.compile if $('#class-template').length == 0 then '' else $('#class-template').html()
	error_template: Handlebars.compile if $('#error-template').length == 0 then '' else  $('#error-template').html()

	# Vykresľuje rozvrh
	schedule: ()->

		Line = db.use( 'lines' )
		Subject = db.use( 'subjects' )

		handlebars_data = { days: [] }


		# Vygenerujeme dni

		days = [ 'Po', 'Ut', 'St', 'Št', 'Pi' ]

		for i in [ 1 .. 5 ]

			handlebars_data.days[ i - 1 ] = { name: days[ i - 1], line: [] }


		# Vymažeme predchádzajúci render

		Line.drop()


		# Prejdeme všetky predmety a priradíme im riadok

		subjects = Subject.find()

		for subject in subjects

			@_insert_into_schedule.call @, subject.lecture, subject, { lecture: true }

			for lab in subject.labs

				@_insert_into_schedule.call @, lab, subject


		# Prejdeme dni a vytvoríme pole riadkov

		for day in [ 0 .. 4 ]

			row = Line.find( ( l )-> l.day == day )

			continue if ! row

			row = row.sort ( a, b )-> b.line - a.line

			for subject in row

				handlebars_data.days[ day ] = {} if ! handlebars_data.days[ day ]?
				handlebars_data.days[ day ]['line'] = [] if ! handlebars_data.days[ day ]['line']
				handlebars_data.days[ day ]['line'][ subject.line ] = [] if ! handlebars_data.days[ day ]['line'][ subject.line ]?

				handlebars_data.days[ day ]['line'][ subject.line ].push subject


		$('#schedule #days').html @day_template( handlebars_data )

	
	# Hľadá miesto pre predmet v rozvrhu
	# @param {object} data - dáta o vkladanej prednáške/cviku
	# @param {object} subject - dáta o predmete
	# @param {object} extend - nejaké rozširujúce dáta (zvyčajne {lecture: true}), ktoré chceme poslať do templatu
	_insert_into_schedule: ( data, subject, extend )->

		console.log data, subject, extend
		extend = {} if ! extend?

		return if ! data? || ! data.time || ! data.time.from || ! data.time.to
		return if subject.locked and ! data.locked and window.preview and ! extend.lecture

		extend.class = 'hide-no-bootstrap' if subject.locked and ! data.locked and ! extend.lecture


		Line = db.use( 'lines' )

		for line_count in [ 0 .. 30 ]

			line = Line.findOne ( l )-> l.day == data.day && l.line == line_count && (( parseInt(l.time.from) <= parseInt(data.time.from) && parseInt(l.time.to) > parseInt(data.time.from )) || ( parseInt(l.time.from) < parseInt(data.time.to) && parseInt(l.time.to) >= parseInt(data.time.to )) || ( parseInt(l.time.from) >= parseInt(data.time.from) && parseInt(l.time.to) <= parseInt(data.time.to )))

			break if ! line

		Line.create $.extend {}, data, { line: line_count, color: subject.color, left: (parseInt(data.time.from) - 700) / 15,  width: ( parseInt(data.time.to) - parseInt(data.time.from)) / 15 }, extend


	# Zobrazuje predmety pod rozvrhom
	classes: ()->

		Subject = db.use( 'subjects' )

		$('#classes').html @class_template { class: Subject.find() }


	# Zobrazuje chyby
	error: ( errors )->

		for error in errors

			$('#errors').append @error_template { message: error }