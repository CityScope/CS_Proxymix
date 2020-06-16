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
	//string dataset <- "MediaLab";
	float normal_step <- 1#s;
	float fast_step <- 5 #mn;
	bool change_step <- false update: false;
	
	float step <- normal_step on_change: {change_step <- true;};
	float separator_proba <- 0.0;
	
	string movement_model <- "pedestrian skill" among: ["moving skill","pedestrian skill"];
	float unit <- #cm;
	shape_file pedestrian_path_shape_file <- shape_file(dataset_path+ useCase+"/pedestrian_path.shp");
	date starting_date <- date([2020,4,6,7]);
	float peopleDensity<-1.0;
	geometry shape <- envelope(the_dxf_file);
	graph pedestrian_network;
	list<room> available_offices;
	
	string density_scenario <- "num_people_building" among: ["data", "distance", "num_people_building", "num_people_room"];
	int num_people_building <- 400;
	float distance_people <- 2.0 #m;
	
	bool display_pedestrian_path <- false;// parameter: true;
	bool display_free_space <- false;// parameter: true;
	
	bool draw_flow_grid <- false;
	date time_first_lunch <- nil;

	
	
	
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
				create building_entrance  with: [shape::polygon(se.points), type::type];
			} else if type in [offices, supermarket, meeting_rooms,coffee,storage] {
				create room with: [shape::polygon(se.points), type::type] ;
			}
		} 
		if (density_scenario = "num_people_building") {
			list<room> offices_list <- room where (each.type = offices);
			float tot_area <- offices_list sum_of each.shape.area;
			ask offices_list {
				num_places <- max(1,round(num_people_building * shape.area / tot_area));
			}
			int nb <- offices_list sum_of each.num_places;
			if (nb > num_people_building) and (length(offices_list) > num_people_building) {
				loop times: nb - num_people_building {
					room r <- one_of(offices_list where (each.num_places > 1));
					r.num_places <- r.num_places - 1;	
				}
			} else if (nb < num_people_building) {
				loop times: num_people_building - nb{
					room r <- one_of(offices_list);
					r.num_places <- r.num_places + 1;	
				}
			}
			
		}
		
		
		
		ask room + building_entrance {
			do intialization;
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
		loop ty over: rooms_type.keys  - [offices, entrance]{
			create activity {
				name <-  ty;
				activity_places <- rooms_type[ty];
			}
		}
		
	
		create working;
		create going_home_act with:[activity_places:: building_entrance as list];
		create eating_outside_act with:[activity_places:: building_entrance as list];
		
		available_offices <- rooms_type[offices] where each.is_available(); 
		if (movement_model = pedestrian_skill) {
			do initialize_pedestrian_model;
		}
		
		ask building_entrance {
			if (not empty(pedestrian_path)) {
				list<pedestrian_path> paths <- pedestrian_path at_distance 10.0;
				if (movement_model = "moving skill") {
					closest_path <-  paths with_min_of (each distance_to location);
				
				} else {
					closest_path <-  paths with_min_of (each.free_space distance_to location);
				
				}
				if (closest_path != nil) {
					init_place <- shape inter closest_path ;
					if (init_place = nil) {
						init_place <- (shape closest_points_with closest_path)[0]; 
					}
				}else {
					init_place <- shape; 
				}
			} else {
				init_place <- shape;
			}
		}
	}	
	
	action initialize_pedestrian_model {
		
		ask pedestrian_path {
			float dist <- max(1.0, self distance_to (wall closest_to self));
			do initialize obstacles:[wall] distance: dist;
			free_space <- free_space.geometries first_with (each overlaps shape);
		}
	}
	
	
	
	action create_people(int nb) {
		create people number: nb {
			age <- rnd(18, 70); // USE DATA TO DEFINE IT
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
			location <- any_location_in (one_of(building_entrance).init_place);
			
			date lunch_time <- date(current_date.year,current_date.month,current_date.day,11, 30) add_seconds rnd(0, 40 #mn);
			time_first_lunch <-((time_first_lunch = nil) or (time_first_lunch > lunch_time)) ? lunch_time : time_first_lunch;
			
			if (flip(0.8)) {
				agenda_day[lunch_time] <-first(eating_outside_act) ;
				lunch_time <- lunch_time add_seconds rnd(30 #mn, 90 #mn);
				if flip(0.3) {
					agenda_day[lunch_time] <- activity first_with (each.name = coffee);
					lunch_time <- lunch_time add_seconds rnd(2#mn, 10 #mn);
				}
			} else {
				activity shopping_supermarket <- activity first_with (each.name = supermarket);
				if flip(0.3) and  shopping_supermarket != nil{
					agenda_day[lunch_time] <-shopping_supermarket ;
					lunch_time <- lunch_time add_seconds rnd(120, 10 #mn);
				}
				if flip(0.5) {
					agenda_day[lunch_time] <- activity first_with (each.name = coffee);
					lunch_time <- lunch_time add_seconds rnd(5#mn, 30 #mn);
				}	
			}
			
			agenda_day[lunch_time] <- first(working);
			agenda_day[date(current_date.year,current_date.month,current_date.day,18, rnd(30),rnd(59))] <- first(going_home_act);
		}
		
		
	}
	
	reflex change_step {
		if (current_date.hour >= 7 and current_date.minute > 3 and empty(people where (each.target != nil)))  {
			step <- fast_step;
		}
		if (time_first_lunch != nil and current_date.hour = time_first_lunch.hour and current_date.minute > time_first_lunch.minute){
			step <- normal_step;
		}
		if (current_date.hour >= 12 and current_date.minute > 5 and empty(people where (each.target != nil)))  {
			step <- fast_step;
		} 
		if (current_date.hour = 18){
			step <- normal_step;
		}
		if (not empty(people where (each.target != nil))) {
			step <- normal_step;
		}
		
	}
	
	
	reflex end_simulation when: current_date.hour > 12 and empty(people) {
		do pause;
	}
	
	reflex people_arriving when: not empty(available_offices) and every(2 #s)
	{	
		  do create_people(rnd(0,min(3, length(available_offices))));
	}
}

species pedestrian_path skills: [pedestrian_road] {
	aspect default {
		if (display_pedestrian_path) {
			if(display_free_space and free_space != nil) {draw free_space color: #lightpink border: #black;}
			draw shape color: #red;
		}
		
	}
}


species separator_ag {
	list<place_in_room> places_concerned; 
	aspect default {
		draw shape color: #lightblue;
	}
}
species wall {
	aspect default {
		draw shape color: #gray;
	}
}

species room {
	int nb_affected;
	string type;
	pedestrian_path closest_path;
	geometry init_place;
	list<point> entrances;
	list<place_in_room> places;
	list<place_in_room> available_places;
	int num_places;
	
	action intialization {
		list<geometry> squares;
		if (density_scenario = "distance") or (type != offices) {
			squares <-  to_squares(shape, distance_people, true) where (each.location overlaps shape);
		}
		else if density_scenario in ["num_people_building", "num_people_room"] {
			int nb <- num_places;
			loop while: length(squares) < num_places {
				squares <-  num_places = 0 ? []: to_squares(shape, nb, true) where (each.location overlaps shape);
				nb <- nb +1;
			}
			if (length(squares) > num_places) {
				squares <- num_places among squares;
			}
		} 
		if not empty(squares) {
			map<geometry, place_in_room> pr;
			loop g over: squares{
				create place_in_room {
					location <- g.location;
					pr[g] <- self;
					myself.places << self;
				}
			} 
			
			if empty(places) {
				create place_in_room {
					location <- myself.location;
					myself.places << self;
				}
			} 
			
			if (length(places) > 1 and separator_proba > 0.0) {
				graph g <- as_intersection_graph(squares, 0.01);
				list<list<place_in_room>> ex;
				loop e over: g.edges {
					geometry s1 <- (g source_of e);
					geometry s2 <- (g target_of e);
					place_in_room pr1 <- pr[s1];
					place_in_room pr2 <- pr[s2];
					if not([pr1,pr2] in ex) and not([pr2,pr1] in ex) {
						ex << [pr1,pr2];
						if flip(separator_proba) {
							geometry sep <- ((s1 + 0.1)  inter (s2 + 0.1)) inter self;
							create separator_ag with: [shape::sep,places_concerned::[pr1,pr2]];
						}
					}
				}
			}
					
			available_places <- copy(places);
		}
	
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
		loop e over: entrances {draw square(0.2) at: {e.location.x,e.location.y,0.001} color: #magenta border: #black;}
		loop p over: available_places {draw square(0.2) at: {p.location.x,p.location.y,0.001} color: #cyan border: #black;}
	}
}

species building_entrance parent: room {
	place_in_room get_target(people p){
		return place_in_room closest_to p;
	}
	
	aspect default {
		draw shape color: standard_color_per_layer[type];
		draw init_place color:#magenta border: #black;
		loop e over: entrances {draw square(0.1) at: e color: #magenta border: #black;}
		loop p over: available_places {draw square(0.1) at: p.location color: #cyan border: #black;}
	}
}

species activity {
	list<room> activity_places;
	
	room get_place(people p) {
		if flip(0.3) {
			return one_of(activity_places with_max_of length(each.available_places));
		} else {
			list<room> rs <- (activity_places where not empty(each.available_places));
			if empty(rs) {
				rs <- activity_places;
			}
			return rs closest_to p;
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

species eating_outside_act parent: activity  {
	string name <- eating_outside;
	room get_place(people p) {
		return building_entrance closest_to p;
	}
}

species place_in_room {
	float dists;
}

species people skills: [escape_pedestrian] {
	int age <- rnd(18,70); // HAS TO BE DEFINED !!!
	room working_place;
	map<date, activity> agenda_day;
	activity current_activity;
	point target;
	room target_room;
	bool has_place <- false;
	place_in_room target_place;
	bool goto_entrance <- false;
	bool go_oustide_room <- false;
	bool is_outside;
	rgb color <- #white;//rnd_color(255);
	float speed <- min(5,gauss(4,1)) #km/#h;
	
	
	aspect default {
		if not is_outside{
			draw circle(0.3) color:color border: #black;
		}
	}
	
	
	reflex updateFlowCell when:not is_outside{
		ask (flowCell overlapping self.location){
			nbPeople<-nbPeople+1;
		}
	}
	reflex define_activity when: not empty(agenda_day) and 
		(after(agenda_day.keys[0])){
		if(target_place != nil and (has_place) ) {target_room.available_places << target_place;}
		string n <- current_activity = nil ? "" : copy(current_activity.name);
		current_activity <- agenda_day.values[0];
		
		agenda_day >> first(agenda_day);
		target <- target_room.entrances closest_to self;
		target_room <- current_activity.get_place(self);
		go_oustide_room <- true;
		is_outside <- false;
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
				if (species(target_room) = building_entrance) {
					is_outside <- true;
				}
				if (current_activity.name = going_home) {
					do die;
				}
			}	
		}
 	}
}

grid flowCell cell_width: world.shape.width/200 cell_height:world.shape.width/200  {
	rgb color <- #white;
	int nbPeople;
	aspect default{
		if (draw_flow_grid){
			if(nbPeople>1){
			  draw shape color:blend(#red,#white, nbPeople/50)  depth:nbPeople/1000;		
			}
		}
	}	
}



experiment DailyRoutine type: gui parent: DXFDisplay{
	parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" among: ["Factory", "MediaLab","Learning_Center","ENSAL","SanSebastian"];
	parameter "num_people_building" var: density_scenario category:'Initialization' among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'density:' var: peopleDensity category:'Initialization' min:0.0 max:1.0 <- 1.0;
	parameter "unit" var: unit category: "file" <- #cm;
	parameter "Draw Flow Grid:" category: "Visualization" var:draw_flow_grid;
	parameter "Draw Pedestrian Path:" category: "Visualization" var:display_pedestrian_path;

	output {
		display map synchronized: true background:#black parent:floorPlan type:opengl draw_env:false{
			species room  refresh: false;
			species building_entrance refresh: false;
			species wall refresh: false;
			species pedestrian_path ;
			species people;
			species separator_ag refresh: false;
			species flowCell;
			graphics 'date'{
			  point legendPos<-{world.shape.width*0,0};
			 draw string("Time: " + current_date.hour + "h:" + current_date.minute+ "m") color: #white at: legendPos perspective: true font:font("Helvetica", 20 , #bold); 	
		    }
		    graphics 'simulation'{
		    	point simulegendPos<-{world.shape.width*0,world.shape.height*0.05};
		    	 draw string("People: " + length(people)) color: #white at: simulegendPos perspective: true font:font("Helvetica", 20 , #bold); 
		    	 draw string("Density: " + peopleDensity*100 + "%") color: #white at: {simulegendPos.x,simulegendPos.y+20#px} perspective: true font:font("Helvetica", 20 , #bold);
		    
		    }
		}
	}
}

