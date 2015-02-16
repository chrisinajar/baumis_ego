
class BasicBitch
	constructor: (@logger, @bot)->
		@logger.log 'Yup'

		@bot.bot.on 'chat', (channel, user, message)=>
			if message == '!guild'
				@bot.bot.chat "@#{user.username} Join channel Minimis in the Dota 2 client and wait. Someone will invite you."



module.exports = BasicBitch
