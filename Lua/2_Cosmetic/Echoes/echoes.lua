local ECHOES_VERSION = 11

-- avoid redefiniton on updates
if timetravel.ECHOES_VERSION == nil or timetravel.ECHOES_VERSION < ECHOES_VERSION then

local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local starttime = 6*TICRATE + 3*TICRATE/4
local EXPLODESPINTIME = (3*TICRATE/2)+2

local MF_SPECIAL = MF_SPECIAL
local MF_NOGRAVITY = MF_NOGRAVITY
local MF_NOCLIP = MF_NOCLIP
local MF_NOCLIPHEIGHT = MF_NOCLIPHEIGHT
local MF_DONTENCOREMAP = MF_DONTENCOREMAP
local MF_SHOOTABLE = MF_SHOOTABLE

local FF_TRANS10 = FF_TRANS10
local FF_TRANS50 = FF_TRANS50
local FF_TRANSMASK = FF_TRANSMASK

local pw_flashing = pw_flashing
local k_squishedtimer = k_squishedtimer
local k_spinouttimer = k_spinouttimer
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_hyudorotimer = k_hyudorotimer
local k_bumper = k_bumper
local k_comebacktimer = k_comebacktimer
local k_comebackmode = k_comebackmode
local k_roulettetype = k_roulettetype
local k_itemroulette = k_itemroulette

local sfx_ttshit = sfx_ttshit
local sfx_s3k49 = sfx_s3k49

local GT_MATCH = GT_MATCH

local S_INVISIBLE = S_INVISIBLE

local table_insert = table.insert
local ipairs = ipairs
local K_SpawnMineExplosion = K_SpawnMineExplosion
local P_SpawnShadowMobj = P_SpawnShadowMobj
local P_RemoveMobj = P_RemoveMobj
local P_SpawnMobj = P_SpawnMobj
local S_StartSound = S_StartSound
local P_CheckPosition = P_CheckPosition
local P_SetOrigin = P_SetOrigin
local P_MoveOrigin = P_MoveOrigin

freeslot("MT_ECHOGHOST")
mobjinfo[MT_ECHOGHOST] = {
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_DONTENCOREMAP
}

timetravel.echoBonkCooldown = (TICRATE/2) - 2
timetravel.echoItemCollideCooldown = TICRATE/4
timetravel.validTypesToEcho = {}

local wavyTransFlag = FF_TRANS50

-- Helpers
local function isPlayerDamaged(player, withItemStates, alsoFlashTics)
	if alsoFlashTics == nil then alsoFlashTics = true end
	
	local pks = player.kartstuff
	return (alsoFlashTics and player.powers[pw_flashing] > 0) or pks[k_squishedtimer] > 0 or pks[k_spinouttimer] > 0 or
			(withItemStates and (pks[k_invincibilitytimer] > 0 or pks[k_growshrinktimer] > 0)) or
			(alsoFlashTics and pks[k_hyudorotimer] > 0) or
			(gametype == GT_MATCH and ((pks[k_bumper] <= 0 and pks[k_comebacktimer]) or pks[k_comebackmode] == 1))

end

local function justGotHit(player)
	local pks = player.kartstuff
	return pks[k_squishedtimer] == TICRATE or pks[k_spinouttimer] == (3*TICRATE/2)+2 or 
		pks[k_spinouttimer] == (5*EXPLODESPINTIME/2)+1 or pks[k_spinouttimer] == EXPLODESPINTIME or
		(pks[k_roulettetype] == 2 and pks[k_itemroulette] == 1)

end

-- This is not in echoesfunctions.lua for the sake of organization.
-- This ideally should never move from this file.
timetravel.echoes_SpawnHandler = function(mobj)
	if not mobj.echoable then return end
	if mobj.linkedItem ~= nil then return end
	
	if timetravel.performSpecialSpawnCode(mobj) then return end
	
	local targetPlayer = mobj.target
	local tracerPlayer = mobj.tracer
	if targetPlayer ~= nil then targetPlayer = $.player end
	if tracerPlayer ~= nil then tracerPlayer = $.player end

	local player = (mobj.player or targetPlayer) or tracerPlayer
	if player == nil or player.mo == nil or player.mo.timetravel == nil then return end
	
	local xOffset, yOffset = timetravel.determineTimeWarpPosition(player.mo)
	local timeTravelStatus = player.mo.timetravel.isTimeWarped
	
	if mobj.type == MT_MINEEXPLOSION then
		--[[
			Fucked up, evil and slow hack.
			Explosion hitbox objects don't have a reference to the mine. It'll grab the player reference,
			but it'll discern the completely wrong time travel and offset if the mine and player are in different timelines.
			So in order to know if it's the correct timeline, we need to discern if the distance between the hitbox and the player
			is bigger than the set time travel offset.
		]]
		local dist = FixedHypot(player.mo.x - mobj.x, player.mo.y - mobj.y)
		local offsetDist = FixedHypot(timetravel.localXdist, timetravel.localYdist)
		
		if dist >= offsetDist then
			timeTravelStatus = not timeTravelStatus
			xOffset, yOffset = timetravel.determineTimeWarpPositionBoolean(timeTravelStatus)
		end
	end
	
	local echoItem = timetravel.SpawnEchoMobj(mobj)
	P_SetOrigin(echoItem, mobj.x + xOffset, mobj.y + yOffset, mobj.z)
	
	if mobj.timetravel == nil and mobj.type ~= MT_PLAYER then mobj.timetravel = {} end
	echoItem.timetravel = {}
	
	mobj.timetravel.isTimeWarped 		= timeTravelStatus
	echoItem.timetravel.isTimeWarped 	= not timeTravelStatus
	
	mobj.timetravel.touchEchoCD = 0
	
	echoItem.linkedItem 	= mobj
	mobj.linkedItem 		= echoItem
	
	timetravel.playEchoSpawnSound(echoItem)
	if mobj.flags & MF_SHOOTABLE and mobj.type ~= MT_EGGMANITEM and mobj.type ~= MT_EGGMANITEM_SHIELD then
		P_SpawnShadowMobj(echoItem)
	end
end

timetravel.echoes_CollisionHandler = function(collisionReceiver)
	if collisionReceiver.linkedItem == nil then return end
	if collisionReceiver.timetravel == nil then return end
	if collisionReceiver.timetravel.touchEchoCD == nil then return end
	
	local otherMobj = collisionReceiver.timetravel.delayedMobjReaction
	
	if otherMobj and otherMobj.valid then
		local otherMobjDir = collisionReceiver.timetravel.delayedMobjReactionDir or {0, 0}
		local otherMobjZ = collisionReceiver.timetravel.delayedMobjReactionZPos or collisionReceiver.z
		
		if collisionReceiver.type == MT_PLAYER and otherMobj.type == MT_PLAYER then
			local collidePlayer, receivePlayer = collisionReceiver.player, otherMobj.player
			if not (isPlayerDamaged(collidePlayer) or isPlayerDamaged(receivePlayer)) then -- Neither is in flashtics.
				-- Pretty sure there's a better way to do this, but I can't recall.
				local damager, damaged = nil, nil
				local rampaging = false
				local squishThreshold = mapobjectscale/8
				
				if abs(otherMobj.scale - collisionReceiver.scale) > squishThreshold then
					if otherMobj.scale > collisionReceiver.scale then
						damager = otherMobj
						damaged = collisionReceiver
					elseif collisionReceiver.scale > otherMobj.scale then
						damager = collisionReceiver
						damaged = otherMobj
					end
					
					rampaging = true
				-- If either have invincibility, but not both.
				elseif (receivePlayer.kartstuff[k_invincibilitytimer] or collidePlayer.kartstuff[k_invincibilitytimer]) and
					not (receivePlayer.kartstuff[k_invincibilitytimer] and collidePlayer.kartstuff[k_invincibilitytimer]) then
					
					if receivePlayer.kartstuff[k_invincibilitytimer] and not collidePlayer.kartstuff[k_invincibilitytimer] then
						damager = otherMobj
						damaged = collisionReceiver
					elseif collidePlayer.kartstuff[k_invincibilitytimer] and not receivePlayer.kartstuff[k_invincibilitytimer] then
						damager = collisionReceiver
						damaged = otherMobj
					end
					
					rampaging = true
				else
					damager = collisionReceiver
					damaged = otherMobj
				end

				if not (rampaging and damaged.player.kartstuff[k_invincibilitytimer] > 0) then 
					timetravel.teleport(damaged)
				end
				
				-- We do this to get the previous height we collided with (fixes height checks)
				P_SetOrigin(otherMobj, otherMobj.x, otherMobj.y, otherMobjZ)
				pcall(function() P_CheckPosition(otherMobj, collisionReceiver.x + otherMobjDir[1], collisionReceiver.y + otherMobjDir[2]) end)

				if not (damaged.player.kartstuff[k_squishedtimer] > 0 or damager.player.kartstuff[k_squishedtimer] > 0) then
					S_StartSound(damager, sfx_s3k49) -- Sound doesn't play for both.
				end
				
				if not rampaging then timetravel.teleport(damager) end
			end
		else
			if collisionReceiver.type ~= MT_PLAYER or (collisionReceiver.player and not isPlayerDamaged(collisionReceiver.player, true, true)) then
				timetravel.teleport(collisionReceiver)
			end
			
			-- We need to revalidate this just in case due to eggboxes, urgh.
			if otherMobj and otherMobj.valid then
				-- We do this to get the previous height we collided with (fixes height checks)
				P_SetOrigin(otherMobj, otherMobj.x, otherMobj.y, otherMobjZ)
				-- This is surrounded by pcall because I get non-valid errors when I really shouldn't be getting it. Because eggboxes.
				pcall(function() P_CheckPosition(otherMobj, collisionReceiver.x + otherMobjDir[1], collisionReceiver.y + otherMobjDir[2]) end)
			end
		end
		
		collisionReceiver.timetravel.delayedMobjReaction = nil
		collisionReceiver.timetravel.delayedMobjReactionDir = nil
		collisionReceiver.timetravel.delayedMobjReactionZPos = nil
	end
	
	if collisionReceiver.timetravel.touchEchoCD > 0 then
		collisionReceiver.timetravel.touchEchoCD = $ - 1
	end
end

timetravel.echoes_OncePerFrameCalc = function(mobj)
	wavyTransFlag = FF_TRANS50 - abs(FF_TRANS10 * (((TICRATE/2) - (leveltime % TICRATE)) / 4))
end

timetravel.echoes_Thinker = function(mobj)
	local linkedItem = mobj.linkedItem
	local xOffset, yOffset = timetravel.determineTimeWarpPosition(linkedItem)
	
	local movement = P_MoveOrigin
	if mobj.justEchoTeleported then movement = P_SetOrigin end
	movement(mobj, linkedItem.x + xOffset, linkedItem.y + yOffset, linkedItem.z)
	
	if mobj.justEchoTeleported and linkedItem.player then
		-- We play a sound later on, and we cannot play another new sound with the same origin apparently.
		-- So we create a new one, temporarily. Only for the player tho otherwise it's confusing.
		local soundHack = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)
		soundHack.target = mobj
		soundHack.state = S_INVISIBLE
		soundHack.fuse = 2
		S_StartSound(soundHack, sfx_ttshit)
	end
	
	mobj.justEchoTeleported = false
	
	if linkedItem.type == MT_PLAYER then
		mobj.skin = linkedItem.skin
		mobj.color = linkedItem.color
		mobj.flags2 = linkedItem.flags2
	end
	
	mobj.sprite = linkedItem.sprite
	mobj.destscale = linkedItem.destscale
	
	if linkedItem.type == MT_PLAYER then
		mobj.angle = linkedItem.player.frameangle
	else mobj.angle = linkedItem.angle
	end
	
	local transFlag = 0	
	if (linkedItem.flags & MF_SHOOTABLE) then
		transFlag = wavyTransFlag
	elseif (linkedItem.frame & FF_TRANSMASK) == 0 then
		transFlag = FF_TRANS50
	end	
	if transFlag ~= 0 then mobj.frame = $ & (~FF_TRANSMASK) end
	
	mobj.frame = linkedItem.frame | transFlag
	
	timetravel.playEchoIdleBehaviour(mobj)
end

addHook("MobjCollide", function(thing, tmthing)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return false end
	
	-- Height checks.
	if tmthing.momz < 0 then
		if tmthing.z + tmthing.momz > thing.z + thing.height then
			return false
		end
	elseif tmthing.z > thing.z + thing.height then
		return false
	end
	
	if tmthing.momz > 0 then
		if tmthing.z + tmthing.height + tmthing.momz < thing.z then
			return false
		end
	elseif tmthing.z + tmthing.height < thing.z then
		return false
	end
	
	if thing.linkedItem == nil or thing.linkedItem.valid == false then return false end
	if tmthing.linkedItem == nil or tmthing.linkedItem.valid == false then return false end
	if thing == tmthing.linkedItem or thing.linkedItem == tmthing then return false end -- don't let things touch themselves...
	-- only relevant to shootables and things we wanna hit.
	if not (thing.linkedItem.flags & MF_SHOOTABLE or timetravel.additionalHittables[thing.linkedItem.type]) or
		not (tmthing.flags & MF_SHOOTABLE or timetravel.additionalHittables[tmthing.type]) then return false end
		
	if thing.linkedItem.type == MT_PLAYER and tmthing.type == MT_PLAYER -- Switch places.
		local thingTTTable = thing.linkedItem.timetravel
		local tmthingTTTable = tmthing.timetravel
	
		if (tmthingTTTable.touchEchoCD or 0) <= 0 and (thingTTTable.touchEchoCD or 0) <= 0 then
			thingTTTable.delayedMobjReaction = tmthing
			thingTTTable.delayedMobjReactionDir = timetravel.getNormalizedVectors(tmthing.momx, tmthing.momy)
			thingTTTable.delayedMobjReactionZPos = tmthing.z
		end
		
		tmthingTTTable.touchEchoCD = timetravel.echoBonkCooldown
		thingTTTable.touchEchoCD = timetravel.echoBonkCooldown
	else -- Hitting an item echo puts you into its timeline.
		local playerMobj, itemMobj
		if thing.linkedItem.type == MT_PLAYER then
			playerMobj = thing.linkedItem
			itemMobj = tmthing
		else
			playerMobj = tmthing
			itemMobj = thing.linkedItem
		end
		
		local playerMobjTTTable = playerMobj.timetravel
		local itemMobjTTTable = itemMobj.timetravel
		
		if (playerMobjTTTable.touchEchoCD or 0) <= 0 and 
			(itemMobj.flags & MF_SHOOTABLE == 0 or (itemMobj.flags & MF_SHOOTABLE and not (itemMobj.target == playerMobj and itemMobj.threshold > 0))) and
			itemMobj.health > 0 then
			-- Hitting an item echo puts you into its timeline.
			playerMobjTTTable.delayedMobjReaction = itemMobj
			playerMobjTTTable.delayedMobjReactionDir = timetravel.getNormalizedVectors(itemMobj.momx, itemMobj.momy)
			playerMobjTTTable.delayedMobjReactionZPos = itemMobj.z
			
			playerMobjTTTable.touchEchoCD = timetravel.echoItemCollideCooldown
			itemMobjTTTable.touchEchoCD = timetravel.echoItemCollideCooldown
		elseif itemMobj.threshold <= 0 then
			playerMobjTTTable.touchEchoCD = timetravel.echoItemCollideCooldown
			itemMobjTTTable.touchEchoCD = timetravel.echoItemCollideCooldown
		end
	end
	
	return false

end, MT_ECHOGHOST)

-- Fix false cases of the echoes just dying if you touch them weird.
addHook("TouchSpecial", function(special, toucher)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	return true
end, MT_ECHOGHOST)

addHook("MobjDeath", function(mobj, inflictor, source)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if mobj.type == MT_ECHOGHOST then return end
	if mobj.linkedItem == nil or mobj.linkedItem.valid == false then return end
	
	timetravel.playEchoDeathSound(mobj.linkedItem)
	-- If this is a death caused by a clash, spawn the item clash mobj
	-- (this is technically a hack but you've seen the rest of the code, right?)
	if inflictor and source and
		timetravel.isClashableItem(mobj.type) and timetravel.isClashableItem(inflictor.type) and inflictor == source then
		local xOffset, yOffset = timetravel.determineTimeWarpPosition(mobj)
		local x = (mobj.x/2 + inflictor.x/2) + xOffset
		local y = (mobj.y/2 + inflictor.y/2) + yOffset
		local z = (mobj.z/2 + inflictor.z/2)
		P_SpawnMobj(x, y, z, MT_ITEMCLASH)
	end
end)

addHook("TouchSpecial", function(special, toucher)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not timetravel.isActive then return end

	if special.type == MT_EGGMANITEM or special.type == MT_EGGMANITEM_SHIELD then
		timetravel.eggmanSoundHandler(special, toucher)
	end
end)

-- Process this after the eggman handling:
addHook("MobjRemoved", function(mobj)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if mobj.type == MT_ECHOGHOST then return end
	if mobj.linkedItem == nil or mobj.linkedItem.valid == false then return end
	
	P_RemoveMobj(mobj.linkedItem)
end)

-- Makes echo explosions work
addHook("PlayerExplode", function(player, inflictor, source)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not (inflictor and inflictor.valid) then return end
	
	local mobj = player.mo
	local linkedItem = mobj.linkedItem
	if not (linkedItem and linkedItem.valid) then return end
		
	if inflictor.type == MT_SPBEXPLOSION or inflictor.type == MT_MINEEXPLOSION then
		K_SpawnMineExplosion(linkedItem, mobj.color)
	end
end)

addHook("MobjThinker", function(mobj)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	
	if not (mobj and mobj.valid) then return end

	if mobj.type == MT_ECHOGHOST and mobj.linkedItem and mobj.linkedItem.valid then -- Movement thinker for echo ghosts
		timetravel.echoes_Thinker(mobj)
	else
		-- Spawn procedure for other mobjs - a normal mobj will have an echo if applicable.
		timetravel.echoes_SpawnHandler(mobj)
		if not (mobj and mobj.valid) then return end
		-- Handle echo-to-nonecho collision stuff here.
		timetravel.echoes_CollisionHandler(mobj)
	end
end)

addHook("MobjSpawn", function(mobj)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	-- Check if this is a echoes-able mobj.
	for _, value in ipairs(timetravel.validTypesToEcho) do
		if value == mobj.type then
			mobj.echoable = true
			break
		end
	end
end)

local function initializeEchoHooks()
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not timetravel.isActive then return end

	timetravel.validTypesToEcho = {}

	for _, value in ipairs(timetravel.typesToEcho) do
		local mobjFound = timetravel.safelyCheckForMTExistence(value)
		if mobjFound ~= nil then table_insert(timetravel.validTypesToEcho, mobjFound) end
	end
end

addHook("NetVars", initializeEchoHooks)
addHook("MapChange", initializeEchoHooks)

timetravel.ECHOES_VERSION = ECHOES_VERSION

end