/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StoryTelling
 
import 'CityScope_Coronaizer.gaml'

/* Insert your model definition here */


experiment Episode1_Reference type: gui parent: Coronaizer{
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
}

experiment Episode1_Mask type: gui parent: Coronaizer{
	parameter 'title:' var: title category: 'Initialization' <- "Mask";
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-1.0;
}

experiment Episode1_Social_Distancing type: gui parent: Coronaizer{
	parameter 'title:' var: title category: 'Initialization' <- "Social Distancing";
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
}

experiment Episode1_Ventilation type: gui parent: Coronaizer{
	parameter 'title:' var: title category: 'Initialization' <- "Ventilation";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "AC";
}



