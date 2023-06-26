local WAYPOINTS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.WAYPOINTS_VERSION == nil or timetravel.WAYPOINTS_VERSION < WAYPOINTS_VERSION then

local starttime = 6*TICRATE + 3*TICRATE/4

timetravel.presentWaypoints = {}
timetravel.futureWaypoints = {}
timetravel.numstarposts = 0

local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT

local MTF_OBJECTSPECIAL = MTF_OBJECTSPECIAL
local MT_BOSS3WAYPOINT = MT_BOSS3WAYPOINT

local DOOMEDNUM_BOSS3WAYPOINT = 292
local DOOMEDNUM_STARPOST = 502

local function getWaypointTableToUse(player)
	local mo = player.mo
	if mo.timetravel == nil then return timetravel.presentWaypoints end
	
	if mo.timetravel.isTimeWarped then
		return timetravel.futureWaypoints
	end
	
	return timetravel.presentWaypoints
end

local K_OldKartUpdatePosition = _G["K_KartUpdatePosition"]

local function K_KartUpdatePositionEX(thisPlayer)
	if not timetravel.isActive then return K_OldKartUpdatePosition(thisPlayer) end
	
	local position = 1
	local oldposition = thisPlayer.timetravelconsts.kartPosition or 0
	local ppcd, pncd, ipcd, incd
	local pmo, imo
	local mo

	if thisPlayer.spectator or not thisPlayer.mo then return end
	
	for otherPlayer in players.iterate do
		if otherPlayer.spectator or (otherPlayer.mo == nil or otherPlayer.mo.valid == false) then continue end
		
		if gametype == GT_RACE then
			if otherPlayer.starpostnum + ((timetravel.numstarposts + 1) * otherPlayer.laps) >
				thisPlayer.starpostnum + ((timetravel.numstarposts + 1) * thisPlayer.laps) then
				
				position = $ + 1
				
			elseif otherPlayer.starpostnum + ((timetravel.numstarposts + 1) * otherPlayer.laps) ==
				thisPlayer.starpostnum + ((timetravel.numstarposts + 1) * thisPlayer.laps) then
				
				ppcd = 0
				pncd = 0
				ipcd = 0
				incd = 0
				
				thisPlayer.kartstuff[k_nextcheck] = 0
				thisPlayer.kartstuff[k_prevcheck] = 0
				otherPlayer.kartstuff[k_nextcheck] = 0
				otherPlayer.kartstuff[k_prevcheck] = 0
				
				--[[
					if thisPlayer == consoleplayer then					
						print("Waypoint num: " + mo.health)
						print("Player's starpost num: " + thisPlayer.starpostnum)
						print("Checkpoint movecount: " + mo.movecount)
						print("Player's laps (+1): " + (thisPlayer.laps + 1))
					end
				]]
				
				local thisPlayerWaypoints = getWaypointTableToUse(thisPlayer)
				for _, mo in ipairs(thisPlayerWaypoints[thisPlayer.starpostnum]) do
					
					pmo = FixedHypot(FixedHypot(mo.x - thisPlayer.mo.x,
										mo.y - thisPlayer.mo.y),
										mo.z - thisPlayer.mo.z) >> FRACBITS

					if not mo.movecount or mo.movecount == thisPlayer.laps + 1 then
						thisPlayer.kartstuff[k_prevcheck] = $ + pmo
						ppcd = $ + 1
					end
					

				end
				
				for _, mo in ipairs(thisPlayerWaypoints[thisPlayer.starpostnum + 1]) do
					
					pmo = FixedHypot(FixedHypot(mo.x - thisPlayer.mo.x,
										mo.y - thisPlayer.mo.y),
										mo.z - thisPlayer.mo.z) >> FRACBITS
					
					if not mo.movecount or mo.movecount == thisPlayer.laps + 1 then
						thisPlayer.kartstuff[k_nextcheck] = $ + pmo
						pncd = $ + 1
					end
				end
				
				local otherPlayerWaypoints = getWaypointTableToUse(otherPlayer)
				for _, mo in ipairs(otherPlayerWaypoints[otherPlayer.starpostnum]) do
				
					imo = FixedHypot(FixedHypot(mo.x - otherPlayer.mo.x,
										mo.y - otherPlayer.mo.y),
										mo.z - otherPlayer.mo.z) >> FRACBITS
							
					if not mo.movecount or mo.movecount == otherPlayer.laps + 1 then
						otherPlayer.kartstuff[k_prevcheck] = $ + imo
						ipcd = $ + 1
					end
				end
				
				for _, mo in ipairs(otherPlayerWaypoints[otherPlayer.starpostnum + 1]) do
				
					imo = FixedHypot(FixedHypot(mo.x - otherPlayer.mo.x,
										mo.y - otherPlayer.mo.y),
										mo.z - otherPlayer.mo.z) >> FRACBITS
				
					if not mo.movecount or mo.movecount == otherPlayer.laps + 1 then
						otherPlayer.kartstuff[k_nextcheck] = $ + imo
						incd = $ + 1
					end
				end

				if ppcd > 1 then thisPlayer.kartstuff[k_prevcheck]  = $ / ppcd end
				if pncd > 1 then thisPlayer.kartstuff[k_nextcheck]  = $ / pncd end
				if ipcd > 1 then otherPlayer.kartstuff[k_prevcheck] = $ / ipcd end
				if incd > 1 then otherPlayer.kartstuff[k_nextcheck] = $ / incd end

				if otherPlayer.kartstuff[k_nextcheck] > 0 or thisPlayer.kartstuff[k_nextcheck] > 0 and not thisPlayer.exiting then
					if otherPlayer.kartstuff[k_nextcheck] - otherPlayer.kartstuff[k_prevcheck] <
						thisPlayer.kartstuff[k_nextcheck] - thisPlayer.kartstuff[k_prevcheck] then
						position = $ + 1
					end	
				elseif not thisPlayer.exiting and otherPlayer.kartstuff[k_prevcheck] > thisPlayer.kartstuff[k_prevcheck] then
						position = $ + 1
				elseif otherPlayer.starposttime < thisPlayer.starposttime then
						position = $ + 1
				end
				
			end
		elseif gametype == GT_MATCH then
			if thisPlayer.exiting then -- End of match standings 
				if otherPlayer.marescore > thisPlayer.marescore then
					position = $ + 1
				end
			else
				if otherPlayer.kartstuff[k_bumper] == thisPlayer.kartstuff[k_bumper] and otherPlayer.marescore > thisPlayer.marescore then
					position = $ + 1
				elseif otherPlayer.kartstuff[k_bumper] > thisPlayer.kartstuff[k_bumper] then
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
	thisPlayer.kartstuff[k_position] = position
	
end

_G["K_KartUpdatePosition"] = K_KartUpdatePositionEX

addHook("PlayerThink", function(player)
	if timetravel.WAYPOINTS_VERSION > WAYPOINTS_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	if player.spectator or (player.mo == nil or player.mo.valid == false) or 
		not player.timetravelconsts then return end
	
	K_KartUpdatePositionEX(player)
	
	if not player.exiting then
	
		if player.kartstuff[k_oldposition] < player.timetravelconsts.kartPosition then
		
			player.kartstuff[k_oldposition] = player.timetravelconsts.kartPosition
			player.kartstuff[k_voices] = 4 * TICRATE
			
			if player.kartstuff[k_tauntvoices] < 4 * TICRATE then
				player.kartstuff[k_tauntvoices] = 4 * TICRATE
			end

		elseif player.kartstuff[k_oldposition] > player.timetravelconsts.kartPosition then
		
			K_PlayOvertakeSound(player.mo)
			player.kartstuff[k_oldposition] = player.timetravelconsts.kartPosition
			
		end
	end

	
	if player.timetravelconsts.kartPositionDelay then
		player.timetravelconsts.kartPositionDelay = $ - 1
	end
	player.kartstuff[k_positiondelay] = player.timetravelconsts.kartPositionDelay or 0

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
			
			table.insert(tableToUse[mapthing.angle], mapthing.mobj)
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