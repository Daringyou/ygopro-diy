--天印·汁光计
local s,id,o=GetID()
s.name="天印·汁光计"
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
	--特殊召唤
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.spcon2)
	c:RegisterEffect(e2)
	--
	local e3=Effect.CreateEffect(c)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1)
	e3:SetCondition(s.ltcon)
	e3:SetValue(s.ltval)
	c:RegisterEffect(e3)
end
function s.ltcon(e)
	local c=e:GetHandler()
	local code_add=aux.SkyTotem_Code_Add
	local ct=c:GetFlagEffectLabel(code_add)
	return ct and ct>0 and Duel.GetTurnPlayer()==e:GetHandlerPlayer()
end
function s.ltval(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return not s.CustomCheck()
end
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return s.CustomCheck()
end
function s.filter(c,e,tp)
	return c:GetOriginalLevel()==2 and c:IsType(TYPE_FUSION) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 or Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,e,tp) and e:GetHandler():IsLevelAbove(2) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end
function s.exfilter1(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFacedown() and c:IsType(TYPE_FUSION)
end
function s.exfilter2(c)
	return c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and c:IsType(TYPE_FUSION)
end
function s.gcheck(g,ft1,ft2,ft3,ect,ct)
	return #g<=ct
		and g:FilterCount(Card.IsLocation,nil,LOCATION_GRAVE)<=ft1
		and g:FilterCount(s.exfilter1,nil)<=ft2
		and g:FilterCount(s.exfilter2,nil)<=ft3
		and g:FilterCount(Card.IsLocation,nil,LOCATION_EXTRA)<=ect
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLevelAbove(2) then return end
	local ct=c:GetLevel()-1
	local ft1=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local ft2=Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_FUSION)
	local ft3=Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_PENDULUM)
	local ft=Duel.GetUsableMZoneCount(tp)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) then
		if ft1>0 then ft1=1 end
		if ft2>0 then ft2=1 end
		if ft3>0 then ft3=1 end
		if ft>0 then ft=1 end
		if ct>0 then ct=1 end
	end
	local ect=Duel.IsPlayerAffectedByEffect(tp,29724053)
	if ect then ect=c29724053[tp] else ect=ft end
	local loc=0
	if ft1>0 then loc=loc+LOCATION_GRAVE end
	if ect>0 and (ft2>0 or ft3>0) then loc=loc+LOCATION_EXTRA end
	if loc==0 then return end
	local sg=Duel.GetMatchingGroup(s.filter,tp,loc,0,nil,e,tp)
	if sg:GetCount()==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	aux.GCheckAdditional=aux.dncheck
	local rg=sg:SelectSubGroup(tp,s.gcheck,false,1,math.min(ft,ct),ft1,ft2,ft3,ect,ct)
	aux.GCheckAdditional=nil
	local fid=c:GetFieldID()
	local og=Group.CreateGroup()
	for tc in aux.Next(rg) do
		local zone=0xff
		if ft2==ft1+1 then
			if tc:IsLocation(LOCATION_EXTRA) then
				zone=0x60
				ft2=ft2-1
			else
				zone=0xff-0x60
				ft1=ft1-1
			end
		end
		if Duel.SpecialSummonStep(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP,zone) then
			og:AddCard(tc)
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		end
	end
	Duel.SpecialSummonComplete()
	for tc in aux.Next(og) do
		tc:CompleteProcedure()
	end
	Duel.BreakEffect()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-og:GetCount())
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
	for tc in aux.Next(og) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		tc:RegisterEffect(e1)
	end
	og:KeepAlive()
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetCountLimit(1)
	e1:SetLabel(Duel.GetTurnCount()+1)
	e1:SetLabelObject(og)
	e1:SetCondition(s.retcon)
	e1:SetOperation(s.retop)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	Duel.RegisterEffect(e1,tp)
end
function s.retfilter(c,fid)
	return c:GetFlagEffect(id)>0
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	return Duel.GetTurnCount()==e:GetLabel() and g:IsExists(s.retfilter,1,nil)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	local tg=g:Filter(s.retfilter,nil)
	Duel.SendtoDeck(tg,nil,2,REASON_EFFECT)
	g:DeleteGroup()
end