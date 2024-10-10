--
local m=91919156
local cm=_G["c"..m]
cm.name="天印·还受生"
function cm.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(m,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,m+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(cm.actg)
	e1:SetOperation(cm.acop)
	c:RegisterEffect(e1)
	--Tohand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(m,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(cm.thcost)
	e2:SetTarget(cm.thtg)
	e2:SetOperation(cm.thop)
	c:RegisterEffect(e2)
end
function cm.cfilter(c)
	return c:GetOriginalRace()&RACE_FAIRY~=0 or c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSetCard(0x1091) and not c:IsCode(m)
end
function cm.actg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,5) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,5)
end
function cm.spfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,true)
		and c:CheckFusionMaterial(mg,nil,tp)
end
function cm.acop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerCanDiscardDeck(tp,5) then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	local cg=g:Filter(cm.cfilter,nil)
	local ct=cg:GetCount()
	if ct==0 then return end
	local hg=cg:Filter(Card.IsAbleToHand,nil)
	local tg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,nil)
	local sg=Duel.GetMatchingGroup(cm.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,cg)
	local hgchk=hg:GetCount()>0
	local tgchk=tg:GetCount()>0
	local sgchk=sg:GetCount()>0
	while (hgchk or tgchk or sgchk) and Duel.SelectYesNo(tp,aux.Stringid(m,2)) do
		local off=1
		local ops={}
		local opval={}
		if hg:GetCount()>0 and hgchk then
			ops[off]=aux.Stringid(m,3)
			opval[off-1]=1
			off=off+1
		end
		if tg:GetCount()>0 and tgchk then
			ops[off]=aux.Stringid(m,4)
			opval[off-1]=2
			off=off+1
		end
		if sg:GetCount()>0 and sgchk then
			ops[off]=aux.Stringid(m,5)
			opval[off-1]=3
			off=off+1
		end
		ops[off]=aux.Stringid(m,6)
		opval[off-1]=4
		off=off+1
		local op=Duel.SelectOption(tp,table.unpack(ops))
		if opval[op]==1 then
			hgchk=false
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local Hg=hg:Select(tp,1,1,nil)
			cg:Sub(Hg)
			Duel.DisableShuffleCheck()
			Duel.SendtoHand(Hg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,Hg)
		elseif opval[op]==2 then
			tgchk=false
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local Tg=tg:Select(tp,1,ct,nil)
			Duel.HintSelection(Tg)
			Duel.SendtoGrave(Tg,REASON_EFFECT)
		elseif opval[op]==3 then
			sgchk=false
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local Sg=sg:Select(tp,1,1,nil)
			local tc=Sg:GetFirst()
			local mat=Duel.SelectFusionMaterial(tp,tc,cg,nil,tp)
			cg:Sub(mat)
			tc:SetMaterial(mat)
			Duel.DisableShuffleCheck()
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,true,POS_FACEUP)
			tc:CompleteProcedure()
		else break end
		hg=cg:Filter(Card.IsAbleToHand,nil)
		if hg:GetCount()==0 then hgchk=false end
		tg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,0,LOCATION_ONFIELD,nil)
		if tg:GetCount()==0 then tgchk=false end
		sg=Duel.GetMatchingGroup(cm.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,cg)
		if sg:GetCount()==0 then sgchk=false end
	end
	Duel.DisableShuffleCheck()
	Duel.SendtoGrave(cg,REASON_EFFECT+REASON_REVEAL)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(m,7))
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c)
		return c:IsLocation(LOCATION_EXTRA) and c:GetOriginalRace()&RACE_FAIRY==0
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function cm.costfilter(c)
	return c:GetOriginalRace()&RACE_FAIRY~=0 and c:IsAbleToRemoveAsCost()
end
function cm.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost()
		and Duel.IsExistingMatchingCard(cm.costfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,cm.costfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	g:AddCard(e:GetHandler())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function cm.thfilter(c)
	return c:IsSetCard(0x1091) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function cm.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and cm.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(cm.thfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,cm.thfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,tp,0)
end
function cm.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end