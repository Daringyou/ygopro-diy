--天印·真武
local s, id, o = GetID()
s.name = "天印·真武"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
end

function s.PublicEffect(c)
	c:SetUniqueOnField(1, 0, id, LOCATION_MZONE)
	--融合召唤手续
	aux.AddFusionProcFunFunRep(c, s.mfilter1, s.mfilter2, 1, 127, true)
	aux.AddContactFusionProcedure(c, aux.FilterBoolFunction(Card.IsReleasable, REASON_SPSUMMON),
		LOCATION_HAND + LOCATION_MZONE, 0, Duel.Release, REASON_MATERIAL + REASON_FUSION):SetValue(SUMMON_TYPE_FUSION)
	c:EnableReviveLimit()
	--特殊召唤限制
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetValue(aux.fuslimit)
	c:RegisterEffect(e1)
	--放置指示物
	local e2 = Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.settlecon)
	e2:SetOperation(s.settleop)
	c:RegisterEffect(e2)
	local e3 = Effect.CreateEffect(c)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_MATERIAL_CHECK)
	e3:SetValue(s.settleval)
	e3:SetLabelObject(e2)
	c:RegisterEffect(e3)
	--指示物累计取除数值
	if not aux.SkyCodeCheck then
		aux.SkyCodeCheck = true
		aux.SkyCodeSub = 91919134 --累计取除的指示物数量
		aux.SkyCodeNow = 919191340 --当前放置的指示物数量
		aux.SkyCodeOperation()
	end
end

function s.mfilter1(c)
	return c:IsFusionSetCard(0x1091)
end

function s.mfilter2(c, fc)
	return c:IsLevel(4) or c:IsFusionAttribute(fc:GetOriginalAttribute())
end

function s.settlecon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.settleop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local ct = c:GetMaterialCount()
	local ect = e:GetLabel()
	c:AddCounter(0x1091, ct + ect)
end

function s.settleval(e, c)
	local val = c:GetMaterial():GetSum(Card.GetCounter, 0x1091)
	e:GetLabelObject():SetLabel(val)
end

function aux.SkyCodeOperation()
	Duel._RemoveCounter = Duel.RemoveCounter
	Card._RemoveCounter = Card.RemoveCounter
	Card._AddCounter = Card.AddCounter
	Duel.RemoveCounter = function(tp, loc_s, loc_o, ctype, ct, reason)
		if ctype ~= 0x1091 then
			return Duel._RemoveCounter(tp, loc_s, loc_o, ctype, ct, reason)
		end
		s.Calculate()
		local res = Duel._RemoveCounter(tp, loc_s, loc_o, ctype, ct, reason)
		s.Calculate()
		return res
	end
	Card.RemoveCounter = function(c, tp, ctype, ct, reason)
		if ctype ~= 0x1091 then
			return Card._RemoveCounter(c, tp, ctype, ct, reason)
		end
		s.Calculate()
		local res = Card._RemoveCounter(c, tp, ctype, ct, reason)
		s.Calculate()
		return res
	end
	Card.AddCounter = function(c, ctype, ct, singly)
		if ctype ~= 0x1091 then
			return Card._AddCounter(c, ctype, ct, singly)
		end
		s.Calculate()
		local res = Card._AddCounter(c, ctype, ct, singly)
		s.Calculate()
		return res
	end
end

function s.CalculateFilter(c)
	if not c:IsLevel(4) then return false end
	local code_now = aux.SkyCodeNow
	local code_sub = aux.SkyCodeSub
	local ct_now = c:GetFlagEffectLabel(code_now)
	local ct_sub = c:GetFlagEffectLabel(code_sub)
	local ct = c:GetCounter(0x1091)
	return not ct_now or not ct_sub or ct_now ~= ct
end

function s.Calculate()
	local g = Duel.GetMatchingGroup(s.CalculateFilter, tp, LOCATION_MZONE, LOCATION_MZONE, nil)
	if g:GetCount() == 0 then return end
	local code_sub = aux.SkyCodeSub              --累计取除指示物数量
	local code_now = aux.SkyCodeNow              --当前放置的指示物数量
	for tc in aux.Next(g) do
		local ct_sub = tc:GetFlagEffectLabel(code_sub) --该flag为指示物累计下降数值的计数器
		local ct_now = tc:GetFlagEffectLabel(code_now) --该flag为指示物标识器,滞后于实际指示物变化
		local ct = tc:GetCounter(0x1091)
		if not ct_sub then
			ct_sub = 0
			tc:RegisterFlagEffect(code_sub, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1, 0)
		end
		if not ct_now then
			ct_now = 0
			tc:RegisterFlagEffect(code_now, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1, 0)
		end
		if ct < ct_now then
			local ct_result = ct_sub + math.abs(ct_now - ct)
			tc:ResetFlagEffect(code_sub)
			tc:RegisterFlagEffect(code_sub, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1, ct_result)
			tc:ResetFlagEffect(code_now)
			tc:RegisterFlagEffect(code_now, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1, ct)
		elseif ct > ct_now then
			tc:ResetFlagEffect(code_now)
			tc:RegisterFlagEffect(code_now, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1, ct)
		end
	end
	Duel.Readjust()
end

function s.PrivateEffect(c)
	--改变攻击力
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE, EFFECT_FLAG2_WICKED)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.adcon)
	e1:SetValue(s.adval)
	c:RegisterEffect(e1)
	--代替破坏
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.reptg)
	e3:SetOperation(s.repop)
	e3:SetValue(s.repval)
	c:RegisterEffect(e3)
end

function s.adcon(e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetCurrentPhase() == PHASE_DAMAGE_CAL
		and e:GetHandler():GetBattleTarget()
end

function s.adval(e, c)
	local ec = e:GetHandler()
	local bc = ec:GetBattleTarget()
	if bc:GetAttack() > ec:GetAttack() then
		return bc:GetAttack()
	end
	return ec:GetAttack()
end

function s.repfilter(c, tp)
	return c:IsControler(tp) and c:IsReason(REASON_BATTLE)
		and not c:IsReason(REASON_REPLACE) and c:IsLocation(LOCATION_MZONE)
end

function s.reptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return eg:IsExists(s.repfilter, 1, nil, tp)
			and Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
	end
	return Duel.SelectEffectYesNo(tp, e:GetHandler(), 96)
end

function s.repval(e, c)
	return s.repfilter(c, e:GetHandlerPlayer())
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
	Duel.RemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
	Duel.Draw(tp, 1, REASON_EFFECT)
end
