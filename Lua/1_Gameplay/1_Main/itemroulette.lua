local ROULETTE_VERSION = 2

-- avoid redefiniton on updates
if timetravel.ROULETTE_VERSION == nil or timetravel.ROULETTE_VERSION < ROULETTE_VERSION then

local defaultItemOddsCalcFunc = nil

--[[
Dear XItem modder,
Because there's no way to directly hook into the item odds calculation, I have to override the function.
All I change is the PDI calculation, which I change in this function, customPDIcalc.
If you want to make your stuff compatible with mine, use this to calculate PDIs for time travel maps.
Thank you.	
]]
timetravel.customPDIcalc = function(p, p2, pingame)
	local pdis = 0
	for p2 in players.iterate do
		if p.mo and p2 and (not p2.spectator) and p2.mo and (p2.kartstuff[k_position] ~= 0) and p2.kartstuff[k_position] < p.kartstuff[k_position] then
			local p2Mo = p2.mo
			if p.mo.timetravel.isTimeWarped ~= p2Mo.timetravel.isTimeWarped and p2Mo.linkedItem then
				p2Mo = p2Mo.linkedItem
			end
		
			pdis = $ + R_PointToDist2(0, p.mo.x, R_PointToDist2(p.mo.y, p.mo.z, p2Mo.y, p2Mo.z), p2Mo.x) / mapobjectscale * (pingame - p2.kartstuff[k_position]) / max(1, ((pingame - 1) * (pingame + 1) / 3))
		end
	end
	
	return pdis
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
			--debug_useoddsstopcode = 8
		else
			useodds = 1
			--debug_useoddsstopcode = 9
			if (oddsvalid[1] == false and oddsvalid[2])
				-- try to use karma odds as a fallback
				useodds = 2
				--debug_useoddsstopcode = 10
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
		
		pdis = ((28 + (8-pingame)) * $) / 28
		
		if pingame == 1 and oddsvalid[1] then					-- Record Attack, or just alone
			useodds = 1
			--debug_useoddsstopcode = 0
		elseif pdis <= 0 then									-- (64*14) *  0 =     0
			useodds = disttable[1]
			--debug_useoddsstopcode = 1
		elseif pks[k_position] == 2 and oddsvalid[10] and (spbplace == -1) and (not indirectitemcooldown) and (not dontforcespb) and (pdis > distvar*6) then -- Force SPB in 2nd
			useodds = 10
			--debug_useoddsstopcode = 7
		elseif pdis > distvar * ((12 * distlen) / 14) then -- (64*14) * 12 = 10752
			useodds = disttable[distlen]
			p.playerbot = nil
			--debug_useoddsstopcode = 2
		else
			for i = 1, 12 do
				if pdis <= distvar * ((i * distlen) / 14) then
					useodds = disttable[((i * distlen) / 14)] + 1
					--debug_useoddsstopcode = 3
					break
				end
			end
		end
	end
	--print("Got useodds "..useodds.." (kart useodds "..(useodds - 1).."). (position: "..p.kartstuff[k_position]..", distance: "..pdis..", stopcode: "..debug_useoddsstopcode..")") 
	--debug_useoddsstopcode = nil
	
	distvar = nil
	i = nil
	pdis = nil
	distlen = nil
	
	return useodds
end

local function xitemItemOddsHandler()
	if timetravel.ROULETTE_VERSION > ROULETTE_VERSION then return end
	if not (xItemLib and xItemLib.func) then return end
	if defaultItemOddsCalcFunc == nil then defaultItemOddsCalcFunc = xItemLib.func.findUseOdds end
	
	local lib = xItemLib.func
	
	if timetravel.isActive then lib.findUseOdds = customItemOddsCalcFunc
	else lib.findUseOdds = defaultItemOddsCalcFunc end
end

addHook("MapLoad", xitemItemOddsHandler)
addHook("NetVars", xitemItemOddsHandler)

timetravel.ROULETTE_VERSION = ROULETTE_VERSION

end