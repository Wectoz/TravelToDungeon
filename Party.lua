local _, TTD = ...

-- Roster, check-ins, waiting timer, and party announcements.
local lastShare = -100

local function Clean(text)
    -- Keep outgoing chat plain and below the client message limit.
    return string.sub((text or ""):gsub("[|\r\n]", ""), 1, 120)
end

function TTD.Scan()
    -- Forever can restrict unit data during combat. Keep the last safe snapshot.
    if TTD.InCombat() then return end
    local current, present = {}, {}
    local count = TTD.IsRaid() and 0 or TTD.PartyCount()
    for i = 0, count do
        local unit = i == 0 and "player" or "party" .. i
        if UnitExists(unit) then
            local name, realm = UnitName(unit)
            local id = UnitGUID(unit)
            if name and id then
                local display = name .. (realm and realm ~= "" and "-" .. realm or "")
                current[#current + 1] = { id = id, name = display, unit = unit }
                present[id] = true
            end
        end
    end
    for id in pairs(TTD.State.statuses) do
        if not present[id] then TTD.State.statuses[id] = nil end
    end
    if #current > 1 and not TTD.State.started then TTD.State.started = GetTime() end
    if #current <= 1 then TTD.State.started = nil end
    TTD.State.members = current
    TTD.Refresh()
end

function TTD.Reset()
    if TTD.InCombat() then TTD.Print("Reset check-ins after combat."); return end
    TTD.State.statuses = {}
    TTD.State.started = #TTD.State.members > 1 and GetTime() or nil
    TTD.Refresh()
end

function TTD.Share()
    if TTD.InCombat() then TTD.Print("Share check-ins after combat."); return end
    TTD.Scan()
    if TTD.IsRaid() or TTD.PartyCount() == 0 then
        TTD.Print("Join a dungeon party before sharing.")
        return
    end
    local destination = Clean(TravelToDungeonDB.destination)
    if not destination:find("%S") then TTD.Print("Set a meeting point first."); return end
    if GetTime() - lastShare < 10 then TTD.Print("Please wait 10 seconds between announcements."); return end
    lastShare = GetTime()
    SendChatMessage("Travel to Dungeon: Meet at " .. destination, "PARTY")
    local note = Clean(TravelToDungeonDB.note)
    if note:find("%S") then SendChatMessage("Preparation: " .. note, "PARTY") end
    -- Separate bounded lines also accommodate realm-qualified player names.
    for _, member in ipairs(TTD.State.members) do
        SendChatMessage(Clean(member.name) .. ": " .. TTD.Data.states[TTD.State.statuses[member.id] or 1]
            .. (UnitIsConnected(member.unit) and "" or " (offline)"), "PARTY")
    end
    SendChatMessage("Check in: 1 = traveling, 2 = nearby, 3 = at entrance, 0 = not ready. Board owner records replies manually.", "PARTY")
end
