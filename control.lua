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

local buoyPlacement_updateCheck, buoyPlacement_updateEntity

APIInterface.registerFunction("on_built_entity", function (e)
  if e.created_entity.valid and string.find(e.created_entity.name, "buoy%-entity") ~= nil then
    global.buoysList[e.created_entity.unit_number] = {entity = e.created_entity, active_state = 1} --1 = "incoming", 2 = "outgoing", 3 = "signal"
    buoyPlacement_updateCheck(e.created_entity)
  end
end)

local buoyTypesList = {[1] = "Incoming", [2] = "Outgoing", [3] = "Signal"}
local buoyTypesList_entity = {[1] = "incoming-buoy-entity", [2] = "outgoing-buoy-entity", [3] = "signal-buoy-entity"}


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


local boatDirector_search_all = function(arg)
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

local boatDirector_compare_one = function(arg)
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

local boatDirector_setDirection = function (boatData)
  if not boatData.currentTarget then return end
  local boatPos = boatData.entity.position
  local targetPos = boatData.currentTarget
  boatData.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
  boatData.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
end

local boatDirector_slowDown = function(boatData)
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

APIInterface.registerFunction("on_gui_elem_changed", function (e)
  if e.element.valid and e.element.name == "basicboat_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local boat_unit_number = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boatData = global.boatsList[boat_unit_number]

    local oldSignalVal = boatData.signal
    local newSignalVal = e.element.elem_value

    if oldSignalVal ~= nil then
      global.boatsList_signalOrdered[oldSignalVal.type..oldSignalVal.name][boat_unit_number] = nil
      if next(global.boatsList_signalOrdered[oldSignalVal.type..oldSignalVal.name]) == nil then global.boatsList_signalOrdered[oldSignalVal.type..oldSignalVal.name] = nil end
    end
    if newSignalVal ~= nil then
      if not global.boatsList_signalOrdered[newSignalVal.type..newSignalVal.name] then global.boatsList_signalOrdered[newSignalVal.type..newSignalVal.name] = {} end
      global.boatsList_signalOrdered[newSignalVal.type..newSignalVal.name][boat_unit_number] = true
    end
    boatData.signal = newSignalVal

    if newSignalVal ~= nil then
      local tempResult = boatDirector_search_all({signal = newSignalVal, boat_unit_number = boat_unit_number})
      if boatData.automated then
        if boatData.currentTarget ~= nil and tempResult then
          boatDirector_setDirection(boatData)
        else
          boatDirector_slowDown(boatData)
        end
      end
    end
  end
end)

APIInterface.registerFunction("on_gui_elem_changed", function (e)
  if e.element.valid and e.element.name == "lighthouse_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]
    local _, lighthouse_unit_number = next(gui_base.lighthouse_id.children_names) lighthouse_unit_number = tonumber(lighthouse_unit_number, 10) --[#gui_base.lighthouse_id.children_names].name
    local lighthouse = global.lighthousesList[lighthouse_unit_number]

    local oldSignalVal = global.lighthousesList[lighthouse_unit_number].signal
    local newSignalVal = gui_base["lighthouse_signalpicker_table"]["lighthouse_signalpicker"].elem_value

    if oldSignalVal ~= nil then
      global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name][lighthouse_unit_number] = nil
      if next(global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name]) == nil then global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name] = nil end
    end
    if newSignalVal ~= nil then
      if not global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] then global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] = {} end
      global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name][lighthouse_unit_number] = true
    end
    lighthouse.signal = newSignalVal

    local boatData = nil
    local boatsList = global.boatsList
    if oldSignalVal ~= nil then
      if global.boatsList_signalOrdered[oldSignalVal.type..oldSignalVal.name] ~= nil then
        for boat_unit_number,_ in pairs(global.boatsList_signalOrdered[oldSignalVal.type..oldSignalVal.name]) do
          boatData = boatsList[boat_unit_number]
          tempResult = boatDirector_search_all({signal = oldSignalVal, boat_unit_number = boat_unit_number})
          if boatData.automated then
            if boatData.currentTarget ~= nil and tempResult then
              boatDirector_setDirection(boatData)
            else
              boatDirector_slowDown(boatData)
            end
          end
        end
      end
    end
    if newSignalVal ~= nil then
      if global.boatsList_signalOrdered[newSignalVal.type..newSignalVal.name] then
        local tempResult = nil
        for boat_unit_number,_ in pairs(global.boatsList_signalOrdered[newSignalVal.type..newSignalVal.name]) do
          boatData = boatsList[boat_unit_number]
          if boatDirector_compare_one({boat_unit_number = boat_unit_number, lighthouse_unit_number = lighthouse_unit_number}) then
            if boatData.automated then
              boatDirector_setDirection(boatData)
            end
          end
        end
      end
    end
  end
end)

local constructConditionChooser = function(e) end --forward declaration

APIInterface.registerFunction("on_gui_opened", function (e)
  if e.entity and e.entity.name == "basic-boat" then
    local boat_data = global.boatsList[e.entity.unit_number]

    local kludge = game.players[e.player_index].gui.top.add({ type = "flow", name = "basicboat_frame", direction = "vertical" })
    local gui_base = kludge.add({type = "frame", name = "basicboat_id_"..(e.entity.unit_number), caption = "Boat Configuration", direction = "vertical" })
    local gui_auttab = gui_base.add({type = "table", name = "basicboat_automated_table", column_count = 2 })
    local gui_sigtab = gui_base.add({type = "table", name = "basicboat_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Automation Enabled: "})
    gui_auttab.add({type = "checkbox", name = "basicboat_automated", state = boat_data.automated})
    gui_sigtab.add({type = "label", caption = "Automation Target Signal: "})
    gui_sigtab.add({type = "choose-elem-button", name = "basicboat_signalpicker", elem_type = "signal", signal = boat_data.signal })


    local gui_condition_buttons_table = gui_base.add({ type = "table", name = "basicboat_conditionButton_table", column_count = 2 })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Add", caption = "Add Condition" })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Remove", caption = "Remove Condition" })

    constructConditionChooser(gui_base, boat_data)
  end
end)

APIInterface.registerFunction("on_gui_checked_state_changed", function(e)
  if e.element.valid and e.element.name == "basicboat_automated" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boatData = global.boatsList[unitNumber]
    local entity = boatData.entity
    --repeat
      local newAutomated = gui_base["basicboat_automated_table"]["basicboat_automated"].state
      if global.boatsList[unitNumber].automated ~= newAutomated then
        if newAutomated then
          if(entity.get_driver()) then
            if(entity.get_driver().player ~= nil) then
              if(entity.get_passenger() ~= nil and entity.get_passenger().player ~= nil) then
                game.players[e.player_index].print("WARNING: Can't set boat to automated while it has a driver.")
                e.element.state = not e.element.state
                return
                --break
              else
                entity.set_passenger(entity.get_driver())
              end
            end
          end
          entity.set_driver(nil)
          entity.set_driver(entity.surface.create_entity({ name = "character", position = entity.position, force = game.forces.player}))

          if boatData.signal ~= nil then
            local tempResult = boatDirector_search_all({signal = boatData.signal, boat_unit_number = entity.unit_number})
            if boatData.currentTarget ~= nil and tempResult then
              boatDirector_setDirection(boatData)
            else
              boatDirector_slowDown(boatData)
            end
          end
        else
          if(entity.get_driver() ~= nil and entity.get_driver().player ~= nil) then
            game.players[e.player_index].print("ERROR: Please tell mod author 2") --how did this happen?
          end
          if entity.get_driver() then entity.get_driver().destroy() end
          entity.set_driver(nil)
          if entity.get_passenger() and entity.get_passenger().player then
            entity.set_driver(entity.get_passenger())
            entity.set_passenger(nil)
          end
        end
        global.boatsList[unitNumber].automated = newAutomated
      end
    return
    --until(true)
  end
end)

APIInterface.registerFunction("on_gui_closed", function (e)
  if e.entity and e.entity.name == "basic-boat" then
    if game.players[e.player_index].gui.top["basicboat_frame"] then
      --local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
      --gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]

      game.players[e.player_index].gui.top["basicboat_frame"].destroy()
    end
  end
end)

APIInterface.registerFunction("on_gui_opened", function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("lighthouse_frame"), caption = "Lighthouse Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "lighthouse_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "lighthouse_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Lighthouse Signal: "})
    gui_auttab.add({type = "choose-elem-button", name = "lighthouse_signalpicker", elem_type = "signal", signal = global.lighthousesList[e.entity.unit_number].signal })
  end
end)

APIInterface.registerFunction("on_gui_closed", function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    if game.players[e.player_index].gui.top["lighthouse_frame"] then
      local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]
      gui_base.destroy()
    end
  end
end)

APIInterface.registerFunction("on_gui_opened", function (e)
  if e.entity and e.entity.name == "dock-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("dock_frame"), caption = "Dock Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "dock_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "dock_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Signal Applied: "})
    gui_auttab.add({type = "choose-elem-button", name = "dock_signalpicker", elem_type = "signal", signal = global.docksList[e.entity.unit_number].signal })
    local gui_contab = gui_base.add({type = "table", name = "dock_conditionpicker_table", column_count = 2 })
    gui_contab.add({type = "label", caption = "Condition Index Applied: "})
    gui_contab.add({ type = "textfield", name = "dock_conditionpicker", text = global.docksList[e.entity.unit_number].conditionIndex, numeric = true, allow_decimal = false, allow_negative = false })

  end
end)

APIInterface.registerFunction("on_gui_closed", function (e)
  if e.entity and e.entity.name == "dock-entity" then
    if game.players[e.player_index].gui.top["dock_frame"] then
      local gui_base = game.players[e.player_index].gui.top["dock_frame"]
      gui_base.destroy()
    end
  end
end)

APIInterface.registerFunction("on_gui_text_changed", function(e)
  if e.element.valid and e.element.name == "dock_conditionpicker" then
    local gui_base = game.players[e.player_index].gui.top["dock_frame"]
    local _, dock_unit_number = next(gui_base.dock_id.children_names) dock_unit_number = tonumber(dock_unit_number, 10)
    local dockData = global.docksList[dock_unit_number]

    if tonumber(e.element.text, 10) == 0 then e.element.text = 1 end

    dockData.conditionIndex = tonumber(e.element.text,10)
  end
end)

APIInterface.registerFunction("on_gui_elem_changed", function (e)
  if e.element.valid and e.element.name == "dock_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["dock_frame"]
    local _, dock_unit_number = next(gui_base.dock_id.children_names) dock_unit_number = tonumber(dock_unit_number, 10)
    local dockData = global.docksList[dock_unit_number]

    dockData.signal = e.element.elem_value
  end
end)


APIInterface.registerFunction("on_gui_opened", function (e)
  if e.entity and string.find(e.entity.name, "buoy%-entity") ~= nil then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("buoy_frame"), caption = "Buoy Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "buoy_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "buoy_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Buoy State: "})
    gui_auttab.add({type = "drop-down", name = "buoy_statepicker", items = buoyTypesList, selected_index = global.buoysList[e.entity.unit_number].active_state })
  end
end)

APIInterface.registerFunction("on_gui_closed", function (e)
  if e.entity and string.find(e.entity.name, "buoy%-entity") ~= nil then
    if game.players[e.player_index].gui.top["buoy_frame"] then
      local gui_base = game.players[e.player_index].gui.top["buoy_frame"]
      gui_base.destroy()
    end
  end
end)

APIInterface.registerFunction("on_gui_selection_state_changed", function(e)
  if e.element.valid and e.element.name == "buoy_statepicker" then
    local gui_base = game.players[e.player_index].gui.top["buoy_frame"]
    local _, buoy_unit_number = next(gui_base.buoy_id.children_names) buoy_unit_number = tonumber(buoy_unit_number, 10)
    local buoyData = global.buoysList[buoy_unit_number]
    local buoy = buoyData.entity

    buoyData.active_state = e.element.selected_index

    local new_buoy = buoyPlacement_updateCheck(buoy, buoyData.active_state)

    gui_base.destroy()

    game.players[e.player_index].opened = new_buoy
  end
end)

----------------------------------------------------------- Boat Conditions Picking GUI

local logicTable = {
  [1] = "AND", [2] = "OR", [3] = "XOR", --[4] = "NOR", [5] = "XOR",
}
--A boat's conditions table contains tables of tables including a "type" and "value" field.
-- types are "conditionIndex", "logic", "numberValue", and "signalValue"
--Pass in: time, numberValue, signalValue, boat
-- VERY IMPORTANT: subconditions go numberValue -> signalValue, if a subcondition requires both
local conditionTable = {
  [1] = { description = "Leave Immediately", defaultValue = nil, defaultSignal = nil, finished = function(...) return true end },
  [2] = { description = "Wait Until _ Seconds Elapsed", defaultValue = 5, defaultSignal = nil, finished = function(...) return (arg.time >= arg.numberValue) end },
  [3] = { description = "Boat Full", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).can_insert("rocket-silo") end },
  [4] = { description = "Boat Empty", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).is_empty() end },
}

constructConditionChooser = function(gui_base, boat_data)

  local gui_condition_base = gui_base.add({ type = "scroll-pane", name = "basicboat_condition", vertical_scroll_policy = "always"})
  local temp_style = gui_condition_base.style
  temp_style.minimal_height = 40
  --gui_condition_base.style = temp_style.name
  --local gui_editor_base = gui_condition_base.add({ type = "line", name = "basicboat_editor_line1", direction = "horizontal" })

  for i,condition in ipairs(boat_data.conditions) do
    local gui_current_condition_table = gui_condition_base.add({ type = "table", name = ("basicboat_condition_table"..i), column_count = 3})
    gui_current_condition_table.add({ type = "label", name = ("basicboat_condition_number_"..i), caption = i})
    gui_current_condition_table.add({ type = "radiobutton", name = ("basicboat_condition_radio_"..i), state = (boat_data.selected_condition_index == i)})
    local gui_current_condition = gui_current_condition_table.add({ type = "flow", name = ("basicboat_condition_"..i), direction = "horizontal"})
    local j = 1
    for _,subcondition in ipairs(condition) do
      if subcondition.type == "conditionIndex" then
        gui_current_condition.add({ type = "drop-down", name = "basicboat_condition_label_"..j, items = ((function(list) local names = {} for i,v in ipairs(list) do names[i] = v.description  end names[#names + 1] = "Remove this condition" return names end )(conditionTable)), selected_index = subcondition.value,  })
      elseif subcondition.type == "logic" then
        gui_current_condition.add({ type = "drop-down", name = "basicboat_condition_label_"..j, items = logicTable, selected_index = subcondition.value })
      elseif subcondition.type == "numberValue" then
        gui_current_condition.add({ type = "textfield", name = "basicboat_condition_label_"..j, text = subcondition.value, numeric = true,  })
      elseif subcondition.type == "signalValue" then
        gui_current_condition.add({ type = "choose-elem-button", name = "basicboat_condition_label_"..j, elem_type = "signal", signal = subcondition.value })
      else
        --throw an error of some kind, this shouldn't happen
      end
      j = j + 1
    end
    gui_current_condition.add({type = "button", name = "basicboat_condition_label_"..j, caption = "+"})
  end
  --local gui_editor_base = gui_condition_base.add({ type = "line", name = "basicboat_editor_line2", direction = "horizontal" })
end

APIInterface.registerFunction("on_gui_selection_state_changed", function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat_data = global.boatsList[unitNumber]

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)
    local condition = boat_data.conditions[conditionIndex]
    if(condition[subconditionIndex].type == "conditionIndex") then
      local minus = 0
      if conditionTable[condition[subconditionIndex].value].defaultValue ~= nil then
        minus = minus + 1
      end
      if conditionTable[condition[subconditionIndex].value].defaultSignal ~= nil then
        minus = minus + 1
      end
      if conditionTable[e.element.selected_index] == nil then
        minus = minus + 1   --delete this one
        minus = minus + 1   --for the logic condition
      else
        if conditionTable[e.element.selected_index].defaultValue ~= nil then
          minus = minus - 1
        end
        if conditionTable[e.element.selected_index].defaultSignal ~= nil then
          minus = minus - 1
        end
      end

      local tempIndex = subconditionIndex
      if minus > 0 then
        if conditionTable[e.element.selected_index] ~= nil then tempIndex = subconditionIndex + 1 end
        for i = (tempIndex + minus), #(condition), 1 do
          condition[i-minus] = condition[i]
        end
        for i = (#condition), (#condition - minus + 1), -1 do
          condition[i] = nil
        end
        if next(condition) == nil then
          condition[1] = { type = "conditionIndex", value = 1, }
        end
        tempIndex = tempIndex - 1
      end
      if minus <= 0 or tempIndex == subconditionIndex then
        if minus < 0 then
          for i = #(condition), (subconditionIndex + 1), -1 do
            condition[i-minus] = condition[i]
          end
        end
        local plus = 1
        if conditionTable[e.element.selected_index].defaultValue ~= nil then
          condition[subconditionIndex+plus] = {type = "numberValue", value = conditionTable[e.element.selected_index].defaultValue}
          plus = plus + 1
        end
        if conditionTable[e.element.selected_index].defaultSignal ~= nil then
          condition[subconditionIndex+plus] = {type = "signalValue", value = conditionTable[e.element.selected_index].defaultSignal}
        end

        condition[subconditionIndex].value = e.element.selected_index
      end

      gui_base["basicboat_condition"].destroy()
      constructConditionChooser(gui_base, boat_data)
    else
      condition[subconditionIndex].value = e.element.selected_index
    end
  end
end)

APIInterface.registerFunction("on_gui_elem_changed", function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.boatsList[unitNumber].conditions[conditionIndex][subconditionIndex].value = e.element.elem_value
  end
end)

APIInterface.registerFunction("on_gui_checked_state_changed", function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_radio_") ~= nil then
    for _, v in pairs(e.element.parent.parent.children) do
      v["basicboat_condition_radio_"..(string.gsub(v.name, "basicboat_condition_table", ""))].state = false
    end
    e.element.state = true

    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    global.boatsList[unitNumber].selected_condition_index = tonumber(string.gsub(e.element.name, "basicboat_condition_radio_", ""), 10)
  end
end)

APIInterface.registerFunction("on_gui_click", function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") and e.element.caption == "+" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat_data = global.boatsList[unitNumber]
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)
    local condition = boat_data.conditions[conditionIndex]

    condition[ #condition + 1 ] = { type = "logic", value = 1 }
    condition[ #condition + 1 ] = { type = "conditionIndex", value = 1 }

    gui_base["basicboat_condition"].destroy()
    constructConditionChooser(gui_base, boat_data)
  end
end)

APIInterface.registerFunction("on_gui_click", function(e)
  if e.element.valid and e.element.parent.name == "basicboat_conditionButton_table" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat_data = global.boatsList[unitNumber]

    if e.element.name == "basicboat_conditionButton_Add" then
      boat_data.conditions[#(boat_data.conditions) + 1] = { [1] = {type = "conditionIndex", value = 1 } }
    else
      for i = boat_data.selected_condition_index, #(boat_data.conditions) - 1, 1 do
        boat_data.conditions[i] = boat_data.conditions[i+1]
      end
      boat_data.conditions[#(boat_data.conditions)] = nil
      if next(boat_data.conditions) == nil then
        boat_data.conditions[1] = { [1] = {type = "conditionIndex", value = 1 } }
      end
      boat_data.selected_condition_index = 1
    end
    gui_base["basicboat_condition"].destroy()
    constructConditionChooser(gui_base, boat_data)
  end
end)

APIInterface.registerFunction("on_gui_text_changed", function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.boatsList[unitNumber].conditions[conditionIndex][subconditionIndex].value = tonumber(e.element.text,10)
  end
end)

----------------------------------------------------------- Ocean Edge Converter

OCEAN_EFFECT_EDGE = 50
OCEAN_SHORE_ZONE = 8
OCEAN_SHALLOW_ZONE = 16

HARBOR_MOUTH_SEARCH_LENGTH = 6

APIInterface.registerFunction("on_chunk_generated", function (e)

    if e.area.right_bottom.x > OCEAN_EFFECT_EDGE then     --could later be changed to a range thing... for now, 1 chunk is fine
        for i,v in pairs(e.surface.find_entities(e.area)) do
            if(v.type ~= nil and v.type ~= "character") then
                v.destroy()
            end
        end
    end
    e.surface.destroy_decoratives({area = e.area})

    local setOfTiles = {} --local i = 1 ;
    local right_edge ; local left_edge

    local sub_overwriter_oceanOverwriter_handler = function (left_edge, right_edge, tilename)
        --hopefully, can affect e, and setOfTiles due to closures(?)
        for y = e.area.left_top.y, e.area.right_bottom.y do
            for x = left_edge, right_edge do
                setOfTiles[tostring(x).."__"..tostring(y)] = { name = tilename, position = { x, y} }
            end
        end
    end

    left_edge = OCEAN_EFFECT_EDGE ; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    right_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE ; if e.area.right_bottom.x < right_edge then right_edge = e.area.right_bottom.x end
    local orig = sub_overwriter_oceanOverwriter_handler(left_edge, right_edge, "sand-1")

    for y = e.area.right_bottom.y, e.area.left_top.y, -1 do
        local test_for_water = false
        local leftestX = right_edge
        for x = right_edge, left_edge - HARBOR_MOUTH_SEARCH_LENGTH, -1 do
            if e.surface.get_tile(x,y).name == "water" then --test for other water types later
                test_for_water = true
                leftestX = x
            end
        end
        if test_for_water then
            if leftestX > left_edge then left_edge = leftestX end
            for x = right_edge, left_edge, -1 do
                local new_tile = "ocean-shallow-water"
                if (math.random() > (x - OCEAN_EFFECT_EDGE) / OCEAN_SHORE_ZONE) then new_tile = "water" end
                setOfTiles[tostring(x).."__"..tostring(y)].name = new_tile
            end
        end
    end

    left_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    right_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE + OCEAN_SHALLOW_ZONE; if e.area.right_bottom.x < right_edge then right_edge = e.area.right_bottom.x end
    sub_overwriter_oceanOverwriter_handler(left_edge, right_edge, "ocean-shallow-water")

    left_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE + OCEAN_SHALLOW_ZONE; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    sub_overwriter_oceanOverwriter_handler(left_edge, e.area.right_bottom.x, "ocean-deep-water")

    e.surface.set_tiles(setOfTiles, true)

end)
