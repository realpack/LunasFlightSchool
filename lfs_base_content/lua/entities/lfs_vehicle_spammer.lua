--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile()

ENT.Type            = "anim"

ENT.PrintName = "AI Vehicle Spammer"
ENT.Author = ""
ENT.Information = ""
ENT.Category = "[LFS]"

ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Int",0, "Type",	{ KeyName = "Vehicle Type",Edit = { type = "Int",	order = 1,min = 1, max = 8,	category = "Options"} } )
	self:NetworkVar( "Bool",1, "AutoTeam",{ KeyName = "AI Auto Team",Edit = { type = "Boolean",	order = 2,	category = "Options"} } )
	self:NetworkVar( "Int",2, "TeamOverride", { KeyName = "AI Team", Edit = { type = "Int", order = 3,min = 0, max = 2, category = "Options"} } )
	self:NetworkVar( "Int",3, "RespawnTime", { KeyName = "spawntime", Edit = { type = "Int", order = 3,min = 1, max = 120, category = "Options"} } )
	
	if SERVER then
		self:NetworkVarNotify( "Type", self.OnTypeChanged )
		
		self:SetAutoTeam( true )
		self:SetRespawnTime( 2 )
		self:SetType( 3 )
	end
end

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/props_phx/huge/road_medium.mdl" )
		
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		
		self.NextSpawn = 0
		
		self.aType = {
			[1] = "arc170",
			[2] = "bf109",
			[3] = "cessna",
			[4] = "n1starfighter",
			[5] = "p47d",
			[6] = "spitfire",
			[7] = "tridroid",
			[8] = "vulturedroid",
		}
	end

	function ENT:OnTypeChanged( name, old, new)
		if new == old then return end
		
		if self.GetCreator then
			local Spawner = self:GetCreator()
			if IsValid( Spawner ) and Spawner:IsPlayer() then
				if istable( self.aType ) then
					local Type = self.aType[ new ]
					
					if isstring( Type ) then
						Spawner:PrintMessage( HUD_PRINTTALK, "Next Vehicle: "..self.aType[ new ] )
					end
				end
			end
		end
	end

	function ENT:Think()
		if self.ShouldSpawn then
			if self.NextSpawn < CurTime() then
				
				self.ShouldSpawn = false
				
				local pos = self:LocalToWorld( Vector( 0, 500, 150 ) )
				local ang = self:LocalToWorldAngles( Angle( 0, -90, 0 ) )

				local Type = self.aType[ self:GetType() ]
				
				if not IsValid( self.spawnedvehicle ) and isstring( Type ) then
					self.spawnedvehicle = ents.Create( "lunasflightschool_"..Type )
					
					if IsValid( self.spawnedvehicle ) then
						self.spawnedvehicle:SetPos( pos )
						self.spawnedvehicle:SetAngles( ang )
						self.spawnedvehicle:Spawn()
						self.spawnedvehicle:Activate()
						self.spawnedvehicle:SetAI( true )
						
						if not self:GetAutoTeam() then
							self.spawnedvehicle:SetAITEAM( self:GetTeamOverride() )
						end
						
						local PhysObj = self.spawnedvehicle:GetPhysicsObject()
						
						if IsValid( PhysObj ) then
							PhysObj:SetVelocityInstantaneous( self:GetRight() * 1000 )
						end
					end
				end
			end
		else
			if not self.spawnedvehicle or not IsValid( self.spawnedvehicle ) and istable( self.aType ) then
				self.ShouldSpawn = true
				self.NextSpawn = CurTime() + self:GetRespawnTime()
			end
		end
		
		self:NextThink( CurTime() )
		
		return true
	end
end