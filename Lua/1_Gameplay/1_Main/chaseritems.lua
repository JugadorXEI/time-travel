-- You are the Chaser! Bring it!
local CHASER_VERSION = 1

-- avoid redefiniton on updates
if timetravel.CHASER_VERSION == nil or timetravel.CHASER_VERSION < CHASER_VERSION then

local FRACUNIT = FRACUNIT
local FRACBITS = FRACBITS

local KITEM_JAWZ = KITEM_JAWZ
local MT_JAWZ = MT_JAWZ
local MT_SPB = MT_SPB
local MT_PLAYERRETICULE = MT_PLAYERRETICULE
local RING_DIST = RING_DIST
local GT_TEAMMATCH = GT_TEAMMATCH
local GT_CTF = GT_CTF

local MF_NOBLOCKMAP = MF_NOBLOCKMAP
local MF_NOCLIP = MF_NOCLIP
local MF_NOGRAVITY = MF_NOGRAVITY
local MF_DONTENCOREMAP = MF_DONTENCOREMAP

local S_PLAYERRETICULE = S_PLAYERRETICULE
local S_NULL = S_NULL

local FF_FULLBRIGHT = FF_FULLBRIGHT

local k_position = k_position
local k_bumper = k_bumper
local k_hyudorotimer = k_hyudorotimer
local k_jawztargetdelay = k_jawztargetdelay
local k_itemheld = k_itemheld
local k_itemtype = k_itemtype

local ANGLE_180 = ANGLE_180
local ANGLE_67h = ANGLE_67h
local ANGLE_45 = ANGLE_45

local sfx_s3k89 = sfx_s3k89

local abs = abs
local R_PointToAngle2 = R_PointToAngle2
local P_AproxDistance = P_AproxDistance
local AngleFixed = AngleFixed
local P_RemoveMobj = P_RemoveMobj
local S_StopSoundByID = S_StopSoundByID
local S_StartSound = S_StartSound
local P_KillMobj = P_KillMobj

local types = {
	MT_JAWZ,
	MT_SPB
}

freeslot("MT_PLAYERRETICULE_TT")
mobjinfo[MT_PLAYERRETICULE_TT] = {
	spawnstate = S_PLAYERRETICULE,
	spawnhealth = 1000,
	radius = 16<<FRACBITS,
	height = 56<<FRACBITS,
	dispoffset = 2,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOGRAVITY|MF_DONTENCOREMAP
}

-- LEMAYO IT'S ANOTHER HARDCODE PORT
timetravel.K_FindJawzTargetEX = function(actor, source)
	local best = -1
	local wtarg = nil

	for target in players.iterate do
		local thisang
		local targetMo = target.mo
		local targetPks = target.kartstuff
		
		if target.spectator or not (targetMo and targetMo.valid) or targetMo.health <= 0 or target == source or
			targetPks[k_hyudorotimer] or
			((gametype == GT_TEAMMATCH or gametype == GT_CTF) and source.ctfteam == target.ctfteam) then
			continue 
		end
		
		-- Which mobj to use for targetting?
		if actor.timetravel and targetMo.timetravel and
			actor.timetravel.isTimeWarped ~= targetMo.timetravel.isTimeWarped and
			(targetMo.linkedItem and targetMo.linkedItem.valid) then
			
			targetMo = targetMo.linkedItem
		end
			
		thisang = actor.angle - R_PointToAngle2(actor.x, actor.y, targetMo.x, targetMo.y)
		if thisang > ANGLE_180 then
			thisang = abs(thisang)
		end
		
		-- Jawz only go after the person directly ahead of you in race... sort of literally now!
		if gametype == GT_RACE then
		
			-- Don't go for people who are behind you
			-- print((thisang / ANG1) + " > " + (ANGLE_67h / ANG1))
			if thisang > ANGLE_67h then continue end
			-- Don't pay attention to people who aren't above your position
			if targetPks[k_position] >= source.kartstuff[k_position] then continue end
				
			if best == -1 or targetPks[k_position] > best then
				wtarg = target
				best = targetPks[k_position]
			end
		
		else
			local thisdist, thisavg
			
			if thisang > ANGLE_45 then continue end -- Don't go for people who are behind you
			if targetPks[k_bumper] <= 0 then continue end -- Don't pay attention to dead players	
			if abs(targetMo.z - (actor.z + actor.momz)) > RING_DIST / 8 then continue end -- Z pos too high/low

			thisdist = P_AproxDistance(targetMo.x - (actor.x + actor.momx), targetMo.y - (actor.y + actor.momy))

			if thisdist > RING_DIST * 2 then continue end -- Don't go for people who are too far away

			thisavg = (AngleFixed(thisang) + thisdist) / 2

			if best == -1 or thisavg < best then			
				wtarg = target
				best = thisavg
			end
		end
	end

	return wtarg
end

local function createPlayerReticule(target, extra)
	local ret = P_SpawnMobj(target.x, target.y, target.z, MT_PLAYERRETICULE_TT)
	ret.target = target
	ret.frame = FF_FULLBRIGHT | ((leveltime % 10) / 2)
	
	if extra then
		ret.frame = $ + 5
		ret.extravalue2 = 1
	end
	
	ret.tics = -1
	
	return ret
end

addHook("MobjThinker", function(mo)
	local target = mo.target
	if not (target and target.health) or 
		(mo.extravalue == 1 and not mo.tracer) then
		P_RemoveMobj(mo)
		return
	end

	mo.frame = FF_FULLBRIGHT | ((leveltime % 10) / 2)
	if mo.extravalue2 then mo.frame = $ + 5 end
	
	local didTargetsChange = (mo.lastTarget and mo.lastTarget ~= target)
	
	-- This is technically a hack, echoes.lua should handle this.
	-- But I'm not implementing a whole system for that. Bear with me.
	local movementfunc = P_MoveOrigin
	if didTargetsChange then movementfunc = P_SetOrigin end
	
	movementfunc(mo, target.x, target.y, target.z)
	if mo.linkedItem and didTargetsChange then
		local xOffset, yOffset = timetravel.determineTimeWarpPosition(mo)
		movementfunc(mo.linkedItem, target.x + xOffset, target.y + yOffset, target.z)
	end
	
	mo.lastTarget = target

end, MT_PLAYERRETICULE_TT)

-- this is ran in waypointfix.lua to account for our new waypoint logic.
-- yes, it's a port of another piece of hardcode.
timetravel.JawzTargettingLogic = function(player)

	local pks = player.kartstuff

	-- Stop the original targetting sound if it happens.
	-- Can't stop local sounds. Sorry if you hear 'em, outta my hands.
	if pks[k_jawztargetdelay] == 5 then
		S_StopSoundByID(player.mo, sfx_s3k89)
	end

	if pks[k_itemtype] == KITEM_JAWZ and pks[k_itemheld] then
		local lasttarg = player.timetravelconsts.lastJawzTarget
		local targ, ret

		if player.timetravelconsts.lastJawzTarget > -1 and not players[lasttarg].spectator then
			targ = players[lasttarg]
			player.timetravelconsts.jawzTargetDelay = $ - 1
		else targ = timetravel.K_FindJawzTargetEX(player.mo, player) end

		local targMo = targ.mo
		if not (targ and targMo and targMo.valid) then
		
			player.timetravelconsts.lastJawzTarget = -1
			player.timetravelconsts.jawzTargetDelay = 0
			
			if player.timetravelconsts.jawzReticule and player.timetravelconsts.jawzReticule.valid then
				P_KillMobj(player.timetravelconsts.jawzReticule)
				player.timetravelconsts.jawzReticule = nil
			end
			
			return
		end
		
		if not (player.timetravelconsts.jawzReticule and player.timetravelconsts.jawzReticule.valid) then
			local reticule = createPlayerReticule(targMo)
			reticule.extravalue = 1
			reticule.tracer = player.mo
			reticule.color = player.skincolor
			player.timetravelconsts.jawzReticule = reticule
		else
			player.timetravelconsts.jawzReticule.target = targMo
		end

		if (#targ - #players) ~= lasttarg then
		
			if timetravel.isDisplayPlayer(player) ~= -1 or timetravel.isDisplayPlayer(targ) ~= -1 then
				S_StartSound(nil, sfx_s3k89)
			else
				S_StartSound(targMo, sfx_s3k89)
			end

			player.timetravelconsts.lastJawzTarget = #targ - #players
			player.timetravelconsts.jawzTargetDelay = 5
		end

	else
		player.timetravelconsts.lastJawzTarget = -1
		player.timetravelconsts.jawzTargetDelay = 0
		
		if player.timetravelconsts.jawzReticule and player.timetravelconsts.jawzReticule.valid then
			P_KillMobj(player.timetravelconsts.jawzReticule)
			player.timetravelconsts.jawzReticule = nil
		end
	end
end

-- SPB & JAWZ LOGIC
addHook("MobjSpawn", function(mo)
	if timetravel.CHASER_VERSION > CHASER_VERSION then return end
	if not timetravel.isActive then return end

	mo.extravalue1 = 69
end, MT_JAWZ)

addHook("MobjThinker", function(mo)
	if timetravel.CHASER_VERSION > CHASER_VERSION then return end
	if not timetravel.isActive then return end
	local isItemTrackerType = false
	for i = 1, #types do
		isItemTrackerType = (types[i] == mo.type)
		if isItemTrackerType then break end
	end
	if not isItemTrackerType then return end
	if not mo.target then return end -- Ownerless item, away!
	if mo.timetravel == nil then mo.timetravel = {} end
	
	local itemTarget = mo.tracer
	
	local justSpawned = false
	if mo.timetravel.isTimeWarped == nil then
		mo.timetravel.isTimeWarped = mo.target.player.mo.timetravel.isTimeWarped
		if mo.type == MT_JAWZ and itemTarget == nil then
			local owner = mo.target
			local ownerPlayer
			if owner then ownerPlayer = owner.player end
			if owner and ownerPlayer then
				local finalJawzTarget = timetravel.K_FindJawzTargetEX(owner, ownerPlayer)
				if finalJawzTarget then itemTarget = finalJawzTarget.mo end
			end
		end
		justSpawned = true
	end

	if justSpawned then return end
	if mo.type == MT_SPB and mo.threshold ~= 0 then return end
	-- Chasing!
	
	if itemTarget == nil then return end
	
	if mo.type == MT_JAWZ then
		if mo.health > 0 and mo.reticule == nil then
			local reticule = createPlayerReticule(itemTarget, true)
			reticule.color = mo.cvmem
			reticule.extravalue = 1
			reticule.tracer = mo
			mo.reticule = reticule
		elseif mo.health <= 0 and (mo.reticule and mo.reticule.valid) then
			P_KillMobj(mo.reticule)
			mo.reticule = nil
		end
	end
	
	if mo.timetravel.isTimeWarped ~= itemTarget.timetravel.isTimeWarped then
		timetravel.changePositions(mo)
	end
	
end)

local reticuleState = S_PLAYERRETICULE
addHook("MapChange", function(mapnum)
	if timetravel.CHASER_VERSION > CHASER_VERSION then return end
	
	if timetravel.isActive then reticuleState = S_NULL
	else reticuleState = S_PLAYERRETICULE end
	
	mobjinfo[MT_PLAYERRETICULE].spawnstate = reticuleState
end)

addHook("NetVars", function(network)
	reticuleState = network(reticuleState)
end)

timetravel.CHASER_VERSION = CHASER_VERSION

end