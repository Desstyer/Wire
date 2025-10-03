-- CLIENT-SIDE
-- The difference from the Server version is that this is unable of creating instances, instead
-- creates RemoteSignals and RemoteFunctionSignals from existing instances.
local Client = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Libraries.Signal)

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

export type RemoteSignal = {
	instance: RemoteEvent,

	Fire: (self: RemoteSignal, ...any) -> (),
	Connect: (self: RemoteSignal, listener: (...any) -> ()) -> (RBXScriptConnection),
	Once: (self: RemoteSignal, listener: (...any) -> ()) -> (RBXScriptConnection)
}

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

-- Get a RemoteFunction as a function that calls it automatically
-- (Will WaitForChild)
function Client.Function(parent: Instance, name: string): (...any) -> (...any)
	local remote = parent:WaitForChild(name)
	
	if not remote then warn(`No function with the name {name} was found`) return end
	
	-- Invoke the RemoteFunction
	local function Fire(...)
		return remote:InvokeServer(...)
	end
	
	return Fire
end

-- Get a signal for multi-level communication (two way)
-- (Will WaitForChild)
function Client.Signal(parent: Instance, name: string): RemoteSignal

	local remote = parent:WaitForChild(name)
	
	if not remote then warn(`No remote with the name {name} was found`) return end

	local self = setmetatable({
		instance = remote
	}, RemoteSignal)

	return self
end

function RemoteSignal:Connect(listener: (any) -> ())
	assert(typeof(listener) == "function", "Invalid listener provided")
	-- for now, we directly connect to the remote, we can change this
	-- to add extra functionality later.
	return self.instance.OnClientEvent:Connect(listener)
end

function RemoteSignal:Once(listener: (any) -> ())
	return self.instance.OnClientEvent:Once(listener)
end

function RemoteSignal:Fire(...)
	self.instance:FireServer(...)
end

return Client
