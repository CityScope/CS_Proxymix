/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StroyTelling

import 'CityScope_Coronaizer.gaml'

/* Insert your model definition here */

experiment Episode1 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUCS/Level 1";
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.5;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 5.0#m;
	
}

experiment Episode2 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "num_people_room" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'People per Building (only working if density_scenario is num_people_building):' var: num_people_per_room category:'Initialization' min:0 max:100 <- 50;
}

experiment Episode3 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "num_people_building" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'People per Building (only working if density_scenario is num_people_building):' var: num_people_per_building category:'Initialization' min:0 max:1000 <- 100;
	
}

experiment Episode4 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
}

experiment Episode5 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUCS_Campus";
}