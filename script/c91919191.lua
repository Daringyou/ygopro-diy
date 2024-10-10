--圣骑士之灵
--scripted by 浅望
--2024/10/06 01:17:39
local s, id, o = GetID()
s.name = "圣骑士之灵"
function s.initial_effect(c)
	--超量召唤
	aux.AddXyzProcedure(c, aux.FilterBoolFunction(Card.IsRace, RACE_WARRIOR), 4, 2)
	c:EnableReviveLimit()
	--
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--装备魔法卡作为超量素材也能适用效果
	if not s.EquipCheck then
		s.EquipCheck = true
		_RegisterEffect = Card.RegisterEffect
		Card.RegisterEffect = function(tc, e, bool)
			local res = _RegisterEffect(tc, e, bool)
			if e:GetType() & EFFECT_TYPE_EQUIP > 0 then
				local ce = e:Clone()
				ce:SetType(EFFECT_TYPE_XMATERIAL)
				_RegisterEffect(tc, ce, bool)
			end
			return res
		end
		
	end
end
function s.filter(c)
	return c:IsLevelBelow(4) and c:IsRace(RACE_WARRIOR) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
