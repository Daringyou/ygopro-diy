--天印·含枢纽
local s, id, o = GetID()
s.name = "天印·含枢纽"
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
	--特殊召唤
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMINGS_CHECK_MONSTER)
	e2:SetCondition(s.spcon2)
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
	return re:IsActiveType(TYPE_MONSTER)
end

function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.spfilter(c, e, tp)
	if not (c:IsLevel(4) and c:IsType(TYPE_FUSION) and not c:IsCode(id)
			and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, true)) then
		return false
	end
	return c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0
		or Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, 1, nil, e, tp)
			and Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_EFFECT)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA + LOCATION_GRAVE)
end

function s.exfilter1(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFacedown()
end

function s.exfilter2(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsType(TYPE_PENDULUM)
end

function s.gcheck(ft1, ft2, ft3, ect, ft, tp)
	return function(g)
		return aux.dncheck(g) and #g <= ft
			and Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, #g, REASON_EFFECT)
			and g:FilterCount(Card.IsLocation, nil, LOCATION_GRAVE) <= ft1
			and g:FilterCount(s.exfilter1, nil) <= ft2
			and g:FilterCount(s.exfilter2, nil) <= ft3
			and g:FilterCount(Card.IsLocation, nil, LOCATION_EXTRA) <= ect
	end
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local ft1 = Duel.GetLocationCount(tp, LOCATION_MZONE)
	local ft2 = Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_FUSION)
	local ft3 = Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_PENDULUM)
	local ft = Duel.GetUsableMZoneCount(tp)
	if Duel.IsPlayerAffectedByEffect(tp, 59822133) then
		if ft1 > 1 then ft1 = 1 end
		if ft2 > 1 then ft2 = 1 end
		if ft3 > 1 then ft3 = 1 end
		if ft > 1 then ft = 1 end
	end
	local ect = c29724053 and Duel.IsPlayerAffectedByEffect(tp, 29724053) and c29724053[tp] or ft
	local loc = 0
	if ft1 > 0 then loc = loc + LOCATION_GRAVE end
	if ect > 0 and (ft2 > 0 or ft3 > 0) then loc = loc + LOCATION_EXTRA end
	if loc == 0 then return end
	local g = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter), tp, loc, 0, nil, e, tp)
	if g:GetCount() == 0 then return end
	local rg = Group.CreateGroup()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	aux.GCheckAdditional = s.gcheck(ft1, ft2, ft3, ect, ft, tp)
	local sg = g:SelectSubGroup(tp, aux.TRUE, false, 1, ft, ft1, ft2, ft3, ect, ft)
	aux.GCheckAdditional = nil
	for tc in aux.Next(sg) do
		if Duel.SpecialSummonStep(tc, SUMMON_TYPE_FUSION, tp, tp, false, true, POS_FACEUP) then
			tc:CompleteProcedure()
			rg:AddCard(tc)
			tc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 2)
		end
	end
	Duel.SpecialSummonComplete()
	Duel.BreakEffect()
	Duel.RemoveCounter(tp, 1, 0, 0x1091, #rg, REASON_EFFECT)
	for tc in aux.Next(rg) do
		tc:AddCounter(0x1091, 1)
	end
end

--[[
function s.filter(c, e, tp)
	if not (c:IsLevel(4) and c:IsType(TYPE_FUSION) and not c:IsCode(id)
			and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, true, true)) then
		return false
	end
	return (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0) or
		Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.filter, tp, LOCATION_EXTRA + LOCATION_GRAVE, 0, 1, nil, e, tp) and
			Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_EFFECT)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA + LOCATION_GRAVE)
end

--额外怪兽可用格子
function s.exfilter1(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFacedown() and c:IsType(TYPE_FUSION)
end

--灵摆怪兽可用格子
function s.exfilter1(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsType(TYPE_FUSION)
end

function s.gcheck(tp, ft1, ft2, ft3, ect)
	return function(g)
		return Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, #g, REASON_EFFECT)
			and g:GetClassCount(Card.GetCode) == #g
			and g:FilterCount(Card.IsLocation, nil, LOCATION_GRAVE) <= ft1
			and g:FilterCount(s.exfilter1, nil) <= ft2
			and g:FilterCount(s.exfilter1, nil) <= ft3
			and g:FilterCount(Card.IsLocation, nil, LOCATION_EXTRA) <= ect
	end
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or not Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_EFFECT) then return end
	local ft1 = Duel.GetLocationCount(tp, LOCATION_MZONE)            --主要怪兽可用格子
	local ft2 = Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_FUSION) --额外怪兽可用格子
	local ft3 = Duel.GetLocationCountFromEx(tp, tp, nil, TYPE_PENDULUM) --灵摆怪兽可用格子
	local ft = Duel.GetUsableMZoneCount(tp)                          --场上全部可用怪兽格子
	if Duel.IsPlayerAffectedByEffect(tp, 59822133) then
		if ft1 > 0 then ft1 = 1 end
		if ft2 > 0 then ft2 = 1 end
		if ft3 > 0 then ft3 = 1 end
		if ft > 0 then ft = 1 end
	end
	local ect = Duel.IsPlayerAffectedByEffect(tp, 29724053) and c29724053[tp] or ft
	local loc = 0
	if ft1 > 0 then loc = loc + LOCATION_GRAVE end
	if ect > 0 and (ft2 > 0 or ft3 > 0) then loc = loc + LOCATION_EXTRA end
	if loc == 0 then return end
	local sg = Duel.GetMatchingGroup(s.filter, tp, loc, 0, nil, e, tp)
	if sg:GetCount() == 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	aux.GCheckAdditional = s.gcheck(tp, ft1, ft2, ft3, ect)
	local rg = sg:SelectSubGroup(tp, aux.TRUE, false, 1, ft)
	aux.GCheckAdditional = nil
	local og = Group.CreateGroup()
	for tc in aux.Next(rg) do
		local zone = 0xff
		if ft2 == ft1 + 1 then
			if tc:IsLocation(LOCATION_EXTRA) then
				zone = 0x60
				ft2 = ft2 - 1
			else
				zone = 0xff - 0x60
				ft1 = ft1 - 1
			end
		end
		if Duel.SpecialSummonStep(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP, zone) then
			og:AddCard(tc)
			tc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 2)
		end
	end
	Duel.SpecialSummonComplete()
	for tc in aux.Next(og) do
		tc:CompleteProcedure()
	end
	Duel.BreakEffect()
	Duel.RemoveCounter(tp, 1, 0, 0x1091, #og, REASON_EFFECT)
	for tc in aux.Next(og) do
		tc:AddCounter(0x1091, 1)
	end
	og:KeepAlive()
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE + PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabel(Duel.GetTurnCount())
	e1:SetLabelObject(og)
	e1:SetCondition(s.retcon)
	e1:SetOperation(s.retop)
	e1:SetReset(RESET_PHASE + PHASE_END, 2)
	Duel.RegisterEffect(e1, tp)
end

function s.retfilter(c)
	return c:GetFlagEffect(id) > 0
end

function s.retcon(e, tp, eg, ep, ev, re, r, rp)
	local g = e:GetLabelObject()
	return Duel.GetTurnCount() ~= e:GetLabel() and g:IsExists(s.retfilter, 1, nil)
end

function s.retop(e, tp, eg, ep, ev, re, r, rp)
	local g = e:GetLabelObject()
	local tg = g:Filter(s.retfilter, nil)
	Duel.SendtoDeck(tg, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	g:DeleteGroup()
end
--]]
