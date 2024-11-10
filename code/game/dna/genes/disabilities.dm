/////////////////////
// DISABILITY GENES
//
// These activate either a mutation, disability
//
// Gene is always activated.
/////////////////////

/datum/dna/gene/disability
	name = "DISABILITY"

	/// Activation message
	var/list/activation_message

	/// Yay, you're no longer growing 3 arms
	var/list/deactivation_message


/datum/dna/gene/disability/can_activate(mob/living/mutant, flags)
	return TRUE // Always set!


/datum/dna/gene/disability/activate(mob/living/mutant, flags)
	. = ..()
	if(length(activation_message))
		var/msg = pick(activation_message)
		to_chat(mutant, span_warning("[msg]"))
	else
		testing("[name] has no activation message.")


/datum/dna/gene/disability/deactivate(mob/living/mutant, flags)
	. = ..()
	if(length(deactivation_message))
		var/msg = pick(deactivation_message)
		to_chat(mutant, span_warning("[msg]"))
	else
		testing("[name] has no deactivation message.")


/datum/dna/gene/disability/hallucinate
	name = "Hallucinate"
	activation_message = list("Ваш разум говорит: «Привет!».")
	deactivation_message = list("Здравомыслие возвращается. Или нет?")
	instability = -GENE_INSTABILITY_MODERATE


/datum/dna/gene/disability/hallucinate/New()
	..()
	block = GLOB.hallucinationblock


/datum/dna/gene/disability/hallucinate/OnMobLife(mob/living/carbon/human/H)
	if(prob(1))
		H.AdjustHallucinate(45 SECONDS)
		H.last_hallucinator_log = "Hallucination Gene"


/datum/dna/gene/disability/epilepsy
	name = "Epilepsy"
	activation_message = list("У вас разболелась голова.")
	deactivation_message = list("Ваша голова перестала болеть. Наконец-то!")
	instability = -GENE_INSTABILITY_MODERATE


/datum/dna/gene/disability/epilepsy/New()
	..()
	block = GLOB.epilepsyblock


/datum/dna/gene/disability/epilepsy/OnMobLife(mob/living/carbon/human/H)
	if((prob(1) && H.AmountParalyzed() < 2 SECONDS))
		H.visible_message(span_danger("[H] начина[pluralize_ru(H.gender, "ет", "ют")] биться в припадке!"), span_alert("У вас припадок!"))
		H.Paralyse(20 SECONDS)
		H.Jitter(2000 SECONDS)


/datum/dna/gene/disability/cough
	name = "Coughing"
	activation_message = list("Вы начинаете кашлять.")
	deactivation_message = list("Ваше горло перестало болеть.")
	instability = -GENE_INSTABILITY_MINOR


/datum/dna/gene/disability/cough/New()
	..()
	block = GLOB.coughblock


/datum/dna/gene/disability/cough/OnMobLife(mob/living/carbon/human/H)
	if((prob(5) && H.AmountParalyzed() <= 2 SECONDS))
		H.drop_from_active_hand()
		H.emote("cough")


/datum/dna/gene/disability/clumsy
	name = "Clumsiness"
	activation_message = list("Вы чувствуете лёгкое головокружение.")
	deactivation_message = list("Вы вновь обретаете контроль над своими движениями.")
	instability = -GENE_INSTABILITY_MINOR
	traits_to_add = list(TRAIT_CLUMSY)


/datum/dna/gene/disability/clumsy/New()
	..()
	block = GLOB.clumsyblock


/datum/dna/gene/disability/tourettes
	name = "Tourettes"
	activation_message = list("Нахлынула какая-то непонятная дрожь...")
	deactivation_message = list("Вы чувствуете вкус мыла во рту.")
	instability = -GENE_INSTABILITY_MODERATE


/datum/dna/gene/disability/tourettes/New()
	..()
	block = GLOB.twitchblock


/datum/dna/gene/disability/tourettes/OnMobLife(mob/living/carbon/human/H)
	if((prob(10) && H.AmountParalyzed() <= 2 SECONDS))
		H.Stun(20 SECONDS)
		switch(rand(1, 3))
			if(1)
				H.emote("twitch")
			if(2 to 3)
				H.say("[prob(50) ? ";" : ""][pick("ГОВНО", "МОЧА", "БЛЯТЬ", "ПИЗДА", "ХУЕСОС", "ВЫБЛЯДОК", "ХУЙ", "ХОС ХУЕСОС", "СУКА", "ПОШЁЛ НАХУЙ", "ХЕРНЯ", "КОКПИТАН", "ДОЛБАЁБ", "ЕБЛЯ", "НАМ ПИЗДА")]")
		var/x_offset_old = H.pixel_x
		var/y_offset_old = H.pixel_y
		var/x_offset = H.pixel_x + rand(-2, 2)
		var/y_offset = H.pixel_y + rand(-1, 1)
		animate(H, pixel_x = x_offset, pixel_y = y_offset, time = 1)
		animate(H, pixel_x = x_offset_old, pixel_y = y_offset_old, time = 1)


/datum/dna/gene/disability/nervousness
	name = "Nervousness"
	activation_message = list("Вы начинаете нервничать.")
	deactivation_message = list("Вы чувствуете себя гораздо спокойнее.")


/datum/dna/gene/disability/nervousness/New()
	..()
	block = GLOB.nervousblock


/datum/dna/gene/disability/nervousness/OnMobLife(mob/living/carbon/human/H)
	if(prob(10))
		H.Stuttering(20 SECONDS)


/datum/dna/gene/disability/blindness
	name = "Blindness"
	activation_message = list("Видимо, вы больше ничего не видите.")
	deactivation_message = list("Теперь вы можете видеть, если вдруг не заметили...")
	instability = -GENE_INSTABILITY_MAJOR
	traits_to_add = list(TRAIT_BLIND)


/datum/dna/gene/disability/blindness/New()
	..()
	block = GLOB.blindblock


/datum/dna/gene/disability/blindness/activate(mob/living/mutant, flags)
	. = ..()
	mutant.update_blind_effects()


/datum/dna/gene/disability/blindness/deactivate(mob/living/mutant, flags)
	. = ..()
	mutant.update_blind_effects()


/datum/dna/gene/disability/colourblindness
	name = "Colourblindness"
	activation_message = list("Вы чувствуете странное покалывание в глазах. Ваше восприятие цвета меняется.")
	deactivation_message = list("Вы чувствуете неприятное покалывание в глазах, но все вокруг вновь обрело краски.")
	instability = -GENE_INSTABILITY_MODERATE
	traits_to_add = list(TRAIT_COLORBLIND)


/datum/dna/gene/disability/colourblindness/New()
	..()
	block = GLOB.colourblindblock


/datum/dna/gene/disability/colourblindness/activate(mob/living/mutant, flags)
	. = ..()
	mutant.update_client_colour()	//Handle the activation of the colourblindness on the mob.
	mutant.update_misc_effects()	//Apply eyeshine as needed.


/datum/dna/gene/disability/colourblindness/deactivate(mob/living/carbon/human/mutant, flags)
	. = ..()
	mutant.update_client_colour()	//Handle the deactivation of the colourblindness on the mob.
	mutant.update_misc_effects()	//Remove eyeshine as needed.


/datum/dna/gene/disability/deaf
	name = "Deafness"
	activation_message = list("Здесь как-то тихо...")
	deactivation_message = list("Вы снова можете слышать!")
	instability = -GENE_INSTABILITY_MAJOR
	traits_to_add = list(TRAIT_DEAF)


/datum/dna/gene/disability/deaf/New()
	..()
	block = GLOB.deafblock


/datum/dna/gene/disability/nearsighted
	name = "Nearsightedness"
	activation_message = list("Всё вокруг начинает размываться...")
	deactivation_message = list("Теперь вы можете ясно видеть.")
	instability = -GENE_INSTABILITY_MODERATE
	traits_to_add = list(TRAIT_NEARSIGHTED)


/datum/dna/gene/disability/nearsighted/New()
	..()
	block = GLOB.glassesblock


/datum/dna/gene/disability/nearsighted/activate(mob/living/mutant, flags)
	. = ..()
	mutant.update_nearsighted_effects()


/datum/dna/gene/disability/nearsighted/deactivate(mob/living/mutant, flags)
	. = ..()
	mutant.update_nearsighted_effects()


/datum/dna/gene/disability/lisp
	name = "Lisp"
	desc = "Интерефно, фто это делает."
	activation_message = list("Фто-то тошно не тах.")
	deactivation_message = list("Теперь вы можете произносить согласные.")


/datum/dna/gene/disability/lisp/New()
	..()
	block = GLOB.lispblock


/datum/dna/gene/disability/lisp/OnSay(mob/M, message)
	return replacetext(message,"с",pick("щ","ш","ф"))


/datum/dna/gene/disability/comic
	name = "Comic"
	desc = "Это принесет только смерть и разрушение."
	activation_message = list(span_sans("Ой-йо!"))
	deactivation_message = list("Слава Святой Хонкоматери, с этим покончено.")
	traits_to_add = list(TRAIT_COMIC)


/datum/dna/gene/disability/comic/New()
	..()
	block = GLOB.comicblock


/datum/dna/gene/disability/wingdings
	name = "Alien Voice"
	desc = "Искажает голос субъекта, превращая его в непонятную речь."
	activation_message = list("✡︎□︎◆︎❒︎ ❖︎□︎♍︎♋︎●︎ ♍︎□︎❒︎♎︎⬧︎ ⬧︎♏︎♏︎❍︎ ♋︎●︎♓︎♏︎■︎📬︎") // Your vocal cords seem alien.
	deactivation_message = list("Ваши голосовые связки больше не кажутся инородными.")
	instability = -GENE_INSTABILITY_MINOR
	traits_to_add = list(TRAIT_WINGDINGS)


/datum/dna/gene/disability/wingdings/New()
	..()
	block = GLOB.wingdingsblock


/datum/dna/gene/disability/wingdings/OnSay(mob/M, message)
	var/garbled_message = ""
	var/i = 1
	while(i <= length(message))
		var/char = lowertext(message[i])
		if(char in GLOB.alphabet)
			if(prob(50)) // upper and lowercase chars have different symbols, we encrypt the word and mix them up
				garbled_message += pick(GLOB.alphabet_uppercase)
			else
				garbled_message += pick(GLOB.alphabet)
		else if(char in GLOB.alphabet_cyrillic)
			if(prob(50))
				garbled_message += pick(GLOB.alphabet_uppercase)
			else
				garbled_message += pick(GLOB.alphabet)
			i++ // rus chars coded by 2 bytes, so we need to skip one byte when encrypting them
		else
			garbled_message += message[i]
		i++
	message = garbled_message
	return message


/datum/dna/gene/disability/weak
	name = "Weak"
	desc = "Делает мышцы субъекта более слабыми."
	activation_message = list("Вы чувствуете внезапную слабость в мышцах.")
	deactivation_message = list("Вы снова ощущаете силу в мышцах.")
	instability = -GENE_INSTABILITY_MODERATE
	traits_to_add = list(TRAIT_GENE_WEAK)


/datum/dna/gene/disability/weak/New()
	..()
	block = GLOB.weakblock


/datum/dna/gene/disability/weak/can_activate(mob/living/mutant, flags)
	if(!ishuman(mutant) || HAS_TRAIT(mutant, TRAIT_GENE_STRONG))
		return FALSE
	return ..()


/datum/dna/gene/disability/weak/activate(mob/living/carbon/human/mutant, flags)
	. = ..()
	RegisterSignal(mutant, COMSIG_HUMAN_SPECIES_CHANGED, PROC_REF(on_species_change))
	add_weak_modifiers(mutant)


/datum/dna/gene/disability/weak/deactivate(mob/living/carbon/human/mutant, flags)
	. = ..()
	UnregisterSignal(mutant, COMSIG_HUMAN_SPECIES_CHANGED)
	remove_weak_modifiers(mutant)


/datum/dna/gene/disability/weak/proc/on_species_change(mob/living/carbon/human/mutant, datum/species/old_species)
	SIGNAL_HANDLER

	if(old_species.name != mutant.dna.species.name)
		remove_weak_modifiers(mutant, old_species)
		add_weak_modifiers(mutant)


/datum/dna/gene/disability/weak/proc/add_weak_modifiers(mob/living/carbon/human/mutant)
	mutant.physiology.tail_strength_mod *= 0.75
	switch(mutant.dna.species.name)
		if(SPECIES_VULPKANIN, SPECIES_DRASK, SPECIES_UNATHI)
			mutant.physiology.grab_resist_mod *= 0.75
			mutant.physiology.punch_damage_low -= 3
			mutant.physiology.punch_damage_high -= 4
		if(SPECIES_HUMAN)
			mutant.physiology.grab_resist_mod *= 0.9
			mutant.physiology.punch_damage_low -= 1
			mutant.physiology.punch_damage_high -= 2
		else
			mutant.physiology.grab_resist_mod *= 0.85
			mutant.physiology.punch_damage_low -= 2
			mutant.physiology.punch_damage_high -= 3


/datum/dna/gene/disability/weak/proc/remove_weak_modifiers(mob/living/carbon/human/mutant, datum/species/species)
	if(!species)
		species = mutant.dna.species
	mutant.physiology.tail_strength_mod /= 0.75
	switch(species.name)
		if(SPECIES_VULPKANIN, SPECIES_DRASK, SPECIES_UNATHI)
			mutant.physiology.grab_resist_mod /= 0.75
			mutant.physiology.punch_damage_low += 3
			mutant.physiology.punch_damage_high += 4
		if(SPECIES_HUMAN)
			mutant.physiology.grab_resist_mod /= 0.9
			mutant.physiology.punch_damage_low += 1
			mutant.physiology.punch_damage_high += 2
		else
			mutant.physiology.grab_resist_mod /= 0.85
			mutant.physiology.punch_damage_low += 2
			mutant.physiology.punch_damage_high += 3

/datum/dna/gene/disability/paraplegia
	name = "Paraplegia"
	desc = "Парализует мышцы ног."
	activation_message = list("Вы не чувствуете своих ног.")
	deactivation_message = list("Вы возвращаете контроль над ногами.")
	instability = -GENE_INSTABILITY_MAJOR
	traits_to_add = list(TRAIT_FLOORED)

/datum/dna/gene/disability/paraplegia/New()
	..()
	block = GLOB.paraplegiablock
