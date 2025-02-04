-- Get the QBCore object from the exported resource
local QBCore = exports['qb-core']:GetCoreObject()

-- Helper: checks if the current ped has the driver_license item.
local function HasDriverLicense()
    return QBCore.Functions.HasItem('driver_license')
end

-- Helper: determines which seat the ped is occupying in a given vehicle.
local function GetCurrentSeat(vehicle, ped)
    local seatIndex = nil
    if GetPedInVehicleSeat(vehicle, -1) == ped then
        seatIndex = -1
    else
        for i = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
            if GetPedInVehicleSeat(vehicle, i) == ped then
                seatIndex = i
                break
            end
        end
    end
    return seatIndex
end

-- Check if the vehicle is in the exception list
local function IsNoLicenseVehicle(vehicle)
    local modelHash = GetEntityModel(vehicle)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(modelHash))
    for _, allowedModel in ipairs(Config.NoLicenseVehicles) do
        if modelName == allowedModel then
            return true
        end
    end
    return false
end

-- In this version, only the driver's seat (-1) is restricted for players without a license.
local function IsRestrictedSeat(seatIndex)
    return seatIndex == -1
end

-- Main loop: every half-second, check if the player is in a vehicle and in a restricted seat without a license.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- If the vehicle is on the exception list, skip the license check.
            if IsNoLicenseVehicle(vehicle) then
                goto continue
            end

            local seat = GetCurrentSeat(vehicle, ped)
            if seat and IsRestrictedSeat(seat) then
                if not HasDriverLicense() then
                    QBCore.Functions.Notify("You don't have a driver license. You need a driver license to drive this vehicle.", "error")
                    TaskLeaveVehicle(ped, vehicle, 0)
                end
            end
        end
        ::continue::
    end
end)
