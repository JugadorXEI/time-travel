local SKIES_VERSION = 1

-- avoid redefiniton on updates
if timetravel.SKIES_VERSION == nil or timetravel.SKIES_VERSION < SKIES_VERSION then

local SecondMapSkyNumString = "tt_2ndmapskynum"
local SecondMapSkyboxIdString = "tt_2ndmapskyboxid"

local storedZone = nil

local MT_SKYBOX = 780
local tonumber = tonumber
local P_SetupLevelSky = P_SetupLevelSky
local P_SetSkyboxMobj = P_SetSkyboxMobj

local firstMapSkyNum = 0
local firstMapSkyboxNum = 0
local firstMapSkyboxMobj = nil
local secondMapSkyNum = 0
local secondMapSkyboxNum = 0
local secondMapSkyboxMobj = nil

local enabled = false

addHook("PostThinkFrame", function()	
	if enabled == false then return end
	if not consoleplayer then return end
	if leveltime < 2 then return end
	
	local player = displayplayers[0]
	if not player then return end
	
	local playerMo = player.mo
	if not (playerMo and playerMo.valid) then return end
	if not playerMo.timetravel or playerMo.timetravel.isTimeWarped == nil then return end
	
	local currentZone = playerMo.timetravel.isTimeWarped
	if currentZone == storedZone then return end
	
	if currentZone then
		P_SetupLevelSky(secondMapSkyNum, consoleplayer)
		P_SetSkyboxMobj(secondMapSkyboxMobj, consoleplayer)
	else
		P_SetupLevelSky(firstMapSkyNum, consoleplayer)
		P_SetSkyboxMobj(firstMapSkyboxMobj, consoleplayer)
	end
	
	storedZone = currentZone
end)

local function init()
	if timetravel.SKIES_VERSION > SKIES_VERSION then return end
	if not timetravel.isActive then return end

	storedZone = nil
	firstMapSkyNum = 0
	firstMapSkyboxNum = 0
	firstMapSkyboxMobj = nil
	secondMapSkyNum = 0
	secondMapSkyboxNum = 0
	secondMapSkyboxMobj = nil

	local mapheader = mapheaderinfo[gamemap]
	local has2ndSkyIdSet = mapheader[SecondMapSkyNumString] ~= nil
	local has2ndSkyboxIdSet = mapheader[SecondMapSkyboxIdString] ~= nil

	if not has2ndSkyIdSet and not has2ndSkyboxIdSet then
		enabled = false
	else
		enabled = true
		
		firstMapSkyNum = mapheader.skynum
		firstMapSkyboxNum = 0 -- if someone changes their skybox on the very first frame i'd be surprised.
		if has2ndSkyIdSet then secondMapSkyNum = tonumber(mapheader[SecondMapSkyNumString]) end
		if has2ndSkyboxIdSet then secondMapSkyboxNum = tonumber(mapheader[SecondMapSkyboxIdString]) end
		
		for thing in mapthings.iterate do
			if thing.type ~= MT_SKYBOX then continue end

			local extrainfo = thing.extrainfo
			if extrainfo == firstMapSkyboxNum then
				firstMapSkyboxMobj = thing.mobj
			elseif extrainfo == secondMapSkyboxNum then
				secondMapSkyboxMobj = thing.mobj
			end
		end
	end
end

addHook("MapLoad", init)
addHook("NetVars", init)

timetravel.SKIES_VERSION = SKIES_VERSION

end