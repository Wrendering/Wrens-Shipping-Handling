

local boatGui_on_gui_opened = function (e) 
    if e.entity and e.entity.name == "basic-boat" then
        game.players[e.player_index].gui.top.add({type = "choose-elem-button", name = "basicboat_signalpicker", elem_type = "signal", signal = global.boatsList[e.entity.unit_number].signal })
    end
end

local boatGui_on_gui_closed = function (e) 
    if e.entity and e.entity.name == "basic-boat" then
        if game.players[e.player_index].gui.top["basicboat_signalpicker"] then 
            global.boatsList[e.entity.unit_number].signal = game.players[e.player_index].gui.top["basicboat_signalpicker"].elem_value
            game.players[e.player_index].gui.top["basicboat_signalpicker"].destroy()
        end
    end
end

----------------------------------------------------------- Boat Globals

if global.boatsList == nil then
    global.boatsList = {}
end

local boatCreation_on_built_entity = function (e) 
    if e.created_entity.name == "basic-boat" then
        global.boatsList[e.created_entity.unit_number] = { entity = e.created_entity, automated = false, signal = nil }
        --game.players[1].print("Boat made!  "..e.created_entity.unit_number)
    end
end

local boatDestruction_on_entity_died_on_player_mined_entity = function (e) 
    if e.entity.name == "basic-boat" then
        global.boatsList[e.entity.unit_number] = nil
        --game.players[1].print("Boat destroyed!  "..e.entity.unit_number)
    end
end

--[[local boatPrint_on_tick = function (e) 
    if e.tick % 120 == 0 then
        game.players[1].print("Hi")
        for i,v in pairs(global.boatsList) do
            if math.random() < 0.05 then
                v.automated = true
            end
            game.players[1].print("Automated: "..(v.automated and "true" or "false").."\tUnit: "..tostring(v.entity.unit_number))
        end
    end
end]]--

----------------------------------------------------------- Boat Movement

local boatDirector_on_tick = function (e) 
    if e.tick % 60 == 0 then
        for _,v in pairs(global.boatsList) do
            if v.automated then
                local boatPos = v.entity.position
                local targetPos = {x = 0, y = 0}

                v.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
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
end
script.on_event(defines.events.on_built_entity, on_built_entity_handler)

local on_entity_died_handler = function(e) 
    boatDestruction_on_entity_died_on_player_mined_entity(e)
end
script.on_event(defines.events.on_entity_died, on_entity_died_handler)

local on_player_mined_entity_handler = function(e) 
    boatDestruction_on_entity_died_on_player_mined_entity(e)
end
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity_handler)

local on_chunk_generated_handler = function(e) 
    oceanOverwriter_on_chunk_generated(e)
end
script.on_event(defines.events.on_chunk_generated, on_chunk_generated_handler)

local on_gui_opened_handler = function(e) 
    boatGui_on_gui_opened(e)
end
script.on_event(defines.events.on_gui_opened, on_gui_opened_handler)

local on_gui_closed_handler = function(e) 
    boatGui_on_gui_closed(e)
end
script.on_event(defines.events.on_gui_closed, on_gui_closed_handler)
