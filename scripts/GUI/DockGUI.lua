local APIInterface = require("scripts/APIInterface")

local dockGUI = {}

dockGUI.handler_on_gui_opened = function (e)
  if e.entity and e.entity.name == "dock-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("dock_frame"), caption = "Dock Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "dock_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "dock_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Signal Applied: "})
    gui_auttab.add({type = "choose-elem-button", name = "dock_signalpicker", elem_type = "signal", signal = global.lists["dock-entity"][e.entity.unit_number].signal })
    local gui_contab = gui_base.add({type = "table", name = "dock_conditionpicker_table", column_count = 2 })
    gui_contab.add({type = "label", caption = "Condition Index Applied: "})
    gui_contab.add({ type = "textfield", name = "dock_conditionpicker", text = global.lists["dock-entity"][e.entity.unit_number].conditionIndex, numeric = true, allow_decimal = false, allow_negative = false })

  end
end
APIInterface.registerFunction("on_gui_opened", dockGUI.handler_on_gui_opened)


dockGUI.handler_on_gui_closed = function (e)
  if e.entity and e.entity.name == "dock-entity" then
    if game.players[e.player_index].gui.top["dock_frame"] then
      local gui_base = game.players[e.player_index].gui.top["dock_frame"]
      gui_base.destroy()
    end
  end
end
APIInterface.registerFunction("on_gui_closed", dockGUI.handler_on_gui_closed)


dockGUI.conditionHandler_on_gui_text_changed = function(e)
  if e.element.valid and e.element.name == "dock_conditionpicker" then
    local gui_base = game.players[e.player_index].gui.top["dock_frame"]
    local _, dock_unit_number = next(gui_base.dock_id.children_names) dock_unit_number = tonumber(dock_unit_number, 10)
    local dockData = global.lists["dock-entity"][dock_unit_number]

    if tonumber(e.element.text, 10) == 0 then e.element.text = 1 end

    dockData.conditionIndex = tonumber(e.element.text,10)
  end
end
APIInterface.registerFunction("on_gui_text_changed", dockGUI.conditionHandler_on_gui_text_changed)


dockGUI.signalHandler_on_gui_elem_changed = function (e)
  if e.element.valid and e.element.name == "dock_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["dock_frame"]
    local _, dock_unit_number = next(gui_base.dock_id.children_names) dock_unit_number = tonumber(dock_unit_number, 10)
    local dockData = global.lists["dock-entity"][dock_unit_number]

    dockData.signal = e.element.elem_value
  end
end
APIInterface.registerFunction("on_gui_elem_changed", dockGUI.signalHandler_on_gui_elem_changed)
