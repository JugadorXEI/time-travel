local XITEM_SANITY_SCRIPT_VERSION = 10

-- avoid redefiniton on updates
if timetravel.XITEM_SANITY_SCRIPT_VERSION == nil or timetravel.XITEM_SANITY_SCRIPT_VERSION < XITEM_SANITY_SCRIPT_VERSION then

-- Intended to fix the edge case where people *will* load xItem before this.
-- This will keep xItem enabled in the xItemDisabler.lua.
if xItemLib and xItemLib.func then
	timetravel.defaultXItemEnabledValue = "On"
else
	timetravel.defaultXItemEnabledValue = "Off"
end

timetravel.XITEM_SANITY_SCRIPT_VERSION = XITEM_SANITY_SCRIPT_VERSION

end