local ECHOES_ACTIONS_VERSION = 10

-- avoid redefiniton on updates
if timetravel.ECHOES_ACTIONS_VERSION == nil or timetravel.ECHOES_ACTIONS_VERSION < ECHOES_ACTIONS_VERSION then

local MF2_FIRING = MF2_FIRING
local MF2_SUPERFIRE = MF2_SUPERFIRE
local S_StartSound = S_StartSound
local sfx_mario2 = sfx_mario2

-- Action overrides for sounds.
function A_PlaySound(actor, var1, var2)
	if leveltime < 2 then return end
	if not var1 then return end
	
	local soundTarget = nil
	if var2 then soundTarget = actor end
	S_StartSound(soundTarget, var1)

	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	if var2 then S_StartSound(linkedItem, var1) end
end

function A_Pain(actor, var1, var2)
	local painSound = actor.info.painsound
	
	actor.flags2 = $ & (~MF2_FIRING)
	actor.flags2 = $ & (~MF2_SUPERFIRE)

	if not painSound then return end
	S_StartSound(actor, painSound)

	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	S_StartSound(linkedItem, painSound)
end

function A_PlayActiveSound(actor, var1, var2)
	local activeSound = actor.info.activesound
	if not activeSound then return end
	
	S_StartSound(actor, activeSound)
	
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	S_StartSound(linkedItem, activeSound)
end

function A_PlayAttackSound(actor, var1, var2)
	local attackSound = actor.info.attacksound
	if not attackSound then return end
	
	S_StartSound(actor, attackSound)
	
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	S_StartSound(linkedItem, attackSound)
end

function A_PlaySeeSound(actor, var1, var2)
	local seeSound = actor.info.seesound
	if not seeSound then return end
	
	S_StartSound(actor, seeSound)
	
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	S_StartSound(linkedItem, seeSound)
end

function A_Scream(actor, var1, var2)
	local screamSound = nil

	local deathSound = actor.info.deathsound
	local tracerType = nil
	if actor.tracer then tracerType = actor.tracer.type end
	
	if tracerType == MT_SHELL or tracerType == MT_FIREBALL then screamSound = sfx_mario2
	elseif deathSound then screamSound = deathSound end
	
	if not screamSound then return end
	S_StartSound(actor, screamSound)
	
	if not timetravel.isActive then return end
	
	local linkedItem = actor.linkedItem
	if linkedItem == nil then return end
	
	S_StartSound(actor, screamSound)
end
-- End.

timetravel.ECHOES_ACTIONS_VERSION = ECHOES_ACTIONS_VERSION

end