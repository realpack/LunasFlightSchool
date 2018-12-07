--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:RunOnSpawn()
	for _, Pos in pairs( { Vector(5,-8,38), Vector(-35,-8,38), Vector(-35,8,38) } ) do
		self:AddPassengerSeat( Pos, self.SeatAng )
	end
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end

function ENT:HandleWeapons(Fire1, Fire2)
end

function ENT:OnEngineStarted()
	self:EmitSound( "lfs/cessna/start.wav" )
end

function ENT:OnEngineStopped()
	self:EmitSound( "lfs/cessna/stop.wav" )
end

