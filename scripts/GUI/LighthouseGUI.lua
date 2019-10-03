local APIInterface = require("scripts/APIInterface")

local lighthouseGUI = {}

lighthouseGUI.signalHandler_on_gui_elem_changed = function (e)
  if e.element.valid and e.element.name == "lighthouse_signalpicker" then
    local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]
    local _, lighthouse_unit_number = next(gui_base.lighthouse_id.children_names) lighthouse_unit_number = tonumber(lighthouse_unit_number, 10) --[#gui_base.lighthouse_id.children_names].name
    local lighthouse = global.lists["lighthouse-entity"][lighthouse_unit_number]

    lighthouse:setSignal{signal = gui_base["lighthouse_signalpicker_table"]["lighthouse_signalpicker"].elem_value }
  end
end
APIInterface.registerFunction("on_gui_elem_changed", lighthouseGUI.signalHandler_on_gui_elem_changed)


lighthouseGUI.handler_on_gui_opened = function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("lighthouse_frame"), caption = "Lighthouse Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "lighthouse_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "lighthouse_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Lighthouse Signal: "})
    gui_auttab.add({type = "choose-elem-button", name = "lighthouse_signalpicker", elem_type = "signal", signal = global.lists["lighthouse-entity"][e.entity.unit_number].signal })
  end
end
APIInterface.registerFunction("on_gui_opened", lighthouseGUI.handler_on_gui_opened)


lighthouseGUI.handler_on_gui_closed = function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    if game.players[e.player_index].gui.top["lighthouse_frame"] then
      local gui_base = game.players[e.player_index].gui.top["lighthouse_frame"]
      gui_base.destroy()
    end
  end
end
APIInterface.registerFunction("on_gui_closed", lighthouseGUI.handler_on_gui_closed)
