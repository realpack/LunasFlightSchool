--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:Think()
	
	self:HandleActive()
	self:HandleLandingGear()
	self:HandleWeapons()
	self:CalcFlight()
	self:PrepExplode()
	self:RechargeShield()
	self:OnTick()
	
	self:NextThink( CurTime() )
	
	return true
end

function ENT:CalcFlight()
	if not self:GetEngineActive() then 
		self:SetRPM( math.max(self:GetRPM() - self:GetRPM() * FrameTime() * 2,0) )
		return
	end
	
	if self:IsDestroyed() or self:GetRotorDestroyed() then
		self:StopEngine()
	end
	
	self:CheckRotorClearance()
	self:InWater()
	
	local MaxTurnSpeed = self:GetMaxTurnSpeedHeli()
	local MaxPitch = MaxTurnSpeed.p
	local MaxYaw = MaxTurnSpeed.y
	local MaxRoll = MaxTurnSpeed.r
	
	local PhysObj = self:GetPhysicsObject()
	if not IsValid( PhysObj ) then return end
	
	local Pod = self:GetDriverSeat()
	if not IsValid( Pod ) then return end
	
	local Driver = Pod:GetDriver()
	
	local EyeAngles = self:GetAngles()

	local OnGround = self:HitGround()
	
	local W = false
	local A = false
	local S = OnGround
	local D = false
	
	local HoverMode  = false
	
	if IsValid( Driver ) then
		EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
		
		if Driver:KeyDown( IN_WALK ) then
			if isangle( self.StoredEyeAngles ) then
				EyeAngles = self.StoredEyeAngles
			end
		else
			self.StoredEyeAngles = EyeAngles
		end
		
		W = Driver:KeyDown( IN_FORWARD )
		A = Driver:KeyDown( IN_MOVELEFT )
		S = not W and OnGround or Driver:KeyDown( IN_BACK )
		D = Driver:KeyDown( IN_MOVERIGHT )
		
		HoverMode = Driver:KeyDown( IN_SPEED )
	end
	
	local LocalVel = self:WorldToLocal( self:GetVelocity() + self:GetPos() )
	local AngVel = self:GetAngVel()
	
	local Mass = PhysObj:GetMass()
	
	local TargetThrust = self:GetMaxThrustHeli() * ((W and 1 or 0)  - (S and 1 or 0))
	local Rate = FrameTime() * 8
	
	self.Thrust = self.Thrust and ( self.Thrust + math.Clamp( TargetThrust - self.Thrust,-Rate,Rate ) ) or 0
	
	local cForce = self:GetZForce()
	local Force = Vector(0,0,cForce * (1 - self:GetThrustEfficiency())) + self:GetUp() * (cForce * self:GetThrustEfficiency() - LocalVel.z * 0.01 + self.Thrust)
	
	self.Roll = self.Roll and self.Roll + ((D and MaxRoll or 0) - (A and MaxRoll or 0)) * FrameTime() or 0

	local AngForce = self:WorldToLocalAngles( Angle(EyeAngles.p,EyeAngles.y,self.Roll) )
	
	local HasAI = self:GetAI()
	
	if HasAI or HoverMode then
		--local Ang = self:RunAI()
		local P = math.Clamp(-LocalVel.x * 0.1,-40,40)
		local Y = self:GetAngles().y
		local R = math.Clamp(LocalVel.y * 0.1,-40,40)
		
		if A or D then
			R = (D and 60 or 0) - (A and 60 or 0)
		end
		
		AngForce = self:WorldToLocalAngles( Angle(P,HasAI and Y or EyeAngles.y,R) )
		
		self.Roll = 0
		
		if HasAI then
			self.Thrust = math.Clamp( -LocalVel.z,0,self:GetMaxThrustHeli())
		end
	end
	
	self:SetRPM( self:GetLimitRPM() * ((self.Thrust + cForce) / (self:GetMaxThrustHeli() + cForce)) )
	
	AngForce.p = math.Clamp(AngForce.p,-MaxPitch,MaxPitch)
	AngForce.y = math.Clamp(AngForce.y,-MaxYaw,MaxYaw)
	AngForce.r = math.Clamp(AngForce.r + math.cos(CurTime()) * 2,-MaxRoll,MaxRoll)
	
	PhysObj:ApplyForceCenter( Force * Mass )
	
	if (OnGround and (W or A or D or HoverMode)) or not OnGround then
		self:ApplyAngForce( (AngForce * 2 - AngVel) * FrameTime() * Mass * 500 )
	else
		self:ApplyAngForce( -AngVel * Mass * FrameTime() * 500 )
	end
	
	self:SetRotPitch( AngForce.p / MaxPitch )
	self:SetRotYaw( AngForce.y / MaxYaw)
	self:SetRotRoll( AngForce.r / MaxRoll )
end

function ENT:OnRotorDestroyed()
	self:EmitSound( "physics/metal/metal_box_break2.wav" )
	
	self:SetHP(1)
	
	timer.Simple(2, function()
		if not IsValid( self ) then return end
		self:Destroy()
	end)
end

function ENT:OnRotorCollide( Pos, Dir )
	local effectdata = EffectData()
		effectdata:SetOrigin( Pos )
		effectdata:SetNormal( Dir )
	util.Effect( "manhacksparks", effectdata, true, true )

	self:EmitSound( "ambient/materials/roust_crash"..math.random(1,2)..".wav" )
end

function ENT:CheckRotorClearance()
	if self.BreakRotor then
		if self.BreakRotor ~= self:GetRotorDestroyed() then
			self:SetRotorDestroyed( self.BreakRotor )
			self:OnRotorDestroyed()
		end
		
		return
	end
	
	local angUp = self:GetRotorAngle()
	local Up = angUp:Up()
	local Forward = angUp
	Forward:RotateAroundAxis( Up, -CurTime() * 2000 )
	Forward = Forward:Forward()
	
	local position = self:GetRotorPos()

	local tr = util.TraceLine( {
		start = position,
		endpos = (position + Forward * self:GetRotorRadius()),
		filter = function( ent ) 
			if ent == self or ent:IsPlayer() then 
				return false
			end
			
			return true
		end
	} )
	
	self.RotorHitCount = self.RotorHitCount or 0
	
	if tr.Hit then
		self.RotorHit = true
		
		self.RotorHitCount = self.RotorHitCount + 1
	else 
		self.RotorHit = false
		
		self.RotorHitCount = math.max(self.RotorHitCount - 1 * FrameTime(),0)
	end
	
	if self.RotorHitCount > 20 then
		self.BreakRotor = true
	end
	
	if self.RotorHit ~= self.oldRotorHit then
		self.oldRotorHit = self.RotorHit
		if self.RotorHit then
			self:OnRotorCollide( tr.HitPos, tr.HitNormal )
		end
	end
end

function ENT:HitGround()
	if not isvector( self.obbvc ) or not isnumber( self.obbvm ) then
		self.obbvc = self:OBBCenter() 
		self.obbvm = self:OBBMins().z
	end
	
	local tr = util.TraceLine( {
		start = self:GetPos(),
		endpos = self:LocalToWorld( self.obbvc + Vector(0,0,self.obbvm - 100) ),
		filter = function( ent ) 
			if ( ent == self ) then 
				return false
			end
		end
	} )
	
	return tr.Hit 
end

function ENT:GetZForce()
	if not isnumber( self.ZForce ) then
		self.ZForce = 600 * FrameTime()
	end
	return self.ZForce
end

function ENT:StartEngine()
	if self:GetEngineActive() or self:IsDestroyed() or self:InWater() or not self:IsEngineStartAllowed() or self:GetRotorDestroyed() then return end
	
	self:SetEngineActive( true )
	self:OnEngineStarted()

	local RotorWash = ents.Create( "env_rotorwash_emitter" )
	
	if IsValid( RotorWash ) then
		RotorWash:SetPos( self:GetRotorPos() )
		RotorWash:SetAngles( Angle(0,0,0) )
		RotorWash:Spawn()
		RotorWash:Activate()
		RotorWash:SetParent( self )
		
		RotorWash.DoNotDuplicate = true
		self:DeleteOnRemove( RotorWash )
		self:dOwner( RotorWash )
		
		self.RotorWashEnt = RotorWash
	end
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end
	
	self:SetEngineActive( false )
	self:OnEngineStopped()
	
	if IsValid( self.RotorWashEnt ) then
		self.RotorWashEnt:Remove()
	end
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

function ENT:OnLandingGearToggled( bOn )
end
