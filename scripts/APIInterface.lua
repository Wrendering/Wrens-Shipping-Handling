
local eventFunctions = {}   --a table of tables of functions, indexed by event name


--[[
  script.on_event demands only a single callback,
    so this function constructs one from a list of callbacks
    The parameters mirror those of script.on_event

  event: either a string (the name of the event)
    or a table of strings (for registering multiple events)
  f: the callback function to be registered
--]]
local registerFunction
registerFunction = function(event, f)
  if type(event) == "table" then
    for _,eventElement in pairs(event) do
      registerFunction(eventElement, f)
    end
    return
  end
  if eventFunctions[event] == nil then
    eventFunctions[event] = {}
  end
  table.insert(eventFunctions[event], f)
  local handler = function (e)
    for _, func in pairs(eventFunctions[event]) do
      func(e)
    end
  end
  script.on_event(defines.events[event], handler)
end


APIInterface = {
  registerFunction = registerFunction,
}

return APIInterface
