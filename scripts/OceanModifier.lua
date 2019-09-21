local APIInterface = require("scripts/APIInterface")

OCEAN_EFFECT_EDGE = 50
OCEAN_SHORE_ZONE = 8
OCEAN_SHALLOW_ZONE = 16

HARBOR_MOUTH_SEARCH_LENGTH = 6

local oceanEdgeOverwriter = function (e)
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

APIInterface.registerFunction("on_chunk_generated", oceanEdgeOverwriter)
