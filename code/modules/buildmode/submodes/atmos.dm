/datum/buildmode_mode/atmos
	key = "atmos"

	use_corner_selection = TRUE
	var/pressure = ONE_ATMOSPHERE
	var/temperature = T20C
	var/datum/gaslist/gases = new

	var/oxygen = O2STANDARD
	var/nitrogen = N2STANDARD
	var/plasma = 0
	var/cdiox = 0
	var/nitrox = 0
	var/agentbx = 0

/datum/buildmode_mode/atmos/New(datum/click_intercept/buildmode/newBM)
	. = ..()
	gases._set(GAS_OXYGEN, O2STANDARD)
	gases._set(GAS_NITROGEN, N2STANDARD)

/datum/buildmode_mode/atmos/show_help(mob/user)
	to_chat(user, "<span class='notice'>***********************************************************</span>")
	to_chat(user, "<span class='notice'>Left Mouse Button on turf      = Select corner</span>")
	to_chat(user, "<span class='notice'>Left Mouse Button + Ctrl on turf = Set 'base atmos conditions' for space turfs in region</span>")
	to_chat(user, "<span class='notice'>Right Mouse Button on buildmode button = Adjust target atmos</span>")
	to_chat(user, "<span class='notice'><b>Notice:</b> Starts out with standard breathable/liveable defaults</span>")
	to_chat(user, "<span class='notice'>***********************************************************</span>")

// FIXME this is a little tedious, something where you don't have to fill in each field would be cooler
// maybe some kind of stat panel thing?
/datum/buildmode_mode/atmos/change_settings(mob/user)
	pressure = input(user, "Atmospheric Pressure", "Input", ONE_ATMOSPHERE) as num|null
	temperature = input(user, "Temperature", "Input", T20C) as num|null
	gases._set(GAS_OXYGEN, input(user, "Oxygen ratio", "Input", O2STANDARD) as num|null)
	gases._set(GAS_NITROGEN, input(user, "Nitrogen ratio", "Input", N2STANDARD) as num|null)
	gases._set(GAS_PLASMA, input(user, "Plasma ratio", "Input", 0) as num|null)
	gases._set(GAS_CDO, input(user, "CO2 ratio", "Input", 0) as num|null)
	gases._set(GAS_N2O, input(user, "N2O ratio", "Input", 0) as num|null)
	gases._set(GAS_AGENT_B, input(user, "Agent B ratio", "Input", 0) as num|null)

/datum/buildmode_mode/atmos/proc/ppratio_to_moles(ppratio)
	// ideal gas equation: Pressure * Volume = Moles * r * Temperature
	// air datum fields are in moles, we have partial pressure ratios
	// Moles = (Pressure * Volume) / (r * Temperature)
	return ((ppratio * pressure) * CELL_VOLUME) / (temperature * R_IDEAL_GAS_EQUATION)

/datum/buildmode_mode/atmos/handle_selected_region(mob/user, params)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")
	var/ctrl_click = pa.Find("ctrl")
	if(left_click) //rectangular
		for(var/turf/T in block(cornerA,cornerB))
			if(issimulatedturf(T))
				// fill the turf with the appropriate gasses
				// this feels slightly icky
				var/turf/simulated/S = T
				if(S.air)
					S.air.temperature = temperature
					for(var/id in gases.gases)
						S.air.gases._set(id, ppratio_to_moles(gases.get(id)))

					S.update_visuals()
					S.air_update_turf()
			else if(ctrl_click) // overwrite "default" space air
				T.temperature = temperature

				for(var/id in gases.gases)
					T.air.gases._set(id, ppratio_to_moles(gases.get(id)))

				T.air_update_turf()

		// admin log
		log_admin("Build Mode: [key_name(user)] changed the atmos of region [COORD(cornerA)] to [COORD(cornerB)]. T: [temperature], P: [pressure], Ox: [oxygen]%, N2: [nitrogen]%, Plsma: [plasma]%, CO2: [cdiox]%, N2O: [nitrox]%. [ctrl_click ? "Overwrote base space turf gases." : ""]")
