local VERSION = 11

if minimaplib == nil then
	rawset(_G, "minimaplib", {})
end

-- avoid redefiniton on updates
if minimaplib.VERSION == nil or minimaplib.VERSION < VERSION then

local TICRATE = TICRATE
local hyudorotime = 7*TICRATE
local FF_TRANSSHIFT = FF_TRANSSHIFT
local TC_RAINBOW = TC_RAINBOW
local TC_BOSS = TC_BOSS
local FRACUNIT = FRACUNIT
local FRACBITS = FRACBITS
local SKINCOLOR_CSUPER5 = SKINCOLOR_CSUPER5
local V_FLIP = V_FLIP
local V_HUDTRANSHALF = V_HUDTRANSHALF
local V_HUDTRANS = V_HUDTRANS
local k_position = k_position
local k_bumper = k_bumper
local k_hyudorotimer = k_hyudorotimer

local CV_FindVar = CV_FindVar
local FixedDiv = FixedDiv
local FixedMul = FixedMul
local K_IsPlayerWanted = K_IsPlayerWanted
local min = min
local table_insert = table.insert

local areHUDfunctionsLocalized = false
local hudEnable = hud.enable
local hudEnabled = hud.enabled
local hudDisable = hud.disable
local hudAdd = hud.add
local hudCachePatch = nil
local hudDraw = nil
local hudDrawScaled = nil
local hudPatchExists = nil
local hudGetColormap = nil

local kp_wantedreticle = nil
local cachedPatches = {}

local BASEVIDWIDTH = 320
local BASEVIDHEIGHT = 200

local minX = 0
local maxX = 0
local minY = 0
local maxY = 0

local mapWidth = 0
local mapHeight = 0

local xOffset = 0
local yOffset = 0

local minimapPatchString = nil
local headhooks = {}

local function turnCommaDelimitedStringIntoTable(string)
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
		table_insert(tableVar, newString);
		numThingsAdded = $ + 1
	end

	return tableVar, numThingsAdded
end

local function localizeHUDfunctions(v)
	hudCachePatch = v.cachePatch
	hudDraw = v.draw
	hudDrawScaled = v.drawScaled
	hudPatchExists = v.patchExists
	hudGetColormap = v.getColormap
	kp_wantedreticle = hudCachePatch("MMAPWANT")
	areHUDfunctionsLocalized = true
end

local function cacheThenStorePatch(patch)
	cachedPatches[patch] = hudCachePatch(patch)
	return cachedPatches[patch]
end

local function getOrCachePatch(patch)
	return cachedPatches[patch] or cacheThenStorePatch(patch)
end

minimaplib.isMinimapLibActive = false

minimaplib.setMinimapPatchByString = function(minimapPatchName)
	minimapPatchString = minimapPatchName
end

minimaplib.getMinimapPatchString = function()
	return minimapPatchString
end

minimaplib.addHeadHook = function(func)
	table_insert(headhooks, func)
end

local function handleHeadHooks(v, mo, moX, moY, flags, scale, patch, colormap)

	local moX2, moY2, flags2, scale2, patch2, colormap2
	for i = 1, #headhooks do
		moX2, moY2, flags2, scale2, patch2, colormap2 = headhooks[i](v, mo, moX, moY, flags, scale, patch, colormap)
	end
	
	return (moX2 or moX), (moY2 or moY), (flags2 or flags), (scale2 or scale), (patch2 or patch), (colormap2 or colormap)
end

local function recalculateMinimapBoundaries_X()
	mapWidth = maxX - minX
	xOffset = (minX + mapWidth / 2) << FRACBITS
end

local function recalculateMinimapBoundaries_Y()
	mapHeight = maxY - minY
	yOffset = (minY + mapHeight / 2) << FRACBITS
end

local function recalculateMinimapBoundaries()
	recalculateMinimapBoundaries_X()
	recalculateMinimapBoundaries_Y()
end

minimaplib.changeMinimapBoundaries = function(_minX, _maxX, _minY, _maxY)
	minX = _minX
	maxX = _maxX
	minY = _minY
	maxY = _maxY

	if _minX ~= nil or _maxX ~= nil then recalculateMinimapBoundaries_X() end
	if _minY ~= nil or _maxY ~= nil then recalculateMinimapBoundaries_Y() end
end

minimaplib.setMapHeaderBoundaryChanges = function()
	local map_LLBounds = turnCommaDelimitedStringIntoTable(mapheaderinfo[gamemap]["mmlib_llbounds"])
	local map_URBounds = turnCommaDelimitedStringIntoTable(mapheaderinfo[gamemap]["mmlib_urbounds"])
	
	if #map_LLBounds == 0 or #map_URBounds == 0 then return false end
	minimaplib.changeMinimapBoundaries(map_LLBounds[1], map_URBounds[1], map_LLBounds[2], map_URBounds[2])
	return true
end

minimaplib.setMapHeaderMinimap = function()
	local minimapString = mapheaderinfo[gamemap]["mmlib_minimap"]
	if minimapString == nil or minimapString == "" then
		minimaplib.setMinimapPatchByString(G_BuildMapName(gamemap).."R")
		return false
	end
	
	minimaplib.setMinimapPatchByString(minimapString)
	return true
end

-- INTERNAL:
local function getMinimapPosition()
	local mm_x = BASEVIDWIDTH - 50
	local mm_y = (BASEVIDHEIGHT / 2) - 16
	
	if splitscreen then
		mm_y = BASEVIDHEIGHT / 2
		
		if splitscreen > 1 then
			mm_x = 3*BASEVIDWIDTH/4
			mm_y = 3*BASEVIDHEIGHT/4
			
			if splitscreen > 2 then
				mm_x = BASEVIDWIDTH/2
				mm_y = BASEVIDHEIGHT/2
			end
		end
	end
	
	return mm_x, mm_y
end

local function getMinimapTransparency()
	local trans = 0
	local leveltime = leveltime
	
	if leveltime > 105 then
		trans = CV_FindVar("kartminimap").value
		if leveltime <= 113 then
			trans = ((leveltime - 105) * $) / (113 - 105)
		end
	end
	
	return (10 - trans) << FF_TRANSSHIFT
end

local function drawPlayerMinimapHead(v, mo, x, y, flags, minimap, --[[OPTIONAL:]] scale, patch, colormap)
	if mo == nil then return end
	local moX = mo.x
	local moY = mo.y

	moX, moY, flags, scale, patch, colormap = handleHeadHooks(v, mo, moX, moY, flags, scale, patch, colormap)

	if scale == nil then
		scale = FRACUNIT
	end
	
	if patch == nil then -- assume this is a player.
		patch = getOrCachePatch(skins[mo.skin].facemmap)
	else 
		patch = getOrCachePatch(patch)
	end
	
	if patch == nil then return end
	
	local xScale = FixedDiv(minimap.width, mapWidth)
	local yScale = FixedDiv(minimap.height, mapHeight)
	local zoom = FixedMul(min(xScale, yScale), FRACUNIT - FRACUNIT / 20)

	local moXpos = (FixedMul(moX, zoom) - FixedMul(xOffset, zoom))
	local moYpos = -(FixedMul(moY, zoom) - FixedMul(yOffset, zoom))
	
	if encoremode then
		moXpos = -$
	end

	local minimapXPos	= moXpos + ((x + minimap.width  / 2 - (patch.width  / 2))<<FRACBITS)
	local minimapYPos 	= moYpos + ((y + minimap.height / 2 - (patch.height / 2))<<FRACBITS)
	
	if not mo.color then
		hudDrawScaled(minimapXPos, minimapYPos, scale, patch, flags)
	else
		local player = mo.player
		if colormap == nil then
			if mo.colorized then
				colormap = hudGetColormap(TC_RAINBOW, mo.color)
			else
				colormap = hudGetColormap(mo.skin, mo.color)
			end
		end

		hudDrawScaled(minimapXPos, minimapYPos, scale, patch, flags, colormap)
		
		-- if SPB-running or wanted, show it.
		if player and player.valid and (spbplace == player.kartstuff[k_position] or K_IsPlayerWanted(mo.player)) then
			hudDrawScaled(minimapXPos - (4<<FRACBITS), minimapYPos - (4<<FRACBITS), scale, kp_wantedreticle, flags)
		end
	end
end

local function minimapHook(v, stplyr, cam)
	if minimaplib.VERSION > VERSION then return end
	if leveltime <= 105 then return end
	if not minimaplib.isMinimapLibActive then return end
	if stplyr ~= displayplayers[0] then return end
	-- if stplyr.mo == nil or stplyr.spectator == true then return end
	if minimapPatchString == nil then return end
	if not areHUDfunctionsLocalized then localizeHUDfunctions(v) end
	if not hudPatchExists(minimapPatchString) then return end
	
	local minimap = hudCachePatch(minimapPatchString)
	
	local patchX, patchY = minimap.width, minimap.height
	local minimapX, minimapY = getMinimapPosition()
	minimapX = $ - (patchX / 2)
	minimapY = $ - (patchY / 2)
	-- print(minimapX.."x"..minimapY)
	
	local snaptype = V_SNAPTORIGHT
	if splitscreen == 3 then
		snaptype = 0
	end
	local minimapTrans = getMinimapTransparency()
	local minimapFlags = snaptype | minimapTrans
	
	local minimapColormap = hudGetColormap(TC_BOSS, leveltime % SKINCOLOR_CSUPER5)
	
	if encoremode then
		hudDraw(minimapX+patchX, minimapY, minimap, minimapFlags|V_FLIP)
	else
		hudDraw(minimapX, minimapY, minimap, minimapFlags)
	end
	
	-- Drawing the heads
	if not splitscreen == 2 then
		minimapFlags = $ & (~minimapTrans)
		minimapFlags = $ | V_HUDTRANSHALF
	end
	
	if encoremode then
		minimapX = $ + minimap.leftoffset
	else
		minimapX = $ - minimap.leftoffset
	end
	minimapY = $ - minimap.topoffset
	
	for player in players.iterate do
		local pMo = player.mo
		if not (pMo and pMo.valid) or player.spectator == true then continue end
		
		if player ~= displayplayers[0] or splitscreen then
			local pks = player.kartstuff
			if gametype == GT_MATCH and pks[k_bumper] <= 0 then continue end
			
			if pks[k_hyudorotimer] > 0 then
				if not ((pks[k_hyudorotimer] < 1 * TICRATE / 2 or
					pks[k_hyudorotimer] > hyudorotime - (1 * TICRATE / 2)) and
					leveltime & 1 == 0)
					
					continue
				end
			end
			
			for i = 0, splitscreen do
				if displayplayers[i] ~= nil and displayplayers[i] == player then continue end
			end

			drawPlayerMinimapHead(v, pMo, minimapX, minimapY, minimapFlags, minimap)
		end
	end
	
	-- Drawing opaque local heads
	minimapFlags = $ & (~V_HUDTRANSHALF)
	minimapFlags = $ | V_HUDTRANS
	
	for i = 0, splitscreen do
		-- print(displayplayers[i].name)
		drawPlayerMinimapHead(v, displayplayers[i].mo, minimapX, minimapY, minimapFlags, minimap)
	end
end
hudAdd(minimapHook, "game")

addHook("ThinkFrame", function()
	if minimaplib.VERSION > VERSION then return end
	if leveltime ~= 4 then return end

	minimaplib.isMinimapLibActive = false

	minX = 0
	maxX = 0
	minY = 0
	maxY = 0

	local customBoundaries = minimaplib.setMapHeaderBoundaryChanges()
	local customMinimap = minimaplib.setMapHeaderMinimap()

	if customBoundaries or customMinimap then
		minimaplib.isMinimapLibActive = true
		if hudEnabled("minimap") then
			hudDisable("minimap")
		end
	end

	if not minimaplib.isMinimapLibActive then
		if not hudEnabled("minimap") then
			hudEnable("minimap")
		end
		return
	end

	if not customBoundaries then
		for vertex in vertexes.iterate do
			local vX, vY = vertex.x, vertex.y
			
			if vX < minX then minX = vX
			elseif vX > maxX then maxX = vX
			end
			
			if vY < minY then minY = vY
			elseif vY > maxY then maxY = vY
			end
		end

		minX = $ >> FRACBITS
		maxX = $ >> FRACBITS
		recalculateMinimapBoundaries_X()
		minY = $ >> FRACBITS
		maxY = $ >> FRACBITS
		recalculateMinimapBoundaries_Y()
	end

end)

addHook("NetVars", function(network)
	if minimaplib.VERSION > VERSION then return end

	minimaplib.isMinimapLibActive = network(minimaplib.isMinimapLibActive)
	if minimaplib.isMinimapLibActive then
		hudDisable("minimap")
	else
		hudEnable("minimap")
	end
	minimapPatchString = network(minimapPatchString)
	minX = network(minX)
	maxX = network(maxX)
	minY = network(minY)
	maxY = network(maxY)
	mapWidth = network(mapWidth)
	mapHeight = network(mapHeight)
	xOffset = network(xOffset)
	yOffset = network(yOffset)
end)

minimaplib.VERSION = VERSION
end