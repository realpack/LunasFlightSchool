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
	self:NetworkVar( "Bool",2, "AutoTeam",{ KeyName = "AI Auto Team",Edit = { type = "Boolean",	order = 3,	category = "Options"} } )
	self:NetworkVar( "Int",3, "TeamOverride", { KeyName = "AI Team", Edit = { type = "Int", order = 4,min = 0, max = 2, category = "Options"} } )
	self:NetworkVar( "Int",4, "RespawnTime", { KeyName = "spawntime", Edit = { type = "Int", order = 5,min = 1, max = 120, category = "Options"} } )
	self:NetworkVar( "Int",5, "Amount", { KeyName = "amount", Edit = { type = "Int", order = 6,min = 1, max = 10, category = "Options"} } )
	self:NetworkVar( "Int",6, "SpawnWithSkin", { KeyName = "spawnwithskin", Edit = { type = "Int", order = 7,min = 0, max = 16, category = "Options"} } )
	
	if SERVER then
		self:NetworkVarNotify( "Type", self.OnTypeChanged )
		
		self:SetAutoTeam( true )
		self:SetRespawnTime( 2 )
		self:SetAmount( 1 )
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
		self.spawnedvehicles = self.spawnedvehicles or {}
		
		if self.ShouldSpawn then
			if self.NextSpawn < CurTime() then
				
				self.ShouldSpawn = false
				
				local pos = self:LocalToWorld( Vector( 0, 500, 150 ) )
				local ang = self:LocalToWorldAngles( Angle( 0, -90, 0 ) )
				
				local Type = self:GetType()
				
				if Type ~= "" then
					local spawnedvehicle = ents.Create( Type )
					
					if IsValid( spawnedvehicle ) then
						spawnedvehicle:SetPos( pos )
						spawnedvehicle:SetAngles( ang )
						spawnedvehicle:Spawn()
						spawnedvehicle:Activate()
						spawnedvehicle:SetAI( true )
						spawnedvehicle:SetSkin( self:GetSpawnWithSkin() )
						
						if not self:GetAutoTeam() then
							spawnedvehicle:SetAITEAM( self:GetTeamOverride() )
						end
						
						local PhysObj = spawnedvehicle:GetPhysicsObject()
						
						if IsValid( PhysObj ) then
							PhysObj:SetVelocityInstantaneous( self:GetRight() * 1000 )
						end
						
						table.insert( self.spawnedvehicles, spawnedvehicle )
					end
				end
			end
		else
			local AmountSpawned = 0
			for k,v in pairs( self.spawnedvehicles ) do
				if IsValid( v ) then
					AmountSpawned = AmountSpawned + 1
				else
					self.spawnedvehicles[k] = nil
				end
			end
			
			if AmountSpawned < self:GetAmount() then
				self.ShouldSpawn = true
				self.NextSpawn = CurTime() + self:GetRespawnTime()
			end
		end
		
		self:NextThink( CurTime() )
		
		return true
	end
end

if CLIENT then
	local mat = Material( "sprites/light_glow02_add" )
	
	function ENT:Draw()
		self:DrawModel()
		
		if self:GetType() ~= "" then return end
		
		self.NextStep = self.NextStep or 0
		
		if self.NextStep < CurTime() then
			self.NextStep = CurTime() + 0.15
			
			self.PX = self.PX and self.PX + 125 or 0
			if self.PX > 1000 then self.PX = 0 end
		end
		
		render.SetMaterial( mat )
		render.DrawSprite( self:LocalToWorld( Vector(125,500 - self.PX,10) ), 32, 32, Color( 255, 255, 255, 255) )
		render.DrawSprite( self:LocalToWorld( Vector(-125,500 - self.PX,10) ), 32, 32, Color( 255, 255, 255, 255) )
		
		render.DrawSprite( self:LocalToWorld( Vector(125,500 - self.PX,10) ), 130, 130, Color( 0, 127, 255, 255) )
		render.DrawSprite( self:LocalToWorld( Vector(-125,500 - self.PX,10) ), 130, 130, Color( 0, 127, 255, 255) )
	end
end