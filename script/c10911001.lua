--天印·楚江
local s, id, o = GetID()
s.name = "天印·楚江"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
	Duel.AddCustomActivityCounter(id, ACTIVITY_CHAIN, s.ChainCheck)
end

function s.ChainCheck(re, tp, cid)
	local rc = re:GetHandler()
	return not (re:GetHandler():IsLevel(4) and not rc:IsCode(id) and re:IsActiveType(TYPE_MONSTER))
end

function s.ActivateCheck()
	return Duel.GetCustomActivityCount(id, 0, ACTIVITY_CHAIN) + Duel.GetCustomActivityCount(id, 1, ACTIVITY_CHAIN) == 0
end

function s.PublicEffect(c)
	--从手卡特殊召唤
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetCondition(s.rcon)
	e1:SetOperation(s.rop)
	c:RegisterEffect(e1)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1, EFFECT_COUNT_CODE_CHAIN)
	e2:SetCondition(s.hscon1)
	e2:SetTarget(s.hstg)
	e2:SetOperation(s.hsop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCondition(s.hscon2)
	c:RegisterEffect(e3)
end

function s.rcon(e, tp, eg, ep, ev, re, r, rp)
	return bit.band(r, REASON_EFFECT) ~= 0
end

function s.rop(e, tp, eg, ep, ev, re, r, rp)
	if e:GetHandler():GetFlagEffect(id) == 0 then
		e:GetHandler():RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD, EFFECT_FLAG_CLIENT_HINT, 1, 0,
			aux.Stringid(id, 1))
	end
end

function s.hscon1(e, tp, eg, ep, ev, re, r, rp)
	return (e:GetHandler():GetFlagEffect(id) > 0 or not Duel.IsExistingMatchingCard(Card.IsFaceup, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)) and
		s.ActivateCheck()
end

function s.hscon2(e, tp, eg, ep, ev, re, r, rp)
	return (e:GetHandler():GetFlagEffect(id) > 0 or not Duel.IsExistingMatchingCard(Card.IsFaceup, e:GetHandlerPlayer(), LOCATION_MZONE, 0, 1, nil)) and
		not s.ActivateCheck()
end

function s.hstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
end

function s.hsop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	if e:GetHandler():IsRelateToEffect(e) then
		Duel.SpecialSummon(e:GetHandler(), 0, tp, tp, false, false, POS_FACEUP)
	end
end

function s.PrivateEffect(c)
	--特殊召唤
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 2))
	e1:SetCategory(CATEGORY_DRAW + CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.spcon2)
	c:RegisterEffect(e2)
end

function s.spcon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.spcon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp, 1) and Duel.IsPlayerCanDiscardDeck(tp, 3) end
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
	Duel.SetOperationInfo(0, CATEGORY_DECKDES, nil, 0, tp, 3)
end

function s.spfilter(c, e, tp)
	return c:IsLevel(4) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.Draw(tp, 1, REASON_EFFECT) > 0 and Duel.DiscardDeck(tp, 3, REASON_EFFECT) > 0 then
		Duel.BreakEffect()
		local g = Duel.GetMatchingGroup(s.spfilter, tp, LOCATION_HAND, 0, nil, e, tp)
		if g:GetCount() > 0 and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local sg = g:Select(tp, 1, 1, nil)
			Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
		end
	end
end
