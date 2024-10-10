--天印·灵威仰
local s, id, o = GetID()
s.name = "天印·灵威仰"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
end

function s.PublicEffect(c)
	c:SetUniqueOnField(1, 0, id, LOCATION_MZONE)
	--融合召唤手续
	aux.AddFusionProcFunFunRep(c, s.mfilter1, s.mfilter2, 2, 127, true)
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
	--除外对方卡组
	local e0 = Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id, 0))
	e0:SetCategory(CATEGORY_REMOVE)
	e0:SetType(EFFECT_TYPE_QUICK_O)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetRange(LOCATION_MZONE)
	e0:SetHintTiming(TIMINGS_CHECK_MONSTER + TIMING_BATTLE_PHASE)
	e0:SetCountLimit(1, EFFECT_COUNT_CODE_CHAIN)
	e0:SetTarget(s.remtg)
	e0:SetOperation(s.remop)
	c:RegisterEffect(e0)
	--攻守上升
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 1))
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter1)
	e1:SetLabel(1)
	local ge1 = Effect.CreateEffect(c)
	ge1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_GRANT)
	ge1:SetRange(LOCATION_MZONE)
	ge1:SetTargetRange(LOCATION_MZONE, 0)
	ge1:SetTarget(s.granttg)
	ge1:SetLabelObject(e1)
	c:RegisterEffect(ge1)
	--卡组抽卡
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 2))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetLabel(2)
	e2:SetCost(s.drcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	local ge2 = ge1:Clone()
	ge2:SetLabelObject(e2)
	c:RegisterEffect(ge2)
	--放置指示物
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 3))
	e3:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e3:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetLabel(3)
	e3:SetCondition(s.ctcon)
	e3:SetOperation(s.ctop)
	local ge3 = ge1:Clone()
	ge3:SetLabelObject(e3)
	c:RegisterEffect(ge3)
	--效果免疫
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 4))
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.efilter2)
	e4:SetLabel(4)
	local ge4 = ge1:Clone()
	ge4:SetLabelObject(e4)
	c:RegisterEffect(ge4)
end

function s.remfilter(c, tp, list)
	local ct = list and list[c] or 0
	return c:GetFlagEffect(id) == 0 and c:IsCanRemoveCounter(tp, 0x1091, ct + 1, REASON_COST)
end

function s.seqfilter(c, seq)
	return c:GetSequence() == seq
end

function s.remtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local g = Duel.GetDecktopGroup(1 - tp, 1)
		local tc = g:GetFirst()
		return tc and tc:IsAbleToRemove()
			and Duel.IsExistingMatchingCard(s.remfilter, tp, LOCATION_ONFIELD, 0, 1, nil, tp)
	end
	local ct = 0
	local min = 1
	local list = {}
	local og = Group.CreateGroup()
	local g = Duel.GetFieldGroup(tp, 0, LOCATION_DECK)
	local deckct = g:GetCount()
	local tc = g:Filter(s.seqfilter, nil, deckct - ct - 1):GetFirst()
	while tc and tc:IsAbleToRemove() and Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, ct + 1, REASON_COST) do
		Duel.Hint(HINT_SELECTMSG, tp, aux.Stringid(id, 5))
		local sg = Duel.SelectMatchingCard(tp, s.remfilter, tp, LOCATION_ONFIELD, 0, min, 1, nil, tp, list)
		if not sg or sg:GetCount() == 0 then break end
		ct = ct + 1
		local sc = sg:GetFirst()
		if not list[sc] then list[sc] = 0 end
		list[sc] = list[sc] + 1
		og:AddCard(sc)
		if min ~= 0 then min = 0 end
		tc = g:Filter(s.seqfilter, nil, deckct - ct - 1):GetFirst()
	end
	for oc in aux.Next(og) do
		if oc:GetFlagEffect(id) == 0 then
			oc:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, EFFECT_FLAG_CLIENT_HINT, 1, 0, aux.Stringid(id, 6))
		end
		oc:RemoveCounter(tp,0x1091,list[oc],REASON_COST)
	end
	Duel.SetTargetPlayer(1 - tp)
	Duel.SetTargetParam(ct)
	Duel.SetOperationInfo(0, CATEGORY_REMOVE, nil, ct, 1 - tp, LOCATION_DECK)
end

function s.remcheck(c, seq)
	return c:GetSequence() > seq
end

function s.remop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	local g = Duel.GetFieldGroup(p, LOCATION_DECK, 0)
	if g:GetCount() == 0 then return end
	local seq = -1
	local rg = g:Filter(aux.NOT(Card.IsAbleToRemove), nil)
	if rg:GetCount() > 0 then
		local _, maxseq = rg:GetMaxGroup(Card.GetSequence)
		seq = g:Filter(s.remcheck, nil, maxseq)
	end
	local sg = g:Filter(s.remcheck, nil, seq)
	local og = Duel.GetDecktopGroup(p, math.min(d, sg:GetCount()))
	if og:GetCount() > 0 then
		Duel.DisableShuffleCheck()
		local ct = Duel.Remove(og, POS_FACEDOWN, REASON_EFFECT)
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetTargetRange(LOCATION_MZONE, 0)
		e1:SetTarget(s.addval)
		e1:SetValue(ct * 100)
		e1:SetReset(RESET_PHASE + PHASE_END)
		Duel.RegisterEffect(e1, tp)
	end
end

function s.addval(e, c)
	return c:GetFlagEffect(aux.SkyCode) > 0
end

function s.granttg(e, c)
	return aux.SkyCodePlayer[e:GetHandlerPlayer()] >= e:GetLabelObject():GetLabel() and c:GetFlagEffect(aux.SkyCode) > 0
end

function s.efilter1(e, c)
	return aux.SkyCodePlayer[e:GetHandlerPlayer()] * 100
end

function s.drcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsCanRemoveCounter(tp, 0x1091, 1, REASON_COST) end
	e:GetHandler():RemoveCounter(tp, 0x1091, 1, REASON_COST)
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDraw(tp, 1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	Duel.Draw(p, d, REASON_EFFECT)
end

function s.efilter2(e, re)
	return e:GetHandlerPlayer() ~= re:GetOwnerPlayer()
end

function s.ctcon(e, tp, eg, ep, ev, re, r, rp)
	return ep == 1 - tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
end

function s.ctop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_CARD, tp, id)
	e:GetHandler():AddCounter(0x1091, 1)
end
