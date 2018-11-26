-- YOU CAN EDIT AND REUPLOAD THIS FILE. 
-- HOWEVER MAKE SURE TO RENAME THE FOLDER TO AVOID CONFLICTS

include("shared.lua")

function ENT:LFSCalcViewFirstPerson( view ) -- modify first person camera view here
	--[[
	local ply = LocalPlayer()
	if ply == self:GetDriver() then
		-- driver view
	elseif ply == self:GetGunner() then
		-- gunner view
	else
		-- everyone elses view
	end
	]]--
	
	return view
end

function ENT:LFSCalcViewThirdPerson( view ) -- modify third person camera view here
	return view
end

function ENT:CalcEngineSound( RPM, Pitch, Doppler )
	if self.ENG then
		self.ENG:ChangePitch(  math.Clamp( 60 + Pitch * 40 + Doppler,0,255) )
		self.ENG:ChangeVolume( math.Clamp( Pitch, 0.5,1) )
	end
end

function ENT:EngineActiveChanged( bActive )
	if bActive then
		self.ENG = CreateSound( self, "vehicles/airboat/fan_blade_fullthrottle_loop1.wav" )
		self.ENG:PlayEx(0,0)
	else
		self:SoundStop()
	end
end

function ENT:OnRemove()
	self:SoundStop()
	
	if IsValid( self.TheRotor ) then
		self.TheRotor:Remove()
	end
	
	if IsValid( self.TheLandingGear ) then
		self.TheLandingGear:Remove()
	end
end

function ENT:SoundStop()
	if self.ENG then
		self.ENG:Stop()
	end
end

function ENT:AnimFins()
	--[[ function gets called each frame by the base script. you can do whatever you want here ]]--
end

function ENT:AnimRotor()
	if not IsValid( self.TheRotor ) then -- spawn the rotor for all clients that dont have one
		local Rotor = ents.CreateClientProp()
		Rotor:SetPos( self:GetRotorPos() )
		Rotor:SetAngles( self:LocalToWorldAngles( Angle(90,0,0) ) )
		Rotor:SetModel( "models/XQM/propeller1big.mdl" )
		Rotor:SetParent( self )
		Rotor:Spawn()
		
		self.TheRotor = Rotor
	end
	
	local RPM = self:GetRPM() * 2 -- spin twice as fast
	self.RPM = self.RPM and (self.RPM + RPM * FrameTime()) or 0
	
	local Rot = Angle(0,0,-self.RPM)
	Rot:Normalize() 
	
	self.TheRotor:SetAngles( self:LocalToWorldAngles( Rot ) )
end

function ENT:AnimCabin()
	--[[ function gets called each frame by the base script. you can do whatever you want here ]]--
end

function ENT:AnimLandingGear()
	if not IsValid( self.TheLandingGear ) then -- spawn landing gear for all clients that dont have one
		local LandingGear = ents.CreateClientProp()
		LandingGear:SetPos( self:LocalToWorld( Vector(30,5,-15) ) )
		LandingGear:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
		LandingGear:SetModel( "models/mechanics/solid_steel/type_b_2_2.mdl" )
		LandingGear:SetParent( self )
		LandingGear:Spawn()
		
		self.TheLandingGear = LandingGear
	end
	
	self.SMLG = self.SMLG and self.SMLG + (1 *  self:GetLGear() - self.SMLG) * FrameTime() or 0 -- Left Wheel
	--self.SMRG = self.SMRG and self.SMRG + (1 *  self:GetRGear() - self.SMRG) * FrameTime() or 0 -- Right Wheel
	
	self.TheLandingGear:SetPos( self:LocalToWorld( Vector(30,5,-self.SMLG * 15) ) )
end

function ENT:ExhaustFX()
	--[[ function gets called each frame by the base script. you can do whatever you want here ]]--
end
