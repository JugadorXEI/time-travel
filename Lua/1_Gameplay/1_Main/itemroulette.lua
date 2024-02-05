--[[
GPLv2 notice: Reimplementation of K_KartItemRoulette,
made 05/02/2023 (dd/mm/aaaa).
]]

local ROULETTE_VERSION = 12

-- avoid redefiniton on updates
if timetravel.ROULETTE_VERSION == nil or timetravel.ROULETTE_VERSION < ROULETTE_VERSION then

local k_itemroulette = k_itemroulette
local k_position = k_position
local TICRATE = TICRATE
local BT_ATTACK = BT_ATTACK

local ROULETTE_ENDTIC = TICRATE*3

local function isValidItemOddsPlayer(player)
	local playerMo = player.mo
	return player.valid and not player.spectator and playerMo and playerMo.valid or playerMo.timetravelconsts == nil
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
		for p in players.iterate do
			if p.spectator then continue end
			pingame = $ + 1
		end
		
		local roulettestop = TICRATE + (3*(pingame - playerPosition))
		local canbemashed = roulettestop <= roulettetic
		
		if not (roulettetic >= ROULETTE_ENDTIC or (canbemashed and player.cmd.buttons & BT_ATTACK)) then continue end

		for otherPlayer in players.iterate do
			if otherPlayer == player or not isValidItemOddsPlayer(otherPlayer) then continue end
			
			-- Two people mashed or rolled at the same time, non-sense time.
			if otherPlayer.timetravelconsts.itemRollComeBack then continue end
			local otherPlayerPosition = otherPlayer.kartstuff[k_position]
			
			if playerPosition > otherPlayerPosition then
				if (player.mo.timetravel.isTimeWarped ~= otherPlayer.mo.timetravel.isTimeWarped) then
					otherPlayer.timetravelconsts.itemRollComeBack = true
					otherPlayer.timetravelconsts.storedComeBackZ = otherPlayer.mo.z
					timetravel.changePositions(otherPlayer.mo, true)
				end
			end
		end
	end
end)

addHook("ThinkFrame", function(player)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	
	for player in players.iterate do
		if player.timetravelconsts.itemRollComeBack then
			local playerMo = player.mo
			
			timetravel.changePositions(playerMo, true)
			
			local didZActuallyChange = player.timetravelconsts.storedComeBackZ ~= playerMo.z
			playerMo.z = player.timetravelconsts.storedComeBackZ
			
			-- Prevents camera weirdness.
			if didZActuallyChange and timetravel.isDisplayPlayer(player) ~= -1 then
				COM_BufInsertText(consoleplayer, "resetcamera")
			end
			
			player.timetravelconsts.itemRollComeBack = false
			player.timetravelconsts.storedComeBackZ = 0
		end
	end
end)

addHook("ShouldSquish", function(target, inflictor, source)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	
	-- We're looking for inflictor-less, source-less squishing.
	if inflictor ~= nil and source ~= nil then return nil end
	-- Prevent people from getting crushed on that one cut.
	if target.timetravelconsts.itemRollComeBack then return false end
end)

timetravel.ROULETTE_VERSION = ROULETTE_VERSION

end