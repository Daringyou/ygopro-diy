--天印·泰山
local s, id, o = GetID()
s.name = "天印·泰山"
function s.initial_effect(c)
	--融合召唤
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1, id)
	e1:SetCondition(s.fscon)
	e1:SetCost(s.fscost)
	e1:SetOperation(s.fsop)
	c:RegisterEffect(e1)
end

function s.fscon(e, tp, eg, ep, ev, re, r, rp)
	return rp == 1 - tp
end

function s.fsfilter(c)
	return c:IsLevel(4) and c:IsType(TYPE_FUSION) and c:GetAttribute() ~= 0
end

function s.fscost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(s.fsfilter, tp, LOCATION_EXTRA, 0, 1, nil)
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONFIRM)
	local g = Duel.SelectMatchingCard(tp, s.fsfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil)
	Duel.ConfirmCards(1 - tp, g)
	e:SetLabel(g:GetFirst():GetAttribute())
end

function s.checkfilter(c, tp)
	return c:IsLevel(4) and c:IsControler(tp)
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

function s.fsop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetTargetRange(0, LOCATION_MZONE)
	e1:SetValue(e:GetLabel())
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
	Duel.BreakEffect()
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
	if (sg1:GetCount() > 0 or (sg2 ~= nil and sg2:GetCount() > 0)) and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
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
