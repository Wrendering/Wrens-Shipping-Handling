local APIInterface = require("scripts/APIInterface")

local Entity = require("Entity")
local Buoy = Entity:new{entity = nil, active_state = nil}

Buoy.buoyTypesList_entity = {[1] = "incoming-buoy-entity", [2] = "outgoing-buoy-entity", [3] = "signal-buoy-entity"}

function Buoy:new(args)
  -- Note: args._buoyPlacementLock is a thing. Don't use it outside of this class, please.
  args.className = "buoy-entity"
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  newObject.active_state = args.active_state

  if args._buoyPlacementLock == nil then
    newObject.active_state = newObject.active_state or 1
    newObject = newObject:updateEntityWithChecks()
  end

  return newObject
end

APIInterface.registerFunction("on_built_entity", function(e)
  if e.created_entity.valid and string.find(e.created_entity.name, "buoy%-entity") then
    local buoy = Buoy:new{entity = e.created_entity}
  end
end)

function Buoy:updateEntityWithChecks(args)
  -- args.buoy_type_index *optional* -- keeps to current active state otherwise
  -- args.not_within_range *optional* -- set to 'true' to skip lighthouse checks/updates
  -- Replace this buoy with a new one; update all relevant buoysLists to new unit_number
  args = args or {}
  local new_buoy
  if args.not_within_range == nil then
    local location = self.entity.position
    local lighthousesList = global.lists["lighthouse-entity"]
    local radius = (BEACON_RADIUS + BUOY_RADIUS)

    local lighthouses = self.entity.surface.find_entities_filtered({area={ left_top = {location.x - radius, location.y - radius }, right_bottom = {location.x + radius, location.y + radius }}, name = "lighthouse-entity" })
    new_buoy = self:updateEntityRaw({within_range = (next(lighthouses) ~= nil), buoy_type_index = args.buoy_type_index })

    local new_buoy_entity = new_buoy.entity
    for _,i in pairs(lighthouses) do
      lighthousesList[i.unit_number].buoysList[new_buoy_entity.unit_number] = {entity = new_buoy_entity, distance = (new_buoy_entity.position.x - i.position.x)^2 + (new_buoy_entity.position.y - i.position.y)^2 }
    end
  else
    new_buoy = self:updateEntityRaw({within_range = false, buoy_type_index = args.buoy_type_index })
  end

  return new_buoy
end

function Buoy:updateEntityRaw(args)
  -- Optional: within_range, buoy_type_index

  args.within_range = args.within_range or false
  local active_state = args.buoy_type_index or self.active_state

  local buoy = self.entity

  local new_buoy
  if args.within_range then
    new_buoy = buoy.surface.create_entity({name=Buoy.buoyTypesList_entity[active_state], position = buoy.position, force = buoy.force})
  else
    new_buoy = buoy.surface.create_entity({name="disabled-buoy-entity", position = buoy.position, force = buoy.force})
  end

  if self.entity.unit_number ~= new_buoy.unit_number then self:destroy() end
  new_buoy_object = Buoy:new{_buoyPlacementLock = true, entity = new_buoy, active_state = active_state }
  return new_buoy_object
end

function Buoy:destroy()
  local lighthousesList = global.lists["lighthouse-entity"]
  local unit_number = self.entity.unit_number

  if self.lighthouses ~= nil then
    for i,_ in pairs(self.lighthouses) do
      lighthousesList[i].buoysList[unit_number] = nil
    end
  end

  getmetatable(Buoy).destroy(self, {className = "buoy-entity"})
end

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.valid and string.find(e.entity.name, "buoy%-entity") then
    global.lists["buoy-entity"][e.entity.unit_number]:destroy()
  end
end)
--]]--
