local COMBIINTEROP_VERSION = 10

-- avoid redefiniton on updates
if timetravel.COMBIINTEROP_VERSION == nil or timetravel.COMBIINTEROP_VERSION < COMBIINTEROP_VERSION then

local NONE = 0
local FICKLE = 1
local HAYA = 2
local combiInteropType = NONE

local combiCvar = nil
local hCombiCvar = nil

-- This is so derranged... I have to make compatibility for two of them?
timetravel.combiInit = function()
	if timetravel.COMBIINTEROP_VERSION > COMBIINTEROP_VERSION then return end

	-- Oh boy. Which is it?
	if not combiCvar then combiCvar = CV_FindVar("combi_active") end
	if not hCombiCvar then hCombiCvar = CV_FindVar("combi_teleportspoof") end
	
	if combiCvar and combiCvar.value > 0 then
		if hCombiCvar then
			combiInteropType = HAYA
		else
			combiInteropType = FICKLE
		end
	else
		combiInteropType = NONE
	end
end

addHook("PlayerSpawn", function(player) -- Restore time warp status to mo.
	if timetravel.COMBIINTEROP_VERSION > COMBIINTEROP_VERSION then return end
	if not timetravel.isActive then return end
	if combiInteropType == NONE then return end
	if not (player.mo and player.mo.valid) then return end
	if not player.mo.timetravel then return end
	
	if combiInteropType == FICKLE then
		if not (player.combi and player.combi.mo and player.combi.mo.valid) then return end
	
		if player.combi.valid == true then
			if player.kartstuff[k_respawn] > 0 and player.combi.kartstuff[k_respawn] > 0 then
				player.mo.timetravel.isTimeWarped = player.timetravelconsts.starpostStatus or false
				player.combi.mo.timetravel.isTimeWarped = player.timetravelconsts.starpostStatus or false
			else
				player.mo.timetravel.isTimeWarped = player.combi.mo.timetravel.isTimeWarped
			end
		elseif player.combi.valid == "uwu" then 
			if player.combi.mo.timetravel == nil then
				player.combi.mo.timetravel = {}
			end
			player.combi.mo.timetravel.isTimeWarped = player.mo.timetravel.isTimeWarped
		end
		
	elseif combiInteropType == HAYA then
		if player.has_partner then -- Connected to a player.
			if player.combi == nil then return end
			local partner = players[player.combi]
			
			if not (partner and partner.mo and partner.valid) then return end
			if player.kartstuff[k_respawn] > 0 and partner.kartstuff[k_respawn] > 0 then
				player.mo.timetravel.isTimeWarped = player.timetravelconsts.starpostStatus or false
				partner.mo.timetravel.isTimeWarped = player.timetravelconsts.starpostStatus or false
			else
				player.mo.timetravel.isTimeWarped = partner.mo.timetravel.isTimeWarped
			end		
		else -- Connected to the dreaded gargoyle of doom.
			local gargoyle = player.gargoyle
			if not (gargoyle and gargoyle.valid) then return end
		
			if gargoyle.timetravel == nil then gargoyle.timetravel = {} end
			gargoyle.timetravel.isTimeWarped = player.mo.timetravel.isTimeWarped
		end
	end

end)

timetravel.addTimeTravelHook(function(mo)
	if combiInteropType == NONE then return end
	
	local player = mo.player
	if not (player and player.valid) then return end
	
	local combiPartner = nil
	
	if combiInteropType == FICKLE then
		if not (player.combi and player.combi.mo and player.combi.mo.valid) then return end
		
		combiPartner = player.combi.mo
	
		if combiPartner.type == MT_GARGOYLE then
			if combiPartner.timetravel == nil then
				combiPartner.timetravel = {}
				combiPartner.timetravel.isTimeWarped = mo.timetravel.isTimeWarped
			end
		end
	elseif combiInteropType == HAYA then
		local playerPartner = nil
		if player.combi ~= nil then
			local partner = players[player.combi]
			if not (partner and partner.mo and partner.valid) then return end
			playerPartner = partner.mo
		end
		combiPartner = playerPartner or player.gargoyle
		
		if combiPartner == player.gargoyle and player.gargoyle.timetravel == nil then
			combiPartner.timetravel = {}
			combiPartner.timetravel.isTimeWarped = mo.timetravel.isTimeWarped
		end
	end
	
	if combiPartner ~= nil then
		timetravel.teleport(combiPartner, true)
		timetravel.createSparkles(combiPartner)
	end
end)

timetravel.COMBIINTEROP_VERSION = COMBIINTEROP_VERSION

end