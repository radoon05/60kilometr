



--[[
	THANK YOU FOR YOUR PURCHASE!

	TO SET COLOR ADD TO CFG:

	setr skeletonnetworks:primaryColor [31, 193, 193]
]]

Config = {
	disableKeybind = true, -- set to true to disable the use of keybind
	defaultKey = 'F3', -- default key used for open/close of menu
	command = 'vehiclem', -- /command used for open/close of menu
    commandHelpText = 'Open Vehicle Menu', -- help text when using command

	useCamera = true, -- places the camera where the player can see everything
	showWindows = true,
	blacklist = {
		[`bmx`] = true,
	}
}

function toggleEngine(vehicle)
    --TriggerEvent('qb-vehiclekeys:client:ToggleEngine') -- For qb-vehiclekeys checks if you have keys (You dont need the bottom code)
    SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), false, true)
end

function changeSeat(ped, vehicle, SeatID)
	--Wait(1000) -- idk wait time so they dont spam change seats or you can add a loading bad idk
    SetPedIntoVehicle(ped, vehicle, SeatID)
end

function getLockState(vehicle)
	return GetVehicleDoorLockStatus(vehicle) == 2
end

function toggleLocks(vehicle)
 	ExecuteCommand('togglelocks')-- QB VEHICLE KEYS
	--SetVehicleDoorsLocked(vehicle, getLockState(vehicle) and 1 or 2) -- NATIVE
end