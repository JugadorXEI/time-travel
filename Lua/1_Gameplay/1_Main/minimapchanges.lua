local HUDCHANGES_VERSION = 1

-- avoid redefiniton on updates
if timetravel.HUDCHANGES_VERSION == nil or timetravel.HUDCHANGES_VERSION < HUDCHANGES_VERSION then

local TICRATE = TICRATE
local G_BuildMapName = G_BuildMapName

local minimapName = "UNKNWN"
local minimapReverseName = "UNKNWN"

timetravel.hudInit = function()
	if timetravel.HUDCHANGES_VERSION > HUDCHANGES_VERSION then return end

	minimapName = G_BuildMapName().."R"
	minimapReverseName = G_BuildMapName().."RI"
end

timetravel.hudMinimapThinker = function()
	if timetravel.HUDCHANGES_VERSION > HUDCHANGES_VERSION then return end

	if not minimaplib.isMinimapLibActive then return end
	if consoleplayer == nil then return end
	
	local firstDisplayPlayerMo = displayplayers[0].mo
	if firstDisplayPlayerMo and firstDisplayPlayerMo.valid and 
		firstDisplayPlayerMo.timetravel and firstDisplayPlayerMo.timetravel.isTimeWarped then
		
		local patchString = minimaplib.getMinimapPatchString()
		
		if patchString ~= minimapReverseName then
			minimaplib.setMinimapPatchByString(minimapReverseName)
		end
	else
		if patchString ~= minimapName then
			minimaplib.setMinimapPatchByString(minimapName)
		end
	end
end

local function headPositionModify(v, mo, moX, moY, flags, scale, patch, colormap)
	if not timetravel.isActive then return end
	if not (mo and mo.valid) then return end
	
	if mo.timetravel.isTimeWarped then
		moX = $ - timetravel.localXdist
		moY = $ - timetravel.localYdist
	end
	
	-- Head icons flicker when other players are on a different timeline than the display player.
	-- This happens every second for 3 tics. Only 1P splitscreen compatibility as it'd be waaay too messy otherwise.
	if leveltime % TICRATE <= 2 then
		local P1 = displayplayers[0]
		local P1mo = P1.mo
		if P1 and P1mo and P1mo.valid and P1mo ~= mo then
			local status = P1mo.timetravel.isTimeWarped
			if status ~= mo.timetravel.isTimeWarped then
				local color = mo.color
				if mo.player then color = mo.player.skincolor end
				colormap = v.getColormap(TC_BLINK, color)
			end
		end
	end
	
	return moX, moY, flags, scale, patch, colormap
end
minimaplib.addHeadHook(headPositionModify)

addHook("NetVars", function(network)
	if timetravel.HUDCHANGES_VERSION > HUDCHANGES_VERSION then return end
	if not timetravel.isActive then return end
	
	minimapName = network($)
	minimapReverseName = network($)
end)

timetravel.HUDCHANGES_VERSION = HUDCHANGES_VERSION

end