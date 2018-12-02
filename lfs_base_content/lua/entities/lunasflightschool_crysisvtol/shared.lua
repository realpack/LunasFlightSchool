--DO NOT EDIT OR REUPLOAD THIS FILE

ENT.Type            = "anim"
DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.PrintName = "Crysis Vtol"
ENT.Author = "Blu"
ENT.Information = ""
ENT.Category = "[LFS]"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.LFSHELI = true

ENT.MDL = "models/Combine_Helicopter.mdl"
ENT.GibModels = {
	"models/gibs/helicopter_brokenpiece_01.mdl",
	"models/gibs/helicopter_brokenpiece_02.mdl",
	"models/gibs/helicopter_brokenpiece_03.mdl",
	"models/gibs/helicopter_brokenpiece_06_body.mdl",
	"models/gibs/helicopter_brokenpiece_04_cockpit.mdl",
	"models/gibs/helicopter_brokenpiece_05_tailfan.mdl",
}

ENT.AITEAM = 1

ENT.Mass = 3000
ENT.Inertia = Vector(5000,5000,5000)
ENT.Drag = 0

ENT.SeatPos = Vector(120,0,-40)
ENT.SeatAng = Angle(0,-90,0)

ENT.IdleRPM = 400
ENT.MaxRPM = 3000
ENT.LimitRPM = 3000

ENT.RotorPos = Vector(0,0,65) -- used for the crosshair
--[[ -- not used for heli.
ENT.WingPos = Vector(50,5,20)
ENT.ElevatorPos = Vector(-150,5,20)
ENT.RudderPos = Vector(-150,5,20)

ENT.MaxVelocity = 1000
ENT.MaxPerfVelocity = 1500

ENT.MaxThrust = 800


ENT.MaxTurnPitch = 600
ENT.MaxTurnYaw = 600
ENT.MaxTurnRoll = 600

ENT.MaxStability = 0.7
]]--

ENT.MaxThrustHeli = 7
ENT.MaxTurnPitchHeli = 30
ENT.MaxTurnYawHeli = 50
ENT.MaxTurnRollHeli = 100

ENT.ThrustEfficiencyHeli = 0.6

ENT.RotorAngleHeli = Angle(15,0,0)
ENT.RotorRadiusHeli = 310

ENT.MaxHealth = 1600

ENT.MaxPrimaryAmmo = 100
ENT.MaxSecondaryAmmo = 12
