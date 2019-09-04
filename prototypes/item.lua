
-- https://stable.wiki.factorio.com/User:Adil/Modding_tutorial#The_very_simple_mod
-- https://wiki.factorio.com/Tutorial:Modding_tutorial/Gangsir#Terminology_used_in_modding
-- https://wiki.factorio.com/Data.raw
-- https://wiki.factorio.com/Prototype/Car
-- https://github.com/wube/factorio-data/blob/master/base/prototypes/tile/tiles.lua

------------------------ OBJECT buoy buoy
local buoy_entity = {
  type = "beacon",
  name = "buoy-entity",

  flags = { "placeable-player", },
  collision_mask = { "object-layer", "player-layer", "ground-tile"},
  minable = { mining_time = 0.4, result = "buoy-item", },
  max_health = 500,
  collision_box = {{-0.3, -0.3}, {0.3, 0.3}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  energy_usage = "10kW",
  energy_source = { type = "void", },

  supply_area_distance = 2,
  distribution_effectivity = 0,
  module_specification = { module_slots = 0, },
  allowed_effects = nil,

  corpse = "big-remnants",
  vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.7 },
  icon = "__base__/graphics/icons/small-lamp.png",
  icon_size = 32,

  base_picture = {
    filename = "__base__/graphics/entity/small-lamp/lamp.png",
    width = 42,
    height = 36,
    --shift = { 0.34375, 0.046875},
  },
  animation = {
    filename = "__base__/graphics/entity/small-lamp/lamp-light.png",
    width = 46,
    height = 40,
    line_length = 1,
    frame_count = 1,
    --shift = { -0.03125, -1.71875},
    animation_speed = 0.5,
  },
  animation_shadow = {
    filename = "__base__/graphics/entity/small-lamp/lamp-shadow.png",
    width = 38,
    height = 24,
    line_length = 1,
    frame_count = 1,
    --shift = { 3.140625, 0.484375},
    animation_speed = 0.5,
  },
  radius_visualisation_picture = {
    filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
    width = 10,
    height = 10,
  },
}
data:extend({buoy_entity})

local buoy_item = {
    type = "item",
    name = "buoy-item",
    icon = "__base__/graphics/icons/small-lamp.png",
    icon_size = 32,
    subgroup = "energy",
    order = "a[buoy]",
    place_result = "buoy-entity",
    stack_size = 25,
}
data:extend({buoy_item})

local buoy_recipe = {
    type = "recipe",
    name = "buoy-recipe",
    enabled = true,
    ingredients = {
        {'iron-plate',1},
    },
    result = "buoy-item",
}
data:extend({buoy_recipe})


------------------------ OBJECT lighthouse lighthouse

local lighthouse_entity = {
    type = "beacon",
    name = "lighthouse-entity",

    flags = { "placeable-player", },
    minable = { mining_time = 3, result = "lighthouse-item", },
    max_health = 500,
    collision_box = {{-1.5, -1.5}, {1.5, 1.5}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    energy_usage = "1MW",
    energy_source = {
        type = "electric",
        buffer_capacity = "5MJ",
        usage_priority = "primary-input",
        input_flow_limit = "1.5MW",
    },

    supply_area_distance = 15,
    distribution_effectivity = 0,
    module_specification = { module_slots = 0, },
    allowed_effects = nil,

    corpse = "big-remnants",
    vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.7 },

    icon = "__base__/graphics/icons/small-lamp.png",
    icon_size = 32,
    base_picture = {
      filename = "__base__/graphics/entity/beacon/beacon-base.png",
      width = 116,
      height = 93,
      shift = { 0.34375, 0.046875},
    },
    animation = {
      filename = "__base__/graphics/entity/beacon/beacon-antenna.png",
      width = 54,
      height = 50,
      line_length = 8,
      frame_count = 32,
      shift = { -0.03125, -1.71875},
      animation_speed = 0.5,
    },
    animation_shadow = {
      filename = "__base__/graphics/entity/beacon/beacon-antenna-shadow.png",
      width = 63,
      height = 49,
      line_length = 8,
      frame_count = 32,
      shift = { 3.140625, 0.484375},
      animation_speed = 0.5,
    },
    radius_visualisation_picture = {
      filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
      width = 10,
      height = 10,
    },
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
basicBoat_entity.collision_mask = {"ground-tile", "player-layer", "consider-tile-transitions" }
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
oceanShallow_tile.collision_mask = {"water-tile", "resource-layer", "doodad-layer"}
sub_copyTransitions("water", "ocean-shallow-water")
data:extend({oceanShallow_tile})
