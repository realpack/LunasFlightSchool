--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.003 )
	
	local fP = {
		Vector(141.83,-121.84,68.4),
		Vector(141.83,121.84,68.4),
		Vector(136.44,-128.69,68.49),
		Vector(136.44,128.69,68.49),
		Vector(129.23,-135.24,68.31),
		Vector(129.23,135.24,68.31),
		Vector(122.84,-142.46,68.32),
		Vector(122.84,142.46,68.32)
	}

	self.NumPrim = self.NumPrim and self.NumPrim + 1 or 1
	if self.NumPrim > 8 then self.NumPrim = 1 end
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld( fP[self.NumPrim] )
	bullet.Dir 	= self:LocalToWorldAngles( Angle(-0.5,(fP[self.NumPrim].y > 0 and -2 or 2),0) ):Forward()
	bullet.Spread 	= Vector( 0.015,  0.015, 0 )
	bullet.Tracer	= 3
	bullet.TracerName	= "lfs_tracer_green"
	bullet.Force	= 100
	bullet.HullSize 	= 10
	bullet.Damage	= 16
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
		
		if IsValid( tr.Entity ) then
			if tr.Entity.LFS then
				local effectdata = EffectData()
				effectdata:SetOrigin( tr.HitPos )
				effectdata:SetNormal( tr.HitNormal * 0.25 )
				effectdata:SetRadius( 2 )
				util.Effect( "cball_bounce", effectdata, true, true )
			end
		end
	end
	self:FireBullets( bullet )
	
	self:TakePrimaryAmmo()
end

function ENT:SecondaryAttack()
	if self:GetAI() then return end
	if not self:CanSecondaryAttack() then return end
	
	self:SetNextSecondary( 0.1 )

	self:TakeSecondaryAmmo()
	
	if istable( self.MissileEnts ) then
		local Missile = self.MissileEnts[ self:GetAmmoSecondary() + 1 ]
		Missile:EmitSound( "npc/waste_scanner/grenade_fire.wav" )
		if IsValid( Missile ) then
			local ent = ents.Create( "lunasflightschool_missile" )
			local mPos = Missile:GetPos()
			local Ang = self:WorldToLocal( mPos ).y > 0 and -1 or 1
			ent:SetPos( mPos )
			ent:SetAngles( self:LocalToWorldAngles( Angle(0,Ang,0) ) )
			ent:Spawn()
			ent:Activate()
			ent:SetAttacker( self:GetDriver() )
			ent:SetInflictor( self )
			ent:SetStartVelocity( self:GetVelocity():Length() )
			
			constraint.NoCollide( ent, self, 0, 0 ) 
			
			if IsValid( self.wheel_R ) then
				constraint.NoCollide( ent, self.wheel_R, 0, 0 ) 
			end
			if IsValid( self.wheel_L ) then
				constraint.NoCollide( ent, self.wheel_L, 0, 0 ) 
			end
		end
	end
end

function ENT:RunOnSpawn()
	if not self:GetAI() then
		self:SetBodygroup( 15, 1 )
	end
	
	if self.LandingGearUp then
		self:SetBodygroup( 13, 0 )
	else
		self:SetBodygroup( 13, 1 ) 
	end
	
	self:SetBodygroup( 23, 1 )
	
	self.MissileEnts = {}
	
	for k,v in pairs( self.MISSILES ) do
		for _,n in pairs( v ) do
			local Missile = ents.Create( "prop_dynamic" )
			Missile:SetModel( self.MISSILEMDL )
			Missile:SetPos( self:LocalToWorld( n ) )
			Missile:SetAngles( self:GetAngles() )
			Missile:SetMoveType( MOVETYPE_NONE )
			Missile:Spawn()
			Missile:Activate()
			Missile:SetNotSolid( true )
			Missile:DrawShadow( false )
			Missile:SetParent( self )
			
			table.insert( self.MissileEnts, Missile )
		end
	end
end

function ENT:CreateAI()
	self:SetBodygroup( 15, 0 ) 
end

function ENT:RemoveAI()
	self:SetBodygroup( 15, 1 ) 
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
	
	if istable( self.MissileEnts ) then
		for k, v in pairs( self.MissileEnts ) do
			if IsValid( v ) then
				if k > self:GetAmmoSecondary() then
					v:SetNoDraw( true )
				else
					v:SetNoDraw( false )
				end
			end
		end
	end
	
	if self.OldFire2 ~= Fire2 then
		if Fire2 then
			self:SecondaryAttack()
		end
		self.OldFire2 = Fire2
	end
	
	if self.OldFire ~= Fire1 then
		
		if Fire1 then
			self.wpn1 = CreateSound( self, "SPITFIRE_FIRE_LOOP" )
			self.wpn1:Play()
			self:CallOnRemove( "stopmesounds1", function( ent )
				if ent.wpn1 then
					ent.wpn1:Stop()
				end
			end)
		else
			if self.OldFire == true then
				if self.wpn1 then
					self.wpn1:Stop()
				end
				self.wpn1 = nil
					
				self:EmitSound( "SPITFIRE_FIRE_LASTSHOT" )
			end
		end
		
		self.OldFire = Fire1
	end
end

function ENT:OnEngineStarted()
	self:EmitSound( "lfs/cessna/start.wav" )
end

function ENT:OnEngineStopped()
	self:EmitSound( "lfs/cessna/stop.wav" )
end

function ENT:OnLandingGearToggled( bOn )
	self:EmitSound( "lfs/bf109/gear.wav" )

	if bOn then
		self:SetBodygroup( 13, 0 )
	else
		self:SetBodygroup( 13, 1 ) 
	end
end
