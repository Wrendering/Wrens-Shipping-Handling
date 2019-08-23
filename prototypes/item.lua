
-- https://stable.wiki.factorio.com/User:Adil/Modding_tutorial#The_very_simple_mod
-- https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir#Terminology_used_in_modding
-- https://wiki.factorio.com/Data.raw
-- https://wiki.factorio.com/Prototype/Car
-- https://github.com/wube/factorio-data/blob/master/base/prototypes/tile/tiles.lua

------------------------ OBJECT basicBoat basic-boat

local basicBoat_entity = table.deepcopy(data.raw["car"]["car"])
basicBoat_entity.name = "basic-boat"
basicBoat_entity.guns = nil
basicBoat_entity.minable.result = "basic-boat-item"
basicBoat_entity.collision_mask = {"ground-tile", "consider-tile-transitions" }
data:extend({basicBoat_entity})

local basicBoat_item = table.deepcopy(data.raw["item-with-entity-data"]["car"])
basicBoat_item.name = "basic-boat-item"
basicBoat_item.place_result = "basic-boat"
data:extend({basicBoat_item})

local basicBoat_recipe = {
    type = "recipe",
    name = "basic-boat-recipe",
    enabled = true,
    ingredients = {
        {'iron-plate',5},
    },
    result = "basic-boat-item",
}
data:extend({basicBoat_recipe})

------------------------ TILEs oceanWater ocean-deep-water | oceanShallow ocean-shallow-water

local sub_copyTransitions = function (fromTile, toTile)
    for _, tile in pairs(data.raw.tile) do  --#thankyouAlienBiomes
        if tile.transitions then
            for _, transition in pairs(tile.transitions) do
                if transition.to_tiles then
                    for _, to_tile in pairs(transition.to_tiles) do
                        if to_tile == fromTile then
                            table.insert(transition.to_tiles, toTile)
                        end
                    end
                end
            end
        end
    end
end

local oceanWater_tile = table.deepcopy(data.raw["tile"]["deepwater"])
oceanWater_tile.name = "ocean-deep-water"
oceanWater_tile.tint = {0.2,1,0.9,1}
oceanWater_tile.autoplace = nil
sub_copyTransitions("deepwater", "ocean-deep-water")
data:extend({oceanWater_tile})

local oceanShallow_tile = table.deepcopy(data.raw["tile"]["water"]) -- water-tile item-layer resource-layer player-layer doodad-layer
oceanShallow_tile.name = "ocean-shallow-water"
oceanShallow_tile.tint = {0.2,1,0.9,1}
oceanShallow_tile.autoplace = nil
oceanShallow_tile.collision_mask = {"water-tile", "item-layer", "resource-layer", "doodad-layer"}
sub_copyTransitions("water", "ocean-shallow-water")
data:extend({oceanShallow_tile})
