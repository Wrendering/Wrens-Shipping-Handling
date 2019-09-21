local APIInterface = require("scripts/APIInterface")

local lighthouseGUI = {}

lighthouseGUI.signalHandler_on_gui_elem_changed = function (e)
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
end
APIInterface.registerFunction("on_gui_elem_changed", lighthouseGUI.signalHandler_on_gui_elem_changed)


lighthouseGUI.handler_on_gui_opened = function (e)
  if e.entity and e.entity.name == "lighthouse-entity" then
    local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = ("lighthouse_frame"), caption = "Lighthouse Configuration", direction = "vertical" })
    local guiEntityId = gui_base.add({ type = "empty-widget", name = "lighthouse_id"})
    guiEntityId.add({ type = "empty-widget", name = e.entity.unit_number})
    local gui_auttab = gui_base.add({type = "table", name = "lighthouse_signalpicker_table", column_count = 2 })
    gui_auttab.add({type = "label", caption = "Lighthouse Signal: "})
    gui_auttab.add({type = "choose-elem-button", name = "lighthouse_signalpicker", elem_type = "signal", signal = global.lighthousesList[e.entity.unit_number].signal })
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
