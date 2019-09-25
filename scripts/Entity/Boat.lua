local Entity = require("Entity")

local Boat = Entity:new{entity = nil}

function Boat:new(args)
  local newObject = getmetatable(self):new(args)
  setmetatable(newObject, self)
  self.__index = self

  newObject.str = args.str
  if(newObject.str == "Hi!") then print("Ayy!") end

  return newObject
end
