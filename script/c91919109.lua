--天印·泰山
local s, id, o = GetID()
s.name = "天印·泰山"
function s.initial_effect(c)
	--spsummon
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_DRAW)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--融合召唤
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
	e2:SetProperty(EFFECT_FLAG_DELAY + EFFECT_FLAG_DAMAGE_STEP)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.fstg)
	e2:SetOperation(s.fsop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp, chk)
	return eg:IsExists(Card.IsSummonPlayer, 1, nil, 1 - tp)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and e:GetHandler():IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP)
			and Duel.IsPlayerCanDraw(tp, 1)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, e:GetHandler(), 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE) <= 0 then return end
	local c = e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP) > 0 then
		local e1 = Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id, 2))
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CLIENT_HINT)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetRange(LOCATION_MZONE)
		e1:SetAbsoluteRange(tp, 1, 0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD)
		c:RegisterEffect(e1, true)
		if Duel.IsPlayerCanDraw(tp, 1) then
			Duel.BreakEffect()
			Duel.Draw(tp, 1, REASON_EFFECT)
		end
	end
end

function s.splimit(e, c)
	return c:GetOriginalLevel() ~= 2
end

function s.filtercheck(c, tp)
	return not c:IsCode(id) and c:GetOriginalLevel() == 2 and c:IsControler(tp) and c:IsFusionType(TYPE_MONSTER)
end

function s.fcheck(tp, sg, fc)
	return sg:FilterCount(Card.IsControler, nil, 1 - tp) <= sg:FilterCount(s.filtercheck, nil, tp)
end

function s.gcheck(tp)
	return function(sg)
		return sg:FilterCount(Card.IsControler, nil, 1 - tp) <= sg:FilterCount(s.filtercheck, nil, tp)
	end
end

function s.filter(c, tp)
	return (c:IsLocation(LOCATION_MZONE) or c:IsHasEffect(EFFECT_EXTRA_FUSION_MATERIAL, tp)) and
	c:IsCanBeFusionMaterial() and c:IsAbleToGrave() and (c:IsFaceup() or c:IsPublic())
end

function s.filter1(c, e)
	return not c:IsImmuneToEffect(e)
end

function s.filter2(c, e, tp, g, f, gc, chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, true) and c:CheckFusionMaterial(g, gc, chkf)
end

function s.fstg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local c = e:GetHandler()
		local chkf = tp
		local mg1 = Duel.GetFusionMaterial(tp)
		local mg2 = Duel.GetMatchingGroup(s.filter, tp, 0, LOCATION_ONFIELD, nil, tp)
		local exm = false
		if mg1:IsExists(s.filtercheck, 1, nil, tp) and mg2:GetCount() > 0 then
			mg1:Merge(mg2)
			aux.FCheckAdditional = s.fcheck
			aux.GCheckAdditional = s.gcheck(tp)
			exm = true
		end
		local res = Duel.IsExistingMatchingCard(s.filter2, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg1, nil, c, chkf)
		if exm then
			aux.FCheckAdditional = nil
			aux.GCheckAdditional = nil
		end
		if not res then
			local ce = Duel.GetChainMaterial(tp)
			if ce ~= nil then
				local fgroup = ce:GetTarget()
				local mg3 = fgroup(ce, e, tp)
				local mf = ce:GetValue()
				res = Duel.IsExistingMatchingCard(s.filter2, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg3, mf, c, chkf)
			end
		end
		return res
	end
end

function s.fsop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1 - tp) then return end
	local chkf = tp
	local mg1 = Duel.GetFusionMaterial(tp):Filter(s.filter1, nil, e)
	local mg2 = Duel.GetMatchingGroup(s.filter, tp, 0, LOCATION_ONFIELD, nil, tp):Filter(s.filter1, nil, e)
	local exm = false
	if mg1:IsExists(s.filtercheck, 1, nil, tp) and mg2:GetCount() > 0 then
		mg1:Merge(mg2)
		aux.FCheckAdditional = s.fcheck
		aux.GCheckAdditional = s.gcheck(tp)
		exm = true
	end
	local sg1 = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_EXTRA, 0, nil, e, tp, mg1, nil, c, chkf)
	if exm then
		aux.FCheckAdditional = nil
		aux.GCheckAdditional = nil
	end
	local mg3 = nil
	local sg2 = nil
	local ce = Duel.GetChainMaterial(tp)
	if ce ~= nil then
		local fgroup = ce:GetTarget()
		mg3 = fgroup(ce, e, tp)
		local mf = ce:GetValue()
		sg2 = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_EXTRA, 0, nil, e, tp, mg3, mf, c, chkf)
	end
	local sg = sg1:Clone()
	if sg2 then sg:Merge(sg2) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local tg = sg:Select(tp, 1, 1, nil)
	local tc = tg:GetFirst()
	if not tc then return end
	if sg1:IsContains(tc) and (sg2 == nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp, ce:GetDescription())) then
		if exm then
			aux.FCheckAdditional = s.fcheck
			aux.GCheckAdditional = s.gcheck(tp)
		end
		local mat1 = Duel.SelectFusionMaterial(tp, tc, mg1, c, chkf)
		if exm then
			aux.FCheckAdditional = nil
			aux.GCheckAdditional = nil
		end
		tc:SetMaterial(mat1)
		Duel.SendtoGrave(mat1, REASON_EFFECT + REASON_MATERIAL + REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, true, POS_FACEUP)
	else
		local mat2 = Duel.SelectFusionMaterial(tp, tc, mg3, c, chkf)
		local fop = ce:GetOperation()
		fop(ce, e, tp, tc, mat2)
	end
	tc:CompleteProcedure()
end
