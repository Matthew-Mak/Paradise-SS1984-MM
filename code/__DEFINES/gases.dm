#define GAS_PLASMA				"plasma"
#define GAS_OXYGEN				"oxygen"
#define GAS_NITROGEN			"nitrogen"
#define GAS_CDO					"carbon_dioxide"
#define GAS_N2O					"sleeping_agent"
#define GAS_AGENT_B				"agent_b"


#define HEAT_CAP_DEFAULT		50
#define HEAT_CAP_PLASMA			200
#define HEAT_CAP_OXYGEN			20
#define HEAT_CAP_NITROGEN		20
#define HEAT_CAP_CDO			30
#define HEAT_CAP_N2O			40
#define HEAT_CAP_AGENT_B		300


GLOBAL_LIST_INIT(gastype_specific_heatcup_by_id, list(
	GAS_PLASMA = HEAT_CAP_PLASMA,
	GAS_OXYGEN = HEAT_CAP_OXYGEN,
	GAS_NITROGEN = HEAT_CAP_NITROGEN,
	GAS_CDO = HEAT_CAP_CDO,
	GAS_N2O = HEAT_CAP_N2O,
	GAS_AGENT_B = HEAT_CAP_AGENT_B
))

GLOBAL_LIST_INIT(special_gases, list(
	GAS_PLASMA = 		/datum/gas/not_reagent/plasma,
	GAS_OXYGEN =	 	/datum/gas/not_reagent/oxygen,
	GAS_NITROGEN = 		/datum/gas/not_reagent/nitrogen,
	GAS_CDO = 			/datum/gas/not_reagent/cdo,
	GAS_N2O = 			/datum/gas/not_reagent/n2o,
	GAS_AGENT_B = 		/datum/gas/not_reagent/agent_b,
))

#define isgas(A) (istype(A, /datum/gas))
#define QUANTIZE(variable)		(round(variable, 0.0001))
