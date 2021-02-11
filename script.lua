-- SPDX-License-Identifier: MIT

time_for_despawn = 5 * 60 * 1000 -- duration (ms)
time_for_loaded = 2 * 60 * 1000 -- duration (ms)

g_savedata = { spawned_vehicle_ids = {} } -- List<{vehicle_id, peer_id}>
will_removed = {} -- List<{vehicle_id, peer_id, remove_at}>

function remove_by_vehicle_id(target, id)
	for k,v in pairs(target) do
		if v.vehicle_id == id then
			table.remove(target, k)
			return
		end
	end
end

function onCreate(is_world_create)
	local remove_at = server.getTimeMillisec() + time_for_despawn + time_for_loaded
	for k,v in pairs(g_savedata.spawned_vehicle_ids) do
		table.insert(will_removed, {vehicle_id = v.vehicle_id, peer_id = v.peer_id, remove_at = remove_at})
	end
end

function onTick()
	for k,v in pairs(will_removed) do
		if v.remove_at <= server.getTimeMillisec() then
			table.remove(will_removed, k)
			remove_by_vehicle_id(g_savedata.spawned_vehicle_ids, v.vehicle_id)
			server.despawnVehicle(v.vehicle_id, true)
		end
	end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z)
	if peer_id ~= -1 then
		table.insert(g_savedata.spawned_vehicle_ids, {vehicle_id = vehicle_id, peer_id = peer_id})
	end
end

function onVehicleDespawn(vehicle_id, peer_id)
	if peer_id ~= -1 then
		remove_by_vehicle_id(g_savedata.spawned_vehicle_ids, vehicle_id)
		remove_by_vehicle_id(will_removed, vehicle_id)
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	for k,v in pairs(will_removed) do
		if v.peer_id == peer_id then
			table.remove(will_removed, k)
		end
	end
end

function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
	local remove_at = server.getTimeMillisec() + time_for_despawn
	for k,v in pairs(g_savedata.spawned_vehicle_ids) do
		if v.peer_id == peer_id then
			table.insert(will_removed, {vehicle_id = v.vehicle_id, peer_id = v.peer_id, remove_at = remove_at})
		end
	end
end

function onPlayerSit(peer_id, vehicle_id, seat_name)
	for k,v in pairs(g_savedata.spawned_vehicle_ids) do
		if v.vehicle_id == vehicle_id then
			if v.peer_id ~= peer_id then
				v.peer_id = peer_id
				remove_by_vehicle_id(will_removed, vehicle_id)
			end
			return
		end
	end
end