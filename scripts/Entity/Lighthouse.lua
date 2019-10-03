local APIInterface = require("scripts/APIInterface")

local Entity = require("Entity")
local Lighthouse = Entity:new{entity = nil, className = "lighthouse-entity", signalType = true, buoysList = {}, docksList = {}  }

function Lighthouse:new(args)
  args.signalType = true
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  newObject.signal = args.signal or nil
  newObject.buoysList = {}
  newObject.docksList = {}

  newObject:setSignal{args.signal}

  local buoysList = global.lists["buoy-entity"]
  local buoys = args.entity.surface.find_entities_filtered({area={ left_top = {args.entity.position.x - (BEACON_RADIUS + BUOY_RADIUS+1), args.entity.position.y - (BEACON_RADIUS + BUOY_RADIUS+1) }, right_bottom = {args.entity.position.x + (BEACON_RADIUS + BUOY_RADIUS+1), args.entity.position.y + (BEACON_RADIUS + BUOY_RADIUS+1) }}, name = {"incoming-buoy-entity", "outgoing-buoy-entity", "signal-buoy-entity", "disabled-buoy-entity" }  })
  for _,i in pairs(buoys) do
    buoysList[i.unit_number]:updateEntityWithChecks() --handles adding to newObject.buoysList
  end

  local docksList = global.lists["dock-entity"]
  local docks = args.entity.surface.find_entities_filtered({area={ left_top = {args.entity.position.x - (BEACON_RADIUS + 1 + DOCK_RADIUS), args.entity.position.y - (BEACON_RADIUS + 1 + DOCK_RADIUS) }, right_bottom = {args.entity.position.x + (BEACON_RADIUS + 1 + DOCK_RADIUS), args.entity.position.y + (BEACON_RADIUS + 1 + DOCK_RADIUS) }}, name = "dock-entity" })
  for _,i in pairs(docks) do
    docksList[i.unit_number].lighthouses[args.entity.unit_number] = true
    newObject.docksList[i.unit_number] = true
  end

  return newObject
end

APIInterface.registerFunction("on_built_entity", function (e)
    if e.created_entity.valid and e.created_entity.name == "lighthouse-entity" then
      local lighthouse = Lighthouse:new{  entity = e.created_entity,  }
    end
end)

function Lighthouse:destroy()
  local lighthouse = self.entity
  local lostSignal = self.signal
  local lostPos = self.entity.position
  local lighthousesList = global.lists["lighthouse-entity"]
  local buoysList = global.lists["buoy-entity"]
  local lighthouses = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - ((BEACON_RADIUS+BUOY_RADIUS+1) * 2), lighthouse.position.y - ((BEACON_RADIUS+BUOY_RADIUS+1) * 2) }, right_bottom = {lighthouse.position.x + ((BEACON_RADIUS+BUOY_RADIUS+1) * 2), lighthouse.position.y + ((BEACON_RADIUS+BUOY_RADIUS+1) * 2) }}, name = "lighthouse-entity"  })
  local buoys = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - (BEACON_RADIUS + BUOY_RADIUS + 1), lighthouse.position.y - (BEACON_RADIUS + BUOY_RADIUS + 1) }, right_bottom = {lighthouse.position.x + (BEACON_RADIUS + BUOY_RADIUS + 1), lighthouse.position.y + (BEACON_RADIUS + BUOY_RADIUS + 1) }}, name = {"incoming-buoy-entity", "outgoing-buoy-entity", "signal-buoy-entity", "disabled-buoy-entity" }  })
  local bool = false
  for _,i in pairs(buoys) do
    bool = true
    for _,j in pairs(lighthouses) do
      if j.unit_number ~= lighthouse.unit_number then
        if lighthousesList[j.unit_number].buoysList[i.unit_number] ~= nil then
          bool = false
          break
        end
      end
    end
    if bool then
      buoysList[i.unit_number]:updateEntityWithChecks({not_within_range = true})
    end
  end

  local docksList = global.lists["dock-entity"]
  local docks = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - (BEACON_RADIUS + 1+1), lighthouse.position.y - (BEACON_RADIUS + 1+1) }, right_bottom = {lighthouse.position.x + (BEACON_RADIUS + 1+1), lighthouse.position.y + (BEACON_RADIUS + 1+1) }}, name = "dock-entity" })
  for _,i in pairs(docks) do
    --note that the relevant entry might not actually already exist
    docksList[i.unit_number].lighthouses[lighthouse.unit_number] = nil
    --don't need to clear the lighthouse' dockList -- the lighthouse is gone
  end

  getmetatable(Lighthouse).destroy(self)

  local boatTemp = nil
  local boatsList = global.lists["basic-boat"]
  local boatsSignalList = global.signalLists["basic-boat"]
  if lostSignal ~= nil and boatsSignalList[lostSignal.type..lostSignal.name] then
    for boat_unit_number,_ in pairs(boatsSignalList[lostSignal.type..lostSignal.name]) do
      boatTemp = boatsList[boat_unit_number]
      if (boatTemp.currentTarget.x == lostPos.x) and (boatTemp.currentTarget.y == lostPos.y) then
        boatsList[boat_unit_number]:searchAll{signal = lostSignal}
      end
    end
  end

end

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.valid and e.entity.name == "lighthouse-entity" then
    global.lists["lighthouse-entity"][e.entity.unit_number]:destroy()
  end
end)


function Lighthouse:setSignal(args)
  --Arguments: signal = the new signal
  local oldSignalVal = self.signal
  local newSignalVal = args.signal

  local lighthouse = self.entity
  local lighthouse_unit_number = lighthouse.unit_number

  if(oldSignalVal == newSignalVal) then return end

  local lighthousesList_signalOrdered = global.signalLists["lighthouse-entity"]
  if oldSignalVal ~= nil then
    lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name][lighthouse_unit_number] = nil
    if next(lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name]) == nil then lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name] = nil end
  end
  if newSignalVal ~= nil then
    if not lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] then lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] = {} end
    lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name][lighthouse_unit_number] = true
  end
  self.signal = newSignalVal

  local boat = nil
  local boatsList = global.lists["basic-boat"]
  local boatSignalList = global.signalLists["basic-boat"]

  if oldSignalVal ~= nil then
    if boatSignalList[oldSignalVal.type..oldSignalVal.name] ~= nil then
      for boat_unit_number,_ in pairs(boatSignalList[oldSignalVal.type..oldSignalVal.name]) do
        boat = boatsList[boat_unit_number]
        if (boat.currentTarget.x == lighthouse.position.x) and (boat.currentTarget.y == lighthouse.position.y) then
          boat:searchAll{signal = oldSignalVal}
        end
      end
    end
  end
  if newSignalVal ~= nil then
    if boatSignalList[newSignalVal.type..newSignalVal.name] then
      local tempResult = nil
      for boat_unit_number,_ in pairs(boatSignalList[newSignalVal.type..newSignalVal.name]) do
        boat = boatsList[boat_unit_number]
        if boat:compareOne{lighthouse_unit_number = lighthouse_unit_number} then
          if boat.automated then
            boat:setDirection()
          end
        end
      end
    end
  end
end
