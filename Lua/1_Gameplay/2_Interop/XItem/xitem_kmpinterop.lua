-- The optimization momento certificado.
local KITEM_BANANA = KITEM_BANANA
local KITEM_ORBINAUT = KITEM_ORBINAUT
local KITEM_JAWZ = KITEM_JAWZ
local TICRATE = TICRATE
local k_itemblink = k_itemblink
local k_itemamount = k_itemamount
local MF2_DONTDRAW = MF2_DONTDRAW
-- No more opti.

local xitemHooked = false

local VERSION = 1
local KMP_NAMESPACE = "KARTMP"

-- Hooray for reusability, right?
-- Copied from KMP to preserve KMP Item Limiter:
local itemfalloff = {
	[KITEM_BANANA] 		= {4, 5, 1, 3},
	[KITEM_ORBINAUT] 	= {2, 6, 2, 2},
	[KITEM_JAWZ]		= {2, 8, 1, 1},
}

local function K_countplayers()
	local count = 0
	for p in players.iterate do
		if not (p.mo and p.mo.valid) then continue end
		count = $+1
	end
	return count
end

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[KMP_NAMESPACE] and modData[KMP_NAMESPACE].defDat.ver <= VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(KMP_NAMESPACE, "KartMP", 
	{
		lib = "By Lat - KartMP interop by JugadorXEI",
		ver = VERSION,
		-- Fixes KartMP's item limiter.
		getfunc = function(player, item)
			if not (kmp_itemlimiter and kmp_itemlimiter.value) then return end
			local pks = player.kartstuff
			-- Only for getting items through roulette, dropped/debug items are fine.
			if pks[k_itemblink] ~= TICRATE or xItemLib.toggles.debugItem > 0 then return end 
			if not itemfalloff[item] return end
			
			local playerCount = K_countplayers()
			
			for k, v in pairs(itemfalloff) do
				if item == k then
					local amount = pks[k_itemamount]

					-- If we have too many items of this type and too many players for this item...
					if amount >= v[1] and playerCount >= v[2] then

						local diff = playerCount - v[2]
						local loop_count = 0	-- how many players we've counted

						for i = 1, diff+1 do 
							loop_count = $+1
							if not (loop_count % v[3])
							and amount > v[4] then	-- > min item count for this
								amount = $-1		-- remove 1 item
							end
						end

						pks[k_itemamount] = amount
					end
				end
			end
		end
	})
	
	addHook("MobjThinker", function(mo)
		if not (kmp_floatingitemfuse and kmp_floatingitemfuse.value) then return end
		-- I don't make an xitem check here because it would be paradoxical,
		-- you can't have MT_FLOATINGXITEM without xItem.
		local modData = xItemLib.xItemCrossData.modData
		if modData[KMP_NAMESPACE] and modData[KMP_NAMESPACE].defDat.ver > VERSION then return end
		
		if P_IsObjectOnGround(mo) and not mo.fuse then
			local numlaps = mapheaderinfo[gamemap].numlaps
			mo.fuse = max(12*TICRATE, (60-(10*numlaps))*TICRATE)
		end

		if mo.fuse then
			mo.flags2 = (mo.fuse <= 5*TICRATE and leveltime % 2) and $ + MF2_DONTDRAW or $ & ~(MF2_DONTDRAW)
		end
	end, MT_FLOATINGXITEM)

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)