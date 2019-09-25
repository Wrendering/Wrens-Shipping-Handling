--
--global = {}
--

local PIInterface = require("scripts/APIInterface")

local Entity = require("Entity")

local Dock = Entity:new{entity = nil}

function Dock:new(args)
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  newObject.signal = nil
  newObject.condition = 1
  newObject.lighthouses = {}

  local location = newObject.entity.position
  local radius = BEACON_RADIUS + 1 + DOCK_RADIUS
  local lighthousesList = global.lighthousesList

  local lighthouses = newObject.entity.surface.find_entities_filtered({area={ left_top = {location.x - radius, location.y - radius }, right_bottom = {location.x + radius, location.y + radius }}, name = "lighthouse-entity" })
  for _,i in pairs(lighthouses) do
    newObject.lighthouses[i.unit_number] = true
    lighthousesList[i.unit_number].docksList[newObject.entity.unit_number] = true
  end

  return newObject
end

APIInterface.registerFunction("on_built_entity", function(e)
  if e.created_entity.valid and e.created_entity.name == "dock-entity" then
    local dock = Dock:new{entity = e.created_entity}
  end
end)


function Dock.checkPlacement(e)
  --Effectively a static method -- don't use ':' syntax
  if e.created_entity.valid and e.created_entity.name == "dock-entity" then
    if next(e.created_entity.surface.find_tiles_filtered({area = { {e.created_entity.bounding_box.left_top.x - 1, e.created_entity.bounding_box.left_top.y}, {e.created_entity.bounding_box.left_top.x, e.created_entity.bounding_box.right_bottom.y}}, collision_mask = {"water-tile",}, })) ~= nil then
      game.players[e.player_index].print("ERROR: Dock must be placed with back to land.")
    elseif next(e.created_entity.surface.find_tiles_filtered({area = { {e.created_entity.bounding_box.right_bottom.x, e.created_entity.bounding_box.left_top.y}, {e.created_entity.bounding_box.right_bottom.x + 1, e.created_entity.bounding_box.right_bottom.y}}, collision_mask = {"ground-tile",}, })) ~= nil then
      game.players[e.player_index].print("ERROR: Dock must be placed with front to water.")
    else
      return
    end
    game.players[e.player_index].insert(e.stack)
    e.created_entity.destroy()
  end
end
APIInterface.registerFunction("on_built_entity", Dock.checkPlacement)


function Dock:destroy()
  local lighthousesList = global.lighthousesList
  local unit_number = self.entity.unit_number

  for i,_ in pairs(self.lighthouses) do
    lighthousesList[i].docksList[unit_number] = nil
  end

  getmetatable(Dock).destroy(self)
end

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.name == "dock-entity" then
    global.lists["dock-entity"][e.entity.unit_number]:destroy()
  end
end)
--]]--
