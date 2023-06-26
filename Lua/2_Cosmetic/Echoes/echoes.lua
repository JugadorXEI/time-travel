local ECHOES_VERSION = 1

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

local GT_MATCH = GT_MATCH

freeslot("MT_ECHOGHOST")
mobjinfo[MT_ECHOGHOST] = {
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_DONTENCOREMAP
}

timetravel.echoBonkCooldown = (TICRATE/2) - 2
timetravel.echoItemCollideCooldown = TICRATE/4
timetravel.validTypesToEcho = {}

addHook("MobjThinker", function(mo)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if mo.linkedItem == nil or mo.linkedItem.valid == false then return end
	
	local xOffset, yOffset = timetravel.determineTimeWarpPosition(mo.linkedItem)
	
	local movement = P_MoveOrigin
	if mo.justEchoTeleported then movement = P_SetOrigin end
	movement(mo, mo.linkedItem.x + xOffset, mo.linkedItem.y + yOffset, mo.linkedItem.z)
	
	if mo.justEchoTeleported and mo.linkedItem.player then
		-- We play a sound later on, and we cannot play another new sound with the same origin apparently.
		-- So we create a new one, temporarily. Only for the player tho otherwise it's confusing.
		local soundHack = P_SpawnMobj(mo.x, mo.y, mo.z, MT_OVERLAY)
		soundHack.target = mo
		soundHack.state = S_INVISIBLE
		soundHack.fuse = 2
		S_StartSound(soundHack, sfx_ttshit)
	end
	
	mo.justEchoTeleported = false
	
	if mo.linkedItem.type == MT_PLAYER then
		mo.skin = mo.linkedItem.skin
	end
	
	mo.color = mo.linkedItem.color
	mo.sprite = mo.linkedItem.sprite
	mo.scale = mo.linkedItem.scale
	mo.destscale = mo.linkedItem.destscale
	mo.height = mo.linkedItem.height
	mo.radius = mo.linkedItem.radius
	
	if mo.linkedItem.type == MT_PLAYER then
		mo.angle = mo.linkedItem.player.frameangle
	else mo.angle = mo.linkedItem.angle
	end
	
	mo.flags2 = mo.linkedItem.flags2
	mo.colorized = true
	
	local transFlag = 0	
	if (mo.linkedItem.flags & MF_SHOOTABLE) then
		transFlag = FF_TRANS50 - abs(FF_TRANS10 * (((TICRATE/2) - (leveltime % TICRATE)) / 4))
	elseif (mo.linkedItem.frame & FF_TRANSMASK) == 0 then
		transFlag = FF_TRANS50
	end	
	if transFlag ~= 0 then mo.frame = $ & (~FF_TRANSMASK) end
	
	mo.frame = mo.linkedItem.frame | transFlag
	
	timetravel.playEchoIdleBehaviour(mo)
end, MT_ECHOGHOST)

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
		if (tmthing.timetravel.touchEchoCD or 0) <= 0 and (thing.linkedItem.timetravel.touchEchoCD or 0) <= 0 then
			thing.linkedItem.timetravel.delayedMobjReaction = tmthing
			thing.linkedItem.timetravel.delayedMobjReactionDir = timetravel.getNormalizedVectors(tmthing.momx, tmthing.momy)
			thing.linkedItem.timetravel.delayedMobjReactionZPos = tmthing.z
		end
		
		tmthing.timetravel.touchEchoCD = timetravel.echoBonkCooldown
		thing.linkedItem.timetravel.touchEchoCD = timetravel.echoBonkCooldown
	else -- Hitting an item echo puts you into its timeline.
		local playerMobj, itemMobj
		if thing.linkedItem.type == MT_PLAYER then
			playerMobj = thing.linkedItem
			itemMobj = tmthing
		else
			playerMobj = tmthing
			itemMobj = thing.linkedItem
		end
		
		if (playerMobj.timetravel.touchEchoCD or 0) <= 0 and 
			(itemMobj.flags & MF_SHOOTABLE == 0 or (itemMobj.flags & MF_SHOOTABLE and not (itemMobj.target == playerMobj and itemMobj.threshold > 0))) and
			itemMobj.health > 0 then
			-- Hitting an item echo puts you into its timeline.
			playerMobj.timetravel.delayedMobjReaction = itemMobj
			playerMobj.timetravel.delayedMobjReactionDir = timetravel.getNormalizedVectors(itemMobj.momx, itemMobj.momy)
			playerMobj.timetravel.delayedMobjReactionZPos = itemMobj.z
			
			playerMobj.timetravel.touchEchoCD = timetravel.echoItemCollideCooldown
			itemMobj.timetravel.touchEchoCD = timetravel.echoItemCollideCooldown
		elseif itemMobj.threshold <= 0 then
			playerMobj.timetravel.touchEchoCD = timetravel.echoItemCollideCooldown
			itemMobj.timetravel.touchEchoCD = timetravel.echoItemCollideCooldown
		end
	end
	
	return false

end, MT_ECHOGHOST)

-- Fix false cases of the echoes just dying if you touch them weird.
addHook("TouchSpecial", function(special, toucher)
	return true
end, MT_ECHOGHOST)

addHook("MobjThinker", function(collisionReceiver)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	
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
end)

addHook("MobjDeath", function(mo, inflictor, source)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if mo.type == MT_ECHOGHOST then return end
	if mo.linkedItem == nil or mo.linkedItem.valid == false then return end
	
	timetravel.playEchoDeathSound(mo.linkedItem)
	-- If this is a death caused by a clash, spawn the item clash mobj
	-- (this is technically a hack but you've seen the rest of the code, right?)
	if inflictor and source and
		timetravel.isClashableItem(mo.type) and timetravel.isClashableItem(inflictor.type) and inflictor == source then
		local xOffset, yOffset = timetravel.determineTimeWarpPosition(mo)
		local x = (mo.x/2 + inflictor.x/2) + xOffset
		local y = (mo.y/2 + inflictor.y/2) + yOffset
		local z = (mo.z/2 + inflictor.z/2)
		P_SpawnMobj(x, y, z, MT_ITEMCLASH)
	end
end)

-- Eggman Monitor-specific hack to play its pickup sound and effects.
local function eggmanSoundHandler(special, toucher)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if special.linkedItem == nil or special.linkedItem.valid == false then return end
	
	if (special.target == toucher or special.target == toucher.target) and special.threshold > 0 then return end
	if special.health <= 0 or toucher.health <= 0 then return end
	local player = toucher.player
	if not (player and player.valid) then return end
	if not P_CanPickupItem(player, 2) then return end

	local poof = P_SpawnMobj(special.linkedItem.x, special.linkedItem.y, special.linkedItem.z, MT_EXPLODE)
	poof.frame = poof.frame | FF_TRANS50
	S_StartSound(poof, special.info.deathsound)
end

addHook("TouchSpecial", eggmanSoundHandler, MT_EGGMANITEM)
addHook("TouchSpecial", eggmanSoundHandler, MT_EGGMANITEM_SHIELD)

-- Process this after the eggman handling:
addHook("MobjRemoved", function(mo)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if mo.type == MT_ECHOGHOST then return end
	if mo.linkedItem == nil or mo.linkedItem.valid == false then return end
	
	P_RemoveMobj(mo.linkedItem)
end)

-- Makes echo explosions work
addHook("PlayerExplode", function(player, inflictor, source)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not (inflictor and inflictor.valid) then return end
	
	local mo = player.mo
	if not (mo.linkedItem and mo.linkedItem.valid) then return end
		
	if inflictor.type == MT_SPBEXPLOSION or inflictor.type == MT_MINEEXPLOSION then
		K_SpawnMineExplosion(mo.linkedItem, mo.color)
	end
end)

addHook("MobjThinker", function(mo)
	if timetravel.ECHOES_VERSION > ECHOES_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	if not (mo and mo.valid) then return end
	if not mo.echoable then return end
	if mo.linkedItem ~= nil then return end
	
	if timetravel.performSpecialSpawnCode(mo) then return end
	
	local targetPlayer = mo.target
	local tracerPlayer = mo.tracer
	if targetPlayer ~= nil then targetPlayer = $.player end
	if tracerPlayer ~= nil then tracerPlayer = $.player end

	local player = (mo.player or targetPlayer) or tracerPlayer
	if player == nil or player.mo.timetravel == nil then return end
	
	local xOffset, yOffset = timetravel.determineTimeWarpPosition(player.mo)
	
	local echoItem = timetravel.SpawnEchoMobj(mo)
	P_SetOrigin(echoItem, mo.x + xOffset, mo.y + yOffset, mo.z)
	
	if mo.timetravel == nil and mo.type ~= MT_PLAYER then mo.timetravel = {} end
	echoItem.timetravel = {}
	
	mo.timetravel.isTimeWarped 			= player.mo.timetravel.isTimeWarped
	echoItem.timetravel.isTimeWarped 	= not player.mo.timetravel.isTimeWarped
	
	mo.timetravel.touchEchoCD 			= 0
	
	echoItem.linkedItem = mo
	mo.linkedItem 		= echoItem
	
	timetravel.playEchoSpawnSound(echoItem)
	if mo.flags & MF_SHOOTABLE and mo.type ~= MT_EGGMANITEM and mo.type ~= MT_EGGMANITEM_SHIELD then
		P_SpawnShadowMobj(echoItem)
	end
end)

addHook("MobjSpawn", function(mo)
	-- Check if this is a echoes-able mobj.
	for _, value in ipairs(timetravel.validTypesToEcho) do
		if value == mo.type then
			mo.echoable = true
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
		if mobjFound ~= nil then table.insert(timetravel.validTypesToEcho, mobjFound) end
	end
end

addHook("NetVars", initializeEchoHooks)
addHook("MapChange", initializeEchoHooks)

timetravel.ECHOES_VERSION = ECHOES_VERSION

end