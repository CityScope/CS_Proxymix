/***
* Name: campus
* Author: Thibaut
* Description: 
* Tags: Tag1, Tag2, TagN
***/

/*
 * Question: A* -> présence de poid variable afin de privilégié des chemins même si plus long
 *  Question : possible épaisseur de route ? comment marche le jump d'un batiment / point au graph
 * write tram or road on circle
 */

model Campus


global {
	//Load of the different shapefiles used by the model
	file shape_file_buildings <- shape_file('../includes/campus_new2(1).shp', 0);
	file shape_file_roads <- shape_file('../includes/route(1).shp', 0);
	file shape_file_bounds <- shape_file('../includes/environ.shp', 0);
	file shape_tram <- shape_file('../includes/sation_T2_polygone(1).shp', 0);
	file shape_gate <- shape_file('../includes/point_start_polygone.shp', 0);
	file environ_square <- shape_file('../includes/environ5_shp.shp', 0);
	file learning_center <- shape_file('../includes/LC.shp', 0);
	
		
    float step <- 1 #s parameter: "Time speed" category: "Model"; 
    
    
    bool moveOnGraph <- true parameter: "Move on Graph:" category: "Model";
    bool show_road <- false parameter: "Draw roads:" category: "Vizu";
    bool show_buildings <- false parameter: "Draw buildings:" category: "Vizu";
   // bool show_objectif <- false parameter: "Show objectifs:" category: "Vizu";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	bool draw_old_path <- false parameter: "Draw old path" category: "Interaction";
	int size_old_path <- 10 parameter: "Size old path" category: "Interaction";
	float population_LC <- 0.3 parameter: "Percent luck to go in the learning center" category: "debug";
	float Need_to_move <- 0.01 parameter: "Percent people that need to move" category: "debug";
	float rot <- 0.0 parameter: "Rotate" category: "debug";
	float long <- 265.0 parameter: "Long" category: "debug";
	float larg <- 290.0 parameter: "Larg" category: "debug";
	float amplitude_wander <- 180.0 parameter: "Amplitude" category: "debug wander";
	float speed_wander <- 0.5 parameter: "Speed" category: "debug wander";
	
	
	//Definition of the shape of the world as the bounds of the shapefiles to show everything contained
	// by the area delimited by the bounds
	geometry shape <- envelope(shape_file_bounds);
	int nb_people <- 100;
	int nb_current_agent <- 0;
	int new_people;
	int killed_people <- 0;
	
	int day_time update: cycle mod 1800; // day in min with only two hour for 24-6
	int min_work_end <- 60;
	int max_work_end <- 1600;
	float min_speed <- 2.0;
	float max_speed <- 5.0;
	list<building> work_buildings;
	list<gate> gate_place;
	list<tram> tram_station;
	list<geometry> clean_lines;
	list<learning_center_shp> LC;
	
	//clean or not the data
	bool clean_data <- true ;
	
	//tolerance for reconnecting nodes
	float tolerance <- 10.0 ;
	
	//if true, split the lines at their intersection
	bool split_lines <- true ;
	
	//if true, keep only the main connected components of the network
	bool reduce_to_main_connected_components <- true ;
	
	string legend <- not clean_data ? "Raw data" : ("Clean data : tolerance: " + tolerance + "; split_lines: " + split_lines + " ; reduce_to_main_connected_components:" + reduce_to_main_connected_components );
	
	
	//Declaration of a graph that will represent our road network
	graph the_graph;
	
	
	/* Get a random set of building that will be visited by the people */
	list<building> get_visited_building(list<building> all_buildings){
		int nbr_building <- (1 + rnd(3));
		list<building> ret;

		loop times: nbr_building {
			ret <- ret + one_of(all_buildings);
		}
		return ret;
	}
	
	init
	{
		create building from: shape_file_buildings //with: [type:: string(read('NATURE'))]
		{
			if type = "Industrial"
			{
				color <- # blue;
			}
			height <- 10 + rnd(90);
		}

		create tram from: shape_tram ;
		tram_station <- list(tram);
		create learning_center_shp from: learning_center ;
		LC <- list(learning_center_shp);
		
		create gate from: shape_gate;
		gate_place <- list(gate);
		//work_buildings <- building where (each.type = 'Residential');
		work_buildings <- list(building);
		//industrial_buildings <- building where (each.type = 'Industrial');
		
		
		//clean data, with the given options
		clean_lines <- clean_data ? clean_network(shape_file_roads.contents,tolerance,split_lines,reduce_to_main_connected_components) : shape_file_roads.contents;
		
		create road from: clean_lines;
		
		list<list<point>> connected_components ;
		list<rgb> colors;
		the_graph <- as_edge_graph(road);
		
		create fond from: environ_square{
			//location<-{world.shape.width/2,world.shape.height/2};	
		}		
		
		//create ML_people number:nb_people;
		//ask ML_people {location <- any_location_in(one_of(ML_element));}
		//create ML_element from: ML_file;// with: [layer::string(get("layer"))];
		//map layers <- list(ML_element) group_by each.layer;
	}
	
	reflex update_current_agent{
		nb_current_agent <- length(people); 
	}
	
	reflex add_people {
		if (nb_current_agent < nb_people){
			if (day_time < (60*20)){ // if before 20:00
				if (day_time > (30)){ // if after 06:00
					if ((day_time mod 10) = 0){ // tram arrive all 10 min
						new_people <- (20 + rnd(20));
						create people number: new_people {
							location <- any_location_in(one_of(tram_station));
							entry_point <- location;
							objectif <- "working";
							if(flip(population_LC)){
								the_target <- any_location_in(one_of(LC));	
							}else{
								the_target <- any_location_in(one_of(work_buildings));
							}
						}
						nb_current_agent <- nb_current_agent + new_people; 
					}
					if ((day_time mod 1) = 0){ // people arrive by road every min
						new_people <- rnd(10);
						create people number: new_people {
							location <- any_location_in(one_of(gate_place));
							objectif <- "working";
							entry_point <- location;
							if(flip(population_LC)){
								the_target <- any_location_in(one_of(LC));	
							}else{
								the_target <- any_location_in(one_of(work_buildings));
							}
						}
						nb_current_agent <- nb_current_agent + new_people;
					} 
				}
			}
		}else{
			ask (nb_current_agent - nb_people) among people
				{
					do die;
				}
		}
	}
	


}

//  ------- CRÉATION DE L'ESPACE ------------

species learning_center_shp{
	string type;
	rgb color;
	int height;
	bool empty;
	aspect base
	{
		color <- # transparent;
		empty <- true;
		
		if(show_buildings){
			color <- #gray;
			empty <- false;
		}
		draw shape color: color empty:empty;// depth: height;
	}
}

species tram{
	string type;
	rgb color <- #purple;
	//int height;
	aspect base
	{
		//draw shape color: color depth: height;
		draw shape color: color border:#white;
		//draw text: "T2" color: #white size: 5 ;
		
		draw("T2") color:#white rotate:90 font:font("Default", 10 , #bold);// rotate;
		
		//draw circle(5) color: color border: color-50;
		//TODO draw string
		//draw texture: "T2" color: #white;
	}
}

species gate
{
	rgb color <- #green;
	
	aspect base
	{
		draw circle(5) color: color border: color-50;
		draw texture: "Gate";
	}
}

species building
{
	string type;
	rgb color;
	int height;
	bool empty;
	aspect base
	{
		color <- # transparent;
		empty <- true;
		
		if(show_buildings){
			color <- #gray;
			empty <- false;
		}
		draw shape color: color empty:empty;// depth: height;
	}

}


species road
{
	rgb color;
	aspect base
	{
		color <- # transparent;
		if (show_road) {
			color <- #grey;
			
		}
		draw shape color: color;
	}

}

species people skills: [moving]
{
	float speed <- min_speed + rnd(max_speed - min_speed);
	rgb color <- rnd_color(255);
	path currentPath;
	point entry_point;
	bool toKill <- false;
	bool moving <- false;
	
	list<point> old_path;
	
	int end_work <- day_time + min_work_end + rnd(max_work_end - min_work_end);
	string objectif;
	point the_target <- nil;


	reflex time_to_go_home when: day_time >= end_work
	{
		if(the_target=nil){
			objectif <- 'go home';
			the_target <- entry_point;
			toKill <- true;
		}
	}
	
	reflex go_out when: day_time >=1700
	{
		if(the_target != entry_point){
			objectif <- 'go home';
			the_target <- entry_point;
			toKill <- true;
			}
	}
	
	reflex fired when: toKill
	{
		if(moving){
			nb_current_agent <- nb_current_agent -1;
			killed_people <- killed_people +1;
			do die;
		}
	}

	reflex move when: the_target != nil
	{
		

 		if (moveOnGraph){
 			moving <- true;
 			do goto( target: the_target ,on: the_graph);
 			
 			
 		}else{
 			moving <- true;
 			do goto target:the_target speed:speed;
 		}

		if (location = the_target) {
			moving <- false;
            the_target <- nil;
        }
        
        loop while:(length(old_path) > size_old_path){
        	old_path >> first(old_path);
        }
        if(moving){
        	if(flip(0.8)){
        		do wander amplitude:amplitude_wander speed:speed_wander;
        	}
        }else{
        	if(flip(0.5)){
	        	do wander amplitude:amplitude_wander speed:speed_wander;
 			}		
        }
        old_path << location;
		

	}

	reflex switchLocation when: the_target = nil 
	{
		if(flip(Need_to_move)){
			if(flip(population_LC)){
				the_target <- any_location_in(one_of(LC));	
			}else{
				the_target <- any_location_in(one_of(work_buildings));
			}
		}
	}
	
	aspect base
	{
		draw sphere(1) color: color;
		if (current_path != nil and draw_trajectory = true) {
			draw current_path.shape color: #red width: 2;
		}
		/*if (show_objectif){
			draw(objectif) color:#black font:font("Default", 100#px , #bold);//rotate:90  rotate;
			
		}*/
		if (draw_old_path){
			draw line(old_path) color:#blue;
		}
	}

}


species fond {
	aspect base {
		//draw shape color:#white texture: string("../includes/Fond Plan.png"); //empty:true;
		draw square(larg) color:#white rotate:rot texture:"../includes/Fond Plan1.png";
	}
}


experiment road_traffic type: gui
{   float minimun_cycle_duration <- 0.025;
//	parameter 'Shapefile for the buildings:' var: shape_file_buildings category: 'GIS';
//	parameter 'Shapefile for the roads:' var: shape_file_roads category: 'GIS';
//	parameter 'Shapefile for the bounds:' var: shape_file_bounds category: 'GIS';
//	parameter 'Earliest hour to end work' var: min_work_end category: 'People';
//	parameter 'Latest hour to end work' var: max_work_end category: 'People';
	parameter 'minimal speed' var: min_speed category: 'People';
	parameter 'maximal speed' var: max_speed category: 'People';
	parameter 'Number of people agents' var: nb_people category: 'People' min: 0 max: 1000 on_change:
	{
		int nb <- length(people);
		ask simulation
		{
			if (nb_people > nb)
			{
				
				if (nb_current_agent < nb_people){
					if (day_time < (60*20)){ // if before 20:00
						if (day_time > (30)){ // if after 06:00
							if ((day_time mod 10) = 0){ // tram arrive all 10 min
								new_people <- (20 + rnd(20));
								create people number: new_people {
									location <- any_location_in(one_of(tram_station));
									entry_point <- location;
									objectif <- "working";
									the_target <- any_location_in(one_of(work_buildings));
									}
								nb_current_agent <- nb_current_agent + new_people; 
							}
							if ((day_time mod 1) = 0){ // people arrive by road every min
								new_people <- rnd(10);
								create people number: new_people {
									location <- any_location_in(one_of(gate_place));
									objectif <- "working";
									entry_point <- location;
									the_target <- any_location_in(one_of(work_buildings));
								}
								nb_current_agent <- nb_current_agent + new_people;
							} 
						}
					}
				}
			} else
			{
				ask (nb - nb_people) among people
				{
					do die;
				}
			}
		}
	};
	output
	{	
		display city_display type:opengl background:#black synchronized:true ambient_light:(((day_time+2*60) mod 720)/10)  camera_pos: {279.8083,432.1905,441.7286} camera_look_pos: {310.7344,432.4962,-0.4492} camera_up_vector: {0.9975,-0.0099,0.0698} keystone: [{0.0,0.0,0.0},{-0.009849174003025984,0.9561517994158923,0.0},{1.0196983480060533,0.8867254818243895,0.0},{1.0,0.0,0.0}]
		{
			//image 'background' file:"../includes/Fond Plan.png" ;

			species fond aspect: base refresh: true;		
			species building aspect: base refresh: true;
			species learning_center_shp aspect: base refresh: true;
			species road aspect: base refresh: true;
			species people aspect: base refresh: true;
			species tram aspect: base refresh: true;
			species gate aspect: base refresh: true;
			
			event 'm' action: {
				if moveOnGraph = false{
					moveOnGraph <- true;}
				else {
					moveOnGraph <- false;
				}
			};
			event 'b' action: {
				if show_buildings = false{
					show_buildings <- true;}
				else {
					show_buildings <- false;
				}
			};
			event 'r' action: {
				if show_road = false{
					show_road <- true;}
				else {
					show_road <- false;
				}
			};
		/* 	event 'o' action: {
				if show_objectif = false{
					show_objectif <- true;}
				else {
					show_objectif <- false;
				}
			};
		*/	event 't' action: {
				if draw_trajectory = false{
					draw_trajectory <- true;}
				else {
					draw_trajectory <- false;
				}
			};
			event 'p' action: {
				if draw_old_path = false{
					draw_old_path <- true;}
				else {
					draw_old_path <- false;
				}
			};
			event 'z' action: {
				if (nb_people < 1000){
					nb_people <- nb_people + 50;
					}
			};
			event 'a' action: {
				if (nb_people >= 50){
					nb_people <- nb_people - 50;
					}
			};
			event 's' action: {
				if (size_old_path < 100){
					size_old_path <- size_old_path + 2;
					}
			};
			event 'q' action: {
				if (size_old_path >= 2){
					size_old_path <- size_old_path - 2;
					}
			};
			
			
		}
	}

}
//TODO new shape file with 3 point for the gate 