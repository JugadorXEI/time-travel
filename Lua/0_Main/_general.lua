local GENERAL_VERSION = 1

if timetravel == nil then
	rawset(_G, "timetravel", {})
end

-- avoid redefiniton on updates
if timetravel.GENERAL_VERSION == nil or timetravel.GENERAL_VERSION < GENERAL_VERSION then

local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local ROULETTE_ENDTIC = TICRATE*3
local RING_DIST = RING_DIST
local KITEM_SNEAKER = KITEM_SNEAKER
local KITEM_ROCKETSNEAKER = KITEM_ROCKETSNEAKER
local KITEM_POGOSPRING = KITEM_POGOSPRING

local k_spinouttimer = k_spinouttimer
local k_squishedtimer = k_squishedtimer
local k_itemroulette = k_itemroulette
local k_itemtype = k_itemtype
local k_itemheld = k_itemheld
local k_eggmanheld = k_eggmanheld
local k_eggmanexplode = k_eggmanexplode
local k_rocketsneakertimer = k_rocketsneakertimer
local k_curshield = k_curshield
local k_growshrinktimer = k_growshrinktimer
local k_pogospring = k_pogospring

local P_PlayerInPain = P_PlayerInPain
local P_IsObjectOnGround = P_IsObjectOnGround
local FixedMul = FixedMul
local FixedDiv = FixedDiv
local FixedSqrt = FixedSqrt
local table_insert = table.insert

timetravel.turnCommaDelimitedStringIntoTable = function(string)
	if string == nil or string == "" then
		return {}, 0
	end

	local tableVar = {}
	local newString = ""
	local numThingsAdded = 0
	for i = 1, #string do
		local c = string:sub(i,i)
		
		if c == ',' then
			table_insert(tableVar, newString)
			numThingsAdded = $ + 1
			newString = ""
		else
			newString = $..c
		end
	end

	if newString ~= "" then
		table_insert(tableVar, newString)
		numThingsAdded = $ + 1
	end

	return tableVar, numThingsAdded
end

-- HELPERS
timetravel.isInDamageState = function(player)
	local pks = player.kartstuff
	
	if player.playerstate == PST_DEAD or
		P_PlayerInPain(player) or
		pks[k_spinouttimer]  > 0 or
		pks[k_squishedtimer] > 0 then
		
		return true
	end

	return false
end

timetravel.hasSomethingInItemBox = function(player, disregardboxonlyeffects)
	if disregardboxonlyeffects == nil then disregardboxonlyeffects = false end
	local pks = player.kartstuff

	if pks[k_itemroulette] > 0 or
		pks[k_itemtype] ~= 0 or
		pks[k_itemheld] == true or
		(disregardboxonlyeffects and pks[k_eggmanheld] ~= 0) or
		pks[k_eggmanexplode] > 0 or
		pks[k_rocketsneakertimer] > 0 or
		pks[k_curshield] > 0 or
		(not disregardboxonlyeffects and pks[k_growshrinktimer] > 0) or 
		(not disregardboxonlyeffects and (JUICEBOX ~= nil and JUICEBOX.value >= 1 and
			(player.gatedecay ~= nil and player.gatebarhappy ~= nil) and
			(player.gatedecay < 100 or player.gatebarhappy < (1*TICRATE/3+6)))) or -- Juicebox 
		(xItemLib and player.xItemData and player.xItemData.xItem_roulette > 0) -- Xitem
		then
		return true
	end

	return false
end

-- Overall edit of the previous function since some of the gameplay logic
-- wouldn't make much sense in HUD code...
timetravel.canUseItem = function(player)
	local pks = player.kartstuff
	local mo = player.mo

	if player.exiting then return false end
	if pks[k_itemroulette] > 0 or
		pks[k_eggmanheld] ~= 0 or
		pks[k_eggmanexplode] > 0 or
		(pks[k_rocketsneakertimer] > 0 and (P_IsObjectOnGround(mo) or pks[k_pogospring] > 0 or mo.paragliding)) or
		pks[k_curshield] > 0 or
		-- pks[k_growshrinktimer] > 0 or
		((pks[k_itemtype] == KITEM_SNEAKER or 
		  pks[k_itemtype] == KITEM_ROCKETSNEAKER or
		  pks[k_itemtype] == KITEM_POGOSPRING) and (P_IsObjectOnGround(mo) or pks[k_pogospring] > 0 or mo.paragliding) or
		 (pks[k_itemtype] ~= 0 and pks[k_itemtype] ~= KITEM_SNEAKER and
		  pks[k_itemtype] ~= KITEM_ROCKETSNEAKER and
		  pks[k_itemtype] ~= KITEM_POGOSPRING)) or
		pks[k_itemheld] or
		(xItemLib and player.xItemData and player.xItemData.xItem_roulette > 0) -- Xitem
		then
		return true
	end

	return false
end

timetravel.isDisplayPlayer = function(player)
	for i = 0, 3 do
		if displayplayers[i] ~= nil and displayplayers[i] == player then
			return i
		end
	end
	
	return -1

end

timetravel.getNormalizedVectors = function(x, y)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	
	local xSquared, ySquared = FixedMul(x, x), FixedMul(y, y)
	local totalSquared = xSquared + ySquared
	if totalSquared < 0 then return {0, 0} end
	
	local magnitude = FixedSqrt(totalSquared)

	local xNormal, yNormal = 0, 0
	if magnitude > 0 then
		xNormal = FixedDiv(x, magnitude)
		yNormal = FixedDiv(y, magnitude)
	end
	return {xNormal, yNormal}
end

timetravel.GENERAL_VERSION = GENERAL_VERSION

end