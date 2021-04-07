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


experiment FullBenchMarkPLOT type:gui parent: CoronaizerHeadless parallel: false{
	string usecase<-"UDG/CUCEA";// 1."UDG/CUCS/Level 2" 2.!!!!DOESN'TWORK"UDG/CUT/lab" 3."UDG/CUAAD" 4. "UDG/CUCEA" 5."UDG/CUSUR" 0."MediaLab"
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


experiment Headless type:batch repeat: 2 until: ((people count not each.end_of_day) = 0) and time > (arrival_time_interval + 10) parent:Coronaizer{//parent: CoronaizerHeadless{
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2" among: ["UDG/CUCS/Campus","UDG/CUSUR","UDG/CUCEA","UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	parameter agenda_scenario var: agenda_scenario<-"simple";
	parameter timeSpent var: timeSpent <-2.0#h ;
	parameter title var: title <- "Reference";
	parameter maskRatio var: maskRatio <-0.0 ;
	parameter density_scenario var:density_scenario <-"data" ;
	parameter distance_people var: distance_people <-2.0#m;
	parameter ventilationType var: ventilationType<-"Natural" ;
	parameter 'fileName:' var: useCase category: 'Initialization' <- useCase;

}

experiment FullBenchMarkHeadless type:batch repeat: 1 until: ((people count not each.end_of_day) = 0) and time > (arrival_time_interval + 10) parallel:false{//parent: CoronaizerHeadless{
	string usecase<-"MediaLab";// 1."UDG/CUCS/Level 2" 2.!!!!DOESN'TWORK"UDG/CUT/lab" 3."UDG/CUAAD" 4. "UDG/CUCEA" 5."UDG/CUSUR" 0."MediaLab"
	string scenario<-"simple";
	float timespent<-2.0#h;
	parameter useCase var: useCase<-usecase ;
	parameter agenda_scenario var: agenda_scenario<-scenario;
	parameter timeSpent var: timeSpent <-timespent;
	parameter title var: title <- "Mask";
	parameter maskRatio var: maskRatio <-1.0 ;
	
	parameter density_scenario var:density_scenario <-"data" ;
	parameter distance_people var: distance_people <-2.0#m;
	parameter ventilationType var: ventilationType<-"Natural" ;
	
	parameter 'fileName:' var: useCase category: 'Initialization' <- useCase;
	
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

experiment GUI type:gui parent: CoronaizerHeadless{
	string usecase<-"UDG/CUCS/Level 2";
	string scenario<-"simple";
	float timespent<-2.0#h;
	parameter 'fileName:' var: useCase category: 'Initialization' <- usecase;
	init
	{   
		create simulation with: [title::"Mask", maskRatio::1.0,density_scenario::'data',distance_people::2.0#m, ventilationType::"Natural",
		useCase::usecase,agenda_scenario::scenario,timeSpent::timespent];
	}
}

experiment FullBenchMark type: gui parent: Coronaizer parallel: false{
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

experiment stochasticity_analysis type: batch repeat: 100 until: ((people count not each.end_of_day) = 0) and time > (arrival_time_interval + 10) {
	parameter batch_mode var:batch_mode <- true among: [true];
	parameter type_explo  var:type_explo <- "stochasticity" among: ["stochasticity"];

	parameter "Agenda Scenario:" category: 'Initialization' var: agenda_scenario  <-"simple" among: ["simple"];
	parameter "Mask Ratio:" category: "Policy" var: maskRatio <-0.0  among: [0.0];
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "data"  among: ["data"];
	parameter 'distance people:' var: distance_people category:'Policy' <- 2.0#m  among: [2.0#m ];
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural"  among: ["Natural"];
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 2.0 #h  among: [2.0 #h];
	
	parameter "Show available desk:" category: "Visualization" var:showAvailableDesk <-false  among: [false];
	parameter "Show bottlenecks:" category: "Visualization" var:show_dynamic_bottleneck <-false  among: [false];
	parameter "Show droplets:" category: "Visualization" var:show_droplet <-false  among: [false];
		
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2"  among: ["UDG/CUCS/Level 2"];

}