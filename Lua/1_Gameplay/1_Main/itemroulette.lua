local ROULETTE_VERSION = 12

-- avoid redefiniton on updates
if timetravel.ROULETTE_VERSION == nil or timetravel.ROULETTE_VERSION < ROULETTE_VERSION then

local k_itemroulette = k_itemroulette
local k_position = k_position

local ROULETTE_ENDTIC = TICRATE*3

local function isValidItemOddsPlayer(player)
	return player.valid and not player.spectator and player.mo and player.mo.valid or player.mo.timetravel == nil
end

addHook("PreThinkFrame", function()
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	
	for player in players.iterate do
		if not isValidItemOddsPlayer(player) then continue end
		
		local pks = player.kartstuff
		local playerPosition = pks[k_position]
		
		-- You don't care about item odds if you're first, they're fixed for you.
		if playerPosition <= 1 then continue end
		
		local roulettetic = pks[k_itemroulette]
		
		if roulettetic <= 0 then continue end
		roulettetic = $ + 1 -- the function +1s the var inside, we simulate it.
		
		local pingame = 0
		for p in players.iterate
			if p.spectator then continue end
			pingame = $ + 1
		end
		
		local roulettestop = TICRATE + (3*(pingame - playerPosition))
		print(roulettestop)
		local canbemashed = roulettestop <= roulettetic
		
		if not (roulettetic >= ROULETTE_ENDTIC or (canbemashed and player.cmd.buttons & BT_ATTACK)) then continue end

		for otherPlayer in players.iterate do
			if otherPlayer == player or not isValidItemOddsPlayer(otherPlayer) then continue end
			
			-- Two people mashed or rolled at the same time, non-sense time.
			if otherPlayer.itemRollComeBack then continue end
			local otherPlayerPosition = otherPlayer.kartstuff[k_position]
			
			if playerPosition > otherPlayerPosition then
				if (player.mo.timetravel.isTimeWarped ~= otherPlayer.mo.timetravel.isTimeWarped) then
					timetravel.changePositions(otherPlayer.mo, true)
					otherPlayer.itemRollComeBack = true
					print(string.format("Player %s has been teleported (position %d)", otherPlayer.name, otherPlayerPosition))
				end
			end
		end
	end
end)

addHook("ThinkFrame", function(player)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	
	for player in players.iterate do
		if player.itemRollComeBack then
			timetravel.changePositions(player.mo, true)
			player.itemRollComeBack = false
		end
	end
end)

addHook("ShouldSquish", function(target, inflictor, source)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	
	-- We're looking for inflictor-less, source-less squishing.
	if inflictor ~= nil and source ~= nil then return nil end
	-- Prevent people from getting crushed on that one cut.
	if target.itemRollComeBack then return false end
end)

timetravel.ROULETTE_VERSION = ROULETTE_VERSION

end