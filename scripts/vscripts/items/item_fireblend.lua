if item_fireblend == nil then item_fireblend = class({}) end

LinkLuaModifier("modifier_fireblend_passive","items/item_fireblend.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fireblend_fire","items/item_fireblend.lua",LUA_MODIFIER_MOTION_NONE)

function item_fireblend:OnSpellStart(  )
	if IsClient() then ClientLoadGridNav() end

	local target = self:GetCursorTarget()
	GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 160, true)
	self:CreateVisibilityNode(target:GetAbsOrigin(), 210, 0.6)
end

function item_fireblend:GetIntrinsicModifierName(  )
	return "modifier_fireblend_passive"
end

if modifier_fireblend_passive == nil then modifier_fireblend_passive = class({}) end

function modifier_fireblend_passive:GetAttributes(  )
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_fireblend_passive:IsHidden(  )
	return true
end

function modifier_fireblend_passive:IsPurgable(  )
	return false
end

function modifier_fireblend_passive:DeclareFunctions(  )
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_fireblend_passive:GetModifierAttackSpeedBonus_Constant(  )
	return self:GetAbility():GetSpecialValueFor("atk")
end

function modifier_fireblend_passive:GetModifierPreAttack_BonusDamage(  )
	return self:GetAbility():GetSpecialValueFor("attack")
end

function modifier_fireblend_passive:OnCreated(  )
	self:GetCaster():AddNewModifier(self:GetCaster(),self:GetAbility(),"modifier_fireblend_fire",{})
	self.quell = ability:GetSpecialValueFor("quell") 
	self.quell_ranged = ability:GetSpecialValueFor("quell_ranged") 
end

function modifier_fireblend_passive:OnDestroy(  )
	self:GetCaster():RemoveModifierByName("modifier_fireblend_fire")
end

function modifier_fireblend_passive:OnAttackLanded( params )
	local caster = self:GetParent()
	local target = params.target

	if IsServer() and params.attacker == caster then
		damage = params.damage
		local ability = self:GetAbility()

		if caster:IsRealHero() then
			if IsBoss(target) then
				print('This unit is boss, Quell dont work on boss')
				return;
			else
				if target:IsCreep() then
					local quell = nil

					if self:GetCaster():IsRangedAttacker() then
						quell = self.quell_ranged
					else
						quell = self.quell
					end

					local damage_quell = (damage  * self.quell - damage) / 100

					ApplyDamage({victim = target, attacker = caster, damage = damage_quell, damage_type = DAMAGE_TYPE_PHYSICAL})
				end
			end
		end	
	end	
end		
if modifier_fireblend_fire == nil then modifier_fireblend_fire = class({}) end

function modifier_fireblend_fire:IsHidden(  )
	return true
end

function modifier_fireblend_fire:IsPurgable(  )
	return false
end

function modifier_fireblend_fire:DeclareFunctions(  )
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_fireblend_fire:OnAttackLanded( params )
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local old_target
	local basic_target = params.target
	if params.attacker == caster then
		if RollPercentage(ability:GetSpecialValueFor("chance")) then
			if (caster:IsRealHero() and ability:IsCooldownReady()) then
				ability:StartCooldown(4);
				local id0 = ParticleManager:CreateParticle("particles/fireblend_explosion.vpcf",PATTACH_ABSORIGIN_FOLLOW, basic_target)
				ParticleManager:SetParticleControlEnt(id0, 3, basic_target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", basic_target:GetAbsOrigin(), false)
				caster:EmitSound("Hero_Jakiro.LiquidFire")
			
				local Units = FindUnitsInRadius(caster:GetTeamNumber(),
	                              params.target:GetAbsOrigin(),
	                              nil,
	                              ability:GetSpecialValueFor("radius"),
	                              DOTA_UNIT_TARGET_TEAM_ENEMY,
	                              DOTA_UNIT_TARGET_ALL,
	                              DOTA_UNIT_TARGET_FLAG_NONE,
	                              FIND_ANY_ORDER,
	                              false)
				
				for _,target in pairs(Units) do
					if target == old_target then break end
					
					local int = caster:GetIntellect() / 12
					local damage = ability:GetSpecialValueFor("damage")
					damage = damage + damage * int * 0.01
					if not caster:IsRealHero() then damage = damage * 0.2 end
					ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL,ability = ability})
					old_target = target
				end
			end
		end
	end
end