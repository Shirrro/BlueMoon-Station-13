// Active parry system goes in here.

/**
  * Called from keybindings.
  */
/mob/living/proc/keybind_parry()
	initiate_parry_sequence()

/**
  * Initiates a parrying sequence.
  */
/mob/living/proc/initiate_parry_sequence()
	if(parrying)
		return		// already parrying
	if(!CHECK_MOBILITY(src, MOBILITY_USE))
		to_chat(src, "<span class='warning'>You are incapacitated, or otherwise unable to swing a weapon to parry with!")
		return FALSE
	if(!SEND_SIGNAL(src, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		to_chat(src, "<span class='warning'>You must be in combat mode to parry!</span>")
		return FALSE
	var/datum/block_parry_data/data
	// Prioritize item, then martial art, then unarmed.
	// yanderedev else if time
	var/obj/item/using_item = get_active_held_item()
	var/method
	if(using_item.item_flags & ITEM_CAN_PARRY)
		data = using_item.block_parry_data
		method = ITEM_PARRY
	else if(mind?.martial_art?.can_martial_parry)
		data = mind.martial_art.block_parry_data
		method = MARTIAL_PARRY
	else if(parry_while_unarmed)
		data = block_parry_data
		method = UNARMED_PARRY
	else
		to_chat(src, "<span class='warning'>You have nothing to parry with!</span>")
		return FALSE
	data = return_block_parry_datum(data)
	var/full_parry_duration = data.parry_time_windup + data.parry_time_active + data.parry_time_spindown
	// no system in place to "fallback" if out of the 3 the top priority one can't parry due to constraints but something else can.
	// can always implement it later, whatever.
	if(data.parry_respect_clickdelay && (next_move > world.time))
		to_chat(src, "<span class='warning'>You are not ready to parry (again)!</span>")
		return
	// Point of no return, make sure everything is set.
	parrying = method
	if(method == ITEM_PARRY)
		active_parry_item = using_item
	adjustStaminaLossBuffered(data.parry_stamina_cost)
	parry_start_time = world.time
	successful_parries = list()
	addtimer(CALLBACK(src, .proc/end_parry_sequence), full_parry_duration)
	handle_parry_starting_effects(data)
	return TRUE

/**
  * Called via timer when the parry sequence ends.
  */
/mob/living/proc/end_parry_sequence()
	if(!parrying)
		return
	var/datum/block_parry_data/data = get_parry_data()
	var/list/effect_text = list()
	if(!length(successful_parries))		// didn't parry anything successfully
		if(data.parry_failed_stagger_duration)
			Stagger(data.parry_failed_stagger_duration)
			effect_text += "staggering themselves"
		if(data.parry_failed_clickcd_duration)
			changeNext_move(data.parry_failed_clickcd_duration)
			effect_text += "throwing themselves off balance"
	handle_parry_ending_effects(data, effect_text)
	parrying = NOT_PARRYING
	parry_start_time = 0
	successful_parries = null

/**
  * Handles starting effects for parrying.
  */
/mob/living/proc/handle_parry_starting_effects(datum/block_parry_data/data)
	playsound(src, data.parry_start_sound, 75, 1)
	new /obj/effect/abstract/parry/main(null, data, src)
	switch(parrying)
		if(ITEM_PARRY)
			visible_message("<span class='warning'>[src] swings [active_parry_item]!</span>")
		else
			visible_message("<span class='warning'>[src] rushes forwards!</span>")

/**
  * Handles ending effects for parrying.
  */
/mob/living/proc/handle_parry_ending_effects(datum/block_parry_data/data, list/failed_effect_text)
	if(length(successful_parries))
		return
	visible_message("<span class='warning'>[src] fails to connect their parry[failed_effect_text? ", [english_list(failed_effect_text)]" : ""]!")

/**
  * Gets this item's datum/block_parry_data
  */
/obj/item/proc/get_block_parry_data()
	return return_block_parry_datum(block_parry_data)

//Stubs.

/**
  * Called when an attack is parried using this, whether or not the parry was successful.
  */
/obj/item/proc/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, parry_efficiency, parry_time)

/**
  * Called when an attack is parried innately, whether or not the parry was successful.
  */
/mob/living/proc/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, parry_efficiency, parry_time)

/**
  * Called when an attack is parried using this, whether or not the parry was successful.
  */
/datum/martial_art/proc/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, parry_efficiency, parry_time)

/**
  * Called when an attack is parried and block_parra_data indicates to use a proc to handle counterattack.
  */
/obj/item/proc/active_parry_reflex_counter(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list, parry_efficiency)

/**
  * Called when an attack is parried and block_parra_data indicates to use a proc to handle counterattack.
  */
/mob/living/proc/active_parry_reflex_counter(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list, parry_efficiency)

/**
  * Called when an attack is parried and block_parra_data indicates to use a proc to handle counterattack.
  */
/datum/martial_art/proc/active_parry_reflex_counter(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list, parry_efficiency)

/**
  * Gets the stage of our parry sequence we're currently in.
  */
/mob/living/proc/get_parry_stage()
	if(!parrying)
		return NOT_PARRYING
	var/datum/block_parry_data/data = get_parry_data()
	var/windup_end = data.parry_time_windup
	var/active_end = windup_end + data.parry_time_active
	var/spindown_end = active_end + data.parry_time_spindown
	switch(get_parry_time())
		if(0 to windup_end)
			return PARRY_WINDUP
		if(windup_end to active_end)
			return PARRY_ACTIVE
		if(active_end to spindown_end)
			return PARRY_SPINDOWN
	return NOT_PARRYING

/**
  * Gets the percentage efficiency of our parry.
  *
  * Returns a percentage in normal 0 to 100 scale, but not clamped to just 0 to 100.
  */
/mob/living/proc/get_parry_efficiency(attack_type)
	var/datum/block_parry_data/data = get_parry_data()
	if(get_parry_stage() != PARRY_ACTIVE)
		return 0
	var/difference = abs(get_parry_time() - (data.parry_time_perfect + data.parry_time_windup))
	var/leeway = data.attack_type_list_scan(data.parry_time_perfect_leeway_override, attack_type)
	if(isnull(leeway))
		leeway = data.parry_time_perfect_leeway
	difference -= leeway
	. = data.parry_efficiency_perfect
	if(difference <= 0)
		return
	var/falloff = data.attack_type_list_scan(data.parry_imperfect_falloff_percent_override, attack_type)
	if(isnull(falloff))
		falloff = data.parry_imperfect_falloff_percent
	. -= falloff * difference

/**
  * Gets the current decisecond "frame" of an active parry.
  */
/mob/living/proc/get_parry_time()
	return world.time - parry_start_time

/// same return values as normal blocking, called with absolute highest priority in the block "chain".
/mob/living/proc/run_parry(atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list = list())
	var/stage = get_parry_stage()
	if(stage == NOT_PARRYING)
		return BLOCK_NONE
	if(!CHECK_MOBILITY(src, MOBILITY_USE))
		to_chat(src, "<span class='warning'>Your parry is interrupted!</span>")
		end_parry_sequence()
	var/datum/block_parry_data/data = get_parry_data()
	if(attack_type && !(attack_type & data.parry_attack_types))
		return BLOCK_NONE
	var/efficiency = get_parry_efficiency(attack_type)
	switch(parrying)
		if(ITEM_PARRY)
			. = active_parry_item.on_active_parry(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, efficiency, get_parry_time())
		if(UNARMED_PARRY)
			. = on_active_parry(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, efficiency, get_parry_time())
		if(MARTIAL_PARRY)
			. = mind.martial_art.on_active_parry(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, efficiency, get_parry_time())
	if(!isnull(return_list[BLOCK_RETURN_OVERRIDE_PARRY_EFFICIENCY]))		// one of our procs overrode
		efficiency = return_list[BLOCK_RETURN_OVERRIDE_PARRY_EFFICIENCY]
	if(efficiency <= 0)		// Do not allow automatically handled/standardized parries that increase damage for now.
		return
	. |= BLOCK_SHOULD_PARTIAL_MITIGATE
	if(isnull(return_list[BLOCK_RETURN_MITIGATION_PERCENT]))		//  if one of the on_active_parry procs overrode. We don't have to worry about interference since parries are the first thing checked in the [do_run_block()] sequence.
		return_list[BLOCK_RETURN_MITIGATION_PERCENT] = clamp(efficiency, 0, 100)		// do not allow > 100% or < 0% for now.
	var/list/effect_text = run_parry_countereffects(object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, efficiency)
	if(data.parry_default_handle_feedback)
		handle_parry_feedback(object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, efficiency, effect_text)
	successful_parries += efficiency

/mob/living/proc/handle_parry_feedback(atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list = list(), parry_efficiency, list/effect_text)
	var/datum/block_parry_data/data = get_parry_data()
	if(data.parry_sounds)
		playsound(src, pick(data.parry_sounds), 75)
	visible_message("<span class='danger'>[src] parries \the [attack_text][length(effect_text)? ", [english_list(effect_text)] [attacker]" : ""]!</span>")

/// Run counterattack if any
/mob/living/proc/run_parry_countereffects(atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/return_list = list(), parry_efficiency)
	if(!isliving(attacker))
		return
	var/mob/living/L = attacker
	var/datum/block_parry_data/data = get_parry_data()
	var/list/effect_text = list()
	if(data.parry_data[PARRY_REFLEX_COUNTERATTACK])
		switch(data.parry_data[PARRY_REFLEX_COUNTERATTACK])
			if(PARRY_COUNTERATTACK_PROC)
				switch(parrying)
					if(ITEM_PARRY)
						active_parry_item.active_parry_reflex_counter(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, parry_efficiency)
					if(UNARMED_PARRY)
						active_parry_reflex_counter(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, parry_efficiency)
					if(MARTIAL_PARRY)
						mind.martial_art.active_parry_reflex_counter(src, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list, parry_efficiency)
			if(PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN)
				switch(parrying)
					if(ITEM_PARRY)
						active_parry_item.melee_attack_chain(src, attacker, null)
					if(UNARMED_PARRY)
						UnarmedAttack(attacker)
					if(MARTIAL_PARRY)
						UnarmedAttack(attacker)
	if(data.parry_data[PARRY_DISARM_ATTACKER])
		L.drop_all_held_items()
		effect_text += "disarming"
	if(data.parry_data[PARRY_KNOCKDOWN_ATTACKER])
		L.DefaultCombatKnockdown(data.parry_data[PARRY_KNOCKDOWN_ATTACKER])
		effect_text += "knocking them to the ground"
	if(data.parry_data[PARRY_STAGGER_ATTACKER])
		L.Stagger(data.parry_data[PARRY_STAGGER_ATTACKER])
		effect_text += "staggering"
	if(data.parry_data[PARRY_DAZE_ATTACKER])
		L.Daze(data.parry_data[PARRY_DAZE_ATTACKER])
		effect_text += "dazing"
	return effect_text

/// Gets the datum/block_parry_data we're going to use to parry.
/mob/living/proc/get_parry_data()
	if(parrying == ITEM_PARRY)
		return active_parry_item.get_block_parry_data()
	else if(parrying == UNARMED_PARRY)
		return return_block_parry_datum(block_parry_data)
	else if(parrying == MARTIAL_PARRY)
		return return_block_parry_datum(mind.martial_art.block_parry_data)

/// Effects
/obj/effect/abstract/parry
	icon = 'icons/effects/block_parry.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = FLOAT_LAYER
	plane = FLOAT_PLANE
	vis_flags = VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
	/// The person we're on
	var/mob/living/owner

/obj/effect/abstract/parry/main
	name = null
	icon_state = "parry_bm_hold"

/obj/effect/abstract/parry/main/Initialize(mapload, datum/block_parry_data/data, mob/living/owner)
	. = ..()
	if(owner)
		attach_to(owner)
	if(data)
		INVOKE_ASYNC(src, .proc/run_animation, data.parry_time_windup, data.parry_time_active, data.parry_time_spindown, TRUE)

/obj/effect/abstract/parry/main/Destroy()
	detach_from(owner)
	return ..()

/obj/effect/abstract/parry/main/proc/attach_to(mob/living/attaching)
	if(owner)
		detach_from(owner)
	owner = attaching
	owner.vis_contents += src

/obj/effect/abstract/parry/main/proc/detach_from(mob/living/detaching)
	if(detaching == owner)
		owner = null
	detaching.vis_contents -= src

/obj/effect/abstract/parry/main/proc/run_animation(windup_time = 2, active_time = 5, spindown_time = 3, qdel_end = TRUE)
	if(qdel_end)
		QDEL_IN(src, windup_time + active_time + spindown_time)
	var/matrix/current = transform
	transform = matrix(0.1, 0, 0, 0, 0.1, 0)
	animate(src, transform = current, time = windup_time)
	sleep(active_time)
	flick(icon, "parry_bm_end")
