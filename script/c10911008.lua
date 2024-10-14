--天印·都市
local s, id, o = GetID()
s.name = "天印·都市"
function s.initial_effect(c)
	--卡组检索+特殊召唤
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SEARCH + CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND + LOCATION_GRAVE)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.thcon1)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.thcon2)
	c:RegisterEffect(e2)
	--融合召唤
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
	e3:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetTarget(s.fstg)
	e3:SetOperation(s.fsop)
	c:RegisterEffect(e3)
	local e4 = e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
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

function s.thcon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.thcon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.costfilter(c)
	return c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSetCard(0x1091) and
		(c:IsLocation(LOCATION_HAND) and c:IsDiscardable() or c:IsAbleToRemoveAsCost())
end

function s.thcost(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	if chk == 0 then return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, c) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_OPERATECARD)
	local g = Duel.SelectMatchingCard(tp, s.costfilter, tp, LOCATION_HAND + LOCATION_GRAVE, 0, 1, 1, c)
	local tc = g:GetFirst()
	if tc:IsLocation(LOCATION_HAND) then
		Duel.SendtoGrave(tc, REASON_COST + REASON_DISCARD)
	else
		Duel.Remove(tc, POS_FACEUP, REASON_COST)
	end
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.costfilter, tp, LOCATION_DECK, 0, 1, nil)
			and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false)
			and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, nil, 1, tp, LOCATION_DECK)
end

function s.thfilter(c)
	return c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSetCard(0x1091) and c:IsAbleToHand()
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if g:GetFirst() > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1 - tp, g)
		end
	end
end

function s.checkfilter(c, tp)
	return not c:IsCode(id) and c:IsLevel(4) and c:IsControler(tp)
end

function s.fcheck(tp, sg, fc)
	return sg:FilterCount(Card.IsControler, nil, 1 - tp) <= sg:FilterCount(s.checkfilter, nil, tp)
end

function s.filter1(c, e)
	return c:IsCanBeFusionMaterial() and (c:IsFaceup() or c:IsPublic()) and
		(not e or not c:IsImmuneToEffect(e))
end

function s.filter2(c, e, tp, mg, f, gc, chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false) and c:CheckFusionMaterial(mg, gc, chkf)
end

function s.fstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local c = e:GetHandler()
		if not c:IsRelateToEffect(e) then return false end
		local chkf = tp
		local mg1 = Duel.GetFusionMaterial(tp)
		local mg2 = Duel.GetMatchingGroup(s.filter1, tp, 0, LOCATION_MZONE, nil)
		if mg1:IsExists(s.checkfilter, 1, nil, tp) and mg2:GetCount() > 0 then
			mg1:Merge(mg2)
		end
		aux.FCheckAdditional = s.fcheck
		local res = Duel.IsExistingMatchingCard(s.filter2, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg1, nil, c, chkf)
		if not res then
			local ce = Duel.GetChainMaterial(tp)
			if ce ~= nil then
				local fgroup = ce:GetTarget()
				local mg3 = fgroup(ce, e, tp)
				local mf = ce:GetValue()
				res = Duel.IsExistingMatchingCard(s.filter2, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg3, mf, c, chkf)
			end
		end
		aux.FCheckAdditional = nil
		return res
	end
end

function s.fsop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1 - tp) or c:IsImmuneToEffect(e) then return end
	local chkf = tp
	local mg1 = Duel.GetFusionMaterial(tp):Filter(aux.NOT(Card.IsImmuneToEffect), nil, e)
	local mg2 = Duel.GetMatchingGroup(s.filter1, tp, 0, LOCATION_MZONE, nil, e)
	if mg1:IsExists(s.checkfilter, 1, nil, tp) and mg2:GetCount() > 0 then
		mg1:Merge(mg2)
	end
	aux.FCheckAdditional = s.fcheck
	local sg1 = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_EXTRA, 0, nil, e, tp, mg1, nil, c, chkf)
	local mg3 = nil
	local sg2 = nil
	local ce = Duel.GetChainMaterial(tp)
	if ce ~= nil then
		local fgroup = ce:GetTarget()
		mg3 = fgroup(ce, e, tp)
		local mf = ce:GetValue()
		sg2 = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_EXTRA, 0, nil, e, tp, mg3, mf, c, chkf)
	end
	if sg1:GetCount() > 0 or (sg2 ~= nil and sg2:GetCount() > 0) then
		local sg = sg1:Clone()
		if sg2 then sg:Merge(sg2) end
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
		local tg = sg:Select(tp, 1, 1, nil)
		local tc = tg:GetFirst()
		if sg1:IsContains(tc) and (sg2 == nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp, ce:GetDescription())) then
			local mat1 = Duel.SelectFusionMaterial(tp, tc, mg1, c, chkf)
			tc:SetMaterial(mat1)
			Duel.SendtoGrave(mat1, REASON_EFFECT + REASON_MATERIAL + REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)
		else
			local mat2 = Duel.SelectFusionMaterial(tp, tc, mg3, c, chkf)
			local fop = ce:GetOperation()
			fop(ce, e, tp, tc, mat2)
		end
		tc:CompleteProcedure()
	end
	aux.FCheckAdditional = nil
end
