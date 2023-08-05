-- The optimization momento certificado.
local k_itemheld = k_itemheld
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
-- No more opti.

local xitemHooked = false

local function handleItemCollision(thing, tmthing)
	if not (thing and thing.valid and tmthing and tmthing.valid and tmthing.player) then return nil end -- Lua hot potato moment
	if not thing.spawnedbyspawner then return nil end -- Only kick in if floating item spawner is loaded + item is from spawner.
	if not thing.limitpickup then return nil end -- The bug we're trying to fix is from pickup limiting, don't run this if not the case.
	
	local pks = tmthing.player.kartstuff
	-- We only want to limit pickups if the player's not dragging anything, it's the same type of item and we have some of it.
	if not (not pks[k_itemheld] and pks[k_itemtype] == thing.threshold and pks[k_itemamount] > 0) then return nil end

	-- Don't run the collision hook if we'd be picking more than we have, d'uh.
	if pks[k_itemamount] >= thing.movecount then return false end
end

local function xitemHandler()
	if xitemHooked then return end
	if not floatingitemspawner then return end -- Don't kick in if this script isn't loaded
	if not (xItemLib and xItemLib.func) then return end

	addHook("MobjCollide", handleItemCollision, MT_FLOATINGXITEM)
	addHook("MobjMoveCollide", handleItemCollision, MT_FLOATINGXITEM)

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)