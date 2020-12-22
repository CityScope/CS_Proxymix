/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StoryTelling
 
import 'CityScope_Coronaizer.gaml'

/* Insert your model definition here */

experiment HighCovid type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "Andorra/High_Covid19";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 1.0 #h;
	parameter "Agenda Scenario:" category: 'Initialization' var: agenda_scenario  <-"simple";
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario 2
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"Andorra/High_Covid19",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::0.0,
		timeSpent::1.0#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,queueing::false, peopleSize::0.3#m , agenda_scenario::"simple",
		arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

