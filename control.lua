
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


----------------------------------------------------------- Entity Globals

if global.boatsList == nil then global.boatsList = {} end
if global.boatsList_signalOrdered == nil then global.boatsList_signalOrdered = {} end
if global.lighthousesList == nil then global.lighthousesList = {} end
if global.lighthousesList_signalOrdered == nil then global.lighthousesList_signalOrdered = {} end
if global.docksList == nil then global.docksList = {} end
if global.buoysList == nil then global.buoysList = {} end

----------------------------------------------------------- Boat Movement and Control

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

local boatCreation_on_built_entity = function (e)
    if e.created_entity.name == "basic-boat" then
        global.boatsList[e.created_entity.unit_number] = {
          entity = e.created_entity,
          automated = true,
          signal = nil,
          currentTarget = position,-- = nil, --unit_number = nil },
          selected_condition_index = 1,
          conditions = { [1] = { [1] = { type = "conditionIndex", value = 1, }, } }
        }
    end
end

local boatSetup_on_built_entity = function (e)
  if(e.created_entity.name == "basic-boat") then
    if(global.boatsList[e.created_entity.unit_number].automated) then
      e.created_entity.set_driver(e.created_entity.surface.create_entity({ name = "character", position = e.created_entity.position, force = game.forces.player}))
    end
  end
end

local boatDestruction_on_entity_died_on_player_mined_entity = function (e)
  if e.entity.name == "basic-boat" then
    local lostSignal = global.boatsList[e.entity.unit_number].signal
    if lostSignal ~= nil then
      global.boatsList_signalOrdered[lostSignal.type..lostSignal.name][e.entity.unit_number] = nil
      if next(global.boatsList_signalOrdered[lostSignal.type..lostSignal.name]) == nil then global.boatsList_signalOrdered[lostSignal.type..lostSignal.name] = nil end
    end
    global.boatsList[e.entity.unit_number] = nil
  end
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

    local boatData = nil
    local tempResult = nil
    local boatsList = global.boatsList
    if global.boatsList_signalOrdered[lostSignal.type..lostSignal.name] then
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
  end
end

local boatGui_on_gui_elem_changed = function (e)
  if e.element.name == "basicboat_signalpicker" then
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
end

local lighthouseGui_on_gui_elem_changed = function (e)
  if e.element.name == "lighthouse_signalpicker" then
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
end

local constructConditionChooser = function(e) end

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


    local gui_condition_buttons_table = gui_base.add({ type = "table", name = "basicboat_conditionButton_table", column_count = 2 })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Add", caption = "Add Condition" })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Remove", caption = "Remove Condition" })

    constructConditionChooser(gui_base, boat_data)
  end
end

local boatGui_Automated_on_gui_checked_state_changed = function(e)
  if e.element.name == "basicboat_automated" then
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
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("lighthouse_frame"), caption = "Lighthouse Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "lighthouse_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "lighthouse_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Lighthouse Signal: "})
    gui_auttab.add({type = "choose-elem-button", name = "lighthouse_signalpicker", elem_type = "signal", signal = global.lighthousesList[e.entity.unit_number].signal })
  end
end

local lighthouseGui_on_gui_closed = function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    if game.players[e.player_index].gui.top["lighthouse_frame"] then
      local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]
      gui_base.destroy()
    end
  end
end

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

 local boatGui_ConditionDropDown_on_gui_selection_state_changed = function(e)
  if string.find(e.element.name, "basicboat_condition_label_") ~= nil then
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
end

local boatGui_SubconditionSignal_on_gui_elem_changed = function(e)
  if string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.boatsList[unitNumber].conditions[conditionIndex][subconditionIndex].value = e.element.elem_value
  end
end

local boatGui_ConditionRadio_on_gui_checked_state_changed = function(e)
  if string.find(e.element.name, "basicboat_condition_radio_") ~= nil then
    for _, v in pairs(e.element.parent.parent.children) do
      v["basicboat_condition_radio_"..(string.gsub(v.name, "basicboat_condition_table", ""))].state = false
    end
    e.element.state = true

    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    global.boatsList[unitNumber].selected_condition_index = tonumber(string.gsub(e.element.name, "basicboat_condition_radio_", ""), 10)
  end
end

local boatGui_ConditionAdd_on_gui_click = function(e)
  if string.find(e.element.name, "basicboat_condition_label_") and e.element.caption == "+" then
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
end

local boatGui_ConditionButtons_on_gui_click = function(e)
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
end

local boatGui_ConditionNumber_on_gui_text_changed = function(e)
  if string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.boatsList[unitNumber].conditions[conditionIndex][subconditionIndex].value = tonumber(e.element.text,10)
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
    --boatDirector_on_tick(e)
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
    boatGui_Automated_on_gui_checked_state_changed(e)
    boatGui_ConditionRadio_on_gui_checked_state_changed(e)
end
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed_handler)

local on_gui_elem_changed_handler = function(e)
  boatGui_on_gui_elem_changed(e)
  boatGui_SubconditionSignal_on_gui_elem_changed(e)
  lighthouseGui_on_gui_elem_changed(e)
end
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed_handler)

local on_gui_selection_state_changed_handler = function(e)
  boatGui_ConditionDropDown_on_gui_selection_state_changed(e)
end
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed_handler)

local on_gui_click_handler = function (e)
  boatGui_ConditionAdd_on_gui_click(e)
  boatGui_ConditionButtons_on_gui_click(e)
end
script.on_event(defines.events.on_gui_click, on_gui_click_handler)

local on_gui_text_changed_handler = function(e)
  boatGui_ConditionNumber_on_gui_text_changed(e)
end
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed_handler)
