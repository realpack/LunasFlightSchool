--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )

	if not tr.Hit then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal * 15 )
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:Initialize()
	self:SetModel( self.MDL )
	
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	
	local PObj = self:GetPhysicsObject()
	
	if not IsValid( PObj ) then 
		self:Remove()
		
		print("LFS: missing model. Plane terminated.")
		
		return
	end
	
	PObj:EnableMotion( false )
	PObj:SetMass( self.Mass ) 
	PObj:SetDragCoefficient( self.Drag ) 
	
	self.LFSInertiaDefault = PObj:GetInertia()
	
	if not self:HandleActive() then -- add compatibility for old vehicles
		PObj:SetInertia( self.Inertia ) 
	end
	
	self:InitPod()
	self:InitWheels()
	self:RunOnSpawn()
end

function ENT:RunOnSpawn()
end

function ENT:CanSound()
	self.NextSound = self.NextSound or 0
	return self.NextSound < CurTime()
end

function ENT:DelayNextSound( fDelay )
	if not isnumber( fDelay ) then return end
	
	self.NextSound = CurTime() + fDelay
end

function ENT:SetNextPrimary( delay )
	self.NextPrimary = CurTime() + delay
end

function ENT:SetNextSecondary( delay )
	self.NextSecondary = CurTime() + delay
end

function ENT:CanPrimaryAttack()
	self.NextPrimary = self.NextPrimary or 0
	return self.NextPrimary < CurTime()
end

function ENT:CanSecondaryAttack()
	self.NextSecondary = self.NextSecondary or 0
	return self.NextSecondary < CurTime()
end

function ENT:TakePrimaryAmmo( amount )
	amount = amount or 1
	
	self:SetAmmoPrimary( math.max(self:GetAmmoPrimary() - amount,0) )
end

function ENT:TakeSecondaryAmmo( amount )
	amount = amount or 1
	
	self:SetAmmoSecondary( math.max(self:GetAmmoSecondary() - amount,0) )
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.1 )
	
	self:TakePrimaryAmmo()
end

function ENT:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	
	self:SetNextSecondary( 0.15 )
	
	self:TakeSecondaryAmmo()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
		end
		
		if self:GetAmmoSecondary() > 0 then
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

function ENT:OnTick()
end

function ENT:Think()
	
	self:HandleActive()
	self:HandleStart()
	self:HandleLandingGear()
	self:HandleWeapons()
	self:RunEngine()
	self:CalcFlight()
	self:PrepExplode()
	self:RechargeShield()
	self:OnTick()
	
	self:NextThink( CurTime() )
	
	return true
end

function ENT:CalcFlight()
	local MaxTurnSpeed = self:GetMaxTurnSpeed()
	local MaxPitch = MaxTurnSpeed.p
	local MaxYaw = MaxTurnSpeed.y
	local MaxRoll = MaxTurnSpeed.r
	
	local PhysObj = self:GetPhysicsObject()
	if not IsValid( PhysObj ) then return end
	
	local Pod = self:GetDriverSeat()
	if not IsValid( Pod ) then return end
	
	local Driver = Pod:GetDriver()
	
	local A = false
	local D = false
	local WingFinFadeOut = 1
	local RudderFadeOut = 1
	
	local LocalAngPitch = 0
	local LocalAngYaw = 0
	local LocalAngRoll = 0
	
	if IsValid( Driver ) then 
		local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
		
		if Driver:KeyDown( IN_WALK ) then
			if isangle( self.StoredEyeAngles ) then
				EyeAngles = self.StoredEyeAngles
			end
		else
			self.StoredEyeAngles = EyeAngles
		end
		
		local LocalAngles = self:WorldToLocalAngles( EyeAngles )
		
		if Driver:KeyDown( IN_SPEED ) then
			EyeAngles = self:GetAngles()
			
			self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)
			
			LocalAngles = Angle(-90,0,0)
		end
		
		LocalAngPitch = LocalAngles.p
		LocalAngYaw = LocalAngles.y
		LocalAngRoll = LocalAngles.r + math.cos(CurTime()) * 2
		
		local EyeAngForward = EyeAngles:Forward()
		local Forward = self:GetForward()
		
		WingFinFadeOut = math.max((90 - math.deg( math.acos( math.Clamp( Forward:Dot(EyeAngForward) ,-1,1) ) ) ) / 90,0)
		RudderFadeOut = math.max((60 - math.deg( math.acos( math.Clamp( Forward:Dot(EyeAngForward) ,-1,1) ) ) ) / 60,0)
		
		A = Driver:KeyDown( IN_MOVELEFT ) 
		D = Driver:KeyDown( IN_MOVERIGHT )
	else
		if self:GetAI() then
			local EyeAngles = self:RunAI()
			local LocalAngles = self:WorldToLocalAngles( EyeAngles )
			
			LocalAngPitch = LocalAngles.p
			LocalAngYaw = LocalAngles.y
			LocalAngRoll = LocalAngles.r
			
			local EyeAngForward = EyeAngles:Forward()
			
			WingFinFadeOut = math.max((90 - math.deg( math.acos(   math.Clamp( self:GetForward():Dot(EyeAngForward) ,-1,1) ) ) ) / 90,0)
			RudderFadeOut = math.max((60 - math.deg( math.acos(   math.Clamp( self:GetForward():Dot(EyeAngForward) ,-1,1) ) ) ) / 60,0)
		end
	end
	
	if IsValid( self.wheel_C_master ) then
		if isvector( self.WheelPos_L ) and isvector( self.WheelPos_R ) and isvector( self.WheelPos_C ) then
			local SteerMaster = self.wheel_C_master
			local smPObj = SteerMaster:GetPhysicsObject()
			
			if IsValid( smPObj ) then
				if smPObj:IsMotionEnabled() then
					smPObj:EnableMotion( false )
				end
			end
			
			local Mirror = ((self.WheelPos_L.x + self.WheelPos_R.x) * 0.5 > self.WheelPos_C.x) and -1 or 1
			
			self.wheel_C_master:SetAngles( self:LocalToWorldAngles( Angle(0,math.Clamp(LocalAngYaw * Mirror,-45,45),0) ) )
		end
	end

	local RollRate = math.min(self:GetVelocity():Length() / (self:GetMaxVelocity() * 0.5),1)
	RudderFadeOut = math.max(RudderFadeOut,1-RollRate)
	
	local Stability = self:GetStability()

	local ManualRoll = (D and MaxRoll or 0) - (A and MaxRoll or 0)
	
	local AutoRoll = (-LocalAngYaw * 22 * RollRate + LocalAngRoll * 3.5 * RudderFadeOut) * WingFinFadeOut
	
	local Roll = math.Clamp( (not A and not D) and AutoRoll or ManualRoll,-MaxRoll ,MaxRoll )
	local Yaw = math.Clamp(-LocalAngYaw * 80 * RudderFadeOut,-MaxYaw,MaxYaw)
	local Pitch = math.Clamp(-LocalAngPitch * 25,-MaxPitch,MaxPitch)
	
	local WingVel = self:GetWingVelocity()
	local ElevatorVel = self:GetElevatorVelocity()
	local RudderVel = self:GetRudderVelocity()
	
	local Mass = PhysObj:GetMass()
	
	self:ApplyAngForce( Angle(0,0,-self:GetAngVel().r + Roll * Stability) *  Mass * 500 * Stability )
	
	PhysObj:ApplyForceOffset( -self:GetWingUp() * WingVel *  Mass * Stability, self:GetWingPos() )
	
	PhysObj:ApplyForceOffset( -self:GetElevatorUp() * (ElevatorVel + Pitch * Stability) * Mass * Stability, self:GetElevatorPos() )
	
	PhysObj:ApplyForceOffset( -self:GetRudderUp() * (math.Clamp(RudderVel,-MaxYaw,MaxYaw) + Yaw * Stability) *  Mass * Stability, self:GetRudderPos() )
    
	local MaxAngle = 30
    
	self:SetRotPitch( (Pitch / MaxPitch) * MaxAngle )
	self:SetRotYaw( (Yaw / MaxYaw) * MaxAngle )
	self:SetRotRoll( (Roll / MaxRoll) * MaxAngle )
end

function ENT:HitGround()
	if not isvector( self.obbvc ) or not isnumber( self.obbvm ) then
		self.obbvc = self:OBBCenter() 
		self.obbvm = self:OBBMins().z
	end
	
	local tr = util.TraceLine( {
		start = self:LocalToWorld( self.obbvc ),
		endpos = self:LocalToWorld( self.obbvc + Vector(0,0,self.obbvm - 100) ),
		filter = function( ent ) 
			if ( ent == self ) then 
				return false
			end
		end
	} )
	
	return tr.Hit 
end

function ENT:RunEngine()
	local IdleRPM = self:GetIdleRPM()
	local MaxRPM =self:GetMaxRPM()
	local LimitRPM = self:GetLimitRPM()
	local MaxVelocity = self:GetMaxVelocity()
	
	self.TargetRPM = self.TargetRPM or 0
	
	if self:IsDestroyed() then
		self:StopEngine()
	end
	
	if self:GetEngineActive() then
		local Pod = self:GetDriverSeat()
		
		if not IsValid( Pod ) then return end
		
		local Driver = Pod:GetDriver()
		
		local RPMAdd = 0
		local KeyThrottle = false
		if IsValid( Driver ) then 
			KeyThrottle = Driver:KeyDown( IN_FORWARD )
			RPMAdd = ((KeyThrottle and 350 or 0) - (Driver:KeyDown( IN_BACK ) and 350 or 0)) * FrameTime()
		end
		
		self.TargetRPM = math.Clamp( self.TargetRPM + RPMAdd,IdleRPM,KeyThrottle and LimitRPM or MaxRPM)
	else
		self.TargetRPM = self.TargetRPM - math.Clamp(self.TargetRPM,-250,250)
	end
	
	self:SetRPM( self:GetRPM() + (self.TargetRPM - self:GetRPM()) * FrameTime() )
	
	local PhysObj = self:GetPhysicsObject()
	if not IsValid( PhysObj ) then return end
	
	local Throttle = self:GetRPM() / self:GetLimitRPM()
	
	local Power = math.max(MaxVelocity * Throttle - self:GetForwardVelocity(),0) / MaxVelocity * self:GetMaxThrust() * self:GetLimitRPM()
	
	PhysObj:ApplyForceOffset( self:GetForward() * Power * FrameTime(),  self:GetRotorPos() )
	
end

function ENT:HandleActive()
	local gPod = self:GetGunnerSeat()
	
	if IsValid( gPod ) then
		local Gunner = gPod:GetDriver()
		
		if Gunner ~= self:GetGunner() then
			self:SetGunner( Gunner )
			
			if IsValid( Gunner ) then
				Gunner:CrosshairEnable() 
			end
		end
	end
	
	local Pod = self:GetDriverSeat()
	
	if not IsValid( Pod ) then
		self:SetActive( false )
		return
	end
	
	local Driver = Pod:GetDriver()
	local Active = self:GetActive()
	
	if Driver ~= self:GetDriver() then
		if self.HideDriver then
			if IsValid( self:GetDriver() ) then
				self:GetDriver():SetNoDraw( false )
			end
			if IsValid( Driver ) then
				Driver:SetNoDraw( true )
			end
		end
		
		self:SetDriver( Driver )
		self:SetActive( IsValid( Driver ) )
		
		if Active then
			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
	
	local inea = Active or self:GetEngineActive() or self:GetStability() > 0.1
	if inea ~= self.oldlfsin then
		self.oldlfsin = inea
		local PObj = self:GetPhysicsObject()
		
		if inea then
			PObj:SetInertia( self.Inertia )
		else
			PObj:SetInertia( self.LFSInertiaDefault  )
		end
	end
	
	return true
end

function ENT:HandleStart()
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		local KeyReload = Driver:KeyDown( IN_RELOAD )
		
		if self.OldKeyReload ~= KeyReload then
			self.OldKeyReload = KeyReload
			if KeyReload then
				self:ToggleEngine()
			end
		end
	end
end

function ENT:HandleLandingGear()
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		local KeyJump = Driver:KeyDown( IN_JUMP )
		
		if self.OldKeyJump ~= KeyJump then
			self.OldKeyJump = KeyJump
			if KeyJump then
				self:ToggleLandingGear()
				self:PhysWake()
			end
		end
	end
	
	local TValAuto = (self:GetStability() > 0.3) and 0 or 1
	local TValManual = self.LandingGearUp and 0 or 1
	
	local TVal = self.WheelAutoRetract and TValAuto or TValManual
	local Speed = FrameTime()
	local Speed2 = Speed * math.abs( math.cos( math.rad( self:GetLGear() * 180 ) ) )
	
	self:SetLGear( self:GetLGear() + math.Clamp(TVal - self:GetLGear(),-Speed,Speed) )
	self:SetRGear( self:GetRGear() + math.Clamp(TVal - self:GetRGear(),-Speed2,Speed2) )
	
	if IsValid( self.wheel_R ) then
		local RWpObj = self.wheel_R:GetPhysicsObject()
		if IsValid( RWpObj ) then
			RWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetRGear() ^ 5 )
		end
	end
	
	if IsValid( self.wheel_L ) then
		local LWpObj = self.wheel_L:GetPhysicsObject()
		if IsValid( LWpObj ) then
			LWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetLGear() ^ 5 )
		end
	end
	
	if IsValid( self.wheel_C ) then
		local CWpObj = self.wheel_C:GetPhysicsObject()
		if IsValid( CWpObj ) then
			CWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetRGear() )
		end
	end
end

function ENT:ToggleEngine()
	if self:GetEngineActive() then
		self:StopEngine()
	else
		self:StartEngine()
	end
end

function ENT:IsEngineStartAllowed()
	local Driver = self:GetDriver()
	local Pod = self:GetDriverSeat()
	
	if self:GetAI() or not IsValid( Driver ) or not IsValid( Pod ) then return true end

	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	local AimDirToForwardDir = math.deg( math.acos( math.Clamp( self:GetForward():Dot( EyeAngles:Forward() ) ,-1,1) ) )
	
	local CanStart = AimDirToForwardDir < 10
	
	if not CanStart then
		net.Start( "lfs_failstartnotify" )
		net.Send( Driver )
	end
	
	return CanStart
end

function ENT:StartEngine()
	if self:GetEngineActive() or self:IsDestroyed() or self:InWater() or not self:IsEngineStartAllowed() or self:GetRotorDestroyed() then return end
	
	self:SetEngineActive( true )
	self:OnEngineStarted()
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end
	
	self:SetEngineActive( false )
	self:OnEngineStopped()
end

function ENT:ToggleLandingGear()
	self.LandingGearUp = not self.LandingGearUp
	
	self:OnLandingGearToggled( self.LandingGearUp )
end

function ENT:RaiseLandingGear()
	if not self.LandingGearUp then
		self.LandingGearUp = true
		
		self:OnLandingGearToggled( self.LandingGearUp )
	end
end

function ENT:OnRemove()
end

function ENT:OnEngineStarted()
end

function ENT:OnEngineStopped()
end

function ENT:OnLandingGearToggled( bOn )
end

function ENT:Use( ply )
	self:SetPassenger( ply )
end

function ENT:GetPassengerSeats()
	local pSeats = {}
	local DriverSeat = self:GetDriverSeat()
	
	for _, v in pairs( self:GetChildren() ) do
		if v:IsVehicle() and v ~= DriverSeat and v:GetClass():lower() == "prop_vehicle_prisoner_pod" then
			table.insert( pSeats, v )
		end
	end
	
	return pSeats
end

function ENT:SetPassenger( ply )
	if not IsValid( ply ) then return end
	
	local AI = self:GetAI()
	local DriverSeat = self:GetDriverSeat()
	
	if IsValid( DriverSeat ) and not IsValid( DriverSeat:GetDriver() ) and not ply:KeyDown( IN_WALK ) and not AI then
		ply:EnterVehicle( DriverSeat )
	else
		local Seat = NULL
		local Dist = 500000
		
		for _, v in pairs( self:GetPassengerSeats() ) do
			if IsValid( v ) and not IsValid( v:GetDriver() ) then
				local cDist = (v:GetPos() - ply:GetPos()):Length()
				
				if cDist < Dist then
					Seat = v
					Dist = cDist
				end
			end
		end
		
		if IsValid( Seat ) then
			ply:EnterVehicle( Seat )
		else
			if not IsValid( self:GetDriver() ) and not AI then
				ply:EnterVehicle( DriverSeat )
			end
		end
	end
end

function ENT:ConvTick()
	return FrameTime() * 66.66666
end

function ENT:IsBrokenFrameTime()
	if self.ftBork == nil then
		local FT = FrameTime()
		
		self.ftBork = (FT > 0.015 and FT < 0.015625) or (FT < (1 / 70) and FT > (1 / 67))
		
		if self.ftBork then
			print("[LFS] skipping FrameTime detected. Running on emergency-code. Please check your servers -tickrate setting!")
		end
	end
	
	return self.ftBork
end

function ENT:GetWingVelocity()
	local CurPos = self:GetWingPos()
	self.wpOld = self.wpOld or CurPos
	
	local Vel = (CurPos - self.wpOld) * 66.66666 / self:ConvTick()
	
	local VelForward = Vel:GetNormalized()

	local Up = self:GetWingUp()
	
	self.wpOld = CurPos
	
	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )

	local Fz = math.sin( Az ) * Vel:Length()
	
	if self:IsBrokenFrameTime() then -- !!!hack!!! some people run their servers on a what i call "broken" tickrate which skips one tick every second. This usually happens around the frametimes defined in this function
		self.smFzW = self.smFzW and (self.smFzW + (Fz - self.smFzW)) * FrameTime() * 40 or 0 -- by smoothing out the velocity we can avoid unwanted fluctuations
	
		return self.smFzW
	else
		return Fz
	end
end

function ENT:GetElevatorVelocity()
	local CurPos = self:GetElevatorPos()
	self.epOld = self.epOld or CurPos
	
	local Vel = (CurPos - self.epOld) * 66.66666 / self:ConvTick()
	local VelForward = Vel:GetNormalized()
	local Up = self:GetElevatorUp()
	
	self.epOld = CurPos

	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )
	local Fz = math.sin( Az ) * Vel:Length()
	
	if self:IsBrokenFrameTime() then -- !!!hack!!! some people run their servers on a what i call "broken" tickrate which skips one tick every second. This usually happens around the frametimes defined in this function
		self.smFzE = self.smFzE and (self.smFzE + (Fz - self.smFzE)) * FrameTime() * 40 or 0 -- by smoothing out the velocity we can avoid unwanted fluctuations
	
		return self.smFzE
	else
		return Fz
	end
end

function ENT:GetRudderVelocity()
	local CurPos = self:GetRudderPos()
	self.rpOld = self.rpOld or CurPos
	
	local Vel = (CurPos - self.rpOld) * 66.66666 / self:ConvTick()
	local VelForward = Vel:GetNormalized()
	local Up = self:GetRudderUp()
	
	self.rpOld = CurPos

	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )
	local Fz = math.sin( Az ) * Vel:Length()

	if self:IsBrokenFrameTime() then -- !!!hack!!! some people run their servers on a what i call "broken" tickrate which skips one tick every second. This usually happens around the frametimes defined in this function
		self.smFzR= self.smFzR and (self.smFzR + (Fz - self.smFzR)) * FrameTime() * 40 or 0 -- by smoothing out the velocity we can avoid unwanted fluctuations
	
		return self.smFzR
	else
		return Fz
	end
end

function ENT:InWater()
	local InWater = self:WaterLevel() > 2
	
	if InWater then
		self.nfwater = self.nfwater or 0
		
		if self.nfwater < CurTime() then
			self.nfwater = CurTime() + 0.02
			local PhysObj = self:GetPhysicsObject()
			if IsValid( PhysObj ) then
				PhysObj:ApplyForceCenter( -self:GetVelocity() * PhysObj:GetMass() * 0.1 )
			end
			self:ApplyAngForce( -self:GetAngVel() * PhysObj:GetMass() * 100 )
			
			if self:GetAI() then
				self:Destroy()
			end
			
			if self:GetEngineActive() then
				self:StopEngine()
			end
		end
	end
	
	return InWater
end

function ENT:IsSpaceShip()
	return isnumber( self.Stability )
end

function ENT:GetStability()
	self.MaxStability = self.MaxStability or 1
	
	local Stability = math.abs( math.Clamp( self:GetForwardVelocity() / self:GetMaxPerfVelocity(),-self.MaxStability,self.MaxStability ) )
	
	if self:IsSpaceShip() then
		Stability = self:IsDestroyed() and 0.1 or (self:GetEngineActive() and self.Stability or 0)
	end
	
	return self:InWater() and 0 or Stability
end

function ENT:GetForwardVelocity()
	local Velocity = self:GetVelocity()
	local VelForward = Velocity:GetNormalized()

	local Forward = self:GetForward()
	
	local Ax = math.acos( math.Clamp( Forward:Dot(VelForward) ,-1,1) )

	local Fx = math.cos( Ax ) * Velocity:Length()
	
	return Fx
end

function ENT:InitWheels()
	if isnumber( self.WheelMass ) and isnumber( self.WheelRadius ) then
		if isvector( self.WheelPos_L ) then
			local wheel_L = ents.Create( "prop_physics" )
		
			if IsValid( wheel_L ) then
				wheel_L:SetPos( self:LocalToWorld( self.WheelPos_L ) )
				wheel_L:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
				
				wheel_L:SetModel( "models/props_vehicles/tire001c_car.mdl" )
				wheel_L:Spawn()
				wheel_L:Activate()
				
				wheel_L:SetNoDraw( true )
				wheel_L:DrawShadow( false )
				wheel_L.DoNotDuplicate = true
				
				local radius = self.WheelRadius
				
				wheel_L:PhysicsInitSphere( radius, "jeeptire" )
				wheel_L:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
				
				local LWpObj = wheel_L:GetPhysicsObject()
				if not IsValid( LWpObj ) then
					self:Remove()
					
					print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
					return
				end
			
				LWpObj:EnableMotion(false)
				LWpObj:SetMass( self.WheelMass )
				
				self.wheel_L = wheel_L
				self:DeleteOnRemove( wheel_L )
				self:dOwner( wheel_L )
				
				constraint.Axis( wheel_L, self, 0, 0, LWpObj:GetMassCenter(), wheel_L:GetPos(), 0, 0, 50, 0, Vector(1,0,0) , false )
				constraint.NoCollide( wheel_L, self, 0, 0 ) 
				
				LWpObj:EnableMotion( true )
				LWpObj:EnableDrag( false ) 
				
			else
				self:Remove()
			
				print("LFS: Failed to initialize landing gear. Plane terminated.")
			end
		end
		
		if isvector( self.WheelPos_R ) then
			local wheel_R = ents.Create( "prop_physics" )
			
			if IsValid( wheel_R ) then
				wheel_R:SetPos( self:LocalToWorld(  self.WheelPos_R ) )
				wheel_R:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
				
				wheel_R:SetModel( "models/props_vehicles/tire001c_car.mdl" )
				wheel_R:Spawn()
				wheel_R:Activate()
				
				wheel_R:SetNoDraw( true )
				wheel_R:DrawShadow( false )
				wheel_R.DoNotDuplicate = true
				
				local radius = self.WheelRadius
				
				wheel_R:PhysicsInitSphere( radius, "jeeptire" )
				wheel_R:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
				
				local RWpObj = wheel_R:GetPhysicsObject()
				if not IsValid( RWpObj ) then
					self:Remove()
					
					print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
					return
				end
			
				RWpObj:EnableMotion(false)
				RWpObj:SetMass( self.WheelMass )
				
				self.wheel_R = wheel_R
				self:DeleteOnRemove( wheel_R )
				self:dOwner( wheel_R )
				
				constraint.Axis( wheel_R, self, 0, 0, RWpObj:GetMassCenter(), wheel_R:GetPos(), 0, 0, 50, 0, Vector(1,0,0) , false )
				constraint.NoCollide( wheel_R, self, 0, 0 ) 
				
				RWpObj:EnableMotion( true )
				RWpObj:EnableDrag( false ) 
			else
				self:Remove()
			
				print("LFS: Failed to initialize landing gear. Plane terminated.")
			end
		end
		
		if isvector( self.WheelPos_C ) then
			local SteerMaster = ents.Create( "prop_physics" )
			
			if IsValid( SteerMaster ) then
				SteerMaster:SetModel( "models/hunter/plates/plate025x025.mdl" )
				SteerMaster:SetPos( self:GetPos() )
				SteerMaster:SetAngles( Angle(0,90,0) )
				SteerMaster:Spawn()
				SteerMaster:Activate()
				
				local smPObj = SteerMaster:GetPhysicsObject()
				if IsValid( smPObj ) then
					smPObj:EnableMotion( false )
				end
				
				SteerMaster:SetOwner( self )
				SteerMaster:DrawShadow( false )
				SteerMaster:SetNotSolid( true )
				SteerMaster:SetNoDraw( true )
				SteerMaster.DoNotDuplicate = true
				self:DeleteOnRemove( SteerMaster )
				self:dOwner( SteerMaster )
				
				self.wheel_C_master = SteerMaster
				
				local wheel_C = ents.Create( "prop_physics" )
				
				if IsValid( wheel_C ) then
					wheel_C:SetPos( self:LocalToWorld( self.WheelPos_C ) )
					wheel_C:SetAngles( Angle(0,0,0) )
					
					wheel_C:SetModel( "models/props_vehicles/tire001c_car.mdl" )
					wheel_C:Spawn()
					wheel_C:Activate()
					
					wheel_C:SetNoDraw( true )
					wheel_C:DrawShadow( false )
					wheel_C.DoNotDuplicate = true
					
					local radius = self.WheelRadius
					
					wheel_C:PhysicsInitSphere( radius, "jeeptire" )
					wheel_C:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
					
					local CWpObj = wheel_C:GetPhysicsObject()
					if not IsValid( CWpObj ) then
						self:Remove()
						
						print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
						return
					end
				
					CWpObj:EnableMotion(false)
					CWpObj:SetMass( self.WheelMass )
					
					self.wheel_C = wheel_C
					self:DeleteOnRemove( wheel_C )
					self:dOwner( wheel_C )
					
					constraint.AdvBallsocket(wheel_C, SteerMaster,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -0.01, -0.01, 180, 0.01, 0.01, 0, 0, 0, 1, 0)
					constraint.AdvBallsocket(wheel_C,self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 0, 0)
					constraint.NoCollide( wheel_C, self, 0, 0 ) 
					
					CWpObj:EnableMotion( true )
					CWpObj:EnableDrag( false ) 
				end
			end
		end
	end
	
	local PObj = self:GetPhysicsObject()
	
	if IsValid( PObj ) then 
		PObj:EnableMotion( true )
	end
end

function ENT:InitPod()
	if IsValid( self:GetDriverSeat() ) then return end
	
	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )
	
	if not IsValid( Pod ) then
		self:Remove()
		
		print("LFS: Failed to create driverseat. Plane terminated.")
		
		return
	else
		self:SetDriverSeat( Pod )
		
		local DSPhys = Pod:GetPhysicsObject()
		
		Pod:SetMoveType( MOVETYPE_NONE )
		Pod:SetModel( "models/nova/airboat_seat.mdl" )
		Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
		Pod:SetKeyValue( "limitview", 0 )
		Pod:SetPos( self:LocalToWorld( self.SeatPos ) )
		Pod:SetAngles( self:LocalToWorldAngles( self.SeatAng ) )
		Pod:SetOwner( self )
		Pod:Spawn()
		Pod:Activate()
		Pod:SetParent( self )
		Pod:SetNotSolid( true )
		Pod:SetNoDraw( true )
		Pod:DrawShadow( false )
		Pod.DoNotDuplicate = true
		
		if IsValid( DSPhys ) then
			DSPhys:EnableDrag( false ) 
			DSPhys:EnableMotion( false )
			DSPhys:SetMass( 1 )
		end
		
		self:DeleteOnRemove( Pod )
		
		self:dOwner( Pod )
	end
end

function ENT:AddPassengerSeat( Pos, Ang )
	if not isvector( Pos ) or not isangle( Ang ) then return NULL end
	
	local Pod = ents.Create( "prop_vehicle_prisoner_pod" )
	
	if not IsValid( Pod ) then return NULL end

	Pod:SetMoveType( MOVETYPE_NONE )
	Pod:SetModel( "models/nova/airboat_seat.mdl" )
	Pod:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
	Pod:SetKeyValue( "limitview", 0 )
	Pod:SetPos( self:LocalToWorld( Pos ) )
	Pod:SetAngles( self:LocalToWorldAngles( Ang ) )
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
	
	return Pod
end

function ENT:ApplyAngForce( angForce )
	if self:IsDestroyed() then return end

	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then return end
	
	local up = self:GetUp()
	local left = self:GetRight() * -1
	local forward = self:GetForward()

	local pitch = up * (angForce.p * 0.5)
	phys:ApplyForceOffset( forward, pitch )
	phys:ApplyForceOffset( forward * -1, pitch * -1 )

	local yaw = forward * (angForce.y * 0.5)
	phys:ApplyForceOffset( left, yaw )
	phys:ApplyForceOffset( left * -1, yaw * -1 )

	local roll = left * (angForce.r * 0.5)
	phys:ApplyForceOffset( up, roll )
	phys:ApplyForceOffset( up * -1, roll * -1 )
end

function ENT:GetAngVel()
	local phys = self:GetPhysicsObject()
	if not IsValid( phys ) then return Angle(0,0,0) end
	
	local vec = phys:GetAngleVelocity()
	
	return Angle( vec.y, vec.z, vec.x )
end

function ENT:UpdateTransmitState() 
	return TRANSMIT_ALWAYS
end

function ENT:dOwner( eEnt )
	if not IsEntity( eEnt ) or not IsValid( eEnt ) then return end
	
	if not CPPI then return end
	
	local Owner = self:CPPIGetOwner( )
	if not IsEntity( Owner ) then return end
	
	if IsValid( Owner ) then
		Pod:CPPISetOwner( ply )
	end
end

function ENT:CanRechargeShield()
	self.NextShieldRecharge = self.NextShieldRecharge or 0
	return self.NextShieldRecharge < CurTime()
end

function ENT:SetNextShieldRecharge( nDelay )
	if not isnumber( nDelay ) then return end
	
	self.NextShieldRecharge = CurTime() + nDelay
end

function ENT:RechargeShield()
	local MaxShield = self:GetMaxShield()
	
	if MaxShield <= 0 then return end
	if not self:CanRechargeShield() then return end
	
	local Cur = self:GetShield()
	local Rate = FrameTime() * 30
	
	self:SetShield( Cur + math.Clamp(MaxShield - Cur,-Rate,Rate) )
end

function ENT:TakeShieldDamage( Damage )
	local Cur = self:GetShield()
	local New = math.Clamp( Cur - Damage , 0, self:GetMaxShield()  )
	
	self:SetShield( New )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
	
	local Damage = dmginfo:GetDamage()
	local CurHealth = self:GetHP()
	local NewHealth = math.Clamp( CurHealth - Damage , 0, self:GetMaxHP()  )
	local ShieldCanBlock = dmginfo:IsBulletDamage() or dmginfo:IsDamageType( DMG_AIRBOAT )
	
	if ShieldCanBlock then
		local dmgNormal = -dmginfo:GetDamageForce():GetNormalized() 
		
		self:SetNextShieldRecharge( 3 )
		
		if self:GetMaxShield() > 0 and self:GetShield() > 0 then
			dmginfo:SetDamagePosition( dmginfo:GetDamagePosition() + dmgNormal * 250 ) 
			
			net.Start("lfs_shieldhit")
				net.WriteVector( dmginfo:GetDamagePosition() )
			net.Broadcast()
			
			self:TakeShieldDamage( Damage )
		else
			local effectdata = EffectData()
				effectdata:SetOrigin( dmginfo:GetDamagePosition() )
				effectdata:SetNormal( dmgNormal )
			util.Effect( "MetalSpark", effectdata )
			
			self:SetHP( NewHealth )
		end
	else
		self:SetHP( NewHealth )
	end
	
	if NewHealth == 0 and not (self:GetShield() > Damage and ShieldCanBlock) then
		if not self:IsDestroyed() then
			self.FinalAttacker = dmginfo:GetAttacker() 
			self.FinalInflictor = dmginfo:GetInflictor()
			
			self:Destroy()
			
			self.MaxPerfVelocity = self.MaxPerfVelocity * 10
			
			self.particleeffect = ents.Create( "info_particle_system" )
			self.particleeffect:SetKeyValue( "effect_name" , "fire_large_01")
			self.particleeffect:SetKeyValue( "start_active" , 1)
			self.particleeffect:SetOwner( self )
			self.particleeffect:SetPos( self:LocalToWorld( self:GetPhysicsObject():GetMassCenter() ) )
			self.particleeffect:SetAngles( self:GetAngles() )
			self.particleeffect:Spawn()
			self.particleeffect:Activate()
			self.particleeffect:SetParent( self )
			
			if self:GetAI() then
				timer.Simple( math.Rand(0,8), function()
					if not IsValid( self ) then return end
					self:Explode()
				end)
			end
		end
	end
end

function ENT:PrepExplode()
	if self.MarkForDestruction then
		self:Explode()
	end
	
	if self:IsDestroyed() then
		if self:GetVelocity():Length() < 500 then
			self:Explode()
		end
	end
end

function ENT:Explode()
	if self.ExplodedAlready then return end
	
	self.ExplodedAlready = true
	
	local Driver = self:GetDriver()
	local Gunner = self:GetGunner()
	
	if IsValid( Driver ) then
		Driver:TakeDamage( 200, self.FinalAttacker or Entity(0), self.FinalInflictor or Entity(0) )
	end
	
	if IsValid( Gunner ) then
		Gunner:TakeDamage( 200, self.FinalAttacker or Entity(0), self.FinalInflictor or Entity(0) )
	end
	
	local ent = ents.Create( "lunasflightschool_destruction" )
	if IsValid( ent ) then
		ent:SetPos( self:GetPos() + Vector(0,0,100) )
		ent.GibModels = self.GibModels
		
		ent:Spawn()
		ent:Activate()
	end
	
	self:Remove()
end

function ENT:IsDestroyed()
	return self.Destroyed or false
end

function ENT:Destroy()
	self.Destroyed = true
	
	local PObj = self:GetPhysicsObject()
	if IsValid( PObj ) then
		PObj:SetDragCoefficient( -20 )
	end
end

function ENT:PhysicsCollide( data, physobj )
	if self:IsDestroyed() then
		self.MarkForDestruction = true
	end
	
	if data.Speed > 60 and data.DeltaTime > 0.2 then
		if data.Speed > 500 then
			self:EmitSound( "Airboat_impact_hard" )
			
			self:TakeDamage( 400, data.HitEntity, data.HitEntity )
		else
			self:EmitSound( "MetalVehicle.ImpactSoft" )
		end
	end
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:OnToggleAI( name, old, new)
	if new == old then return end
	
	if new == true then
		local Driver = self:GetDriver()
		
		if IsValid( Driver ) then
			Driver:ExitVehicle()
		end
		
		self:SetActive( true )
		self:StartEngine()
		self:CreateAI()
	else
		self:SetActive( false )
		self:StopEngine()
		self:RemoveAI()
	end
end

function ENT:AITargetInfront( ent, range )
	if not IsValid( ent ) then return false end
	if not range then range = 45 end
	
	local DirToTarget = (ent:GetPos() - self:GetPos()):GetNormalized()
	
	local InFront = math.deg( math.acos( math.Clamp( self:GetForward():Dot( DirToTarget ) ,-1,1) ) ) < range
	return InFront
end

function ENT:AIGetTarget()
	self.NextAICheck = self.NextAICheck or 0
	
	if self.NextAICheck > CurTime() then return self.LastTarget end
	
	self.NextAICheck = CurTime() + 2
	
	local players = player.GetAll()
	
	local ClosestTarget = NULL
	local TargetDistance = 60000
	
	local MyPos = self:GetPos()
	local MyTeam = self:GetAITEAM()
	
	if not simfphys.LFS.IgnorePlayers then
		for _, v in pairs( players ) do
			if IsValid( v ) then
				if v:Alive() then
					local Dist = (v:GetPos() - MyPos):Length()
					if Dist < TargetDistance then
						local Plane = v:lfsGetPlane()
						
						if IsValid( Plane ) then
							if Plane:IsLineOfSightClear( self ) and not Plane:IsDestroyed() and Plane ~= self then
								local HisTeam = Plane:GetAITEAM()
								if HisTeam ~= MyTeam or HisTeam == 0 then
									ClosestTarget = v
									TargetDistance = Dist
								end
							end
						else
							local HisTeam = v:lfsGetAITeam()
							if v:IsLineOfSightClear( self ) then
								if HisTeam ~= MyTeam or HisTeam == 0 then
									ClosestTarget = v
									TargetDistance = Dist
								end
							end
						end
					end
				end
			end
		end
	end
	
	self.FoundPlanes = simfphys.LFS:PlanesGetAll()
	
	for _, v in pairs( self.FoundPlanes ) do
		if IsValid( v ) and v ~= self and v.LFS then
			local Dist = (v:GetPos() - MyPos):Length()
			
			if Dist < TargetDistance and self:AITargetInfront( v, 100 ) then
				if v.IsDestroyed and not v:IsDestroyed() and v.GetAITEAM then
					local HisTeam = v:GetAITEAM()
					
					if HisTeam ~= self:GetAITEAM() or HisTeam == 0 then
						ClosestTarget = v
						TargetDistance = Dist
					end
				end
			end
		end
	end

	self.LastTarget = ClosestTarget
	
	return ClosestTarget
end

function ENT:RunAI()
	local RangerLength = 15000
	local mySpeed = self:GetVelocity():Length()
	local MinDist = 1500 + mySpeed
	local StartPos = self:GetPos()
	
	local TraceFilter = {self,self.wheel_L,self.wheel_R,self.wheel_C}
	
	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,20,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-20,0) ):Forward() * RangerLength } )
	
	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,65,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,-65,0) ):Forward() * RangerLength } )
	
	local FrontLeft3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,65,0) ):Forward() * RangerLength } )
	local FrontRight3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,-65,0) ):Forward() * RangerLength } )
	
	local FrontUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-20,0,0) ):Forward() * RangerLength } )
	local FrontDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(20,0,0) ):Forward() * RangerLength } )

	local Up = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetUp() * RangerLength } )
	local Down = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos - self:GetUp() * RangerLength } )
	
	local Down2 = util.TraceLine( { start = self:LocalToWorld( Vector(0,0,100) ), filter = TraceFilter, endpos = StartPos + Vector(0,0,-RangerLength) } )
	
	local cAvoid = Vector(0,0,0)
	if istable( self.FoundPlanes ) then
		local myRadius = self:BoundingRadius() 
		local myPos = self:GetPos()
		local myDir = self:GetForward()
		for _, v in pairs( self.FoundPlanes ) do
			if IsValid( v ) and v ~= self and v.LFS then
				local theirRadius = v:BoundingRadius() 
				local Sub = (myPos - v:GetPos())
				local Dir = Sub:GetNormalized()
				local Dist = Sub:Length()
				
				if Dist < (theirRadius + myRadius + 200) then
					if math.deg( math.acos( math.Clamp( myDir:Dot( -Dir ) ,-1,1) ) ) < 90 then
						cAvoid = cAvoid + Dir * (theirRadius + myRadius + 500)
					end
				end
			end
		end
	end
	
	local FLp = FrontLeft.HitPos + FrontLeft.HitNormal * MinDist + cAvoid * 8
	local FRp = FrontRight.HitPos + FrontRight.HitNormal * MinDist + cAvoid * 8
	
	local FL2p = FrontLeft2.HitPos + FrontLeft2.HitNormal * MinDist
	local FR2p = FrontRight2.HitPos + FrontRight2.HitNormal * MinDist
	
	local FL3p = FrontLeft3.HitPos + FrontLeft3.HitNormal * MinDist
	local FR3p = FrontRight3.HitPos + FrontRight3.HitNormal * MinDist
	
	local FUp = FrontUp.HitPos + FrontUp.HitNormal * MinDist
	local FDp = FrontDown.HitPos + FrontDown.HitNormal * MinDist
	
	local Up = Up.HitPos + Up.HitNormal * MinDist
	local Dp = Down.HitPos + Down.HitNormal * MinDist
	
	local TargetPos = (FLp+FRp+FL2p+FR2p+FL3p+FR3p+FUp+FDp+Up+Dp) / 10
	
	local alt = (self:GetPos() - Down2.HitPos):Length()
	
	if alt < 600 then 
		self.TargetRPM = self:GetMaxRPM()
		
		if self:GetStability() < 0.4 then
			self.TargetRPM = self:GetLimitRPM()
			TargetPos.z = self:GetPos().z + 2000
		end
	else
		if self:GetStability() < 0.4 then
			self.TargetRPM = self:GetMaxRPM()
			
			self.TargetRPM = self:GetLimitRPM()
			TargetPos.z = self:GetPos().z + 600
		else
			if alt > mySpeed then
				local Target = self:AIGetTarget()
				if IsValid( Target ) then
					if self:AITargetInfront( Target, 65 ) then
						TargetPos = Target:GetPos() + cAvoid * 8 + Target:GetVelocity() * math.abs(math.cos( CurTime() * 150 ) ) * 3
						
						local Throttle = (self:GetPos() - TargetPos):Length() / 8000 * self:GetMaxRPM()
						self.TargetRPM = math.Clamp( Throttle,self:GetIdleRPM(),self:GetMaxRPM())
						
						local startpos =  self:GetRotorPos()
						local tr = util.TraceHull( {
							start = startpos,
							endpos = (startpos + self:GetForward() * 50000),
							mins = Vector( -30, -30, -30 ),
							maxs = Vector( 30, 30, 30 ),
							filter = function( e )
								local collide = e ~= self
								return collide
							end
						} )
					
						local CanShoot = (IsValid( tr.Entity ) and tr.Entity.LFS and tr.Entity.GetAITEAM) and (tr.Entity:GetAITEAM() ~= self:GetAITEAM() or tr.Entity:GetAITEAM() == 0) or true
					
						if CanShoot then
							if self:AITargetInfront( Target, 15 ) then
								self:HandleWeapons( true )
								
								if self:AITargetInfront( Target, 10 ) then
									self:HandleWeapons( true, true )
								end
							end
						end
					else
						TargetPos = TargetPos + Target:GetPos() * 0.1
						
						self.TargetRPM = self:GetMaxRPM()
					end
				else
					self.TargetRPM = self:GetMaxRPM()
				end
			else
				self.TargetRPM = self:GetMaxRPM()
				TargetPos.z = self:GetPos().z + 2000
			end
		end
		self:RaiseLandingGear()
	end
	
	if self:IsDestroyed() or not self:GetEngineActive() then
		self.TargetRPM = 0
	end
	
	self.smTargetPos = self.smTargetPos and self.smTargetPos + (TargetPos - self.smTargetPos) * FrameTime() or self:GetPos()
	
	local TargetAng = (self.smTargetPos - self:GetPos()):GetNormalized():Angle()
	
	return TargetAng
end

function ENT:PlayAnimation( animation, playbackrate )
	playbackrate = playbackrate or 1
	
	local anims = string.Implode( ",", self:GetSequenceList() )
	
	if not animation or not string.match( string.lower(anims), string.lower( animation ), 1 ) then return end
	
	local sequence = self:LookupSequence( animation )
	
	self:ResetSequence( sequence )
	self:SetPlaybackRate( playbackrate )
	self:SetSequence( sequence )
end

function ENT:GetMissileOffset()
	return self:OBBCenter()
end
