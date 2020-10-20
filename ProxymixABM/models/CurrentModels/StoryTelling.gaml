/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StoryTelling
 
import 'CityScope_Coronaizer.gaml'

/* Insert your model definition here */

experiment Mask type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 1.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::0.0,
		timeSpent::1.0#h,density_scenario::'data',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment SocialDistance type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 1.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 1.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::0.0,
		timeSpent::1.0#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment Time type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 1.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::0.0,
		timeSpent::0.75#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment Ventilation type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "AC";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 1.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::1.0,
		timeSpent::0.75#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment Sanitation type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUAAD";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "AC";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 1.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUAAD",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::1.0,use_sanitation::true,nb_people_per_sanitation::2, sanitation_usage_duration::20#s,
		proba_using_before_work::1.0, proba_using_after_work::0.5,
		timeSpent::0.75#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment Rerouting type: gui parent: Coronaizer{
	//Scenario without Mask
	parameter 'Episode:' var: episode category: 'Initialization' <- 1;
	parameter 'title:' var: title category: 'Initialization' <- "No intervention";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUAAD";
	parameter 'useCaseType:' var: useCaseType category: 'Initialization' <- "Classrooms";
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "AC";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 1.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Ventilated room ratio:" category: "Policy" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "People Size:" category: "Visualization" var: peopleSize  <-0.3#m;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario with Mask
	init
	{   
		create simulation with: [episode::1,title::"Mask/Social Distancing",useCase::"UDG/CUAAD",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::1.0,use_sanitation::true,nb_people_per_sanitation::2, sanitation_usage_duration::20#s,
		proba_using_before_work::1.0, proba_using_after_work::0.5,
		timeSpent::0.75#h,density_scenario::'distance',distance_people::2.0#m,maskRatio::1.0,peopleSize::0.3#m ,arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

