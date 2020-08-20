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
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.9;
	
}

experiment Episode2 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
}

experiment Episode3 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
}

experiment Episode4 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUT";
}

experiment Episode5 type: gui parent: Coronaizer{
	parameter 'fileName:' var: useCase category: 'file' <- "CUCS_Campus";
}