-- SERVER-SIDE
local Server = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Libraries.Signal)

export type RemoteSignal = {
	instance: RemoteEvent,

	Fire: (self: RemoteSignal, player: Player, ...any) -> (),
	FireAll: (self: RemoteSignal, any) -> (),
	Connect: (self: RemoteSignal, listener: (any) -> ()) -> (RBXScriptConnection),
	Once: (self: RemoteSignal, listener: (any) -> ()) -> (RBXScriptConnection),
	Destroy: (self: RemoteSignal) -> (),
	FireClients: (self: RemoteSignal, players: {Player}, ...any) -> (),
	FireFilter: (self: RemoteSignal, predicate: (player: Player) -> (boolean), ...any) -> ({Player})
}

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

-- Checks if the provided parent already has an instance with the same name.
function AlreadyExists(name: string, parent: Instance, class_name: string? | {string}?)
	for _, v in ipairs(parent:GetChildren()) do
		if class_name then
			if typeof(class_name) == "table" and table.find(class_name, v.ClassName) and v.Name == name then
				return true
			elseif typeof(class_name) == "string" and v.ClassName == class_name and v.Name == name then
				return true
			elseif v.Name == name then
				return true
			end
		end
	end
	return false
end

-- Create a function for multi-level communication (client to server)
function Server.Function(callback: (...any) -> (...any), parent: Instance, name: string): RemoteFunction
	assert(RunService:IsServer(), "This function can only be called from the server")
	
	if AlreadyExists(name, parent, {"RemoteEvent", "RemoteFunction"}) then
		error(`Function with the name '{name}' already exists!`)
	end
	
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.OnServerInvoke = callback
	remote.Parent = parent
	
	return remote
end

-- Create a signal for multi-level communication (two way)
function Server.Signal(parent: Instance, name: string): RemoteSignal
	assert(RunService:IsServer(), "This function can only be called from the server")	
	
	if AlreadyExists(name, parent, {"RemoteEvent", "RemoteFunction"}) then
		error(`Signal with the name '{name}' already exists!`)
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent

	local self = setmetatable({
		instance = remote	
	}, RemoteSignal)

	return self
end

function RemoteSignal:Destroy()
	self.instance:Destroy()
end

function RemoteSignal:Connect(listener: (any) -> ())
	assert(typeof(listener) == "function", "Invalid listener provided")
	-- for now, we directly connect to the remote, we can change this
	-- to add extra functionality later.
	return self.instance.OnServerEvent:Connect(listener)
end

function RemoteSignal:Fire(player: Player, ...)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Invalid player provided")
	
	self.instance:FireClient(player, ...)
end

function RemoteSignal:Once(listener: (any) -> ())
	return self.instance.OnServerEvent:Once(listener)
end

function RemoteSignal:FireAll(...)
	self.instance:FireAllClients(...)
end

function RemoteSignal:FireClients(players: {Player}, ...)
	for _, player in ipairs(players) do
		self.instance:FireClient(player, ...)
	end
end

function RemoteSignal:FireFilter(predicate: (Player) -> (boolean), ...): {Player}
	local players = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			table.insert(players, player)
		end
	end
	self:FireClients(players)
	return players
end

return Server
