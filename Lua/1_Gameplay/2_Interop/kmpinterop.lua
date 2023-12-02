local KMPINTEROP_VERSION = 10

-- avoid redefiniton on updates
if timetravel.KMPINTEROP_VERSION == nil or timetravel.KMPINTEROP_VERSION < KMPINTEROP_VERSION then

-- kmp_respawnpoints is rawset'D thus freely accessible without FindVar'ing it.

-- Prevent latpoints from utterly breaking the gimmick.
addHook("MobjDeath", function(mobj)
	if timetravel.KMPINTEROP_VERSION > KMPINTEROP_VERSION then return end
	if not timetravel.isActive then return end
	if not (kmp_respawnpoints and kmp_respawnpoints.value) then return end
	
	local player = mobj.player
	if not (mobj and player and not player.spectator) then return end
	
	if player.kmp_respawn then player.kmp_respawn = nil end
end, MT_PLAYER)

-- Prevent the never ending spawning gargoyles from killing the framerate.
addHook("MobjThinker", function(gargoyle)
	if timetravel.KMPINTEROP_VERSION > KMPINTEROP_VERSION then return end
	if not timetravel.isActive then return end
	if not (kmp_respawnpoints and kmp_respawnpoints.value) then return end
	
	if gargoyle.flags & MF_RUNSPAWNFUNC and gargoyle.flags2 & MF2_DONTDRAW then
		P_RemoveMobj(gargoyle) -- Go away.
	end	
end, MT_GARGOYLE)

timetravel.KMPINTEROP_VERSION = KMPINTEROP_VERSION

end