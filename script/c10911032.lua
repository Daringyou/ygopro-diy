--天印·青华
local s, id, o = GetID()
s.name = "天印·青华"
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
	local code_sub = aux.SkyCodeSub			  --累计取除指示物数量
	local code_now = aux.SkyCodeNow			  --当前放置的指示物数量
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
	--效果免疫
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.descon)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandlerPlayer()~=e:GetHandlerPlayer()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST) end
	Duel.RemoveCounter(tp, 1, 0, 0x1091, 1, REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(Card.IsDestructable,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetRange(LOCATION_MZONE)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetLabelObject(re)
		c:RegisterEffect(e1)
	end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,1,nil)
	if g:GetCount()>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
function s.efilter(e,re)
	return re == e:GetLabelObject()
end