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
	//Scenario 1
	parameter 'title:' var: title category: 'file' <- "Scenario A: No intervention";
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "Classrooms and Offices";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.3#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";


	//Scenario 2
	init
	{   
		create simulation with: [title::"Scenario B: Mask and Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms and Offices",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::0.5,queueing::true, peopleSize::0.3#m , agenda_scenario::"simple"];
	}
}

experiment Episode2 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUT/room104";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.15#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	//Scenario 2
	init
	{   
		create simulation with: [useCase::"UDG/CUT/lab",useCaseType::"Labs",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"data",distance_people::2.0#m,maskRatio::0.5,queueing::true, peopleSize::0.15#m,agenda_scenario::"simple"];

	}
}

experiment Episode3 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUAAD";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.2#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	//Scenario 2
	init
	{   
		create simulation with: [useCase::"UDG/CUAAD",useCaseType::"Labs",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::0.5,queueing::true, peopleSize::0.2#m,agenda_scenario::"simple"];

	}
}

experiment Episode4 type: gui parent: Coronaizer{
	//Scenario 1

	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUCEA";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.4#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	//Scenario 2
	init
	{   
		create simulation with: [useCase::"UDG/CUCEA",useCaseType::"Labs",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::0.5,queueing::true, peopleSize::0.4#m,agenda_scenario::"simple"];

	}
}

experiment Episode5 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUSUR";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-2.0#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	//Scenario 2
	init
	{   
		create simulation with: [useCase::"UDG/CUSUR",useCaseType::"Labs",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::0.5,queueing::true, peopleSize::2.0#m,agenda_scenario::"simple"];

	}
}