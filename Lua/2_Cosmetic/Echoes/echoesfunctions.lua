local ECHOES_FUNCS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.ECHOES_FUNCS_VERSION == nil or timetravel.ECHOES_FUNCS_VERSION < ECHOES_FUNCS_VERSION then

local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local FRACBITS = FRACBITS
local k_respawn = k_respawn
local k_enginesnd = k_enginesnd
local k_growshrinktimer = k_growshrinktimer
local k_invincibilitytimer = k_invincibilitytimer
local k_drift = k_drift
local k_driftcharge = k_driftcharge
local BT_ACCELERATE = BT_ACCELERATE
local MFE_VERTICALFLIP = MFE_VERTICALFLIP
local MF2_OBJECTFLIP = MF2_OBJECTFLIP
local MF_DONTENCOREMAP = MF_DONTENCOREMAP
local MF_SHOOTABLE = MF_SHOOTABLE
local FF_TRANSMASK = FF_TRANSMASK
local FF_TRANSSHIFT = FF_TRANSSHIFT
local FF_TRANS50 = FF_TRANS50
local PF_SKIDDOWN = PF_SKIDDOWN
local tr_trans50 = tr_trans50

local ANGLE_180 = ANGLE_180
local ANG10 = ANG10

local sfx_None = sfx_None
local sfx_krta00 = sfx_krta00
local sfx_alarmg = sfx_alarmg
local sfx_alarmi = sfx_alarmi
local sfx_kgrow = sfx_kgrow
local sfx_kinvnc = sfx_kinvnc
local sfx_screec = sfx_screec
local sfx_s23c = sfx_s23c

local FixedHypot = FixedHypot
local FixedDiv = FixedDiv
local FixedMul = FixedMul
local S_SoundPlaying = S_SoundPlaying
local S_StopSoundByID = S_StopSoundByID
local S_StartSoundAtVolume = S_StartSoundAtVolume
local S_StartSound = S_StartSound
local CV_FindVar = CV_FindVar
local P_SpawnMobj = P_SpawnMobj
local R_PointToAngle2 = R_PointToAngle2
local K_GetKartDriftSparkValue = K_GetKartDriftSparkValue
local P_IsObjectOnGround = P_IsObjectOnGround
local P_CanPickupItem = P_CanPickupItem
local pcall = pcall
local type = type
local abs = abs

local kartinvinsfx = CV_FindVar("kartinvinsfx")

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

timetravel.canDisplayPlayerHearThis = function(mobj)

	--[[
	The display player(s) will not be able to hear things from
	a different timeline, this is an optimization measure.
	
	If any display player is spectating, then they will always be hearable.
	Otherwise, players in-game won't have sounds in other timelines play.
	(Only one timeline or the other.)
	(This kinda just exists to mute the engine sound function for players)
	]]

	for i = 0, 3 do
		if displayplayers[i] and (displayplayers[i].spectator or
			displayplayers[i].mo.timetravel.isTimeWarped ~= mobj.isTimeWarped) then
			return true
		end
	end
	
	return false

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
	
	local pks = player.kartstuff
	
	if leveltime < 8 or player.spectator or player.exiting then
		-- Silence the engines, and reset sound number while we're at it.
		pks[k_enginesnd] = 0
		return
	end

	-- .25 seconds of wait time between each engine sound playback
	if leveltime % 8 then return end

	if (leveltime >= (starttime - (2*TICRATE)) and leveltime <= starttime) or pks[k_respawn] == 1 then
		-- Startup boosts only want to check for BT_ACCELERATE being pressed.
		if (cmd.buttons & BT_ACCELERATE) then targetsnd = 12
		else targetsnd = 0 end
	else
		-- Average out the value of forwardmove and the speed that you're moving at.
		targetsnd = (((6 * cmd.forwardmove) / 25) + ((player.speed / mapobjectscale) / 5)) / 2
	end

	if targetsnd < 0 then targetsnd = 0 end
	if targetsnd > 12 then targetsnd = 12 end

	if pks[k_enginesnd] < targetsnd then pks[k_enginesnd] = $ + 1 end
	if pks[k_enginesnd] > targetsnd then pks[k_enginesnd] = $ - 1 end

	if pks[k_enginesnd] < 0 then pks[k_enginesnd] = 0 end
	if pks[k_enginesnd] > 12 then pks[k_enginesnd] = 12 end

	-- This code calculates how many players (and thus, how many engine sounds) are within ear shot,
	-- and rebalances the volume of your engine sound based on how far away they are.
	local playerMo = player.mo

	-- This results in multiple things:
	-- - When on your own, you will hear your own engine sound extremely clearly.
	-- - When you were alone but someone is gaining on you, yours will go quiet, and you can hear theirs more clearly.
	-- - When around tons of people, engine sounds will try to rebalance to not be as obnoxious.
	for otherPlayer in players.iterate do
		local thisvol = 0
		local dist
		
		local otherPlayerMo = otherPlayer.mo
		if not (otherPlayerMo and otherPlayerMo.valid) then continue end -- This player doesn't exist.
		if otherPlayer.spectator or otherPlayer.exiting then continue end -- This player isn't playing an engine sound.
		if player == otherPlayer or timetravel.isDisplayPlayer(otherPlayer) > -1 then continue end -- Don't dampen yourself!
		
		if otherPlayerMo.timetravel and playerMo.timetravel.isTimeWarped ~= otherPlayerMo.timetravel.isTimeWarped then
			otherPlayerMo = otherPlayerMo.linkedItem
			if not (otherPlayerMo and otherPlayerMo.valid) then return end
		end

		dist = FixedHypot(
			FixedHypot(
				playerMo.x - otherPlayerMo.x,
				playerMo.y - otherPlayerMo.y),
				playerMo.z - otherPlayerMo.z) / 2

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

	S_StartSoundAtVolume(playerMo.linkedItem, (sfx_krta00 + pks[k_enginesnd]) + (class * numsnds), volume)
end

local function stopThis(mobj, sfxnum, this)
	if sfxnum ~= this and S_SoundPlaying(mobj, this) then
		S_StopSoundByID(mobj, this)
	end
end

timetravel.K_UpdateInvincibilitySoundsEX = function(player, mobj)
	local playerMo = player.mo
	if not (player and playerMo and playerMo.valid) then return end

	local sfxnum = sfx_None

	if playerMo.health > 0 and timetravel.isDisplayPlayer(player) == -1 then
		local pks = player.kartstuff
		if kartinvinsfx.value then
			if pks[k_growshrinktimer] > 0 then -- Prioritize Grow
				sfxnum = sfx_alarmg
			elseif pks[k_invincibilitytimer] > 0 then
				sfxnum = sfx_alarmi
			end
		else
			if pks[k_growshrinktimer] > 0 then
				sfxnum = sfx_kgrow
			elseif pks[k_invincibilitytimer] > 0 then
				sfxnum = sfx_kinvnc
			end
		end
	end

	if sfxnum ~= sfx_None and not S_SoundPlaying(mobj, sfxnum) then
		S_StartSound(mobj, sfxnum)
	end
	
	stopThis(mobj, sfxnum, sfx_alarmi)
	stopThis(mobj, sfxnum, sfx_alarmg)
	stopThis(mobj, sfxnum, sfx_kinvnc)
	stopThis(mobj, sfxnum, sfx_kgrow)
end

timetravel.P_SkidAndDriftNoises = function(player, mobj)

	local anglediff = 0
	local pks = player.kartstuff
	local linkedItem = mobj.linkedItem
	local linkedItemAngle = linkedItem.angle
	
	if player.pflags & PF_SKIDDOWN then
		anglediff = abs(linkedItemAngle - player.frameangle)
		if leveltime % 6 == 0 then S_StartSound(mobj, sfx_screec) end
	elseif player.speed >= 5<<FRACBITS then
		local playerangle = linkedItemAngle
		
		if player.cmd.forwardmove < 0 then playerangle = $ + ANGLE_180 end
		anglediff = abs(playerangle - R_PointToAngle2(0, 0, player.rmomx, player.rmomy))
	end
	
	if anglediff > ANG10 * 4 then
		if leveltime % 6 == 0 then S_StartSound(mobj, sfx_screec) end
	end

	-- Drift release noise.
	local dsr = K_GetKartDriftSparkValue(player)
	if pks[k_drift] ~= -5 and pks[k_drift] ~= 5 and
		pks[k_driftcharge] >= dsr and P_IsObjectOnGround(linkedItem) then
		S_StartSound(mobj, sfx_s23c)
	end
	
end

-- Eggman Monitor-specific hack to play its pickup sound and effects.
timetravel.eggmanSoundHandler = function(special, toucher)
	local linkedItem = special.linkedItem
	if linkedItem == nil or linkedItem.valid == false then return end
	
	if (special.target == toucher or special.target == toucher.target) and special.threshold > 0 then return end
	if special.health <= 0 or toucher.health <= 0 then return end
	
	local player = toucher.player
	if not (player and player.valid) then return end
	if not P_CanPickupItem(player, 2) then return end

	local poof = P_SpawnMobj(linkedItem.x, linkedItem.y, linkedItem.z, MT_EXPLODE)
	poof.frame = poof.frame | FF_TRANS50
	S_StartSound(poof, special.info.deathsound)
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