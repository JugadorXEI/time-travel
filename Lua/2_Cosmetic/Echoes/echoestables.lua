local ECHOES_TABLES_VERSION = 1

-- avoid redefiniton on updates
if timetravel.ECHOES_TABLES_VERSION == nil or timetravel.ECHOES_TABLES_VERSION < ECHOES_TABLES_VERSION then

timetravel.typesToEcho = {
	-- Vanilla:
	"MT_PLAYER",
	"MT_ORBINAUT",
	"MT_ORBINAUT_SHIELD",
	"MT_JAWZ",
	"MT_JAWZ_SHIELD",
	"MT_JAWZ_DUD",
	"MT_BANANA",
	"MT_BANANA_SHIELD",
	"MT_SPB",
	"MT_SINK", -- Sinks get special behaviour.
	"MT_SINK_SHIELD",
	"MT_ROCKETSNEAKER",
	"MT_BALLHOG",
	"MT_EGGMANITEM",
	"MT_EGGMANITEM_SHIELD",
	"MT_SSMINE",
	"MT_SSMINE_SHIELD",
	"MT_THUNDERSHIELD",
	"MT_SPBEXPLOSION",
	"MT_MINEEXPLOSION",
	-- Vanilla Effects:
	"MT_THOK", -- mostly for generic effects...
	"MT_OVERLAY", -- same.
	"MT_INSTASHIELDA",
	"MT_INSTASHIELDB",
	"MT_FIREDITEM",
	"MT_FASTLINE",
	"MT_BOOSTFLAME",
	"MT_SNEAKERTRAIL",
	"MT_SPARKLETRAIL",
	"MT_INVULNFLASH",
	"MT_WIPEOUTTRAIL",
	"MT_DRIFTSPARK",
	"MT_BRAKEDRIFT",
	"MT_PLAYERRETICULE",
	"MT_PLAYERWANTED",
	"MT_PLAYERARROW",
	"MT_SIGN",
	"MT_FZEROBOOM", -- 34
	-- MOD STUFF starts here.
	-- Time Travel (this mod)
	"MT_PLAYERRETICULE_TT",
	-- XItem Sampler Pack
	"MT_DKRRETICLEFRAME",
	"MT_DKRRETICLEGLASS",
	-- "MT_DKRMAGNETELECTRICITY",
	"MT_PEEPEEJAR",
	-- "MT_PEEPEEDRIP",
	"MT_KOURABLUE",
	"MT_LAUNCHERBOMBHEI",
	"MT_PICKEL_AXE",
	-- "MT_PICKEL_AXE_DEAD",
	-- "MT_SMK_PIPE", -- This is technically not a custom mobj but it is reused for an item.
	-- Checker Wrecker
	"MT_GHZBALL",
	"MT_GHZBALLLINK",
	-- "MT_GHZBALLCHUNK",
	-- TSR -- Unintentionally skipping the skimboost trail since every level would hit the mobj limit because of it.
	"MT_TSR_RIVAL",
	"MT_TSR_SKIMBINDICATOR",
	"MT_TSR_SKIMB",
	"MT_TSR_SLINGSHOTLEVEL",
	"MT_TSR_MARKER",
	"MT_TSR_HIGHLIGHTITEM",
	-- "MT_TSR_ULTIMATESPARK",
	-- Juicebox - Dash Rings are not reflected in this system, see juiceinterop.lua
	"MT_TECHFLASH",
	"MT_TECHBUTTON",
	"MT_TECHLOCK",
	"MT_BLIBTRAIL", -- Boostlib
	"MT_HAHALOUD", -- Hornmod
	-- Acrobatics
	"MT_BURSTAURA",
	"MT_STORELINE",
	"MT_STORECHARGE",
	"MT_AUGSPARKLE",
	-- Open Tricks (+ DLC)
	"MT_OTRICKSPARK",
	"MT_OTRICKFIRE",
	"MT_OTRICKWHEEL",
	"MT_OTRICKSMOKE",
	"MT_TRXOMO",
	-- Drift Nitro
	"MT_DUPESNEAKERTRAIL",
}

timetravel.additionalHittables = {
	[MT_SPBEXPLOSION] = true,
	[MT_MINEEXPLOSION] = true,
}

timetravel.optimizedExplosion = function(mobj)
	-- Absolutely remove anything that's going up or down.
	local momz = abs(mobj.momz)
	if momz > 8<<FRACBITS then
		P_RemoveMobj(mobj)
		return true
	end
	
	mobj.height = mobjinfo[MT_PLAYER].height * 4
	
	return false
end

timetravel.specialBehaviourFuncs = {
	[MT_SPBEXPLOSION] = timetravel.optimizedExplosion,
	[MT_MINEEXPLOSION] = timetravel.optimizedExplosion,
}

--[[
-- this system doesn't work with these mobjs:
MT_ITEMCLASH
MT_BUMP
MT_BOOSTSMOKE ??? why do you give a reference in MT_BOOSTFLAME and not this one???
MT_AIZDRIFTSTRAT ??? why do you give a reference in MT_SNEAKERTRAIL and not this one???
MT_DRIFTDUST ??? why do you give a reference in MT_BRAKEDRIFT and not this one???
]]

local function bananaSounds_Spawn(mobj)
	local soundToReturn = mobj.linkedItem.info.activesound
	if mobj.linkedItem.momx > 0 or mobj.linkedItem.momy > 0 or mobj.linkedItem.momz > 0 then
		soundToReturn = mobj.linkedItem.info.seesound
	end
	
	return soundToReturn
end

timetravel.echoSpawnSounds = {
	[MT_ROCKETSNEAKER] = sfx_s3k3a,
	[MT_ORBINAUT_SHIELD] = sfx_s3k3a,
	[MT_JAWZ_SHIELD] = sfx_s3k3a,
	[MT_THUNDERSHIELD] = sfx_s3k41,
	[MT_BANANA_SHIELD] = sfx_s254,
	[MT_EGGMANITEM_SHIELD] = sfx_s254,
	[MT_BANANA] = bananaSounds_Spawn,
	[MT_EGGMANITEM] = bananaSounds_Spawn,
	[MT_SSMINE_SHIELD] = sfx_s254,
	[MT_SINK_SHIELD] = sfx_s254,
	[MT_INSTASHIELDA] = sfx_cdpcm9,
	[MT_BOOSTFLAME] = sfx_cdfm01
}

local function jawzSoundz(mobj)
	if (leveltime % TICRATE) == 0 then S_StartSound(mobj, mobj.linkedItem.info.activesound) end
end

local function bananaSounds(mobj)
	if P_IsObjectOnGround(mobj.linkedItem) and mobj.linkedItem.health > 1 then
		S_StartSound(mobj, mobj.linkedItem.info.activesound)
	end
end

local function beep(mobj)
	if leveltime % 35 == 0 then
		S_StartSound(mobj, mobj.linkedItem.info.activesound)
	end
end

timetravel.echoIdleSounds = {
	[MT_PLAYER] = function(mobj)
		if not mobj and not mobj.valid and not mobj.timetravel then return end
		local linkedItem = mobj.linkedItem
		local player = linkedItem.player
		if not player then return end
		
		timetravel.K_UpdateEngineSoundsEX(player, player.cmd)
		
		-- Regular dorifto noise.
		local anglediff = 0
		if (player.pflags & PF_SKIDDOWN) then
			anglediff = abs(linkedItem.angle - player.frameangle)
			if leveltime % 6 == 0 then S_StartSound(mobj, sfx_screec) end
		elseif player.speed >= 5<<FRACBITS then
			local playerangle = linkedItem.angle 
			
			if player.cmd.forwardmove < 0 then playerangle = $ + ANGLE_180 end
			anglediff = abs(playerangle - R_PointToAngle2(0, 0, player.rmomx, player.rmomy))
		end
		
		if anglediff > ANG10 * 4 then
			if leveltime % 6 == 0 then S_StartSound(mobj, sfx_screec) end
		end
		
		-- print((anglediff/ANG1) + " ... " + (anglediff > ANG10*4))

		-- Drift release noise.
		local dsr = K_GetKartDriftSparkValue(player)
		if player.kartstuff[k_drift] ~= -5 and player.kartstuff[k_drift] ~= 5 and
			player.kartstuff[k_driftcharge] >= dsr and P_IsObjectOnGround(mobj.linkedItem) then
			S_StartSound(mobj, sfx_s23c)
		end
		
		-- Invincibility & Grow
		timetravel.K_UpdateInvincibilitySoundsEX(player, mobj)
		
	end,
	[MT_ORBINAUT] = function(mobj)
		if leveltime % 6 == 0 then S_StartSound(mobj, mobj.linkedItem.info.activesound) end
	end,
	[MT_JAWZ] = jawzSoundz,
	[MT_JAWZ_DUD] = jawzSoundz,
	[MT_BANANA] = bananaSounds,
	[MT_EGGMANITEM] = bananaSounds,
	[MT_SINK] = function(mobj)
		beep(mobj)
	
		if P_IsObjectOnGround(mobj.linkedItem) then
			S_StartSound(mobj, mobj.linkedItem.info.deathsound)
		end
	end,
	[MT_SSMINE_SHIELD] = function(mobj)
		if P_IsObjectOnGround(mobj.linkedItem) and mobj.linkedItem.extravalue1 <= 0 and
			(mobj.linkedItem.state == S_SSMINE_AIR1 or mobj.linkedItem.state == S_SSMINE_AIR2) then
				S_StartSound(mobj, mobj.linkedItem.info.activesound)
		end
		
		local explodedist = FixedMul(mobj.linkedItem.info.painchance, mapobjectscale)
		if mobj.linkedItem.state == S_SSMINE_DEPLOY8 then
			explodedist = (3*$)/2 
		end
		
		if (mobj.linkedItem.state >= S_SSMINE1 and mobj.linkedItem.state <= S_SSMINE4) or
			(mobj.linkedItem.state >= S_SSMINE_DEPLOY8 and mobj.linkedItem.state <= S_SSMINE_DEPLOY13) then
			beep(mobj)
			searchBlockmap("objects", function(refmobj, foundmobj)
				if FixedHypot(FixedHypot(refmobj.x - foundmobj.x, refmobj.y - foundmobj.y),
					refmobj.z - foundmobj.z) > explodedist  then return nil end -- In radius?
				
				if not foundmobj.timetravel then return nil end
				if foundmobj.type ~= MT_PLAYER then return end
				timetravel.teleport(foundmobj)
				
				-- Incoming explosion...
				P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_MINEEXPLOSIONSOUND)
				
			end, mobj, mobj.x - explodedist, mobj.x + explodedist, mobj.y - explodedist, mobj.y + explodedist)
		end
	end,
	[MT_BRAKEDRIFT] = function(mobj)
		if not S_SoundPlaying(mobj, sfx_cdfm17) then S_StartSound(mobj, sfx_cdfm17) end
	end,
	[MT_SIGN] = function(mobj)
		if mobj.linkedItem.z <= mobj.linkedItem.movefactor then
			if mobj.linkedItem.info.attacksound then S_StartSound(mobj, mobj.linkedItem.info.attacksound) end
		else
			if abs(mobj.linkedItem.z - mobj.linkedItem.movefactor) <= (512 * mobj.linkedItem.scale) and not mobj.linkedItem.cvmem then
				if mobj.linkedItem.info.seesound then S_StartSound(mobj, mobj.linkedItem.info.seesound) end
				mobj.linkedItem.cvmem = 1
			end
		end
	end,
	[MT_FZEROBOOM] = function(mobj)
		if not S_SoundPlaying(mobj, mobj.linkedItem.info.attacksound) then
			S_StartSound(mobj, mobj.linkedItem.info.attacksound)
		end
	end,
}

timetravel.ECHOES_TABLES_VERSION = ECHOES_TABLES_VERSION

end