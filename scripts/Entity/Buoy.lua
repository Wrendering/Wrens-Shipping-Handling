local APIInterface = require("scripts/APIInterface")

local Entity = require("Entity")
local Buoy = Entity:new{entity = nil}

Buoy.buoyTypesList_entity = {[1] = "incoming-buoy-entity", [2] = "outgoing-buoy-entity", [3] = "signal-buoy-entity"}

function Buoy:new(args)
  -- Note: args._buoyPlacementLock is a thing. Don't use it outside of this class, please.
  log(args.entity.unit_number)
  args.className = "buoy-entity"
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  if args._buoyPlacementLock == nil then
    newObject = newObject:updateCheck()
    newObject.active_state = 1
  end

  return newObject
end

APIInterface.registerFunction("on_built_entity", function(e)
  if e.created_entity.valid and string.find(e.created_entity.name, "buoy%-entity") then
    local buoy = Buoy:new{entity = e.created_entity}
  end
end)

function Buoy:updateCheck(buoy_type_index)
  -- Replace this buoy with a new one; update all relevant buoysLists to new unit_number
  -- buoy_type_index is an optional argument

  local buoy_type = (buoy_type_index and buoyTypesList_entity[buoy_type_index])
  local location = self.entity.position
  local lighthousesList = global.lighthousesList
  local radius = (BEACON_RADIUS + BUOY_RADIUS)

  local lighthouses = self.entity.surface.find_entities_filtered({area={ left_top = {location.x - radius, location.y - radius }, right_bottom = {location.x + radius, location.y + radius }}, name = "lighthouse-entity" })

  local new_buoy = self:updateEntity({within_range = (next(lighthouses) ~= nil), buoy_type = buoy_type })
  local new_buoy_entity = new_buoy.entity
  for _,i in pairs(lighthouses) do
    lighthousesList[i.unit_number].buoysList[new_buoy_entity.unit_number] = {entity = new_buoy_entity, distance = (new_buoy_entity.position.x - i.position.x)^2 + (new_buoy_entity.position.y - i.position.y)^2 }
  end

  return new_buoy
end

function Buoy:updateEntity(arg)
  -- Optional: within_range, buoy_type

  local buoy = self.entity
  local new_buoy
  local buoysList = global.lists["buoy-entity"]

  arg.buoy_type = arg.buoy_type or Buoy.buoyTypesList_entity[self.active_state]
  arg.within_range = arg.within_range or false

  if arg.within_range then
    new_buoy = buoy.surface.create_entity({name=arg.buoy_type, position = buoy.position, force = buoy.force})
    buoysList[new_buoy.unit_number] = buoysList[buoy.unit_number]
    buoysList[buoy.unit_number] = nil
  else
    new_buoy = buoy.surface.create_entity({name="disabled-buoy-entity", position = buoy.position, force = buoy.force})
    buoysList[new_buoy.unit_number] = buoysList[buoy.unit_number]
    buoysList[buoy.unit_number] = nil
  end
  buoysList[new_buoy.unit_number].entity = new_buoy

  self:destroy()
  new_buoy_object = Buoy:new{_buoyPlacementLock = true, entity = new_buoy }
  return new_buoy_object
end

function Buoy:destroy()
  local lighthousesList = global.lists["lighthouse"]
  local unit_number = self.entity.unit_number

  if self.lighthouses ~= nil then
    for i,_ in pairs(self.lighthouses) do
      lighthousesList[i].buoysList[unit_number] = nil
    end
  end

  getmetatable(Buoy).destroy(self, {className = "buoy-entity"})
end

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if string.find(e.entity.name, "buoy%-entity") then
    global.lists["buoy-entity"][e.entity.unit_number]:destroy()
  end
end)
--]]--
