
------------------------------------------------ Dock Placement

local dockPlacement_on_built_entity = function (e)
  if e.created_entity.name == "dock-entity" then
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


----------------------------------------------------------- Boat and Lighthouse Globals

if global.boatsList == nil then
    global.boatsList = {}
end


--A boat's conditions table contains tables of tables including a "type" and "value" field.
-- types are "conditionIndex", "logic", "numberValue", and "signalValue"
--Pass in: time, numberValue, signalValue, boat
local conditionTable = {
  ["A"] = { description = "Leave Immediately", defaultValue = nil, defaultSignal = nil, finished = function(...) return true end },
  ["B"] = { description = "Wait Until _ Seconds Elapsed", defaultValue = 5, defaultSignal = nil, finished = function(...) return (arg.time >= arg.numberValue) end },
  ["C"] = { description = "Boat Full", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).can_insert("rocket-silo") end },
  ["D"] = { description = "Boat Empty", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).is_empty() end },
}

local boatCreation_on_built_entity = function (e)
    if e.created_entity.name == "basic-boat" then
        global.boatsList[e.created_entity.unit_number] = {
          entity = e.created_entity,
          automated = true,
          signal = nil,
          selected_condition_index = 0,
          conditions = {
            [1] = { [1] = { type = "conditionIndex", value = "A", }, [2] = { type = "logic", value = "AND", }, [3] = { type = "conditionIndex", value = "C", } },
            [2] = { [1] = { type = "conditionIndex", value = "B", }, [2] = { type = "numberValue", value = "5", }, [3] = { type = "conditionIndex", value = "D", }, [4] = { type = "signalValue", value = {type = "item", name = "iron-plate"}, } },
          }
        }
    end
end

local boatDestruction_on_entity_died_on_player_mined_entity = function (e)
    if e.entity.name == "basic-boat" then
        global.boatsList[e.entity.unit_number] = nil
    end
end

if global.lighthousesList == nil then
    global.lighthousesList = {}
end

if global.lighthousesList_signalOrdered == nil then
    global.lighthousesList_signalOrdered = {}
end

local lighthouseCreation_on_built_entity = function (e)
    if e.created_entity.name == "lighthouse-entity" then
        global.lighthousesList[e.created_entity.unit_number] = { entity = e.created_entity, signal = nil }
    end
end

local lighthouseDestruction_on_entity_died_on_player_mined_entity = function (e)
    if e.entity.name == "lighthouse-entity" then
        local lostSignal = global.lighthousesList[e.entity.unit_number].signal
        if lostSignal ~= nil then
          global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name][e.entity.unit_number] = nil
          if next(global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name]) == nil then global.lighthousesList_signalOrdered[lostSignal.type..lostSignal.name] = nil end
        end
        global.lighthousesList[e.entity.unit_number] = nil

    end
end


----------------------------------------------------------- Boat and Lighthouse GUI picker handling


local boatGui_on_gui_opened = function (e)
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

    --local gui_condition_base_base = gui_base.add({ type = "scroll-pane", name = "basicboat_condition_condition", vertical_scroll_policy = "always", })--horizontal_scroll_policy = "never" })
--[[    local gui_condition_base = gui_base.add({ type = "scroll-pane", name = "basicboat_condition"})
    for i,condition in pairs(boat_data.conditions) do
      local gui_current_condition = gui_condition_base.add({ type = "flow", name = ("basicboat_condition_"..i), direction = "horizontal"})
      local j = 0
      for _,subcondition in ipairs(condition) do
        if subcondition.type == "conditionIndex" then
          gui_current_condition.add({ type = "button", name = "basicboat_condition_label_"..j, caption = conditionTable[subcondition.value].description,  })
        elseif subcondition.type == "logic" then
          gui_current_condition.add({ type = "button", name = "basicboat_condition_label_"..j, caption = subcondition.value })
        elseif subcondition.type == "numberValue" then
          gui_current_condition.add({ type = "button", name = "basicboat_condition_label_"..j, caption = subcondition.value })
        elseif subcondition.type == "signalValue" then
          gui_current_condition.add({ type = "choose-elem-button", name = "basicboat_condition_label_"..j, elem_type = "signal", signal = subcondition.value })
        else
          --throw an error of some kind, this shouldn't happen
        end
        j = j + 1
      end
      gui_current_condition.add({type = "button", name = "basicboat_condition_label_"..j, caption = "+"})
    end]]--


  end
end

local boatGui_on_gui_checked_state_changed = function(e)
  if e.element.name == "basicboat_automated" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local entity = global.boatsList[unitNumber].entity
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
end

local boatGui_on_gui_elem_changed = function (e)
  if e.element.name == "basicboat_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    global.boatsList[unitNumber].signal = e.element.elem_value
  end
end

local boatGui_on_gui_closed = function (e)
  if e.entity and e.entity.name == "basic-boat" then
    if game.players[e.player_index].gui.top["basicboat_frame"] then
      --local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
      --gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]

      game.players[e.player_index].gui.top["basicboat_frame"].destroy()
    end
  end
end

local lighthouseGui_on_gui_opened = function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = "lighthouse_frame", caption = "Lighthouse Configuration", direction = "vertical" })
    local gui_auttab = gui_base.add({type = "table", name = "lighthouse_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Lighthouse Signal: "})
    gui_auttab.add({type = "choose-elem-button", name = "lighthouse_signalpicker", elem_type = "signal", signal = global.lighthousesList[e.entity.unit_number].signal })
  end
end

local lighthouseGui_on_gui_closed = function (e)
    if e.entity and e.entity.name == "lighthouse-entity" then
        if game.players[e.player_index].gui.top["lighthouse_frame"] then
            local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]

            local oldSignalVal = global.lighthousesList[e.entity.unit_number].signal
            local newSignalVal = gui_base["lighthouse_signalpicker_table"]["lighthouse_signalpicker"].elem_value

            if oldSignalVal ~= nil then
              global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name][e.entity.unit_number] = nil
              if next(global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name]) == nil then global.lighthousesList_signalOrdered[oldSignalVal.type..oldSignalVal.name] = nil end
            end
            if newSignalVal ~= nil then
              if not global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] then global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name] = {} end
              global.lighthousesList_signalOrdered[newSignalVal.type..newSignalVal.name][e.entity.unit_number] = true
            end
            global.lighthousesList[e.entity.unit_number].signal = newSignalVal

            gui_base.destroy()
        end
    end
end


----------------------------------------------------------- Boat Movement and Control

local boatSetup_on_built_entity = function (e)
  if(e.created_entity.name == "basic-boat") then
    e.created_entity.set_driver(e.created_entity.surface.create_entity({ name = "character", position = e.created_entity.position, force = game.forces.player}))
  end
end

local boatDirector_on_tick = function (e)
    if e.tick % 60 == 0 then
        for _,v in pairs(global.boatsList) do
            if v.automated and (v.entity.burner.currently_burning or not v.entity.get_fuel_inventory().is_empty()) then
                local boatPos = v.entity.position
                if v.signal ~= nil and global.lighthousesList_signalOrdered[v.signal.type..v.signal.name] ~= nil then

                  local targetPos = nil
                  local potentialTarget = nil
                  local targetDistance = nil

                  for k,_ in pairs(global.lighthousesList_signalOrdered[v.signal.type..v.signal.name]) do
                    potentialTarget = global.lighthousesList[k].entity.position
                    if targetPos == nil then
                      targetPos = potentialTarget
                    else
                      targetDistance = targetDistance or (targetPos.x - boatPos.x)^2 + (targetPos.y - boatPos.y)^2
                      if (boatPos.x - potentialTarget.x)^2 + (boatPos.y - potentialTarget.y)^2 < targetDistance then
                        targetPos = potentialTarget
                      end
                    end
                  end
                  if targetPos ~= nil then
                    v.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
                    v.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
                  end
                else
                  if v.entity.speed < 0.01 then
                    v.entity.speed = 0
                    v.entity.riding_state = {acceleration = defines.riding.acceleration.nothing, direction = defines.riding.direction.straight }
                  else
                    v.entity.riding_state = {acceleration = defines.riding.acceleration.braking, direction = defines.riding.direction.straight }
                  end
                end
            end
        end
    end
end

----------------------------------------------------------- Ocean Edge Converter

OCEAN_EFFECT_EDGE = 50
OCEAN_SHORE_ZONE = 8
OCEAN_SHALLOW_ZONE = 16

HARBOR_MOUTH_SEARCH_LENGTH = 6

local oceanOverwriter_on_chunk_generated = function (e)

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

end

--x==y and x or y -- x==y ? x : y --works as long as x is not false or nil

----------------------------------------------------------- Register Handlers

local on_tick_handler = function(e)
    --boatPrint_on_tick(e)
    boatDirector_on_tick(e)
end
script.on_event(defines.events.on_tick, on_tick_handler)

local on_built_entity_handler = function(e)
    boatCreation_on_built_entity(e)
    boatSetup_on_built_entity(e)
    lighthouseCreation_on_built_entity(e)
    dockPlacement_on_built_entity(e)
end
script.on_event(defines.events.on_built_entity, on_built_entity_handler)

local on_entity_died_handler = function(e)
    boatDestruction_on_entity_died_on_player_mined_entity(e)
    lighthouseDestruction_on_entity_died_on_player_mined_entity(e)
end
script.on_event(defines.events.on_entity_died, on_entity_died_handler)

local on_player_mined_entity_handler = function(e)
    boatDestruction_on_entity_died_on_player_mined_entity(e)
    lighthouseDestruction_on_entity_died_on_player_mined_entity(e)
end
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity_handler)

local on_chunk_generated_handler = function(e)
    oceanOverwriter_on_chunk_generated(e)
end
script.on_event(defines.events.on_chunk_generated, on_chunk_generated_handler)

local on_gui_opened_handler = function(e)
    boatGui_on_gui_opened(e)
    lighthouseGui_on_gui_opened(e)
end
script.on_event(defines.events.on_gui_opened, on_gui_opened_handler)

local on_gui_closed_handler = function(e)
    boatGui_on_gui_closed(e)
    lighthouseGui_on_gui_closed(e)
end
script.on_event(defines.events.on_gui_closed, on_gui_closed_handler)

local on_gui_checked_state_changed_handler = function(e)
    boatGui_on_gui_checked_state_changed(e)
end
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed_handler)

local on_gui_elem_changed_handler = function(e)
  boatGui_on_gui_elem_changed(e)
end
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed_handler)
