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
	string usecase<-"IDB/Level 1";// 1."UDG/CUCS/Level 2" 2.!!!!DOESN'TWORK"UDG/CUT/lab" 3."UDG/CUAAD" 4. "UDG/CUCEA" 5."UDG/CUSUR"
	string scenario<-"shopping";
	
	int to_create_init <- 500;
	int nb_agents_to_create <- 2000;
	float arrival_time_interval <-2#h;
	float step_arrival_<- 1 #mn;
	
	int max_num_waypoints <- 5; 
	float max_activity_time <- 10 #mn;
	float distance_waypoints <- 5.0; // distance of the waypoints to the shortest path
	
	
	float timespent<-2.0#h;
	parameter 'fileName:' var: useCase category: 'Initialization' <- usecase;
	action _init_
	{   
		create simulation with: (title:"No Mask", maskRatio:0.0,max_num_waypoints:max_num_waypoints,max_activity_time:max_activity_time,distance_waypoints:distance_waypoints, step_arrival:step_arrival, arrival_time_interval: arrival_time_interval, to_create_init:to_create_init, nb_agents_to_create: nb_agents_to_create, density_scenario:'fill_with_agents',distance_people: 3.0, distance_people:2.0#m, ventilationType:"Natural",
		useCase:usecase,agenda_scenario:scenario,timeSpent:timespent, use_change_step: false);
		 
		 create simulation with: (title:"With Mask", maskRatio:1.0,max_num_waypoints:max_num_waypoints,max_activity_time:max_activity_time,distance_waypoints:distance_waypoints, step_arrival:step_arrival, arrival_time_interval: arrival_time_interval, to_create_init:to_create_init, nb_agents_to_create: nb_agents_to_create, density_scenario:'fill_with_agents',distance_people: 3.0, distance_people:2.0#m, ventilationType:"Natural",
		useCase:usecase,agenda_scenario:scenario,timeSpent:timespent, use_change_step: false);
		
		// create simulation with: (title:"With Mask", maskRatio:1.0, arrival_time_interval: arrival_time_interval, to_create_init:to_create_init, nb_agents_to_create: nb_agents_to_create, density_scenario:'fill_with_agents',distance_people: 3.0, distance_people:2.0#m, ventilationType:"Natural",
		//useCase:usecase,agenda_scenario:scenario,timeSpent:timespent, use_change_step: false);
		
		//create simulation with: (title:"With Mask", maskRatio:1.0,density_scenario:'fill_with_agents',distance_people: 3.0, distance_people:2.0#m, ventilationType:"Natural",
		//useCase:usecase,agenda_scenario:scenario,timeSpent:timespent, use_change_step: false);
	
	}
}

