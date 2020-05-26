/***
* Name: generatepedestriannetwork
* Author: Patrick Taillandier
* Description: generate the pedestrian network
***/

model generatepedestriannetwork


import "DXF_Loader.gaml"

global {
	string useCase <- "Factory";
	float unit <- #cm;
	
	list<string> layer_to_consider <- [walls,offices, supermarket, meeting_rooms,coffee,storage, furnitures ];
	
	bool P_use_body_geometry <- false parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 10.0 parameter: true ;
	
	
	string P_pedestrian_model among: ["simple", "SFM"] <- "SFM" parameter: true ;
	
	bool display_free_space <- false parameter: true category:"Visualization";
	bool display_pedestrian_path <- false parameter: true category:"Visualization";
	
	float step <- 1.0;
	
	
	bool build_pedestrian_network <- true;
	graph network;
	init { 
		do initiliaze_dxf;
		ask dxf_element where not( each.layer in layer_to_consider) {
			do die;
		} 
		ask dxf_element where (each.layer = walls) {
			shape <- simplification(shape + 0.001, 0.1) ;
		}
		write length(dxf_element);
		geometry walking_area_g <- copy(shape);
			ask dxf_element {
				walking_area_g <- walking_area_g - (shape );
				walking_area_g <- walking_area_g.geometries with_max_of each.area;
			}
			create walking_area from: walking_area_g.geometries;
		if (build_pedestrian_network) {
			display_pedestrian_path <- true;
			
			//default option
			list<geometry> pp  <- generate_pedestrian_network([dxf_element],walking_area,false,false,0.0,0.0,true,0.1,0.0,0.0);
			list<geometry> cn <- clean_network(pp, 0.01,true,true);
			
			create pedestrian_path from: cn;
			save pedestrian_path type: shp to:dataset_path  + useCase+ "/pedestrian_path.shp"; 
		} else {
			
			create pedestrian_path from: shape_file(dataset_path + useCase+ "/pedestrian_path.shp") ;
			geometry walking_area_g <- copy(shape);
			ask dxf_element {
				walking_area_g <- walking_area_g - (shape + 0.01);
				walking_area_g <- walking_area_g.geometries with_max_of each.area;
			}
			create walking_area from: walking_area_g.geometries;
			
			ask pedestrian_path {
				do initialize obstacles:[dxf_element] distance: 1.0;
				free_space <- free_space inter walking_area_g;
				if (free_space = nil) {
					free_space <- copy(shape);
				}
				free_space <- free_space.geometries with_max_of each.area;
			}
			network <- as_edge_graph(pedestrian_path);
		
		
			create people number: 500 {
				location <- any_location_in(one_of(pedestrian_path).free_space);
				pedestrian_model <- P_pedestrian_model;
				avoid_other <- P_avoid_other;
					
				obstacle_species <- [people, dxf_element];
			}
		}
	}
}

species walking_area;
species pedestrian_path skills: [pedestrian_road] {
	aspect default {
		if (display_pedestrian_path) {
			if(display_free_space and free_space != nil) {draw free_space color: #lightpink border: #black;}
			draw shape color: #red;
		}
		
	}
}

species people skills: [escape_pedestrian] {
	rgb color <- rnd_color(255);
	float speed <- gauss(3,1.5) #km/#h min: 1 #km/#h;
	
	reflex choose_target when: final_target = nil  {
		final_target <- any_location_in(one_of(pedestrian_path).free_space);
		do compute_virtual_path pedestrian_graph:network final_target: final_target ;
		
	}
	
	 
	
	reflex move when: final_target != nil {
		do walk ;
	}	
	
	aspect default {
		draw circle(0.3) color: color;
		
	}
	
}


experiment generate_pedestrian_network type: gui {
	action _init_ {
		create simulation with: [build_pedestrian_network::true, dataset_path::"../../includes/",validator::false];
	}
	output {
		display map {
			species dxf_element;
			species walking_area;
			species pedestrian_path;
		
		}
	}
}



experiment test_pedestrian_network type: gui {
	float minimum_cycle_duration <- 0.05;
	action _init_ {
		create simulation with: [build_pedestrian_network::false, dataset_path::"../../includes/", validator::false];
	}
	output {
		display map {
			species dxf_element;
			species pedestrian_path;
			species people;
		
		}
	}
}
