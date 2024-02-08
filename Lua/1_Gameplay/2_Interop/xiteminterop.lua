--[[
GPLv2 notice: Reimplementation of item roulette PDI calculation,
made 15/01/2023 (dd/mm/aaaa).
]]

local XITEM_ROULETTE_VERSION = 1

-- avoid redefiniton on updates
if timetravel.XITEM_ROULETTE_VERSION == nil or timetravel.XITEM_ROULETTE_VERSION < XITEM_ROULETTE_VERSION then

local defaultItemOddsCalcFunc = nil
local k_position = k_position
local k_roulettetype = k_roulettetype

local R_PointToDist2 = R_PointToDist2
local G_BattleGametype = G_BattleGametype

local XIF_SMUGGLECHECK = 128 --item contributes to the smuggle detection

timetravel.isXItemOddsEnabled = false

--[[
Dear XItem modder,
Because there's no way to directly hook into the item odds calculation, I have to override the function.
All I change is the PDI calculation, which I change in this function, customPDIcalc.
If you want to make your stuff compatible with mine, use this to calculate PDIs for time travel maps.
Thank you.	

02/12/2023 (dd/mm/aaaa) FIXME: No compatibility with conga calc distributions, this script is pretty much
in maintenance mode and I really don't want to enter the item odds calculation nightmare again, sorry.
Feel free to PR me a fix with that if you see it and you care, though.
]]
timetravel.customPDIcalc = function(p, p2, pingame)
	local pdis = 0
	local pmo = p.mo
	local pks = p.kartstuff
	
	for p2 in players.iterate do
		local p2mo = p2.mo
		local p2ks = p2.kartstuff
		if pmo and p2 and (not p2.spectator) and p2mo and (p2ks[k_position] ~= 0) and p2ks[k_position] < pks[k_position] then
			if pmo.timetravel.isTimeWarped ~= p2mo.timetravel.isTimeWarped and p2mo.linkedItem then
				p2mo = p2mo.linkedItem
			end
		
			pdis = $ + R_PointToDist2(0, pmo.x, R_PointToDist2(pmo.y, pmo.z, p2mo.y, p2mo.z), p2mo.x) / mapobjectscale * (pingame - p2ks[k_position]) / max(1, ((pingame - 1) * (pingame + 1) / 3))
		end
	end
	
	return pdis
end

local function smuggleDetection()
	local group = {}
	local itemData = {}
	local itemFlags = 0
	for p in players.iterate
		if not p.spectator then
			table.insert(group, p)
		end
	end
	
	for i=1, #group
		itemFlags = 0
		if group[i].kartstuff[k_itemtype] then
			itemData = xItemLib.func.getItemDataById(group[i].kartstuff[k_itemtype])
			if itemData then
				itemFlags = itemData.flags
			end
		end
		if 
			group[i].kartstuff[k_position] <= 2
			and (
				(itemFlags and (itemFlags & XIF_SMUGGLECHECK))
				or group[i].kartstuff[k_invincibilitytimer] > 0
				or group[i].kartstuff[k_growshrinktimer] > 0
				or (HugeQuest and group[i].hugequest.huge > 0)
			)
		then
			--print("SMUGGLER DETECTED")
			return true
		end
	end

	return false
end

local function customItemOddsCalcFunc(p, mashed, pingame, spbrush, dontforcespb)
	if not p then return end

	local distvar = 64*14
	local i
	local pdis = 0
	local useodds = 1
	local oddsvalid = {}
	local disttable = {}
	local distlen = 0
	--local debug_useoddsstopcode = 0
	
	local FAUXPOS = G_BattleGametype() and 2 or 10
	
	local libdat = xItemLib
	local libfn = libdat.func
	
	local pks = p.kartstuff
	
	--make faux positions valid or not
	for i = 1, FAUXPOS do
		local available = false
		for j = 1, libfn.countItems() do
			--print("checking itemodds for item "..j.." at pos "..i)
			if libfn.getOdds(i, j, mashed, spbrush, p) > 0 then
				available = true
				break
			end
		end
		oddsvalid[i] = available
	end
	
	--calc distances (honestly kinda weiiiirdddd)
	pdis = timetravel.customPDIcalc(p, p2, pingame)
	
	--set up distributions
	if (G_BattleGametype()) then
		if (pks[k_roulettetype] == 1 and oddsvalid[2])
			-- 1 is the extreme odds of player-controlled "Karma" items
			useodds = 2
		else
			useodds = 1
			if (oddsvalid[1] == false and oddsvalid[2])
				-- try to use karma odds as a fallback
				useodds = 2
			end
		end
	else
		if oddsvalid[2] then distlen = $ + libfn.setupDist(2, 1, disttable, distlen) end
		if oddsvalid[3] then distlen = $ + libfn.setupDist(3, 1, disttable, distlen) end
		if oddsvalid[4] then distlen = $ + libfn.setupDist(4, 1, disttable, distlen) end
		if oddsvalid[5] then distlen = $ + libfn.setupDist(5, 2, disttable, distlen) end
		if oddsvalid[6] then distlen = $ + libfn.setupDist(6, 2, disttable, distlen) end
		if oddsvalid[7] then distlen = $ + libfn.setupDist(7, 3, disttable, distlen) end
		if oddsvalid[8] then distlen = $ + libfn.setupDist(8, 3, disttable, distlen) end
		if oddsvalid[9] then distlen = $ + libfn.setupDist(9, 1, disttable, distlen) end
		
		if (franticitems) then -- Frantic items make the distances between everyone artifically higher, for crazier items
			pdis = (15 * $) / 14
		end
		
		if (spbrush) then -- SPB Rush Mode: It's 2nd place's job to catch-up items and make 1st place's job hell
			pdis = (3 * $) >> 1
		end
		
		if xItemLib.cvars.bSmugglerBonus.value 
			and smuggleDetection()
			and pks[k_position] > 1 
		then -- Haha, FUCK YOU
			pdis = (6*$)/5
		end

		pdis = ((28 + 8 - min(pingame, 16)) * $) / 28
		
		if pingame == 1 and oddsvalid[1] then					-- Record Attack, or just alone
			useodds = 1
		elseif pdis <= 0 then									-- (64*14) *  0 =     0
			useodds = disttable[1]
		elseif pks[k_position] == 2 and oddsvalid[10] and (spbplace == -1) and (not indirectitemcooldown) and (not dontforcespb) and (pdis > distvar*6) then -- Force SPB in 2nd
			useodds = 10
		elseif pdis > distvar * ((12 * distlen) / 14) then -- (64*14) * 12 = 10752
			useodds = disttable[distlen]
		else
			for i = 1, 12 do
				if pdis <= distvar * ((i * distlen) / 14) then
					useodds = disttable[((i * distlen) / 14)] + 1
					break
				end
			end
		end
	end
	
	-- lastpdis = pdis -- Sorry Ash!
	
	distvar = nil
	i = nil
	pdis = nil
	distlen = nil
	
	return useodds
end

local function xitemItemOddsHandler()
	if timetravel.XITEM_ROULETTE_VERSION > XITEM_ROULETTE_VERSION then return end
	if not (xItemLib and xItemLib.func) then return end
	if defaultItemOddsCalcFunc == nil then defaultItemOddsCalcFunc = xItemLib.func.findUseOdds end
	
	local lib = xItemLib.func
	
	if timetravel.isActive then
		lib.findUseOdds = customItemOddsCalcFunc
		timetravel.isXItemOddsEnabled = true
	else
		lib.findUseOdds = defaultItemOddsCalcFunc
		timetravel.isXItemOddsEnabled = false
	end
end

addHook("MapLoad", xitemItemOddsHandler)
addHook("NetVars", xitemItemOddsHandler)

timetravel.XITEM_ROULETTE_VERSION = XITEM_ROULETTE_VERSION

end