/***
* Name: COVID
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model COVID

import "Constants.gaml"
import "./../ToolKit/DXF_Loader.gaml" 

global {
	string dataset <- "Factory";
	string movement_model <- "pedestrian skill" among: ["moving skill","pedestrian skill"];
	float unit <- #cm;
	shape_file pedestrian_path_shape_file <- shape_file(dataset_path+ useCase+"/pedestrian_path.shp");
	date starting_date <- date([2020,4,6,7]);
	int nb_people <- 300;
	geometry shape <- envelope(the_dxf_file);
	graph pedestrian_network;
	list<room> available_offices;
	list<room> entrances;
	
	
	init {
		validator <- false;
	
		do initiliaze_dxf;
		create pedestrian_path from: pedestrian_path_shape_file;
		pedestrian_network <- as_edge_graph(pedestrian_path);
		loop se over: the_dxf_file  {
			string type <- se get layer;
			
			if (type = walls) {
				create wall with: [shape::clean(polygon(se.points))];
			} else if type = entrance {
				create building_entrance  with: [shape::polygon(se.points), type::type] {
					do intialization;
				}
			} else if type in [offices, supermarket, meeting_rooms,coffee,storage] {
				create room with: [shape::polygon(se.points), type::type] {
					do intialization;
					
				}
				
			}
		} 
		ask wall {
			if not empty((room + building_entrance) inside self ) {
				shape <- shape.contour;
			}
		}
		ask room {
			list<wall> ws <- wall overlapping self;
			loop w over: ws {
				if w covers self {
					do die;
				}
			}
		}
		ask room + building_entrance{
			geometry contour <- nil;
			float dist <-0.3;
			loop while: contour = nil {
				contour <- copy(shape.contour);
				ask wall at_distance 1.0 {
					contour <- contour - (shape +dist);
				}
				ask (room + building_entrance) at_distance 1.0 {
					contour <- contour - (shape + dist);
				}
				dist <- dist * 0.5;	
			} 
			if contour != nil {
				entrances <- points_on (contour, 2.0);
			}
			ask places {
				point pte <- myself.entrances closest_to self;
				dists <- self distance_to pte;
			}
					
		}
		map<string, list<room>> rooms_type <- room group_by each.type;
		entrances <-list(building_entrance);
		loop ty over: rooms_type.keys  - [offices, entrance]{
			create activity {
				name <-  ty;
				activity_places <- rooms_type[ty];
			}
		}
		create working;
		create going_home_act with:[activity_places:: entrances];
		
		available_offices <- rooms_type[offices] where each.is_available(); 
		
		if (movement_model = pedestrian_skill) {
			do initialize_pedestrian_model;
		}
	}	
	
	action initialize_pedestrian_model {
		geometry walking_area_g <- copy(shape);
		ask room + wall {
			walking_area_g <- walking_area_g - (shape + 0.01);
			walking_area_g <- walking_area_g.geometries with_max_of each.area;
		}
			
		ask pedestrian_path {
			float dist <- max(1.0, self distance_to (wall closest_to self));
			do initialize obstacles:[wall, room] distance: dist;
			free_space <- free_space inter walking_area_g;
			free_space <- free_space.geometries first_with (each overlaps shape);
		}
	}
	
	
	
	action create_people(int nb) {
		create people number: nb {
			pedestrian_model <- SFM;
			obstacle_species <- [people, wall];
			working_place <- one_of (available_offices);
			working_place.nb_affected <- working_place.nb_affected + 1;
			if not(working_place.is_available()) {
				available_offices >> working_place;
			}
			current_activity <- first(working);
			target_room <- current_activity.get_place(self);
			target <- target_room.entrances closest_to self;
			
			goto_entrance <- true;
			location <- any_location_in (one_of(entrances));
			date lunch_time <- date(current_date.year,current_date.month,current_date.day,11, 30) add_seconds rnd(0, 40 #mn);
			
			if flip(0.3) {agenda_day[lunch_time] <- activity first_with (each.name = supermarket);}
			lunch_time <- lunch_time add_seconds rnd(120, 10 #mn);
			agenda_day[lunch_time] <- activity first_with (each.name = coffee);
			lunch_time <- lunch_time add_seconds rnd(5#mn, 30 #mn);
			agenda_day[lunch_time] <- first(working);
			agenda_day[date(current_date.year,current_date.month,current_date.day,18, rnd(30),rnd(59))] <- first(going_home_act);
			
		}
		
	}
	
	reflex change_step {
		if (current_date.hour >= 7 and current_date.minute > 10 and empty(people where (each.target != nil)))  {
			step <- 5#mn;
		}
		if (current_date.hour = 11 and current_date.minute > 30){
			step <- 1#s;
		}
		if (current_date.hour >= 12 and current_date.minute > 5 and empty(people where (each.target != nil)))  {
			step <- 5 #mn;
		} 
		if (current_date.hour = 18){
			step <- 1#s;
		}
		if (not empty(people where (each.target != nil))) {
			step <- 1#s;
		}
	}
	
	reflex end_simulation when: after(starting_date add_hours 13) {
		do pause;
	}
	
	reflex people_arriving when: not empty(available_offices) 
	{
		do create_people(rnd(0,min(5, length(available_offices))));
	}
}

species pedestrian_path skills: [pedestrian_road];

species wall {
	aspect default {
		draw shape color: #gray;
	}
}

species room {
	int nb_affected;
	string type;
	list<point> entrances;
	list<place_in_room> places;
	list<place_in_room> available_places;
	
	action intialization {
		loop g over: to_squares(shape, 1.5, true) where (each.location overlaps shape){
			create place_in_room {
				location <- g.location;
				myself.places << self;
			}
		} 
		if empty(places) {
			create place_in_room {
				location <- myself.location;
				myself.places << self;
			}
		} 
				
		available_places <- copy(places);
	}
	bool is_available {
		return nb_affected < length(places);
	}
	place_in_room get_target(people p){
		place_in_room place <- (available_places with_max_of each.dists);
		available_places >> place;
		return place;
	}
	
	aspect default {
		draw shape color: standard_color_per_layer[type];
		loop e over: entrances {draw square(0.1) at: e color: #magenta border: #black;}
		loop p over: available_places {draw square(0.1) at: p.location color: #cyan border: #black;}
	}
}

species building_entrance parent: room {
	place_in_room get_target(people p){
		return place_in_room closest_to p;
	}
}

species activity {
	list<room> activity_places;
	
	room get_place(people p) {
		if flip(0.3) {
			return one_of(activity_places with_max_of length(each.available_places));
		} else {
			return (activity_places where not empty(each.available_places)) closest_to p;
		}
		
	}
	
}

species working parent: activity {
	
	room get_place(people p) {
		return p.working_place;
	}
}

species going_home_act parent: activity  {
	string name <- going_home;
	room get_place(people p) {
		return building_entrance closest_to p;
	}
}

species place_in_room {
	float dists;
}

species people skills: [escape_pedestrian] {
	room working_place;
	map<date, activity> agenda_day;
	activity current_activity;
	point target;
	room target_room;
	bool has_place <- false;
	place_in_room target_place;
	bool goto_entrance <- false;
	bool go_oustide_room <- false;
	rgb color <- rnd_color(255);
	float speed <- min(2,gauss(4,1)) #km/#h;
	
	
	aspect default {
		draw circle(0.3) color:color border: #black;
	}
	reflex define_activity when: not empty(agenda_day) and 
		(after(agenda_day.keys[0])){
		if(target_place != nil and (has_place) ) {target_room.available_places << target_place;}
		
		current_activity <- agenda_day.values[0];
		agenda_day >> first(agenda_day);
		target <- target_room.entrances closest_to self;
		target_room <- current_activity.get_place(self);
		go_oustide_room <- true;
		goto_entrance <- false;
		target_place <- nil;
	}
	
	reflex goto_activity when: target != nil{
		bool arrived <- false;
		if goto_entrance {
			if (movement_model = moving_skill) {
				do goto target: target on: pedestrian_network;
				arrived <- location = target;
			} else {
				if (final_target = nil) {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target ;
				}
				do walk;
				arrived <- final_target = nil;
			}
		}
		else {
			do goto target: target;
			arrived <- location = target;
		}
		if(arrived) {
			if (go_oustide_room) {
				target <- target_room.entrances closest_to self;
				go_oustide_room <- false;
				goto_entrance <- true;
			}
			else if (goto_entrance) {
				target_place <- target_room.get_target(self);
				if target_place != nil {
					target <- target_place.location;
					goto_entrance <- false;
				} else {
					room tr <- current_activity.get_place(self);
					if (tr != nil ) {
						target_room <- tr;
						target <- target_room.entrances closest_to self;
					}
				}
			} else {
				has_place <- true;
				target <- nil;
				if (current_activity.name = going_home) {
					do die;
				}
			}	
		}
 	}
}



experiment COVID type: gui parent: DXFDisplay{
	parameter 'fileName:' var: useCase category: 'file' <- "Factory" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL"];
	parameter "unit" var: unit category: "file" <- #cm;
	output {
		display map synchronized: true parent:floorPlan type:opengl{
			species room;
			species building_entrance;
			species wall;
			species people;
		}
	}
}

experiment COVIDMulti type: gui {
	
	init{
		create simulation with: [useCase::"MediaLab", unit::#cm];
		create simulation with: [useCase::"Hotel-Dieu",unit::#cm ];
		create simulation with: [useCase::"Learning_Center_Lyon",unit::#cm ];
	}
	parameter 'fileName:' var: useCase category: 'file' <- "Factory" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL"];
	parameter "unit" var: unit category: "file" <- #cm;
	output {
		display map synchronized: true {
			species room;
			species building_entrance;
			species wall;
			species people;
		}
	}
}
