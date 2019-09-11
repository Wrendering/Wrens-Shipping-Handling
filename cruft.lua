for i in boatsList_signalOrdered[lostSignal] do
  i.boatDirector_updateTargets_all(e.entity.unit_number, lostSignal, false)
end

local boatDirector_updateTargets_single_sub1 = function (boat, boatPos, origTarget, newTarget)
if (origTarget == nil) or (boatPos.x - origTarget.x)^2 + (boatPos.y - origTarget.y)^2 > (boatPos.x - newTarget.x)^2 + (boatPos.y - newTarget.y)^2 then
    boat.currentTarget = { position = newTarget, unit_number = lighthouse_unit_number }
    return boat.currentTarget
  end
  return nil
end

local boatDirector_updateTargets_single_sub2 = function (boat_unit_number, keep_target)
  local boat = global.boatsList[boat_unit_number]
  local boatPos = boat.entity.position
  local origTarget = keep_target and boat.currentTarget.position or nil
  return boat, boatPos, origTarget
end

local boatDirector_updateTargets_single = function (boat_unit_number, lighthouse_unit_number)
  if boatDirector_updateTargets_single_sub1(boatDirector_updateTargets_single_sub2(boat_unit_number), lighthousesList[lighthouse_unit_number].entity.position) ~= nil then
    boatDirector_updateTargets_sub3(global.boatsList[boat_unit_number].entity)
  end
end

local boatDirector_updateTargets_all = function (boat_unit_number, signal, keep_target)
  local boat, boatPos, origTarget = boatDirector_updateTargets_single_sub2(boat_unit_number, (keep_target or nil) )
  signal = signal or boat.signal
  local flag = origTarget
  local lighthousesList_signalOrdered = global.lighthousesList_signalOrdered
  if lighthousesList_signalOrdered[signal.type..signal.name] ~= nil then
    local lighthousesList = global.lighthousesList
    local temp
    for unit_number,_ in pairs(lighthousesList_signalOrdered[signal.type..signal.name]) do
      log(unit_number)
      temp = boatDirector_updateTargets_single_sub1(boat, boatPos, origTarget, lighthousesList[unit_number].entity.position)
      origTarget = temp and temp.position or origTarget
    end
  end
  return (origTarget ~= nil) and flag ~= origTarget
end

local boatDirector_updateTargets_sub3 = function (v)
  local boatPos = v.entity.position
  local targetPos = v.currentTarget.position
  v.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
  v.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
end

local boatDirector_runState = function (v, func)
  if v.automated then
    if v.signal and (v.entity.burner.currently_burning or not v.entity.get_fuel_inventory().is_empty()) then
      if func() then
        boatDirector_updateTargets_sub3(v)
        return
      end
    end
    if v.entity.speed < 0.01 then
      v.entity.speed = 0
      v.entity.riding_state = {acceleration = defines.riding.acceleration.nothing, direction = defines.riding.direction.straight }
    else
      v.entity.riding_state = {acceleration = defines.riding.acceleration.braking, direction = defines.riding.direction.straight }
    end
  end
end


--[[if e.tick % 60 == 0 then
  for _,v in pairs(global.boatsList) do
    if v.automated then
      if v.signal and (v.entity.burner.currently_burning or not v.entity.get_fuel_inventory().is_empty()) then
        log("check:")
        if boatDirector_updateTargets_all(v.entity.unit_number,v.signal, false) then
          log("yup")
          local boatPos = v.entity.position
          local targetPos = v.currentTarget.position
          v.entity.orientation = math.atan2( (boatPos.x - targetPos.x), -(boatPos.y - targetPos.y)) / (2*math.pi) + 0.5
          v.entity.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.straight }
        end
      else
        if v.entity.speed < 0.01 then
          v.entity.speed = 0
          v.entity.riding_state = {acceleration = defines.riding.acceleration.nothing, direction = defines.riding.direction.straight }
        else
          v.entity.riding_state = {acceleration = defines.riding.acceleration.braking, direction = defines.riding.direction.straight }
        end
      end
    end
  end
end]]--
