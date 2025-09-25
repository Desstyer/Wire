--!strict
--[[
	Wire module
	By @Desstyer
	28/8/2025
	
	Simple server-client communication module
]]

-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local Client = require(script.Communication.Client)
local Server = require(script.Communication.Server)

-- Types

-- Constants
local Wire = {}

local Events = script:WaitForChild("Events")
local Functions = script:WaitForChild("Functions")

type fn = (...any) -> (...any)

-- Get a RemoteEvent as a RemoteSignal wrapper object
-- Might yield if not created yet
function Wire.GetSignal(event_id: string): Client.RemoteSignal
	assert(RunService:IsClient(), `This function cannot be called from the server`)
	local signal = Client.Signal(Events, event_id)
	return signal
end

-- Get a RemoteFunction as a function that calls it.
-- Might yield if the remote function is not found
function Wire.GetFunction(function_id: string): fn
	assert(RunService:IsClient(), `This function cannot be called from the server`)
	local callback = Client.Function(Functions, function_id)
	return callback
end

-- Create a RemoteSignal object
-- Automatically creates a RemoteEvent behind the scenes
-- Can only be called from the server
function Wire.CreateSignal(event_id: string): Server.RemoteSignal
	assert(RunService:IsServer(), `This function cannot be called from the client`)

	local signal = Server.Signal(Events, event_id)
	return signal
end

-- Binds a function to a RemoteFunction
-- When the remote function is invoked by the client/server it will call the function
function Wire.CreateFunction(function_id: string, callback: fn)
	if RunService:IsClient() then 
		warn(`[{script.Name}]: Cannot create functions from the client`) 
		return 
	end
	if not callback then
		warn(`[{script.Name}]: No callback provided for function '{function_id}'`)
		return
	end
	Server.Function(callback, Functions, function_id)
end

return Wire
