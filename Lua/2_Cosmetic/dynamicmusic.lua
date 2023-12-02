local DYNMUS_VERSION = 10

-- avoid redefiniton on updates
if timetravel.DYNMUS_VERSION == nil or timetravel.DYNMUS_VERSION < DYNMUS_VERSION then

local TICRATE = TICRATE
local starttime = 6*TICRATE + 3*TICRATE/4
local S_MusicName = S_MusicName
local S_GetMusicPosition = S_GetMusicPosition

local inOtherZone = nil

local pastMusic = nil
local futureMusic = nil

timetravel.dynMusInit = function()
	if timetravel.DYNMUS_VERSION > DYNMUS_VERSION then return end
	-- Only care about the first display player here.
	local mapheaders = mapheaderinfo[gamemap]
	
	pastMusic = mapheaders.musname
	futureMusic = mapheaders.musname_future
	inOtherZone = nil
end

timetravel.dynMusThinker = function()
	if timetravel.DYNMUS_VERSION > DYNMUS_VERSION then return end
	if leveltime < (starttime + (TICRATE/2)) then return end
	if pastMusic == nil or futureMusic == nil then return end
	if consoleplayer ~= nil and consoleplayer.exiting > 0 then return end
	
	local player = displayplayers[0]
	local musname = S_MusicName()
	
	if musname ~= pastMusic and musname ~= futureMusic or -- Don't override invincibility music, grow music or other mods' music
		not (player and player.mo and player.mo.timetravel and player.mo.timetravel.isTimeWarped ~= nil) then
		inOtherZone = nil
		return
	end
	-- Finally don't constantly change the music if we're on the same timeline as before the last tic.
	if player.mo.timetravel.isTimeWarped == inOtherZone then return end	
	inOtherZone = player.mo.timetravel.isTimeWarped
	
	if player.mo.timetravel.isTimeWarped then
		S_ChangeMusic(futureMusic, true, consoleplayer, 0, S_GetMusicPosition())
	else
		S_ChangeMusic(pastMusic, true, consoleplayer, 0, S_GetMusicPosition())
	end
end

-- You need a music hook to prevent the game to reset to the default music on death.
addHook("MusicChange", function(oldname, newname)
	if timetravel.DYNMUS_VERSION > DYNMUS_VERSION then return end
	if not timetravel.isActive then return end
	if leveltime < (starttime + (TICRATE/2)) then return end
	if pastMusic == nil or futureMusic == nil then return end
	if inOtherZone == nil then return end
	
	if (inOtherZone == true and newname == pastMusic) then
		return true -- Don't do this, let the hook above change the music as needed.
	end
end)

addHook("NetVars", function(network)
	pastMusic = network(pastMusic)
	futureMusic = network(futureMusic)
end)

timetravel.DYNMUS_VERSION = DYNMUS_VERSION

end