/**
* Name: StroyTelling
* Based on the internal empty template. 
* Author: arno
* Tags: 
*/



model StoryTelling
 
import 'CityScope_Coronaizer.gaml'

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


experiment FullBenchMarkHeadless type: gui parent: CoronaizerHeadless{
	string usecase<-"UDG/CUCS/Level 2";// 1."UDG/CUCS/Level 2" 2.!!!!DOESN'TWORK"UDG/CUT/lab" 3."UDG/CUAAD" 4. "UDG/CUCEA" 5."UDG/CUSUR" 0."MediaLab"
	string scenario<-"simple";
	float timespent<-2.0#h;
	parameter 'fileName:' var: useCase category: 'Initialization' <- usecase;
	init
	{   
		create simulation with: [title::"Mask", maskRatio::1.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Social Distance", maskRatio::0.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Ventilation",maskRatio::0.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];

		create simulation with: [title::"Mask/Social Distance",maskRatio::1.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Mask/Ventilation",maskRatio::1.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Social Distance/Ventilation",maskRatio::0.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::2.0#h];
		
		create simulation with: [title::"All",maskRatio::1.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
	}
}

experiment FullBenchMark type: gui parent: Coronaizer{
	string usecase<-"UDG/CUCS/Level 2";// 1."UDG/CUCS/Level 2" 2.!!!!DOESN'TWORK"UDG/CUT/lab" 3."UDG/CUAAD" 4. "UDG/CUCEA" 5."UDG/CUSUR" 0."MediaLab"
	string scenario<-"simple";
	float timespent<-2.0#h;
	parameter 'fileName:' var: useCase category: 'Initialization' <- usecase;
	init
	{   
		create simulation with: [title::"Mask", maskRatio::1.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Social Distance", maskRatio::0.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Ventilation",maskRatio::0.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];

		create simulation with: [title::"Mask/Social Distance",maskRatio::1.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Mask/Ventilation",maskRatio::1.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
		
		create simulation with: [title::"Social Distance/Ventilation",maskRatio::0.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::2.0#h];
		
		create simulation with: [title::"All",maskRatio::1.0,density_scenario::'distance',distance_people::2.0#m, ventilationType::"AC",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
	}
}