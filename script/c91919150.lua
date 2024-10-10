--
local m=91919150
local cm=_G["c"..m]
cm.name="圣天印·帷幕"
cm.counter_add_list={0x1091}
function cm.initial_effect(c)
	--activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(cm.acop)
	c:RegisterEffect(e1)
	--
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTarget(cm.sptg)
	e2:SetOperation(cm.spop)
	c:RegisterEffect(e2)
	--inactivatable
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetValue(cm.efilter)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_DISABLE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(LOCATION_ONFIELD,0)
	e5:SetTarget(cm.notdistg)
	c:RegisterEffect(e5)
	--Destroy replace
	local e6=Effect.CreateEffect(c)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EFFECT_DESTROY_REPLACE)
	e6:SetRange(LOCATION_FZONE)
	e6:SetTarget(cm.desreptg)
	e6:SetOperation(cm.desrepop)
	c:RegisterEffect(e6)
	if not cm.check then
		cm.check={}
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		e1:SetOperation(cm.restop)
		Duel.RegisterEffect(e1,0)
	end
end
function cm.acop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerCanDraw(tp,1) then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
function cm.efilter(e,ev)
	local p=e:GetHandler():GetControler()
	local te,tp,loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER,CHAININFO_TRIGGERING_LOCATION)
	local tc=te:GetHandler()
	return p==tp and (tc:GetOriginalRace()&RACE_FAIRY~=0 or tc:IsType(TYPE_SPELL+TYPE_TRAP) and tc:IsSetCard(0x1091)) and bit.band(loc,LOCATION_ONFIELD)~=0
end
function cm.notdistg(e,c)
	return c:GetOriginalRace()&RACE_FAIRY~=0 or c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSetCard(0x1091)
end
function cm.filter(c,e,tp)
	if not c:IsFaceup() or c:GetOriginalRace()&RACE_FAIRY==0 or cm.check[c:GetOriginalLevel()] then return false end
	if c:GetOriginalLevel()>4 then return true end
	return c:IsAbleToHand() and Duel.IsExistingMatchingCard(cm.cfilter,tp,LOCATION_DECK,0,1,nil,e,tp,c:GetOriginalCode(),c:GetOriginalLevel()) and Duel.GetMZoneCount(tp,c)>0
end
function cm.cfilter(c,e,tp,code,lv)
	return c:GetOriginalRace()&RACE_FAIRY~=0 and c:GetOriginalCode()~=code and c:GetOriginalLevel()==lv and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function cm.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and cm.filter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(cm.filter,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,cm.filter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	if g:GetFirst():GetOriginalLevel()<5 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	else
		e:SetCategory(CATEGORY_COUNTER)
		Duel.SetOperationInfo(0,CATEGORY_COUNTER,g,1,0,0)
	end
end
function cm.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsControler(tp)) then return end
	local lv=tc:GetOriginalLevel()
	if lv<5 then
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,cm.cfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,tc:GetOriginalCode(),lv)
			if g:GetCount()>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
			cm.check[lv]=true
		end
	else
		tc:AddCounter(0x1091,1)
		c:AddCounter(0x1091,1)
		cm.check[lv]=true
	end
end
function cm.desreptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsReason(REASON_RULE)
		and e:GetHandler():IsCanRemoveCounter(tp,0x1091,1,REASON_EFFECT) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function cm.desrepop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RemoveCounter(ep,0x1091,1,REASON_EFFECT)
end
function cm.restop(e,tp,eg,ep,ev,re,r,rp)
	cm.check={}
end