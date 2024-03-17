local WAYPOINTS_VERSION = 11

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
local tablePlayer = 1
local tableLaps = 2
local tableStarposts = 3
local tableNextpos = 4
local tablePrevPos = 5

local function sortPositionTable(a, b)
	if a[tableLaps] == b[tableLaps] then
		if a[tableStarposts] == b[tableStarposts] then
			return a[tableNextpos] < b[tableNextpos]
		end

		return a[tableStarposts] > b[tableStarposts]
	end

	return a[tableLaps] > b[tableLaps]
end


local positionTable = {}
local function timeTravelWaypointsProcessing()
	positionTable = {} -- Reset the table for each execution.

	for player in players.iterate do
		if not (player and player.valid) then continue end
		if player.spectator then continue end
		
		local lap = player.laps
		local starpostnum = player.starpostnum
		local prevpos = 0
		local nextpos = 0
		
		local pMo = player.mo
		local pMoX, pMoY, pMoZ = pMo.x, pMo.y, pMo.z
		local pks = player.kartstuff
		local prevWaypointNum, nextWaypointNum = 0, 0
		
		local thisPlayerWaypoints = getWaypointTableToUse(player)
		for _, mo in ipairs(thisPlayerWaypoints[starpostnum]) do
			
			local dist = FixedHypot(FixedHypot(mo.x - pMoX,
								mo.y - pMoY),
								mo.z - pMoZ) >> FRACBITS

			prevpos = $ + dist
			prevWaypointNum = $ + 1
		end
		
		for _, mo in ipairs(thisPlayerWaypoints[starpostnum + 1]) do
			
			local dist = FixedHypot(FixedHypot(mo.x - pMoX,
								mo.y - pMoY),
								mo.z - pMoZ) >> FRACBITS
			

			nextpos = $ + dist
			nextWaypointNum = $ + 1
		end
		
		if prevWaypointNum > 1 then prevpos = $ / prevWaypointNum end
		if nextWaypointNum > 1 then nextpos = $ / nextWaypointNum end
		
		table_insert(positionTable, {player, lap, starpostnum, nextpos, prevpos})
	end
	
	if #positionTable <= 0 then return end -- This should NEVER happen.
	
	table_sort(positionTable, sortPositionTable)
	-- print("----------")
end

local function timeTravelSetPositions()
	for i = 1, #positionTable do
		local player = positionTable[i][tablePlayer]
		if not (player and player.valid) then continue end
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
		pks[k_nextcheck] = positionTable[i][tableNextpos]
		pks[k_prevcheck] = positionTable[i][tablePrevPos]
		
		-- print("#" + i + ": " + player.name + "(" + positionTable[i][2] + ", " + positionTable[i][3] + ", " + positionTable[i][4] + ")")
	end
end

addHook("PlayerThink", function(player)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	local pMo = player.mo
	if player.spectator or (pMo == nil or pMo.valid == false) or 
		not player.timetravelconsts then return end
	
	-- Only the last connected player processes this.
	if timetravel.isLastPlayer(player) then timeTravelWaypointsProcessing() end
	-- Because of K_KartUpdatePosition fuckery, this needs to happen every frame for each player.
	timeTravelSetPositions()
	
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
end)

-- This should ideally load after timetravel.lua to avoid a race condition.
timetravel.waypointsInit = function()
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end

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
end

addHook("NetVars", function(network)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	timetravel.presentWaypoints = network(timetravel.presentWaypoints)
	timetravel.futureWaypoints = network(timetravel.futureWaypoints)
	timetravel.numstarposts = network(timetravel.numstarposts)
	positionTable = network(positionTable)
end)

timetravel.WAYPOINTS_VERSION = WAYPOINTS_VERSION
end