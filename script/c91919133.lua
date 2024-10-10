--天印·天皇
local s, id, o = GetID()
s.name = "天印·天皇"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
	Duel.AddCustomActivityCounter(id, ACTIVITY_CHAIN, s.ChainCheck)
end

--
function s.ChainCheck(re, tp, cid)
	local rc = re:GetHandler()
	return not (re:GetHandler():IsLevel(4) and not rc:IsCode(id) and re:IsActiveType(TYPE_MONSTER))
end

function s.ActivateCheck()
	return Duel.GetCustomActivityCount(id, 0, ACTIVITY_CHAIN) + Duel.GetCustomActivityCount(id, 1, ACTIVITY_CHAIN) ~= 0
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
	--回到卡组
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.tdcon1)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.tdcon2)
	c:RegisterEffect(e2)
end

function s.tdcon1(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.tdcon2(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
			and Duel.IsExistingMatchingCard(Card.IsAbleToDeck, tp, 0, LOCATION_ONFIELD, 1, nil)
	end
	local g = Duel.GetMatchingGroup(Card.IsAbleToDeck, tp, 0, LOCATION_ONFIELD, nil)
	local ct = 1
	if g:GetCount() > 1 and Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 2, REASON_COST) then
		Duel.Hint(HINT_SELECTMSG, tp, aux.Stringid(id, 1))
		ct = Duel.AnnounceNumber(tp, 1, 2)
	end
	Duel.RemoveCounter(tp, 1, 0, 0x1091, ct, REASON_COST)
	e:SetLabel(ct)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, ct, 1 - tp, LOCATION_ONFIELD)
end

function s.tdop(e, tp, eg, ep, ev, re, r, rp)
	local ct = e:GetLabel()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local g = Duel.SelectMatchingCard(tp, Card.IsAbleToDeck, tp, 0, LOCATION_ONFIELD, ct, ct, nil)
	if g:GetCount() > 0 then
		Duel.HintSelection(g)
		Duel.SendtoDeck(g, nil, 2, REASON_EFFECT)
	end
end
