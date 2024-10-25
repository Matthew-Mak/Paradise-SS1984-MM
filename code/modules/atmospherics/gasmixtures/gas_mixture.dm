#define MINIMUM_HEAT_CAPACITY	0.0003

/datum/gas_mixture
	var/volume = CELL_VOLUME
	var/datum/gaslist/gases = new
	var/temperature = 0 //in Kelvin

	var/last_share

	var/tmp/datum/gaslist/gases_archived = new
	var/tmp/temperature_archived = 0

	var/tmp/fuel_burnt = 0

	//PV=nRT - related procedures

/datum/gas_mixture/proc/heat_capacity()
	return gases.heatcap()

/datum/gas_mixture/proc/heat_capacity_archived()
	return gases_archived.heatcap()

/datum/gas_mixture/proc/total_moles()
	return gases.amount()

/datum/gas_mixture/proc/total_trace_moles()
	return gases.get(GAS_N2O) + gases.get(GAS_AGENT_B)

/datum/gas_mixture/proc/return_pressure()
	if(volume > 0)
		return total_moles() * R_IDEAL_GAS_EQUATION * temperature / volume

	return 0


/datum/gas_mixture/proc/return_temperature()
	return temperature


/datum/gas_mixture/proc/return_volume()
	return max(0, volume)


/datum/gas_mixture/proc/thermal_energy()
	return temperature * heat_capacity()


//Procedures used for very specific events


/datum/gas_mixture/proc/react()
	var/reacting = 0 //set to 1 if a notable reaction occured (used by pipe_network)

	if(gases.get(GAS_AGENT_B) && temperature > 900)
		if(gases.get(GAS_PLASMA) > MINIMUM_HEAT_CAPACITY && gases.get(GAS_CDO) > MINIMUM_HEAT_CAPACITY)
			var/reaction_rate = min(gases.get(GAS_CDO) * 0.75, gases.get(GAS_PLASMA) * 0.25, gases.get(GAS_AGENT_B) * 0.05)

			gases._set(GAS_CDO, max(gases.get(GAS_CDO) - reaction_rate, 0))
			gases.add(GAS_OXYGEN, reaction_rate)

			gases._set(GAS_AGENT_B, max(gases.get(GAS_AGENT_B) - reaction_rate * 0.05, 0))

			temperature += (reaction_rate * 20000) / heat_capacity()

			reacting = 1

	fuel_burnt = 0
	if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		if(fire() > 0)
			reacting = 1

	return reacting

/datum/gas_mixture/proc/fire()
	var/energy_released = 0
	var/old_heat_capacity = heat_capacity()

	//Handle plasma burning
	if(gases.get(GAS_PLASMA) > MINIMUM_HEAT_CAPACITY)
		var/plasma_burn_rate = 0
		var/oxygen_burn_rate = 0
		//more plasma released at higher temperatures
		var/temperature_scale
		if(temperature > PLASMA_UPPER_TEMPERATURE)
			temperature_scale = 1
		else
			temperature_scale = (temperature - PLASMA_MINIMUM_BURN_TEMPERATURE) / (PLASMA_UPPER_TEMPERATURE-PLASMA_MINIMUM_BURN_TEMPERATURE)
		if(temperature_scale > 0)
			oxygen_burn_rate = OXYGEN_BURN_RATE_BASE - temperature_scale
			if(gases.get(GAS_OXYGEN) > gases.get(GAS_PLASMA) * PLASMA_OXYGEN_FULLBURN)
				plasma_burn_rate = (gases.get(GAS_PLASMA) * temperature_scale) / PLASMA_BURN_RATE_DELTA
			else
				plasma_burn_rate = (temperature_scale * (gases.get(GAS_OXYGEN) / PLASMA_OXYGEN_FULLBURN)) / PLASMA_BURN_RATE_DELTA
			if(plasma_burn_rate > MINIMUM_HEAT_CAPACITY)
				gases.add(GAS_PLASMA, -plasma_burn_rate)
				gases.add(GAS_OXYGEN, -plasma_burn_rate * oxygen_burn_rate)
				gases.add(GAS_CDO, plasma_burn_rate)

				energy_released += FIRE_PLASMA_ENERGY_RELEASED * (plasma_burn_rate)

				fuel_burnt += (plasma_burn_rate) * (1 + oxygen_burn_rate)

	if(energy_released > 0)
		var/new_heat_capacity = heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			temperature = (temperature * old_heat_capacity + energy_released) / new_heat_capacity

	return fuel_burnt

/datum/gas_mixture/proc/archive()
	//Update archived versions of variables
	//Returns: 1 in all cases

/datum/gas_mixture/proc/merge(datum/gas_mixture/giver)
	//Merges all air from giver into self. Deletes giver.
	//Returns: 1 on success (no failure cases yet)

/datum/gas_mixture/proc/remove(amount)
	//Proportionally removes amount of gas from the gas_mixture
	//Returns: gas_mixture with the gases removed

/datum/gas_mixture/proc/remove_ratio(ratio)
	//Proportionally removes amount of gas from the gas_mixture
	//Returns: gas_mixture with the gases removed

/datum/gas_mixture/proc/copy_from(datum/gas_mixture/sample)
	//Copies variables from sample

/datum/gas_mixture/proc/copy_from_turf(turf/model)
	//Copies all gas info from the turf into the gas list along with temperature
	//Returns: 1 if we are mutable, 0 otherwise

/datum/gas_mixture/proc/share(datum/gas_mixture/sharer)
	//Performs air sharing calculations between two gas_mixtures assuming only 1 boundary length
	//Return: amount of gas exchanged (+ if sharer received)
/datum/gas_mixture/proc/mimic(turf/model) //I want this proc to die a painful death
	//Similar to share(...), except the model is not modified
	//Return: amount of gas exchanged

/datum/gas_mixture/proc/check_turf(turf/model) //I want this proc to die a painful death
	//Returns: 0 if self-check failed or 1 if check passes

/datum/gas_mixture/proc/temperature_mimic(turf/model, conduction_coefficient) //I want this proc to die a painful death

/datum/gas_mixture/proc/temperature_share(datum/gas_mixture/sharer, conduction_coefficient)

/datum/gas_mixture/proc/temperature_turf_share(turf/simulated/sharer, conduction_coefficient)

/datum/gas_mixture/proc/compare(datum/gas_mixture/sample)
	//Compares sample to self to see if within acceptable ranges that group processing may be enabled

/datum/gas_mixture/archive()
	gases_archived = gases.copy()
	temperature_archived = temperature
	return 1

/datum/gas_mixture/merge(datum/gas_mixture/giver)
	if(!giver || !giver.gases)
		return 0

	if(abs(temperature - giver.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()
		var/giver_heat_capacity = giver.heat_capacity()
		var/combined_heat_capacity = giver_heat_capacity + self_heat_capacity
		if(combined_heat_capacity != 0)
			temperature = (giver.temperature * giver_heat_capacity + temperature * self_heat_capacity) / combined_heat_capacity

	gases.merge(giver.gases)
	return 1

/datum/gas_mixture/remove(amount)
	if(amount <= 0)
		return null

	var/datum/gas_mixture/removed = new
	removed.gases = gases.remove(amount)
	removed.temperature = temperature
	return removed

/datum/gas_mixture/remove_ratio(ratio)
	if(ratio <= 0)
		return null

	ratio = min(ratio, 1)
	var/datum/gas_mixture/removed = new
	removed.gases = gases.remove_ratio(ratio)
	removed.temperature = temperature
	return removed

/datum/gas_mixture/copy_from(datum/gas_mixture/sample)
	gases = sample.gases.copy()
	temperature = sample.temperature
	return 1

/datum/gas_mixture/copy_from_turf(turf/simulated/model)
	gases = model.air.gases.copy()

	//acounts for changes in temperature
	var/turf/model_parent = model.parent_type
	if(model.temperature != initial(model.temperature) || model.temperature != initial(model_parent.temperature))
		temperature = model.temperature

	return 1

/datum/gas_mixture/check_turf(turf/simulated/model, atmos_adjacent_turfs = 4)
	var/datum/gaslist/delta_gaslist = gases.delta_gaslist(gases_archived, model.air.gases, atmos_adjacent_turfs)
	var/delta_temperature = (temperature_archived - model.temperature)

	for(var/id in delta_gaslist.gases)
		if((abs(delta_gaslist.get(id)) > MINIMUM_AIR_TO_SUSPEND) && (abs(delta_gaslist.get(id)) >= gases_archived.get(id) * MINIMUM_AIR_RATIO_TO_SUSPEND))
			return 0

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
		return 0

	return 1

/datum/gas_mixture/proc/check_turf_total(turf/simulated/model) //I want this proc to die a painful death
	var/datum/gaslist/delta_gaslist = gases.delta_gaslist_total(model.air.gases)
	var/delta_temperature = (temperature - model.temperature)

	for(var/id in delta_gaslist.gases)
		if((abs(delta_gaslist.get(id)) > MINIMUM_AIR_TO_SUSPEND) && (abs(delta_gaslist.get(id)) >= gases_archived.get(id) * MINIMUM_AIR_RATIO_TO_SUSPEND))
			return 0

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
		return 0

	return 1

/datum/gas_mixture/share(datum/gas_mixture/sharer, atmos_adjacent_turfs = 4)
	if(!sharer)
		return 0
	//If there is no difference why do the calculations?
	if(gases_archived.isequal(sharer.gases_archived))
		return 0

	var/datum/gaslist/delta_gaslist = gases.delta_gaslist(gases_archived, sharer.gases_archived, atmos_adjacent_turfs)
	var/delta_temperature = (temperature_archived - sharer.temperature_archived)

	var/old_self_heat_capacity = 0
	var/old_sharer_heat_capacity = 0

	var/heat_capacity_self_to_sharer = 0
	var/heat_capacity_sharer_to_self = 0

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)

		for(var/id in delta_gaslist.gases)
			var/heatcap = gases.heatcap(id)
			if(delta_gaslist.get(id) > 0)
				heat_capacity_self_to_sharer += heatcap
			else
				heat_capacity_sharer_to_self -= heatcap

		old_self_heat_capacity = heat_capacity()
		old_sharer_heat_capacity = sharer.heat_capacity()

	for(var/id in delta_gaslist.gases)
		gases.add(id, -delta_gaslist.get(id))
		sharer.gases.add(id, delta_gaslist.get(id))

	var/moved_moles = delta_gaslist.amount
	last_share = 0
	for(var/id in delta_gaslist.gases)
		last_share += abs(delta_gaslist.get(id))

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/new_self_heat_capacity = old_self_heat_capacity + heat_capacity_sharer_to_self - heat_capacity_self_to_sharer
		var/new_sharer_heat_capacity = old_sharer_heat_capacity + heat_capacity_self_to_sharer - heat_capacity_sharer_to_self

		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			temperature = (old_self_heat_capacity * temperature - heat_capacity_self_to_sharer * temperature_archived + heat_capacity_sharer_to_self * sharer.temperature_archived) / new_self_heat_capacity

		if(new_sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			sharer.temperature = (old_sharer_heat_capacity * sharer.temperature - heat_capacity_sharer_to_self * sharer.temperature_archived + heat_capacity_self_to_sharer * temperature_archived) / new_sharer_heat_capacity

			if(abs(old_sharer_heat_capacity) > MINIMUM_HEAT_CAPACITY)
				if(abs(new_sharer_heat_capacity / old_sharer_heat_capacity - 1) < 0.10) // <10% change in sharer heat capacity
					temperature_share(sharer, OPEN_HEAT_TRANSFER_COEFFICIENT)

	if((delta_temperature > MINIMUM_TEMPERATURE_TO_MOVE) || abs(moved_moles) > MINIMUM_MOLES_DELTA_TO_MOVE)
		var/delta_pressure = temperature_archived * (total_moles() + moved_moles) - sharer.temperature_archived * (sharer.total_moles() - moved_moles)
		return delta_pressure * R_IDEAL_GAS_EQUATION / volume

/datum/gas_mixture/mimic(turf/simulated/model, atmos_adjacent_turfs = 4)
	var/datum/gaslist/delta_gaslist = gases.delta_gaslist(gases_archived, model.air.gases, atmos_adjacent_turfs)
	var/delta_temperature = (temperature_archived - model.temperature)

	var/heat_transferred = 0
	var/old_self_heat_capacity = 0
	var/heat_capacity_transferred = 0

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		for(var/id in delta_gaslist.gases)
			var/heatcap = delta_gaslist.heatcap(id)
			heat_transferred -= heatcap * model.temperature
			heat_capacity_transferred -= heatcap

		old_self_heat_capacity = heat_capacity()

	for(var/id in delta_gaslist.gases)
		gases.add(id, -delta_gaslist[id])

	var/moved_moles = delta_gaslist.amount
	last_share = 0
	for(var/id in delta_gaslist.gases)
		last_share += abs(delta_gaslist.get(id))

	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/new_self_heat_capacity = old_self_heat_capacity - heat_capacity_transferred
		if(new_self_heat_capacity > MINIMUM_HEAT_CAPACITY)
			temperature = (old_self_heat_capacity * temperature - heat_capacity_transferred * temperature_archived) / new_self_heat_capacity

		temperature_mimic(model, model.thermal_conductivity)

	if((delta_temperature > MINIMUM_TEMPERATURE_TO_MOVE) || abs(moved_moles) > MINIMUM_MOLES_DELTA_TO_MOVE)
		var/delta_pressure = temperature_archived * (total_moles() + moved_moles) - model.temperature * model.air.gases.amount
		return delta_pressure * R_IDEAL_GAS_EQUATION / volume
	else
		return 0

/datum/gas_mixture/temperature_share(datum/gas_mixture/sharer, conduction_coefficient)

	var/delta_temperature = (temperature_archived - sharer.temperature_archived)
	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity_archived()
		var/sharer_heat_capacity = sharer.heat_capacity_archived()

		if((sharer_heat_capacity > MINIMUM_HEAT_CAPACITY) && (self_heat_capacity > MINIMUM_HEAT_CAPACITY))
			var/heat = conduction_coefficient*delta_temperature * \
				(self_heat_capacity * sharer_heat_capacity / (self_heat_capacity + sharer_heat_capacity))

			temperature -= heat / self_heat_capacity
			sharer.temperature += heat / sharer_heat_capacity

/datum/gas_mixture/temperature_mimic(turf/model, conduction_coefficient)
	var/delta_temperature = (temperature - model.temperature)
	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()

		if((model.heat_capacity > MINIMUM_HEAT_CAPACITY) && (self_heat_capacity > MINIMUM_HEAT_CAPACITY))
			var/heat = conduction_coefficient * delta_temperature * \
				(self_heat_capacity * model.heat_capacity / (self_heat_capacity + model.heat_capacity))

			temperature -= heat / self_heat_capacity

/datum/gas_mixture/temperature_turf_share(turf/simulated/sharer, conduction_coefficient)
	var/delta_temperature = (temperature_archived - sharer.temperature)
	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()

		if((sharer.heat_capacity > MINIMUM_HEAT_CAPACITY) && (self_heat_capacity > MINIMUM_HEAT_CAPACITY))
			var/heat = conduction_coefficient * delta_temperature * \
				(self_heat_capacity * sharer.heat_capacity / (self_heat_capacity + sharer.heat_capacity))

			temperature -= heat / self_heat_capacity
			sharer.temperature += heat / sharer.heat_capacity

/datum/gas_mixture/compare(datum/gas_mixture/sample)
	for(var/id in gases.gases_with(sample))
		if((abs(gases.get(id) - sample.gases.get(id)) > MINIMUM_AIR_TO_SUSPEND) && \
			((gases.get(id) < (1 - MINIMUM_AIR_RATIO_TO_SUSPEND) * sample.gases.get(id)) || \
			(gases.get(id) > (1 + MINIMUM_AIR_RATIO_TO_SUSPEND) * sample.gases.get(id))))
			return 0

	if(total_moles() > MINIMUM_AIR_TO_SUSPEND)
		if((abs(temperature - sample.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND) && \
			((temperature < (1 - MINIMUM_TEMPERATURE_RATIO_TO_SUSPEND) * sample.temperature) || (temperature > (1 + MINIMUM_TEMPERATURE_RATIO_TO_SUSPEND) * sample.temperature)))
			return 0

	return 1



//Takes the amount of the gas you want to PP as an argument
//So I don't have to do some hacky switches/defines/magic strings

//eg:
//Tox_PP = get_partial_pressure(gas_mixture.gases.get(GAS_PLASMA))
//O2_PP = get_partial_pressure(gas_mixture.gases.get(GAS_OXYGEN))

//Does handle trace gases!

/datum/gas_mixture/proc/get_breath_partial_pressure(gas_pressure)
	return (gas_pressure * R_IDEAL_GAS_EQUATION * temperature) / BREATH_VOLUME


//Reverse of the above
/datum/gas_mixture/proc/get_true_breath_pressure(breath_pp)
	return (breath_pp * BREATH_VOLUME) / (R_IDEAL_GAS_EQUATION * temperature)

//Mathematical proofs:
/*

get_breath_partial_pressure(gas_pp) --> gas_pp/total_moles()*breath_pp = pp
get_true_breath_pressure(pp) --> gas_pp = pp/breath_pp*total_moles()

10/20*5 = 2.5
10 = 2.5/5*20

*/
