--天印·白招拒
local s,id,o=GetID()
s.name="天印·白招拒"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
end
function s.PublicEffect(c)
	--融合召唤手续
	aux.AddFusionProcFunFunRep(c,s.mfilter1,s.mfilter2,1,127,true)
	aux.AddContactFusionProcedure(c,aux.FilterBoolFunction(Card.IsReleasable,REASON_FUSION),LOCATION_HAND+LOCATION_MZONE,0,Duel.Release,REASON_MATERIAL+REASON_FUSION):SetValue(SUMMON_TYPE_FUSION)
	c:EnableReviveLimit()
	--召唤限制
	local e0=Effect.CreateEffect(c)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)
	--等级上升
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.lvupcon)
	e1:SetValue(s.lvupval)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_MATERIAL_CHECK)
	e2:SetValue(s.valcheck)
	e2:SetLabelObject(e1)
	c:RegisterEffect(e2)
	--等级累计变化数值
	if not aux.SkyTotem_LevelCount then
		aux.SkyTotem_LevelCount=true
		--等级累计上升
		aux.SkyTotem_Code_Add=91919134
		--等级累计下降
		aux.SkyTotem_Code_Sub=91919234
		--当前等级
		aux.SkyTotem_Code_Now=91919334
		--
		local ce=Effect.CreateEffect(c)
		ce:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ce:SetCode(EVENT_ADJUST)
		ce:SetCondition(s.adjustcon)
		ce:SetOperation(s.adjustop)
		Duel.RegisterEffect(ce,0)
	end
end
function s.mfilter1(c)
	return c:IsFusionSetCard(0x1091)
end
function s.mfilter2(c,fc)
	return c:GetOriginalLevel()==2 or c:IsFusionAttribute(fc:GetOriginalAttribute())
end
function s.lvupcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.lvupval(e,c)
	return c:GetMaterialCount()+e:GetLabel()
end
function s.matval(c)
	local code_sub=aux.SkyTotem_Code_Sub
	local code_add=aux.SkyTotem_Code_Add
	local ct1=c:GetFlagEffectLabel(code_sub) or 0
	local ct2=c:GetFlagEffectLabel(code_add) or 0
	return ct1+ct2
end
function s.valcheck(e,c)
	local val=c:GetMaterial():GetSum(s.matval)
	e:GetLabelObject():SetLabel(val)
end
function s.adjustfilter(c)
	if c:GetOriginalLevel()~=2 then return false end
	local code_now=aux.SkyTotem_Code_Now
	local code_add=aux.SkyTotem_Code_Add
	local code_sub=aux.SkyTotem_Code_Sub
	local lv_now=c:GetFlagEffectLabel(code_now)
	local lv_add=c:GetFlagEffectLabel(code_add)
	local lv_sub=c:GetFlagEffectLabel(code_sub)
	local lv=c:GetLevel()
	return not lv_now or not lv_add or not lv_sub or lv_now~=lv
end
function s.adjustcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.adjustfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.adjustfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	--等级累计上升
	local code_add=aux.SkyTotem_Code_Add
	--等级累计下降
	local code_sub=aux.SkyTotem_Code_Sub
	--当前等级
	local code_now=aux.SkyTotem_Code_Now
	for tc in aux.Next(g) do
		--该flag为等级累计上升数值的计数器
		local lv_add=tc:GetFlagEffectLabel(code_add)
		if not lv_add then
			tc:RegisterFlagEffect(code_add,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET,0,1,0)
			lv_add=0
		end
		--该flag为等级累计下降数值的计数器
		local lv_sub=tc:GetFlagEffectLabel(code_sub)
		if not lv_sub then
			tc:RegisterFlagEffect(code_sub,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET,0,1,0)
			lv_sub=0
		end
		--该flag为等级标识器,滞后于实际等级变化
		local lv_now=tc:GetFlagEffectLabel(code_now)
		if not lv_now then
			tc:RegisterFlagEffect(code_now,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET,0,1,tc:GetOriginalLevel())
			lv_now=tc:GetOriginalLevel()
		end
		local lv=tc:GetLevel()
		if lv~=lv_now then
			local lv_result=lv_sub+math.abs(lv_now-lv)
			local code_result=lv<lv_now and code_sub or code_add
			tc:ResetFlagEffect(code_result)
			tc:RegisterFlagEffect(code_result,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET,0,1,lv_result)
			tc:ResetFlagEffect(code_now)
			tc:RegisterFlagEffect(code_now,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET,0,1,lv)
		end
	end
	Duel.Readjust()
end
function s.chainfilter(re,tp,cid)
	return re:GetHandler():IsCode(id) or re:GetHandler():GetOriginalLevel()~=2 or not re:IsActiveType(TYPE_MONSTER)
end
function s.CustomCheck()
	return Duel.GetCustomActivityCount(id,0,ACTIVITY_CHAIN)~=0
		or Duel.GetCustomActivityCount(id,1,ACTIVITY_CHAIN)~=0
end
function s.PrivateEffect(c)
	--墓地回收
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.tdcon1)
	e1:SetCost(s.tdcost)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.tdcon2)
	c:RegisterEffect(e2)
	--攻守上升
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.risetg)
	e3:SetValue(s.riseval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
end
function s.tdcon1(e,tp,eg,ep,ev,re,r,rp)
	return not s.CustomCheck()
end
function s.tdcon2(e,tp,eg,ep,ev,re,r,rp)
	return s.CustomCheck()
end
function s.tdcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsLevelAbove(2) end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and chkc:IsAbleToDeck() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToDeck,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,LOCATION_GRAVE,0,1,3,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,g:GetCount(),0,0)
end
function s.tdfilter(c)
	return c:GetOriginalLevel()==2 and not c:IsCode(id) and c:IsType(TYPE_MONSTER) or c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetsRelateToChain():Filter(Card.IsRelateToEffect,nil,e)
	Duel.SendtoDeck(g,nil,2,REASON_EFFECT)
	local ft=Duel.GetOperatedGroup():FilterCount(Card.IsLocation,nil,LOCATION_DECK+LOCATION_EXTRA)
	if ft>=1 then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(s.risetg)
		e1:SetValue(1)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
	if ft>=2 then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,2))
		e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CLIENT_HINT)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetTargetRange(LOCATION_ONFIELD,0)
		e2:SetTarget(s.risetg)
		e2:SetValue(1)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end
	if ft==3 then
		local e3=Effect.CreateEffect(c)
		e3:SetDescription(aux.Stringid(id,3))
		e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CLIENT_HINT)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e3:SetTargetRange(LOCATION_ONFIELD,0)
		e3:SetTarget(s.risetg)
		e3:SetValue(aux.tgoval)
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e4:SetCode(EVENT_CHAIN_SOLVING)
		e4:SetCondition(s.discon)
		e4:SetOperation(s.disop)
		e4:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e4,tp)
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_FIELD)
		e5:SetCode(EFFECT_DISABLE)
		e5:SetTargetRange(0,LOCATION_ONFIELD)
		e5:SetTarget(s.distg)
		e5:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e5,tp)
		local e6=e5:Clone()
		e6:SetCode(EFFECT_DISABLE_EFFECT)
		Duel.RegisterEffect(e6,tp)
	end
end
function s.risetg(e,c)
	return c:GetOriginalLevel()==2 and c:IsType(TYPE_MONSTER) or c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.riseval(e,c)
	local tc=e:GetHandler()
	local code_sub=aux.SkyTotem_Code_Sub
	local code_add=aux.SkyTotem_Code_Add
	local ct1=tc:GetFlagEffectLabel(code_sub) or 0
	local ct2=tc:GetFlagEffectLabel(code_add) or 0
	return (ct1+ct2)*200
end
function s.cfilter(c,tp)
	return (c:GetOriginalLevel()==2 and c:IsType(TYPE_MONSTER) or c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL+TYPE_TRAP)) and c:IsControler(tp)
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return rp~=tp and Duel.IsChainDisablable(ev)
		and g and g:IsExists(s.cfilter,1,nil,tp)
end
function s.distg(e,c)
	if c:GetCardTargetCount()==0 then return false end
	return c:GetCardTarget():IsExists(s.cfilter,1,nil,e:GetHandlerPlayer())
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end