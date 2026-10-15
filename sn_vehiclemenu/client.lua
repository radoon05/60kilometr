


-- Verify resource name
local currentResource = GetCurrentResourceName()
if "sn_vehiclemenu" ~= currentResource then
  return
end

-- State variables
local isMenuOpen = false
local currentVehicle = nil
local vehicleMinDimensions = nil
local vehicleMaxDimensions = nil
local camera = nil
local interactionPoints = {}
local brokenWindows = {}
local vehY = nil

-- Vehicle bone definitions for interaction points
local vehicleBones = {
  {bone = "seat_dside_f", size = 4.0},
  {bone = "seat_pside_f", size = 4.0},
  {bone = "seat_dside_r", size = 4.0},
  {bone = "seat_pside_r", size = 4.0},
  {bone = "seat_dside_r1", size = 4.0},
  {bone = "seat_pside_r1", size = 4.0},
  {bone = "seat_dside_r2", size = 4.0},
  {bone = "seat_pside_r2", size = 4.0},
  {bone = "seat_dside_r3", size = 4.0},
  {bone = "seat_pside_r3", size = 4.0},
  {bone = "seat_dside_r4", size = 4.0},
  {bone = "seat_pside_r4", size = 4.0},
  {bone = "seat_dside_r5", size = 4.0},
  {bone = "seat_pside_r5", size = 4.0},
  {bone = "seat_dside_r6", size = 4.0},
  {bone = "seat_pside_r6", size = 4.0},
  {bone = "seat_dside_r7", size = 4.0},
  {bone = "seat_pside_r7", size = 4.0},
  {bone = "handle_dside_f", size = 4.25},
  {bone = "handle_pside_f", size = 4.25},
  {bone = "handle_dside_r", size = 4.25},
  {bone = "handle_pside_r", size = 4.25},
  {bone = "bonnet", size = 4.25},
  {bone = "boot", size = 4.25}
}

-- Add window bones if enabled in config
if Config.showWindows then
  table.insert(vehicleBones, {bone = "window_lf", size = 3.25})
  table.insert(vehicleBones, {bone = "window_rf", size = 3.25})
  table.insert(vehicleBones, {bone = "window_lr", size = 3.25})
  table.insert(vehicleBones, {bone = "window_rr", size = 3.25})
end

-- Toggle camera for vehicle inspection
function toggleCamera(enable)
  if camDB then
    return
  end
  camDB = true
  
  if enable then
    -- Destroy existing camera if present
    if camera then
      SetCamActive(camera, false)
      DestroyCam(camera, true)
      RenderScriptCams(false, false, 1, true, true)
    end
    
    -- Create new camera
    camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetGameplayCamCoord(), GetGameplayCamRot(2), 60.0, false, 2)
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 1, true, true)
    
    -- Get vehicle dimensions for camera positioning
    vehicleMinDimensions, vehicleMaxDimensions = GetModelDimensions(GetEntityModel(currentVehicle))
    vehY = vehicleMinDimensions.y
    
    if vehY > -2 then
      vehY = -2.0
    end
    
    -- Attach camera to vehicle
    HardAttachCamToEntity(camera, currentVehicle, -40.0, 0.0, 0.0, 0.0, vehY * 2.3, vehicleMaxDimensions.z * 5, true)
  else
    -- Disable camera
    SetCamActive(camera, false)
    DestroyCam(camera, true)
    RenderScriptCams(false, false, 1, true, true)
  end
  
  camDB = false
end

-- Close the vehicle menu
function closeMenu()
  -- Prevent pause menu during transition
  CreateThread(function()
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < 1000 do
      SetPauseMenuActive(false)
      Wait(0)
    end
  end)
  
  SendNUIMessage({action = "toggleUI", data = false})
  toggleCamera(false)
  SetNuiFocus(false)
  isMenuOpen = false
end

-- Check if a window can be rolled down (not broken)
function canRollWindow(vehicle, windowID)
  if not IsVehicleWindowIntact(vehicle, windowID) then
    if brokenWindows[vehicle] and brokenWindows[vehicle][windowID] then
      return false
    end
  end
  return not IsVehicleWindowIntact(vehicle, windowID)
end

-- Build interaction points for current vehicle
function buildInteractionPoints()
  local points = {}
  local seatIndex = -2
  local doorIndex = -1
  local windowIndex = -1
  
  -- Initialize broken windows tracker for this vehicle
  if not brokenWindows[currentVehicle] then
    brokenWindows[currentVehicle] = {}
  end
  
  -- Process each bone to create interaction points
  for _, boneData in pairs(vehicleBones) do
    local boneIndex = GetEntityBoneIndexByName(currentVehicle, boneData.bone)
    
    if boneIndex ~= -1 then
      boneData.boneIndex = boneIndex
      local boneType = string.sub(boneData.bone, 1, 5)
      
      -- Handle seat interactions
      if boneType == "seat_" then
        seatIndex = seatIndex + 1
        boneData.seatID = seatIndex
        boneData.image = "seat.png"
        boneData.active = IsVehicleSeatFree(currentVehicle, seatIndex)
        table.insert(points, boneData)
        
      -- Handle door interactions
      elseif string.sub(boneData.bone, 1, 7) == "handle_" then
        doorIndex = doorIndex + 1
        
        if not IsVehicleDoorDamaged(currentVehicle, doorIndex) then
          boneData.doorID = doorIndex
          
          -- Determine door image based on side
          if string.sub(boneData.bone, 8, 13) == "dside_" then
            boneData.image = "frontDoor2.png"
          else
            boneData.image = "frontDoor.png"
          end
          
          boneData.active = true
          table.insert(points, boneData)
        end
        
      -- Handle hood/bonnet
      elseif boneData.bone == "bonnet" then
        boneData.doorID = 4
        boneData.image = "hood.png"
        boneData.active = true
        table.insert(points, boneData)
        
      -- Handle trunk/boot
      elseif boneData.bone == "boot" then
        boneData.doorID = 5
        boneData.image = "trunk.png"
        boneData.active = true
        table.insert(points, boneData)
        
      -- Handle window interactions
      elseif string.sub(boneData.bone, 1, 7) == "window_" then
        windowIndex = windowIndex + 1
        
        if canRollWindow(currentVehicle, windowIndex) then
          boneData.windowID = windowIndex
          
          -- Determine window image based on side
          if string.sub(boneData.bone, 8, 8) == "l" then
            boneData.image = "window2.png"
          else
            boneData.image = "window.png"
          end
          
          boneData.active = not brokenWindows[currentVehicle][boneData.windowID]
          table.insert(points, boneData)
        end
      end
    end
  end
  
  interactionPoints = points
end

-- Update vehicle data in UI
function updateVehicleData()
  local isDriver = GetPedInVehicleSeat(currentVehicle, -1) == GetPlayerPed(-1)
  local engineRunning = GetIsVehicleEngineRunning(currentVehicle)
  local hazardsOn = GetVehicleIndicatorLights(currentVehicle) == 3
  local locked = getLockState(currentVehicle)
  
  SendNUIMessage({
    action = "updateVehicleData",
    data = {
      isDriver = isDriver,
      engine = engineRunning,
      hazards = hazardsOn,
      locked = locked
    }
  })
end

-- Update interaction point positions on screen
function updateInteractionPointPositions()
  CreateThread(function()
    while isMenuOpen do
      local visiblePoints = {}
      
      for _, point in pairs(interactionPoints) do
        local boneWorldPos = GetWorldPositionOfEntityBone(currentVehicle, point.boneIndex)
        local onScreen, screenX, screenY = GetHudScreenPositionFromWorldPosition(boneWorldPos.x, boneWorldPos.y, boneWorldPos.z)
        
        if not onScreen then
          point.left = screenX * 100
          point.top = screenY * 100
          table.insert(visiblePoints, point)
        end
      end
      
      SendNUIMessage({action = "updateData", data = visiblePoints})
      SetPauseMenuActive(false)
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      Wait(50)
    end
  end)
end

-- Monitor vehicle changes while menu is open
function monitorVehicleChange()
  CreateThread(function()
    while isMenuOpen do
      local playerVehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
      
      if currentVehicle ~= playerVehicle then
        closeMenu()
        return
      end
      
      buildInteractionPoints()
      updateVehicleData()
      Wait(500)
    end
  end)
end

-- Open the vehicle menu
function openMenu()
  local playerPed = GetPlayerPed(-1)
  local vehicle = GetVehiclePedIsIn(playerPed, false)
  currentVehicle = vehicle
  
  if currentVehicle == 0 then
    return
  end
  
  SetNuiFocus(true, true)
  
  if Config.useCamera then
    toggleCamera(true)
    SetNuiFocusKeepInput(true)
  end
  
  isMenuOpen = true
  SetCursorLocation(0.5, 0.5)
  monitorVehicleChange()
  updateInteractionPointPositions()
  SendNUIMessage({action = "toggleUI", data = true})
end

-- Register command and keybind
CreateThread(function()
  RegisterCommand(Config.command, function(source, args)
    local playerPed = GetPlayerPed(-1)
    
    if IsPedInAnyVehicle(playerPed, false) then
      local vehicleModel = GetEntityModel(GetVehiclePedIsIn(playerPed))
      
      if Config.blacklist[vehicleModel] then
        return
      end
      
      if not isMenuOpen then
        openMenu()
      else
        closeMenu()
      end
    end
  end)
  
  TriggerEvent("chat:addSuggestion", "/" .. Config.command, Config.commandHelpText)
  
  if not Config.disableKeybind then
    RegisterKeyMapping(Config.command, Config.commandHelpText, "keyboard", Config.defaultKey)
  end
end)

-- Load primary color from convar
local primaryColor = GetConvar("skeletonnetworks:primaryColor", "")

if primaryColor and primaryColor ~= "" then
  primaryColor = json.decode(primaryColor)
else
  primaryColor = {157, 96, 255}
end

-- NUI Callback: UI Loaded
RegisterNUICallback("uiLoaded", function(data, callback)
  SendNUIMessage({
    action = "setPrimaryColor",
    data = string.format("rgb(%s,%s,%s)", primaryColor[1], primaryColor[2], primaryColor[3])
  })
  callback(1)
end)

-- NUI Callback: Exit Menu
RegisterNUICallback("exitMenu", function(data, callback)
  closeMenu()
  callback(1)
end)

-- NUI Callback: Item Clicked
local canClick = true

RegisterNUICallback("itemClicked", function(data, callback)
  if not canClick then
    return callback(0)
  end
  
  canClick = false
  local playerPed = GetPlayerPed(-1)
  
  -- Handle seat changes
  if data.seatID then
    if IsVehicleSeatFree(currentVehicle, data.seatID) then
      changeSeat(playerPed, currentVehicle, data.seatID)
    end
    
  -- Handle door toggles
  elseif data.doorID then
    if GetVehicleDoorAngleRatio(currentVehicle, data.doorID) > 0.0 then
      SetVehicleDoorShut(currentVehicle, data.doorID, false)
    else
      SetVehicleDoorOpen(currentVehicle, data.doorID, false)
    end
    
  -- Handle window toggles
  elseif data.windowID then
    if not brokenWindows[currentVehicle] then
      brokenWindows[currentVehicle] = {}
    end
    
    if brokenWindows[currentVehicle][data.windowID] then
      RollUpWindow(currentVehicle, data.windowID)
      brokenWindows[currentVehicle][data.windowID] = nil
    else
      RollDownWindow(currentVehicle, data.windowID)
      brokenWindows[currentVehicle][data.windowID] = true
    end
    
  -- Handle hazard lights
  elseif data.hazards then
    if GetVehicleIndicatorLights(currentVehicle) == 3 then
      SetVehicleIndicatorLights(currentVehicle, 0, false)
      SetVehicleIndicatorLights(currentVehicle, 1, false)
    else
      SetVehicleIndicatorLights(currentVehicle, 0, true)
      SetVehicleIndicatorLights(currentVehicle, 1, true)
    end
    updateVehicleData()
    
  -- Handle engine toggle
  elseif data.engine then
    toggleEngine(currentVehicle)
    updateVehicleData()
    
  -- Handle lock toggle
  elseif data.lock then
    toggleLocks(currentVehicle)
    updateVehicleData()
  end
  
  buildInteractionPoints()
  canClick = true
  callback(1)
end)