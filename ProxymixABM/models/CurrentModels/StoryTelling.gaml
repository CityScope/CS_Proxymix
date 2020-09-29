/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StoryTelling
 
import 'CityScope_Coronaizer.gaml'

/* Insert your model definition here */

experiment Episode1 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'Episode:' var: episode category: 'file' <- 1;
	parameter 'title:' var: title category: 'file' <- "Scenario A: No intervention";
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUCS/Level 2";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "Classrooms";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0 #h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.3#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	parameter "Ventilated room ratio:" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "step_arrival" var: step_arrival <- 1#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 3 #mn;
	//Scenario 2
	init
	{   
		create simulation with: [episode::1,title::"Scenario B: Mask/Social Distancing",useCase::"UDG/CUCS/Level 2",useCaseType::"Classrooms",
		ventilationType::"Natural",ventilation_ratio::0.0,
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::1.0,queueing::true, peopleSize::0.3#m , agenda_scenario::"simple",
		arrival_time_interval:: 3#mn, step_arrival::1#s];
	}
}

experiment Episode2 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'Episode:' var: episode category: 'file' <- 2;
	parameter 'title:' var: title category: 'file' <- "Scenario A: Air Conditioning";
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUT/lab";
	parameter 'Workplace layer name' var: workplace_layer category: "file" <- ["Labs"];
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'initial infected:' var: initial_nb_infected category: 'Initialization' <- 5;
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 45#mn;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.15#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	//DROPLET PARAMETER
	parameter "Show droplets:" category: "Droplet" var:show_droplet <-false;
	parameter "Droplets lifespan:" category: "Droplet" var:droplet_livespan min:0 max:100 <-5;
	parameter "Droplets distance:" category: "Droplet" var:droplet_distance min:0.0 max:10.0 <-1.0;
	parameter "Ventilated room ratio:" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "Normal step" var: normal_step <- 0.2;
	parameter "step_arrival" var: step_arrival <- 0.2#s;
	parameter "step_arrival" var: fast_step <- 5#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 20#s;
	parameter "limit_cpt_for_entrance_room_creation" var: limit_cpt_for_entrance_room_creation <-2;
	parameter "Map Scale :" category: "Ventilation" var:base_scale min:0.0 max:100.0 <-1#m;
 	
	//Scenario 2
	init
	{   
		create simulation with: [episode::2,title::"Scenario B: Natural Ventilation",useCase::"UDG/CUT/lab",useCaseType::"Labs",ventilationType::"AC",ventilation_ratio::1.0,
		initial_nb_infected::5,timeSpent::45#mn,workplace_layer::["Labs"],density_scenario::"distance",distance_people::2.0#m,maskRatio::1.0,queueing::false, peopleSize::0.15#m,agenda_scenario::"simple",
		show_droplet::false,droplet_livespan::20,droplet_distance::1.0, fast_step::5.0,normal_step::0.2,arrival_time_interval:: 20#s, step_arrival::0.2#s,limit_cpt_for_entrance_room_creation::2,base_scale::1#m];

	}
}

experiment Episode3 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUAAD";
	parameter 'title:' var: title category: 'file' <- "Scenario A: No intervention";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 3.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.2#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	parameter "Ventilated room ratio:" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "step_arrival" var: step_arrival <- 3#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 5#mn;
	parameter "tolerance_target_param" var: tolerance_target_param <- 2.0;
	parameter "Map Scale :" category: "Ventilation" var:base_scale min:0.0 max:100.0 <-1#m;
	//Scenario 2
	init
	{   
		create simulation with: [title::"Scenario B: Sanitation ",useCase::"UDG/CUAAD",useCaseType::"Labs",ventilationType::"Natural", use_sanitation::true,nb_people_per_sanitation::2, sanitation_usage_duration::20#s,
		proba_using_before_work::1.0, proba_using_after_work::0.5,step_arrival::3, arrival_time_interval::5#mn,tolerance_target_param::2.0,
		timeSpent::45#mn,density_scenario::"distance",distance_people::1.5#m,maskRatio::1.0,queueing::true, peopleSize::0.2#m,agenda_scenario::"simple",ventilation_ratio::0.0,base_scale::1#m];

	}
}

experiment Episode4 type: gui parent: Coronaizer{
	//Scenario 1

	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUCEA";
	parameter 'title:' var: title category: 'file' <- "Scenario A: No intervention";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "Labs";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 1.0#h;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 2.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-0.4#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	parameter "Ventilated room ratio:" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "step_arrival" var: step_arrival <- 3#s;
	parameter "arrival_time_interval" var: arrival_time_interval <- 10#mn;
	//Scenario 2
	parameter use_change_step var: use_change_step <- false;
	
	init
	{   
		create simulation with: [title::"Scenario B: Mask",useCase::"UDG/CUCEA",useCaseType::"Labs",ventilationType::"Natural",use_change_step::false,step_arrival::3, arrival_time_interval::10#mn,
		timeSpent::1.0#h,density_scenario::"distance",distance_people::1.5#m,maskRatio::1.0,queueing::true, peopleSize::0.4#m,agenda_scenario::"simple",ventilation_ratio::0.0];
		
	}
}

experiment Episode5 type: gui parent: Coronaizer{
	//Scenario 1
	parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUSUR";
	parameter 'title:' var: title category: 'file' <- "Scenario A: No intervention";
	parameter 'useCaseType:' var: useCaseType category: 'file' <- "lab";
	parameter 'ventilationType:' var: ventilationType category: 'file' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'file' <- 45#mn;
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 4.0#m;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Queueing:" category: "Policy" var: queueing  <-false;
	parameter "People Size:" category: "Policy" var: peopleSize  <-2.0#m;
	parameter "Agenda Scenario:" category: "Policy" var: agenda_scenario  <-"simple";
	parameter "Ventilated room ratio:" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.0;
	parameter "Map Scale :" category: "Ventilation" var:base_scale min:0.0 max:100.0 <-25#m;
	//Scenario 2
	init
	{   
		create simulation with: [title::"Scenario B: Dedicated path",useCase::"UDG/CUSUR",useCaseType::"Labs",ventilationType::"Natural",
		timeSpent::45#mn,density_scenario::"distance",distance_people::2.0#m,maskRatio::0.5,queueing::false, peopleSize::2.0#m,agenda_scenario::"simple",ventilation_ratio::0.0,base_scale::25#m];
	}
}