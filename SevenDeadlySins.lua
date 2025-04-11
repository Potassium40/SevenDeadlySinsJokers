SMODS.current_mod.optional_features = function()
    return {
        post_trigger = true
    }
end

--Creates an atlas for cards to use
SMODS.Atlas {
	-- Key for code to find it with
	key = "SevenDeadlySins",
	-- The name of the file, for the code to pull the atlas from
	path = "SevenDeadlySins.png",
	-- Width of each sprite in 1x size
	px = 71,
	-- Height of each sprite in 1x size
	py = 95
}


SMODS.Joker {
	key = 'greed',
	loc_txt = {
		name = 'Greed',
		text = {
			"When a hand is played,",
			"lose {C:money}2${}. This joker",
			"gains {C:money}4${} of sell value"
		}
	},
	
	rarity = 2,
	atlas = 'SevenDeadlySins',
	pos = { x = 0, y = 0 },
	cost = 4,

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra_value } }
	end,
	
	calculate = function(self, card, context)
		if context.before then
			card.ability.extra_value = card.ability.extra_value + 4
			card:set_cost()
			return {
				message = localize('k_val_up'),
				colour = G.C.MONEY,
				ease_dollars(-2),
			}
		end
	end
}

SMODS.Joker {
	key = 'gluttony',
	loc_txt = {
		name = 'Gluttony',
		text = {
			"Gains {C:chips}+#2#{} Chips",
			"for every other joker owned",
			"when scoring. Loses {C:chips}#3#{} Chips",
			"when selling a card.",
			"{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
		}
	},
	config = { extra = { chips = 0, chip_gain = 10, chip_loss = 50 } },
	rarity = 1,
	atlas = 'SevenDeadlySins',
	pos = { x = 1, y = 0 },
	cost = 5,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.chip_gain, card.ability.extra.chip_loss } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				chip_mod = card.ability.extra.chips,
				message = localize { type = 'variable', key = 'a_chips', vars = { card.ability.extra.chips } }
			}
		end
		if context.selling_card then
			if card.ability.extra.chips < card.ability.extra.chip_loss then
				card.ability.extra.chips = 0
			else
				card.ability.extra.chips = card.ability.extra.chips - card.ability.extra.chip_loss
			end
			return {
				message = "Chips lost!",
				colour = G.C.CHIPS,
				card = card
			}
		end
		if context.other_joker and not context.blueprint and context.other_joker ~= card then
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain
			return {
				message = 'Upgraded!',
				colour = G.C.CHIPS,
				card = card
			}
		end
	end
}


SMODS.Joker {
	key = 'lust',
	loc_txt = {
		name = 'Lust',
		text = {
			"All cards have a {C:green}#2# in #1#{} chance",
			"to be converted to {C:hearts}hearts{}",
			"when scored. When sold, create a",
			"{C:attention}Lusty Joker{}."
		}
	},
	config = { extra = { odds = 2 } },
	rarity = 3,
	atlas = 'SevenDeadlySins',
	pos = { x = 2, y = 0 },
	cost = 6,
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.j_lusty_joker
		return { vars = { card.ability.extra.odds, (G.GAME.probabilities.normal or 1) } }
	end,
	calculate = function(self, card, context)
		if context.individual then
			if context.cardarea == G.play then
				if pseudorandom('lust') < G.GAME.probabilities.normal/card.ability.extra.odds then
					local playedcard = context.other_card
					G.E_MANAGER:add_event(Event({
						func = function()
							playedcard:change_suit("Hearts")
							playedcard:juice_up()
							return true
						end
					}))
					return {
						message = "Lust",
						colour = G.C.RED
					}
				end
			end
		end
		if context.selling_self then
			SMODS.add_card{key = "j_lusty_joker"}
		end
	end
}

SMODS.Joker {
	key = 'wrath',
	loc_txt = {
		name = 'Wrath',
		text = {
			"{X:mult,C:white} X#1# {} Mult",
			"Loses {X:mult,C:white}X#2#{} Mult when buying",
			"a card, booster pack or voucher"
		}
	},
	config = { extra = { Xmult = 5, Xmult_loss = 0.5 } },
	rarity = 1,
	atlas = 'SevenDeadlySins',
	pos = { x = 3, y = 0 },
	cost = 4,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_loss } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult } },
				Xmult_mod = card.ability.extra.Xmult
			}
		end
		if context.buying_card or context.open_booster then
			if card.ability.extra.Xmult - card.ability.extra.Xmult_loss <= 1 then 
				G.E_MANAGER:add_event(Event({
					func = function()
						play_sound('tarot1')
						card.T.r = -0.2
						card:juice_up(0.3, 0.4)
						card.states.drag.is = true
						card.children.center.pinch.x = true
						G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.3, blockable = false,
							func = function()
									G.jokers:remove_card(card)
									card:remove()
									card = nil
								return true; end})) 
						return true
					end
				})) 
				return {
					message = "Wrath",
					colour = G.C.RED
				}
			else
				card.ability.extra.Xmult = card.ability.extra.Xmult - card.ability.extra.Xmult_loss
				return {
					message = "Wrath",
					colour = G.C.RED
				}
			end
		end
	end
}


SMODS.Joker {	
	key = 'sloth',
	loc_txt = {
		name = 'Sloth',
		text = {
			"{C:red}+#1#{} mult for each",
			"{C:blue}hand{} and {C:red}discard{} remaining."
		}
	},
	config = { extra = { mult = 4 } },
	rarity = 2,
	atlas = 'SevenDeadlySins',
	pos = { x = 4, y = 0 },
	cost = 7,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			local currentmult = G.GAME.current_round.discards_left * card.ability.extra.mult + G.GAME.current_round.hands_left * card.ability.extra.mult
			return {
				message = localize { type = 'variable', key = 'a_mult', vars = { currentmult } }
			}
		end
	end
}


SMODS.Joker {
	key = 'pride',
	loc_txt = {
		name = 'Pride',
		text = {
			"{X:mult,C:white} X#1# {} Mult",
			"Gains {X:mult,C:white}X1{} Mult when a blind",
			"is won in 1 hand. Reset when a blind",
			"is beaten in more than 1 hand"
		}
	},
	config = { extra = { Xmult = 1 } },
	rarity = 1,
	atlas = 'SevenDeadlySins',
	pos = { x = 5, y = 0 },
	cost = 4,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult } },
				Xmult_mod = card.ability.extra.Xmult
			}
		end
		if context.end_of_round and not context.repetition and context.game_over == false and not context.blueprint then
			if G.GAME.current_round.hands_played == 1 then
				card.ability.extra.Xmult = card.ability.extra.Xmult + 1
				return {
					message = "Upgraded!",
					colour = G.C.MULT
				}
			else
				card.ability.extra.Xmult = 1
				return {
					message = "Pride",
					colour = G.C.BLUE
				}
			end
		end
	end
}

SMODS.Joker {
	key = 'envy',
	loc_txt = {
		name = 'Envy',
		text = {
			"At the end of shop, if nothing was bought,",
			"create a {C:spectral}spectral{} card. Otherwise,",
			"create a {C:tarot}tarot{} and {C:planet}planet{} card.",
			"{C:inactive}(Must have room){}"
		}
	},
	config = { extra = { bought_cards = false } },
	rarity = 2,
	atlas = 'SevenDeadlySins',
	pos = { x = 0, y = 1 },
	cost = 6,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.bought_cards } }
	end,
	calculate = function(self, card, context)
		if context.buying_card or context.open_booster then
			card.ability.extra.bought_cards = true
		end
		if context.ending_shop then
			if card.ability.extra.bought_cards == false then
				if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
					G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
					G.E_MANAGER:add_event(Event({
						func = (function()
							G.E_MANAGER:add_event(Event({
								func = function() 
									local spectral = create_card('Spectral',G.consumeables, nil, nil, nil, nil, nil, 'envy')
									card:add_to_deck()
									G.consumeables:emplace(spectral)
									G.GAME.consumeable_buffer = 0
									return true
								end}))   
								card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_spectral'), colour = G.C.SPECTRAL})                       
							return true
						end)}))
				end
			else
				if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
					G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
					G.E_MANAGER:add_event(Event({
						func = (function()
							G.E_MANAGER:add_event(Event({
								func = function() 
									local tarot = create_card('Tarot',G.consumeables, nil, nil, nil, nil, nil, 'envy')
									card:add_to_deck()
									G.consumeables:emplace(tarot)
									G.GAME.consumeable_buffer = 0
									return true
								end}))   
								card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})                       
							return true
						end)}))
				end
				if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
					G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
					G.E_MANAGER:add_event(Event({
						func = (function()
							G.E_MANAGER:add_event(Event({
								func = function() 
									local planet = create_card('Planet',G.consumeables, nil, nil, nil, nil, nil, 'envy')
									card:add_to_deck()
									G.consumeables:emplace(planet)
									G.GAME.consumeable_buffer = 0
									return true
								end}))   
								card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_planet'), colour = G.C.PLANET})                       
							return true
						end)}))
				end
			end
		end
		if context.setting_blind then
			card.ability.extra.bought_cards = false
		end
	end
}