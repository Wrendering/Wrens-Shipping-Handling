
-- https://stable.wiki.factorio.com/User:Adil/Modding_tutorial#The_very_simple_mod
-- https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir#Terminology_used_in_modding
-- https://wiki.factorio.com/Data.raw
-- https://wiki.factorio.com/Prototype/Car
-- https://github.com/wube/factorio-data/blob/master/base/prototypes/tile/tiles.lua

------------------------ OBJECT lighthouse lighthouse

local lighthouse_entity = {
    type = "lamp",

    name = "lighthouse-entity",
    icon = "__base__/graphics/icons/small-lamp.png",
    icon_size = 32,
    flags = { "placeable-player", },
    minable = { mining_time = 3, result = "lighthouse-item", },
    max_health = 500,
    corpse = "lamp-remnants",
    collision_box = {{-1.5, -1.5}, {1.5, 1.5}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.7 },

    energy_usage_per_tick = "1MW",
    energy_source = {
        type = "electric",
        buffer_capacity = "5MJ",
        usage_priority = "primary-input",
        input_flow_limit = "1.5MW",
    },
    light = { type = "basic", intensity = 1, size = 15,  color = { r=1.0, g=1.0, b=1.0} },
    glow_size = 10,
    glow_color_intensity = 0.25,
    always_on = true,
    picture_on  = {
        layers = {
            {
                filename = "__base__/graphics/entity/assembling-machine-2/assembling-machine-2.png",
                priority = "high",
                width = 108,
                height = 119,
                frame_count = 32,
                line_length = 8,
                shift = util.by_pixel(0,-0.5),
            },
            {
                filename = "__base__/graphics/entity/assembling-machine-2/assembling-machine-2-shadow.png",
                priority = "high",
                width = 130,
                height = 82,
                frame_count = 32,
                line_length = 8,
                draw_as_shadow = true,
                shift = util.by_pixel(28,4),
            },
        },
    },

    picture_off  = {
        layers = {
            {
                filename = "__base__/graphics/entity/assembling-machine-3/assembling-machine-3.png",
                priority = "high",
                width = 108,
                height = 119,
                frame_count = 32,
                line_length = 8,
                shift = util.by_pixel(0,-0.5),
            },
            {
                filename = "__base__/graphics/entity/assembling-machine-3/assembling-machine-3-shadow.png",
                priority = "high",
                width = 130,
                height = 82,
                frame_count = 32,
                line_length = 8,
                draw_as_shadow = true,
                shift = util.by_pixel(28,4),
            },
        },
    }
}
data:extend({lighthouse_entity})

local lighthouse_item = {
    type = "item",
    name = "lighthouse-item",
    icon = "__base__/graphics/icons/beacon.png",
    icon_size = 32,
    subgroup = "energy",
    order = "a[lighthouse]",
    place_result = "lighthouse-entity",
    stack_size = 5,
}
data:extend({lighthouse_item})

local lighthouse_recipe = {
    type = "recipe",
    name = "lighthouse-recipe",
    enabled = true,
    ingredients = {
        {'iron-plate',1},
    },
    result = "lighthouse-item",
}
data:extend({lighthouse_recipe})

------------------------ OBJECT basicBoat basic-boat

local basicBoat_entity = table.deepcopy(data.raw["car"]["car"])
basicBoat_entity.name = "basic-boat"
basicBoat_entity.friction = 0.01
basicBoat_entity.weight = 2000
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
        {'iron-plate',1},
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
