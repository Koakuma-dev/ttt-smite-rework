AddCSLuaFile()

if engine.ActiveGamemode() ~= 'terrortown' then
    SWEP.PrintName = 'Lightning Caller (Sandbox)'

    SWEP.Author = 'dhkatz & splet'
    SWEP.Purpose = 'Smite your foes.'
    SWEP.Instructions = 'Click to obliterate!'

    SWEP.Category = 'Other'
    SWEP.Spawnable = true
    SWEP.AdminOnly = false

    SWEP.Base = 'weapon_base'

    SWEP.Slot = 4
    SWEP.SlotPos = 4

    SWEP.AutoSwitchTo = false
    SWEP.AutoSwitchFrom = false
else
    SWEP.PrintName = 'ttt_smite_weapon_name'

    SWEP.Base = 'weapon_tttbase'

    SWEP.Slot = 7
    SWEP.Icon = 'vgui/ttt/icon_ttt_smite.png'

    SWEP.EquipMenuData = {
        type = 'item_weapon',
        desc = 'ttt_smite_weapon_desc'
    }

    SWEP.Kind = WEAPON_EQUIP1
    SWEP.CanBuy = { ROLE_TRAITOR }
    SWEP.LimitedStock = true

    SWEP.AllowDrop = false
    SWEP.NoSights = true
end

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 62
SWEP.ViewModel = Model('models/weapons/c_wizardry_caller.mdl')
SWEP.WorldModel	= Model("models/Items/combine_rifle_ammo01.mdl")

SWEP.HoldType = 'normal'
SWEP.UseHands = true
SWEP.FiresUnderwater = true

SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true 

if CLIENT then
    SWEP.BounceWeaponIcon = false 
	SWEP.WepSelectIcon = surface.GetTextureID('vgui/entities/weapon_ttt_smite.vtf')
    killicon.Add('weapon_ttt_smite', 'hud/killicons/weapon_ttt_smite.vtf', Color(255, 80, 0, 255))
end

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = 'AR2AltFire'
SWEP.Primary.Delay = 10

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = 'none'
SWEP.Secondary.Delay = 999

function SWEP:Initialize()
    self.ConvarDelay = GetConVar('ttt_smite_time')
    self.ConvarRadius = GetConVar('ttt_smite_radius')
    self.ConvarDamage = GetConVar('ttt_smite_damage')
    self.ConvarSparksVictim = GetConVar('ttt_smite_sparks_victim')
    self.ConvarSparksSelf = GetConVar('ttt_smite_sparks_self')
    self.ConvarMaxAmmo = GetConVar('ttt_smite_ammo')
    self.ConvarCooldown = GetConVar('ttt_smite_cooldown')
    self.ConvarStatus = GetConVar('ttt_smite_status')

    if engine.ActiveGamemode() == 'terrortown' then
        self:SetClip1(self.ConvarMaxAmmo:GetInt())
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar('Bool', 0, 'Charging')
    self:NetworkVar('Bool', 1, 'Charged')
    self:NetworkVar('Bool', 2, 'Smiting')
    self:NetworkVar('Entity', 0, 'Target')
    self:NetworkVar('Vector', 0, 'TargetPos')
    self:NetworkVar('Float', 0, 'ChargeTime')

    self:SetCharging(false)
    self:SetCharged(false)
    self:SetSmiting(false)
    self:SetTarget(NULL)
    self:SetTargetPos(Vector(0, 0, 0))
    self:SetChargeTime(0)
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then
        if engine.ActiveGamemode() == "terrortown" then
            SafeRemoveEntityDelayed(self, 0)
        end
        return
    end

    if self:GetCharging() then return end

    if self:GetOwner():IsPlayer() then
        self:GetOwner():LagCompensation(true)
    end

    local trace = self:GetOwner():GetEyeTrace()

    if self:GetOwner():IsPlayer() then
        self:GetOwner():LagCompensation(false)
    end

    local pos = trace.HitPos
    local ent = trace.Entity
    if IsValid(ent) then
        pos = ent:GetPos()
        self:SetTarget(ent)
        self:SetTargetPos(pos)
    else
        self:SetTarget(NULL)
        self:SetTargetPos(pos)
    end

    self:EmitSound('ttt_smite_speech', 550)

    local delay = self.ConvarDelay:GetFloat()
    if IsFirstTimePredicted() then
        timer.Simple(delay - 0.52, function()
            if not IsValid(self) then return end
            EmitSound('ttt_smite_thunder', self:CurrentTargetPos(), 0, CHAN_AUTO, 1, 550)
            self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
        end)

        timer.Simple(delay - 0.12, function()
            if not IsValid(self) then return end
            EmitSound('ttt_smite_explode', self:CurrentTargetPos(), 0, CHAN_AUTO, 1, 550)
        end)

        timer.Simple(delay - 0.25, function()
            if not IsValid(self) then return end
            self:SetCharged(true)
        end)

        timer.Simple(delay, function()
            if not IsValid(self) then return end
            self:SetSmiting(true)
            self:TakePrimaryAmmo(1)
        end)
    end

    self:SetCharging(true)
    self:SetChargeTime(CurTime() + delay)
    self:SetNextPrimaryFire(CurTime() + math.max(delay + 1, self.ConvarCooldown:GetFloat()))
end

function SWEP:SecondaryAttack()

end

function SWEP:Think()
    local trace = self:GetOwner():GetEyeTrace()
    local pos = trace.HitPos
    local ent = trace.Entity

    if IsValid(ent) then
        pos = ent:GetPos()
    end

    local target = self:GetTarget()
    if IsValid(target) then
        ent = target
        pos = target:GetPos()
    end

    if self:GetNextPrimaryFire() < CurTime() then
        if self.ConvarSparksVictim:GetBool() then
            self:Spark(ent)
        end
        if self.ConvarSparksSelf:GetBool() then
            self:Spark(self:GetOwner())
        end
    end

    if self:GetSmiting() then
        self:Smite()
    elseif self:GetCharging() then
        if not self:GetCharged() then
            self:Charge()
        else
            self:Prepare()
        end
    end
end

function SWEP:Smite()
    local pos = self:CurrentTargetPos()

    self:SetCharging(false)
    self:SetCharged(false)
    self:SetSmiting(false)
    self:SetTarget(NULL)

    if not SERVER then return end

    self:Glow(pos, 180, Color(150, 200, 255, 200))
    self:Glow(self:GetOwner():GetPos(), 40, Color(50, 70, 255, 170))

    self:Bolt(1000)

    self:Explosion(pos, true)
    self:Explosion(self:GetOwner():GetPos(), false)

    self:Shake(pos, 3000)
    self:Shake(pos, 16000)

    self:Scorch(pos)

    self:Steam(pos)
    self:Steam(self:GetOwner():GetPos())

    local damage = DamageInfo()
    damage:SetAttacker(self:GetOwner())
    damage:SetInflictor(self)
    damage:SetDamage(self.ConvarDamage:GetInt())
    damage:SetMaxDamage(1000)
    damage:SetDamageType(DMG_DISSOLVE + DMG_SHOCK)

    util.BlastDamageInfo(damage, pos, self.ConvarRadius:GetInt())

    if engine.ActiveGamemode() == "terrortown" and self:Clip1() <= 0 then
        SafeRemoveEntityDelayed(self, 0)
    end
end

function SWEP:Charge()
    -- Charge intensity based on how close to delay we are
    local intensity = 1 - math.Clamp((self:GetChargeTime() - CurTime()) / self.ConvarDelay:GetFloat(), 0, 1)

    if math.random() < intensity then
        local function glow(pos)
            local light = DynamicLight()
            if light then
                light.pos = pos
                light.r = 130
                light.g = 160
                light.b = 255
                light.brightness = 1
                light.decay = 1000
                light.size = 250 * intensity
                light.dietime = CurTime() + 1
            end
        end

        if CLIENT then
            glow(self:CurrentTargetPos())
            glow(self:GetOwner():GetPos())
        end

        local function tesla(target)
            if not IsValid(target) then return end

            local effect = EffectData()
            effect:SetEntity(target)
            effect:SetMagnitude(intensity * 5 / 2)
            util.Effect('TeslaHitBoxes', effect)

            if target:IsRagdoll() then
                for i = 0, target:GetPhysicsObjectCount() - 1 do
                    local phys = target:GetPhysicsObjectNum(i)
                    if IsValid(phys) then
                        phys:ApplyForceCenter(VectorRand(-250, 250))
                    end
                end
            end
        end

        if IsFirstTimePredicted() then
            tesla(self:GetOwner())
            tesla(self:GetTarget())
        end
    end

    if not IsValid(self:GetTarget()) and math.random() > 0.8 then
        local spark = EffectData()
        spark:SetOrigin(self:CurrentTargetPos())
        util.Effect('StunstickImpact', spark)
    end
end

function SWEP:Prepare()
    self:SetCharging(false)

    if SERVER then
        local pos = self:CurrentTargetPos()

        local sprite = ents.Create('env_sprite')
        sprite:SetKeyValue('model', 'sprites/blueflare1.spr')
        sprite:SetKeyValue('scale', '0')
        sprite:SetKeyValue('rendermode', '9')
        sprite:SetPos(pos)
        sprite:Spawn()
        sprite:Fire('Alpha', '170', 0)
        sprite:Fire('Color', '60 90 255', 0)
        sprite:Fire('Kill', '', 0.25)

        for i = 0.25, 0.01, -0.01 do
            sprite:Fire('SetScale', tostring(0 + (i * 200)), i)
            timer.Simple(i, function()
                if not IsValid(sprite) then return end
                sprite:SetPos(pos)
            end)
        end

        self:DeleteOnRemove(sprite)
    end
end

function SWEP:CurrentTargetPos()
    local target = self:GetTarget()
    if IsValid(target) then
        return target:GetPos()
    else
        return self:GetTargetPos()
    end
end

function SWEP:OnRemove()

end

function SWEP:Deploy()
    self:GetOwner():DrawViewModel(false)

    self:DrawShadow(false)

    return true
end

function SWEP:Reload()
    if engine.ActiveGamemode() == 'terrortown' then return false end

    return not self:GetCharging() and not self:GetSmiting()
end

function SWEP:Holster()
    return not self:GetCharging() and not self:GetSmiting()
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Spark(ent)
    if not IsValid(ent) then return end
    if math.random() < 0.95 then return end
    if ent:GetNWFloat('ttt_smite_spark', 0) > CurTime() then return end

    if CLIENT and IsFirstTimePredicted() then
        local light = DynamicLight()
        if light then
            light.pos = ent:GetPos() + Vector(0, 0, 50)
            light.r = 207
            light.g = 255
            light.b = 250
            light.brightness = 2
            light.decay = 1000
            light.size = 150
            light.dietime = CurTime() + 1
        end
    end

    if SERVER and TTT2 and ent:IsPlayer() and self.ConvarStatus:GetBool() then
        STATUS:AddTimedStatus(ent, 'ttt_smite_warning', 1)
    end

    ent:EmitSound(Sound('ambient/energy/spark' .. math.random(1, 6) .. '.wav'), 100, 100, 0.25, CHAN_AUTO)

    if IsFirstTimePredicted() then
        local effect = EffectData()
        effect:SetEntity(ent)
        effect:SetMagnitude(6)
        util.Effect('TeslaHitBoxes', effect, true, true)
    end

    ent:SetNWFloat('ttt_smite_spark', CurTime() + 1.8)
end

function SWEP:Bolt(offset)
    if not SERVER then return end

    offset = offset or 1000

    for height = -5, 5, 1 do
        local pos = self:CurrentTargetPos()
        local sprite = ents.Create('env_sprite')
        sprite:SetKeyValue('model', 'sprites/bluelight1.spr')
        sprite:SetKeyValue('scale', '75')
        sprite:SetKeyValue('rendermode', '5')
        sprite:SetKeyValue('disablereceiveshadows', 'true')
        sprite:SetPos(pos + Vector(0, 0, offset * height))
        sprite:Spawn()
        sprite:Fire('Kill', '', 0.5)
    
        for i = 0.50, 0.01, -0.01 do
            sprite:SetPos(pos + Vector(0, 0, (i * 18000) + offset * height))
            sprite:Fire('SetScale', tostring(75 - (i * 250)), i)
        end

        self:DeleteOnRemove(sprite)
    end
end

function SWEP:Explosion(pos, damage)
    if not SERVER then return end

    local targetExplosion = ents.Create('env_explosion')
    targetExplosion:SetPos(pos)
    targetExplosion:SetKeyValue('iMagnitude', '0')
    targetExplosion:SetKeyValue('iRadiusOverride', '0')
    if damage then
        targetExplosion:SetKeyValue('spawnflags', 64 + 512)
    else
        targetExplosion:SetKeyValue('spawnflags', 1 + 4 + 64 + 512)
    end
    targetExplosion:Spawn()
    targetExplosion:Fire('Explode', 0, 0)

    self:DeleteOnRemove(targetExplosion)
end

function SWEP:Glow(pos, scale, color)
    if not SERVER then return end

    local sprite = ents.Create('env_sprite')
    sprite:SetKeyValue('model', 'sprites/blueflare1.spr')
    sprite:SetKeyValue('scale', tostring(scale or 1))
    sprite:SetKeyValue('rendermode', '9')
    sprite:SetPos(pos)
    sprite:Spawn()
    sprite:Fire('Alpha', tostring(color.a), 0)
    sprite:Fire('Color', tostring(color.r) .. ' ' .. tostring(color.g) .. ' ' .. tostring(color.b), 0)
    sprite:Fire('Kill', '', 0.20)

    local factor = 2.143 * scale + 414.26
    for i = 0.20, 0.01, -0.01 do
        sprite:Fire('SetScale', tostring(scale - (i * factor)), i)
    end

    self:DeleteOnRemove(sprite)
end

function SWEP:Steam(pos)
    if not SERVER then return end

	local steam = ents.Create('env_steam')
    steam:SetKeyValue('initialstate', '1')
    steam:SetKeyValue('angles', '270 0 0')
    steam:SetKeyValue('type', '1')
    steam:SetKeyValue('spreadspeed', '5')
    steam:SetKeyValue('speed', '40')
    steam:SetKeyValue('startsize', '30')
    steam:SetKeyValue('endsize', '1')
    steam:SetKeyValue('rate', '20')
    steam:SetKeyValue('jetlength', '90')
    steam:SetKeyValue('rollspeed', '50')
    steam:SetKeyValue('renderamt', '200')
    steam:SetPos(pos)
    steam:Spawn()
    steam:Fire('TurnOn', '', 0)
    steam:Fire('TurnOff', '', 3)
    steam:Fire('Kill', '', 5)
    for i = 2, 0.5, -0.5 do
        steam:Fire('speed', tostring(40 - (i * 30)), i)
    end
    
    self:DeleteOnRemove(steam)
end

function SWEP:Shake(pos, radius)
    if not SERVER then return end

    local screenshake = ents.Create('env_shake')
    screenshake:SetKeyValue('amplitude', 1000)
    screenshake:SetKeyValue('duration', 2)
    screenshake:SetKeyValue('radius', radius)
    screenshake:SetKeyValue('frequency', 255)
    screenshake:Spawn()
    screenshake:SetPos(pos)
    screenshake:Activate()
    screenshake:Fire('StartShake', '', 0)
    screenshake:Fire('Kill', '', 0)

    self:DeleteOnRemove(screenshake)
end

function SWEP:Scorch(pos)
    if IsFirstTimePredicted() then
        local sparks = EffectData()
        sparks:SetOrigin(pos)
        sparks:SetScale(1)
        sparks:SetMagnitude(1)
        sparks:SetNormal(Vector(0, 0, 1))
        sparks:SetRadius(1)
        util.Effect('Sparks', sparks, true, true)

        util.Decal('Scorch', pos, pos + Vector(0, 0, -10), player.GetAll())
        for i = 1, 5 do
            util.Decal('Scorch', pos + Vector(math.Rand(-2, 2) * 25, math.Rand(-2, 2) * 25, 50), pos + Vector(math.Rand(-2, 2) * 25, math.Rand(-2, 2) * 25, -50), player.GetAll())
        end
    end
end
