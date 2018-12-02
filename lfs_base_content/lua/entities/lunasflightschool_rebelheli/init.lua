--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 100 )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:OnTick()
end

function ENT:RunOnSpawn()
	local PassengerSeats = {
		{
			pos = Vector(85,20,-7),
			ang = Angle(0,-90,10)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
		{
			pos = Vector(0,0,20),
			ang = Angle(0,-90,0)
		},
	}
	
	for num, v in pairs( PassengerSeats ) do
		local Pod = ents.Create( "prop_vehicle_prisoner_pod" )
		
		if IsValid( Pod ) then
			Pod:SetMoveType( MOVETYPE_NONE )
			Pod:SetModel( "models/nova/airboat_seat.mdl" )
			Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
			Pod:SetKeyValue( "limitview", 0 )
			Pod:SetPos( self:LocalToWorld( v.pos ) )
			Pod:SetAngles( self:LocalToWorldAngles( v.ang ) )
			
			if num == 1 then
				self:SetGunnerSeat( Pod )
			end
			
			Pod:SetOwner( self )
			Pod:Spawn()
			Pod:Activate()
			Pod:SetParent( self )
			Pod:SetNotSolid( true )
			Pod:SetNoDraw( true )
			Pod:DrawShadow( false )
			Pod.DoNotDuplicate = true
			
			self:DeleteOnRemove( Pod )
			self:dOwner( Pod )
			
			local DSPhys = Pod:GetPhysicsObject()
			if IsValid( DSPhys ) then
				DSPhys:EnableDrag( false ) 
				DSPhys:EnableMotion( false )
				DSPhys:SetMass( 1 )
			end
		end
	end
end

function ENT:PrimaryAttack()
end

function ENT:SecondaryAttack()
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:OnEngineStarted()
end

function ENT:OnEngineStopped()
end

function ENT:OnLandingGearToggled( bOn )
end

function ENT:OnHeliRotorDestroyed()
	self:EmitSound( "physics/metal/metal_box_break2.wav" )
	
	self:SetBodygroup( 1, 2 )
	self:SetBodygroup( 2, 2 ) 
	
	self:SetHP(1)
	
	timer.Simple(2, function()
		if not IsValid( self ) then return end
		self:Destroy()
	end)
end

function ENT:InitWheels()
	local PObj = self:GetPhysicsObject()
	
	if IsValid( PObj ) then 
		PObj:EnableMotion( true )
	end
	
	self:PhysWake()
end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end