config = require './config'
irc = require 'twitch-irc'
EventEmitter = require('events').EventEmitter
Prompt = require './prompt'
ModuleManager = require './modulemanager'
vm = require 'vm'
redis = require 'redis'
domain = require 'domain'

defaults = {
	admins: ['chrisinajar']
	subs: []
}

class BaumisEgo
	constructor: (key)->
		#module stuff
		@eventProxies = {}
		@domains = {}

		prompt = @prompt = new Prompt()
		@prompt.setStatusLines [@prompt.clc.blackBright("Not connected")]
		@prompt.setStatusLines [@prompt.clc.green("Connected!")]

		@module = new ModuleManager @prompt, @

		@bot = new irc.client key
		@bot._emit = @bot.emit
		@bot.emit = (name)=>
			# console.log arguments
			@module.proxyEvent arguments
			@bot._emit.apply(@bot, arguments)
		@bot.chat = (msg)->
			@say config.irc.channels[0], msg
			prompt.log prompt.clc.blackBright(config.irc.identity.username) + ":", prompt.clc.cyanBright(msg)
		@bot.on = @bot.addListener

		@db = redis.createClient()
		@db.on 'error', (err)=>
			@prompt.log @prompt.clc.red("Error: #{err}")
		@db.get 'baumibot_config', (err, data)=>
			if err
				return

			@prompt.log @prompt.clc.blackBright(data)

			if !data
				@db.set 'baumibot_config', JSON.stringify(defaults), @connect
				@config = defaults
			else
				@config = JSON.parse data
				@connect()



		# @bot.addListener 'error', @connect
		# @bot.addListener 'close', @connect

		# @bot.addListener 'error', (data)=>
			# @prompt.setStatusLines [@prompt.clc.red("Error!")]
		# @bot.addListener 'close', =>
			# @prompt.setStatusLines [@prompt.clc.blackBright("Not connected")]
		# @bot.setLogObject(@prompt)

		@prompt.on 'line', (msg)=>
			if (msg.charAt(0) == "/")
				if (msg.charAt(1) == " ")
					msg = "/"+msg.substring(2)
				else
					return @parseCommand msg

			@bot.chat msg

		@bot.addListener 'jtv', (data)=>
			@processJTV( if data.length then data[1] else data )

		@bot.addListener 'chat', @chat
		@bot.addListener 'connecteding', =>
			@prompt.setStatusLines [@prompt.clc.yellow("Joining room...")]
		# @bot.addListener 'djAdvance', (data)=>
		# 	@currentSong = data.media
		# 	@setStatusLines()
		@bot.addListener 'connected', (data)=>
		# 	@userCache = new UserCache(data.room.users, @prompt, @module.getEventProxy("usercache"))
		# 	@userCache.on 'changed', @setStatusLines
		# 	@room = data.room
		# 	@currentSong = data.room.media
			@setStatusLines()
	storeConfig: =>
		@db.set 'baumibot_config', JSON.stringify(@config)
	setStatusLines: =>
		@prompt.setStatusLines [
			@prompt.clc.green("Connected!")
			]

	parseCommand: (msg)->
		index = msg.indexOf(" ")
		if index < 1 then index = msg.length
		cmd = msg.substring(1, index)

		if index == msg.length
			args = null
		else
			args = msg.substring index

		switch cmd
			when "e"
				try
					result = vm.runInContext args, context
					@prompt.log result
				catch e
					@prompt.log e
			when "l"
				args = args.trim()
				if (args == "usercache")
					@prompt.setStatusLines [@prompt.clc.yellow("Joining room...")]
					delete require.cache[require.resolve("./usercache")]
					delete @eventProxies["usercache"]
					delete @domains["usercache"]
					UserCache = require './usercache'
					# @bot.joinRoom "coding-soundtrack"
				else
					@module.loadModule args
	processJTV: (str)=>
		parts = str.split(' ')
		if parts[0] == 'SPECIALUSER'
			# shift then pop and do a little dance
			parts.shift()
			type = parts.pop()
			user = parts.join(' ')
			@prompt.log "#{user} is a #{type}"

			if type == "subscriber"
				index = @config.subs.indexOf(user)
				if index != -1
					@config.subs.splice index, 1

				@config.subs.push user
				@storeConfig()

	chat: (channel, user, message)=>
		@prompt.log @prompt.clc.blue(user.username+": ") + message

		if message[0] == '!'
			index = message.indexOf(" ")
			if index < 1 then index = message.length
			cmd = message.substring(1, index)

			if index == message.length
				args = null
			else
				args = message.substring index
				args = args.trim()
				args = args.split " "

			if @config.admins.indexOf(user.username) > -1
				user.admin = true
			else
				user.admin = false

			if @config.subs.indexOf(user.username) > -1
				user.sub = true
			else
				user.sub = false


			@bot.emit 'command', user, cmd, args


	connect: =>
		@bot.connect()
		@module.loadModule module for module in config.plugins

ego = new BaumisEgo(config.irc)

scope = 
	bot: ego.bot
	ego: ego
	db: ego.db
	prompt: ego.prompt
	require: require

context = vm.createContext scope