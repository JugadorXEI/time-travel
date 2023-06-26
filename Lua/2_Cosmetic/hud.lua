local HUD_VERSION = 1

-- avoid redefiniton on updates
if timetravel.HUD_VERSION == nil or timetravel.HUD_VERSION < HUD_VERSION then

local TICRATE = TICRATE
local starttime = 6*TICRATE + 3*TICRATE/4

timetravel.Sprite_CDSign = "CDTIME"
timetravel.Sprite_TimeTravelDevice = "K_STON"
timetravel.Sprite_TimeTravelDeviceSmall = "K_STOM"
timetravel.Sprite_TimeTravelCorner = "TTBORD"

local ANGLETOFINESHIFT = 19
local FINEANGLES = 8192
local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT
local RING_DIST = RING_DIST

local BASEVIDWIDTH = 320
local BASEVIDHEIGHT = 200

local V_SNAPTOLEFT = V_SNAPTOLEFT
local V_SNAPTORIGHT = V_SNAPTORIGHT
local V_SPLITSCREEN = V_SPLITSCREEN
local V_SNAPTOTOP = V_SNAPTOTOP
local V_SNAPTOBOTTOM = V_SNAPTOBOTTOM
local V_FLIP = V_FLIP

local TC_ALLWHITE = TC_ALLWHITE

local V_90TRANS = V_90TRANS
local V_10TRANS = V_10TRANS

local function getSplitscreenFlags(player)
	local flags = 0
	if splitscreen > 1 then -- P1, P2, P3, P4
		for i = 0, 3 do
			if player == displayplayers[i] then
				if i % 2 == 0 then -- odd, p1 and p3
					flags = $|V_SNAPTOLEFT
				else -- even, p2 and p4
					flags = $|V_SNAPTORIGHT
				end
				
				if i > 1 then flags = $|V_SPLITSCREEN
				else flags = $|V_SNAPTOTOP
				end
				
				return flags
			end
		end
	else
		if splitscreen == 1 then
			flags = V_SNAPTOLEFT
			if player == displayplayers[0] then
				flags = $|V_SNAPTOTOP
			else
				flags = $|V_SPLITSCREEN
			end
		else
			flags = V_SNAPTOLEFT|V_SNAPTOTOP
		end
	end

	return flags
end

local function getItemBoxPosition(player, centered)

	local xPos, yPos = 5, 5

	if splitscreen then
		xPos, yPos = 5, 3
		
		if splitscreen > 1 then
			for i = 0, 3 do
				if player == displayplayers[i] then
					if i % 2 == 0 then xPos = -9
					else xPos = 281
					end
					
					yPos = -8
				end
			end
		end
	end
	
	if centered then
		if splitscreen > 1 then
			xPos = $ + 24
			yPos = $ + 23
		else
			xPos = $ + 25
			yPos = $ + 25
		end
	end

	return xPos, yPos 
end

local function powerOf(num, to)
	local final = num
	for i = 1, to do final = FixedMul(final, num) end
	return final
end

local function easeOut(a)
	local frac = FRACUNIT - a
	return FRACUNIT - powerOf(frac, 2)
end

-- Variables for the moving time travel device
local ttd_animLength = TICRATE/2
local ttd_animDuration = {ttd_animLength, ttd_animLength, ttd_animLength, ttd_animLength}
local ttd_currentOffset = {
	{0, 0, FRACUNIT},
	{0, 0, FRACUNIT},
	{0, 0, FRACUNIT},
	{0, 0, FRACUNIT}
}

local function ttd_getPlayerOffset(player)
	if splitscreen > 1 then
		for i = 0, 3 do
			if player == displayplayers[i] then
				if i % 2 == 0 then
					return { 9<<FRACBITS, -6<<FRACBITS, FRACUNIT/2}
				else 
					return { 9<<FRACBITS, -6<<FRACBITS, FRACUNIT/2}
				end
			end
		end
	end
	
	return {18<<FRACBITS, -8<<FRACBITS, FRACUNIT/2}
end

-- Variables for the time travel device frame animations
local ttd_spriteLowerBound = 1
local ttd_spriteUpperBound = 6
local ttd_animCurrentDeviceFrame = {
	ttd_spriteLowerBound,
	ttd_spriteLowerBound,
	ttd_spriteLowerBound,
	ttd_spriteLowerBound
}

-- Variables for the moving Sonic CD sign
local cd_animLength = TICRATE*4
local cd_animDimensionView = TICRATE*3
local cd_animDisappear = TICRATE
local cd_spriteLowerBound = 1
local cd_spriteUpperBound = 8
local cd_animDuration = {0, 0, 0, 0}
local cd_animCurrentSignFrame = {
	cd_spriteLowerBound,
	cd_spriteLowerBound,
	cd_spriteLowerBound,
	cd_spriteLowerBound
}
local cd_previousPlaceStatus = {false, false, false, false}
local cd_past = 1
local cd_future = 5

-- Variables for the time travel borders
local border_spriteLowerBound = 1
local border_spriteUpperBound = 6

-- Tables for cached patches
local check_patches = {}
local itembox_patches = {}
local tt_patches = {}
local tt_4p_patches = {}
local cdsign_patches = {}
local corner_patches = {}
local cornervert_patches = {}

local function cacheAllPatches(v)
	-- Kart's default CHECK sprites.
	for i = 1, 6 do table.insert(check_patches, v.cachePatch("K_CHECK"..i)) end
	-- Kart's default item box sprites.
	table.insert(itembox_patches, v.cachePatch("K_ITBG"))
	table.insert(itembox_patches, v.cachePatch("K_ISBG"))
	-- Time Travel gem patches
	for i = ttd_spriteLowerBound, ttd_spriteUpperBound do
		table.insert(tt_patches, 	v.cachePatch(timetravel.Sprite_TimeTravelDevice..i))
		table.insert(tt_4p_patches, v.cachePatch(timetravel.Sprite_TimeTravelDeviceSmall..i))
	end
	-- CD sign patches
	for i = cd_spriteLowerBound, cd_spriteUpperBound do
		table.insert(cdsign_patches, v.cachePatch(timetravel.Sprite_CDSign..i))
	end
	-- TT corner patches
	for i = border_spriteLowerBound, border_spriteUpperBound do
		table.insert(corner_patches, 	 v.cachePatch(timetravel.Sprite_TimeTravelCorner..i))
		table.insert(cornervert_patches, v.cachePatch(timetravel.Sprite_TimeTravelCorner..i.."V"))
	end
end

local function cd_getPlayerOffset(player)
	if splitscreen > 1 then
		for i = 0, 3 do
			if player == displayplayers[i] then
				if i % 2 == 0 then
					return {44, 15}
				else 
					return {276, 15}
				end
			end
		end
	end
	
	return {30, 62}
end

local cv_kartcheck
local function K_FindCheckX(px, py, ang, mx, my)
	local range = (RING_DIST / 3) * (gamespeed + 1)
	local dist = abs(R_PointToDist2(px, py, mx, my))
	-- print("range: " + range)
	-- print("dist:  " + dist)
	if dist > range then return -320 end

	local diff = R_PointToAngle2(px, py, mx, my) - ang
	-- print("diff:  " + diff)
	-- print("diff (exact):  " + (diff/ANG1))
	-- print("is diff? " + (not (diff < ANGLE_270 or diff > ANGLE_90)))
	local x = 0

	if not (diff < ANGLE_270 or diff > ANGLE_90) then return -320
	else x = (FixedMul(tan(diff, true), 160 << FRACBITS) + (160 << FRACBITS)) >> FRACBITS end

	if encoremode then x = 320 - $ end
	if splitscreen > 1 then x = $ / 2 end
	
	-- print("x: " + x)

	return x

end

local function K_DrawKartPlayerCheckEX(player, v)
	if not player.mo and not player.mo.valid and player.specator then return end
	if player.awayviewtics then return end
	
	for otherPlayer in players.iterate do
		if otherPlayer == player then continue end
		if otherPlayer.spectator then continue end
		if not otherPlayer.mo or not otherPlayer.mo.valid then continue end
		if not otherPlayer.mo.timetravel then continue end
		-- Only do this for players that are *not* in your timeline.
		if player.mo.timetravel.isTimeWarped == otherPlayer.mo.timetravel.isTimeWarped then continue end
		-- Get the other player's offset position.
		local xOffset, yOffset = timetravel.determineTimeWarpPosition(otherPlayer.mo)
		
		local checkNum = 1
		local pks = otherPlayer.kartstuff
		
		if pks[k_invincibilitytimer] <= 0 and leveltime & 2 == 0 then
			checkNum = $ + 1
		end
		
		if pks[k_itemtype] == KITEM_GROW or pks[k_growshrinktimer] > 0 then
			checkNum = $ + 4
		elseif pks[k_itemtype] == KITEM_INVINCIBILITY or pks[k_invincibilitytimer] > 0 then
			checkNum = $ + 2
		end
		
		local x = K_FindCheckX(player.mo.x, player.mo.y, player.mo.angle, otherPlayer.mo.x + xOffset, otherPlayer.mo.y + yOffset)
		if x <= 320 and x >= 0 then
		
			if x < 14 then x = 14
			elseif x > 306 then x = 306 end
			local colormap = v.getColormap(TC_DEFAULT, otherPlayer.mo.color)
			v.draw(x, 200, check_patches[checkNum], V_HUDTRANS|V_SNAPTOBOTTOM, colormap)
		end

	end
end

hud.add(function(v, player)
	if timetravel.HUD_VERSION > HUD_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < 3 then return end
	
	if not (#check_patches > 0) then cacheAllPatches(v) end
	if leveltime == 3 then
		ttd_animDuration = {ttd_animLength, ttd_animLength, ttd_animLength, ttd_animLength}
		ttd_currentOffset = {
			{0, 0, FRACUNIT},
			{0, 0, FRACUNIT},
			{0, 0, FRACUNIT},
			{0, 0, FRACUNIT},
			{0, 0, FRACUNIT}
		}
	
		cd_animDuration = {0, 0, 0, 0}
		cd_previousPlaceStatus = {false, false, false, false}
		cd_animCurrentSignFrame = {
			cd_spriteLowerBound,
			cd_spriteLowerBound,
			cd_spriteLowerBound,
			cd_spriteLowerBound
		}
	end

	if player == nil or player.valid == false or 
		player.mo == nil or player.mo.valid == false or 
		player.mo.timetravel == nil or
		player.timetravelconsts == nil then return end

	local xOffset, yOffset = getItemBoxPosition(player)
	
	local flags = V_HUDTRANS
	if leveltime < timetravel.introTP2tic then
		flags = 0
	end
	
	local playerLocalNum = timetravel.isDisplayPlayer(player) + 1
	
	if not timetravel.hasSomethingInItemBox(player) then
		-- draw item box
		local itemBoxPatch = itembox_patches[1]
		if splitscreen > 1 then itemBoxPatch = itembox_patches[2] end
		
		v.draw(xOffset, yOffset, itemBoxPatch, flags|getSplitscreenFlags(player))
		
		if ttd_animDuration[playerLocalNum] < ttd_animLength then
			ttd_animDuration[playerLocalNum] = $ + 1
		end
	else
		if ttd_animDuration[playerLocalNum] > 0 then
			ttd_animDuration[playerLocalNum] = $ - 1
		end
	end
	
	local timeTravelDeviceFrameNum = ttd_spriteLowerBound
	if player.mo.timetravel.teleportCooldown > 0 then
		if player.mo.timetravel.teleportCooldown > timetravel.teleportCooldown - (ttd_spriteUpperBound * 2) then
			timeTravelDeviceFrameNum = (timetravel.teleportCooldown / 2) - (player.mo.timetravel.teleportCooldown / 2) + 1
		else timeTravelDeviceFrameNum = ttd_spriteUpperBound
		end
	end
	
	local table_timetravelpatches = tt_patches
	if splitscreen > 1 then table_timetravelpatches = tt_4p_patches end	
	local timeTravelDevicePatch = table_timetravelpatches[timeTravelDeviceFrameNum]
	
	local xItemOffset, yItemOffset = getItemBoxPosition(player, true)
	
	local endValues = ttd_getPlayerOffset(player)
	local posXFraction = (endValues[1] / ttd_animLength) * (ttd_animLength - ttd_animDuration[playerLocalNum])
	local posYFraction = (endValues[2] / ttd_animLength) * (ttd_animLength - ttd_animDuration[playerLocalNum])
	local sizeFraction = (endValues[3] / ttd_animLength) * (ttd_animDuration[playerLocalNum])
	
	local posResultX = abs(easeOut(posXFraction/ttd_animLength))
	local posResultY = abs(easeOut(posYFraction/ttd_animLength))
	local sizeResult = abs(easeOut(sizeFraction * 2)) -- size is already mapped from 0 - 1
	
	if splitscreen > 1 and (playerLocalNum == 2 or playerLocalNum == 4) then posResultX = -$ end
	
	ttd_currentOffset[playerLocalNum][1] = FixedMul(endValues[1], posResultX)
	ttd_currentOffset[playerLocalNum][2] = FixedMul(endValues[2], posResultY)
	ttd_currentOffset[playerLocalNum][3] = FixedMul(endValues[3], sizeResult)
	
	-- print(((FRACUNIT/2) + ttd_currentOffset[playerLocalNum][3]) + " = " + FRACUNIT)
	-- print("hud y: " + ttd_currentOffset[playerLocalNum][2]>>FRACBITS)
	local playerColormap = v.getColormap(player.mo.skin, player.skincolor)

	v.drawScaled((xItemOffset << FRACBITS) + ttd_currentOffset[playerLocalNum][1],
		(yItemOffset << FRACBITS) + ttd_currentOffset[playerLocalNum][2],
		(FRACUNIT/2) + ttd_currentOffset[playerLocalNum][3],
		timeTravelDevicePatch, flags|getSplitscreenFlags(player), playerColormap)
	
	-- CD Sign
	-- Perform animations based on whether the player just time traveled
	if player.mo.timetravel.isTimeWarped ~= cd_previousPlaceStatus[playerLocalNum] then
		cd_animDuration[playerLocalNum] = cd_animLength
		
		if player.mo.timetravel.isTimeWarped then
			cd_animCurrentSignFrame[playerLocalNum] = 4
		else
			cd_animCurrentSignFrame[playerLocalNum] = 8
		end
	end
	cd_previousPlaceStatus[playerLocalNum] = player.mo.timetravel.isTimeWarped
	
	if cd_animDuration[playerLocalNum] > 0 then
		local cd_pos = cd_getPlayerOffset(player)
		
		if cd_animDuration[playerLocalNum] > cd_animDimensionView then -- Spinning

			local colormap = nil
			if cd_animDuration[playerLocalNum] == cd_animDimensionView - 1 then
				colormap = v.getColormap(TC_ALLWHITE)
			end

			local currentAnimPatch = cdsign_patches[cd_animCurrentSignFrame[playerLocalNum]]
			v.draw(cd_pos[1], cd_pos[2], currentAnimPatch, getSplitscreenFlags(player), colormap)
			
			if cd_animDuration[playerLocalNum] % 2 == 0 then
				cd_animCurrentSignFrame[playerLocalNum] = $ + 1
				
				if cd_animCurrentSignFrame[playerLocalNum] > cd_spriteUpperBound then
					cd_animCurrentSignFrame[playerLocalNum] = cd_spriteLowerBound
				end
			end
			
		else
			local currentLocationPatch = nil
			if player.mo.timetravel.isTimeWarped == false then currentLocationPatch = cdsign_patches[cd_past]
			else currentLocationPatch = cdsign_patches[cd_future] end
		
			if cd_animDuration[playerLocalNum] >= 9 then -- Showing off where we are
				v.draw(cd_pos[1], cd_pos[2], currentLocationPatch, getSplitscreenFlags(player))
			elseif cd_animDuration[playerLocalNum] < 9 then
				v.draw(cd_pos[1], cd_pos[2], currentLocationPatch, getSplitscreenFlags(player)|(V_10TRANS * (9 - cd_animDuration[playerLocalNum])))
			end
		end
		
		cd_animDuration[playerLocalNum] = $ - 1
	end
	
	-- Kart Check
	if (cv_kartcheck and cv_kartcheck.value) and not splitscreen and not player.exiting then
		K_DrawKartPlayerCheckEX(player, v)
	end
	
	-- Borders
	if not splitscreen and player.mo.timetravel.teleportCooldown ~= nil and
		player.mo.timetravel.teleportCooldown > timetravel.echoBonkCooldown then -- testing borders
		-- print(timetravel.Sprite_TimeTravelCorner+((leveltime % 6) + 1))
		local flags = 0
		
		if player.mo.timetravel.teleportCooldown < timetravel.echoBonkCooldown + 9 then
			flags = V_90TRANS - (V_10TRANS * (player.mo.timetravel.teleportCooldown - timetravel.echoBonkCooldown))
		end
		
		local frameNum = ((leveltime % 12) / 2) + 1
		local upperRightCorner = corner_patches[frameNum]
		local lowerRightCorner = cornervert_patches[frameNum]

		v.drawScaled(BASEVIDWIDTH<<FRACBITS, 0, FRACUNIT/3, upperRightCorner, flags|V_SNAPTOTOP|V_SNAPTORIGHT)
		v.drawScaled(BASEVIDWIDTH<<FRACBITS, BASEVIDHEIGHT<<FRACBITS, FRACUNIT/3, lowerRightCorner, flags|V_SNAPTOBOTTOM|V_SNAPTORIGHT)
		v.drawScaled(0, 0, FRACUNIT/3, upperRightCorner, flags|V_SNAPTOTOP|V_SNAPTOLEFT|V_FLIP)
		v.drawScaled(0, BASEVIDHEIGHT<<FRACBITS, FRACUNIT/3, lowerRightCorner, flags|V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_FLIP)
	end
	
	-- Flash
	if player.timetravelconsts.TWFlash > 0 then
		local paletteColor = 120
		if player.mo.timetravel.isTimeWarped then
			paletteColor = 30
		end
	
		v.fadeScreen(paletteColor, player.timetravelconsts.TWFlash * 2)
	end
end)

addHook("ThinkFrame", function()
	if timetravel.HUD_VERSION > HUD_VERSION then return end
	if not timetravel.isActive then return end
	if cv_kartcheck ~= nil then return end
	if leveltime ~= 3 then return end
	cv_kartcheck = CV_FindVar("kartcheck")
end)

timetravel.HUD_VERSION = HUD_VERSION

end