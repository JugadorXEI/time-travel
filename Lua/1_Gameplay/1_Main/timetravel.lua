local VERSION = 1

-- avoid redefiniton on updates
if timetravel.VERSION == nil or timetravel.VERSION < VERSION then

-- TIME TRAVEL
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local RING_DIST = RING_DIST
local KITEM_THUNDERSHIELD = KITEM_THUNDERSHIELD
local BT_ATTACK = BT_ATTACK
local sfx_kc50 = sfx_kc50
local k_itemtype = k_itemtype
local k_respawn = k_respawn

local cos = cos
local sin = sin
local ipairs = ipairs
local pcall = pcall
local tonumber = tonumber
local FixedMul = FixedMul
local P_SetOrigin = P_SetOrigin
local P_RandomChance = P_RandomChance
local R_PointToDist2 = R_PointToDist2
local S_StopMusic = S_StopMusic
local S_StartSound = S_StartSound
local P_KillMobj = P_KillMobj
local P_RemoveMobj = P_RemoveMobj
local COM_BufInsertText = COM_BufInsertText

timetravel.teleportCooldown = TICRATE
local starttime = 6*TICRATE + 3*TICRATE/4
timetravel.introTP1tic = TICRATE+2
timetravel.introTP2tic = (TICRATE*3)+2

timetravel.isActive = false
timetravel.localXdist = 0
timetravel.localYdist = 0
timetravel.hasBackrooms = false
timetravel.backroomsX = 0
timetravel.backroomsY = 0
timetravel.backroomsZ = 0

timetravel.hookFuncs = {}

freeslot("sfx_ttshif", "sfx_ttshit", "sfx_ttfail", "sfx_ttfrag", "sfx_cdpast", "sfx_cdfutr")

sfxinfo[sfx_ttshif] = {
	singular = false,
	priority = 64,
	flags = 0
}

sfxinfo[sfx_ttshit] = {
	singular = false,
	priority = 64,
	flags = 0
}

timetravel.determineTimeWarpPosition = function(mo)
	local xOffset = 0
	local yOffset = 0

	if mo.timetravel and mo.timetravel.isTimeWarped then
		xOffset = $ - timetravel.localXdist
		yOffset = $ - timetravel.localYdist
	else
		xOffset = $ + timetravel.localXdist
		yOffset = $ + timetravel.localYdist
	end

	return xOffset, yOffset
end

timetravel.changePositions = function(mo, dontrunextralogic)
	local xOffset, yOffset = timetravel.determineTimeWarpPosition(mo)
	local finalX = mo.x + xOffset
	local finalY = mo.y + yOffset

	P_SetOrigin(mo, finalX, finalY, mo.z)
	
	if mo.timetravel.isTimeWarped == nil then
		mo.timetravel.isTimeWarped = false
	end
	mo.timetravel.isTimeWarped = not $
	
	if dontrunextralogic then return end
	
	if mo.linkedItem and mo.linkedItem.valid and mo.linkedItem.type == MT_ECHOGHOST then
		mo.linkedItem.justEchoTeleported = true
	end
	
	if mo.z < mo.floorz then
		-- print(abs(mo.floorz - mo.z)>>FRACBITS + " | " + ((mo.height * 3) >>FRACBITS))
		if abs(mo.floorz - mo.z) > mo.height then
			if timetravel.hasBackrooms and P_RandomChance(FRACUNIT/100) then
				P_SetOrigin(mo, timetravel.backroomsX, timetravel.backroomsY, timetravel.backroomsZ)
				
				-- Transform momentum to where the mo is looking
				local thrustForce = R_PointToDist2(0, 0, mo.momx, mo.momy)
				mo.momx = FixedMul(thrustForce, cos(mo.angle))
				mo.momy = FixedMul(thrustForce, sin(mo.angle))
				
				if mo.player then S_StopMusic(mo.player) end
			else
				S_StartSound(mo, sfx_ttfrag)
				if mo.linkedItem then S_StartSound(mo.linkedItem, sfx_ttfrag) end
				P_KillMobj(mo) -- DEATH.
				
				-- Destroy everything in the hnext chain.
				-- (Orbinals, 'nanas, Rocket Sneakers)
				local hNext = mo.hnext
				while hNext and hNext.valid do
					P_RemoveMobj(hNext)
					hNext = mo.hnext
				end
			end
		end
	end
end

timetravel.teleport = function(mo, dontrunhooks)
	if not dontrunhooks then
		local result = timetravel.runHooks(mo)
		if result == false then return result end
	end

	local player = mo.player
	if player then
		local localDisplayPlayer = timetravel.isDisplayPlayer(player) 
		if localDisplayPlayer > -1 then player.timetravelconsts.TWFlash = 5 end
		mo.timetravel.teleportCooldown = timetravel.teleportCooldown
	end
	
	timetravel.changePositions(mo)
	S_StartSound(mo, sfx_ttshif)
	
	-- Stuff in the mo's hnext list will also time travel.
	local moHnext = mo.hnext
	while moHnext ~= nil do
		if moHnext.timetravel then timetravel.changePositions(moHnext) end
		moHnext = moHnext.hnext
	end
	
	if consoleplayer and player and timetravel.isDisplayPlayer(player) ~= -1 and not player.exiting then
		COM_BufInsertText(consoleplayer, "resetcamera")
	end
	
	return true
end

timetravel.addTimeTravelHook = function(func)
	table.insert(timetravel.hookFuncs, func)
end

timetravel.runHooks = function(mo)
	local result = nil
	for _, v in ipairs(timetravel.hookFuncs) do
		-- Don't let people's awful code break teleporting, please.
		local ran, errorMsg = pcall(function() result = v(mo) end)
		
		if not ran then
			print(errorMsg)
			continue
		end
	end
	return result

end

timetravel.handleThunderShieldZap = function(player)
	local mobj = player.mo
	if not (mobj and mobj.valid) then return end
	
	local thunderradius = RING_DIST/4
	local linkedItem = mobj.linkedItem
	
	searchBlockmap("objects", function(refmobj, foundmobj)
		if FixedHypot(FixedHypot(refmobj.x - foundmobj.x, refmobj.y - foundmobj.y),
			refmobj.z - foundmobj.z) > thunderradius then return nil end -- In radius?
		
		if not foundmobj.timetravel then return nil end
		if foundmobj == mobj then return end
		
		timetravel.teleport(foundmobj)
		
	end, linkedItem, 	linkedItem.x - thunderradius, linkedItem.x + thunderradius,
						linkedItem.y - thunderradius, linkedItem.y + thunderradius)
end

timetravel.timeTravelInputThinker = function(player)
	if timetravel.VERSION > VERSION then return end
	
	local pMo = player.mo
	if not (pMo and pMo.valid and not player.spectator) then
		player.timetravelconsts = $ or {}
		player.timetravelconsts.spectatorTimer = $ or 0
		
		if player.timetravelconsts.spectatorTimer >= TICRATE then
			player.timetravelconsts.starpostStatus = false
			player.timetravelconsts.starpostNumOld = 0
		else
			player.timetravelconsts.spectatorTimer = $ + 1
		end
		
		continue
	end
	
	local leveltime = leveltime
	if leveltime == 2 then -- Init
		pMo.timetravel = {}
		pMo.timetravel.isTimeWarped = false
		player.timetravelconsts = {}
	end
	
	-- Intro teleports:
	if leveltime == timetravel.introTP1tic or leveltime == timetravel.introTP2tic then timetravel.teleport(pMo) end
	-- Don't allow player input until the race starts.
	if leveltime < starttime then continue end
	
	if player.cmd.buttons & BT_ATTACK and not player.timetravelconsts.holdingItemButton then
		if not timetravel.isInDamageState(player) and not timetravel.canUseItem(player) and 
			(pMo.timetravel.teleportCooldown == nil or pMo.timetravel.teleportCooldown <= 0) then
			timetravel.teleport(pMo)
		elseif not timetravel.isInDamageState(player) and timetravel.canUseItem(player) and
			player.kartstuff[k_respawn] == 0 and player.kartstuff[k_itemtype] == KITEM_THUNDERSHIELD then
			timetravel.handleThunderShieldZap(player)
		elseif not timetravel.canUseItem(player) and player.kartstuff[k_eggmanheld] == 0 then -- INCORRECTLY LOUD BUZZER
			S_StartSound(nil, sfx_ttfail, player)
		end
		
		player.timetravelconsts.holdingItemButton = true
	elseif not (player.cmd.buttons & BT_ATTACK) and player.timetravelconsts.holdingItemButton then
		player.timetravelconsts.holdingItemButton = false
	end
	
	-- Checkpoint Nums:		
	if player.starpostnum ~= player.timetravelconsts.starpostNumOld then
		if player.starpostnum == 0 then
			player.timetravelconsts.starpostStatus = false
		else
			player.timetravelconsts.starpostStatus = player.mo.timetravel.isTimeWarped
		end
	end

	player.timetravelconsts.starpostNumOld = player.starpostnum
	player.timetravelconsts.spectatorTimer = 0
end

timetravel.timeTravelCooldownsHandler = function(player)
	if timetravel.VERSION > VERSION then return end

	local pMo = player.mo
	if pMo and pMo.valid and pMo.timetravel then
		local pMoTimeTravel = pMo.timetravel
		pMoTimeTravel.teleportCooldown = $ or 0
		
		if pMoTimeTravel.teleportCooldown > 0 then
			pMoTimeTravel.teleportCooldown = $ - 1
		
			if pMoTimeTravel.teleportCooldown == 0 then
				S_StartSound(nil, sfx_kc50, player)
				
				local sfx = sfx_cdpast
				if pMoTimeTravel.isTimeWarped == true then
					sfx = sfx_cdfutr
				end
				
				S_StartSound(nil, sfx, player)
			end
		end
	end	
	
	if player.timetravelconsts then
		player.timetravelconsts.TWFlash = $ or 0
		if player.timetravelconsts.TWFlash > 0 then
			player.timetravelconsts.TWFlash = $ - 1
		end
	end
end

local thunderShieldBehaviour = function(player, inflictor, source)
	if timetravel.VERSION > VERSION then return end
	if not timetravel.isActive then return end

	if player.kartstuff[k_itemtype] == KITEM_THUNDERSHIELD then
		timetravel.handleThunderShieldZap(player)
	end
end

addHook("ShouldSpin", thunderShieldBehaviour)
addHook("ShouldExplode", thunderShieldBehaviour)
addHook("ShouldSquish", thunderShieldBehaviour)

addHook("PlayerSpawn", function(player) -- Restore time warp status to mo.
	if timetravel.VERSION > VERSION then return end
	if not timetravel.isActive then return end
	local pMo = player.mo
	if not (pMo and pMo.valid) then return end
	
	player.timetravelconsts = $ or {}
	pMo.timetravel = {}
	pMo.timetravel.isTimeWarped = player.timetravelconsts.starpostStatus or false
end)

addHook("MapChange", function(mapnum)
	if timetravel.VERSION > VERSION then return end
	
	if timetravel.isActive == true then -- cleanup
		for player in players.iterate do
			player.timetravelconsts = nil
		end
	end
	
	timetravel.isActive = false
	timetravel.localXdist = 0
	timetravel.localYdist = 0
	timetravel.hasBackrooms = false
	timetravel.backroomsX = 0
	timetravel.backroomsY = 0
	timetravel.backroomsZ = 0
	
	local XYOffsets = timetravel.turnCommaDelimitedStringIntoTable(mapheaderinfo[mapnum]["tt_2ndmapxyoffset"])
	local XYBackrooms = timetravel.turnCommaDelimitedStringIntoTable(mapheaderinfo[mapnum]["tt_backroomspos"])
	-- print(XYOffsets)
		
	if #XYOffsets >= 2 then
		timetravel.localXdist = tonumber(XYOffsets[1]) << FRACBITS
		timetravel.localYdist = tonumber(XYOffsets[2]) << FRACBITS
	end
	
	if #XYBackrooms >= 3 then
		timetravel.hasBackrooms = true
		timetravel.backroomsX = tonumber(XYBackrooms[1]) << FRACBITS
		timetravel.backroomsY = tonumber(XYBackrooms[2]) << FRACBITS
		timetravel.backroomsZ = tonumber(XYBackrooms[3]) << FRACBITS
	end
	
	if timetravel.localXdist ~= 0 or timetravel.localYdist ~= 0 then
		timetravel.isActive = true
	end
end)

addHook("NetVars", function(network)
	if timetravel.VERSION > VERSION then return end
	
	timetravel.isActive = network($)
	timetravel.localXdist = network($)
	timetravel.localYdist = network($)
	timetravel.hasBackrooms = network($)
	timetravel.backroomsX = network($)
	timetravel.backroomsY = network($)
	timetravel.backroomsZ = network($)
end)

timetravel.VERSION = VERSION

end