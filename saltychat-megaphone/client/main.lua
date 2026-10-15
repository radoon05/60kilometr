-- SaltyChat Megaphone System for FiveM
-- Framework support: ESX, QB-Core, Standalone
-- Cleaned and organized code

local framework = nil
local esx = nil
local qbcore = nil
local isUsingMegaphone = false

-- Utility function to detect framework
local function detectFramework()
    if framework then
        return framework
    end
    
    local esxState = GetResourceState("es_extended")
    if esxState == "started" then
        framework = "esx"
        
        if not esx then
            local success = pcall(function()
                local esxExport = exports.es_extended
                if esxExport then
                    esx = esxExport.getSharedObject()
                end
            end)
            
            if success and esx then
                -- ESX object obtained via export
            else
                -- Fallback to trigger event method
                TriggerEvent("esx:getSharedObject", function(obj)
                    esx = obj
                end)
            end
        end
    else
        local qbState = GetResourceState("qb-core")
        if qbState == "started" then
            framework = "qb"
            
            if not qbcore then
                qbcore = exports["qb-core"]:GetCoreObject()
            end
        else
            framework = nil
        end
    end
    
    if Config.Debug then
        print(string.format("[SaltyChat] Framework detected: %s", framework or "none"))
    end
    
    return framework
end

-- Initialize framework detection
detectFramework()

-- Get player data based on framework
local function getPlayerData()
    local currentFramework = framework or detectFramework()
    
    if currentFramework == "esx" then
        if esx then
            return esx.GetPlayerData()
        end
    elseif currentFramework == "qb" then
        if qbcore then
            return qbcore.Functions.GetPlayerData()
        end
    end
    
    return {}
end

-- Get player identifier based on framework
local function getPlayerIdentifier()
    local currentFramework = framework or detectFramework()
    local playerData = getPlayerData()
    
    if currentFramework == "esx" then
        if Config.Debug then
            print(string.format("[SaltyChat] Framework identifier: %s", playerData.identifier))
        end
        return playerData.identifier
    elseif currentFramework == "qb" then
        local license = playerData.license
        if not license then
            if playerData.metadata then
                license = playerData.metadata.license
            end
        end
        
        if Config.Debug then
            print(string.format("[SaltyChat] Framework identifier: %s", license))
        end
        
        return license or playerData.citizenid
    end
    
    return nil
end

-- Check if player has required item
local function hasRequiredItem()
    if not Config.UseItem then
        return true
    end
    
    local currentFramework = framework or detectFramework()
    local playerData = getPlayerData()
    
    if currentFramework == "esx" then
        if not playerData.inventory then
            return false
        end
        
        for _, item in pairs(playerData.inventory) do
            if item.name == Config.ItemName or item.label == Config.ItemName then
                local count = item.count or 0
                if count > 0 then
                    return true
                end
            end
        end
        
        return false
    elseif currentFramework == "qb" then
        if not playerData.items then
            return false
        end
        
        for _, item in pairs(playerData.items) do
            if item then
                if item.name == Config.ItemName then
                    local amount = item.amount or 0
                    if amount > 0 then
                        return true
                    end
                end
            end
        end
        
        return false
    end
    
    return false
end

-- Check if player has required job/grade
local function hasRequiredJob()
    if not Config.RequireJob then
        return true
    end
    
    if not Config.RequiredJobs or next(Config.RequiredJobs) == nil then
        return true
    end
    
    local currentFramework = framework or detectFramework()
    local playerData = getPlayerData()
    
    if currentFramework == "esx" then
        if not playerData.job then
            return false
        end
        
        local requiredGrade = Config.RequiredJobs[playerData.job.name]
        if not requiredGrade then
            return false
        end
        
        local currentGrade = playerData.job.grade or 0
        return requiredGrade <= currentGrade
    elseif currentFramework == "qb" then
        if not playerData.job then
            return false
        end
        
        local requiredGrade = Config.RequiredJobs[playerData.job.name]
        if not requiredGrade then
            return false
        end
        
        local currentGrade = 0
        if playerData.job.grade then
            if playerData.job.grade.level then
                currentGrade = playerData.job.grade.level
            elseif playerData.job.grade then
                currentGrade = playerData.job.grade
            end
        end
        
        return requiredGrade <= currentGrade
    end
    
    return false
end

-- Check if player identifier is in allowed list
local function hasAllowedIdentifier()
    local identifier = getPlayerIdentifier()
    if not identifier then
        return false
    end
    
    return Config.AllowedIdentifiers[identifier] == true
end

-- Check all permissions for megaphone use
local function canUseMegaphone()
    -- Check vehicle restriction
    if not Config.AllowInVehicles then
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            return false, "Not allowed in vehicles"
        end
    end
    
    -- Check if identifier is allowed and no item required
    if hasAllowedIdentifier() then
        if Config.AllowedIdentifierNoItem then
            return true
        end
    end
    
    -- Check item requirement
    if not hasRequiredItem() then
        return false, "Missing item"
    end
    
    -- Check job requirement
    if not hasRequiredJob() then
        return false, "Wrong job / grade"
    end
    
    return true
end

-- Start megaphone usage
local function startMegaphone()
    isUsingMegaphone = true
    local packedData = msgpack.pack(isUsingMegaphone)
    
    -- Play emote if configured
    if Config.UseEmote then
        if Config.EmoteName and Config.EmoteName ~= "" then
            ExecuteCommand(string.format("e %s", Config.EmoteName))
        end
    end
    
    -- Set state bag for other players to detect megaphone usage
    SetStateBagValue(
        "player:" .. GetPlayerServerId(PlayerId()),
        "SaltyChat_IsUsingMegaphone",
        packedData,
        packedData:len(),
        true
    )
    
    if Config.Debug then
        print("[SaltyChat] Megaphone started")
    end
end

-- Stop megaphone usage
local function stopMegaphone()
    isUsingMegaphone = false
    local packedData = msgpack.pack(isUsingMegaphone)
    
    -- Update state bag
    SetStateBagValue(
        "player:" .. GetPlayerServerId(PlayerId()),
        "SaltyChat_IsUsingMegaphone",
        packedData,
        packedData:len(),
        true
    )
    
    -- Cancel emote if configured
    if Config.UseEmote then
        ExecuteCommand("e c")
    end
    
    if Config.Debug then
        print("[SaltyChat] Megaphone stopped")
    end
end

-- Command handler for starting megaphone
local function handleMegaphoneStart()
    local canUse, reason = canUseMegaphone()
    
    if not canUse then
        if Config.Debug then
            print(string.format("[SaltyChat] Megaphone denied: %s", reason or "Unknown"))
        end
        return
    end
    
    startMegaphone()
end

-- Command handler for stopping megaphone
local function handleMegaphoneStop()
    if isUsingMegaphone then
        stopMegaphone()
    end
end

-- Initialize the megaphone system
CreateThread(function()
    detectFramework()
    
    local startCommand = "+" .. Config.MegaphoneCommand
    local stopCommand = "-" .. Config.MegaphoneCommand
    
    -- Register commands
    RegisterCommand(startCommand, handleMegaphoneStart, false)
    RegisterCommand(stopCommand, handleMegaphoneStop, false)
    
    -- Register key mapping
    RegisterKeyMapping(
        startCommand,
        Config.KeyBindName,
        Config.KeyBindMapper,
        Config.KeyBindDefaultParameter
    )
    
    if Config.Debug then
        print(string.format("[SaltyChat] Commands registered: %s / %s", startCommand, stopCommand))
    end
end)