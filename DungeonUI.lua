local _, TTD = ...

-- Optional launcher attached to Blizzard's Dungeon/Group Finder.
local dungeonButtons = {}
function TTD.AttachDungeonButton()
    if not TTD.State.ready or TTD.InCombat() then return end
    -- Prefer the outer modern Group Finder; support the legacy standalone panel.
    local parent = _G.PVEFrame or _G.LFDParentFrame
    if not parent or dungeonButtons[parent] then return end
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(40, 40)
    button:SetNormalTexture("Interface\\Icons\\INV_Misc_Map_01")
    button:SetPushedTexture("Interface\\Icons\\INV_Misc_Map_01")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("CENTER")
    border:SetSize(66, 66)
    border:SetVertexColor(.85, .66, .36)
    local function Position()
        if TTD.InCombat() then return end
        -- Find the existing right-edge icon tabs by their geometry, avoiding
        -- dependence on names that can change between Forever beta builds.
        local lowest, lowestBottom
        local right = parent:GetRight()
        if right then
            for _, child in ipairs({ parent:GetChildren() }) do
                if child ~= button and child:IsObjectType("Button") and child:IsShown() then
                    local left, bottom = child:GetLeft(), child:GetBottom()
                    local width, height = child:GetWidth(), child:GetHeight()
                    if left and bottom and width >= 25 and width <= 65 and height >= 25 and height <= 65
                        and left >= right - 15 and left <= right + 40 then
                        if not lowestBottom or bottom < lowestBottom then lowest, lowestBottom = child, bottom end
                    end
                end
            end
        end
        button:ClearAllPoints()
        if lowest then
            button:SetPoint("TOP", lowest, "BOTTOM", 0, -8)
        else
            button:SetPoint("TOPLEFT", parent, "TOPRIGHT", 3, -170)
        end
    end
    Position()
    parent:HookScript("OnShow", Position)
    button:SetScript("OnClick", TTD.ToggleBoard)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Travel to Dungeon")
        GameTooltip:AddLine("Open your dungeon meeting board.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dungeonButtons[parent] = button
end
