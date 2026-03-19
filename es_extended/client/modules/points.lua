local points = {}

function ESX.CreatePointInternal(coords, distance, hidden, enter, leave)
	local point = {
		coords = coords,
		distance = distance,
		hidden = hidden,
		enter = enter,
		leave = leave,
		resource = GetInvokingResource()
	}
	local handle = ESX.Table.SizeOf(points) + 1
	points[handle] = point
	return handle
end

function ESX.RemovePointInternal(handle)
	points[handle] = nil
end

function ESX.HidePointInternal(handle, hidden)
	if points[handle] then
		points[handle].hidden = hidden
	end
end

local pointsLoopStarted = false

local function runPointsLoop()
	if not ESX.PlayerLoaded or not ESX.PlayerData.ped then
		return SetTimeout(500, runPointsLoop)
	end

	local coords = GetEntityCoords(ESX.PlayerData.ped)
	for handle, point in pairs(points) do
		if not point.hidden and #(coords - point.coords) <= point.distance then
			if not point.nearby then
				points[handle].nearby = true
				points[handle].enter()
			end
		elseif point.nearby then
			points[handle].nearby = false
			points[handle].leave()
		end
	end

	SetTimeout(500, runPointsLoop)
end

function StartPointsLoop()
	if pointsLoopStarted then return end
	pointsLoopStarted = true
	runPointsLoop()
end


AddEventHandler('onResourceStop', function(resource)
	for handle, point in pairs(points) do
		if point.resource == resource then
			points[handle] = nil
		end
	end
end)