Citizen.CreateThread(function()
    while esx.GetPlayerData().job == nil do
        Citizen.Wait(2000)
    end

    esx.PlayerData = esx.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    esx.PlayerData = xPlayer
    esx.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    esx.PlayerLoaded = false
    esx.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    print(json.encode(job))
    esx.PlayerData.job = job
end)
