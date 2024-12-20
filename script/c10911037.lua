--天印·汁光计
local s, id, o = GetID()
s.name = "天印·汁光计"
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
		aux.SkyCode = 919191340 --累计取除的指示物数量
		aux.SkyCodePlayer = { [0] = 0, [1] = 0 }
		SkyCode_Duel_RemoveCounter = Duel.RemoveCounter
		SkyCode_Card_RemoveCounter = Card.RemoveCounter
		Duel.RemoveCounter = function(tp, loc_s, loc_o, ctype, ct, reason)
			if ctype ~= 0x1091 then
				return SkyCode_Duel_RemoveCounter(tp, loc_s, loc_o, ctype, ct, reason)
			end
			s.CalculateTarget(tp, ctype, ct)
			local res = SkyCode_Duel_RemoveCounter(tp, loc_s, loc_o, ctype, ct, reason)
			s.CalculateOperation(tp, ctype, ct)
			return res
		end
		Card.RemoveCounter = function(c, tp, ctype, ct, reason)
			if ctype ~= 0x1091 then
				return SkyCode_Card_RemoveCounter(c, tp, ctype, ct, reason)
			end
			s.CalculateTarget(tp, ctype, ct)
			local res = SkyCode_Card_RemoveCounter(c, tp, ctype, ct, reason)
			s.CalculateOperation(tp, ctype, ct)
			return res
		end
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

function s.CalculateFilter(c, ctype)
	if ctype then
		return c:GetCounter(ctype) > 0
	end
	return c:GetFlagEffectLabel(aux.SkyCode + 100)
end

function s.CalculateTarget(tp, ctype, ct)
	local g = Duel.GetMatchingGroup(s.CalculateFilter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil, ctype)
	if g:GetCount() == 0 then return false end
	for tc in aux.Next(g) do
		local ft = tc:GetFlagEffectLabel(aux.SkyCode + 100)
		if ft then
			tc:SetFlagEffectLabel(aux.SkyCode + 100, tc:GetCounter(ctype))
		else
			tc:RegisterFlagEffect(aux.SkyCode + 100, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1,
				tc:GetCounter(ctype))
		end
	end
end

function s.CalculateOperation(tp, ctype, ct)
	local g = Duel.GetMatchingGroup(s.CalculateFilter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, nil)
	for tc in aux.Next(g) do
		local ft1 = tc:GetFlagEffectLabel(aux.SkyCode + 100)
		local ft2 = tc:GetCounter(ctype)
		if ft1 > ft2 then
			aux.SkyCodePlayer[tp] = aux.SkyCodePlayer[tp] + ft1 - ft2
			if tc:GetFlagEffect(aux.SkyCode) == 0 then
				tc:RegisterFlagEffect(aux.SkyCode, RESET_EVENT + RESETS_STANDARD - RESET_TURN_SET, 0, 1)
			end
		end
		tc:ResetFlagEffect(aux.SkyCode + 100)
	end
	Duel.Readjust()
end

function s.PrivateEffect(c)
	--除外
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, EFFECT_COUNT_CODE_SINGLE)
	e1:SetCost(s.remcost)
	e1:SetCondition(s.remcon1)
	e1:SetTarget(s.remtg)
	e1:SetOperation(s.remop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMINGS_CHECK_MONSTER + TIMING_MAIN_END)
	e2:SetCondition(s.remcon2)
	c:RegisterEffect(e2)
	--
	local e3 = Effect.CreateEffect(c)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0, 1)
	e3:SetCondition(s.ltcon)
	e3:SetValue(s.ltval)
	c:RegisterEffect(e3)
	Duel.AddCustomActivityCounter(id, ACTIVITY_CHAIN, s.ChainCheck)
end

function s.ChainCheck(re, tp, cid)
	local rc = re:GetHandler()
	return not (re:GetHandler():IsLevel(4) and not rc:IsCode(id) and re:IsActiveType(TYPE_MONSTER))
end

function s.ActivateCheck()
	return Duel.GetCustomActivityCount(id, 0, ACTIVITY_CHAIN) + Duel.GetCustomActivityCount(id, 1, ACTIVITY_CHAIN) == 0
end

function s.ltcon(e)
	local c = e:GetHandler()
	return c:GetCounter(0x1091) > 0 and Duel.GetTurnPlayer() == e:GetHandlerPlayer()
end

function s.ltval(e, re, tp)
	return re:IsActiveType(TYPE_SPELL + TYPE_TRAP)
end

function s.remcon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.remcon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.remcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST) end
	Duel.RemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
end

function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then
		return chkc:IsControler(1 - tp) and chkc:IsAbleToRemove()
			and chkc:IsLocation(LOCATION_ONFIELD + LOCATION_GRAVE)
	end
	if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD + LOCATION_GRAVE, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectTarget(tp, Card.IsAbleToRemove, tp, 0, LOCATION_ONFIELD + LOCATION_GRAVE, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, g, 1, 0, 0)
	Duel.SetChainLimit(s.limit(g:GetFirst():GetOriginalCode()))
end

function s.limit(code)
	return function(e, rp, tp)
		return not e:GetHandler():IsOriginalCodeRule(code)
	end
end

function s.remop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.Remove(tc, POS_FACEDOWN, REASON_EFFECT) ~= 0 and tc:IsLocation(LOCATION_REMOVED) then
		local c = e:GetHandler()
		local e1 = Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetTargetRange(0, LOCATION_ONFIELD)
		e1:SetTarget(s.distg)
		e1:SetLabelObject(tc)
		e1:SetReset(RESET_PHASE + PHASE_END)
		Duel.RegisterEffect(e1, tp)
		local e2 = Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_CHAIN_SOLVING)
		e2:SetCondition(s.discon)
		e2:SetOperation(s.disop)
		e2:SetLabelObject(tc)
		e2:SetReset(RESET_PHASE + PHASE_END)
		Duel.RegisterEffect(e2, tp)
	end
end

function s.distg(e, c)
	local tc = e:GetLabelObject()
	return c:IsOriginalCodeRule(tc:GetOriginalCodeRule())
end

function s.discon(e, tp, eg, ep, ev, re, r, rp)
	local tc = e:GetLabelObject()
	return rp == 1 - tp and re:GetHandler():IsOriginalCodeRule(tc:GetOriginalCodeRule())
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
	Duel.NegateEffect(ev)
end
