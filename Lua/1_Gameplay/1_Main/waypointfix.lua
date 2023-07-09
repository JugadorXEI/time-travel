local WAYPOINTS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.WAYPOINTS_VERSION == nil or timetravel.WAYPOINTS_VERSION < WAYPOINTS_VERSION then

timetravel.presentWaypoints = {}
timetravel.futureWaypoints = {}
timetravel.numstarposts = 0

local TICRATE = TICRATE
local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT
local INT32_MAX = INT32_MAX
local MTF_OBJECTSPECIAL = MTF_OBJECTSPECIAL
local MT_BOSS3WAYPOINT = MT_BOSS3WAYPOINT
local DOOMEDNUM_BOSS3WAYPOINT = 292
local DOOMEDNUM_STARPOST = 502
local k_positiondelay = k_positiondelay
local k_oldposition = k_oldposition
local k_position = k_position
local k_nextcheck = k_nextcheck
local k_prevcheck = k_prevcheck
local k_tauntvoices = k_tauntvoices
local k_voices = k_voices
local starttime = 6*TICRATE + 3*TICRATE/4

local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local FixedHypot = FixedHypot
local K_PlayOvertakeSound = K_PlayOvertakeSound

local function getWaypointTableToUse(player)
	local mo = player.mo
	if mo.timetravel == nil then return timetravel.presentWaypoints end
	
	if mo.timetravel.isTimeWarped then
		return timetravel.futureWaypoints
	end
	
	return timetravel.presentWaypoints
end

--[[
	Waypoints v2
	Instead of comparing player positions per-player, we instead do this once.
	We first process the players' waypoint positions (next and prev).
	We then gather all necesary data first from each player (lap, startpost num, next pos. to waypoint)
	We then sort this data by lap, startpost and position.
	Finally we assign the final player positions.
]]
local function sortPositionTable(a, b)
		return a[2] < b[2] or a[3] < b[3] or a[4] < b[4]
	end

local function timeTravelWaypointsProcessing()
	local positionTable = {}
	
	for player in players.iterate do
		if not (player and player.valid) then continue end
		if player.spectator then continue end
		
		local lap = player.laps
		local starpostnum = player.starpostnum
		local nextpos = INT32_MAX
		
		local pMo = player.mo
		local pMoX, pMoY, pMoZ = pMo.x, pMo.y, pMo.z
		local pks = player.kartstuff
		local prevWaypointNum, nextWaypointNum = 0, 0
		
		pks[k_prevcheck] = 0
		pks[k_nextcheck] = 0
		
		local thisPlayerWaypoints = getWaypointTableToUse(player)
		for _, mo in ipairs(thisPlayerWaypoints[starpostnum]) do
			
			local dist = FixedHypot(FixedHypot(mo.x - pMoX,
								mo.y - pMoY),
								mo.z - pMoZ) >> FRACBITS

			pks[k_prevcheck] = $ + dist
			prevWaypointNum = $ + 1
		end
		
		for _, mo in ipairs(thisPlayerWaypoints[starpostnum + 1]) do
			
			local dist = FixedHypot(FixedHypot(mo.x - pMoX,
								mo.y - pMoY),
								mo.z - pMoZ) >> FRACBITS
			

			pks[k_nextcheck] = $ + dist
			nextWaypointNum = $ + 1
		end
		
		if prevWaypointNum > 1 then pks[k_prevcheck] = $ / prevWaypointNum end
		if nextWaypointNum > 1 then pks[k_nextcheck] = $ / nextWaypointNum end
		
		nextpos = pks[k_prevcheck]
		
		table_insert(positionTable, {player, lap, starpostnum, nextpos})
	end
	
	if #positionTable <= 0 then return end -- This should NEVER happen.
	
	table_sort(positionTable, sortPositionTable)
	
	for i = 1, #positionTable do
		local player = positionTable[i][1]
		local pks = player.kartstuff
		
		local oldPosition = player.timetravelconsts.kartPosition
		local position = i
		
		if leveltime < starttime or oldPosition == 0 then
			oldPosition = position
		end
		
		if oldPosition ~= position then
			player.timetravelconsts.kartPositionDelay = 10 -- Position number growth
		end
		
		player.timetravelconsts.kartPosition = position
		pks[k_position] = position
		
		-- print("#" + i + ": " + player.name)
	end
	
	-- print("----------")
end

addHook("PlayerThink", function(player)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	local pMo = player.mo
	if player.spectator or (pMo == nil or pMo.valid == false) or 
		not player.timetravelconsts then return end
	
	timeTravelWaypointsProcessing()
	
	local pks = player.kartstuff
	player.timetravelconsts.kartPosition = $ or 0
	
	if not player.exiting then
	
		if pks[k_oldposition] < player.timetravelconsts.kartPosition then
		
			pks[k_oldposition] = player.timetravelconsts.kartPosition
			pks[k_voices] = 4 * TICRATE
			
			if pks[k_tauntvoices] < 4 * TICRATE then
				pks[k_tauntvoices] = 4 * TICRATE
			end

		elseif pks[k_oldposition] > player.timetravelconsts.kartPosition then
		
			K_PlayOvertakeSound(player.mo)
			pks[k_oldposition] = player.timetravelconsts.kartPosition
			
		end
	end

	
	if player.timetravelconsts.kartPositionDelay then
		player.timetravelconsts.kartPositionDelay = $ - 1
	end
	pks[k_positiondelay] = player.timetravelconsts.kartPositionDelay or 0

	timetravel.JawzTargettingLogic(player)

	--[[
	if player == consoleplayer then
		print(player.name + "'s k_positiondelay: " + player.kartstuff[k_positiondelay])
		print(player.name + "'s k_position: " + player.kartstuff[k_position])
		print(player.name + "'s k_nextcheck: " + player.kartstuff[k_nextcheck])
		print(player.name + "'s k_prevcheck: " + player.kartstuff[k_prevcheck])
	end
	]]
end)

-- This should ideally load after timetravel.lua to avoid a race condition.
addHook("MapLoad", function(mapnum)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	if not timetravel.isActive then return end
	-- print("waypoints setup...")

	timetravel.presentWaypoints = {}
	timetravel.futureWaypoints = {}
	timetravel.numstarposts = 0
	local starpostsFound = {}
	
	for mapthing in mapthings.iterate do
		if mapthing.type == DOOMEDNUM_BOSS3WAYPOINT then
			local tableToUse
			if mapthing.options & MTF_OBJECTSPECIAL then tableToUse = timetravel.futureWaypoints
			else tableToUse = timetravel.presentWaypoints
			end
			
			if tableToUse[mapthing.angle] == nil then
				tableToUse[mapthing.angle] = {}
			end
			
			table_insert(tableToUse[mapthing.angle], mapthing.mobj)
		elseif mapthing.type == DOOMEDNUM_STARPOST then
			starpostsFound[(mapthing.angle / 360) + 1] = true
		end
	end
	
	timetravel.numstarposts = #starpostsFound
	
	--[[
	print("Present waypoints found: " + #timetravel.presentWaypoints)
	print("Future waypoints found: " + #timetravel.futureWaypoints)
	print("Number of starposts: " + timetravel.numstarposts)
	]]
end)

addHook("NetVars", function(network)
	timetravel.presentWaypoints = network(timetravel.presentWaypoints)
	timetravel.futureWaypoints = network(timetravel.futureWaypoints)
	timetravel.numstarposts = network(timetravel.numstarposts)
end)

timetravel.WAYPOINTS_VERSION = WAYPOINTS_VERSION
end