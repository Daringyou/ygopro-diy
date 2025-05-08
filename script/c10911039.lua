--天印·玉清
local s, id, o = GetID()
s.name = "天印·玉清"
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
	--效果复制
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1, EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.cpcon1)
	e1:SetCost(s.cpcost)
	e1:SetTarget(s.cptg)
	e1:SetOperation(s.cpop)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.cpcon2)
	c:RegisterEffect(e2)
	Duel.AddCustomActivityCounter(id, ACTIVITY_CHAIN, s.ChainCheck)
end

function s.ChainCheck(re, tp, cid)
	local rc = re:GetHandler()
	return not (re:GetHandler():IsLevel(4) and not rc:IsCode(id) and re:IsActiveType(TYPE_MONSTER))
end

function s.ActivateCheck()
	return Duel.GetCustomActivityCount(id, 0, ACTIVITY_CHAIN) + Duel.GetCustomActivityCount(id, 1, ACTIVITY_CHAIN) == 0
end

function s.cpcon1(e, tp, eg, ep, ev, re, r, rp)
	return s.ActivateCheck()
end

function s.cpcon2(e, tp, eg, ep, ev, re, r, rp)
	return not s.ActivateCheck()
end

function s.cpcost(e, tp, eg, ep, ev, re, r, rp, chk)
	e:SetLabel(1)
	return true
end

function s.cpfilter(c)
	return c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToGraveAsCost() and
		c:CheckActivateEffect(false, true, false) ~= nil
end

function s.cptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	local c = e:GetHandler()
	if chkc then
		local te = e:GetLabelObject()
		local tg = te:GetTarget()
		return tg and tg(e, tp, eg, ep, ev, re, r, rp, 0, chkc)
	end
	if chk == 0 then
		if e:GetLabel() == 0 then return false end
		e:SetLabel(0)
		return Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
			and Duel.IsExistingMatchingCard(s.cpfilter, tp, LOCATION_DECK, 0, 1, nil)
	end
	e:SetLabel(0)
	Duel.RemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOGRAVE)
	local g = Duel.SelectMatchingCard(tp, s.cpfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
	Duel.SendtoGrave(g, REASON_COST)
	local te, ceg, cep, cev, cre, cr, crp = g:GetFirst():CheckActivateEffect(false, true, true)
	Duel.ClearTargetCard()
	local tg = te:GetTarget()
	e:SetProperty(te:GetProperty())
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg = te:GetTarget()
	if tg then tg(e, tp, eg, ep, ev, re, r, rp, 1) end
	te:SetLabel(e:GetLabel())
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	e:SetLabel(te:GetLabel())
	Duel.ClearOperationInfo(0)
end

function s.cpop(e, tp, eg, ep, ev, re, r, rp)
	local te = e:GetLabelObject()
	if not te then return end
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local op = te:GetOperation()
	if op then op(e, tp, eg, ep, ev, re, r, rp) end
end
