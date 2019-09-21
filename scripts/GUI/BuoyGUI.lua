local APIInterface = require("scripts/APIInterface")

local buoyGUI = {}

buoyGUI.buoyTypesList = {[1] = "Incoming", [2] = "Outgoing", [3] = "Signal"}

buoyGUI.handler_on_gui_opened = function (e)
  if e.entity and string.find(e.entity.name, "buoy%-entity") ~= nil then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("buoy_frame"), caption = "Buoy Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "buoy_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "buoy_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Buoy State: "})
    gui_auttab.add({type = "drop-down", name = "buoy_statepicker", items = buoyGUI.buoyTypesList, selected_index = global.buoysList[e.entity.unit_number].active_state })
  end
end
APIInterface.registerFunction("on_gui_opened", buoyGUI.handler_on_gui_opened)


buoyGUI.handler_on_gui_closed = function (e)
  if e.entity and string.find(e.entity.name, "buoy%-entity") ~= nil then
    if game.players[e.player_index].gui.top["buoy_frame"] then
      local gui_base = game.players[e.player_index].gui.top["buoy_frame"]
      gui_base.destroy()
    end
  end
end
APIInterface.registerFunction("on_gui_closed", buoyGUI.handler_on_gui_closed)


buoyGUI.stateHandler_on_gui_selection_state_changed = function(e)
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
end
APIInterface.registerFunction("on_gui_selection_state_changed", buoyGUI.stateHandler_on_gui_selection_state_changed)
