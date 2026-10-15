local _, TTD = ...

-- Shared addon namespace; transient party state is never persisted.
TTD.State = { members = {}, statuses = {}, ready = false }

function TTD.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc89b62Travel to Dungeon:|r " .. message)
end

function TTD.IsRaid()
    if IsInRaid then return IsInRaid() end
    return GetNumRaidMembers and GetNumRaidMembers() > 0
end

function TTD.PartyCount()
    if GetNumSubgroupMembers then return GetNumSubgroupMembers() end
    return GetNumPartyMembers and GetNumPartyMembers() or 0
end

function TTD.InCombat()
    return InCombatLockdown and InCombatLockdown()
end

