local _, TTD = ...

-- Startup, saved settings, events, and slash commands.
local addon = CreateFrame("Frame")

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent(GetNumSubgroupMembers and "GROUP_ROSTER_UPDATE" or "PARTY_MEMBERS_CHANGED")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        TTD.HideBoard()
        return
    end
    if event == "PLAYER_LOGIN" then
        if type(TravelToDungeonDB) ~= "table" then TravelToDungeonDB = {} end
        for _, field in ipairs({ "destination", "note" }) do
            if type(TravelToDungeonDB[field]) ~= "string" then TravelToDungeonDB[field] = "" end
        end
        TravelToDungeonDB.departure = nil
        -- Migrate old preset-generated text once; retain user-written notes.
        if not TravelToDungeonDB.simpleMeetingPoint then
            for _, preset in ipairs(TTD.Data.presets) do
                if TravelToDungeonDB.destination == preset[1] .. " - " .. preset[2] then
                    TravelToDungeonDB.destination = preset[1]
                end
                if TravelToDungeonDB.note == preset[3] then TravelToDungeonDB.note = "" end
            end
            TravelToDungeonDB.simpleMeetingPoint = true
        end
        for _, field in ipairs({ "x", "y" }) do
            if type(TravelToDungeonDB[field]) ~= "number" then TravelToDungeonDB[field] = 0 end
        end
        TTD.CreateBoard()
        TTD.State.ready = true
        TTD.Print("Loaded. Use /traveltodungeon or /ttd to open your meeting board.")
    end
    if TTD.State.ready then TTD.Scan(); TTD.AttachDungeonButton() end
end)

local elapsed = 0
addon:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        if TTD.State.ready then TTD.Scan(); TTD.AttachDungeonButton() end
    end
end)

SLASH_TRAVELTODUNGEON1 = "/traveltodungeon"
SLASH_TRAVELTODUNGEON2 = "/ttd"
SlashCmdList.TRAVELTODUNGEON = function(command)
    if not TTD.State.ready then return end
    command = (command or ""):lower():match("^%s*(.-)%s*$")
    if command == "share" then TTD.Share()
    elseif command == "reset" then TTD.Reset()
    elseif command == "help" then TTD.Print("/ttd: toggle board; /ttd share: announce; /ttd reset: clear check-ins. Click statuses to cycle. Replies are recorded manually.")
    else
        TTD.ToggleBoard()
    end
end
