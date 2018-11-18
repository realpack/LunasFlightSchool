AddCSLuaFile()

ENT.Type            = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool",0, "Disabled" )
	self:NetworkVar( "Bool",1, "CleanMissile" )
	self:NetworkVar( "Entity",0, "Attacker" )
	self:NetworkVar( "Entity",1, "Inflictor" )
	self:NetworkVar( "Entity",2, "LockOn" )
	self:NetworkVar( "Float",0, "StartVelocity" )
end

if SERVER then
	function ENT:SpawnFunction( ply, tr, ClassName )

		if not tr.Hit then return end

		local ent = ents.Create( ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 20 )
		ent:Spawn()
		ent:Activate()

		return ent

	end

	function ENT:BlindFire()
		if self:GetDisabled() then return end
		
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			pObj:SetVelocityInstantaneous( self:GetForward() * (self:GetStartVelocity() + 3000) )
		end
	end
	
	function ENT:FollowTarget( followent )
		local speed = (self:GetStartVelocity() + 3000)
		local turnrate = 30
		local pos = followent:LocalToWorld( followent:OBBCenter() )  + followent:GetVelocity() * 0.25
		
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			if not self:GetDisabled() then
				local targetdir = (pos - self:GetPos()):GetNormalized()
				
				local AF = self:WorldToLocalAngles( targetdir:Angle() )
				AF.p = math.Clamp( AF.p * 400,-turnrate,turnrate )
				AF.y = math.Clamp( AF.y * 400,-turnrate,turnrate )
				AF.r = math.Clamp( AF.r * 400,-turnrate,turnrate )
				
				local AVel = pObj:GetAngleVelocity()
				pObj:AddAngleVelocity( Vector(AF.r,AF.p,AF.y) - AVel ) 
				
				pObj:SetVelocityInstantaneous( self:GetForward() * speed )
			end
		end
	end

	function ENT:Initialize()	
		self:SetModel( "models/weapons/w_missile_launch.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetRenderMode( RENDERMODE_TRANSALPHA )
		self:PhysWake()
		local pObj = self:GetPhysicsObject()
		
		if IsValid( pObj ) then
			pObj:EnableGravity( false ) 
			pObj:SetMass( 1 ) 
		end
		
		self.SpawnTime = CurTime()
	end

	function ENT:Think()	
		local curtime = CurTime()
		self:NextThink( curtime )
		
		if IsValid( self:GetLockOn() ) then
			self:FollowTarget( self:GetLockOn() )
		else
			self:BlindFire()
		end
		
		if self.MarkForRemove then
			self:Remove()
		end
		
		if self.Explode then
			local Inflictor = self:GetInflictor()
			local Attacker = self:GetAttacker()
			util.BlastDamage( IsValid( Inflictor ) and Inflictor or Entity(0), IsValid( Attacker ) and Attacker or Entity(0), self:GetPos(),500,200)
			
			self:Remove()
		end
		
		if (self.SpawnTime + 12) < curtime then
			self:Remove()
		end
		
		return true
	end

	function ENT:PhysicsCollide( data )
		if self:GetDisabled() then
			self.MarkForRemove = true
		else
			self.Explode = true
		end
	end

	function ENT:OnTakeDamage( dmginfo )	
		if dmginfo:GetDamageType() ~= DMG_AIRBOAT then return end
		
		if not self:GetDisabled() then
			self:SetDisabled( true )
			
			local pObj = self:GetPhysicsObject()
			
			if IsValid( pObj ) then
				pObj:EnableGravity( true )
				self:PhysWake()
				self:EmitSound( "Missile.ShotDown" )
			end
		end
	end
else
	function ENT:Initialize()	
		self.Emitter = ParticleEmitter( self:GetPos(), false )
		
		self.Materials = {
			"particle/smokesprites_0001",
			"particle/smokesprites_0002",
			"particle/smokesprites_0003",
			"particle/smokesprites_0004",
			"particle/smokesprites_0005",
			"particle/smokesprites_0006",
			"particle/smokesprites_0007",
			"particle/smokesprites_0008",
			"particle/smokesprites_0009",
			"particle/smokesprites_0010",
			"particle/smokesprites_0011",
			"particle/smokesprites_0012",
			"particle/smokesprites_0013",
			"particle/smokesprites_0014",
			"particle/smokesprites_0015",
			"particle/smokesprites_0016"
		}
		
		self.snd = CreateSound(self, "weapons/flaregun/burn.wav")
		self.snd:Play()
	end

	local mat = Material( "sprites/light_glow02_add" )
	function ENT:Draw()
		self:DrawModel()
		
		if self.Disabled then return end
		
		local pos = self:GetPos()


		local r = 255
		local g = 100
		local b = 0
		
		render.SetMaterial( mat )
		if self:GetCleanMissile() then
			r = 0
			g = 127
			b = 255
			
			for i =0,10 do
				local Size = (10 - i) * 25.6
				render.DrawSprite( pos - self:GetForward() * i * 5, Size, Size, Color( r, g, b, 255 ) )
			end
		end
		
		render.DrawSprite( pos, 256, 256, Color( r, g, b, 255 ) )
	end

	function ENT:Think()
		local curtime = CurTime()
		
		self.NextFX = self.NextFX or 0
		
		if self.NextFX < curtime then
			self.NextFX = curtime + 0.02
			
			local pos = self:LocalToWorld( Vector(-8,0,0) )
			
			if self:GetDisabled() then 
				if not self.Disabled then
					self.Disabled = true
					
					if self.snd then
						self.snd:Stop()
					end
				end
				
				self:doFXbroken( pos )
				
				return
			end
			
			self:doFX( pos )
		end
		
		return true
	end

	function ENT:doFXbroken( pos )
		local emitter = self.Emitter
		if not emitter then return end
		
		local particle = emitter:Add( self.Materials[math.random(1, table.Count(self.Materials) )], pos )
		
		if particle then
			particle:SetGravity( Vector(0,0,100) + VectorRand() * 50 ) 
			particle:SetVelocity( -self:GetForward() * 500  )
			particle:SetAirResistance( 600 ) 
			particle:SetDieTime( math.Rand(4,6) )
			particle:SetStartAlpha( 150 )
			particle:SetStartSize( math.Rand(6,12) )
			particle:SetEndSize( math.Rand(40,90) )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 50,50,50 )
			particle:SetCollide( false )
		end

		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), self:GetPos() )
		if particle then
			particle:SetVelocity( -self:GetForward() * 500 + VectorRand() * 50 )
			particle:SetDieTime( 0.25 )
			particle:SetAirResistance( 600 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( math.Rand(25,40) )
			particle:SetEndSize( math.Rand(10,15) )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetCollide( false )
		end
	end

	function ENT:doFX( pos )
		local emitter = self.Emitter
		if not emitter then return end
	
		if not self:GetCleanMissile() then
			local particle = emitter:Add( self.Materials[math.random(1, table.Count(self.Materials) )], pos )
			
			if particle then
				particle:SetGravity( Vector(0,0,100) + VectorRand() * 50 ) 
				particle:SetVelocity( -self:GetForward() * 500  )
				particle:SetAirResistance( 600 ) 
				particle:SetDieTime( math.Rand(4,6) )
				particle:SetStartAlpha( 150 )
				particle:SetStartSize( math.Rand(6,12) )
				particle:SetEndSize( math.Rand(40,90) )
				particle:SetRoll( math.Rand( -1, 1 ) )
				particle:SetColor( 50,50,50 )
				particle:SetCollide( false )
			end
		end
		
		local particle = emitter:Add( "particles/flamelet"..math.random(1,5), pos )
		if particle then
			particle:SetVelocity( -self:GetForward() * 300 + self:GetVelocity())
			particle:SetDieTime( 0.1 )
			particle:SetAirResistance( 0 ) 
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 4 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 255,255,255 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			particle:SetCollide( false )
		end
	end

	function ENT:OnRemove()
		if self.snd then
			self.snd:Stop()
		end
		
		local Pos = self:GetPos()
		
		self:Explosion( Pos + self:GetVelocity() / 20 )
		
		local random = math.random(1,2)
		
		sound.Play( "Explo.ww2bomb", Pos, 95, 140, 1 )
		
		if self.Emitter then
			self.Emitter:Finish()
		end
	end

	function ENT:Explosion( pos )
		local emitter = self.Emitter
		if not emitter then return end
		
		for i = 0,60 do
			local particle = emitter:Add( self.Materials[math.random(1,table.Count( self.Materials ))], pos )
			
			if particle then
				particle:SetVelocity( VectorRand(-1,1) * 600 )
				particle:SetDieTime( math.Rand(4,6) )
				particle:SetAirResistance( math.Rand(200,600) ) 
				particle:SetStartAlpha( 255 )
				particle:SetStartSize( math.Rand(10,30) )
				particle:SetEndSize( math.Rand(80,120) )
				particle:SetRoll( math.Rand(-1,1) )
				particle:SetColor( 50,50,50 )
				particle:SetGravity( Vector( 0, 0, 100 ) )
				particle:SetCollide( false )
			end
		end
		
		for i = 0, 40 do
			local particle = emitter:Add( "sprites/flamelet"..math.random(1,5), pos )
			
			if particle then
				particle:SetVelocity( VectorRand(-1,1) * 500 )
				particle:SetDieTime( 0.14 )
				particle:SetStartAlpha( 255 )
				particle:SetStartSize( 10 )
				particle:SetEndSize( math.Rand(30,60) )
				particle:SetEndAlpha( 100 )
				particle:SetRoll( math.Rand( -1, 1 ) )
				particle:SetColor( 200,150,150 )
				particle:SetCollide( false )
			end
		end
		
		local dlight = DynamicLight( math.random(0,9999) )
		if dlight then
			dlight.pos = pos
			dlight.r = 255
			dlight.g = 180
			dlight.b = 100
			dlight.brightness = 8
			dlight.Decay = 2000
			dlight.Size = 200
			dlight.DieTime = CurTime() + 0.1
		end
	end
end