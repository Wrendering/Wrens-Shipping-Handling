global.lists = {}

local Entity = { entity = nil, }

function Entity.curry(func, val)  --Static function
  local curriedFunction = function(arg)
    return func(val, arg)
  end --I'm pretty sure this is what currying means
  return curriedFunction
end

function Entity:new(args)
  --[[
  Constructor for new object. Called < obj = Entity:new{} >.
  args:
    entity: the entity associated with this Entity wrapper
              if it exists, this wrapper will be added to global.lists
    className (optional): if you'd like to use a different className for this object.
    signalType (optional): if this type has a global.signalLists entry
  ]]--

  local newObject = {}
  setmetatable(newObject, self)
  self.__index = self
  --log("Entity call > "..(function () local s = "" for i,v in pairs(args) do s = s.."\tIndex: "..i.."\tValue: "..tostring(v).." |" end return s end)() )
  args.className = args.className or (args.entity and args.entity.prototype.name) or nil
  if args.className ~= nil then
    if global.lists[args.className] == nil then global.lists[args.className] = {} end
    if args.signalType then
      if global.signalLists[args.className] == nil then global.signalLists[args.className] = {} end
    end
  end

  if args.entity then
    newObject.entity = args.entity
    global.lists[args.className][args.entity.unit_number] = newObject --if entity then className exists
  end

  return newObject
end

function Entity:destroy(args)
  --[[
  Destructor for an object. Called obj:destroy().
  args:
    className (optional): if you'd like to use a different className for this object.
  ]]--
  args = args or {}

  local className = args.className or self.entity.prototype.name

  local lostSignal = self.signal
  if lostSignal ~= nil then
    local classSignalList = global.signalLists[className]

    classSignalList[lostSignal.type..lostSignal.name][self.entity.unit_number] = nil
    if next(classSignalList[lostSignal.type..lostSignal.name]) == nil then classSignalList[lostSignal.type..lostSignal.name] = nil end
  end

  global.lists[className][self.entity.unit_number] = nil
  if next(global.lists[className]) == nil then global.lists[className] = nil end

  if self.entity and self.entity.valid then self.entity.destroy() end

end

return Entity
