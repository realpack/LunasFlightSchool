--DO NOT EDIT OR REUPLOAD THIS FILE

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	
	self.mat = Material( "sprites/light_glow02_add" )
	
	self.LifeTime = 0.2
	self.DieTime = CurTime() + self.LifeTime
	
	sound.Play( "lfs/shield_deflect.ogg", self.Pos, 120, 100, 1 )
	
	self:Spark( self.Pos )
end

function EFFECT:Spark( pos )
	local emitter = ParticleEmitter( pos, false )
	
	for i = 0, 20 do
		local particle = emitter:Add( "sprites/rico1", pos )
		
		local vel = VectorRand() * 500
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( math.Rand( 200, 255 ) )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(10,20) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( 0, 127, 255 )

			particle:SetAirResistance( 0 )
		end
	end
	
	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end
	
	return true
end

function EFFECT:Render()
	local Scale = (self.DieTime - CurTime()) / self.LifeTime
	render.SetMaterial( self.mat )
	render.DrawSprite( self.Pos, 800 * Scale, 800 * Scale, Color( 0, 127, 255, 255) )
	render.DrawSprite( self.Pos, 200 * Scale, 200 * Scale, Color( 255, 255, 255, 255) )
end
