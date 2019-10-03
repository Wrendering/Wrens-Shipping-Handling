local APIInterface = require("scripts/APIInterface")

local Entity = require("Entity")
local Boat = Entity:new{entity = nil, className = "basic-boat", signalType = true }

function Boat:new(args)
  args.signalType = true
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  newObject.automated = args.automated or false
  newObject.signal = args.signal or nil
  newObject.currentTarget = args.currentTarget or nil
  newObject.selected_condition_index = args.selected_condition_index or 1
  newObject.conditions = args.conditions or { [1] = { [1] = { type = "conditionIndex", value = 1, }, }, }

  if newObject.automated then
    newObject.entity.set_driver(newObject.entity.surface.create_entity(
      { name = "character", position = newObject.entity.position, force = game.forces.player}
    ))
  end

  newObject:setSignal(args.signal)

  return newObject
end

APIInterface.registerFunction("on_built_entity", function (e)
    if e.created_entity.valid and e.created_entity.name == "basic-boat" then
      local boat = Boat:new{
        entity = e.created_entity,
        automated = true,
      }
    end
end)

function Boat:destroy()
  -- Remove from docks
  getmetatable(Boat).destroy(self)
end

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.valid and e.entity.name == "basic-boat" then
    global.lists["basic-boat"][e.entity.unit_number]:destroy()
  end
end)

APIInterface.registerFunction("on_tick", function(e)
  local distance = nil
  local boat_entity = nil
  local position = nil
  local lighthouses = nil
  local buoys = {}
  local lighthouseData = nil
  local lighthousesList = global.lists["lighthouse-entity"]

  if global.lists["basic-boat"] then
    for boat_unit_number, boat in pairs(global.lists["basic-boat"]) do
      boat_entity = boat.entity
      position = boat_entity.position

      lighthouses = boat_entity.surface.find_entities_filtered({area={ left_top = {position.x - BEACON_RADIUS, position.y - BEACON_RADIUS }, right_bottom = {position.x + BEACON_RADIUS, position.y + BEACON_RADIUS }}, name = "lighthouse-entity" })
      for _,lighthouse in pairs(lighthouses) do
        lighthouseData = lighthousesList[lighthouse.unit_number]
        if lighthouseData.buoysList ~= nil then
          distance = lighthouse.position
          distance = (position.x - distance.x)^2 + (position.y - distance.y)^2
          for _,buoy in pairs(lighthouseData.buoysList) do
            if math.abs(buoy.distance - distance) < BUOY_RADIUS then
              buoys[#buoys + 1] = buoy
            end
          end
        end
      end
    end
    --log(#buoys)
  end
end)

function Boat:setSignal(signal)
  local boatSignalLists = global.signalLists["basic-boat"]

  if self.signal ~= nil then
    boatSignalLists[self.signal.type..self.signal.name][self.entity.unit_number] = nil
    if next(boatSignalLists[self.signal.type..self.signal.name]) == nil then boatSignalLists[self.signal.type..self.signal.name] = nil end
  end

  self.signal = signal

  if signal ~= nil then
    if boatSignalLists[signal.type..signal.name] == nil then boatSignalLists[signal.type..signal.name] = {} end
    boatSignalLists[signal.type..signal.name][self.entity.unit_number] = true

    local tempResult = self:searchAll{signal = signal}
  else
    self.currentTarget = nil
    if self.automated then self:slowDown() end
  end

end


function Boat:searchAll(arg)
  --Input table: signal = signal to search
  local returnVal = nil
  local boatPos = self.entity.position
  local origTarget = nil
  local newTarget = nil
  local local_lighthousesList = global.lists["lighthouse-entity"]
  if global.signalLists["lighthouse-entity"][arg.signal.type..arg.signal.name] ~= nil then
    for lighthouse_unit_number,_ in pairs(global.signalLists["lighthouse-entity"][arg.signal.type..arg.signal.name]) do
      if not origTarget then
        origTarget = local_lighthousesList[lighthouse_unit_number].entity.position
      else
        newTarget = local_lighthousesList[lighthouse_unit_number].entity.position
        if (boatPos.x - origTarget.x)^2 + (boatPos.y - origTarget.y)^2 > (boatPos.x - newTarget.x)^2 + (boatPos.y - newTarget.y)^2 then
          origTarget = newTarget
        end
      end
    end
    if self.currentTarget == origTarget then
      returnVal = false
    else
      self.currentTarget = origTarget
      returnVal = true
    end
  end
  if returnVal == nil then
    self.currentTarget = nil
    returnVal = true
  end

  if self.automated then
    if self.currentTarget ~= nil and returnVal then
      self:setDirection()
    else
      self:slowDown()
    end
  end
end



function Boat:compareOne(args)
  --Input table: lighthouse_unit_number
  local boatPos = self.entity.position
  local origTarget = self.currentTarget
  local newTarget = global.lists["lighthouse-entity"][args.lighthouse_unit_number].entity.position

  if origTarget == nil or (boatPos.x - origTarget.x)^2 + (boatPos.y - origTarget.y)^2 > (boatPos.x - newTarget.x)^2 + (boatPos.y - newTarget.y)^2 then
    self.currentTarget = newTarget
    return true
  end
  return false
end

function Boat:setDirection ()
  if not self.currentTarget then return end
  local boatPos = self.entity.position
  local targetPos = self.currentTarget
  self.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
  self.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
end

function Boat:slowDown ()
  if self.entity.speed < 0.01 then
    self.entity.speed = 0
    self.entity.riding_state = {acceleration = defines.riding.acceleration.nothing, direction = defines.riding.direction.straight }
  else
    self.entity.riding_state = {acceleration = defines.riding.acceleration.braking, direction = defines.riding.direction.straight }
  end
end


function Boat:setAutomated(newAutomated)
  -- return values: 0->fine, 1->Set to automated while has two, 2-> somehow player automated driver
  if self.automated ~= newAutomated then
    self.automated = newAutomated
    local entity = self.entity
    if newAutomated then
      local driver = entity.get_driver()
      if(driver) then
        if(driver.player ~= nil) then
          local passenger = entity.get_passenger()
          if(passenger ~= nil and passenger.player ~= nil) then
            return 1
          else
            entity.set_passenger(entity.get_driver())
          end
        end
      end
      entity.set_driver(nil)
      entity.set_driver(entity.surface.create_entity{ name = "character", position = entity.position, force = game.forces.player})

      if self.signal ~= nil then
        self:searchAll{signal = self.signal}
      end
    else
      if(entity.get_driver() ~= nil and entity.get_driver().player ~= nil) then
        return 2
      end
      if entity.get_driver() then entity.get_driver().destroy() end
      entity.set_driver(nil)
      if entity.get_passenger() and entity.get_passenger().player then
        entity.set_driver(entity.get_passenger())
        entity.set_passenger(nil)
      end
    end
  end
  return 0
end
