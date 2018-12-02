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
	local Pod = self:GetDriverSeat()
	local Driver = self:GetDriver()
	
	if not IsValid( Pod ) or not IsValid( Driver ) then return end
	
	local startpos =  self:GetRotorPos()
	local tr = util.TraceHull( {
		start = startpos,
		endpos = (startpos + Pod:WorldToLocalAngles( Driver:EyeAngles() ):Forward() * 50000),
		mins = Vector( -40, -40, -40 ),
		maxs = Vector( 40, 40, 40 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )
	
	local ID = self:LookupAttachment( "muzzle" )
	local Attachment = self:GetAttachment( ID )
	
	if not Attachment then return end
	
	local Aimang = (tr.HitPos - Attachment.Pos):Angle()
	local Angles = self:WorldToLocalAngles( Aimang )
	Angles:Normalize()
	
	local Rate = 3
	self.sm_pp_yaw = self.sm_pp_yaw and (self.sm_pp_yaw + math.Clamp(Angles.y - self.sm_pp_yaw,-Rate,Rate) ) or 0
	self.sm_pp_pitch = self.sm_pp_pitch and ( self.sm_pp_pitch + math.Clamp(Angles.p - self.sm_pp_pitch,-Rate,Rate) ) or 0
	
	self:SetPoseParameter("weapon_yaw", self.sm_pp_yaw )
	self:SetPoseParameter("weapon_pitch", -self.sm_pp_pitch )
	
	self.StartPos = Attachment.Pos
	self.AimDir = Attachment.Ang
	self.MuzzleID = ID
end

function ENT:RunOnSpawn()
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.03 )
	
	self.charge = self.charge - 0.75
	
	if self.charge <= 0 then
		self:EmitSound("weapons/airboat/airboat_gun_energy"..math.random(1,2)..".wav")
	end
	
	if not isvector( self.StartPos ) or not isangle( self.AimDir ) or not isnumber( self.MuzzleID ) then return end
	
	local effectdata = EffectData()
		effectdata:SetOrigin( self.StartPos )
		effectdata:SetAngles( self.AimDir )
		effectdata:SetEntity( self )
		effectdata:SetAttachment( self.MuzzleID )
		effectdata:SetScale( 1 )
	util.Effect( "AirboatMuzzleFlash", effectdata, true, true )
	
	local bullet = {}
		bullet.Num 			= 1
		bullet.Src 			= self.StartPos
		bullet.Dir 			= self.AimDir:Forward()
		bullet.Spread 		= Vector(0.04,0.04,0)
		bullet.Tracer		= 2
		bullet.TracerName 	= "AirboatGunHeavyTracer"
		bullet.Force		= 12
		bullet.Damage		= 25
		bullet.HullSize		= 30
		bullet.IgnoreEntity 	= self
		bullet.DisableOverride = true
		bullet.Callback = function(att, tr, dmginfo)
			dmginfo:SetDamageType(DMG_AIRBOAT)
			
			local effectdata = EffectData()
				effectdata:SetOrigin(  tr.HitPos + tr.HitNormal )
				effectdata:SetNormal( tr.HitNormal )
				effectdata:SetRadius( 8 )
			util.Effect( "cball_bounce", effectdata, true, true )
		end
		bullet.Attacker 	= self:GetDriver()
	self:FireBullets( bullet )
	
	self:SetAmmoPrimary( math.max( self.charge, 0 ) )
end

function ENT:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	
	self:SetNextSecondary( 0.2 )
	
	self:EmitSound("npc/waste_scanner/grenade_fire.wav")
	
	local startpos =  self:GetRotorPos()
	local tr = util.TraceHull( {
		start = startpos,
		endpos = (startpos + self:GetForward() * 50000),
		mins = Vector( -40, -40, -40 ),
		maxs = Vector( 40, 40, 40 ),
		filter = function( e )
			local collide = e ~= self
			return collide
		end
	} )

	self.FireLeft = not self.FireLeft
	
	local ent = ents.Create( "lunasflightschool_missile" )
	local Pos = self:LocalToWorld( Vector(17.36,50.89 * (self.FireLeft and 1 or -1),-59.39) )
	ent:SetPos( Pos )
	ent:SetAngles( (tr.HitPos - Pos):Angle() )
	ent:Spawn()
	ent:Activate()
	ent:SetAttacker( self:GetDriver() )
	ent:SetInflictor( self )
	ent:SetStartVelocity( self:GetVelocity():Length() )
	
	if tr.Hit then
		local Target = tr.Entity
		if IsValid( Target ) then
			if Target:GetClass():lower() ~= "lunasflightschool_missile" then
				ent:SetLockOn( Target )
				ent:SetStartVelocity( 0 )
			end
		end
	end
	
	constraint.NoCollide( ent, self, 0, 0 ) 
	
	self:TakeSecondaryAmmo()
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:OnEngineStarted()
	self:PlayAnimation( "idle" )
end

function ENT:OnEngineStopped()
	self:PlayAnimation( "idle", 0 )
end

function ENT:PlayAnimation( animation, playbackrate )
	playbackrate = playbackrate or 1
	local sequence = self:LookupSequence( animation )
	
	self:ResetSequence( sequence )
	self:SetPlaybackRate( playbackrate ) 
	self:SetSequence( sequence )
end

function ENT:OnLandingGearToggled( bOn )
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

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	local Fire1 = false
	local Fire2 = false
	
	if IsValid( Driver ) then
		Fire1 = Driver:KeyDown( IN_ATTACK )
		
		if self:GetAmmoSecondary() > 0 then
			Fire2 = Driver:KeyDown( IN_ATTACK2 )
		end
	end

	self.charge = self.charge or 0
	if self.charging then
		self.charge = math.min(self.charge + FrameTime() * 60,self:GetMaxAmmoPrimary())
		self:SetAmmoPrimary( math.max( self.charge, 0 ) )
		
		if self.charge >= self:GetMaxAmmoPrimary() or not Fire1 then
			self.charging = false
			
			if self.snd_chrg then
				self.snd_chrg:Stop()
				self.snd_chrg = nil
			end
		end
	end
	
	if Fire1 ~= self.OldKeyAttack then
		self.OldKeyAttack = Fire1
		if Fire1 then
			if not self.charging then
				self.snd_chrg = CreateSound( self, "NPC_AttackHelicopter.ChargeGun" )
				self.snd_chrg:Play()
				
				self.charging = true
			end
		end
	end
	
	local fire = Fire1 and self.charge > 0 and not self.charging
	
	if fire then
		self:PrimaryAttack()
	else
		if not self.charging then
			self.charge = math.max(self.charge - FrameTime() * 120,0)
			self:SetAmmoPrimary( math.max( self.charge, 0 ) )
		end
	end
	
	if self.OldFire2 ~= Fire2 then
		if Fire2 then
			self:SecondaryAttack()
		end
		self.OldFire2 = Fire2
	end
	
	self.OldFire = self.OldFire or false
	if self.OldFire ~= fire then
		self.OldFire = fire
		if fire then
			self.wpn = CreateSound( self, "NPC_AttackHelicopter.FireGun" )
			self.wpn:Play()
			self:CallOnRemove( "stopmesounds", function( vehicle )
				if vehicle.wpn then
					vehicle.wpn:Stop()
				end
			end)
		else
			self:EmitSound("weapons/airboat/airboat_gun_energy"..math.random(1,2)..".wav")
			if self.wpn then
				self.wpn:Stop()
				self.wpn = nil
			end
		end
	end
end

function ENT:GetMissileOffset()
	return Vector(0,20,0)
end