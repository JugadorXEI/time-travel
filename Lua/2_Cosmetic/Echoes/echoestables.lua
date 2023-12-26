--[[
GPLv2 notice: Lua ports of various SFX-related parts of objects.
Made 15/01/2023 (dd/mm/aaaa)
]]

local ECHOES_TABLES_VERSION = 10

-- avoid redefiniton on updates
if timetravel.ECHOES_TABLES_VERSION == nil or timetravel.ECHOES_TABLES_VERSION < ECHOES_TABLES_VERSION then

local FRACBITS = FRACBITS
local TICRATE = TICRATE

local sfx_s3k3a = sfx_s3k3a
local sfx_s3k41 = sfx_s3k41
local sfx_s254 = sfx_s254
local sfx_cdpcm9 = sfx_cdpcm9
local sfx_cdfm01 = sfx_cdfm01
local sfx_cdfm17 = sfx_cdfm17

local S_SSMINE_AIR1 = S_SSMINE_AIR1
local S_SSMINE_AIR2 = S_SSMINE_AIR2
local S_SSMINE_DEPLOY8 = S_SSMINE_DEPLOY8
local S_SSMINE_DEPLOY13 = S_SSMINE_DEPLOY13
local S_SSMINE1 = S_SSMINE1
local S_SSMINE4 = S_SSMINE4

local abs = abs
local FixedMul = FixedMul
local FixedHypot = FixedHypot
local P_RemoveMobj = P_RemoveMobj
local S_StartSound = S_StartSound
local S_SoundPlaying = S_SoundPlaying
local P_IsObjectOnGround = P_IsObjectOnGround
local R_PointToAngle2 = R_PointToAngle2
local P_SpawnMobj = P_SpawnMobj
local searchBlockmap = searchBlockmap

local playerHeight = mobjinfo[MT_PLAYER].height

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
	[MT_SPB] = true,
}

timetravel.optimizedExplosion = function(mobj)
	-- Absolutely remove anything that's going up or down.
	local momz = abs(mobj.momz)
	if momz > 2<<FRACBITS then
		P_RemoveMobj(mobj)
		return true
	end
	
	mobj.height = playerHeight * 4
	
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
	local linkedItem = mobj.linkedItem
	
	local soundToReturn = linkedItem.info.activesound
	if linkedItem.momx > 0 or linkedItem.momy > 0 or linkedItem.momz > 0 then
		soundToReturn = linkedItem.info.seesound
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
	local linkedItem = mobj.linkedItem
	if P_IsObjectOnGround(linkedItem) and linkedItem.health > 1 then
		S_StartSound(mobj, linkedItem.info.activesound)
	end
end

local function beep(mobj)
	if leveltime % 35 == 0 then
		S_StartSound(mobj, mobj.linkedItem.info.activesound)
	end
end

timetravel.echoIdleSounds = {
	[MT_PLAYER] = function(mobj)
		if not (mobj and mobj.valid and mobj.timetravel) then return end
		local player = mobj.linkedItem.player
		if not player then return end
		
		if not timetravel.canDisplayPlayerHearThis(mobj.linkedItem) then return end
		
		-- Engine sounds
		timetravel.K_UpdateEngineSoundsEX(player, player.cmd)
		
		-- Drift and skid noises
		timetravel.P_SkidAndDriftNoises(player, mobj)
			
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
		local linkedItem = mobj.linkedItem
		local linkedItemState = linkedItem.state
		
		if P_IsObjectOnGround(linkedItem) and linkedItem.extravalue1 <= 0 and
			(linkedItemState == S_SSMINE_AIR1 or linkedItemState == S_SSMINE_AIR2) then
				S_StartSound(mobj, linkedItem.info.activesound)
		end
		
		local explodedist = FixedMul(linkedItem.info.painchance, mapobjectscale)
		if linkedItemState == S_SSMINE_DEPLOY8 then
			explodedist = (3*$)/2 
		end
		
		if (linkedItemState >= S_SSMINE1 and linkedItemState <= S_SSMINE4) or
			(linkedItemState >= S_SSMINE_DEPLOY8 and linkedItemState <= S_SSMINE_DEPLOY13) then
			beep(mobj)
			searchBlockmap("objects", function(refmobj, foundmobj)
				if FixedHypot(FixedHypot(refmobj.x - foundmobj.x, refmobj.y - foundmobj.y),
					refmobj.z - foundmobj.z) > explodedist  then return nil end -- In radius?
				
				if not foundmobj.timetravel then return nil end
				if foundmobj.type ~= MT_PLAYER then return end
				-- timetravel.teleport(foundmobj) -- This was actually a stupid idea, wasn't it...?
				linkedItem.state = linkedItem.info.deathstate -- Blow the mine up.
				
				-- Incoming explosion...
				P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_MINEEXPLOSIONSOUND)
				K_SpawnMineExplosion(mobj)
			end, mobj, mobj.x - explodedist, mobj.x + explodedist, mobj.y - explodedist, mobj.y + explodedist)
		end
	end,
	[MT_BRAKEDRIFT] = function(mobj)
		if not S_SoundPlaying(mobj, sfx_cdfm17) then S_StartSound(mobj, sfx_cdfm17) end
	end,
	[MT_SIGN] = function(mobj)
		local linkedItem = mobj.linkedItem
		local attackSound = linkedItem.info.attacksound
		local seeSound = linkedItem.info.seesound
		
		if linkedItem.z <= linkedItem.movefactor then
			if attackSound then S_StartSound(mobj, attackSound) end
		else
			if abs(linkedItem.z - linkedItem.movefactor) <= (512 * linkedItem.scale) and not linkedItem.cvmem then
				if seeSound then S_StartSound(mobj, seeSound) end
				linkedItem.cvmem = 1
			end
		end
	end,
	[MT_FZEROBOOM] = function(mobj)
		local attacksound = mobj.linkedItem.info.attacksound
		if not S_SoundPlaying(mobj, attacksound) then
			S_StartSound(mobj, attacksound)
		end
	end,
}

timetravel.ECHOES_TABLES_VERSION = ECHOES_TABLES_VERSION

end