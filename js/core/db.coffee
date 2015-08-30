define ['require', 'inc/store'], ( require, store )->

	Array.prototype.select = ( select, force_object )->

		# Select určuje, aké polia má vrátiť: [ 'name', 'likes' ]
		# Ak bude polí (ktoré má vrátiť) viac, funkcia vráti pole objektov,
		# ak bude iba jedno, funkcia vráti pole hodnôt. Pre vrátenie objektu
		# treba nastaviť druhý parameter na TRUE

		return false if ! select 

		select = [ select ] if select.constructor != Array

		results = []

		for item in @ 	# Pre každý prvok pola

			if item.constructor != Object

				console.error 'Nesprávny tvar poľa, pole musí obsahovať objekty'
				return false


			if select.length == 1 && item[ select[0] ]

				if force_object

					obj = {}
					obj[ select[0] ] = item[ select[0] ]

					results.push obj

				else

					results.push item[ select[0] ]


			else

				obj = {}

				obj[ s ] = item[ s ] for s in select when item[ s ]

				results.push obj

		return results



	constructor = ()->

		store: store

		connect: ( store )->

			throw new Error('DB not specified') if ! store
			throw new Error('Not valid DB') if ! store.get || ! store.set
			
			db = constructor()
			db.store = store

			return db


		create_db: ()->
			{
				store: {}
				set: ( key, value )-> @store[ key ] = value
				get: ( key )-> @store[ key ]
				getAll: ()-> @store
				remove: (key)-> delete @store[ key ] if @store[ key ]
				clear: ()-> @store = {} 
			
			}


		use: ( table )->

			__this = @

			{
				find: ( fn )->

					_this = @

					t = __this.store.get table

					if ! t? then return false


					# Odfiltrujeme podÄľa funkcie fn

					if fn 
						filtered = t.filter fn

					else
						filtered = t


					# PripravĂ­me na moĹľnosĹĄ zmazaĹĄ a uloĹľiĹĄ
					
					for item in filtered

						item.$$index = t.indexOf item
						item.save = ()-> _this.save @
						item.remove = ()-> _this.remove @

					return if filtered.length == 0 then false else filtered

				findOne: ( fn )->

					x = @find fn

					return if ! x then false else x[0]

				create: ( data )->

					t = __this.store.get table

					t = [] if ! t?

					t.push data

					__this.store.set table, t

					data.$$index = t.indexOf data
					data.save = ()-> _this.save @
					data.remove = ()-> _this.remove @

					return data
					

				createBatch: ( data )->

					for item in data

						@create item

					return true

				save: ( item )->

					index = item.$$index

					delete item.$$index
					delete item.save
					delete item.remove

					t = __this.store.get table

					t[ index ] = item

					__this.store.set table, t

					item.$$index = t.indexOf item
					item.save = ()-> _this.save @
					item.remove = ()-> _this.remove @

					return true

				remove: ( item )->

					t = __this.store.get table

					t.splice item.$$index, 1

					__this.store.set table, t

					return true

				drop: ()->

					__this.store.remove table

					return this
			}

	return constructor()