
class Admin
	constructor: (@logger, @ego, @events)->
		@events.on 'command', (user, cmd, args)=>
			if !user.admin
				@logger.log 'No access!'
				return
			else
				@logger.log 'Worked? ', cmd, args

			if cmd == 'admins'
				@ego.bot.chat @ego.config.admins.join(', ')

			else if cmd == 'load'
				name = args.join(' ')
				if @ego.module.loadModule name
					@ego.bot.chat "#{name} was loaded"
				else
					@ego.bot.chat "Failed to load #{name}"

			else if cmd == 'unload'
				name = args.join(' ')
				@ego.module.unloadModule name

			else if cmd == 'removeadmin'
				name = args.join(' ')
				index = @ego.config.admins.indexOf(name)
				if index == -1
					@ego.bot.chat "#{name} is not an admin Keepo"
					return
				@ego.bot.chat "Removing #{name} from admin list."
				@ego.config.admins.splice(index, 1)
				@ego.storeConfig()
				@logger.log 'Someone is running this command'

			else if cmd == 'addadmin'
				name = args.join(' ')
				if @ego.config.admins.indexOf(name) != -1
					@ego.bot.chat "#{name} is already an admin, dumbass"
					return
				@ego.bot.chat "Adding #{name} to admin list."
				@ego.config.admins.push args.join(' ')
				@ego.storeConfig()



module.exports = Admin
