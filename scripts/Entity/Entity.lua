--
global = {}
--

global.lists = {}

local Entity = { entity = nil, }

function Entity.curry(val, func)
  local curriedFunction = function(arg)
    func(val, arg)
  end --I'm pretty sure this is what currying means
  return curriedFunction
end

function Entity:new(args)
  --[[
  Constructor for new object. Called < obj = Entity:new{} >.
  args:
    entity: the entity associated with this Entity wrapper
  ]]--

  local newObject = { entity = args.entity }
  setmetatable(newObject, self)
  self.__index = self

  local className = args.entity.prototype.name

  if global.lists[className] == nil then global.lists[className] = {} end
  global.lists[className][args.entity.unit_number] = newObject

  return newObject
end

function Entity:destroy(args)
  --[[
  Destructor for an object. Called obj:destroy().
  args: none
  ]]--

  local className = self.entity.prototype.name

  global.lists[className][self.entity.unit_number] = nil
  if next(global.lists[className]) == nil then global.lists[className] = nil end

end


local obj1 = Entity:new{entity = {prototype = {name = "car",}, unit_number = 1,  str = "Ha Ha!",}, }
local obj2 = Entity:new{entity = {prototype = {name = "car",}, unit_number = 2, str = "YEET",},  }
local obj3 = Entity:new{entity = {prototype = {name = "car",}, unit_number = 3, str = "lol XD >)", }, }

obj2:destroy()

for _,i in pairs(global.lists) do
  print("List name: ".._)
  for _,j in pairs(i) do
    print("Entity:\tUnit Number: ".._.."\tVal: "..tostring(j.entity.str))
  end
  print("")
end
