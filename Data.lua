local _, TTD = ...

-- Status labels, colors, and editable dungeon presets.
TTD.Data = {}
TTD.Data.states = { "Not ready", "Traveling", "Nearby", "At entrance" }
TTD.Data.colors = { {1, .45, .4}, {1, .8, .3}, {.4, .8, 1}, {.4, 1, .5} }
TTD.Data.presets = {
    { "The Hall of Thanes", "Ironforge", "Meet outside the dungeon entrance.", minLevel = 13, maxLevel = 18 },
    { "Ruins of Lordaeron", "Ruins of Lordaeron", "Confirm the meeting spot with the party.", minLevel = 15, maxLevel = 20 },
    { "Excavation Site: Wetlands", "Above Whelgar's Excavation", "Meet outside the dungeon entrance.", minLevel = 26, maxLevel = 31 },
    { "City of Dalaran", "Dalaran", "Meet outside the dungeon entrance.", minLevel = 28, maxLevel = 33 },
    { "The Drowned City", "The Drowned City", "Confirm the approach with the party.", minLevel = 35, maxLevel = 40 },
    { "Krol'dok Stronghold", "Riverglades", "Meet outside the dungeon entrance.", minLevel = 40, maxLevel = 45 },
    { "Alcaz Prison", "Dustwallow Marsh", "Confirm the approach with the party.", minLevel = 48, maxLevel = 53 },
    { "Blackmaw Hold", "Azshara", "Meet outside the dungeon entrance.", minLevel = 55, maxLevel = 60 },
    { "Shaper's Terrace", "Un'Goro Crater", "Meet outside the dungeon entrance.", minLevel = 58, maxLevel = 60 },
    { "Blackrock Depths", "Blackrock Mountain", "Bring the Shadowforge Key if you have it.", minLevel = 52, maxLevel = 60 },
    { "Lower Blackrock Spire", "Blackrock Mountain", "Meet at the Blackrock Spire entrance.", minLevel = 55, maxLevel = 60 },
    { "Upper Blackrock Spire", "Blackrock Mountain", "Confirm someone has the Seal of Ascension.", minLevel = 55, maxLevel = 60 },
    { "Deadmines", "Moonbrook, Westfall", "Meet at the instance portal inside the mines.", minLevel = 17, maxLevel = 26 },
    { "Scarlet Monastery", "Tirisfal Glades", "Confirm the wing with the party.", minLevel = 26, maxLevel = 45 },
    { "Zul'Farrak", "Tanaris", "Bring the Mallet of Zul'Farrak for Gahz'rilla.", minLevel = 44, maxLevel = 54 },
    { "Maraudon", "Desolace", "Confirm the entrance and route with the party.", minLevel = 46, maxLevel = 55 },
    { "Stratholme", "Eastern Plaguelands", "Confirm main entrance or service entrance.", minLevel = 58, maxLevel = 60 },
    { "Scholomance", "Caer Darrow, Western Plaguelands", "Bring the Skeleton Key if you have it.", minLevel = 58, maxLevel = 60 },
    { "Dire Maul", "Feralas", "Confirm the wing with the party.", minLevel = 55, maxLevel = 60 },
}

-- Recommended ranges, not enforced entrance requirements.
-- Source: https://forevercompass.com/dungeons (Forever beta, October 2026).
-- Combined wing presets cover the full range of their constituent wings.

function TTD.GetDungeonChoices(level, showAll)
    local choices = {}
    for _, preset in ipairs(TTD.Data.presets) do
        if showAll or (level >= preset.minLevel and level <= preset.maxLevel) then
            choices[#choices + 1] = preset
        end
    end
    table.sort(choices, function(a, b)
        if a.minLevel == b.minLevel then return a[1] < b[1] end
        return a.minLevel < b.minLevel
    end)
    return choices
end
