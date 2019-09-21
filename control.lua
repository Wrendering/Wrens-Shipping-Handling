------------------------------------------------ Buoy Placement

 --[[
PROGRAM ASSUMPTIONS:
- Boat automated state is only changed through the GUI [update]
- Currently, no cloning or direct movement (Picker et al) of anything [set][update]
- No tile types exist that change boat speed

TODO: Add on_collision update
--]]

local APIInterface = require("scripts/APIInterface")



----------------------------------------------------------- Entity Globals

if global.boatsList == nil then global.boatsList = {} end
if global.boatsList_signalOrdered == nil then global.boatsList_signalOrdered = {} end
if global.lighthousesList == nil then global.lighthousesList = {} end
if global.lighthousesList_signalOrdered == nil then global.lighthousesList_signalOrdered = {} end
if global.docksList == nil then global.docksList = {} end
if global.buoysList == nil then global.buoysList = {} end

local BEACON_RADIUS = 15 --game.entity_prototypes["lighthouse-entity"].supply_area_distance
local BUOY_RADIUS = 1
local DOCK_RADIUS = 1

------------------------------------------------ Dock Placement


APIInterface.registerFunction("on_built_entity",  function (e)
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
end)


APIInterface.registerFunction("on_built_entity", function(e)
  if e.created_entity.valid and e.created_entity.name == "dock-entity" then
    local docksList = global.docksList
    local dock = e.created_entity
    docksList[dock.unit_number] = { signal = nil, condition = 1, lighthouses = {}, entity = dock, }
    local lighthouses = dock.surface.find_entities_filtered({area={ left_top = {dock.position.x - (BEACON_RADIUS + 1 + DOCK_RADIUS), dock.position.y - (BEACON_RADIUS + 1 + DOCK_RADIUS) }, right_bottom = {dock.position.x + (BEACON_RADIUS + 1 + DOCK_RADIUS), dock.position.y + (BEACON_RADIUS + 1 + DOCK_RADIUS) }}, name = "lighthouse-entity" })
    local lighthousesList = global.lighthousesList
    for _,i in pairs(lighthouses) do
      docksList[dock.unit_number].lighthouses[i.unit_number] = true
      lighthousesList[i.unit_number].docksList[dock.unit_number] = true
    end
  end
end)

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.name == "dock-entity" then
    local docksList = global.docksList
    local lighthousesList = global.lighthousesList
    for i,_ in pairs(docksList[e.entity.unit_number].lighthouses) do
      lighthousesList[i].docksList[e.entity.unit_number] = nil
    end
    docksList[e.entity.unit_number] = nil

  end
end)

------------------------------------------------ Buoy Placement and Registration

--buoyPlacement_updateCheck, buoyPlacement_updateEntity

local buoyTypesList_entity = {[1] = "incoming-buoy-entity", [2] = "outgoing-buoy-entity", [3] = "signal-buoy-entity"}


APIInterface.registerFunction("on_built_entity", function (e)
  if e.created_entity.valid and string.find(e.created_entity.name, "buoy%-entity") ~= nil then
    global.buoysList[e.created_entity.unit_number] = {entity = e.created_entity, active_state = 1} --1 = "incoming", 2 = "outgoing", 3 = "signal"
    buoyPlacement_updateCheck(e.created_entity)
  end
end)

buoyPlacement_updateCheck = function(buoy, buoy_type_index)
  --buoy_type_index is an optional argument

  local lighthouses = buoy.surface.find_entities_filtered({area={ left_top = {buoy.position.x - (BEACON_RADIUS + BUOY_RADIUS), buoy.position.y - (BEACON_RADIUS + BUOY_RADIUS) }, right_bottom = {buoy.position.x + (BEACON_RADIUS + BUOY_RADIUS), buoy.position.y + (BEACON_RADIUS + BUOY_RADIUS) }}, name = "lighthouse-entity" })
  local lighthousesList = global.lighthousesList

  for _,i in pairs(lighthouses) do
    lighthousesList[i.unit_number].buoysList[buoy.unit_number] = nil
  end

  local new_buoy = buoyPlacement_updateEntity({ buoy = buoy, within_range = (next(lighthouses) ~= nil), buoy_type = (buoy_type_index and buoyTypesList_entity[buoy_type_index]) })

  for _,i in pairs(lighthouses) do
    lighthousesList[i.unit_number].buoysList[new_buoy.unit_number] = {entity = new_buoy, distance = (new_buoy.position.x - i.position.x)^2 + (new_buoy.position.y - i.position.y)^2 }
  end

  return new_buoy
end

buoyPlacement_updateEntity = function(arg)
  -- Required: buoy
  -- Optional: within_range, buoy_type
  arg.buoy_type = arg.buoy_type or buoyTypesList_entity[global.buoysList[arg.buoy.unit_number].active_state]
  arg.within_range = arg.within_range or false

  local buoy = arg.buoy
  local new_buoy
  local buoysList = global.buoysList

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
  buoy.destroy()
  return new_buoy
end

-- So buoys: each lighthouse has a buoyList. Default color of buoys is grey, they change color on_lighthouse_placement or on_buoy_placement, they're returned that way on_lighthouse_destruction IF not covered by anything
--

----------------------------------------------------------- Boat Beacon Checking

APIInterface.registerFunction("on_tick", function(e)
  local distance = nil
  local boat_entity = nil
  local position = nil
  local lighthouses = nil
  local buoys = {}
  local lighthouseData = nil
  local lighthousesList = global.lighthousesList

  for boat_unit_number, boatData in pairs(global.boatsList) do
    boat_entity = boatData.entity
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
end)

----------------------------------------------------------- Boat Movement Updating


boatDirector_search_all = function(arg)
  --Input table: signal = signal to search, EITHER boat OR boat_unit_number
  if not arg.boat then
    arg.boat = global.boatsList[arg.boat_unit_number].entity
  else
    arg.boat_unit_number = arg.boat.unit_number
  end
  arg.boatData = global.boatsList[arg.boat_unit_number]
  local boatPos = arg.boat.position
  local origTarget = nil
  local newTarget = nil
  local local_lighthousesList = global.lighthousesList
  if global.lighthousesList_signalOrdered[arg.signal.type..arg.signal.name] ~= nil then
    for lighthouse_unit_number,_ in pairs(global.lighthousesList_signalOrdered[arg.signal.type..arg.signal.name]) do
      if not origTarget then
        origTarget = local_lighthousesList[lighthouse_unit_number].entity.position
      else
        newTarget = local_lighthousesList[lighthouse_unit_number].entity.position
        if (boatPos.x - origTarget.x)^2 + (boatPos.y - origTarget.y)^2 > (boatPos.x - newTarget.x)^2 + (boatPos.y - newTarget.y)^2 then
          origTarget = newTarget
        end
      end
    end
    if arg.boatData.currentTarget == origTarget then
      return false
    end
    arg.boatData.currentTarget = origTarget
    return true
  end
  arg.boatData.currentTarget = nil
  return true
end

boatDirector_compare_one = function(arg)
  --Input table: boat_unit_number, lighthouse_unit_number
  arg.boatData = global.boatsList[arg.boat_unit_number]
  local boatPos = arg.boatData.entity.position
  local origTarget = arg.boatData.currentTarget
  local newTarget = global.lighthousesList[arg.lighthouse_unit_number].entity.position

  if origTarget == nil or (boatPos.x - origTarget.x)^2 + (boatPos.y - origTarget.y)^2 > (boatPos.x - newTarget.x)^2 + (boatPos.y - newTarget.y)^2 then
    arg.boatData.currentTarget = newTarget
    return true
  end
  return false
end

boatDirector_setDirection = function (boatData)
  if not boatData.currentTarget then return end
  local boatPos = boatData.entity.position
  local targetPos = boatData.currentTarget
  boatData.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
  boatData.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
end

boatDirector_slowDown = function(boatData)
  if boatData.entity.speed < 0.01 then
    boatData.entity.speed = 0
    boatData.entity.riding_state = {acceleration = defines.riding.acceleration.nothing, direction = defines.riding.direction.straight }
  else
    boatData.entity.riding_state = {acceleration = defines.riding.acceleration.braking, direction = defines.riding.direction.straight }
  end
end

--  v.automated and v.signal and (v.entity.burner.currently_burning or not v.entity.get_fuel_inventory().is_empty())

----------------------------------------------------------- Boat and Lighthouse GUI

APIInterface.registerFunction("on_built_entity", function (e)
    if e.created_entity.valid and e.created_entity.name == "basic-boat" then
        global.boatsList[e.created_entity.unit_number] = {
          entity = e.created_entity,
          automated = true,
          signal = nil,
          currentTarget = position,-- = nil, --unit_number = nil },
          selected_condition_index = 1,
          conditions = { [1] = { [1] = { type = "conditionIndex", value = 1, }, } }
        }
    end
end)

APIInterface.registerFunction("on_built_entity", function (e)
  if(e.created_entity.valid and e.created_entity.name == "basic-boat") then
    if(global.boatsList[e.created_entity.unit_number].automated) then
      e.created_entity.set_driver(e.created_entity.surface.create_entity({ name = "character", position = e.created_entity.position, force = game.forces.player}))
    end
  end
end)

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.name == "basic-boat" then
    local lostSignal = global.boatsList[e.entity.unit_number].signal
    if lostSignal ~= nil then
      global.boatsList_signalOrdered[lostSignal.type..lostSignal.name][e.entity.unit_number] = nil
      if next(global.boatsList_signalOrdered[lostSignal.type..lostSignal.name]) == nil then global.boatsList_signalOrdered[lostSignal.type..lostSignal.name] = nil end
    end
    global.boatsList[e.entity.unit_number] = nil
  end
end)

APIInterface.registerFunction("on_built_entity", function (e)
  if e.created_entity.valid and e.created_entity.name == "lighthouse-entity" then
    local lighthouse = e.created_entity
    local lighthousesList = global.lighthousesList
    lighthousesList[lighthouse.unit_number] =  { entity = e.created_entity, signal = nil, buoysList = {}, docksList = {} }
    local lighthouseData = lighthousesList[lighthouse.unit_number]

    local buoys = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - (BEACON_RADIUS + BUOY_RADIUS+1), lighthouse.position.y - (BEACON_RADIUS + BUOY_RADIUS+1) }, right_bottom = {lighthouse.position.x + (BEACON_RADIUS + BUOY_RADIUS+1), lighthouse.position.y + (BEACON_RADIUS + BUOY_RADIUS+1) }}, name = {"incoming-buoy-entity", "outgoing-buoy-entity", "signal-buoy-entity", "disabled-buoy-entity" }  })
    for _,i in pairs(buoys) do
      if i.name == "disabled-buoy-entity" then i = buoyPlacement_updateEntity({buoy = i, within_range = true, }) end
      lighthouseData.buoysList[i.unit_number] = {entity = i, distance = (lighthouse.position.x - i.position.x)^2 + (lighthouse.position.y - i.position.y)^2}
    end

    local docksList = global.docksList
    local docks = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - (BEACON_RADIUS + 1 + DOCK_RADIUS), lighthouse.position.y - (BEACON_RADIUS + 1 + DOCK_RADIUS) }, right_bottom = {lighthouse.position.x + (BEACON_RADIUS + 1 + DOCK_RADIUS), lighthouse.position.y + (BEACON_RADIUS + 1 + DOCK_RADIUS) }}, name = "dock-entity" })
    for _,i in pairs(docks) do
      docksList[i.unit_number].lighthouses[lighthouse.unit_number] = true
      lighthouseData.docksList[i.unit_number] = true
    end

  end
end)

APIInterface.registerFunction({"on_entity_died", "on_player_mined_entity"}, function (e)
  if e.entity.name == "lighthouse-entity" then
    local lostSignal = global.lighthousesList[e.entity.unit_number].signal
    if lostSignal ~= nil then
      global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name][e.entity.unit_number] = nil
      if next(global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name]) == nil then global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name] = nil end
    end
    global.lighthousesList[e.entity.unit_number] = nil

    local boatData = nil
    local tempResult = nil
    local boatsList = global.boatsList
    if lostSignal ~= nil and global.boatsList_signalOrdered[lostSignal.type..lostSignal.name] then
      for boat_unit_number,_ in pairs(global.boatsList_signalOrdered[lostSignal.type..lostSignal.name]) do
        boatData = boatsList[boat_unit_number]
        tempResult = boatDirector_search_all({signal = lostSignal, boat_unit_number = boat_unit_number})
        if boatData.automated then
          if boatData.currentTarget ~= nil and tempResult then
            boatDirector_setDirection(boatData)
          else
            boatDirector_slowDown(boatData)
          end
        end
      end
    end

    local lighthouse = e.entity
    local lighthousesList = global.lighthousesList
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
        buoyPlacement_updateEntity({buoy = i, within_range = false})
      end
    end

    local docksList = global.docksList
    local docks = lighthouse.surface.find_entities_filtered({area={ left_top = {lighthouse.position.x - (BEACON_RADIUS + 1+1), lighthouse.position.y - (BEACON_RADIUS + 1+1) }, right_bottom = {lighthouse.position.x + (BEACON_RADIUS + 1+1), lighthouse.position.y + (BEACON_RADIUS + 1+1) }}, name = "dock-entity" })
    for _,i in pairs(docks) do
      --note that the relevant entry might not actually already exist
      docksList[i.unit_number].lighthouses[lighthouse.unit_number] = nil
      --don't need to clear the lighthouse' dockList -- the lighthouse is gone
    end

  end
end)

------------------------------
require("scripts/OceanModifier")
require("scripts/GUI/BoatGUI")
require("scripts/GUI/DockGUI")
require("scripts/GUI/BuoyGUI")
require("scripts/GUI/LighthouseGUI")
