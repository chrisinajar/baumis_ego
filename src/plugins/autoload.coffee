
class PluginAutoload
	constructor: (@logger, @ego, @events)->
		@ego.db.get 'baumibot_autoload', (err, data)=>
			if !data
				@ego.db.set 'baumibot_autoload', JSON.stringify([])
				@data = []
				return

			@data = if data then JSON.parse data else []
			@ego.module.loadModule module for module in @data


		@events.on 'command', (user, cmd, args)=>
			if !user.admin
				return


			if cmd == 'autoload'
				name = args.join ' '
				index = @data.indexOf(name)
				if index != -1
					@ego.bot.chat "#{name} is already autoloaded"
					return
				@data.push name
				@write()
				@ego.bot.chat "MrDestructoid #{name}"

			else if cmd == 'unautoload'
				name = args.join ' '
				index = @data.indexOf(name)
				if index == -1
					@ego.bot.chat "#{name}? Go home"
					return

				@data.splice index, 1
				@write()

			else if cmd == 'reload'
				@ego.bot.chat "Loading: #{@data.join(', ')}"
				@ego.module.loadModule module for module in @data


	write: ->
		@ego.db.set 'baumibot_autoload', JSON.stringify(@data), @logger.log


module.exports = PluginAutoload
