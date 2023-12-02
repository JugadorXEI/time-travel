local TPANIM_VERSION = 10

-- avoid redefiniton on updates
if timetravel.TPANIM_VERSION == nil or timetravel.TPANIM_VERSION < TPANIM_VERSION then

local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT

local A = A
local FF_TRANSMASK = FF_TRANSMASK
local FF_TRANS90 = FF_TRANS90
local FF_TRANS10 = FF_TRANS10
local FF_FULLBRIGHT = FF_FULLBRIGHT
local FF_FRAMEMASK = FF_FRAMEMASK

local MF_NOBLOCKMAP = MF_NOBLOCKMAP
local MF_NOCLIP = MF_NOCLIP
local MF_NOGRAVITY = MF_NOGRAVITY
local MF_NOCLIPHEIGHT = MF_NOCLIPHEIGHT
local MF_DONTENCOREMAP = MF_DONTENCOREMAP
local MF_SCENERY = MF_SCENERY

local ANGLE_90 = ANGLE_90
local ANGLE_180 = ANGLE_180

local SKINCOLOR_BLUE = SKINCOLOR_BLUE

local S_INVISIBLE = S_INVISIBLE

local FixedMul = FixedMul
local FixedDiv = FixedDiv
local P_KillMobj = P_KillMobj
local P_MoveOrigin = P_MoveOrigin
local P_ReturnThrustX = P_ReturnThrustX
local P_ReturnThrustY = P_ReturnThrustY

local noDrawDist = 6144<<FRACBITS

freeslot("SPR_TTSP", "S_TT_SPARKLE", "MT_TT_SPARKLEOVERLAY")

local animOrder = { A, B, C, B }
local sparklePos = {
	--X					Z
	{ 0, 				25	<<FRACBITS	},
	{ 20<<FRACBITS, 	20	<<FRACBITS	},
	{ 25<<FRACBITS,		0				},
	{ 20<<FRACBITS, 	-20	<<FRACBITS	},
	{ 0, 				-25	<<FRACBITS	},
	{ -20<<FRACBITS, 	-20	<<FRACBITS	},
	{ -25<<FRACBITS,	0				},
	{ -20<<FRACBITS, 	20	<<FRACBITS	}
}

local function powerOf(num, to)
	local final = num
	for i = 1, to do final = FixedMul(final, num) end
	return final
end

local function easeOut(a)
	local frac = FRACUNIT - a
	return FRACUNIT - powerOf(frac, 7)
end

function A_SparkleOnItsTuesdayDontForgetToBeYourself(actor, var1)
	local actorFuse = actor.fuse
	local actorFrame = actor.frame

	actor.momx = FixedMul(actor.momx, FRACUNIT - easeOut(FRACUNIT / actorFuse))
	actor.momy = FixedMul(actor.momy, FRACUNIT - easeOut(FRACUNIT / actorFuse))
	
	actor.frame = ($ & ~FF_FRAMEMASK) | animOrder[((actorFuse % 8) / 2) + 1]
	
	if (actorFrame & FF_TRANSMASK) then actor.extravalue1 = (actorFrame & FF_TRANSMASK) / FF_TRANS10 end
	if actorFuse < (FF_TRANS90/FF_TRANS10) - actor.extravalue1 then
		if (actorFrame & FF_TRANSMASK) 	then actorFrame = $ & ~FF_TRANSMASK end
		if (actorFrame & FF_FULLBRIGHT) 	then actorFrame = $ & ~FF_FULLBRIGHT end
		actor.frame = $ | (FF_TRANS90 - (FF_TRANS10 * actorFuse))
	end
	
	-- print(actor.frame)
	
	if actorFuse <= 0 then P_KillMobj(actor) end
end

mobjinfo[MT_TT_SPARKLEOVERLAY] = {
	spawnstate = S_INVISIBLE,
	radius = 1<<FRACBITS,
	height = 1<<FRACBITS,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_DONTENCOREMAP,
}

states[S_TT_SPARKLE] = {
	sprite = SPR_TTSP,
	frame = FF_FULLBRIGHT|FF_TRANS10|A,
	action = A_SparkleOnItsTuesdayDontForgetToBeYourself,
	var1 = 20,
	tics = 1,
	nextstate = S_TT_SPARKLE,
}

addHook("MobjThinker", function(mo)
	if not (mo.target and mo.target.valid) then
		P_KillMobj(mo)
		return nil
	end
	
	local target = mo.target
	
	P_MoveOrigin(mo, target.x, target.y, target.z)
	
	if mo.tics % 4 == 0 then
		local targetAngle = target.angle
		local targetScale = target.scale
		local targetRadius = target.radius
		local mapobjectscale = mapobjectscale
		local xOffset = P_ReturnThrustX(targetAngle + ANGLE_180, FRACUNIT)
		local yOffset = P_ReturnThrustY(targetAngle + ANGLE_180, FRACUNIT)
		local zOffset = FixedDiv(target.height, mapobjectscale*2)
		local extravalue1 = mo.extravalue1
		
		xOffset = $ + P_ReturnThrustX(targetAngle + ANGLE_90, sparklePos[(extravalue1 % #sparklePos) + 1][1])
		yOffset = $ + P_ReturnThrustY(targetAngle + ANGLE_90, sparklePos[(extravalue1 % #sparklePos) + 1][1])
		zOffset = $ + sparklePos[(extravalue1 % #sparklePos) + 1][2]
		
		xOffset = FixedMul(FixedMul($, targetScale), FRACUNIT)
		yOffset = FixedMul(FixedMul($, targetScale), FRACUNIT)
		zOffset = FixedMul(FixedMul($, targetScale), FRACUNIT)
		
		local sparkle = P_SpawnMobj(mo.x + xOffset, mo.y + yOffset, mo.z + zOffset, MT_THOK)
		sparkle.target = target
		
		local momx, momy = target.momx, target.momy
		if target.player then
			momx, momy = target.player.rmomx, target.player.rmomy
		end
		
		if target.player.speed < 5<<FRACBITS then
			momx = $ + P_ReturnThrustX(targetAngle + ANGLE_180, targetRadius/2)
			momy = $ + P_ReturnThrustY(targetAngle + ANGLE_180, targetRadius/2)
		end
		
		sparkle.momx = momx
		sparkle.momy = momy
		-- sparkle.momz = target.momz
		sparkle.fuse = 20
		sparkle.state = S_TT_SPARKLE
		sparkle.colorized = true
		
		if target.player then
			sparkle.color = target.player.skincolor
		elseif mo.color then
			sparkle.color = mo.color
		else 
			sparkle.color = SKINCOLOR_BLUE
		end
		
		sparkle.flags = ($ & ~MF_SCENERY)
		sparkle.scale = (mapobjectscale/4)*3
		sparkle.destscale = (mapobjectscale/4)*3
		
		mo.extravalue1 = $ + 1
	end

end, MT_TT_SPARKLEOVERLAY)

timetravel.createSparkles = function(mo)
	if mo.type ~= MT_PLAYER then return end
	
	-- Only execute this for non-display players.
	if timetravel.isDisplayPlayer(mo.player) == -1 then
	
		local localPlayerDist = nil
		for i = 0, 3 do
			local player = displayplayers[i]
			if player ~= nil and player.mo and player.mo.valid then
				local xOffset, yOffset = 0, 0
				if player.mo.timetravel.isTimeWarped ~= mo.timetravel.isTimeWarped then
					xOffset, yOffset = timetravel.determineTimeWarpPosition(mo)
				end
			
				local thisDist = FixedHypot((player.mo.x - xOffset) - mo.x, (player.mo.y - yOffset) - mo.y)
				localPlayerDist = min($ or INT32_MAX, thisDist)
				-- print("Last dist stored: " + localPlayerDist)
			else break
			end
		end
		
		if localPlayerDist ~= nil and localPlayerDist > noDrawDist then
			return -- Don't draw this animation if the player is too far away from local players to be seen.
		end
	end
	
	local sparkleOverlay = P_SpawnMobj(mo.x, mo.y, mo.z, MT_TT_SPARKLEOVERLAY)
	sparkleOverlay.target = mo
	sparkleOverlay.tics = 36
	sparkleOverlay.extravalue1 = 0
end

timetravel.addTimeTravelHook(timetravel.createSparkles)

timetravel.TPANIM_VERSION = TPANIM_VERSION

end