--!strict
-- Unified RemoteFunction class that works on both client and server

local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

export type RemoteCallback<T..., R...> = {
	instance: RemoteFunction,
		
	InvokeClient: (self: any, player: Player, T...) -> R...,
	Destroy: (self: any) -> (),

	InvokeServer: (self: any, T...) -> R...,
}

local RemoteCallback = {}
RemoteCallback.__index = RemoteCallback

-- Check if instance already exists
local function AlreadyExists(name: string, parent: Instance): RemoteFunction?
	for _, v in ipairs(parent:GetDescendants()) do
		if v:IsA("RemoteFunction") and v.Name == name then
			return v
		end
	end
	return nil
end

-- Constructor
-- If a callback is provided by the client, it will set the OnClientInvoke property
function RemoteCallback.New<T..., R...>(parent: Instance, name: string, callback: ((T...) -> (R...))?): RemoteCallback<T..., R...>
	local remote: RemoteFunction
	
	if IS_SERVER then
		-- Server: create or error if exists
		local current = AlreadyExists(name, parent)
		if current ~= nil then
			remote = current
		else
			remote = Instance.new("RemoteFunction")
			remote.Name = name

			remote.Parent = parent
		end
		
		if remote and callback then
			remote.OnServerInvoke = callback :: any
		end
	else
		remote = parent:WaitForChild(name) :: RemoteFunction

		assert(remote and remote:IsA("RemoteFunction"), `No remote with the name '{name}' was found`)
		
		if callback then
			remote.OnClientInvoke = callback
		end
	end

	local self = setmetatable({
		instance = remote
	}, RemoteCallback)

	return self :: any
end

function RemoteCallback:InvokeClient(player: Player, ...): ...any
	assert(IS_SERVER, "InvokeClient can only be called from the server")
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Invalid player provided")

	return self.instance:InvokeClient(player, ...)
end

function RemoteCallback:InvokeServer(...): ...any
	assert(not IS_SERVER, "InvokeServer can only be called from the client")

	return self.instance:InvokeServer(...)
end

function RemoteCallback:Destroy()
	assert(IS_SERVER, "Cannot destroy RemoteCallback from client")
	self.instance:Destroy()
end

return RemoteCallback
