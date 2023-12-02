local XITEMDISABLER_VERSION = 10

-- avoid redefiniton on updates
if timetravel.XITEMDISABLER_VERSION == nil or timetravel.XITEMDISABLER_VERSION < XITEMDISABLER_VERSION then

rawset(_G, "chronoshift_xitem_alwayson", CV_RegisterVar({
	name = "chronoshift_xitem_alwayson",
	defaultvalue = timetravel.defaultXItemEnabledValue,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
}))

local obtainedReferences = false
local usingXItem = false
local stub = function() end

local defXitem_playerThinker
local defXitem_playerCmdHook
local defXitem_floatingItemThinker
local defXitem_floatingItemSpecial
local defXitem_itemBoxSpecial
local defXitem_floatingXItemThinker
local defXitem_floatingXItemSpecial
local defXitem_playerArrowThinker
local defXitem_vanillaArrowThinker
local defXitem_hudMain

local function storeReferences()
	defXitem_playerThinker = xItemLib.func.playerThinker
	defXitem_playerCmdHook = xItemLib.func.playerCmdHook
	defXitem_floatingItemThinker = xItemLib.func.floatingItemThinker
	defXitem_floatingItemSpecial = xItemLib.func.floatingItemSpecial
	defXitem_itemBoxSpecial = xItemLib.func.itemBoxSpecial
	defXitem_floatingXItemThinker = xItemLib.func.floatingXItemThinker
	defXitem_floatingXItemSpecial = xItemLib.func.floatingXItemSpecial
	defXitem_playerArrowThinker = xItemLib.func.playerArrowThinker
	defXitem_vanillaArrowThinker = xItemLib.func.vanillaArrowThinker
	defXitem_hudMain = xItemLib.func.hudMain
	obtainedReferences = true
end

local function enableXItem()
	xItemLib.func.playerThinker = defXitem_playerThinker
	xItemLib.func.playerCmdHook = defXitem_playerCmdHook
	xItemLib.func.floatingItemThinker = defXitem_floatingItemThinker
	xItemLib.func.floatingItemSpecial = defXitem_floatingItemSpecial
	xItemLib.func.itemBoxSpecial = defXitem_itemBoxSpecial
	xItemLib.func.floatingXItemThinker = defXitem_floatingXItemThinker
	xItemLib.func.floatingXItemSpecial = defXitem_floatingXItemSpecial
	xItemLib.func.playerArrowThinker = defXitem_playerArrowThinker
	xItemLib.func.vanillaArrowThinker = defXitem_vanillaArrowThinker
	xItemLib.func.hudMain = defXitem_hudMain
	usingXItem = true
end

local function disableXItem()
	xItemLib.func.playerThinker = stub
	xItemLib.func.playerCmdHook = stub
	xItemLib.func.floatingItemThinker = stub
	xItemLib.func.floatingItemSpecial = stub
	xItemLib.func.itemBoxSpecial = stub
	xItemLib.func.floatingXItemThinker = stub
	xItemLib.func.floatingXItemSpecial = stub
	xItemLib.func.playerArrowThinker = stub
	xItemLib.func.vanillaArrowThinker = stub
	xItemLib.func.hudMain = stub
	hud.enable("item")
	usingXItem = false
end

timetravel.xitemEnablerHandler = function()
	if timetravel.XITEMDISABLER_VERSION > XITEMDISABLER_VERSION then return end
	if not (xItemLib and xItemLib.func) then return end
	if not obtainedReferences then storeReferences() end
	
	if chronoshift_xitem_alwayson.value then
		if not usingXItem then enableXItem() end
		return
	end
	
	if timetravel.isActive then enableXItem() else disableXItem() end
end

timetravel.xitemRestoreItemsToDefaults = function(mobj)
	if timetravel.XITEMDISABLER_VERSION > XITEMDISABLER_VERSION then return end
	if not (xItemLib and xItemLib.func) then return end
	if usingXItem then return end
	if not floatingitemspawner then return end
	
	-- Lua hot potato
	if mobj and mobj.valid and mobj.spawnedbyspawner then mobj.type = MT_FLOATINGITEM end
end

addHook("MobjThinker", function(mo) timetravel.xitemRestoreItemsToDefaults(mo) end, MT_FLOATINGXITEM)
addHook("MapChange", function() timetravel.xitemEnablerHandler() end)
addHook("NetVars", function() timetravel.xitemEnablerHandler() end)

timetravel.XITEMDISABLER_VERSION = XITEMDISABLER_VERSION

end