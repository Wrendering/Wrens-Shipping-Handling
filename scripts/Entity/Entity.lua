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
  ]]--

  local newObject = {}
  setmetatable(newObject, self)
  self.__index = self

  if args.entity then
    newObject.entity = args.entity
    local className = args.className or args.entity.prototype.name

    if global.lists[className] == nil then global.lists[className] = {} end
    global.lists[className][args.entity.unit_number] = newObject
  end

  return newObject
end

function Entity:destroy(args)
  --[[
  Destructor for an object. Called obj:destroy().
  args:
    className (optional): if you'd like to use a different className for this object.
  ]]--

  local className = args.className or self.entity.prototype.name

  global.lists[className][self.entity.unit_number] = nil
  if next(global.lists[className]) == nil then global.lists[className] = nil end

  if self.entity and self.entity.valid then self.entity.destroy() end

end

return Entity
