--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")


function ENT:RunOnSpawn()
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.008 )
	
	self.MirrorPrimary = not self.MirrorPrimary
	
	local Mirror = self.MirrorPrimary and -1 or 1
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld( Vector(136.19,74.97 * Mirror,53.7) )
	bullet.Dir 	= self:LocalToWorldAngles( Angle(0,-0.6 * Mirror,0) ):Forward()
	bullet.Spread 	= Vector( 0.018,  0.018, 0 )
	bullet.Tracer	= 3
	bullet.TracerName	= "lfs_tracer_white"
	bullet.Force	= 100
	bullet.HullSize 	= 10
	bullet.Damage	= 13
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

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:SecondaryAttack()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
		end
	end
	
	if Fire1 then
		self:PrimaryAttack()
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
	self:EmitSound( "lfs/spitfire/start.wav" )
end

function ENT:OnEngineStopped()
	self:EmitSound( "lfs/spitfire/stop.wav" )
end

function ENT:OnLandingGearToggled( bOn )
	self:EmitSound( "lfs/bf109/gear.wav" )
end
