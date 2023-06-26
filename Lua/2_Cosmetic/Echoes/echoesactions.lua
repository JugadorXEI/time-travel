local ECHOES_ACTIONS_VERSION = 1

-- avoid redefiniton on updates
if timetravel.ECHOES_ACTIONS_VERSION == nil or timetravel.ECHOES_ACTIONS_VERSION < ECHOES_ACTIONS_VERSION then

-- Action overrides for sounds.
function A_PlaySound(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if leveltime < 2 and var2 >> 16 then return end
	local whichOne = linkedItem
	if not (var2 & 65535) then whichOne = nil end

	S_StartSound(whichOne, var1)
end

function A_Pain(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if actor.info.painsound then
		S_StartSound(linkedItem, actor.info.painsound)
	end
end

function A_PlayActiveSound(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if actor.info.activesound then
		S_StartSound(linkedItem, actor.info.activesound)
	end
end

function A_PlayAttackSound(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if actor.info.attacksound then
		S_StartSound(linkedItem, actor.info.attacksound)
	end
end

function A_PlaySeeSound(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if actor.info.seesound then
		S_StartSound(linkedItem, actor.info.seesound)
	end
end

function A_Scream(actor, var1, var2)
	super(actor, var1, var2)
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if actor.tracer and (actor.tracer.type == MT_SHELL or actor.tracer.type == MT_FIREBALL) then
		S_StartSound(linkedItem, sfx_mario2)
	elseif actor.info.deathsound then
		S_StartSound(linkedItem, actor.info.deathsound)
	end
end
-- End.

timetravel.ECHOES_ACTIONS_VERSION = ECHOES_ACTIONS_VERSION

end