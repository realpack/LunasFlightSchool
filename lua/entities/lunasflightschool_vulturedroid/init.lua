--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")


function ENT:RunOnSpawn()
	if not self:GetEngineActive() then
		self:PlayAnimation( "landing" )
	end
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() or not self:GetEngineActive() then return end

	self:EmitSound( "VULTURE_FIRE" )
	
	self:SetNextPrimary( 0.08 )
	
	local fP = { Vector(27.95,108.99,115.03), Vector(29.15,-110.55,103.67), Vector(29.15,110.55,103.67),Vector(27.95,-108.99,115.03) }

	self.NumPrim = self.NumPrim and self.NumPrim + 1 or 1
	if self.NumPrim > 4 then self.NumPrim = 1 end
	
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld( fP[self.NumPrim] )
	bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
	bullet.Spread 	= Vector( 0.02,  0.02, 0 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_red_large"
	bullet.Force	= 100
	bullet.HullSize 	= 40
	bullet.Damage	= 25
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end
	self:FireBullets( bullet )
	
	self:TakePrimaryAmmo()
end

function ENT:SecondaryAttack()
	if not self:CanPrimaryAttack() or not self:GetEngineActive() then return end
	
	self:SetNextPrimary( 0.16 )

	self:EmitSound( "VULTURE_ALTFIRE" )
	
	local startpos =  self:GetRotorPos()
	local TracePlane = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -10, -10, -10 ),
		maxs = Vector( 10, 10, 10 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )

	for i = 1, 2 do
		self.MirrorSec = not self.MirrorSec
		local Mirror = false
		for i = 0,1 do
			local M = Mirror and 1 or -1
			local Pos = Vector(29.15,110.55 * M,104 + (self.MirrorSec and 12 or 0))
			
			local bullet = {}
			bullet.Num 	= 1
			bullet.Src 	= self:LocalToWorld( Pos )
			bullet.Dir 	= (TracePlane.HitPos - bullet.Src):GetNormalized()
			bullet.Spread 	= Vector( 0.01,  0.01, 0 )
			bullet.Tracer	= 1
			bullet.TracerName	= "lfs_laser_red"
			bullet.Force	= 100
			bullet.HullSize 	= 40
			bullet.Damage	= 12.5
			bullet.Attacker 	= self:GetDriver()
			bullet.AmmoType = "Pistol"
			bullet.Callback = function(att, tr, dmginfo)
				dmginfo:SetDamageType(DMG_AIRBOAT)
			end
			self:FireBullets( bullet )
			self:TakePrimaryAmmo()
			Mirror = true
		end
	end
end

function ENT:RunEngine()
	local IdleRPM = self:GetIdleRPM()
	local MaxRPM =self:GetMaxRPM()
	local LimitRPM = self:GetLimitRPM()
	local MaxVelocity = self:GetMaxVelocity()
	
	self.TargetRPM = self.TargetRPM or 0
	
	if self:GetEngineActive() then
		local Pod = self:GetDriverSeat()
		
		if not IsValid( Pod ) then return end
		
		local Driver = Pod:GetDriver()
		
		local RPMAdd = 0
		local KeyThrottle = false
		local KeyBrake = false
		
		if IsValid( Driver ) then 
			KeyThrottle = Driver:KeyDown( IN_FORWARD )
			KeyBrake = Driver:KeyDown( IN_BACK )
			RPMAdd = ((KeyThrottle and 2000 or 0) - (KeyBrake and 2000 or 0)) * FrameTime()
		end
		
		if KeyThrottle ~= self.oldKeyThrottle then
			self.oldKeyThrottle = KeyThrottle
			if KeyThrottle then
				if self:CanSound() then
					self:EmitSound( "VULTURE_BOOST" )
					self:DelayNextSound( 1 )
				end
			else
				if (self:GetRPM() + 1) > MaxRPM then
					if self:CanSound() then
						self:EmitSound( "VULTURE_BRAKE" )
						self:DelayNextSound( 0.5 )
					end
				end
			end
		end
		
		self.TargetRPM = math.Clamp( self.TargetRPM + RPMAdd,IdleRPM,KeyThrottle and LimitRPM or MaxRPM)
	else
		self.TargetRPM = self.TargetRPM - math.Clamp(self.TargetRPM,-250,250)
	end
	
	self:SetRPM( self:GetRPM() + (self.TargetRPM - self:GetRPM()) * FrameTime() )
	
	local PhysObj = self:GetPhysicsObject()
	if not IsValid( PhysObj ) then return end
	
	local Throttle = self:GetRPM() / self:GetLimitRPM()
	
	local Power = (MaxVelocity * Throttle - self:GetForwardVelocity()) / MaxVelocity * self:GetMaxThrust() * self:GetLimitRPM()
	
	if self:IsDestroyed() or not self:GetEngineActive() then
		self:StopEngine()
		
		return
	end
	
	PhysObj:ApplyForceOffset( self:GetForward() * Power * FrameTime(),  self:GetRotorPos() )
	
end

function ENT:HandleActive()
	local Pod = self:GetDriverSeat()
	
	if not IsValid( Pod ) then
		self:SetActive( false )
		return
	end
	
	local Driver = Pod:GetDriver()
	
	if Driver ~= self:GetDriver() then
		if IsValid( self:GetDriver() ) then
			self:GetDriver():SetNoDraw( false )
		end
		if IsValid( Driver ) then
			Driver:SetNoDraw( true )
		end
		
		self:SetDriver( Driver )
		self:SetActive( IsValid( Driver ) )
		
		if self:GetActive() then
			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:InitWheels()
	local PObj = self:GetPhysicsObject()
	
	if IsValid( PObj ) then 
		PObj:EnableMotion( true )
	end
end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
			Fire2 = Driver:KeyDown( IN_ATTACK2 )
		end
	end
	
	if Fire1 then
		self:PrimaryAttack()
	end
	
	if Fire2 then
		self:SecondaryAttack()
	end
end

function ENT:OnEngineStarted()
	self:PlayAnimation( "takeoff" )
end

function ENT:OnEngineStopped()
	if not self:IsDestroyed() then
		self:PlayAnimation( "landing" )
	end
end
