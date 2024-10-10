--天印·浮黎
local s,id,o=GetID()
s.name="天印·浮黎"
function s.initial_effect(c)
	s.PublicEffect(c)
	s.PrivateEffect(c)
end
s.material_type=TYPE_FUSION
function s.PublicEffect(c)
	--融合召唤手续
	aux.AddFusionProcFunFunRep(c,s.mfilter1,s.mfilter2,2,127,true)
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
	return c:IsFusionSetCard(0x1091) and c:IsFusionType(TYPE_FUSION)
end
function s.mfilter2(c,fc)
	return (c:GetOriginalLevel()==2 or c:IsFusionAttribute(fc:GetOriginalAttribute()))
		and c:IsFusionType(TYPE_FUSION)
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
function s.PrivateEffect(c)
	--
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	e1:SetCondition(s.accon)
	e1:SetValue(s.aclimit)
	c:RegisterEffect(e1)
	--
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.accon)
	e2:SetTarget(s.imtg)
	e2:SetValue(s.imval)
	c:RegisterEffect(e2)
	--
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(TIMINGS_CHECK_MONSTER+TIMING_BATTLE_PHASE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.atkcon)
	e3:SetCost(s.atkcost)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end
function s.accon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.acfilter(c,att)
	local code_add=aux.SkyTotem_Code_Add
	local code_sub=aux.SkyTotem_Code_Sub
	local ct1=c:GetFlagEffectLabel(code_add) or 0
	local ct2=c:GetFlagEffectLabel(code_sub) or 0
	return c:IsAttribute(att) and c:IsFaceup() and ct1+ct2>0
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER) and Duel.IsExistingMatchingCard(s.acfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil,re:GetHandler():GetAttribute())
end
function s.imtg(e,c)
	local code_add=aux.SkyTotem_Code_Add
	local code_sub=aux.SkyTotem_Code_Sub
	local ct1=c:GetFlagEffectLabel(code_add) or 0
	local ct2=c:GetFlagEffectLabel(code_sub) or 0
	return c:IsFaceup() and ct1+ct2>0
end
function s.imval(e,re,ec)
	local rc=re:GetHandler()
	return e:GetHandlerPlayer()~=re:GetOwnerPlayer()
		and (re:IsActiveType(TYPE_SPELL+TYPE_TRAP) or bit.band(ec:GetAttribute(),rc:GetAttribute())==0)
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsLevelAbove(2) end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
end
function s.cfilter(c)
	return c:IsSetCard(0x1091) and not c:IsCode(id) and c:IsFaceup()
end
function s.atkfilter(c)
	local code_add=aux.SkyTotem_Code_Add
	local code_sub=aux.SkyTotem_Code_Sub
	local ct1=c:GetFlagEffectLabel(code_add) or 0
	local ct2=c:GetFlagEffectLabel(code_sub) or 0
	return c:IsFaceup() and ct1+ct2>0
end
function s.atkcon(e)
	return Duel.GetTurnPlayer()==e:GetHandlerPlayer() or Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_MZONE,0,1,nil) end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_MZONE,0,nil)
	if g:GetCount()>0 then
		local atk=g:GetSum(s.atkval)*200
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(atk)
		c:RegisterEffect(e1)
	end
end
function s.atkval(c)
	local code_add=aux.SkyTotem_Code_Add
	local code_sub=aux.SkyTotem_Code_Sub
	local ct1=c:GetFlagEffectLabel(code_add) or 0
	local ct2=c:GetFlagEffectLabel(code_sub) or 0
	return ct1+ct2
end