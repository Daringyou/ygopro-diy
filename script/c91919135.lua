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
	--融合召唤
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,EFFECT_COUNT_CODE_SINGLE)
	e1:SetCondition(s.fscon1)
	e1:SetCost(s.fscost)
	e1:SetTarget(s.fstg)
	e1:SetOperation(s.fsop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(TIMING_SPSUMMON)
	e2:SetCondition(s.fscon2)
	c:RegisterEffect(e2)
end
function s.fscon1(e,tp,eg,ep,ev,re,r,rp)
	return not s.CustomCheck()
end
function s.fscon2(e,tp,eg,ep,ev,re,r,rp)
	return s.CustomCheck()
end
function s.fscost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsLevelAbove(2) end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(-1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
	c:RegisterEffect(e1)
end
function s.fcheck(ct)
	return	function(tp,sg,fc)
				return sg:FilterCount(Card.IsControler,nil,1-tp)<=ct
			end
end
function s.filter1(c,tp,e)
	return (c:IsLocation(LOCATION_MZONE) or c:IsHasEffect(EFFECT_EXTRA_FUSION_MATERIAL,tp)) and c:IsCanBeFusionMaterial() and c:IsAbleToGrave() and (c:IsFaceup() or c:IsPublic()) and (not e or not c:IsImmuneToEffect(e))
end
function s.filter2(c,e,tp,mg,f,gc,chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(mg,nil,chkf)
end
function s.fstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp)
		local mg2=Duel.GetMatchingGroup(s.filter1,tp,0,LOCATION_ONFIELD,nil,tp)
		local exm=false
		local code_sub=aux.SkyTotem_Code_Sub
		local code_add=aux.SkyTotem_Code_Add
		local ct1=c:GetFlagEffectLabel(code_sub) or 0
		local ct2=c:GetFlagEffectLabel(code_add) or 0
		if ct1+ct2>0 and mg2:GetCount()>0 then
			mg1:Merge(mg2)
			aux.FCheckAdditional=s.fcheck(ct1+ct2)
			exm=true
		end
		local res=Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,nil,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg3=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg3,mf,nil,chkf)
			end
		end
		if exm then
			aux.FCheckAdditional=nil
		end
		return res
	end
end
function s.fsop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(aux.NOT(Card.IsImmuneToEffect),nil,e)
	local mg2=Duel.GetMatchingGroup(s.filter1,tp,0,LOCATION_ONFIELD,nil,tp,e)
	local exm=false
	local code_sub=aux.SkyTotem_Code_Sub
	local code_add=aux.SkyTotem_Code_Add
	local ct1=c:GetFlagEffectLabel(code_sub) or 0
	local ct2=c:GetFlagEffectLabel(code_add) or 0
	if ct1+ct2>0 and mg2:GetCount()>0 then
		mg1:Merge(mg2)
		aux.FCheckAdditional=s.fcheck(ct1+ct2)
		exm=true
	end
	local sg1=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,nil,chkf)
	local mg3=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg3=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg3,mf,nil,chkf)
	end
	local sg=sg1:Clone()
	if sg2 then sg:Merge(sg2) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=sg:Select(tp,1,1,nil)
	local tc=tg:GetFirst()
	if not tc then return end
	if sg1:IsContains(tc) and (sg2==nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp,ce:GetDescription())) then
		local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
		tc:SetMaterial(mat1)
		Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	else
		local mat2=Duel.SelectFusionMaterial(tp,tc,mg3,nil,chkf)
		local fop=ce:GetOperation()
		fop(ce,e,tp,tc,mat2)
	end
	tc:CompleteProcedure()
	if exm then
		aux.FCheckAdditional=nil
	end
end