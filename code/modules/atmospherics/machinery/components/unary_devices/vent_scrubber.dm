/obj/machinery/atmospherics/unary/vent_scrubber
	icon = 'icons/obj/pipes_and_stuff/atmospherics/atmos/vent_scrubber.dmi'
	icon_state = "map_scrubber"

	name = "air scrubber"
	desc = "Has a valve and pump attached to it"
	layer = GAS_PIPE_VISIBLE_LAYER + GAS_SCRUBBER_OFFSET
	layer_offset = GAS_SCRUBBER_OFFSET

	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 60

	can_unwrench = TRUE

	vent_movement = VENTCRAWL_ALLOWED|VENTCRAWL_CAN_SEE|VENTCRAWL_ENTRANCE_ALLOWED

	var/area/initial_loc

	frequency = ATMOS_VENTSCRUB

	var/list/turf/simulated/adjacent_turfs = list()

	on = FALSE
	var/scrubbing = 1 //0 = siphoning, 1 = scrubbing

	var/list/scrub_gases = list(GAS_CDO)
	var/scrub_O2 = 0
	var/scrub_N2 = 0
	var/scrub_CO2 = 1
	var/scrub_Toxins = 0
	var/scrub_N2O = 0

	var/volume_rate = 200
	var/widenet = 0 //is this scrubber acting on the 3x3 area around it.

	var/area_uid
	var/radio_filter_out
	var/radio_filter_in

	connect_types = list(1,3) //connects to regular and scrubber pipes

	multitool_menu_type = /datum/multitool_menu/idtag/freq/vent_scrubber

/obj/machinery/atmospherics/unary/vent_scrubber/New()
	. = ..()

	if(scrub_O2)
		scrub_gases.Add(GAS_OXYGEN)

	if(scrub_N2)
		scrub_gases.Add(GAS_NITROGEN)

	if(!scrub_CO2)
		scrub_gases.Remove(GAS_CDO)

	if(scrub_Toxins)
		scrub_gases.Add(GAS_PLASMA)

	if(scrub_N2O)
		scrub_gases.Add(GAS_N2O)

/obj/machinery/atmospherics/unary/vent_scrubber/on
	on = TRUE
	scrub_gases = list(GAS_CDO, GAS_N2O, GAS_PLASMA)

/obj/machinery/atmospherics/unary/vent_scrubber/New()
	..()
	icon = null
	initial_loc = get_area(loc)
	area_uid = initial_loc.uid
	if(!id_tag)
		assign_uid()
		id_tag = num2text(uid)

/obj/machinery/atmospherics/unary/vent_scrubber/Destroy()
	if(initial_loc && frequency == ATMOS_VENTSCRUB)
		initial_loc.air_scrub_info -= id_tag
		initial_loc.air_scrub_names -= id_tag
	if(SSradio)
		SSradio.remove_object(src, frequency)
	radio_connection = null
	return ..()

/obj/machinery/atmospherics/unary/vent_scrubber/examine(mob/user)
	. = ..()
	if(welded)
		. += span_notice("It seems welded shut.")

/obj/machinery/atmospherics/unary/vent_scrubber/auto_use_power()
	if(!powered(power_channel))
		return 0
	if(!on || welded)
		return 0
	if(stat & (NOPOWER|BROKEN))
		return 0

	var/amount = idle_power_usage

	if(scrubbing)
		if(GAS_CDO in scrub_gases)
			amount += idle_power_usage

		if(GAS_PLASMA in scrub_gases)
			amount += idle_power_usage

		if(GAS_NITROGEN in scrub_gases)
			amount += idle_power_usage

		if(GAS_N2O in scrub_gases)
			amount += idle_power_usage
	else
		amount = active_power_usage

	if(widenet)
		amount += amount*(adjacent_turfs.len*(adjacent_turfs.len/2))
	use_power(amount, power_channel)
	return 1

/obj/machinery/atmospherics/unary/vent_scrubber/update_overlays()
	. = ..()
	SET_PLANE_IMPLICIT(src, FLOOR_PLANE)
	if(!check_icon_cache())
		return

	var/scrubber_icon = "scrubber"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(!powered())
		scrubber_icon += "off"
	else
		scrubber_icon += "[on ? "[scrubbing ? "on" : "in"]" : "off"]"

	if(welded)
		scrubber_icon = "scrubberweld"

	. += SSair.icon_manager.get_atmos_icon("device", state = scrubber_icon)
	update_pipe_image()


/obj/machinery/atmospherics/unary/vent_scrubber/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		if(T.intact && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
			return
		else
			if(node)
				add_underlay(T, node, dir, node.icon_connect_type)
			else
				add_underlay(T, direction = dir)

/obj/machinery/atmospherics/unary/vent_scrubber/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency, radio_filter_in)
	if(frequency != ATMOS_VENTSCRUB)
		initial_loc.air_scrub_info -= id_tag
		initial_loc.air_scrub_names -= id_tag
		name = "air Scrubber"
	else
		broadcast_status()

/obj/machinery/atmospherics/unary/vent_scrubber/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src
	signal.data = list(
		"area" = area_uid,
		"tag" = id_tag,
		"device" = "AScr",
		"timestamp" = world.time,
		"power" = on,
		"scrubbing" = scrubbing,
		"widenet" = widenet,
		"filter_o2" = (GAS_OXYGEN in scrub_gases),
		"filter_n2" = (GAS_NITROGEN in scrub_gases),
		"filter_co2" = (GAS_CDO in scrub_gases),
		"filter_toxins" = (GAS_PLASMA in scrub_gases),
		"filter_n2o" = (GAS_N2O in scrub_gases),
		"sigtype" = "status"
	)
	if(frequency == ATMOS_VENTSCRUB)
		if(!initial_loc.air_scrub_names[id_tag])
			var/new_name = "[initial_loc.name] Air Scrubber #[initial_loc.air_scrub_names.len+1]"
			initial_loc.air_scrub_names[id_tag] = new_name
			src.name = new_name
		initial_loc.air_scrub_info[id_tag] = signal.data
	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1

/obj/machinery/atmospherics/unary/vent_scrubber/atmos_init()
	..()
	radio_filter_in = frequency==initial(frequency)?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==initial(frequency)?(RADIO_TO_AIRALARM):null
	if(frequency)
		set_frequency(frequency)
		src.broadcast_status()
	check_turfs()

/obj/machinery/atmospherics/unary/vent_scrubber/process_atmos()
	..()

	if(widenet)
		check_turfs()

	if(stat & (NOPOWER|BROKEN))
		return

	if(!node)
		on = 0

	if(welded)
		return 0
	//broadcast_status()
	if(!on)
		return 0

	scrub(loc)
	if(widenet)
		for(var/turf/simulated/tile in adjacent_turfs)
			scrub(tile)

//we populate a list of turfs with nonatmos-blocked cardinal turfs AND
//	diagonal turfs that can share atmos with *both* of the cardinal turfs
/obj/machinery/atmospherics/unary/vent_scrubber/proc/check_turfs()
	adjacent_turfs.Cut()
	var/turf/T = loc
	if(istype(T))
		adjacent_turfs = T.GetAtmosAdjacentTurfs(TRUE)

/obj/machinery/atmospherics/unary/vent_scrubber/proc/scrub(var/turf/simulated/tile)
	if(!tile || !istype(tile))
		return 0

	var/datum/gas_mixture/environment = tile.return_air()

	if(scrubbing)
		var/will_remove_not_all = FALSE
		var/list/default = list(GAS_OXYGEN, GAS_NITROGEN, GAS_CDO, GAS_PLASMA)
		for(var/id in default)
			if(id in scrub_gases && environment.gases.get(id) > 0.001)
				will_remove_not_all = TRUE
				break

		for(var/id in environment.gases - default)
			will_remove_not_all = TRUE
			break

		if(will_remove_not_all)
			var/transfer_moles = min(1, volume_rate/environment.volume)*environment.total_moles()

			//Take a gas sample
			var/datum/gas_mixture/removed = loc.remove_air(transfer_moles)
			if(isnull(removed)) //in space
				return

			//Filter it
			var/datum/gas_mixture/filtered_out = new
			filtered_out.temperature = removed.temperature

			for(var/id in scrub_gases)
				filtered_out.gases._set(id, removed.gases.get(id))
				removed.gases._set(id, 0)

			//Remix the resulting gases
			air_contents.merge(filtered_out)

			tile.assume_air(removed)
			tile.air_update_turf()

	else //Just siphoning all air
		if(air_contents.return_pressure()>=50*ONE_ATMOSPHERE)
			return

		var/transfer_moles = environment.total_moles()*(volume_rate/environment.volume)

		var/datum/gas_mixture/removed = tile.remove_air(transfer_moles)

		air_contents.merge(removed)
		tile.air_update_turf()

	parent?.update = 1

	return 1

/obj/machinery/atmospherics/unary/vent_scrubber/hide(var/i) //to make the little pipe section invisible, the icon changes.
	update_icon()

/obj/machinery/atmospherics/unary/vent_scrubber/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["power"] != null)
		on = text2num(signal.data["power"])
	if(signal.data["power_toggle"] != null)
		on = !on

	if("widenet" in signal.data)
		widenet = text2num(signal.data["widenet"])
	if("toggle_widenet" in signal.data)
		widenet = !widenet

	if(signal.data["scrubbing"] != null)
		scrubbing = text2num(signal.data["scrubbing"])
	if(signal.data["toggle_scrubbing"])
		scrubbing = !scrubbing

	if(signal.data["o2_scrub"] != null)
		if(text2num(signal.data["o2_scrub"]))
			scrub_gases += GAS_OXYGEN

	if(signal.data["toggle_o2_scrub"])
		if(GAS_OXYGEN in scrub_gases)
			scrub_gases.Remove(GAS_OXYGEN)
		else
			scrub_gases.Add(GAS_OXYGEN)

	if(signal.data["n2_scrub"] != null)
		if(text2num(signal.data["n2_scrub"]))
			scrub_gases += GAS_NITROGEN

	if(signal.data["toggle_n2_scrub"])
		if(GAS_NITROGEN in scrub_gases)
			scrub_gases.Remove(GAS_NITROGEN)
		else
			scrub_gases.Add(GAS_NITROGEN)

	if(signal.data["co2_scrub"] != null)
		if(text2num(signal.data["co2_scrub"]))
			scrub_gases += GAS_CDO

	if(signal.data["toggle_co2_scrub"])
		if(GAS_CDO in scrub_gases)
			scrub_gases.Remove(GAS_CDO)
		else
			scrub_gases.Add(GAS_CDO)

	if(signal.data["tox_scrub"] != null)
		if(text2num(signal.data["tox_scrub"]))
			scrub_gases += GAS_PLASMA

	if(signal.data["toggle_tox_scrub"])
		if(GAS_PLASMA in scrub_gases)
			scrub_gases.Remove(GAS_PLASMA)
		else
			scrub_gases.Add(GAS_PLASMA)

	if(signal.data["n2o_scrub"] != null)
		if(text2num(signal.data["n2o_scrub"]))
			scrub_gases += GAS_N2O

	if(signal.data["toggle_n2o_scrub"])
		if(GAS_N2O in scrub_gases)
			scrub_gases.Remove(GAS_N2O)
		else
			scrub_gases.Add(GAS_N2O)

	if(signal.data["init"] != null)
		name = signal.data["init"]
		return

	if(signal.data["status"] != null)
		spawn(2)
			broadcast_status()
		return //do not update_icon

	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/unary/vent_scrubber/power_change(forced = FALSE)
	if(!..())
		return
	update_icon()

/obj/machinery/atmospherics/unary/vent_scrubber/proc/set_tag(new_tag)
	if(frequency == ATMOS_VENTSCRUB)
		initial_loc.air_scrub_info -= id_tag
		initial_loc.air_scrub_names -= id_tag
	id_tag = new_tag
	broadcast_status()


/obj/machinery/atmospherics/unary/vent_scrubber/attack_alien(mob/user)
	if(!welded || !do_after(user, 2 SECONDS, src))
		return
	user.visible_message(
		span_warning("[user] furiously claws at [src]!"),
		span_notice("You manage to clear away the stuff blocking the scrubber."),
		span_italics("You hear loud scraping noises."),
	)
	set_welded(FALSE)
	playsound(loc, 'sound/weapons/bladeslice.ogg', 100, TRUE)


/obj/machinery/atmospherics/unary/vent_scrubber/multitool_act(mob/user, obj/item/I)
	. = TRUE
	multitool_menu_interact(user, I)


/obj/machinery/atmospherics/unary/vent_scrubber/welder_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return .
	WELDER_ATTEMPT_WELD_MESSAGE
	if(!I.use_tool(src, user, 2 SECONDS, volume = I.tool_volume))
		return .
	set_welded(!welded)
	if(welded)
		user.visible_message(
			span_notice("[user] welds [src] shut!"),
			span_notice("You weld [src] shut!"),
		)
	else
		user.visible_message(
			span_notice("[user] unwelds [src]!"),
			span_notice("You unweld [src]!"),
		)

