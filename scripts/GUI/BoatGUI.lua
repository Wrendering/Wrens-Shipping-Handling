local APIInterface = require("scripts/APIInterface")

local boatGUI = {}

--A boat's conditions table contains tables of tables including a "type" and "value" field.
-- types are "conditionIndex", "logic", "numberValue", and "signalValue"
--Pass in: time, numberValue, signalValue, boat
-- VERY IMPORTANT: subconditions go numberValue -> signalValue, if a subcondition requires both
boatGUI.conditionTable = {
  [1] = { description = "Leave Immediately", defaultValue = nil, defaultSignal = nil, finished = function(...) return true end },
  [2] = { description = "Wait Until _ Seconds Elapsed", defaultValue = 5, defaultSignal = nil, finished = function(...) return (arg.time >= arg.numberValue) end },
  [3] = { description = "Boat Full", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).can_insert("rocket-silo") end },
  [4] = { description = "Boat Empty", defaultValue = nil, defaultSignal = nil, finished = function(...) return arg.boat.get_inventory(defines.inventory.car_trunk).is_empty() end },
}

boatGUI.logicTable = {
  [1] = "AND", [2] = "OR", [3] = "XOR", --[4] = "NOR", [5] = "XOR",
}


boatGUI.handler_on_gui_opened = function (e)
  if e.entity and e.entity.name == "basic-boat" then
    local boat = global.lists["basic-boat"][e.entity.unit_number]

    local kludge = game.players[e.player_index].gui.top.add({ type = "flow", name = "basicboat_frame", direction = "vertical" })
    local gui_base = kludge.add({type = "frame", name = "basicboat_id_"..(e.entity.unit_number), caption = "Boat Configuration", direction = "vertical" })
    local gui_auttab = gui_base.add({type = "table", name = "basicboat_automated_table", column_count = 2 })
    local gui_sigtab = gui_base.add({type = "table", name = "basicboat_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Automation Enabled: "})
    gui_auttab.add({type = "checkbox", name = "basicboat_automated", state = boat.automated})
    gui_sigtab.add({type = "label", caption = "Automation Target Signal: "})
    gui_sigtab.add({type = "choose-elem-button", name = "basicboat_signalpicker", elem_type = "signal", signal = boat.signal })


    local gui_condition_buttons_table = gui_base.add({ type = "table", name = "basicboat_conditionButton_table", column_count = 2 })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Add", caption = "Add Condition" })
    gui_condition_buttons_table.add({ type = "button", name = "basicboat_conditionButton_Remove", caption = "Remove Condition" })

    boatGUI.constructConditionChooser(gui_base, boat)
  end
end
APIInterface.registerFunction("on_gui_opened", boatGUI.handler_on_gui_opened)


boatGUI.handler_on_gui_closed = function (e)
  if e.entity and e.entity.name == "basic-boat" then
    if game.players[e.player_index].gui.top["basicboat_frame"] then
      --local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
      --gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]

      game.players[e.player_index].gui.top["basicboat_frame"].destroy()
    end
  end
end
APIInterface.registerFunction("on_gui_closed", boatGUI.handler_on_gui_closed)


boatGUI.automatedButtonHandler_on_gui_checked_state_changed = function(e)
  if e.element.valid and e.element.name == "basicboat_automated" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat = global.lists["basic-boat"][unitNumber]
    local newAutomated = gui_base["basicboat_automated_table"]["basicboat_automated"].state

    local auto_success = boat:setAutomated(newAutomated)
    if auto_success ~= 0 then
      if auto_success == 1 then
        game.players[e.player_index].print("WARNING: Can't set boat to automated while it has both a driver and a passenger.")
      else
        game.players[e.player_index].print("ERROR: Please tell mod author [automation]") --how did this happen?
      end
      e.element.state = not e.element.state
    end


  end
end
APIInterface.registerFunction("on_gui_checked_state_changed", boatGUI.automatedButtonHandler_on_gui_checked_state_changed)


boatGUI.signalHandler_on_gui_elem_changed = function (e)
  if e.element.valid and e.element.name == "basicboat_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local boat_unit_number = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat = global.lists["basic-boat"][boat_unit_number]

    local newSignalVal = e.element.elem_value
    boat:setSignal(newSignalVal)
  end
end
APIInterface.registerFunction("on_gui_elem_changed", boatGUI.signalHandler_on_gui_elem_changed)


boatGUI.constructConditionChooser = function(gui_base, boat)
  local gui_condition_base = gui_base.add({ type = "scroll-pane", name = "basicboat_condition", vertical_scroll_policy = "always"})
  local temp_style = gui_condition_base.style
  temp_style.minimal_height = 40
  --gui_condition_base.style = temp_style.name
  --local gui_editor_base = gui_condition_base.add({ type = "line", name = "basicboat_editor_line1", direction = "horizontal" })
  for i,condition in ipairs(boat.conditions) do
    local gui_current_condition_table = gui_condition_base.add({ type = "table", name = ("basicboat_condition_table"..i), column_count = 3})
    gui_current_condition_table.add({ type = "label", name = ("basicboat_condition_number_"..i), caption = i})
    gui_current_condition_table.add({ type = "radiobutton", name = ("basicboat_condition_radio_"..i), state = (boat.selected_condition_index == i)})
    local gui_current_condition = gui_current_condition_table.add({ type = "flow", name = ("basicboat_condition_"..i), direction = "horizontal"})
    local j = 1
    for _,subcondition in ipairs(condition) do
      if subcondition.type == "conditionIndex" then
        gui_current_condition.add({ type = "drop-down", name = "basicboat_condition_label_"..j, items = ((function(list) local names = {} for i,v in ipairs(list) do names[i] = v.description  end names[#names + 1] = "Remove this condition" return names end )(boatGUI.conditionTable)), selected_index = subcondition.value,  })
      elseif subcondition.type == "logic" then
        gui_current_condition.add({ type = "drop-down", name = "basicboat_condition_label_"..j, items = boatGUI.logicTable, selected_index = subcondition.value })
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


boatGUI.conditionButtonHandler_on_gui_click = function(e)
  if e.element.valid and e.element.parent.name == "basicboat_conditionButton_table" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat = global.lists["basic-boat"][unitNumber]

    if e.element.name == "basicboat_conditionButton_Add" then
      boat.conditions[#(boat.conditions) + 1] = { [1] = {type = "conditionIndex", value = 1 } }
    else
      for i = boat.selected_condition_index, #(boat.conditions) - 1, 1 do
        boat.conditions[i] = boat.conditions[i+1]
      end
      boat.conditions[#(boat.conditions)] = nil
      if next(boat.conditions) == nil then
        boat.conditions[1] = { [1] = {type = "conditionIndex", value = 1 } }
      end
      boat.selected_condition_index = 1
    end
    gui_base["basicboat_condition"].destroy()
    boatGUI.constructConditionChooser(gui_base, boat)
  end
end
APIInterface.registerFunction("on_gui_click", boatGUI.conditionButtonHandler_on_gui_click)


boatGUI.conditionRadioHandler_on_gui_checked_state_changed = function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_radio_") ~= nil then
    for _, v in pairs(e.element.parent.parent.children) do
      v["basicboat_condition_radio_"..(string.gsub(v.name, "basicboat_condition_table", ""))].state = false
    end
    e.element.state = true

    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    global.lists["basic-boat"][unitNumber].selected_condition_index = tonumber(string.gsub(e.element.name, "basicboat_condition_radio_", ""), 10)
  end
end
APIInterface.registerFunction("on_gui_click", boatGUI.conditionRadioHandler_on_gui_checked_state_changed)


boatGUI.conditionLabelHandler_on_gui_selection_state_changed = function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat = global.lists["basic-boat"][unitNumber]

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)
    local condition = boat.conditions[conditionIndex]
    if(condition[subconditionIndex].type == "conditionIndex") then
      local minus = 0
      if boatGUI.conditionTable[condition[subconditionIndex].value].defaultValue ~= nil then
        minus = minus + 1
      end
      if boatGUI.conditionTable[condition[subconditionIndex].value].defaultSignal ~= nil then
        minus = minus + 1
      end
      if boatGUI.conditionTable[e.element.selected_index] == nil then
        minus = minus + 1   --delete this one
        minus = minus + 1   --for the logic condition
      else
        if boatGUI.conditionTable[e.element.selected_index].defaultValue ~= nil then
          minus = minus - 1
        end
        if boatGUI.conditionTable[e.element.selected_index].defaultSignal ~= nil then
          minus = minus - 1
        end
      end

      local tempIndex = subconditionIndex
      if minus > 0 then
        if boatGUI.conditionTable[e.element.selected_index] ~= nil then tempIndex = subconditionIndex + 1 end
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
        if boatGUI.conditionTable[e.element.selected_index].defaultValue ~= nil then
          condition[subconditionIndex+plus] = {type = "numberValue", value = boatGUI.conditionTable[e.element.selected_index].defaultValue}
          plus = plus + 1
        end
        if boatGUI.conditionTable[e.element.selected_index].defaultSignal ~= nil then
          condition[subconditionIndex+plus] = {type = "signalValue", value = boatGUI.conditionTable[e.element.selected_index].defaultSignal}
        end

        condition[subconditionIndex].value = e.element.selected_index
      end

      gui_base["basicboat_condition"].destroy()
      boatGUI.constructConditionChooser(gui_base, boat)
    else
      condition[subconditionIndex].value = e.element.selected_index
    end
  end
end
APIInterface.registerFunction("on_gui_selection_state_changed", boatGUI.conditionLabelHandler_on_gui_selection_state_changed)


boatGUI.conditionLabelHandler_on_gui_elem_changed = function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.lists["basic-boat"][unitNumber].conditions[conditionIndex][subconditionIndex].value = e.element.elem_value
  end
end
APIInterface.registerFunction("on_gui_elem_changed", boatGUI.conditionLabelHandler_on_gui_elem_changed)


boatGUI.conditionLabelHandler_on_gui_click = function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") and e.element.caption == "+" then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)
    local boat = global.lists["basic-boat"][unitNumber]
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)
    local condition = boat.conditions[conditionIndex]

    condition[ #condition + 1 ] = { type = "logic", value = 1 }
    condition[ #condition + 1 ] = { type = "conditionIndex", value = 1 }

    gui_base["basicboat_condition"].destroy()
    boatGUI.constructConditionChooser(gui_base, boat)
  end
end
APIInterface.registerFunction("on_gui_click", boatGUI.conditionLabelHandler_on_gui_click)


boatGUI.conditionLabelHandler_on_gui_text_changed = function(e)
  if e.element.valid and string.find(e.element.name, "basicboat_condition_label_") ~= nil then
    local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]
    gui_base = gui_base[gui_base.children_names[#gui_base.children_names]]
    local unitNumber = tonumber(string.gsub(gui_base.name, "basicboat_id_", ""), 10)

    local subconditionIndex = tonumber(string.gsub(e.element.name, "basicboat_condition_label_", ""), 10)
    local conditionIndex = tonumber(string.gsub(e.element.parent.name, "basicboat_condition_", ""), 10)

    global.lists["basic-boat"][unitNumber].conditions[conditionIndex][subconditionIndex].value = tonumber(e.element.text,10)
  end
end
APIInterface.registerFunction("on_gui_text_changed", boatGUI.conditionLabelHandler_on_gui_text_changed)
