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
	
	list<string> workplace_layer <- [offices, meeting_rooms];
	float normal_step <- 10#s;
	float fast_step <- 10#s;
	bool use_change_step <- true;
	bool synchronized_step <- true;
	
	float tolerance_target_param <- 1.0;
	string agenda_scenario <- "simple" among: ["simple", "custom", "classic day"];
	float step_arrival <- 5#s;
	float arrival_time_interval <- 0#mn;//15 #mn;
	
	float proba_goto_common_area <- 0.4;
	float proba_wander <- 0.003;
	float wandering_time <- 1 #mn;
	float proba_change_desk <- 0.003;
	//QUEING PARAMETERS
	float distance_queue <- 0.5#m;
	bool queueing <- false;
	float waiting_time_entrance <- 5#s;
	bool first_end_sim <- true;
	//SANITATION PARAMETERS 	
	bool use_sanitation <- false;
	float proba_using_before_work <- 0.7;
	float proba_using_after_work <- 0.3;
	int nb_people_per_sanitation <- 2;
	float sanitation_usage_duration <- 5 #s;
	
	// DARK PARAMETERS
	int limit_cpt_for_entrance_room_creation <- 10;
	
	map<date,int> people_to_create;
	float step <- normal_step;
	float separator_proba <- 0.0;
	
	string movement_model <- "pedestrian skill" among: ["moving skill","pedestrian skill"];
	float unit <- #cm;
	shape_file pedestrian_path_shape_file <- shape_file(dataset_path+ useCase+"/pedestrian_path.shp", gama.pref_gis_default_crs);
	date starting_date <- date([2020,4,6,7]);
	geometry shape <- envelope(the_dxf_file);
	graph pedestrian_network;
	list<room> available_offices;
	float peopleSize<-0.1#m;
	
	list<room> sanitation_rooms;
	
	string density_scenario <- "distance" among: ["data", "distance", "num_people_building", "num_people_room"];
	int num_people_per_building;
	int num_people_per_room;
	float distance_people;
	
	bool display_pedestrian_path <- false;// parameter: true;
	bool display_free_space <- false;// parameter: true;
	
	bool draw_flow_grid <- false;
	bool draw_proximity_grid <- false;
	bool showAvailableDesk<-false;
	
	bool parallel <- false; // use parallel computation
	

	float proximityCellSize <- 0.5; // size of the cells (in meters)
	int proximityCellmaxNumber <- 300 ;
	bool use_masked_by <- false; //far slower, but useful to obtain more realistic map
	float precision <- 120.0; //only necessary when using masked_by operator
	
	date time_first_lunch <- nil;
	
	bool drawSocialDistanceGraph <- false;
	graph<people, people> social_distance_graph <- graph<people, people>([]);
	float R0;

	//SPATIO TEMPORAL VALUES COMPUTED ONLY ONES
	int nbOffices;
	float totalArea;	
	float officeArea;
	int nbMeetingRooms;
	float meetingRoomsArea;	
	int nbDesk;
	bool savetoCSV<-false;
	string outputFilePathName;
		    			
	bool show_dynamic_bottleneck <- false;  //show or not the bottleneck
	int bottleneck_livespan <- 5; //to livespan of a bottleneck agent (to avoid glitching aspect) 
	float coeff_speed_slow <- 2.0; //a people is considered as "slow" if its real speed is lower than it wanted speed / coeff_speed_slow during min_num_step_bottleneck
	int min_num_step_bottleneck <- 3;
	float distance_bottleneck <- 2.0; //a bottleneck is considered if there is at least min_num_people_bottleneck slow people at a distance of distance_bottleneck;
	int min_num_people_bottleneck <- 2; 
	
	bool show_droplet <- false;  //show or not the bottleneck
	int droplet_livespan <- 5; //to livespan of a bottleneck agent (to avoid glitching aspect) 
	float droplet_distance <- 0.8#m;

	map<string,rgb> color_map <- [ "blue"::rgb(50, 197, 255), "red"::rgb(244, 67, 54),"green"::rgb(109, 212, 0), "orange"::rgb(247, 181, 0)];
	
	bool batch_mode <- false;
	
	init {
		validator <- false;
		outputFilePathName <-"../results/output_" + (#now).year+"_"+(#now).month+"_"+ (#now).day + "_"+ (#now).hour+"_"+ (#now).minute  + "_" + (#now).second+"_distance_"+distance_people+".csv";
		do initiliaze_dxf;
		create pedestrian_path from: pedestrian_path_shape_file;
		pedestrian_network <- as_edge_graph(pedestrian_path);
		loop se over: the_dxf_file  {
			string type <- se get layer;
			if (type = walls) {
				create wall with: [shape::clean(polygon(se.points))];
			} else if type = entrance {
				create building_entrance  with: [shape::polygon(se.points), type::type];
			} else if type = library {
				create common_area  with: [shape::polygon(se.points), type::type]{
					if (ventilationType="AC"){
						isVentilated<-true;
					}
				}
			
			} else if type in (workplace_layer + [coffee, sanitation]) {
				create room with: [shape::clean(polygon(se.points)), type::type]{
					if (ventilationType="AC"){
						isVentilated<-true;
					}
				}	
			}
		}
		
		ask room sort_by (-1 * each.shape.area){
			ask(room overlapping self) {
				if (type = myself.type and shape.area>0) {
					if ((self inter myself).area / shape.area) > 0.8 {
						do die;	
					} else {
						shape <- shape - myself.shape;
					}
				}
			}
		} 
		
		ask room +building_entrance + common_area{
			list<wall> ws <- wall overlapping self;
			loop w over: ws {
				if (w covers self) {
					w.shape <- w.shape - (self + 0.5);
				}
			}
		} 
		
		
		if (density_scenario = "num_people_building") {
			list<room> offices_list <- room where (each.type in workplace_layer);
			float tot_area <- offices_list sum_of each.shape.area;
			ask offices_list {
				num_places <- max(1,round(num_people_per_building * shape.area / tot_area));
			}
			int nb <- offices_list sum_of each.num_places;
			if (nb > num_people_per_building) and (length(offices_list) > num_people_per_building) {
				loop times: nb - num_people_per_building {
					room r <- one_of(offices_list where (each.num_places > 1));
					r.num_places <- r.num_places - 1;	
				}
			} else if (nb < num_people_per_building) {
				loop times: num_people_per_building - nb{
					room r <- one_of(offices_list);
					r.num_places <- r.num_places + 1;	
				}
			}
			
		} 
		
		
	
		
		ask room + building_entrance + common_area{
			do intialization;
		}
		ask dxf_element {
			do die;
		}
		
		ask wall {
			if not empty((room + building_entrance + common_area) inside self ) {
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
		ask room + building_entrance + common_area{
			geometry contour <- nil;
			float dist <-0.3;
			int cpt <- 0;
			loop while: contour = nil {
				cpt <- cpt + 1;
				contour <- copy(shape.contour);
				ask wall at_distance 1.0 {
					contour <- contour - (shape +dist);
				}
				if cpt < limit_cpt_for_entrance_room_creation {
					ask (room  + common_area) at_distance 1.0 {
						contour <- contour - (shape + dist);
					}
				}
				if cpt = 20 {
					break;
				}
				dist <- dist * 0.5;	
			} 
			if contour != nil {
				list<point> ents <- points_on (contour, 2.0);
				loop pt over:ents {
					create room_entrance with: [location::pt,my_room::self] {
						myself.entrances << self;
					}
				
				}
			}
			ask places {
				point pte <- (myself.entrances closest_to self).location;
				dists <- self distance_to pte;
			}
					
		}
		map<string, list<room>> rooms_type <- room group_by each.type;
		sanitation_rooms <- rooms_type[sanitation];
		if (use_sanitation and not empty(sanitation_rooms)) {
			create sanitation_activity with:[activity_places:: sanitation_rooms];
		}
		
		loop ty over: rooms_type.keys  - [workplace_layer, entrance, sanitation]{
			create activity {
				name <-  ty;
				activity_places <- rooms_type[ty];
			}
		}
		
		create working;
		create going_home_act with:[activity_places:: building_entrance as list];
		create eating_outside_act with:[activity_places:: building_entrance as list];
		
		available_offices <- (workplace_layer accumulate rooms_type[each]) where each.is_available();	
		
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
		
		ask wall {
			ask proximityCell overlapping self{
				is_walking_area <- false;
			}
		}
		
		nbOffices<-(room count (each.type in workplace_layer));
		totalArea<-sum((room) collect each.shape.area);
		officeArea<-sum((room where (each.type in workplace_layer)) collect each.shape.area);
		nbMeetingRooms<-(room count (each.type="Meeting rooms"));
		meetingRoomsArea<-sum((room where (each.type="Meeting rooms")) collect each.shape.area);
		nbDesk<-length(room accumulate each.available_places);
		do create_people(nbDesk);
		if (arrival_time_interval = 0.0) {
			people_to_create[current_date] <- nbDesk;
		} else {
			int nb <- 1 + int(step_arrival * nbDesk / arrival_time_interval);
			float cpt <- 0.0;
			loop while: cpt < arrival_time_interval {
				people_to_create[starting_date add_ms (cpt * 1000)] <- nb;
				cpt <- cpt + step_arrival ;
			}
			
		}
	}
	
	reflex save_model_output when: (cycle = 1 and savetoCSV){
		// save the values of the variables name, speed and size to the csv file; the rewrite facet is set to false to continue to write in the same file
		//write "save to csv";
		//save ["type","nbEntrance","nbDesk"] to: outputFilePathName type:"csv" rewrite: false;
		ask room {
			// save the values of the variables name, speed and size to the csv file; the rewrite facet is set to false to continue to write in the same file
			save [type,length(entrances), length(available_places)] to: outputFilePathName type:"csv" rewrite: false;
		}
	}
	
	reflex manageDroplet{
	 if(show_droplet){
	   ask people {
	   	if (mod (cycle+int(self),4)=0){
	   	 create droplet{
	 		location<-myself.location;
	 		target <- myself.location + {cos(myself.heading),sin(myself.heading)} * droplet_distance; 
	 		start_location <- myself.location;
	    }		
	   	}
 	   }
	   ask droplet where (each.live_span <= 0) {do die;}		
	 }else{
	 	ask droplet {do die;}
	 }
	}	
	
	action initialize_pedestrian_model {
		
		ask pedestrian_path {
			float dist <- max(1.0, self distance_to (wall closest_to self));
			do initialize obstacles:[wall] distance: dist;
			free_space <- free_space.geometries first_with (each overlaps shape);
		}
	}
	
	
	action active_people(int nb) {
		ask nb first (people where each.not_yet_active) {
			not_yet_active <- false;
		}
	}
	
	action create_people(int nb) {
		create people number: nb {
			age <- rnd(18, 70); 
			pedestrian_model <- SFM;
			obstacle_species <- [people, wall];
			tolerance_target <-tolerance_target_param;
			bool goto_common_area <- (not empty(common_area)) and flip(proba_goto_common_area);
			
			location <- any_location_in (one_of(building_entrance).init_place);
			if (goto_common_area) {
				working_place <- common_area[rnd_choice(common_area collect each.shape.area)];
			} else {
				working_place <- one_of (available_offices);
				if (working_place = nil) {do die;}
				working_place.nb_affected <- working_place.nb_affected + 1;
				if not(working_place.is_available()) {
					available_offices >> working_place;
				}
			}
			working_desk <- working_place.get_target(self,false);
			if (working_place = nil) {
				do die;
			}
			if (use_sanitation and not empty(sanitation_rooms) and flip(proba_using_before_work)) {
				current_activity <- first(sanitation_activity);
				target_room <- sanitation_rooms[rnd_choice(sanitation_rooms collect (1 / (0.1 + each distance_to self)) )];
				waiting_sanitation <- true;
				
				list<room_entrance> re <- copy(target_room.entrances);
				if (length(re) = 1) {
					the_entrance <- first(re);
				} else {
					re <- re where not((pedestrian_network path_between (self, each)).shape overlaps target_room.inside_geom);
					if (empty(re)) {
						re <- target_room.entrances;
					}
					the_entrance <- re[rnd_choice(re collect (max(1,length(each.positions)) / (0.1 + each distance_to self)) )];
				}
				
			//	the_entrance <- (target_room.entrances closest_to self);
				target <- the_entrance.location;
				agenda_day[current_date add_seconds 10] <- first(working);
			} else {
				current_activity <- first(working);
				target_room <- current_activity.get_place(self);
				list<room_entrance> re <- copy(target_room.entrances);
				if (length(re) = 1) {
					the_entrance <- first(re);
				} else {
					room_entrance rec <- room_entrance closest_to self;
					if rec distance_to self < 5.0 { 
						the_entrance <- rec;
					} else {
						
						re <- re where not((pedestrian_network path_between (self, each)).shape overlaps target_room.inside_geom);
					
						if (empty(re)) {
							re <- target_room.entrances;
						}
						
						the_entrance <- re[rnd_choice(re collect (max(1,length(each.positions)) / (0.1 + each distance_to self)) )];
					}	
				}
				
			//	the_entrance <- (target_room.entrances closest_to self);
				target <- the_entrance.location;
		
			}
					
			goto_entrance <- true;
			//location <- any_location_in (one_of(building_entrance).init_place);
			
			switch agenda_scenario {
				match "classic day" {
					date lunch_time <- date(current_date.year,current_date.month,current_date.day,11, 30) add_seconds rnd(0, 40 #mn);
					time_first_lunch <-((time_first_lunch = nil) or (time_first_lunch > lunch_time)) ? lunch_time : time_first_lunch;
					activity act_coffee <- activity first_with (each.name = coffee);
					activity shopping_supermarket <- activity first_with (each.name = supermarket);
					bool return_after_lunch <- false;
					if (flip(0.8)) {
						agenda_day[lunch_time] <-first(eating_outside_act) ;
						return_after_lunch <- true;
						lunch_time <- lunch_time add_seconds rnd(30 #mn, 90 #mn);
						if flip(0.3) and act_coffee != nil{
							agenda_day[lunch_time] <- activity first_with (each.name = coffee);
							lunch_time <- lunch_time add_seconds rnd(5#mn, 15 #mn);
						}
					} else {
						if flip(0.3) and  shopping_supermarket != nil{
							agenda_day[lunch_time] <-shopping_supermarket ;
							return_after_lunch <- true;
							lunch_time <- lunch_time add_seconds rnd(5#mn, 10 #mn);
						}
						if flip(0.5) and act_coffee != nil{
							agenda_day[lunch_time] <- act_coffee;
							return_after_lunch <- true;
							lunch_time <- lunch_time add_seconds rnd(10#mn, 30 #mn);
						}	
					}
					
					if (return_after_lunch) {
						agenda_day[lunch_time] <- first(working);
					}
					agenda_day[date(current_date.year,current_date.month,current_date.day,18, rnd(30),rnd(59))] <- first(going_home_act);
	
				} default {
					if (use_sanitation and not empty(sanitation_rooms) and flip(proba_using_after_work)) {
						agenda_day[current_date add_seconds (max(1#mn,timeSpent) - 1)] <- first(sanitation_activity);
					}
					agenda_day[current_date add_seconds (max(1#mn,timeSpent))] <- first(going_home_act);
				}
			}
		}	
	}
	
	reflex reset_proximity_cell when: draw_proximity_grid {
		ask proximityCell parallel: parallel{
			nb_interactions <- 0;	
		}

	}
	
	reflex manage_bottleneck  {
		if show_dynamic_bottleneck {
			list<people> slow_people <- people where each.is_slow_real;
			if not empty(slow_people) {
				list<list<people>> clusters <- simple_clustering_by_distance(slow_people,distance_bottleneck);
				loop cluster over: clusters {
					if (length(cluster) >= min_num_people_bottleneck) {
						create bottleneck with: [shape:: union(cluster collect (each.shape + (distance_bottleneck/2.0)))];
					}
				}
			}
			ask bottleneck where (each.live_span <= 0) {do die;}
		} else {
			ask bottleneck  {do die;}
		}
		
		
	}
	
	
	reflex change_step when: use_change_step{
		
		if (agenda_scenario = "classic day") {
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
		} else {
			
			if (time > (arrival_time_interval + step * 2) and empty(people where ((not each.end_of_day) and ((each.target != nil) or each.waiting_sanitation)) ))  {
				if synchronized_step and length(COVID_model) > 1 {
					bool ready_change_step <- true;
				 	loop s over: COVID_model {
				 		if  (s.people first_with  (each.target != nil or each.waiting_sanitation) ) != nil {
				 			ready_change_step <- false;
				 		} 
				 	}
				 	if (ready_change_step) {
				 		step <- fast_step;
				 	} else {
				 		step <- normal_step;
				 	}
				} else {
					step <- fast_step;
				}
				
			} else {
				step <- normal_step;
			} 
		}	
		
	}
	
	
	reflex end_simulation when: not batch_mode and ((people count not each.end_of_day) = 0) and time > (arrival_time_interval + 10) {
		if (first_end_sim) {
			first_end_sim <- false;
		}
		bool ready_end <- true;
	 	loop s over: COVID_model {
	 		if  ((s.people count not each.end_of_day) > 0) {
	 			ready_end <- false;
	 		} 
	 	}
	 	if (ready_end) {
	 		do pause;
	 	}
	}
	
	reflex people_arriving when: not empty(people_to_create)
	{	
		loop d over: people_to_create.keys {
			if current_date >= d {
				do active_people (max(0,min(people_to_create[d], people count each.not_yet_active)));
				remove key:d from: people_to_create;
			}
		}
		
	}
	reflex updateGraph when: (drawSocialDistanceGraph = true) {
		social_distance_graph <- graph<people, people>(people as_distance_graph (distance_people - 0.1#m));
	}
	

}


species bottleneck {
	bool real <- false;
	int live_span <- bottleneck_livespan update: live_span - 1;
	aspect default {
		draw shape color: #red ; 
	}
}
species pedestrian_path skills: [pedestrian_road] frequency: 0{
	aspect default {
		if (display_pedestrian_path) {
			if(display_free_space and free_space != nil) {draw free_space color: #lightpink border: #black;}
			draw shape color: #red width:2;
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
		draw shape color: #white;
	}
}


species fomitableSurface{
	float viral_load min: 0.0 max: 10.0;
	float interaction_radius<-1.0#m;
	float fomite_viral_load_decay_per_second<-0.00003;

	
	//Action to add viral load to the cell
	action add_viral_load(float value){
		viral_load <- viral_load+value;
	}
	//Action to remove viral load to the cell
	action remove_viral_load(float value){
		viral_load <- viral_load-value;
	}
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load {
		viral_load <- viral_load * (1- fomite_viral_load_decay_per_second) ^ step;
	}
	
	aspect default{
		if(viral_load>0){
		  //draw circle(interaction_radius) color:rgb(0,0,viral_load*255*100,0.5);	
		}
	}
}

species room_entrance parent:fomitableSurface{
	geometry queue;
	room my_room;
	list<people> people_waiting;
	list<point> positions;
	
	geometry waiting_area;
	
	init {
		if (queueing) {
			do default_queue;
		}
		
	}
	
	geometry create_queue(geometry line_g, int nb_places) {
		
		//line_g <- line_g at_location (line_g.location );
		bool consider_rooms <-  (room first_with ((each - 0.1) overlaps location)) = nil;
		point vector <-  (line_g.points[1] - line_g.points[0]) / line_g.perimeter;
		float nb <- max(1, nb_places) * distance_queue ;
		geometry queue_tmp <- line([location,location + vector * nb ]);
		geometry q_s <- copy(queue_tmp);
		if (queue_tmp intersects my_room ) {
			geometry line_g2 <- line(reverse(queue_tmp.points));
			if (line_g2 inter my_room).perimeter < (queue_tmp inter my_room).perimeter {
				queue_tmp <- line_g2;
			}
		}
		list<geometry> ws <- (wall overlapping (queue_tmp+ 0.2)) collect each.shape;
		ws <- ws +(((room_entrance - self) where (each.queue != nil)) collect each.queue) overlapping (queue_tmp + 0.2);
		if not empty(ws) {
			loop w over: ws {
				geometry qq <- queue_tmp - (w + 0.2);
				if (qq = nil) {
					queue_tmp <- queue_tmp - (w + 0.01);
				} else {
					queue_tmp <- qq;
				}
				if (queue_tmp != nil) {
					queue_tmp <- queue_tmp.geometries with_min_of (each distance_to self);
				}
			}
		}
		if (queue_tmp != nil) {
			vector <- (queue_tmp.points[1] - queue_tmp.points[0]);// / queue.perimeter;
			queue_tmp <- line([location,location + vector * rnd(0.2,1.0)]);
		} else {
			vector <- (q_s.points[1] - q_s.points[0]);// / queue.perimeter;
			queue_tmp <- line([location,location + vector * (0.1 / q_s.perimeter)]);
		}
		
		int cpt <- 0;
		loop while: (queue_tmp.perimeter / distance_queue) < nb_places {
			if (cpt = 10) {break;}
			cpt <- cpt + 1;
			point pt <- last(queue_tmp.points);
			
			line_g <- line([queue_tmp.points[length(queue_tmp.points) - 2],queue_tmp.points[length(queue_tmp.points) - 1]]) rotated_by 90;
			if (line_g.perimeter = 0) {
				break;
			}
			line_g <- line_g at_location last(queue_tmp.points );
			point vector <-  (line_g.points[1] - line_g.points[0]) / line_g.perimeter;
			float nb <- max(0.5,(max(1, nb_places) * distance_queue) - queue_tmp.perimeter);
			queue_tmp <-  line(queue_tmp.points + [pt + vector * nb ]);
			list<geometry> ws <- wall overlapping (queue_tmp+ 0.2);
			ws <- ws +(((room_entrance - self) where (each.queue != nil)) collect each.queue) overlapping (queue_tmp + 0.2);
			if (consider_rooms) {ws <- ws +  room overlapping (queue_tmp+ 0.2);}
			
			if not empty(ws) {
				loop w over: ws {
					geometry g <- queue_tmp - w ;
					if (g != nil) {
							queue_tmp <- g.geometries with_min_of (each distance_to pt);
					}
				
				}
			}
			
		}
		return queue_tmp;
		
	}
	action default_queue {
		int nb_places <- my_room.type = sanitation ? 20 : length(my_room.places);
		geometry line_g;
		float d <- #max_float;
		loop i from: 0 to: length(my_room.shape.points) - 2 {
			point pt1 <- my_room.shape.points[i];
			point pt2 <- my_room.shape.points[i+1];
			geometry l <- line([pt1, pt2]);
			if (self distance_to l) < d {
				line_g <- l;
				d <- self distance_to l;
			}
		}
		
		geometry g1 <- create_queue(line_g rotated_by 90, nb_places);
		geometry g2 <- create_queue(line_g rotated_by -90,nb_places);
		
		geometry l1 <- (g1 = nil) ? nil : line([last(g1.points), ((pedestrian_path with_min_of (each distance_to last(g1.points))) closest_points_with last(g1.points))[0]]);
		geometry l2 <- (g2 = nil) ? nil :line([last(g2.points), ((pedestrian_path with_min_of (each distance_to last(g2.points))) closest_points_with last(g2.points))[0]]);
		
		if (g1 = nil) {
			queue <- g2;
		} else if (g2 = nil) {
			queue <- g1;
		} else {
			if not empty (wall overlapping l1) {
				if empty (wall overlapping l2) {
					queue <- g2;
				} else {
					queue <- [g1,g2] with_max_of each.perimeter;
				}
			} else {
				if not empty (wall overlapping l2) {
					queue <- g1;
				} else {
					queue <- [g1,g2] with_max_of each.perimeter;
				}
			}
		}
		do manage_queue();
	}
	
	action manage_queue {
		positions <- queue.perimeter > 0 ?  queue points_on (distance_queue) : []; 
		waiting_area <- queue;
		list<wall> ws <- wall overlapping waiting_area;
		/*if not empty(ws) {
			loop w over: ws {
				waiting_area <- waiting_area - ws ;
				waiting_area <- waiting_area.geometries with_min_of (each distance_to last(positions) );
			}
		}*/
		
	}
	
	action add_people(people someone) {
		if not empty(positions) {
			if (length(people_waiting) < length(positions)) {
				someone.location <- positions[length(people_waiting)];
			} else {
				someone.location  <- any_location_in(waiting_area);
			}
		}
		people_waiting << someone;
	}
	
	point get_position {
		if empty(positions) {return location;}
		
		else {
			if (length(people_waiting) < length(positions)) {
				return positions[length(people_waiting)];
			} else {
				return any_location_in(waiting_area);
			}
			
		}
	}
	
	
	reflex manage_visitor when: not empty(people_waiting) {
		int nb <- 0;
		if (my_room.type != sanitation) {
			if every(waiting_time_entrance) {
				nb <-1;
			}
		} else {
			nb <- nb_people_per_sanitation - (my_room.people_inside count (each.using_sanitation));
		}
		if nb > 0 {
			loop times: nb {
				people the_first_one <- first(people_waiting);
				people_waiting >> the_first_one;
				the_first_one.in_line<-false;
				if (not empty(people_waiting) and not empty(positions)) {
					loop i from: 0 to: length(people_waiting) - 1 {
						if (i < length(positions)) {
							people_waiting[i].location <- positions[i];
						}
					}
				}
			}
		} 
	}
	 
	aspect queuing {
		if(queueing){
		    draw queue color: #blue;	
	  }	 
	}
}

species common_area parent: room {
}

species room {
	int nb_affected;
	string type;
	pedestrian_path closest_path;
	geometry init_place;
	list<room_entrance> entrances;
	list<place_in_room> places;
	list<place_in_room> available_places;
	int num_places;
	bool isVentilated <- false;
	list<people> people_inside;
	geometry inside_geom;
	
	action intialization {
		inside_geom <- (copy(shape) - 0.2);
		ask wall overlapping self {
			geometry g <- myself.inside_geom - self;
			if g != nil {
				myself.inside_geom <- g.geometries with_max_of each.area;
			}
		}
		if (inside_geom = nil) {
			inside_geom <- shape;
		}
		list<geometry> squares;
		map<geometry, place_in_room> pr;
		
		list<dxf_element> chairs_dxf <-  dxf_element where (each.layer = chairs);
		if (density_scenario = "data") {
			if empty( chairs_dxf ) {
				do tell("Data density scenario requires to have a chair layer");
			} else {
				loop d over: chairs_dxf overlapping self{
					create place_in_room  {
						location <-d.location;
						if length(place_in_room) > 1 {
							if (place_in_room closest_to self) distance_to self < 0.2 {
								do die;
							}
						}
						if not dead(self) {
							myself.places << self;
						}
					}
				}
				if (not empty(places) and (species(self) = room)) {
					//type <- workplace_layer;
				} else {
					create place_in_room number: min(10, 1 + inside_geom.area / 2.0) {
						location <-	any_location_in(myself.inside_geom);
						myself.places << self;
					}
				}
				room the_room <- self;
				if (separator_proba > 0) and (length(places) > 1) {
					list<pair<place_in_room,place_in_room>> already;
					ask places {
						ask myself.places at_distance 2.0 {
							if (self distance_to myself) > 0.1 {
								if not ((self::myself) in already) {
									if flip(separator_proba) {
										point cent <- mean(location, myself.location);
										if empty(separator_ag overlapping line([location, myself.location])) {
											geometry sep <- line([cent - {0,0.5,0}, cent + {0,0.5,0}]);
											sep <- ((sep rotated_by ((myself towards self))) + 0.05) inter the_room;
											create separator_ag with: [shape::sep,places_concerned::[myself,self]];
											already <<myself::self;
										}
										
									}
								}
								
							}
						}
					}
				} 
			}
			ask places where not (self overlaps each){
				do die;
			}
			if empty(places) {
				create place_in_room {
					location <- myself.location;
					myself.places << self;
				}
			}
			
			
		} 
		else if (density_scenario = "distance") or (type != workplace_layer) {
			squares <-  to_squares(inside_geom, distance_people, true) where (each.location overlaps inside_geom);
		}
		else if (density_scenario= "num_people_room"){
			num_places <-num_people_per_room;
			int nb <- num_places;
			loop while: length(squares) < num_places {
				squares <-  num_places = 0 ? []: to_squares(inside_geom, nb, true) where (each.location overlaps inside_geom);
				nb <- nb +1;
			}
			if (length(squares) > num_places) {
				squares <- num_places among squares;
			}
		}
		else if density_scenario in ["num_people_building"] {
			int nb <- num_places;
			loop while: length(squares) < num_places {
				squares <-  num_places = 0 ? []: to_squares(inside_geom, nb, true) where (each.location overlaps inside_geom);
				nb <- nb +1;
			}
			if (length(squares) > num_places) {
				squares <- num_places among squares;
			}
		} 
		if not empty(squares) and  density_scenario != "data"{
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
			
		}
		available_places <- copy(places);
		
	}
	bool is_available {
		return nb_affected < length(places);
	}
	place_in_room get_target(people p, bool random_place){
		place_in_room place <- random_place ? one_of(available_places) : (available_places with_max_of each.dists);
		available_places >> place;
		return place;
	}
	
	
	aspect default {
		//draw inside_geom color: standard_color_per_layer[type];
		loop e over: entrances {draw circle(0.2)-circle(0.1) at: {e.location.x,e.location.y,0.001} color: #yellow border: #black;}
		loop p over: places {draw square(0.2) at: {p.location.x,p.location.y,0.001} color: #gray border: #black;}
		if(isVentilated ){
		 //draw shape*0.75 color:standard_color_per_layer[type]+50 empty:false;
		// draw fanPic size: 3;	
		}
	}
	aspect available_places_info {
		if(showAvailableDesk and (type in workplace_layer)){
		 	draw string(length(available_places)) at: {location.x-20#px,location.y,1.0} color:#white font:font("Helvetica", 20 , #bold) perspective:false; 	
		} 
	}
}


species building_entrance parent: room {
	place_in_room get_target(people p, bool random_place){
		return random_place ? one_of(places) : places closest_to p;
	}

	aspect default {
		draw shape color: standard_color_per_layer[type];
		draw init_place color:#magenta border: #black;
		loop e over: entrances {draw square(0.1) at: e.location color: #magenta border: #black;}
		loop p over: available_places {draw square(0.1) at: p.location color: #yellow border: #black;}
	}
}


species sanitation_activity parent: activity{
	room get_place(people p) {
		if flip(0.3) {
			return shuffle(activity_places) with_min_of length(first(each.entrances).people_waiting);
		} else {
			return activity_places closest_to p;
		}
	}
	
}
species activity {
	list<room> activity_places;
	
	room get_place(people p) {
		if flip(0.3) {
			return activity_places with_max_of length(each.available_places);
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

species place_in_room parent:fomitableSurface{
	float dists;
}

species droplet {
	point start_location;
	point target;
	int live_span <- droplet_livespan update: live_span - 1;
	float size <- 4.0#cm;
	
	reflex change{
		size <- size * (1+0.8*live_span/droplet_livespan);
		location <- target + (start_location - target)/(droplet_livespan-live_span+1);
		location <- target + (start_location - target)*live_span/droplet_livespan;
	}
	
	aspect base{
		draw sphere(size)  color:rgb(100,100,255,0.2+0.3*live_span/droplet_livespan);
	}
}


species people skills: [escape_pedestrian] schedules: people where (not each.end_of_day and not each.not_yet_active){
	int age <- rnd(18,70); // HAS TO BE DEFINED !!!
	bool not_yet_active <- true;
	room working_place;
	place_in_room working_desk;
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
	float speed <- max(2,min(6,gauss(4,1))) #km/#h;
	bool is_slow <- false update: false;
	bool is_slow_real <- false;
	int counter <- 0;
	bool in_line <- false;
	room_entrance the_entrance;
	bool waiting_sanitation <- false;
	bool using_sanitation <- false;
	float sanitation_time <- 0.0;
	bool end_of_day <- false;
	bool wandering <- false;
	bool goto_a_desk <- false;
	point target_desk;
	float wandering_time_ag;
	bool finished_goto <- false;
	
	aspect default {
		if not is_outside and not end_of_day and not not_yet_active{
			draw circle(peopleSize) color:color;// border: #black;
		}
		//draw obj_file(dataset_path+"/Obj/man.obj",-90::{1,0,0}) color:#gamablue size:2 rotate:heading+90;
	}
	
	
	reflex common_area_behavior when: species(target_room) = common_area and (location overlaps target_room) {
		if wandering {
			if (wandering_time_ag > wandering_time) {
				if (target_place != nil) {
					if final_target = nil and ((location distance_to target_place) > 2.0){
						do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target_place ;
					}
					if (final_target = nil) {
						do goto target: target_place;
					} else {
						do walk;
					}
					
					if not(location overlaps target_room.inside_geom) {
						location <- (target_room.inside_geom closest_points_with location) [0];
					}
					if final_target =nil {
						wandering <- false;
					}
				} else {
					wandering <- false;
				}
				if not(location overlaps target_room.inside_geom) {
					location <- (target_room.inside_geom closest_points_with location) [0];
				}
			} else {
				do wander amplitude: 140.0 bounds: target_room.inside_geom speed: speed / 5.0;
				wandering_time_ag <- wandering_time_ag + step;	
			}
		} else if goto_a_desk {
			if (final_target = nil) {
				do goto target: target;
			} else {
				do walk;
			
			}
			if not(location overlaps target_room.inside_geom) {
				location <- (target_room.inside_geom closest_points_with location) [0];
			}
			if final_target =nil {
				goto_a_desk <- false;
			}
		} else {
			if flip(proba_wander) {
				wandering <- true;
				wandering_time_ag <- 0.0;
				heading <- rnd(360.0);
			} else if flip(proba_change_desk) { 
				
				goto_a_desk <- true;
				place_in_room pir <- one_of (target_room.places);
				target_desk <- {pir.location.x + rnd(-0.5,0.5),pir.location.y + rnd(-0.5,0.5)};
				if not(target_desk overlaps target_room.inside_geom) {
					target_desk <- (target_room.inside_geom closest_points_with target_desk) [0];
				}
				if ((location distance_to target_desk) > 2.0) {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target_desk ;
				}
			}
		}
	}
	reflex sanitation_behavior when: using_sanitation {
		sanitation_time <- sanitation_time + step;
		if (sanitation_time > sanitation_usage_duration) {
			sanitation_time <- 0.0;
			using_sanitation <- false;
			waiting_sanitation <- false;
			target_room.people_inside >> self;
		}
	}
	reflex updateFlowCell when:not is_outside{
		ask (flowCell overlapping self.location){
			nbPeople<-nbPeople+1;
		}
	}
	reflex define_activity when: not waiting_sanitation and not empty(agenda_day) and 
		(after(agenda_day.keys[0])){
		if(target_place != nil and (has_place) ) {target_room.available_places << target_place;}
		string n <- current_activity = nil ? "" : copy(current_activity.name);
		room prev_tr <- copy(target_room);
		current_activity <- agenda_day.values[0];
		agenda_day >> first(agenda_day);
		target_room <- current_activity.get_place(self);
		list<room_entrance> possible_entrances <- target_room.entrances where (not((each path_to target_room).shape overlaps prev_tr));
		if (empty (possible_entrances)) {
			possible_entrances <-  target_room.entrances;
		}
		target <- (target_room.entrances closest_to self).location;
		go_oustide_room <- true;
		is_outside <- false;
		goto_entrance <- false;
		target_place <- nil;
		world.step <- normal_step;
		if (species(current_activity) = sanitation_activity) {
			waiting_sanitation <- true;
		}
	}
	
	reflex goto_activity when: target != nil and not in_line{
		bool arrived <- false;
		point prev_loc <- copy(location);
		if goto_entrance {
			if (queueing) and (species(target_room) != building_entrance) and ((self distance_to target) < (2 * distance_queue))  and ((self distance_to target) > (1 * distance_queue))  {
				point pt <- the_entrance.get_position();
				if (pt != target) {
					final_target <- nil;
					target <- pt;
				}
			}
			if (movement_model = moving_skill) {
				do goto target: target on: pedestrian_network;
				arrived <- location = target;
			} else {
				if (final_target = nil) and ((location distance_to target) > 2.0)  {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target ;
				}
				if (final_target != nil) {
					do walk;
					float r_s <- prev_loc distance_to location;
					is_slow <- r_s < (speed/coeff_speed_slow);
					if (is_slow) {
						counter <- counter + 1;
						if (counter >= min_num_step_bottleneck) {
							is_slow_real <- true;
						}
					} else {
						is_slow_real <- false;
						counter <- 0;
					}
				}
				
				arrived <- final_target = nil;
				if (arrived) {
					is_slow_real <- false;
					counter <- 0;
				}
			}
		}
		else {
			if (finished_goto) {
				do goto target: target;
			} else {
				if (final_target = nil) {
					do compute_virtual_path pedestrian_graph:pedestrian_network final_target: target ;
				}
				do walk;
				finished_goto <- (final_target = nil) and (location != target);
			}
			//do goto target: target;
			arrived <- location = target;
			if (arrived) {
				finished_goto <- false;
			}
		}
		if(arrived) {
			if (go_oustide_room) {
				the_entrance <- (target_room.entrances closest_to self);
					
				if (!queueing) {
					target <- the_entrance.location;
				} else {
					if (species(target_room) = building_entrance) {
						target <- the_entrance.location;
					} else {
						target <- the_entrance.get_position();
					}
				}
				if (current_activity.name = going_home) and (location distance_to target < tolerance_target){
					end_of_day <- true;
				}
				
				go_oustide_room <- false;
				goto_entrance <- true;
			}
			else if (goto_entrance) {
				if (species(current_activity) = sanitation_activity) {
					target <- target_room.location;
					goto_entrance <- false;
					if (queueing) or (target_room.type = sanitation) {
						ask room_entrance closest_to self {
							do add_people(myself);
						}
						in_line <- true;
					} else {
							
					}
				} else {
					target_place <- (target_room = working_place) ? working_desk : target_room.get_target(self, species(target_room) = common_area);
					//target_place <- target_room.get_target(self, species(target_room) = common_area);
					if target_place != nil {
						target <- target_place.location;
						
						if (queueing and (species(target_room) != building_entrance)) {
							ask room_entrance closest_to self {
								do add_people(myself);
							}
							in_line <- true;
						}
					} else {
						room tr <- current_activity.get_place(self);
						if (tr != nil ) {
							target_room <- tr;
							target <- (target_room.entrances closest_to self).location;
						}
					}
					goto_entrance <- false;
				}
			} else {
				has_place <- true;
				target <- nil;
				if (species(current_activity) = sanitation_activity) {
					using_sanitation <- true;
					target_room.people_inside << self;
				}
				if (species(target_room) = building_entrance) {
					is_outside <- true;
				}
				if (current_activity.name = going_home) {
					end_of_day <- true;
				}
			}	
		}
 	}
 	reflex when: draw_proximity_grid and not empty(people at_distance (distance_people/2)){
		geometry geom <- circle(distance_people) ;
		list<wall> ws <- wall at_distance (distance_people);
		if not empty(ws) {
			if (use_masked_by) {
				geom <- geom masked_by (ws, precision);
			} else {
				ask ws {
					geom <- geom - self;
					if (geom = nil) {break;}
					geom <- geom.geometries first_with (each overlaps myself);
				}
				
			}
			
		}
		if (geom != nil) {
			ask proximityCell overlapping geom {
				nb_interactions <- nb_interactions + 2;
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


grid proximityCell cell_width: max(world.shape.width / proximityCellmaxNumber, proximityCellSize) cell_height:max(world.shape.height / proximityCellmaxNumber, proximityCellSize) frequency: 0 use_neighbors_cache: false use_regular_agents: false
{
	rgb color <- #white;
	int nb_interactions ;
	bool is_walking_area <- true;
	
	aspect default{
		if (draw_proximity_grid and is_walking_area){
			if(nb_interactions>1){
				  draw shape color:blend(#red,#cyan, nb_interactions/10);//  depth:nb_interactions/1000;		
			}
		}
	}	
}



