-- The optimization momento certificado.
local KITEM_SNEAKER = KITEM_SNEAKER
local TICRATE = TICRATE
local k_itemblink = k_itemblink
local k_itemamount = k_itemamount
local min = min
-- No more opti.

local xitemHooked = false

local VERSION = 2
local JB_NAMESPACE = "JUICEBOX"

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[JB_NAMESPACE] and modData[JB_NAMESPACE].defDat.ver <= VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(JB_NAMESPACE, "Juicebox", 
	{
		lib = "By Tyron - XItem interop by JugadorXEI",
		ver = VERSION,
		-- Fixes XItem stealing the Player Arrow references creating an infinite loop when Juicebox loads them back.
		playerArrowSpawn = function(arrowMo, playerMo)
			if G_BattleGametype() then return end
			if not (JUICEBOX and JUICEBOX.value) then return end
			local player = playerMo.player
			if not player then return end
			
			local f = P_SpawnMobj(arrowMo.x, arrowMo.y, arrowMo.z, MT_XITEMPLAYERARROW)
			f.threshold = arrowMo.threshold
			f.movecount = arrowMo.movecount
			f.flags = arrowMo.flags
			f.flags2 = arrowMo.flags2
			f.target = arrowMo.target
			f.scale = arrowMo.scale
			f.destscale = arrowMo.destscale
			f.state = arrowMo.state	
			player.JBspy = f
			
			-- P_KillMobj(arrowMo) -- Let the hook handle this.
			-- This results in two MT_XITEMPLAYERARROWs being created but fuck it we ball.
			return true
		end,
		-- Fixes Juicebox balance not giving two sneakers when triples were rolled.
		getfunc = function(player, item)
			if G_BattleGametype() then return end
			if not (JUICEBOX and JUICEBOX.value) then return end
			if item ~= KITEM_SNEAKER then return end
			local pks = player.kartstuff
			-- Only for getting items through roulette, dropped/debug items are fine.
			if pks[k_itemblink] ~= TICRATE and (xItemLib.toggles.debugItem and xItemLib.toggles.debugItem <= 0) then return end 
			pks[k_itemamount] = min(2, $)
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)