--DO NOT EDIT OR REUPLOAD THIS FILE

ENT.Type            = "anim"
DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.PrintName = "Droid Tri-Fighter"
ENT.Author = "Blu"
ENT.Information = ""
ENT.Category = "[LFS]"

ENT.Spawnable		= true
ENT.AdminSpawnable		= false

ENT.MDL = "models/salza/droidtrifighter.mdl"

ENT.AITEAM = 1

ENT.Mass = 2000
ENT.Inertia = Vector(150000,150000,150000)
ENT.Drag = -1

ENT.SeatPos = Vector(100,0,-15)
ENT.SeatAng = Angle(0,-90,0)

ENT.IdleRPM = 1
ENT.MaxRPM = 2800
ENT.LimitRPM = 3000

ENT.RotorPos = Vector(40,0,0)
ENT.WingPos = Vector(100,0,0)
ENT.ElevatorPos = Vector(-300,0,0)
ENT.RudderPos = Vector(-300,0,0)

ENT.MaxVelocity = 2200

ENT.MaxThrust = 20000

ENT.MaxTurnPitch = 1200
ENT.MaxTurnYaw = 1500
ENT.MaxTurnRoll = 700

ENT.MaxPerfVelocity = 1500

ENT.MaxHealth = 450

ENT.Stability = 0.7

ENT.MaxPrimaryAmmo = 1200
ENT.MaxSecondaryAmmo = 300

sound.Add( {
	name = "TRIFIGHTER_FIRE",
	channel = CHAN_ITEM,
	volume = 1.0,
	level = 125,
	pitch = {95, 105},
	sound = "lfs/trifighter/fire2.mp3"
} )

sound.Add( {
	name = "TRIFIGHTER_FIRE2",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 125,
	pitch = {95, 105},
	sound = "lfs/trifighter/fire.mp3"
} )

sound.Add( {
	name = "TRIFIGHTER_ENGINE",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	sound = "^lfs/trifighter/loop.wav"
} )
