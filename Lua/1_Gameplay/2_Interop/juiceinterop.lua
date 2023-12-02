local JUICEINTEROP_VERSION = 10

-- avoid redefiniton on updates
if timetravel.JUICEINTEROP_VERSION == nil or timetravel.JUICEINTEROP_VERSION < JUICEINTEROP_VERSION then

local MF2_DONTDRAW = MF2_DONTDRAW
local ANGLE_90 = ANGLE_90

local hookedYet = false

local jb_manta_size = {value = 62500}
local jb_manta_sizescale = {value = 8192}

local function juiceboxInit()
	if timetravel.JUICEINTEROP_VERSION > JUICEINTEROP_VERSION then return end
	if not timetravel.isActive then return end
	if hookedYet then return end
	if JUICEBOX == nil then return end
	
	addHook("MobjThinker", function(oldGate)
		if timetravel.JUICEINTEROP_VERSION > JUICEINTEROP_VERSION then return end
		if not timetravel.isActive then return end
		if oldGate == nil or not oldGate.valid then return end
		if oldGate.hasClone then return end
		
		local player = oldGate.owner
		if player == nil then return end
		
		-- Creates another manta ring, preserves gate id.
		local xOffset, yOffset = timetravel.determineTimeWarpPosition(player.mo)
		
		local newGate = P_SpawnMobj(oldGate.x + xOffset, oldGate.y + yOffset, oldGate.z, MT_MANTARING)
		newGate.owner = player
		newGate.color = player.skincolor
		newGate.ownercolor = player.skincolor
		newGate.ownerspeed = player.kartspeed
		newGate.ownerweight = min(player.kartweight, JUICEBOX_weightadjust)
		newGate.ownerlaps = player.laps
		newGate.gateid = oldGate.gateid
		if player == consoleplayer and (not splitscreen) then newGate.flags2 = $|MF2_DONTDRAW else newGate.flags2 = $&(~MF2_DONTDRAW) end
		newGate.scale = FixedMul(player.mo.scale, jb_manta_size.value + jb_manta_sizescale.value * newGate.ownerweight)
		newGate.angle = R_PointToAngle2(0, 0, player.mo.momx, player.mo.momy) + ANGLE_90
		
		oldGate.hasClone = true
		newGate.hasClone = true

	end, MT_MANTARING)
	hookedYet = true
end

addHook("MapLoad", juiceboxInit)
addHook("NetVars", juiceboxInit)

timetravel.JUICEINTEROP_VERSION = JUICEINTEROP_VERSION

end