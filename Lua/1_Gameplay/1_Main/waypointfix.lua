local WAYPOINTS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.WAYPOINTS_VERSION == nil or timetravel.WAYPOINTS_VERSION < WAYPOINTS_VERSION then

timetravel.presentWaypoints = {}
timetravel.futureWaypoints = {}
timetravel.numstarposts = 0

local TICRATE = TICRATE
local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT
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

local K_OldKartUpdatePosition = K_KartUpdatePosition

local function K_KartUpdatePositionEX(thisPlayer)
	if not timetravel.isActive then return K_OldKartUpdatePosition(thisPlayer) end
	
	local position = 1
	local oldposition = thisPlayer.timetravelconsts.kartPosition or 0
	local thisPlayerMo = thisPlayer.mo
	local ppcd, pncd, ipcd, incd
	local pmo, imo
	local mo

	if thisPlayer.spectator or not thisPlayerMo then return end
	
	local thisPks, thisPlayerStarpostNum, thisPlayerLaps, thisPlayerExiting = thisPlayer.kartstuff, thisPlayer.starpostnum, thisPlayer.laps, thisPlayer.exiting
	local thisPlayerX, thisPlayerY, thisPlayerZ = thisPlayerMo.x, thisPlayerMo.y, thisPlayerMo.z
	
	for otherPlayer in players.iterate do
		local otherPlayerMo = otherPlayer.mo
		if otherPlayer.spectator or (otherPlayerMo == nil or otherPlayerMo.valid == false) then continue end
		
		local otherPks, otherPlayerStarpostNum, otherPlayerLaps = otherPlayer.kartstuff, otherPlayer.starpostnum, otherPlayer.laps
		local otherPlayerX, otherPlayerY, otherPlayerZ = otherPlayerMo.x, otherPlayerMo.y, otherPlayerMo.z
		
		if gametype == GT_RACE then
			
			if otherPlayerStarpostNum + ((timetravel.numstarposts + 1) * otherPlayerLaps) >
				thisPlayerStarpostNum + ((timetravel.numstarposts + 1) * thisPlayerLaps) then
				
				position = $ + 1
				
			elseif otherPlayerStarpostNum + ((timetravel.numstarposts + 1) * otherPlayerLaps) ==
				thisPlayerStarpostNum + ((timetravel.numstarposts + 1) * thisPlayerLaps) then
				
				ppcd = 0
				pncd = 0
				ipcd = 0
				incd = 0
				
				thisPks[k_nextcheck] = 0
				thisPks[k_prevcheck] = 0
				otherPks[k_nextcheck] = 0
				otherPks[k_prevcheck] = 0
				
				local thisPlayerWaypoints = getWaypointTableToUse(thisPlayer)
				for _, mo in ipairs(thisPlayerWaypoints[thisPlayerStarpostNum]) do
					
					pmo = FixedHypot(FixedHypot(mo.x - thisPlayerX,
										mo.y - thisPlayerY),
										mo.z - thisPlayerZ) >> FRACBITS

					if not mo.movecount or mo.movecount == thisPlayerLaps + 1 then
						thisPks[k_prevcheck] = $ + pmo
						ppcd = $ + 1
					end
				end
				
				for _, mo in ipairs(thisPlayerWaypoints[thisPlayerStarpostNum + 1]) do
					
					pmo = FixedHypot(FixedHypot(mo.x - thisPlayerX,
										mo.y - thisPlayerY),
										mo.z - thisPlayerZ) >> FRACBITS
					
					if not mo.movecount or mo.movecount == thisPlayerLaps + 1 then
						thisPks[k_nextcheck] = $ + pmo
						pncd = $ + 1
					end
				end
				
				local otherPlayerWaypoints = getWaypointTableToUse(otherPlayer)
				for _, mo in ipairs(otherPlayerWaypoints[otherPlayerStarpostNum]) do
				
					imo = FixedHypot(FixedHypot(mo.x - otherPlayerX,
										mo.y - otherPlayerY),
										mo.z - otherPlayerZ) >> FRACBITS
							
					if not mo.movecount or mo.movecount == otherPlayerLaps + 1 then
						otherPks[k_prevcheck] = $ + imo
						ipcd = $ + 1
					end
				end
				
				for _, mo in ipairs(otherPlayerWaypoints[otherPlayerStarpostNum + 1]) do
				
					imo = FixedHypot(FixedHypot(mo.x - otherPlayerX,
										mo.y - otherPlayerY),
										mo.z - otherPlayerZ) >> FRACBITS
				
					if not mo.movecount or mo.movecount == otherPlayerLaps + 1 then
						otherPks[k_nextcheck] = $ + imo
						incd = $ + 1
					end
				end

				if ppcd > 1 then thisPks[k_prevcheck]  = $ / ppcd end
				if pncd > 1 then thisPks[k_nextcheck]  = $ / pncd end
				if ipcd > 1 then otherPks[k_prevcheck] = $ / ipcd end
				if incd > 1 then otherPks[k_nextcheck] = $ / incd end

				if otherPks[k_nextcheck] > 0 or thisPks[k_nextcheck] > 0 and not thisPlayerExiting then
					if otherPks[k_nextcheck] - otherPks[k_prevcheck] <
						thisPks[k_nextcheck] - thisPks[k_prevcheck] then
						position = $ + 1
					end	
				elseif not thisPlayerExiting and otherPks[k_prevcheck] > thisPks[k_prevcheck] then
						position = $ + 1
				elseif otherPlayer.starposttime < thisPlayer.starposttime then
						position = $ + 1
				end
				
			end
		elseif gametype == GT_MATCH then
			if thisPlayerExiting then -- End of match standings 
				if otherPlayer.marescore > thisPlayer.marescore then
					position = $ + 1
				end
			else
				if otherPks[k_bumper] == thisPks[k_bumper] and otherPlayer.marescore > thisPlayer.marescore then
					position = $ + 1
				elseif otherPks[k_bumper] > thisPks[k_bumper] then
					position = $ + 1
				end
			end
			
		end
	end
	
	if leveltime < starttime or oldposition == 0 then
		oldposition = position
	end
	
	if oldposition ~= position then -- Changed places?
		thisPlayer.timetravelconsts.kartPositionDelay = 10 -- Position number growth
	end

	thisPlayer.timetravelconsts.kartPosition = position
	thisPks[k_position] = position
	
end

_G["K_KartUpdatePosition"] = K_KartUpdatePositionEX

addHook("PlayerThink", function(player)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	local pMo = player.mo
	if player.spectator or (pMo == nil or pMo.valid == false) or 
		not player.timetravelconsts then return end
	
	K_KartUpdatePositionEX(player)
	local pks = player.kartstuff
	
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