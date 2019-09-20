
local eventFunctions = {}   --a table of tables of functions, indexed by event name

local registerFunction
registerFunction = function(event, f)
  --[[
    event: either a string (the name of the event)
      or a table of strings (for registering multiple events)
    f: the callback function to be registered

    Note that this mirrors the parameters of script.on_event
  --]]

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

  log("Handler: ")
  for _,i in pairs(eventFunctions) do
    log("Registered Event")
    for _,j in pairs(i) do
      log("Registered Function")
    end
  end

  local handler = function (e)
    --log("Handler: ")
    for _,i in pairs(eventFunctions) do
      --log("Registered Event")
      for _,j in pairs(i) do
        --log("Registered Function")
      end
    end
    --log("")
    for _, func in pairs(eventFunctions[event]) do
      func(e)
    end
  end

  script.on_event(defines.events[event], handler)

end

--script.on_event(defines.events[event]

APIInterface = {
  registerFunction = registerFunction,
}

return APIInterface
