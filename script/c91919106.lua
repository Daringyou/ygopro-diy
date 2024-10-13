--
local s, id, o = GetID()
s.name = "天印·卞城"
function s.initial_effect(c)
	--效果无效
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e1:SetCondition(s.discon1)
	e1:SetCost(s.Rcost)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)
	c:RegisterEffect(e1)
	local re1 = e1:Clone()
	re1:SetType(EFFECT_TYPE_QUICK_O)
	re1:SetCode(EVENT_FREE_CHAIN)
	re1:SetCondition(s.discon2)
	c:RegisterEffect(re1)
	--墓地特殊召唤
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1, id)
	e2:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e2:SetCondition(s.gscon1)
	e2:SetCost(s.Rcost)
	e2:SetTarget(s.gstg)
	e2:SetOperation(s.gsop)
	c:RegisterEffect(e2)
	local re2 = e2:Clone()
	re2:SetType(EFFECT_TYPE_QUICK_O)
	re2:SetCode(EVENT_FREE_CHAIN)
	re2:SetCondition(s.gscon2)
	c:RegisterEffect(re2)
	--墓地特殊召唤
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCondition(s.spcon1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	local e4 = e3:Clone()
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetCountLimit(1, EFFECT_COUNT_CODE_CHAIN)
	e4:SetHintTiming(0, TIMINGS_CHECK_MONSTER)
	e4:SetCondition(s.spcon2)
	c:RegisterEffect(e4)
	Duel.AddCustomActivityCounter(id, ACTIVITY_CHAIN, s.ChainCheck)
end

function s.ChainCheck(re, tp, cid)
	local rc = re:GetHandler()
	return not (re:GetHandler():IsLevel(4) and not rc:IsCode(id) and re:IsActiveType(TYPE_MONSTER))
end

function s.ActivateCheck()
	return Duel.GetCustomActivityCount(id, 0, ACTIVITY_CHAIN) + Duel.GetCustomActivityCount(id, 1, ACTIVITY_CHAIN) == 0
end

function s.discon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.discon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.Rcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(), REASON_COST + REASON_DISCARD)
end

function s.disfilter(c)
	return c:IsSetCard(0x1091) and c:IsAbleToGrave() and not c:IsCode(id)
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1 - tp) and chkc:IsOnField() and aux.NegateAnyFilter(chkc) end
	if chk == 0 then
		return Duel.IsExistingTarget(aux.NegateAnyFilter, tp, 0, LOCATION_ONFIELD, 1, nil)
			and Duel.IsExistingMatchingCard(s.disfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DISABLE)
	local g = Duel.SelectTarget(tp, aux.NegateAnyFilter, tp, 0, LOCATION_ONFIELD, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, 1, 0, 0)
	Duel.SetChainLimit(s.chainlm)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsCanBeDisabledByEffect(e, false) then
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local e1 = Effect.CreateEffect(c)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(e1)
		local e2 = Effect.CreateEffect(c)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		tc:RegisterEffect(e2)
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3 = Effect.CreateEffect(c)
			e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			e3:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e3)
		end
		local g = Duel.GetMatchingGroup(s.disfilter, tp, LOCATION_DECK, 0, nil)
		if g:GetCount() > 0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
			local sg = g:Select(tp, 1, 1, nil)
			if sg:GetCount() > 0 then
				Duel.SendtoGrave(sg, REASON_EFFECT)
			end
		end
	end
end

function s.chainlm(e, ep, tp)
	return tp == ep
end

function s.gscon1(e, tp, eg, ep, ev, re, r, rp)
	return not s.CustomCheck()
end

function s.gscon2(e, tp, eg, ep, ev, re, r, rp)
	return s.CustomCheck()
end

function s.gsfilter(c, e, tp)
	return c:GetOriginalLevel() == 2 and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.gstg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.gsfilter(chkc, e, tp) end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(s.gsfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectTarget(tp, s.gsfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
	Duel.SetChainLimit(s.chainlm)
end

function s.gsop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP_DEFENSE)
	end
end

function s.cfilter(c)
	return c:IsFaceup() and c:GetOriginalLevel() == 2 and not c:IsCode(id)
end

function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
		and not s.CustomCheck()
end

function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil)
		and s.CustomCheck()
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.cfilter, tp, LOCATION_MZONE, 0, 1, nil) and
		Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and c:IsCanBeSpecialSummoned(e, 0, tp, false, false) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		local e1 = Effect.CreateEffect(c)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetReset(RESET_EVENT + RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1, true)
	end
end
