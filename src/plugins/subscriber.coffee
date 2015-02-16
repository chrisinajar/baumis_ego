
class Subscription
	constructor: (@logger, @ego, @events)->
		@events.on 'subscription', (channel, username)=>
			@ego.bot.chat "baumiFlag baumiFlag Welcome @#{username} to the sexy pirate crew! baumiFlag baumiFlag"


module.exports = Subscription
