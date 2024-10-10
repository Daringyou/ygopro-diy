--天印·玉清
local s,id,o=GetID()
s.name="天印·玉清"
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
	--融合召唤
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.cpcon1)
	e1:SetCost(s.cpcost)
	e1:SetTarget(s.cptg)
	e1:SetOperation(s.cpop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.cpcon2)
	c:RegisterEffect(e2)
end
function s.cpcon1(e,tp,eg,ep,ev,re,r,rp)
	return not s.CustomCheck()
end
function s.cpcon2(e,tp,eg,ep,ev,re,r,rp)
	return s.CustomCheck()
end
function s.cpcost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	return true
end
function s.cpfilter(c)
	return c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToGraveAsCost() and c:CheckActivateEffect(false,true,false)~=nil
end
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then
		local te=e:GetLabelObject()
		local tg=te:GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then
		if e:GetLabel()==0 then return false end
		e:SetLabel(0)
		return c:IsLevelAbove(2)
			and Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_DECK,0,1,nil)
	end
	e:SetLabel(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
	local te,ceg,cep,cev,cre,cr,crp=g:GetFirst():CheckActivateEffect(false,true,true)
	Duel.ClearTargetCard()
	local tg=te:GetTarget()
	e:SetProperty(te:GetProperty())
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg=te:GetTarget()
	if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
	te:SetLabel(e:GetLabel())
	te:SetLabelObject(e:GetLabelObject())
	e:SetLabelObject(te)
	e:SetLabel(te:GetLabel())
	Duel.ClearOperationInfo(0)
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end