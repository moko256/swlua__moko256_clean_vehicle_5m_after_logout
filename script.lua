-- SPDX-License-Identifier: MIT

time_for_despawn = 5 * 60 * 1000 -- duration (ms)
time_for_loaded = 2 * 60 * 1000 -- duration (ms)

g_savedata = {
	spawned_vehicle_ids = {}, -- Map<vehicle_id, steam_id>
	steam_ids = {}, -- Map<peer_id, steam_id>
}
will_removed = {} -- Map<vehicle_id, { steam_id, remove_at }>

function onCreate(is_world_create)
	local remove_at = server.getTimeMillisec() + time_for_despawn + time_for_loaded
	for vehicle_id, steam_id in pairs(g_savedata.spawned_vehicle_ids) do
		will_removed[vehicle_id] = { steam_id = steam_id, remove_at = remove_at }
	end
end

function onTick()
	for vehicle_id, v in pairs(will_removed) do
		if v.remove_at <= server.getTimeMillisec() then
			g_savedata.spawned_vehicle_ids[vehicle_id] = nil
			will_removed[vehicle_id] = nil
			server.despawnVehicle(vehicle_id, true)
		end
	end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z)
	if peer_id ~= -1 then
		g_savedata.spawned_vehicle_ids[vehicle_id] = g_savedata.steam_ids[peer_id]
	end
end

function onVehicleDespawn(vehicle_id, peer_id)
	if peer_id ~= -1 then
		g_savedata.spawned_vehicle_ids[vehicle_id] = nil
		will_removed[vehicle_id] = nil
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	g_savedata.steam_ids[peer_id] = steam_id
	for vehicle_id, v in pairs(will_removed) do
		if v.steam_id == steam_id then
			will_removed[vehicle_id] = nil
		end
	end
end

function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
	g_savedata.steam_ids[peer_id] = nil
	local remove_at = server.getTimeMillisec() + time_for_despawn
	for vehicle_id, that_steam_id in pairs(g_savedata.spawned_vehicle_ids) do
		if that_steam_id == steam_id then
			will_removed[vehicle_id] = { steam_id = that_steam_id, remove_at = remove_at }
		end
	end
end

function onPlayerSit(peer_id, vehicle_id, seat_name)
	local steam_id = g_savedata.steam_ids[peer_id]
	local that_steam_id = g_savedata.spawned_vehicle_ids[vehicle_id]
	if (that_steam_id ~= nil) and (that_steam_id ~= steam_id) then
		g_savedata.spawned_vehicle_ids[vehicle_id] = steam_id
		will_removed[vehicle_id] = nil
	end
end