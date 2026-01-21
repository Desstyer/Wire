--!strict
-- Unified RemoteSignal class that works on both client and server

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IS_SERVER = RunService:IsServer()

export type RemoteSignal<T...> = {
	instance: RemoteEvent,
	
	-- Server methods
	Fire: (self: any, player: Player, ...any) -> (),
	FireAll: (self: any, T...) -> (),
	FireClients: (self: any, players: {Player}, T...) -> (),
	FireFilter: (self: any, predicate: (player: Player) -> boolean, T...) -> {Player},
	
	-- Client methods
	FireServer: (self: any, ...any) -> (),
	
	-- Shared methods
	Connect: (self: any, listener: (...any) -> ()) -> RBXScriptConnection,
	Once: (self: any, listener: (...any) -> ()) -> RBXScriptConnection,
	Destroy: (self: any) -> ()
}

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

-- Check if instance already exists
local function AlreadyExists(name: string, parent: Instance): RemoteEvent?
	for _, v in ipairs(parent:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == name then
			return v
		end
	end
	return nil
end

-- Constructor
function RemoteSignal.New<T...>(parent: Instance, name: string): RemoteSignal<T...>
	local remote: RemoteEvent

	if IS_SERVER then
		local current = AlreadyExists(name, parent)
		if current ~= nil then
			remote = current
		else
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = parent
		end
	else
		-- Client: wait for it
		remote = parent:WaitForChild(name) :: RemoteEvent

		assert(remote, `No remote with the name '{name}' was found`)
	end

	local self = setmetatable({
		instance = remote
	}, RemoteSignal)

	return self :: any
end

-- Shared: Connect to signal
function RemoteSignal:Connect(listener: (...any) -> ())
	assert(typeof(listener) == "function", "Invalid listener provided")

	if IS_SERVER then
		return self.instance.OnServerEvent:Connect(listener)
	else
		return self.instance.OnClientEvent:Connect(listener)
	end
end

-- Shared: Connect once
function RemoteSignal:Once(listener: (...any) -> ())
	assert(typeof(listener) == "function", "Invalid listener provided")

	if IS_SERVER then
		return self.instance.OnServerEvent:Once(listener)
	else
		return self.instance.OnClientEvent:Once(listener)
	end
end

-- Shared: Destroy the signal (server only creates, but allow cleanup)
function RemoteSignal:Destroy()
	assert(IS_SERVER, "Cannot destroy RemoteSignal from client")
	
	self.instance:Destroy()
end

-- Server: Fire to specific player
function RemoteSignal:Fire(player: Player, ...)
	assert(IS_SERVER, "Fire can only be called from the server")
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Invalid player provided")

	self.instance:FireClient(player, ...)
end

-- Server: Fire to all players
function RemoteSignal:FireAll(...)
	assert(IS_SERVER, "FireAll can only be called from the server")

	self.instance:FireAllClients(...)
end

-- Server: Fire to multiple players
function RemoteSignal:FireClients(players: {Player}, ...)
	assert(IS_SERVER, "FireClients can only be called from the server")

	for _, player in ipairs(players) do
		self.instance:FireClient(player, ...)
	end
end

-- Server: Fire to filtered players
function RemoteSignal:FireFilter(predicate: (Player) -> boolean, ...): {Player}
	assert(IS_SERVER, "FireFilter can only be called from the server")

	local players = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			table.insert(players, player)
		end
	end

	self:FireClients(players, ...)
	return players
end

-- Client: Fire to server
function RemoteSignal:FireServer(...)
	assert(not IS_SERVER, "FireServer can only be called from the client")

	self.instance:FireServer(...)
end

return RemoteSignal
