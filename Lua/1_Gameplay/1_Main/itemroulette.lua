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
	if not (player and player.valid and not player.spectator) then return false end
	
	local playerMo = player.mo
	return playerMo and playerMo.valid or playerMo.timetravelconsts ~= nil
end

local function initItemOddsTeleport(player)
	local playerMo = player.mo

	if playerMo.timetravel.isTimeWarped then
		local ttConsts = player.timetravelconsts
		ttConsts.itemRollComeBack = true
		ttConsts.storedComeBackZ = playerMo.z
		timetravel.changePositions(playerMo, true)
	end
end

timetravel.itemOddsFixThinker = function()
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	-- If XItemLib is on, let XItemLib handle it instead (see xiteminterop.lua in 2_Interop folder)
	if timetravel.isXItemOddsEnabled then return end
	
	for player in players.iterate do
		if not isValidItemOddsPlayer(player) then continue end
		
		local pks = player.kartstuff
		local playerPosition = pks[k_position]
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
		if not player.timetravelconsts.itemRollComeBack then initItemOddsTeleport(player) end
		
		for otherPlayer in players.iterate do
			if otherPlayer == player or not isValidItemOddsPlayer(otherPlayer) then continue end
			
			-- Two people mashed or rolled at the same time, non-sense time.
			if otherPlayer.timetravelconsts.itemRollComeBack then continue end			
			initItemOddsTeleport(otherPlayer)
		end
	end
end

local function movePlayerBackToRealityAfterOdds(player)
	if not (player.timetravelconsts and player.timetravelconsts.itemRollComeBack) then return false end

	local playerMo = player.mo
	timetravel.changePositions(playerMo, true)
	
	local didZActuallyChange = abs(player.timetravelconsts.storedComeBackZ - playerMo.z) > (64<<FRACBITS)
	playerMo.z = player.timetravelconsts.storedComeBackZ
	
	-- Prevents camera weirdness.
	if didZActuallyChange and timetravel.isDisplayPlayer(player) ~= -1 then
		COM_BufInsertText(consoleplayer, "resetcamera")
	end
	
	player.timetravelconsts.itemRollComeBack = false
	player.timetravelconsts.storedComeBackZ = 0
	return true
end

addHook("PlayerThink", function(lastPlayer)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	if timetravel.isXItemOddsEnabled then return end
	
	if not timetravel.isLastPlayer(lastPlayer) then return end
	
	for player in players.iterate do
		if not movePlayerBackToRealityAfterOdds(player) then continue end
	end
end)

addHook("ShouldSquish", function(target, inflictor, source)
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not timetravel.isActive then return end
	if timetravel.isXItemOddsEnabled then return end
	
	-- We're looking for inflictor-less, source-less squishing.
	if inflictor ~= nil and source ~= nil then return nil end
	-- Prevent people from getting crushed on that one cut.
	if target.timetravelconsts.itemRollComeBack then return false end
end)

timetravel.ROULETTE_VERSION = ROULETTE_VERSION

end