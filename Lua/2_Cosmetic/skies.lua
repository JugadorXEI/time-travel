local SKIES_VERSION = 1

-- avoid redefiniton on updates
if timetravel.SKIES_VERSION == nil or timetravel.SKIES_VERSION < SKIES_VERSION then

local SecondMapSkyNumString = "tt_2ndmapskynum"
local SecondMapSkyboxIdString = "tt_2ndmapskyboxid"

local inOtherZone = nil

local MT_SKYBOX = 780

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
	
	for i = 0, 3 do
		local player = displayplayers[i]
		if player == nil then return end
		if player.mo == nil or player.mo.valid == false then return end
		if player.mo.timetravel == nil then return end
		if player.mo.timetravel.isTimeWarped == nil then return end
		if player.mo.timetravel.isTimeWarped == inOtherZone then return end
		
		if player.mo.timetravel.isTimeWarped then
			P_SetupLevelSky(secondMapSkyNum, consoleplayer)
			P_SetSkyboxMobj(secondMapSkyboxMobj, consoleplayer)
		else
			P_SetupLevelSky(firstMapSkyNum, consoleplayer)
			P_SetSkyboxMobj(firstMapSkyboxMobj, consoleplayer)
		end
		
		inOtherZone = player.mo.timetravel.isTimeWarped
	end
end)

local function init()
	if timetravel.SKIES_VERSION > SKIES_VERSION then return end
	if not timetravel.isActive then return end

	inOtherZone = nil
	firstMapSkyNum = 0
	firstMapSkyboxNum = 0
	firstMapSkyboxMobj = nil
	secondMapSkyNum = 0
	secondMapSkyboxNum = 0
	secondMapSkyboxMobj = nil

	local has2ndSkyIdSet = mapheaderinfo[gamemap][SecondMapSkyNumString] ~= nil
	local has2ndSkyboxIdSet = mapheaderinfo[gamemap][SecondMapSkyboxIdString] ~= nil

	if not has2ndSkyIdSet and not has2ndSkyboxIdSet then
		enabled = false
	else
		enabled = true
		
		firstMapSkyNum = mapheaderinfo[gamemap].skynum
		firstMapSkyboxNum = 0 -- if someone changes their skybox on the very first frame i'd be surprised.
		if has2ndSkyIdSet then secondMapSkyNum = tonumber(mapheaderinfo[gamemap][SecondMapSkyNumString]) end
		if has2ndSkyboxIdSet then secondMapSkyboxNum = tonumber(mapheaderinfo[gamemap][SecondMapSkyboxIdString]) end
		
		for thing in mapthings.iterate do
			if thing.type ~= MT_SKYBOX then continue end
			-- print(thing.extrainfo)
			if thing.extrainfo == firstMapSkyboxNum then
				firstMapSkyboxMobj = thing.mobj
			elseif thing.extrainfo == secondMapSkyboxNum then
				secondMapSkyboxMobj = thing.mobj
			end
		end
	end
end

addHook("MapLoad", init)
addHook("NetVars", init)

timetravel.SKIES_VERSION = SKIES_VERSION

end