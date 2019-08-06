
OCEAN_EFFECT_EDGE = 50
OCEAN_SHORE_ZONE = 8
OCEAN_SHALLOW_ZONE = 16

local oceanOverwriter_handler = function (e)

    for i,v in pairs(e.surface.find_entities(e.area)) do
        if(v.type ~= nil) then
            v.destroy()
        end
    end


    local setOfTiles = {}
    local i = 1 ; local right_edge ; local left_edge

    local sub_overwriter_oceanOverwriter_handler = function (left_edge, right_edge, tilename)   
        --hopefully, can affect e, i, and setOfTiles due to closures(?)
        local orig_i = i
        for x = left_edge, right_edge do
            for y = e.area.left_top.y, e.area.right_bottom.y do
                setOfTiles[i] = { name = tilename, position = { x, y} } ; i = i + 1
            end
        end
        return orig_i
    end

    left_edge = OCEAN_EFFECT_EDGE ; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    right_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE ; if e.area.right_bottom.x < right_edge then right_edge = e.area.right_bottom.x end
    local orig = sub_overwriter_oceanOverwriter_handler(left_edge, right_edge, "sand-1")

    --[[for y = e.area.right_bottom.y, e.area.left_top.y, -1 do
        local test_for_water = false
        local i;
        local leftestX;
        for x = right_edge, left_edge - 2, -1 do
            i = orig + (y - e.area.left_top.y) + (x - left_edge) * (e.area.right_bottom.y - e.area.left_top.y)
            if e.surface.get_tile(x,y).name == "water" then --test for other water types later
                test_for_water = true
                leftestX = x
            end
        end
        if test_for_water then
            for x = right_edge, leftestX, -1 do
                i = orig + (y - e.area.left_top.y) + (x - left_edge) * (e.area.right_bottom.y - e.area.left_top.y)
                setOfTiles[i].name = "ocean-shallow-water"
            end
        end
    end]]--

    left_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    right_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE + OCEAN_SHALLOW_ZONE; if e.area.right_bottom.x < right_edge then right_edge = e.area.right_bottom.x end
    sub_overwriter_oceanOverwriter_handler(left_edge, right_edge, "ocean-shallow-water")

    left_edge = OCEAN_EFFECT_EDGE + OCEAN_SHORE_ZONE + OCEAN_SHALLOW_ZONE; if e.area.left_top.x > left_edge then left_edge = e.area.left_top.x end
    sub_overwriter_oceanOverwriter_handler(left_edge, e.area.right_bottom.x, "ocean-deep-water")

    e.surface.set_tiles(setOfTiles, true)

end

script.on_event(defines.events.on_chunk_generated, oceanOverwriter_handler)

--x==y and x or y -- x==y ? x : y --works as long as x is not false or nil
