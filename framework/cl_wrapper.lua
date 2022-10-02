function Framework()
	if Config.framework == 'ESX' then
		ESX = exports['es_extended']:getSharedObject()
		PlayerData = ESX.GetPlayerData()
	elseif Config.framework == 'QBCORE' then
		QBCore = exports['qb-core']:GetCoreObject()
		QBCore.Functions.GetPlayerData(function(p)
			PlayerData = p
			if PlayerData.job ~= nil then
				PlayerData.job.grade = PlayerData.job.grade.level
			end
			if PlayerData.identifier == nil then
				PlayerData.identifier = PlayerData.license
			end
        end)
	end
	if Config.framework == 'ESX' then
		TriggerServerCallback_ = function(...)
			ESX.TriggerServerCallback(...)
		end
	elseif Config.framework == 'QBCORE' then
		TriggerServerCallback_ =  function(...)
			QBCore.Functions.TriggerCallback(...)
		end
	end
end

function Playerloaded()
	if Config.framework == 'ESX' then
		RegisterNetEvent('esx:playerLoaded')
		AddEventHandler('esx:playerLoaded', function(xPlayer)
			PlayerData = xPlayer
			playerloaded = true
		end)
	elseif Config.framework == 'QBCORE' then
		RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
		AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
			playerloaded = true
			QBCore.Functions.GetPlayerData(function(p)
				PlayerData = p
				if PlayerData.job ~= nil then
					PlayerData.job.grade = PlayerData.job.grade.level
				end
				if PlayerData.identifier == nil then
					PlayerData.identifier = PlayerData.license
				end
			end)
		end)
	end
end

function SetJob()
	if Config.framework == 'ESX' then
		RegisterNetEvent('esx:setJob')
		AddEventHandler('esx:setJob', function(job)
			PlayerData.job = job
			playerjob = PlayerData.job.name
			inmark = false
			cancel = true
			markers = {}
		end)
	elseif Config.framework == 'QBCORE' then
		RegisterNetEvent('QBCore:Client:OnJobUpdate')
		AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
			PlayerData.job = job
			PlayerData.job.grade = PlayerData.job.grade.level
			playerjob = PlayerData.job.name
			inmark = false
			cancel = true
			markers = {}
		end)
	end
end

MathRound = function(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

ShowNotification = function(msg)
	if Config.framework == 'ESX' then
		ESX.ShowNotification(msg)
	elseif Config.framework == 'QBCORE' then
		TriggerEvent('QBCore:Notify', msg)
	end
end