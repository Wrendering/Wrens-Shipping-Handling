------------------------------------------------ Buoy Placement

 --[[
PROGRAM ASSUMPTIONS:
- Boat automated state is only changed through the GUI [update]
- Currently, no cloning or direct movement (Picker et al) of anything [set][update]
- No tile types exist that change boat speed

TODO: Add on_collision update
--]]

local APIInterface = require("scripts/APIInterface")

----------------------------------------------------------- Entity Globals

if not global.lists then global.lists = {} end
if not global.signalLists then global.signalLists = {} end


BEACON_RADIUS = 15 --game.entity_prototypes["lighthouse-entity"].supply_area_distance
BUOY_RADIUS = 1
DOCK_RADIUS = 1

------------------------------
require("scripts/OceanModifier")

require("scripts/GUI/BoatGUI")
require("scripts/GUI/DockGUI")
require("scripts/GUI/BuoyGUI")
require("scripts/GUI/LighthouseGUI")

require("scripts/Entity/Boat")
require("scripts/Entity/Dock")
require("scripts/Entity/Buoy")
require("scripts/Entity/Lighthouse")
