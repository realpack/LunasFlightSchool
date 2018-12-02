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
	local AllSents = scripted_ents.GetList() 
	local SpawnOptions = {}
	
	for _, v in pairs( AllSents ) do
		if v and istable( v.t ) then
			if v.t.Spawnable then
				if v.t.Base and string.StartWith( v.t.Base:lower(), "lunasflightschool_basescript" ) then
					if v.t.Category and v.t.PrintName then
						local nicename = v.t.Category.." "..v.t.PrintName
						if not table.HasValue( SpawnOptions, nicename ) then
							SpawnOptions[nicename] = v.t.ClassName
						end
					end
				end
			end
		end
	end
	
	self:NetworkVar( "String",0, "Type",	{ KeyName = "Vehicle Type",Edit = { type = "Combo",	order = 1,values = SpawnOptions,category = "Options"} } )
	self:NetworkVar( "Bool",1, "AutoTeam",{ KeyName = "AI Auto Team",Edit = { type = "Boolean",	order = 2,	category = "Options"} } )
	self:NetworkVar( "Int",2, "TeamOverride", { KeyName = "AI Team", Edit = { type = "Int", order = 3,min = 0, max = 2, category = "Options"} } )
	self:NetworkVar( "Int",3, "RespawnTime", { KeyName = "spawntime", Edit = { type = "Int", order = 3,min = 1, max = 120, category = "Options"} } )
	
	if SERVER then
		self:NetworkVarNotify( "Type", self.OnTypeChanged )
		
		self:SetAutoTeam( true )
		self:SetRespawnTime( 2 )
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
	end

	function ENT:Think()
		if self.ShouldSpawn then
			if self.NextSpawn < CurTime() then
				
				self.ShouldSpawn = false
				
				local pos = self:LocalToWorld( Vector( 0, 500, 150 ) )
				local ang = self:LocalToWorldAngles( Angle( 0, -90, 0 ) )
				
				local Type = self:GetType()
				
				if not IsValid( self.spawnedvehicle ) and Type ~= "" then
					self.spawnedvehicle = ents.Create( Type )
					
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
			if not self.spawnedvehicle or not IsValid( self.spawnedvehicle ) then
				self.ShouldSpawn = true
				self.NextSpawn = CurTime() + self:GetRespawnTime()
			end
		end
		
		self:NextThink( CurTime() )
		
		return true
	end
end