--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile()

ENT.Type            = "anim"

if CLIENT then
	function ENT:Initialize()
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetPos() )
		util.Effect( "lfs_explosion", effectdata )
	end
	
	function ENT:OnRemove()
	end
	
	function ENT:Draw()
	end
end

if SERVER then
	function ENT:Initialize()
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow( false ) 
		
		local gibs = {
			"models/XQM/wingpiece2.mdl",
			"models/XQM/wingpiece2.mdl",
			"models/XQM/jetwing2medium.mdl",
			"models/XQM/jetwing2medium.mdl",
			"models/props_phx/misc/propeller3x_small.mdl",
			"models/props_c17/TrapPropeller_Engine.mdl",
			"models/props_junk/Shoe001a.mdl",
			"models/XQM/jetbody2fuselage.mdl",
			"models/XQM/jettailpiece1medium.mdl",
			"models/XQM/pistontype1huge.mdl",
		}
		
		self.GibModels = istable( self.GibModels ) and self.GibModels or gibs
		
		self.Gibs = {}
		self.DieTime = CurTime() + 5
		
		for _, v in pairs( self.GibModels ) do
			local ent = ents.Create( "prop_physics" )
			
			if IsValid( ent ) then
				table.insert( self.Gibs, ent ) 
				
				ent:SetPos( self:GetPos() + VectorRand() * 100 )
				ent:SetAngles( self:LocalToWorldAngles( VectorRand():Angle() ) )
				ent:SetModel( v )
				ent:Spawn()
				ent:Activate()
				ent:SetMaterial( "models/player/player_chrome1" )
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
				ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
				
				local PhysObj = ent:GetPhysicsObject()
				if IsValid( PhysObj ) then
					PhysObj:SetVelocityInstantaneous( VectorRand() * 1000 )
					PhysObj:AddAngleVelocity( VectorRand() * 500 ) 
					PhysObj:EnableDrag( false ) 
				end
				
				ent.particleeffect = ents.Create( "info_particle_system" )
				ent.particleeffect:SetKeyValue( "effect_name" , "fire_small_03")
				ent.particleeffect:SetKeyValue( "start_active" , 1)
				ent.particleeffect:SetOwner( ent )
				ent.particleeffect:SetPos( ent:GetPos() )
				ent.particleeffect:SetAngles( ent:GetAngles() )
				ent.particleeffect:SetParent( ent )
				ent.particleeffect:Spawn()
				ent.particleeffect:Activate()
				ent.particleeffect:Fire( "Stop", "", math.random(0.5,3) )
				
				timer.Simple( 4.5 + math.Rand(0,0.5), function()
					if not IsValid( ent ) then return end
					ent:SetRenderFX( kRenderFxFadeFast  ) 
				end)
			end
		end
	end

	function ENT:Think()
		if self.DieTime < CurTime() then
			self:Remove()
		end
		
		self:NextThink( CurTime() )
		return true
	end

	function ENT:OnRemove()
		if istable( self.Gibs ) then
			for _, v in pairs( self.Gibs ) do
				if IsValid( v ) then
					v:Remove()
				end
			end
		end
	end

	function ENT:OnTakeDamage( dmginfo )
	end

	function ENT:PhysicsCollide( data, physobj )
	end
end