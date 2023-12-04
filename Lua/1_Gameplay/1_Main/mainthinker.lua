local MAINTHINKER_VERSION = 10

-- avoid redefiniton on updates
if timetravel.MAINTHINKER_VERSION == nil or timetravel.MAINTHINKER_VERSION < MAINTHINKER_VERSION then

-- The mother of all thinkers.
addHook("PreThinkFrame", function()
	if timetravel.MAINTHINKER_VERSION > MAINTHINKER_VERSION then return end
	if not timetravel.isActive then return end
	
	for player in players.iterate do
		timetravel.timeTravelCooldownsHandler(player)
		timetravel.timeTravelInputThinker(player)
	end
	
	timetravel.dynMusThinker()
	timetravel.hudMinimapThinker()
	timetravel.echoes_OncePerFrameCalc()
end)

-- This needs to happen later.
addHook("ThinkFrame", function()
	if timetravel.MAINTHINKER_VERSION > MAINTHINKER_VERSION then return end
	if not timetravel.isActive then return end

	for player in players.iterate do
		timetravel.timeTravelStarpostHandler(player)
	end
end)

-- Everything that inits on start is here.
addHook("MapLoad", function()
	if timetravel.MAINTHINKER_VERSION > MAINTHINKER_VERSION then return end
	if not timetravel.isActive then return end

	timetravel.hudInit()
	timetravel.waypointsInit()
	timetravel.combiInit()
	timetravel.dynMusInit()
end)

timetravel.MAINTHINKER_VERSION = MAINTHINKER_VERSION

end