
class Factoid
	constructor: (@logger, @ego, @events)->
		@logger.log 'Admin init'

		@events.on 'command', (user, cmd, args)=>
			if user.sub && cmd == "learn"
				name = args.shift()
				value = args.join(' ')
				@ego.db.hset 'baumibot_factoids', name, value, (err, data)=>
					if data
						@ego.bot.chat "@#{user.username} Now I know #{name} is #{value}"
					@logger.log err, data

			if user.sub && cmd == "unlearn"
				name = args.shift()
				@ego.db.hdel 'baumibot_factoids', name, (err, data)=>
					if data
						@ego.bot.chat "I can't remember #{name}..."
					@logger.log err, data

			else
				@ego.db.hget 'baumibot_factoids', cmd, (err, data)=>
					if data
						data = "" + data
						data = data.replace(/#{user.username}/g, user.username)
						@ego.bot.chat data


module.exports = Factoid
