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
	--效果无效
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.discon1)
	e2:SetCost(s.discost)
	e2:SetTarget(s.solvetg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCondition(s.discon2)
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
	if (sg1:GetCount() > 0 or (sg2 ~= nil and sg2:GetCount() > 0)) and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
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

function s.disfilter(c, e, tp)
	return c:IsType(TYPE_FUSION) and c:IsAbleToRemoveAsCost() and c:GetAttribute() ~= 0
end

function s.discost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return e:GetHandler():IsAbleToRemoveAsCost()
			and Duel.IsExistingMatchingCard(s.disfilter, tp, LOCATION_GRAVE, 0, 1, e:GetHandler())
	end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
	local g = Duel.SelectMatchingCard(tp, s.disfilter, tp, LOCATION_GRAVE, 0, 1, 1, e:GetHandler())
	e:SetLabel(g:GetFirst():GetAttribute())
	g:AddCard(e:GetHandler())
	Duel.Remove(g, POS_FACEUP, REASON_COST)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local att = e:GetLabel()
	--发动限制
	local e1 = Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0, 1)
	e1:SetLabel(att)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE + PHASE_END)
	Duel.RegisterEffect(e1, tp)
	--效果无效
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetTargetRange(0, LOCATION_MZONE)
	e2:SetLabel(att)
	e2:SetTarget(s.solvetg)
	Duel.RegisterEffect(e2, tp)
	--效果无效
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetLabel(att)
	e3:SetCondition(s.solvecon)
	e3:SetOperation(s.solveop)
	Duel.RegisterEffect(e3, tp)
	--无效陷阱怪兽
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_DISABLE_TRAPMONSTER)
	e4:SetTargetRange(0, LOCATION_MZONE)
	e4:SetLabel(att)
	e4:SetTarget(s.solvetg)
	Duel.RegisterEffect(e4, tp)
end

function s.aclimit(e, re, tp)
	local att = e:GetLabel()
	local loc = re:GetActivateLocation()
	return bit.band(loc, LOCATION_MZONE) == LOCATION_MZONE and re:IsActiveType(TYPE_MONSTER)
		and bit.band(att, re:GetHandler():GetAttribute()) ~= 0
end

function s.solvetg(e, c)
	return bit.band(e:GetLabel(), c:GetAttribute()) ~= 0
end

function s.solvecon(e, tp, eg, ep, ev, re, r, rp)
	local att, loc, tep = Duel.GetChainInfo(ev, CHAININFO_TRIGGERING_ATTRIBUTE, CHAININFO_TRIGGERING_LOCATION,
		CHAININFO_TRIGGERING_PLAYER)
	return loc == LOCATION_MZONE and re:IsActiveType(TYPE_MONSTER) and bit.band(att, e:GetLabel()) ~= 0
		and tep == 1 - tp and Duel.IsChainDisablable(ev)
end

function s.solveop(e, tp, eg, ep, ev, re, r, rp)
	Duel.NegateEffect(ev)
end
