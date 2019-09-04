----------------------------------------------------------- Boat and Lighthouse Globals

if global.boatsList == nil then
    global.boatsList = {}
end

local boatCreation_on_built_entity = function (e)
    if e.created_entity.name == "basic-boat" then
        global.boatsList[e.created_entity.unit_number] = { entity = e.created_entity, automated = true, signal = nil }
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
      local gui_base = game.players[e.player_index].gui.top.add({type = "frame", name = "basicboat_frame", caption = "Boat Configuration", direction = "vertical" })
      local gui_auttab = gui_base.add({type = "table", name = "basicboat_automated_table", column_count = 2 })
      local gui_sigtab = gui_base.add({type = "table", name = "basicboat_signalpicker_table", column_count = 2 })
      gui_auttab.add({type = "label", caption = "Automation Enabled: "})
      gui_auttab.add({type = "checkbox", name = "basicboat_automated", state = global.boatsList[e.entity.unit_number].automated})
      gui_sigtab.add({type = "label", caption = "Automation Target Signal: "})
      gui_sigtab.add({type = "choose-elem-button", name = "basicboat_signalpicker", elem_type = "signal", signal = global.boatsList[e.entity.unit_number].signal })
  end
end

local boatGui_on_gui_closed = function (e)
  if e.entity and e.entity.name == "basic-boat" then
    if game.players[e.player_index].gui.top["basicboat_frame"] then
      local gui_base = game.players[e.player_index].gui.top["basicboat_frame"]

      if gui_base["basicboat_signalpicker_table"]["basicboat_signalpicker"] then
        global.boatsList[e.entity.unit_number].signal = gui_base["basicboat_signalpicker_table"]["basicboat_signalpicker"].elem_value
      end

      if gui_base["basicboat_automated_table"]["basicboat_automated"] then
        repeat
          local newAutomated = gui_base["basicboat_automated_table"]["basicboat_automated"].state
          if global.boatsList[e.entity.unit_number].automated ~= newAutomated then
            if newAutomated then
              if(e.entity.get_driver()) then
                if(e.entity.get_driver().player ~= nil) then
                  if(e.entity.get_passenger() ~= nil and e.entity.get_passenger().player ~= nil) then
                    game.players[e.player_index].print("WARNING: Can't set boat to automated while it has a driver.")
                    break
                  else
                    e.entity.set_passenger(e.entity.get_driver())
                  end
                end
              end
              e.entity.set_driver(nil)
              e.entity.set_driver(e.entity.surface.create_entity({ name = "character", position = e.entity.position, force = game.forces.player}))
            else
              if(e.entity.get_driver() ~= nil and e.entity.get_driver().player ~= nil) then
                game.players[e.player_index].print("ERROR: Please tell mod author 2") --how did this happen?
              end
              if e.entity.get_driver() then e.entity.get_driver().destroy() end
              e.entity.set_driver(nil)
              if e.entity.get_passenger() and e.entity.get_passenger().player then
                e.entity.set_driver(e.entity.get_passenger())
                e.entity.set_passenger(nil)
              end
            end
            global.boatsList[e.entity.unit_number].automated = newAutomated
          end
        until(true)
      end

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
