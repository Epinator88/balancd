--Hello reader! Thank you for downloading my mod! Listed here are some extra ideas that may or may not be added in the future.

--Joker "Oops! All 1's!" -- halved all odds (inverse of oops all 6's), would have to change every joker that had a probability
--Joker "Double Slit Joker" -- All playing cards will act as quantum cards
--Joker "Scorched Joker" -- If the joker is charred, then the chance a given card becomes charred becomes 100%
--Functionality for joker "Balatro", was meant to talk to you as you played.
--Joker "Cover-Up", every card is counted as first of hand, every card with an end-of-round effect is triggered every hand. Too similar to Labyrinth from Cryptid, never will be added.
--Joker "Banana Candy", sell the joker to get whatever stage of banana the run is currently on (gros michel / cavendish)
--Spectral Card "Devotion", select a joker to delete it, and after beating the boss blind, recieve it back with an edition. Too similar to Cryptid, will never be added.
--Voucher Pair "Investment and Economy" Lower how much money you need to get interest from $5 to $3 to $1
--Joker "Compound Interest", Money gotten is multiplied by 1.5x at end of round
--Joker "Negative Joker", +1 joker slot, so it's only useful if you have the negative joker with the negative edition. Too similar to Cryptid, so will probably never be added.
--Joker "Plug 'n Play", doubles all values in the joker immediately to the left of it. Kind of like Blueprint.
--Voucher pair "Raise and Bonus", each give minimum blind completion payout by 1 dollar (small blind goes from 3 dollars minimum -> 4 -> 5)
--Tag "Emperor Tag", creates two random tags.
--also, a voucher pair that raised the odds of a card charring, each individually doubling it. Cut content because i'm not drawing that many cards :sob:

--Feel free to try to code these ideas above! You don't even need to credit me I'm gonna be honest

--Have fun rooting through my putrid spaghetti!





--Creates Atlas for cards to use
SMODS.Atlas {
	key = "ModdedVanilla",
	path = "ModdedVanilla.png",
	px = 71,
	py = 95
}

SMODS.Atlas {
	key = "Voucher",
	path = "Voucher.png",
	px = 71,
	py = 95	
}

function CardArea:ep1n_remove_card(card, discarded_only)
    if not self.cards then return end
    local _cards = discarded_only and {} or self.cards
    if discarded_only then 
        for k, v in ipairs(self.cards) do
            if v.ability and v.ability.discarded then 
                _cards[#_cards+1] = v
            end
        end
    end
    if self.config.type == 'discard' or self.config.type == 'deck' then
        card = card or _cards[#_cards]
    else
        card = card or _cards[1]
    end
    for i = #self.cards,1,-1 do
        if self.cards[i] == card then
            card:remove_from_area()
            table.remove(self.cards, i)
            self:remove_from_highlighted(card, true)
            break
        end
    end
    self:set_ranks()
    if self == G.deck then check_for_unlock({type = 'modify_deck', deck = self}) end
    return card
end

function ep1n_remove_self(self)
    self.removed = true

    if self.area then G.jokers:ep1n_remove_card(self) end

    self:remove_from_deck()
    if self.ability.queue_negative_removal then 
        if self.ability.consumeable then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit - 1
        else
            G.jokers.config.card_limit = G.jokers.config.card_limit - 1
        end 
    end

    if not G.OVERLAY_MENU then
        for k, v in pairs(G.P_CENTERS) do
            if v.name == self.ability.name then
                if not next(find_joker(self.ability.name, true)) then 
                    G.GAME.used_jokers[k] = nil
                end
            end
        end
    end

    if G.playing_cards then
        for k, v in ipairs(G.playing_cards) do
            if v == self then
                table.remove(G.playing_cards, k)
                break
            end
        end
        for k, v in ipairs(G.playing_cards) do
            v.playing_card = k
        end
    end

    remove_all(self.children)

    for k, v in pairs(G.I.CARD) do
        if v == self then
            table.remove(G.I.CARD, k)
        end
    end
    Moveable.remove(self)
end

function ep1n_void_superpos(self)
	local dissolve_time = 0.7*(dissolve_time_fac or 1)
    self.dissolve = 0
    self.dissolve_colours = {G.C.PURPLE}
        or {G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.JOKER_GREY}
    if not no_juice then self:juice_up() end
    local childParts = Particles(0, 0, 0,0, {
        timer_type = 'TOTAL',
        timer = 0.01*dissolve_time,
        scale = 0.1,
        speed = 2,
        lifespan = 0.7*dissolve_time,
        attach = self,
        colours = self.dissolve_colours,
        fill = true
    })
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  0.7*dissolve_time,
        func = (function() childParts:fade(0.3*dissolve_time) return true end)
    }))
    if not silent then 
        G.E_MANAGER:add_event(Event({
            blockable = false,
            func = (function()
                    play_sound('whoosh2', math.random()*0.2 + 0.9,0.5)
                    play_sound('crumple'..math.random(1, 5), math.random()*0.2 + 0.9,0.5)
                return true end)
        }))
    end
    G.E_MANAGER:add_event(Event({
        trigger = 'ease',
        blockable = false,
        ref_table = self,
        ref_value = 'dissolve',
        ease_to = 1,
        delay =  1*dissolve_time,
        func = (function(t) return t end)
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  1.05*dissolve_time,
        func = (function() 
			ep1n_remove_self(self)
			return true end)
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        blockable = false,
        delay =  1.051*dissolve_time,
	}))
end

function ep1n_check_quantum(self, freshSetup) --self is the moved card, freshSetup is the new card layout
	if self.edition and self.edition.ep1n_quantum then
		local oldPos = 0
		for k, v in ipairs(G.GAME.lastSetup) do 
			if self.ability.name == v.ability.name and v.edition and v.edition.ep1n_quantum then oldPos = k end
		end
		local newPos = 0
		for k, v in ipairs(freshSetup) do 
			if self.ability.name == v.ability.name and v.edition and v.edition.ep1n_quantum then newPos = k end
		end
		if newPos < oldPos then oldPos = oldPos + 1 end
		if oldPos ~= newPos then
			card = copy_card(self, nil, nil, nil, nil)
			card:set_edition({ep1n_superpos = true}, true)
			table.insert(G.jokers.cards, oldPos, card)
			card:add_to_deck()
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Entangled!", colour = G.C.PURPLE})
			card:set_card_area(self)
		end
	end
	return freshSetup
end

G.FUNCS.ep1n_boss_tag_func = function(e)
	if not e.parent or not e.parent.states then return end
	if (e.states.hover.is or e.parent.states.hover.is) and (e.created_on_pause == G.SETTINGS.paused) and
	not e.parent.children.alert then
		local _sprite = e.config.ref_table:get_uibox_table()
		e.parent.children.alert = UIBox{
			definition = G.UIDEF.card_h_popup(_sprite),
			config = {align="tm", offset = {x = 0, y = -0.1},
			major = e.parent,
			instance_type = 'POPUP'},
		}
		_sprite:juice_up(0.05, 0.02)
		play_sound('paper1', math.random()*0.1 + 0.55, 0.42)
		play_sound('tarot2', math.random()*0.1 + 0.55, 0.09)
		e.parent.children.alert.states.collide.can = false
	elseif e.parent.children.alert and
	((not e.states.collide.is and not e.parent.states.collide.is) or (e.created_on_pause ~= G.SETTINGS.paused)) then
		e.parent.children.alert:remove()
		e.parent.children.alert = nil
	end
	local hasChicotCharge = false
	if G.jokers and G.jokers.cards then
		for k, v in ipairs(G.jokers.cards) do
			if v.ability.name == "Chicot" and v.ability.extra.charges > 0 then hasChicotCharge = true end
		end
	end
	if not hasChicotCharge then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	end
end

function ep1n_gen_boss_tag(blind_choice, run_info)
	blind_choice = 'Boss'
  G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
  --has to do with the actual blind objects in game.lua
  --figure out how to make a new random tag in tag.lua
  --random number 1 to #G.P_TAGS, and _tag = Tag(G.P_TAGS[that number]
  
  --now just blot out the sign if chicot isn't in G.jokers.cards
  local cap = 0
  for k, v in pairs(G.P_TAGS) do 
	cap = cap + 1
  end
  local tagNum = math.ceil(pseudorandom(pseudoseed('boss_tag')) * cap)
  local _tag
  if G.GAME.round_resets.blind_tags.Boss then 
	_tag = Tag(G.GAME.round_resets.blind_tags.Boss)
else 
  for k, v in pairs(G.P_TAGS) do 
	if v.order == tagNum then 
	 _tag = Tag(v.key)
	end
  end
  G.GAME.round_resets.blind_tags.Boss = _tag.key
  end
  if _tag.name == "Orbital Tag" and G.GAME.round_resets.ante == 1 then _tag = Tag('tag_rare') end--prevent crash
  if _tag.name == "Charm Tag" then _tag = Tag('tag_polychrome') end
  if _tag.name == "Ethereal Tag" then _tag = Tag('tag_negative') end
  if _tag.name == "Standard Tag" then _tag = Tag('tag_double') end
  if _tag.name == "Buffoon Tag" then _tag = Tag('tag_coupon') end
  if _tag.name == "Meteor Tag" then _tag = Tag('tag_juggle') end
  local _tag_ui, _tag_sprite = _tag:generate_UI()
  _tag_sprite.states.collide.can = not not run_info
  return 
  {n=G.UIT.R, config={id = 'tag_container', ref_table = _tag, align = "cm"}, nodes={
    {n=G.UIT.R, config={align = 'tm', minh = 0.65}, nodes={
      {n=G.UIT.T, config={text = localize('k_or'), scale = 0.55, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}},
    }},
      {n=G.UIT.R, config={id = 'tag_'..blind_choice, align = "cm", r = 0.1, padding = 0.1, minw = 1, can_collide = true, ref_table = _tag_sprite}, nodes={
        {n=G.UIT.C, config={id = 'tag_desc', align = "cm", minh = 1}, nodes={
          _tag_ui
        }},
        not run_info and {n=G.UIT.C, config={align = "cm", colour = G.C.UI.BACKGROUND_INACTIVE, minh = 0.6, minw = 2, maxw = 2, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'skip_blind', func = 'ep1n_boss_tag_func', ref_table = _tag}, nodes={
          {n=G.UIT.T, config={text = "Requires Chicot", scale = 0.4, colour = G.C.UI.TEXT_INACTIVE}}
        }} or {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, colour = mix_colours(G.C.BLUE, G.C.BLACK, 0.4), r = 0.1, maxw = 2}, nodes={
          {n=G.UIT.T, config={text = localize('b_skip_reward'), scale = 0.35, colour = G.C.WHITE}},
        }},
      }}
  }}
  end

function ep1n_eval_played(card, context)
	local text,disp_text,poker_hands,scoring_hand,non_loc_disp_text = G.FUNCS.get_poker_hand_info(G.play.cards)
	context = context or {cardarea = G.play, full_hand = G.play.cards, scoring_hand = scoring_hand, poker_hand = text}
	local ret = {}
	
	if context.repetition_only then
        local seals = card:calculate_seal(context)
        if seals then
            ret.seals = seals
        end
        return ret
    end
	
	local chips = card:get_chip_bonus()
	if chips > 0 then 
		ret.chips = chips
	end

	local mult = card:get_chip_mult()
	if mult > 0 then 
		ret.mult = mult
	end

	local x_mult = card:get_chip_x_mult(context)
	if x_mult > 0 then 
		ret.x_mult = x_mult
	end

	local p_dollars = card:get_p_dollars()
	if p_dollars > 0 then 
		ret.p_dollars = p_dollars
	end

	local jokers = card:calculate_joker(context)
	if jokers then 
		ret.jokers = jokers
	end

	local edition = card:get_edition(context)
	if edition then 
		ret.edition = edition
	end
	
	return ret
end

function ep1n_eval_held(card, context)
	local text,disp_text,poker_hands,scoring_hand,non_loc_disp_text = G.FUNCS.get_poker_hand_info(G.play.cards)
	context = context or {cardarea = G.hand, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands}
	local ret =  {}
	
	if context.repetition_only then
        local seals = card:calculate_seal(context)
        if seals then
            ret.seals = seals
        end
        return ret
    end
	
	local h_mult = card:get_chip_h_mult()
	if h_mult > 0 then 
		ret.h_mult = h_mult
	end

	local h_x_mult = card:get_chip_h_x_mult()
	if h_x_mult > 0 then 
		ret.x_mult = h_x_mult
	end

	local jokers = card:calculate_joker(context)
	if jokers then 
		ret.jokers = jokers
	end
	return ret
end

function full_hand_retrigger() 
	local text,disp_text,poker_hands,scoring_hand,non_loc_disp_text = G.FUNCS.get_poker_hand_info(G.play.cards)
	--each card and reps and jokers for each card and red seal
	--each held card and reps and joker for each card and red seal
	if not G.GAME.blind:debuff_hand(G.play.cards, poker_hands, text) then
		local percent = percent or 0.3
		local percent_delta = percent_delta or 0.08
		for i = 1, #scoring_hand do
			local reps = {1}
			
			local eval = ep1n_eval_played(scoring_hand[i], {repetition_only = true,cardarea = G.play, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, repetition = true})
			if next(eval) then 
				for h = 1, eval.seals.repetitions do
					reps[#reps+1] = eval
				end
			end
			for j=1, #G.jokers.cards do
				--calculate the joker effects
				local eval = eval_card(G.jokers.cards[j], {cardarea = G.play, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, other_card = scoring_hand[i], repetition = true})
				if next(eval) and eval.jokers then 
					for h = 1, eval.jokers.repetitions do
						reps[#reps+1] = eval
					end
				end
			end
			for rep = 1, #reps do
				percent = percent + percent_delta
				
				if reps[rep] ~= 1 then
					card_eval_status_text((reps[rep].jokers or reps[rep].seals).card, 'jokers', nil, nil, nil, (reps[rep].jokers or reps[rep].seals))
				end
				
				--calculate the hand effects
				local effects = {ep1n_eval_played(scoring_hand[i], {cardarea = G.play, full_hand = G.play.cards, scoring_hand = scoring_hand, poker_hand = text})}
				for k=1, #G.jokers.cards do
					--calculate the joker individual card effects
					local eval = G.jokers.cards[k]:calculate_joker({cardarea = G.play, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, other_card = scoring_hand[i], individual = true})
					if eval then 
						table.insert(effects, eval)
					end
				end
				for ii = 1, #effects do
					--If chips added, do chip add event and add the chips to the total
					if effects[ii].chips then 
						if effects[ii].card then juice_card(effects[ii].card) end
						hand_chips = mod_chips(hand_chips + effects[ii].chips)
						update_hand_text({delay = 0}, {chips = hand_chips})
						card_eval_status_text(scoring_hand[i], 'chips', effects[ii].chips, percent)
					end

					--If mult added, do mult add event and add the mult to the total
					if effects[ii].mult then 
						if effects[ii].card then juice_card(effects[ii].card) end
						mult = mod_mult(mult + effects[ii].mult)
						update_hand_text({delay = 0}, {mult = mult})
						card_eval_status_text(scoring_hand[i], 'mult', effects[ii].mult, percent)
					end

					--If play dollars added, add dollars to total
					if effects[ii].p_dollars then 
						if effects[ii].card then juice_card(effects[ii].card) end
						ease_dollars(effects[ii].p_dollars)
						card_eval_status_text(scoring_hand[i], 'dollars', effects[ii].p_dollars, percent)
					end

					--If dollars added, add dollars to total
					if effects[ii].dollars then 
						if effects[ii].card then juice_card(effects[ii].card) end
						ease_dollars(effects[ii].dollars)
						card_eval_status_text(scoring_hand[i], 'dollars', effects[ii].dollars, percent)
					end

					--Any extra effects
					if effects[ii].extra then 
						if effects[ii].card then juice_card(effects[ii].card) end
						local extras = {mult = false, hand_chips = false}
						if effects[ii].extra.mult_mod then mult =mod_mult( mult + effects[ii].extra.mult_mod);extras.mult = true end
						if effects[ii].extra.chip_mod then hand_chips = mod_chips(hand_chips + effects[ii].extra.chip_mod);extras.hand_chips = true end
						if effects[ii].extra.swap then 
							local old_mult = mult
							mult = mod_mult(hand_chips)
							hand_chips = mod_chips(old_mult)
							extras.hand_chips = true; extras.mult = true
						end
						if effects[ii].extra.func then effects[ii].extra.func() end
						update_hand_text({delay = 0}, {chips = extras.hand_chips and hand_chips, mult = extras.mult and mult})
						card_eval_status_text(scoring_hand[i], 'extra', nil, percent, nil, effects[ii].extra)
					end

					--If x_mult added, do mult add event and mult the mult to the total
					if effects[ii].x_mult then 
						if effects[ii].card then juice_card(effects[ii].card) end
						mult = mod_mult(mult*effects[ii].x_mult)
						update_hand_text({delay = 0}, {mult = mult})
						card_eval_status_text(scoring_hand[i], 'x_mult', effects[ii].x_mult, percent)
					end

					--calculate the card edition effects
					if effects[ii].edition then
						hand_chips = mod_chips(hand_chips + (effects[ii].edition.chip_mod or 0))
						mult = mult + (effects[ii].edition.mult_mod or 0)
						mult = mod_mult(mult*(effects[ii].edition.x_mult_mod or 1))
						update_hand_text({delay = 0}, {
							chips = effects[ii].edition.chip_mod and hand_chips or nil,
							mult = (effects[ii].edition.mult_mod or effects[ii].edition.x_mult_mod) and mult or nil,
						})
						card_eval_status_text(scoring_hand[i], 'extra', nil, percent, nil, {
							message = (effects[ii].edition.chip_mod and localize{type='variable',key='a_chips',vars={effects[ii].edition.chip_mod}}) or
									(effects[ii].edition.mult_mod and localize{type='variable',key='a_mult',vars={effects[ii].edition.mult_mod}}) or
									(effects[ii].edition.x_mult_mod and localize{type='variable',key='a_xmult',vars={effects[ii].edition.x_mult_mod}}),
							chip_mod =  effects[ii].edition.chip_mod,
							mult_mod =  effects[ii].edition.mult_mod,
							x_mult_mod =  effects[ii].edition.x_mult_mod,
							colour = G.C.DARK_EDITION,
							edition = true})
					end
				end
			end
		end
		--hre go held
		for i=1, #G.hand.cards do
			local reps = {1}
			local rep = 1
			while rep <= #reps do --THERE IS A REASON THIS IS NOT A FOR LOOP BE WARNED
			--^^^^^^^^^^^^^^^^^^ MUST BE A WHILE LOOP. NO IDK WHY.
				if reps[rep] ~= 1 then
					card_eval_status_text((reps[rep].jokers or reps[rep].seals).card, 'jokers', nil, nil, nil, (reps[rep].jokers or reps[rep].seals))
					percent = percent + percent_delta
				end

				--calculate the hand effects
				local effects = {ep1n_eval_held(G.hand.cards[i], {cardarea = G.hand, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands})}
				for k=1, #G.jokers.cards do
					--calculate the joker individual card effects
					local eval = G.jokers.cards[k]:calculate_joker({cardarea = G.hand, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, other_card = G.hand.cards[i], individual = true})
					if eval then 
						table.insert(effects, eval)
					end
				end
				if reps[rep] == 1 then 
					--Check for hand doubling

					--From Red seal
					local eval = ep1n_eval_held(G.hand.cards[i], {repetition_only = true, cardarea = G.hand, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, repetition = true, card_effects = effects})
					if next(eval) then 
						for h  = 1, eval.seals.repetitions do
							reps[#reps+1] = eval
						end
					end

					--From Joker
					for j=1, #G.jokers.cards do
						--calculate the joker effects
						local eval = eval_card(G.jokers.cards[j], {cardarea = G.hand, full_hand = G.play.cards, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, other_card = G.hand.cards[i], repetition = true, card_effects = effects})
						if next(eval) then 
							for h  = 1, eval.jokers.repetitions do
								reps[#reps+1] = eval
							end
						end
					end
				end

				for ii = 1, #effects do
					--if this effect came from a joker
					if effects[ii].card then
						mod_percent = true
						G.E_MANAGER:add_event(Event({
							trigger = 'immediate',
							func = (function() effects[ii].card:juice_up(0.7);return true end)
						}))
					end
					
					--If hold mult added, do hold mult add event and add the mult to the total
					
					--If dollars added, add dollars to total
					if effects[ii].dollars then 
						ease_dollars(effects[ii].dollars)
						card_eval_status_text(G.hand.cards[i], 'dollars', effects[ii].dollars, percent)
					end

					if effects[ii].h_mult then
						mod_percent = true
						mult = mod_mult(mult + effects[ii].h_mult)
						update_hand_text({delay = 0}, {mult = mult})
						card_eval_status_text(G.hand.cards[i], 'h_mult', effects[ii].h_mult, percent)
					end

					if effects[ii].x_mult then
						mod_percent = true
						mult = mod_mult(mult*effects[ii].x_mult)
						update_hand_text({delay = 0}, {mult = mult})
						card_eval_status_text(G.hand.cards[i], 'x_mult', effects[ii].x_mult, percent)
					end

					if effects[ii].message then
						mod_percent = true
						update_hand_text({delay = 0}, {mult = mult})
						card_eval_status_text(G.hand.cards[i], 'extra', nil, percent, nil, effects[ii])
					end
				end
				rep = rep + 1
			end
		end
	end
end

--we gots to put in the voochers 
--or else charring is practically useless, since it's so rare that it happens and you barely destroy cards
SMODS.Voucher { -- Ghost Pepper && Carolina Reaper: Double chance for cards to char
	key = "char_1",
	loc_txt = {
		name = "Ghost Pepper",
		text = { "Doubles chances for", "cards to char"}
	},
	atlas = "Voucher",
	pos = { x = 0, y = 0 },
	redeem = function(self, card)
		G.GAME.char_chance = G.GAME.char_chance / 2
	end
}

SMODS.Voucher { -- Ghost Pepper && Carolina Reaper: Double chance for cards to char
	key = "char_2",
	loc_txt = {
		name = "Carolina Reaper",
		text = { "Doubles chances for", "cards to char"}
	},
	atlas = "Voucher",
	pos = { x = 1, y = 0 },
	redeem = function(self, card)
		G.GAME.char_chance = G.GAME.char_chance / 2
	end
}

SMODS.Joker { -- Balatro -- Legendary -- 1X mult, increase by 1X every activation. Will learn to speak in another update.
	key = "balatro",
	loc_txt = {
		name = "Balatro",
		text = {
			"It's Jimbo!", "{X:mult,C:white} X#1# {} Mult, increases by", "{X:mult,C:white} X#2# {} on activation"
		}
	},
	config = { extra = { Xmult = 1, Xmult_gain = 1 } },
	rarity = 4,
	atlas = "ModdedVanilla",
	blueprint_compat = true,
	pos = { x = 1, y = 0 },
	soul_pos = { x = 0, y = 0 },
	cost = 10,
	loc_vars = function(self, info_queue, card) 
		return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_gain } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult,
			}
		end
		if context.after and not context.blueprint then
			card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain
			return {
				message = "Upgrade!",
				colour = G.C.RED,
				card = card
			} 
		end
	end
} 

SMODS.Joker { --Time Machine -- Uncommon -- Triggers a FULL HAND RETRIGGER when reaached in joker.main
	--G.C.PURPLE
	key = "retrigger",
	loc_txt = {
		name = "Time Machine",
		text = {
			"Triggers a {X:purple,C:white}FHR{}", "when activated"
		}
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 2, y = 0 },
	cost = 4,
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = {key = "j_ep1n_fhr", set = "Other"}
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Retrigger!", colour = G.C.PURPLE})
			full_hand_retrigger()
		end
	end
}	

SMODS.Joker { --The TARDIS -- Rare -- Does 3 full hand retriggers 
	key = "fart", --was originally meant to be roland the farter from history, but changed
	loc_txt = {
		name = "TARDIS",
		text = {
			"Triggers 3 {X:purple,C:white}FHR's{}", "when activated"
		}
	},
	config = { extra = { reps = 3 } },
	rarity = 3,
	atlas = "ModdedVanilla",
	pos = { x = 3, y = 0 },
	cost = 4,
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = {key = "j_ep1n_fhr", set = "Other"}
		return { vars = { card.ability.extra.reps } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Retrigger!", colour = G.C.PURPLE})
			full_hand_retrigger()
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Again!", colour = G.C.PURPLE})
			full_hand_retrigger()
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "One More!", colour = G.C.RED})
			full_hand_retrigger()
		end
	end
}

SMODS.Joker { --Coinflip -- Uncommon -- 1 in 2 chance to swap mult and chips when it is reached in the menu
	key = "flip",
	loc_txt = {
		name = "Coinflip",
		text = {
			"{C:green}#1# in #2#{} chance to", "swap {C:chips}chips{} and {C:mult}mult"
		}
	},
	config = { extra = { odds = 2 } },
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 4, y = 0 },
	cost = 4,
	loc_vars = function(self, info_queue, card)
		return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds} }
	end,
	calculate = function(self, card, context)
		if context.joker_main and
		pseudorandom(pseudoseed('coinflip')) < G.GAME.probabilities.normal/card.ability.extra.odds then
			store = mult 
			mult = hand_chips
			hand_chips = store
			update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Swap!", colour = G.C.FILTER})
		end
	end
}

SMODS.Joker { -- Food Stamps -- Uncommon -- If you have 0 dollars when leaving a shop, spawn a random Food card. (Fridge)
	key = "ebt",
	loc_txt = {
		name = "Food Stamps",
		text = {
			"When leaving a shop with {C:money}$0{}", "spawn a random {C:green}Food{} card"
		}
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 5, y = 0 },
	cost = 6,
	calculate = function(self, card, context)
		if context.ending_shop and #G.jokers.cards < G.jokers.config.card_limit and G.GAME.dollars <= 0 then
			herepossibleJokers = { "j_gros_michel", "j_ice_cream", "j_cavendish", "j_turtle_bean", "j_ramen", "j_diet_cola", "j_selzer", "j_popcorn"}
			pick = herepossibleJokers[math.floor(pseudorandom(pseudoseed('popeyes')) * 9 + .5)]
			card = create_card("Joker", G.jokers, nil, nil, nil, nil, pick)
			card:add_to_deck()
			G.jokers:emplace(card)
		end
	end
}

SMODS.Joker { -- Savings Account -- Rare -- If you go over the chips required to beat the blind, score those chips next blind.
	key = "savings",
	loc_txt = {
		name = "Savings Account",
		text = { "Overscored chips will {C:attention}store{} and", "{C:attention}carry over{} to the next blind", "{C:inactive, s:0.8} #1# chips stored" }
	},
	rarity = 3,
	config = { extra = { stored = 0 }, },
	atlas = "ModdedVanilla",
	pos = { x = 0, y = 1 },
	cost = 8,
	loc_vars = function(self, info_queue, card) 
		return { vars = { card.ability.extra.stored } }
	end,
	calculate = function(self, card, context)
		if context.end_of_round and G.GAME.chips > G.GAME.blind.chips and context.cardarea == G.jokers then
			card.ability.extra.stored = G.GAME.chips - G.GAME.blind.chips
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Stored!", colour = G.C.RED})
		end
		if context.setting_blind and card.ability.extra.stored ~= 0 then
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Deposited!", colour = G.C.RED})
			G.GAME.chips = G.GAME.chips + card.ability.extra.stored
			card.ability.extra.stored = 0
		end
	end
}

--G.GAME.char_chance = 1
SMODS.Joker { -- Scorched Joker -- Uncommon -- If this joker is Charred, increase the chance a card will become charred to 100%
	key = "scorched",
	loc_txt = {
		name = "Scorched Joker",
		text = { 
			"If this joker is {C:attention}charred{},", "set the chance a card {C:attention}chars to 100%", "Status: #2#"
		}
	},
	--dormant: ready to be activated
	--active: working
	--spent: not working, cannot be turned on again
	config = { extra = { store_chance = 0, status = "Dormant" } },
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 1, y = 1 },
	cost = 6,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.store_chance, card.ability.extra.status } }
	end,
	calculate = function(self, card, context)
		if card.ability.extra.status == "Dormant" and card.edition and card.edition.ep1n_charred and not context.selling_self then
			card.ability.extra.store_chance = G.GAME.char_chance
			card.ability.extra.status = "Active"
			G.GAME.char_chance = 1
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Active!", colour = G.C.RED})
		end
		if card.ability.extra.status == "Active" and context.selling_self then
			G.GAME.char_chance = card.ability.extra.store_chance
			card.ability.extra.status = "Spent"
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Spent!", colour = G.C.RED})
		end
		if card.ability.extra.status == "Active" and (not card.edition or (card.edition and not card.edition.ep1n_charred)) then
			G.GAME.char_chance = card.ability.extra.store_chance
			card.ability.extra.status = "Dormant"
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Disabled!", colour = G.C.RED})
		end
	end
}

SMODS.Joker { -- Burn Treatment -- Rare -- Unchars played cards.
	--override vampire to not work if the card is charred so this is the ONLY way to unchar cards
	key = "healing",
	loc_txt = {
		name = "Burn Treatment",
		text = {
			"{C:attention}Unchars{} played cards"
		}
	},
	rarity = 3,
	atlas = "ModdedVanilla",
	pos = { x = 2, y = 1 },
	cost = 10,
	calculate = function(self, card, context)
		if context.before then
			shouldTalk = false
			for _, c in ipairs(G.play.cards) do
				if c.edition and c.edition.ep1n_charred then 
					c:set_edition(nil) 
					shouldTalk = true
				end
			end
			if shouldTalk then
				card_eval_status_text(card, "extra", nil, nil, nil, {message = "Healed!", colour = G.C.GREEN})
			end
		end
	end
}

SMODS.Joker { --Min-Max -- Uncommon -- 2X Chips, 0.5X Mult.
	key = "minmax",
	loc_txt = {
		name = "Min-Max",
		text = {
			"{X:chips,C:white}2X{} {C:chips}Chips{}, {X:mult,C:white}0.5X{} {C:mult}Mult"
		}
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 3, y = 1 },
	cost = 7,
	calculate = function(self, card, context)
		if context.joker_main then
			hand_chips = hand_chips * 3
			mult = mult / 2
			update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Flipped!", colour = G.C.RED})
		end
	end
}

SMODS.Joker { --Synchronity -- Rare -- If the current ante is even, 4X mult.
	key = "even",
	loc_txt = {
		name = "Synchronity",
		text = { "If the current ante is {C:attention}even", "{C:white,X:mult}4X{} {C:mult}mult" }
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 4, y = 1 },
	cost = 8,
	calculate = function(self, card, context)
		if context.joker_main and G.GAME.round_resets.ante % 2 == 0 then
			return {
				xmult = 2
			}
		end
	end
}

SMODS.Joker { --Taxation -- Uncommon -- Takes 10% of chips every hand, needed to spawn Representation
	key = "taxes",
	loc_txt = {
		name = "Taxation",
		text = { "Takes {C:attention}10%{} of total {C:chips}chips",  "every hand. {C:mult}REQUIRED{} for", "{C:attention}Representation{} to show up in shops" }
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 5, y = 1 },
	cost = 6,
	calculate = function(self, card, context)
		if context.after then
			G.E_MANAGER:add_event(Event({
			  trigger = 'immediate',
			  blocking = false,
			  func = (function() G.GAME.chips = math.floor(G.GAME.chips * .9) return true end)
			}))
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Taxed!"})
		end
		if context.selling_self then
			print("test") --FIX LATER
			for _, j in ipairs(G.jokers.cards) do
				if j.ability.name == "j_ep1n_rep" then
					print("has rep")
					anticheat = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_ep1n_anticheat")
					anticheat:set_eternal(true)
					anticheat:add_to_deck()
					G.jokers:emplace(anticheat)
					G.jokers:align_cards()
				end
			end
		end
	end
}

SMODS.Joker { --Representation -- Rare -- 6X mult, only works with Taxation
	key = "rep",
	loc_txt = {
		name = "Representation",
		text = { "{C:white,X:mult}6X{} {C:mult}mult{}, can only", "be gotten with {C:attention}Taxation{}" }
	},
	rarity = 1,
	atlas = "ModdedVanilla",
	pos = { x = 0, y = 2 },
	cost = 1,
	calculate = function(self, card, context)
		if context.joker_main then 
			return { xmult = 6 }
		end
	end,
	in_pool = function(self, args)
		for _, j in ipairs(G.jokers.cards) do
			if j.ability.name == "Taxation" or j.ability.name == "j_ep1n_taxes" then
				return true
			end
		end
		return false
	end
}

SMODS.Joker { --Retaliation -- Common -- Takes 50% of chips every hand, spawns in w eternal sticker if Taxation is sold wihle holding Representation.
	key = "anticheat",
	loc_txt = {
		name = "Retaliation",
		text = { "{C:mult,s:1.4}You cheated...{}", "Takes {C:attention}50%{} of", "total {C:chips}chips every hand." }
	},
	rarity = 1,
	atlas = "ModdedVanilla",
	pos = { x = 1, y = 2 },
	cost = 20,
	calculate = function(self, card, context)
		if context.after then
			G.E_MANAGER:add_event(Event({
			  trigger = 'immediate',
			  blocking = false,
			  func = (function() G.GAME.chips = math.floor(G.GAME.chips * .5) return true end)
			}))
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Punished!"})
		end
	end,
	in_pool = function(self, args) 
		return false
	end
}

SMODS.Joker { --Negative Feedback Loop -- Uncommon -- Brings you 10% closer to the required chips for the blind, higher or lower.
	key = "neg",
	loc_txt = {
		name = "Negative Feedback Loop",
		text = {
			"Brings you 10% {C:attention}closer{} to the blind chips,", "{C:attention}higher or lower.{}"
		}
	},
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = {x = 2, y = 2},
	cost = 5,
	calculate = function(self, card, context)
		if context.after then
			G.E_MANAGER:add_event(Event({
				trigger = 'immediate',
				blocking = false,
				func = (function() G.GAME.chips = math.floor(G.GAME.chips + .1 * (G.GAME.blind.chips - G.GAME.chips)) return true end)
			}))
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Encroached!"})
		end
	end
}

SMODS.Joker { --Have and Eat -- Rare -- Whether you skip or play a blind, get the tag and go to the shop.
	key = "cake",
	loc_txt = {
		name = "Have and Eat",
		text = {
			"If you skip a blind, go to the shop", "If you play a blind, get the tag", "{C:inactive, s:0.8}Skipping Boss Blinds does nothing{}"
		}
	},
	config = { },
	rarity = 3,
	atlas = "ModdedVanilla",
	pos = {x = 3, y = 2},
	cost = 3,
	loc_vars = function(self, info_queue, card)
		return { vars = { } }
	end,
	calculate = function(self, card, context)
		if context.setting_blind then
			local tag = nil
			local type = G.GAME.blind:get_type()
			if type == "Small" then
				card_eval_status_text(card, "extra", nil, nil, nil, { message = "Tag!", colour = G.C.FILTER })
				tag = Tag(G.GAME.round_resets.blind_tags.Small)
			end
			if type == "Big" then
				card_eval_status_text(card, "extra", nil, nil, nil, { message = "Tag!", colour = G.C.FILTER })
				tag = Tag(G.GAME.round_resets.blind_tags.Big)
			end
			if type == "Boss" then
				card_eval_status_text(card, "extra", nil, nil, nil, { message = "Tag!", colour = G.C.FILTER })
				tag = Tag(G.GAME.round_resets.blind_tags.Boss)
			end
			if tag then add_tag(tag) end
		end
		if context.skip_blind then
			--set game state to shop
			--figure this out or just make have and eat only work for taking tags
			if G.GAME.blind_on_deck ~= 'Small' then
				G.E_MANAGER:add_event(Event({
					func = function()
						if G.blind_select then G.blind_select.alignment.offset.y = 40 end
						return true
					end
				}))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.2,
					func = function()
						for k, v in pairs(G.GAME.tags) do 
							if v.name == "Meteor Tag" or v.name == "Ethereal Tag" or v.name == "Standard Tag" or v.name == "Buffoon Tag" then return false end
						end
						if G.booster_pack ~= nil then return false end --booster pack compat
						G.STATE = G.STATES.SHOP 
						if G.blind_select then G.blind_select:remove()
						G.blind_select = nil end
						if G.blind_prompt_box then G.blind_prompt_box:remove() end
						G:update(G.real_dt) --fix ts in case of booster
						G.STATE_COMPLETE = false
						return true
					end,
					blockable = true
				}))
			end
			if G.GAME.blind_on_deck == 'Small' then
				card_eval_status_text(card, "extra", nil, nil, nil, { message = "Too Strong!", colour = G.C.RED })
			end
		end
	end
}

SMODS.Joker { -- Glass Ceiling -- Uncommon -- If the hand will immediately beat the round, then break the glass ceiling and 3x mult from now on
	key = "ceiling",
	loc_txt = {
		name = "Glass Ceiling",
		text = {
			"If blind beaten in one hand", "break the ceiling and permanently get {X:mult,C:white}X#1#{} mult", "Status: #2#"
		}
	},
	config = { extra = { Xmult = 3, Status = "Intact" } },
	rarity = 2,
	atlas = "ModdedVanilla",
	pos = { x = 4, y = 2},
	cost = 5,
	loc_vars = function(self, info_queue, card) 
		return { vars = { card.ability.extra.Xmult, card.ability.extra.Status } }
	end,
	calculate = function(self, card, context)
		if context.final_scoring_step then 
			if hand_chips * mult >= G.GAME.blind.chips then --hand chips beat blind instantly
				card.ability.extra.Status = "Broken" --maybe make this another Joker for diff texture
				card_eval_status_text(card, "extra", nil, nil, nil, {message = "Shattered!", colour = G.C.FILTER })
				--also maybe glass sfx
			end
		end
		if context.joker_main and card.ability.extra.Status == "Broken" then
			return {
				xmult = card.ability.extra.Xmult
			}
		end
	end
}

SMODS.Joker { --Fridge -- Uncommon -- Each food joker now takes three times as long to degrade.
	key = "fridge", --for some reason when you do ability.name it returns as j_(prefix in json)_(this key) and not the actual name so yeah!!! fun!!!
	loc_txt = {
		name = "Fridge",
		text = {
			"Preserves all food Jokers", "tripling their lifespan"
		}
	},
	config = { extra = { Base = 3, IceCreamTally = 2, PopcornTally = 2, PopcornTrigger = 0, TurtleBeanTally = 2, TurtleBeanTrigger = 0, SeltzerTally = 2, MichaelTally = 2, MichaelStatus = 0, MichaelTrigger = 0, CavvyTally = 2, CavvyStatus = 0, CavvyTrigger = 0, SodaTally = 2, ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge = 2} },
	--God, forgive me for what I'm about to do
	rarity = 2,
	atlas = "ModdedVanilla",
	blueprint_compat = false, --idk how to code this, if someone feels like doing it i'll update it but rn its like 3am and i js wanna go to sleep ;_;
	--also this joker is INSANELY broken if you get turtle bean and then immediately sell fridge, free extra 5 hand size that i canNOT figure out how to patch (send help)
	--if you're reading this right now, get up and stretch
	pos = { x = 5, y = 2 },
	cost = 4,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Base, card.ability.extra.IceCreamTally, card.ability.extra.PopcornTally, card.ability.extra.PopcornTrigger, card.ability.extra.TurtleBeanTally, card.ability.extra.TurtleBeanTrigger, card.ability.extra.SeltzerTally, card.ability.extra.MichaelTally, card.ability.extra.MichaelStatus, card.ability.extra.MichaelTrigger, card.ability.extra.CavvyTally, card.ability.extra.CavvyStatus, card.ability.extra.CavvyTrigger, card.ability.extra.SodaTally, card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge} }
	end, --lmao
	calculate = function(self, card, context)
		if not context.blueprint then
			if card.ability.extra.Base == nil then card.ability.extra.Base = 3 end
			if card.ability.extra.PopcornTrigger == nil then card.ability.extra.PopcornTrigger = 0 end
			if card.ability.extra.TurtleBeanTrigger == nil then card.ability.extra.TurtleBeanTrigger = 0 end
			if card.ability.extra.MichaelTrigger == nil then card.ability.extra.MichaelTrigger = 0 end
			if card.ability.extra.CavvyTrigger == nil then card.ability.extra.CavvyTrigger = 0 end
			if context.joker_main then --before joker activation, for ice cream and for seltzer
				cardarea = G.jokers.cards
				for k, v in ipairs(cardarea) do
					if v.ability.name == "Ice Cream" then
						if card.ability.extra.IceCreamTally == nil then card.ability.extra.IceCreamTally = 2 end
						if card.ability.extra.IceCreamTally > 0 then
							v.ability.extra.chip_mod = 0
							card.ability.extra.IceCreamTally = card.ability.extra.IceCreamTally - 1
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Preserved!", colour = G.C.FILTER})
						elseif card.ability.extra.IceCreamTally == 0 then
							v.ability.extra.chip_mod = 5
							card.ability.extra.IceCreamTally = (card.ability.extra.Base - 1 or 3)
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Expired!", colour = G.C.RED})
						end --sorry
					elseif v.ability.name == "Seltzer" then
						if card.ability.extra.SeltzerTally == nil then card.ability.extra.SeltzerTally = 2 end
						if card.ability.extra.SeltzerTally > 0 then
							v.ability.extra = v.ability.extra + 1
							card.ability.extra.SeltzerTally = card.ability.extra.SeltzerTally - 1
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Preserved!", colour = G.C.FILTER})
						elseif card.ability.extra.SeltzerTally == 0 then
							card.ability.extra.SeltzerTally = (card.ability.extra.Base - 1 or 3)
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Expired!", colour = G.C.RED})
						end
					end
				end
			end
			if context.end_of_round then --for popcorn and turtle bean, at end of round
				for k, v in ipairs(G.jokers.cards) do 
					if v.ability.name == "Popcorn" and card.ability.extra.PopcornTrigger == 0 then
						if card.ability.extra.PopcornTally == nil then card.ability.extra.PopcornTally = 2 end
						if card.ability.extra.PopcornTally > 0 then
							v.ability.extra = 0
							card.ability.extra.PopcornTally = card.ability.extra.PopcornTally - 1
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Preserved!", colour = G.C.FILTER})
							card.ability.extra.PopcornTrigger = 1 --idk why this needs to exist but if it doesn't then fridge procs on popcorn like 15 times
						elseif card.ability.extra.PopcornTally == 0 then
							v.ability.extra = 4
							card.ability.extra.PopcornTally = (card.ability.extra.Base - 1 or 3)
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Expired!", colour = G.C.RED})
							card.ability.extra.PopcornTrigger = 1
						end
					elseif v.ability.name == "Turtle Bean" and card.ability.extra.TurtleBeanTrigger == 0 then
						if card.ability.extra.TurtleBeanTally == nil then card.ability.extra.TurtleBeanTally = 2 end
						if card.ability.extra.TurtleBeanTally > 0 then
							v.ability.extra.h_mod = 0
							card.ability.extra.TurtleBeanTally = card.ability.extra.TurtleBeanTally - 1
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Preserved!", colour = G.C.FILTER})
							card.ability.extra.TurtleBeanTrigger = 1
						elseif card.ability.extra.TurtleBeanTally == 0 then
							v.ability.extra.h_mod = 1
							card.ability.extra.TurtleBeanTally = (card.ability.extra.Base - 1 or 3)
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Expired!", colour = G.C.RED})
							card.ability.extra.TurtleBeanTrigger = 1
						end
					elseif v.ability.name == "Gros Michel" then --see below for specifics on how banana status is stored
						--still there at end of round so turn off
						card.ability.extra.MichaelStatus = 0
					elseif v.ability.name == "Cavendish" then --again see below
						card.ability.extra.CavvyStatus = 0
					end --now check if michael or cavvy are gone (will not preserve editions so i have another thing to fix!) (dgaf lmfao)
				end
				if card.ability.extra.MichaelStatus == 1 and card.ability.extra.MichaelTally > 0 then 
					local banana = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_gros_michel")
					banana:add_to_deck()
					G.jokers:emplace(banana)
					card.ability.extra.MichaelTally = card.ability.extra.MichaelTally - 1
					card.ability.extra.MichaelStatus = 0
					card_eval_status_text(banana, "extra", nil, nil, nil, {message = "Preserved!", colour = G.C.FILTER})
				end
				if card.ability.extra.CavvyStatus == 1 and card.ability.extra.CavvyTally > 0 then 
					local banana = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_cavendish")
					banana:add_to_deck()
					G.jokers:emplace(banana)
					card.ability.extra.MichaelTally = card.ability.extra.MichaelTally - 1
					card.ability.extra.CavvyStatus = 0 --broken i think?
					card_eval_status_text(banana, "extra", nil, nil, nil, {message = "Preserved!", colour = G.C.FILTER})
				end
			end
			if context.discard then --ramen (works first try yay)
				for k, v in ipairs(G.jokers.cards) do
					if v.ability.name == "Ramen" then
						if card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge == nil then card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge = 2 end
						if card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge > 0 then
							v.ability.extra = 0
							card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge = card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge - 1
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Preserved!", colour = G.C.FILTER})
						elseif card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge == 0 then
							v.ability.extra = 0.01
							card.ability.extra.ObscenelyLongVariableNameThatCorrelatesToTheAmountOfTimesThatTheRamenJokerFeaturedInTheHitDeckBuilderRoguelikeBalatroCanBePreservedThatMeaningTheAmountOfTimesThatTheJokersDegredationAbilityWillNotTriggerByThisModsNewFunctioningJokerTheFridge = (card.ability.extra.Base - 1 or 3)
							card_eval_status_text(v, "extra", nil, nil,nil, {message = "Expired!", colour = G.C.RED})
						end
					end
				end
			end
			if context.setting_blind then
				card.ability.extra.PopcornTrigger = 0
				card.ability.extra.TurtleBeanTrigger = 0
				card.ability.extra.MichaelTrigger = 0
				card.ability.extra.CavvyTrigger = 0
				for k, v in ipairs(G.jokers.cards) do --stores 1 if gros and cavvy are there
					if v.ability.name == "Gros Michel" then card.ability.extra.MichaelStatus = 1 end
					if v.ability.name == "Cavendish" then card.ability.extra.CavvyStatus = 1 end
				end
			end
			if context.selling_card and card.ability.extra.SodaTally > 0 then
				if context.card.ability.name == "Diet Cola" then
					local soda = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_diet_cola") --j diet cola might be wrong
					soda:add_to_deck()
					G.jokers:emplace(soda)
					card_eval_status_text(soda, "extra", nil, nil, nil, {message = "Preserved!", colour = G.C.FILTER})
					card.ability.extra.SodaTally = card.ability.extra.SodaTally - 1
				end
			end
			if selling_self or context.selling_self then
				for k, v in ipairs(G.jokers.cards) do 
					if v.ability.name == "Ice Cream" then v.ability.extra.chip_mod = 5 end
					if v.ability.name == "Popcorn" then v.ability.extra = 4 end
					if v.ability.name == "Turtle Bean" then v.ability.extra.h_mod = 1 end
					if v.ability.name == "Ramen" then v.ability.extra = 0.01 end
				end
			end
		end
	end
}

SMODS.Shader({ key = "quantum", path = "quantum.fs", 
	send_vars = function(sprite, card)
		return {
			u_time = G.TIMERS.REAL
		}
	end
})

SMODS.Edition({
    key = "quantum",
    loc_txt = {
        name = "Quantum",
        label = "Quantum",
        text = {
            "JOKER: When rearranging this Joker,", "leave behind a superpos copy", "CARD: If played, create a clone in hand", "If in hand, play a clone"
        }
    },
    shader = "quantum",
    discovered = true,
    unlocked = true,
    config = {},
    in_shop = true,
    weight = 8,
    extra_cost = 6,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = { } }
    end
})

SMODS.Shader({ key = "superpos", path = "superpos.fs",
	send_vars = function(sprite, card)
		return {
			u_time = G.TIMERS.REAL
		}
	end
})

SMODS.Edition({ --the EYE blind will prevent these from being made -- maybe not past me
    key = "superpos",
    loc_txt = {
        name = "Superposition",
        label = "Superposition",
        text = {
            "A copy of a Quantum card", "JOKER: Destroyed if moved", "CARD: Destroyed upon opening deck menu"
        }
    },

    shader = "superpos",
    discovered = true,
    unlocked = true,
    config = {},
    in_shop = false,
	on_apply = function(card) 
		card.cost = 0
	end,
    weight = 4,
    extra_cost = 6,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = { } }
    end,
})

SMODS.Shader({ key = "charred", path = "charred.fs",
	send_vars = function(sprite, card)
		return {
			u_time = G.TIMERS.REAL
		}
	end
})

SMODS.Edition({
    key = "charred",
    loc_txt = {
        name = "Charred",
        label = "Charred",
        text = {
            "{C:dark_edition,E:1}But it refused...", "{C:inactive,s:0.85}All cards have a {C:green,s:0.85}#1#/#2#{C:inactive,s:0.85} chance to{}", "{C:inactive,s:0.85}Char instead of being destroyed{}"
        }
    },
    shader = "charred",
	config = {},
    discovered = true,
    unlocked = true,
    config = {},
    in_shop = false,
    weight = 0,
    extra_cost = 6,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = { G.GAME.probabilities.normal, G.GAME.char_chance } }
    end,
})

SMODS.Joker:take_ownership('chicot', { --Chicot REWORK: Legendary -- Makes Chicot allow you to skip up to 2 boss blinds in a row. Skipped boss blinds do not up ante.
	loc_txt = {
		name = "Chicot",
		text = {
			"Allows skipping up to {C:attention}2{}", "consecutive Boss Blinds, skipping a", "Boss Blind will not raise ante", "{C:inactive}(#1# charge(s) left){}"
		}
	},
	config = { extra = { charges = 2, trigger = 0 } },
	loc_vars = function(self, info_queue, card) 
		return { vars = { card.ability.extra.charges, card.ability.extra.trigger } }
	end,
	calculate = function(self, card, context)
		--check for decrement in charge if Skipped
		--check for replenishing of charge if beaten
		if context.skip_blind and G.GAME.blind_on_deck == 'Small' then --skipped boss
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "-1", colour = G.C.RED})
			card.ability.extra.charges = card.ability.extra.charges - 1
		end
		if context.setting_blind then 
			card.ability.extra.trigger = 0
		end
		if context.end_of_round and G.GAME.blind_on_deck == 'Boss' and card.ability.extra.trigger == 0 then --beat boss
			card_eval_status_text(card, "extra", nil, nil, nil, {message = "Recharged!", colour = G.C.FILTER})
			card.ability.extra.charges = 2
			card.ability.extra.trigger = 1
		end
	end
	}, false
)