local _, TTD = ...

-- Window layout, bronze controls, and rendering.
local board, destinationBox, noteBox, summary, timerLabel
local rows = {}
local refreshDungeons, dungeonPanel, selectedLabel

local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local function Bronze(frame, background)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(background or .055, .055, .06, 1)
    frame:SetBackdropBorderColor(.65, .43, .22, 1)
end

local function Label(parent, text, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(.90, .76, .55)
    return label
end

local function Button(parent, text, x, y, width, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetNormalFontObject(GameFontNormal)
    button:SetHighlightFontObject(GameFontHighlight)
    button:SetText(text)
    button:GetFontString():SetTextColor(.95, .79, .53)
    button:SetScript("OnClick", action)
    return button
end

local function Input(parent, y, limit, field)
    local box = CreateFrame("EditBox", nil, parent, backdropTemplate)
    Bronze(box)
    box:SetFontObject(GameFontHighlight)
    box:SetTextColor(.96, .87, .72)
    box:SetTextInsets(7, 7, 0, 0)
    box:SetSize(368, 22)
    box:SetPoint("TOPLEFT", 26, y)
    box:SetAutoFocus(false)
    box:SetMaxLetters(limit)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnTextChanged", function(self)
        TravelToDungeonDB[field] = self:GetText()
    end)
    return box
end

function TTD.Refresh()
    if not board then return end
    if refreshDungeons then refreshDungeons(false) end
    if selectedLabel then selectedLabel:SetText(TravelToDungeonDB.destination ~= "" and TravelToDungeonDB.destination or "Choose a dungeon above.") end
    local arrived, pending = 0, {}
    for i = 1, 5 do
        local row, member = rows[i], TTD.State.members[i]
        if member then
            row:Show()
            local state = TTD.State.statuses[member.id] or 1
            local connected = UnitIsConnected(member.unit)
            row.name:SetText(member.name .. (connected and "" or " (offline)"))
            local _, class = UnitClass(member.unit)
            local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            if color then row.name:SetTextColor(color.r, color.g, color.b)
            else row.name:SetTextColor(1, 1, 1) end
            row.status:SetText(TTD.Data.states[state])
            row.status:GetFontString():SetTextColor(unpack(TTD.Data.colors[state]))
            if state == 4 and connected then arrived = arrived + 1 end
            if state == 1 or not connected then pending[#pending + 1] = member.name end
        else
            row:Hide()
        end
    end
    if TTD.IsRaid() then
        summary:SetText("Raid groups are not supported. Use a dungeon party.")
    elseif #TTD.State.members < 2 then
        summary:SetText("Solo — invite party members to begin.")
    elseif arrived == #TTD.State.members then
        summary:SetText("Everyone is at the entrance — group ready!")
    else
        summary:SetText(arrived .. " / " .. #TTD.State.members .. " at entrance; " .. (#TTD.State.members - arrived) .. " still pending")
    end
    local seconds = TTD.State.started and math.floor(GetTime() - TTD.State.started) or 0
    timerLabel:SetText(string.format("Waiting %d:%02d", math.floor(seconds / 60), seconds % 60)
        .. (#pending > 0 and "  |  Unconfirmed: " .. table.concat(pending, ", ") or "  |  All checked in"))
end

local function CreateDungeonPicker()
    local panel = CreateFrame("Frame", nil, board, backdropTemplate)
    dungeonPanel = panel
    panel:SetPoint("TOPLEFT", 12, -84)
    panel:SetSize(396, 358)
    Bronze(panel, .065)
    panel:SetBackdropBorderColor(.40, .37, .28, 1)
    Label(panel, "Dungeons", 14, -12, "GameFontHighlightSmall")
    local filterLabel = Label(panel, "", 14, -32, "GameFontHighlightSmall")
    local showAll = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    showAll:SetPoint("TOPLEFT", 8, -49)
    showAll:SetSize(26, 26)
    Label(panel, "Show all dungeons", 37, -56, "GameFontHighlightSmall")
    showAll:SetChecked(false)

    local scroll = CreateFrame("ScrollFrame", "TravelToDungeonDungeonScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -82)
    scroll:SetPoint("BOTTOMRIGHT", -26, 56)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(354, 1)
    scroll:SetScrollChild(content)
    local empty = Label(panel, "No dungeons in your level range.\nEnable Show all dungeons to choose another.", 16, -110, "GameFontHighlightSmall")
    empty:SetWidth(260)
    empty:SetJustifyH("LEFT")
    selectedLabel = Label(panel, "", 14, -310, "GameFontHighlightSmall")
    selectedLabel:SetWidth(365)
    selectedLabel:SetHeight(36)
    selectedLabel:SetJustifyH("LEFT")
    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\Buttons\WHITE8X8")
    divider:SetVertexColor(.32, .29, .21, 1)
    divider:SetPoint("TOPLEFT", 12, -302)
    divider:SetSize(370, 1)
    local buttons, lastLevel, lastAll, lastDestination = {}, nil, nil, nil

    refreshDungeons = function(force)
        if TTD.InCombat() then return end
        local level = UnitLevel("player") or 0
        local all = showAll:GetChecked() and true or false
        local destination = TravelToDungeonDB.destination
        if not force and level == lastLevel and all == lastAll and destination == lastDestination then return end
        local filterChanged = level ~= lastLevel or all ~= lastAll
        lastLevel, lastAll, lastDestination = level, all, destination
        filterLabel:SetText("Level " .. level .. (all and "  -  All dungeons" or "  -  Recommended for you"))
        local choices = TTD.GetDungeonChoices(level, all)
        for _, button in ipairs(buttons) do button:Hide() end
        for index, preset in ipairs(choices) do
            local button = buttons[index]
            if not button then
                button = CreateFrame("Button", nil, content, backdropTemplate)
                button:SetSize(354, 20)
                button:SetPoint("TOPLEFT", 0, -(index - 1) * 20)
                button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                button.check = button:CreateTexture(nil, "ARTWORK")
                button.check:SetSize(18, 18)
                button.check:SetPoint("LEFT", 0, 0)
                button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
                button.tick = button:CreateTexture(nil, "OVERLAY")
                button.tick:SetAllPoints(button.check)
                button.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                button.title = Label(button, "", 22, -4, "GameFontNormalSmall")
                button.title:SetWidth(264)
                button.title:SetTextColor(.72, .65, .30)
                button.title:SetJustifyH("LEFT")
                button.title:SetWordWrap(false)
                button.range = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                button.range:SetPoint("RIGHT", -3, 0)
                button.range:SetWidth(60)
                button.range:SetJustifyH("RIGHT")
                button:SetScript("OnClick", function(self)
                    if TTD.InCombat() then return end
                    local chosen = self.preset
                    destinationBox:SetText(chosen[1])
                    noteBox:SetText("")
                    TTD.Reset()
                end)
                button:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(.45, .32, .12, .35)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.preset[1])
                    GameTooltip:AddLine(self.preset[2], .9, .8, .6)
                    GameTooltip:AddLine(self.preset[3], 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    self:SetBackdropColor(.45, .32, .12, self.selected and .30 or 0)
                end)
                buttons[index] = button
            end
            button.preset = preset
            button.title:SetText(preset[1])
            button.range:SetText("(" .. preset.minLevel .. " - " .. preset.maxLevel .. ")")
            local suitable = level >= preset.minLevel and level <= preset.maxLevel
            button.range:SetTextColor(suitable and .72 or .48, suitable and .65 or .46, suitable and .30 or .36)
            local selected = destination == preset[1]
            button.selected = selected
            button:SetBackdropColor(.45, .32, .12, selected and .30 or 0)
            if selected then button.tick:Show() else button.tick:Hide() end
            button:Show()
        end
        content:SetHeight(math.max(1, #choices * 20))
        if #choices == 0 then empty:Show() else empty:Hide() end
        if filterChanged then scroll:SetVerticalScroll(0) end
    end
    showAll:SetScript("OnClick", function() refreshDungeons(true) end)
end

function TTD.CreateBoard()
    board = CreateFrame("Frame", "TravelToDungeonFrame", UIParent, backdropTemplate)
    board:SetSize(420, 500)
    board:SetPoint("CENTER", UIParent, "CENTER", TravelToDungeonDB.x or 0, TravelToDungeonDB.y or 0)
    board:SetFrameStrata("DIALOG")
    board:SetClampedToScreen(true)
    board:SetMovable(true)
    board:EnableMouse(true)
    board:RegisterForDrag("LeftButton")
    board:SetScript("OnDragStart", function(self) self:StartMoving() end)
    board:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = UIParent:GetCenter()
        TravelToDungeonDB.x, TravelToDungeonDB.y = x - px, y - py
    end)
    Bronze(board)
    -- Dialog artwork has transparent pixels even at alpha 1. A solid texture
    -- underneath the trim prevents the game world showing through the window.
    board:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true,
        tileSize = 32, edgeSize = 24, insets = { left = 7, right = 7, top = 7, bottom = 7 } })
    board:SetBackdropBorderColor(.72, .53, .28, 1)
    board:SetBackdropColor(.045, .045, .05, 1)
    board:SetAlpha(1)
    local header = board:CreateTexture(nil, "BACKGROUND")
    header:SetPoint("TOPLEFT", 5, -5)
    header:SetPoint("TOPRIGHT", -5, -5)
    header:SetHeight(28)
    header:SetTexture("Interface\\Buttons\\WHITE8X8")
    header:SetVertexColor(.16, .105, .045, 1)
    local title = Label(board, "Travel to Dungeon", 0, -13, "GameFontNormal")
    title:ClearAllPoints()
    title:SetPoint("TOP", 0, -13)

    local close = CreateFrame("Button", nil, board, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() board:Hide() end)
    tinsert(UISpecialFrames, "TravelToDungeonFrame")
    local details = CreateFrame("Frame", nil, board)
    details:SetPoint("TOPLEFT", 0, 0)
    details:SetSize(420, 500)
    Label(details, "Meeting point", 20, -90)
    destinationBox = Input(details, -110, 100, "destination")

    Label(details, "Preparation notes", 20, -140)
    noteBox = Input(details, -160, 120, "note")
    Label(details, "PARTY  —  click a status to cycle", 20, -246)
    for i = 1, 5 do
        local index = i
        local row = CreateFrame("Frame", nil, details)
        row:SetSize(380, 26)
        row:SetPoint("TOPLEFT", 20, -268 - (i - 1) * 27)
        row.name = Label(row, "", 0, -5, "GameFontHighlight")
        row.name:SetWidth(218)
        row.name:SetJustifyH("LEFT")
        row.status = Button(row, "Not ready", 228, 0, 150, function()
            local member = TTD.State.members[index]
            if member and not TTD.InCombat() then
                TTD.State.statuses[member.id] = (TTD.State.statuses[member.id] or 1) % #TTD.Data.states + 1
                TTD.Refresh()
            end
        end)
        rows[i] = row
    end
    summary = Label(details, "", 20, -409, "GameFontHighlight")
    summary:SetWidth(378)
    summary:SetJustifyH("LEFT")
    timerLabel = Label(details, "", 20, -432, "GameFontHighlightSmall")
    timerLabel:SetWidth(378)
    timerLabel:SetHeight(32)
    timerLabel:SetJustifyH("LEFT")
    Button(board, "Share to party", 270, -466, 130, TTD.Share)
    Button(details, "Reset", 20, -466, 100, TTD.Reset)
    destinationBox:SetText(TravelToDungeonDB.destination)
    noteBox:SetText(TravelToDungeonDB.note)
    CreateDungeonPicker()
    local dungeonTab, partyTab
    local function ShowPage(party)
        if party then details:Show(); dungeonPanel:Hide()
        else details:Hide(); dungeonPanel:Show() end
        dungeonTab:SetEnabled(party)
        partyTab:SetEnabled(not party)
        destinationBox:ClearFocus()
        noteBox:ClearFocus()
    end
    dungeonTab = Button(board, "Dungeons", 22, -47, 178, function() ShowPage(false) end)
    partyTab = Button(board, "Party check-ins", 210, -47, 188, function() ShowPage(true) end)
    ShowPage(false)
    refreshDungeons(true)
    board:Hide()
end

function TTD.ToggleBoard()
    if TTD.InCombat() then TTD.Print("Open the meeting board after combat."); return end
    TTD.Scan()
    if board:IsShown() then board:Hide() else board:Show() end
end

function TTD.HideBoard()
    if board then board:Hide() end
end

TTD.CreateButton = Button
