local ECHOES_FUNCS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.ECHOES_FUNCS_VERSION == nil or timetravel.ECHOES_FUNCS_VERSION < ECHOES_FUNCS_VERSION then

local TICRATE = TICRATE
local FRACUNIT = FRACUNIT

local starttime = 6*TICRATE + 3*TICRATE/4

timetravel.echoRadiusMultiplier = (FRACUNIT/100)*98

timetravel.safelyCheckForMTExistence = function(mt)
	if pcall(function() return _G[mt] end) then
		return _G[mt]
	end
	
	return nil
end

timetravel.isClashableItem = function(mobjtype)
	return mobjtype == MT_ORBINAUT or mobjtype == MT_JAWZ or mobjtype == MT_JAWZ_DUD
			or mobjtype == MT_ORBINAUT_SHIELD or mobjtype == MT_JAWZ_SHIELD
			or mobjtype == MT_BANANA or mobjtype == MT_BANANA_SHIELD
			or mobjtype == MT_BALLHOG
end

timetravel.K_UpdateEngineSoundsEX = function(player, cmd)
	
	local numsnds = 13

	local closedist = 160<<FRACBITS
	local fardist = 1536<<FRACBITS

	local dampenval = 48

	local class, s, w -- engine class number

	local volume = 255
	local volumedampen = FRACUNIT

	local targetsnd = 0
	local i

	s = (player.kartspeed - 1) / 3
	w = (player.kartweight - 1) / 3
	
	if s < 0 then s = 0 end
	if s > 2 then s = 2 end

	if w < 0 then w = 0 end
	if w > 2 then w = 2 end

	class = s + (3 * w)
	
	if leveltime < 8 or player.spectator or player.exiting then
		-- Silence the engines, and reset sound number while we're at it.
		player.kartstuff[k_enginesnd] = 0
		return
	end

	-- .25 seconds of wait time between each engine sound playback
	if leveltime % 8 then return end

	if (leveltime >= (starttime - (2*TICRATE)) and leveltime <= starttime) or player.kartstuff[k_respawn] == 1 then
		-- Startup boosts only want to check for BT_ACCELERATE being pressed.
		if (cmd.buttons & BT_ACCELERATE) then targetsnd = 12
		else targetsnd = 0 end
	else
		-- Average out the value of forwardmove and the speed that you're moving at.
		targetsnd = (((6 * cmd.forwardmove) / 25) + ((player.speed / mapobjectscale) / 5)) / 2
	end

	if targetsnd < 0 then targetsnd = 0 end
	if targetsnd > 12 then targetsnd = 12 end

	if player.kartstuff[k_enginesnd] < targetsnd then player.kartstuff[k_enginesnd] = $ + 1 end
	if player.kartstuff[k_enginesnd] > targetsnd then player.kartstuff[k_enginesnd] = $ - 1 end

	if player.kartstuff[k_enginesnd] < 0 then player.kartstuff[k_enginesnd] = 0 end
	if player.kartstuff[k_enginesnd] > 12 then player.kartstuff[k_enginesnd] = 12 end

	-- This code calculates how many players (and thus, how many engine sounds) are within ear shot,
	-- and rebalances the volume of your engine sound based on how far away they are.

	-- This results in multiple things:
	-- - When on your own, you will hear your own engine sound extremely clearly.
	-- - When you were alone but someone is gaining on you, yours will go quiet, and you can hear theirs more clearly.
	-- - When around tons of people, engine sounds will try to rebalance to not be as obnoxious.
	for otherPlayer in players.iterate do
		local thisvol = 0
		local dist
		
		if not otherPlayer.mo or not otherPlayer.mo.valid then continue end -- This player doesn't exist.
		if otherPlayer.spectator or otherPlayer.exiting then continue end -- This player isn't playing an engine sound.
		if player == otherPlayer or timetravel.isDisplayPlayer(otherPlayer) > -1 then continue end -- Don't dampen yourself!
		
		local otherPlayerMo = otherPlayer.mo
		
		if otherPlayer.mo.timetravel and player.mo.timetravel.isTimeWarped ~= otherPlayer.mo.timetravel.isTimeWarped then
			otherPlayerMo = otherPlayerMo.linkedItem
			if not (otherPlayerMo and otherPlayerMo.valid) then return end
		end

		dist = FixedHypot(
			FixedHypot(
				player.mo.x - otherPlayerMo.x,
				player.mo.y - otherPlayerMo.y),
				player.mo.z - otherPlayerMo.z) / 2

		dist = FixedDiv(dist, mapobjectscale)

		if dist > fardist then continue -- ENEMY OUT OF RANGE !
		elseif dist < closedist then thisvol = 255 -- engine sounds' approx. range
		else thisvol = (15 * ((closedist - dist) >> FRACBITS)) / ((fardist - closedist) >> (FRACBITS+4))
		end

		volumedampen = $ + (thisvol * dampenval)
	end
	
	if volumedampen > FRACUNIT then
		volume = FixedDiv(volume << FRACBITS, volumedampen) >> FRACBITS
	end

	if volume <= 0 then return end -- Don't need to play the sound at all.

	S_StartSoundAtVolume(player.mo.linkedItem, (sfx_krta00 + player.kartstuff[k_enginesnd]) + (class * numsnds), volume)
end

timetravel.K_UpdateInvincibilitySoundsEX = function(player, mobj)

	if not (player and player.mo and player.mo.valid) then return end

	local sfxnum = sfx_None

	if player.mo.health > 0 and timetravel.isDisplayPlayer(player) == -1 then
		if CV_FindVar("kartinvinsfx").value then
			if player.kartstuff[k_growshrinktimer] > 0 then -- Prioritize Grow
				sfxnum = sfx_alarmg
			elseif player.kartstuff[k_invincibilitytimer] > 0 then
				sfxnum = sfx_alarmi
			end
		else
			if player.kartstuff[k_growshrinktimer] > 0 then
				sfxnum = sfx_kgrow
			elseif player.kartstuff[k_invincibilitytimer] > 0 then
				sfxnum = sfx_kinvnc
			end
		end
	end

	if sfxnum ~= sfx_None and not S_SoundPlaying(mobj, sfxnum) then
		S_StartSound(mobj, sfxnum)
	end
	
	local stopThis = function(this)
		if sfxnum ~= this and S_SoundPlaying(mobj, this) then
			S_StopSoundByID(mobj, this)
		end
	end
	
	stopThis(sfx_alarmi)
	stopThis(sfx_alarmg)
	stopThis(sfx_kinvnc)
	stopThis(sfx_kgrow)
end

-- Partial copy of P_SpawnGhostMobj
timetravel.SpawnEchoMobj = function(mo)
	local ghost = P_SpawnMobj(mo.x, mo.y, mo.z, MT_ECHOGHOST)

	ghost.scale 	= mo.scale
	ghost.destscale = mo.scale

	if mo.eflags & MFE_VERTICALFLIP then
		ghost.eflags = $ | MFE_VERTICALFLIP
		ghost.z = $ + (mo.height - ghost.height)
	end

	ghost.color 	= mo.color
	ghost.colorized = mo.colorized

	if mo.player then
		ghost.angle = mo.player.frameangle
	else
		ghost.angle = mo.angle
	end

	ghost.sprite 	= mo.sprite
	ghost.frame 	= mo.frame
	ghost.tics 		= -1
	ghost.frame 	= $ & (~FF_TRANSMASK)
	ghost.frame 	= $ | (tr_trans50 << FF_TRANSSHIFT)
	ghost.radius	= FixedMul(mo.radius, timetravel.echoRadiusMultiplier)
	ghost.height	= mo.height
	ghost.fuse 		= -1
	
	
	if mo.skin ~= nil then
		ghost.skin 	= mo.skin
	end
	
	if mo.flags2 & MF2_OBJECTFLIP then
		ghost.flags = $ | MF2_OBJECTFLIP
	end

	if not (mo.flags & MF_DONTENCOREMAP) then
		mo.flags = $ & (~MF_DONTENCOREMAP)
	end
	
	return ghost
end

timetravel.playEchoSpawnSound = function(mobj)
	local linkedItem = mobj.linkedItem
	local moType = linkedItem.type
	
	if timetravel.echoSpawnSounds[moType] then
		local sound = timetravel.echoSpawnSounds[moType]
		if type(sound) == "function" then sound = sound(mobj) end
		S_StartSound(mobj, sound)
	elseif mobj.linkedItem.flags & MF_SHOOTABLE then
		local seeSound = mobj.linkedItem.info.seesound
		if seeSound ~= nil then S_StartSound(mobj, seeSound) end
	else
		local activeSound = mobj.linkedItem.info.activesound
		if activeSound ~= nil then S_StartSound(mobj, activeSound) end
	end

	return nil
end

timetravel.playEchoIdleBehaviour = function(mobj)
	local moType = mobj.linkedItem.type

	if timetravel.echoIdleSounds[moType] then
		timetravel.echoIdleSounds[moType](mobj)
	end

	return nil
end

timetravel.playEchoDeathSound = function(mobj)
	local deathSound = mobj.linkedItem.info.deathsound
	if deathSound ~= nil then S_StartSound(mobj, deathSound) end

	return nil
end

timetravel.performSpecialSpawnCode = function(mobj)
	if timetravel.specialBehaviourFuncs[mobj.type] == nil then return false end
	return timetravel.specialBehaviourFuncs[mobj.type](mobj)
end

timetravel.ECHOES_FUNCS_VERSION = ECHOES_FUNCS_VERSION

end