/***
* Name: COVID
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model COVID

global {
	
	file ML_file <- dxf_file("../includes/Standard_Factory_Gama.dxf",#cm);
	shape_file pedestrian_path_shape_file <- shape_file("../includes/pedestrian_path.shp");
	date starting_date <- date([2020,4,6,7]);
	int nb_people <- 300;
	geometry shape <- envelope(ML_file);
	graph pedestrian_network;
	map<string,rgb> standard_color_per_type <- 
	["Offices"::#blue,"Meeting rooms"::#darkblue,
	"Entrance"::#yellow,"Elevators"::#orange,
	"Coffee"::#green,"Supermarket"::#darkgreen,
	"Storage"::#brown, "Furnitures"::#maroon, 
	"Toilets"::#purple, "Toilets_Details"::#magenta, 
	"Walls"::#gray, "Doors"::#lightgray,
	"Stairs"::#white,"Path"::#red];
	list<room> available_offices;
	list<room> entrances;
	init {
		create pedestrian_path from: pedestrian_path_shape_file;
		pedestrian_network <- as_edge_graph(pedestrian_path);
		loop se over: ML_file {
			string type <- se get "layer";
			if (type = "Walls") {
				create wall with: [shape::polygon(se.points)];
			} else if type in ["Offices", "Supermarket", "Meeting rooms","Coffee","Storage", "Entrance" ] {
				create room with: [shape::polygon(se.points), type::type] {
					loop g over: to_squares(shape, 1.5, true) where (each.location overlaps shape){
						places << g.location;
					} 
					if empty(places) {
						places << location;
					} 
					available_places <- copy(places);
				}
				
			}
		} 
		ask room {
			geometry contour <- shape.contour;
			ask wall at_distance 1.0 {
				contour <- contour - (shape + 0.3);
			}
			ask room at_distance 1.0 {
				contour <- contour - (shape + 0.3);
			} 
			if contour != nil {
				entrances <- points_on (contour, 2.0);
			}
		}
		map<string, list<room>> rooms_type <- room group_by each.type;
		entrances <- rooms_type["Entrance"];
		loop ty over: rooms_type.keys  - ["Offices", "Entrance"]{
			create activity {
				name <-  ty;
				activity_places <- rooms_type[ty];
			}
		}
		create working;
		create going_home with:[activity_places:: entrances];
		
		available_offices <- rooms_type["Offices"] where each.is_available();
	}	
	
	
	
	action create_people(int nb) {
		create people number: nb {
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
			date lunch_time <- date(current_date.year,current_date.month,current_date.day,11, 30) add_seconds rnd(0, 90 #mn);
			
			if flip(0.3) {agenda_day[lunch_time] <- activity first_with (each.name = "Supermarket");}
			lunch_time <- lunch_time add_seconds rnd(120, 15 #mn);
			agenda_day[lunch_time] <- activity first_with (each.name = "Coffee");
			lunch_time <- lunch_time add_seconds rnd(5#mn, 30 #mn);
			agenda_day[lunch_time] <- first(working);
			agenda_day[date(current_date.year,current_date.month,current_date.day,rnd(17,19), rnd(59),rnd(59))] <- first(going_home);
			
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
		if (current_date.hour = 17){
			step <- 1#s;
		}
	}
	
	reflex end_simulation when: current_date.hour = 20 {
		do pause;
	}
	
	reflex people_arriving when: not empty(available_offices) 
	{
		do create_people(rnd(0,min(5, length(available_offices))));
	}
}

species pedestrian_path;

species wall {
	aspect default {
		draw shape color: #gray;
	}
}

species room {
	int nb_affected;
	string type;
	list<point> entrances;
	list<people> people_inside;
	list<point> places;
	list<point> available_places;
	
	bool is_available {
		return nb_affected < length(places);
	}
	point get_target(people p){
		point place <- (available_places farthest_to p.location);
		available_places >> place;
		return place;
	}
	
	aspect default {
		draw shape color: standard_color_per_type[type];
		loop e over: entrances {draw square(0.1) at: e color: #magenta border: #black;}
		loop p over: places {draw square(0.1) at: p color: #cyan border: #black;}
	}
}

species activity {
	list<room> activity_places;
	
	room get_place(people p) {
		return (activity_places where each.is_available()) closest_to self;
	}
	
}

species working parent: activity {
	
	room get_place(people p) {
		return p.working_place;
	}
}

species going_home parent: activity  {
	string name <- "going home";
}

species people skills: [moving] {
	room working_place;
	map<date, activity> agenda_day;
	activity current_activity;
	point target;
	room target_room;
	bool goto_entrance <- false;
	rgb color <- rnd_color(255);
	float speed <- min(2,gauss(4,1)) #km/#h;
	aspect default {
		draw circle(0.3) color:color border: #black;
	}
	reflex define_activity when: not empty(agenda_day) and 
		(current_date = agenda_day.keys[0]){
		if(target_room != nil and target = nil) {target_room.available_places << location;}
		current_activity <- agenda_day.values[0];
		agenda_day >> first(agenda_day);
		target_room <- current_activity.get_place(self);
		target <- target_room.entrances closest_to self;
		goto_entrance <- true;
	}
	
	reflex goto_activity when: target != nil{
		if goto_entrance {do goto target: target on: pedestrian_network;}
		else {do goto target: target; }
		if(location = target) {
			if (goto_entrance) {
				point loc <- target_room.get_target(self);
				if loc != nil {
					target <- loc;
					goto_entrance <- false;
				} else {
					target_room <- current_activity.get_place(self);
					target <- target_room.entrances closest_to self;
				}
			} else {
				target <- nil;
				if (current_activity.name = "going home") {
					do die;
				}
			}	
		}
 	}
}



experiment COVID type: gui {
	output {
		display map synchronized: true {
			species room;
			species wall;
			species people;
		}
	}
}
