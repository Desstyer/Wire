--!strict
--[[
	//-----------------------------//-//-------//
	//- [Wire]                    -//=//- V2  -//
	//-----------------------------//-//-------//
	
	//-----------------------------//
	//- By @Desstyer              -//
	//- Created: 28/8/2025        -//
	//- Last updated: 20/1/2026   -//
	//-----------------------------//
	
	Simple server-client communication module
	
	Changelog (V1 -> V2):
	- Changed documentation at top
	- Added Wire.Signal
	- Refactored to use unified RemoteSignal and RemoteFunction classes
]]

-- Services
local RunService = game:GetService("RunService")

-- Dependencies
local RemoteSignal = require(script.RemoteSignal)
local RemoteCallback = require(script.RemoteCallback)

-- Types --

export type RemoteSignal<T...> = RemoteSignal.RemoteSignal<T...>
export type RemoteCallback<T..., R...> = RemoteCallback.RemoteCallback<T..., R...>

-- Constants
local IS_SERVER = RunService:IsServer()
local Wire = {}
local Events = script:WaitForChild("Events")
local Functions = script:WaitForChild("Functions")

-- Get or create a RemoteSignal based on RunContext
function Wire.Signal<T...>(event_id: string): RemoteSignal.RemoteSignal<T...>
	return RemoteSignal.New(Events, event_id)
end

-- Get or create a RemoteFunction based on RunContext
-- If a callback is provided it will override the current one within the run context
function Wire.Callback<T..., R...>(function_id: string, callback: ((T...) -> (R...))?): RemoteCallback.RemoteCallback<T..., R...>
	return RemoteCallback.New(Functions, function_id, callback)
end

return Wire
