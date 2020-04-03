/***
* Name: generatepedestriannetwork
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model generatepedestriannetwork

global {
	bool build_pedestrian_network <- false;
	int curFloor<-3;
	file ML_file <- dxf_file("../includes/MediaLab/ML_" + curFloor+".dxf",#cm);
	graph network;
	
	bool P_use_body_geometry <- false parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 10.0 parameter: true ;
	
	
	string P_pedestrian_model among: ["simple", "SFM"] <- "SFM" parameter: true ;
	
	bool display_free_space <- false parameter: true category:"Visualization";
	bool display_pedestrian_path <- false parameter: true category:"Visualization";
	
	float step <- 0.1;
	geometry shape <- envelope(ML_file);
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		create StructuralElement from: ML_file with: [layer::string(get("layer"))]{
		 //est-ce qu'il y a d'autres elements à conserver ?
		  if (layer!= "Walls"){
		    do die;	
		  }
		}
		map layers <- list(StructuralElement) group_by each.layer;
		loop la over: layers.keys
		{
			ask layers[la]
			{   
				color <-#gray;
			}
		}
		
		geometry walking_area_g <- copy(shape);
			ask StructuralElement {
				walking_area_g <- walking_area_g - (shape + 0.01);
				walking_area_g <- walking_area_g.geometries with_max_of each.area;
			}
			create walking_area from: walking_area_g.geometries;
			
		if (build_pedestrian_network) {
			
			//option par defaut.... voir si cela convient ou non
			list<geometry> pp  <- generate_pedestrian_network([],walking_area,false,false,0.0,0.0,true,0.05,0.0,0.0);
			list<geometry> cn <- clean_network(pp, 0.01,true,true);
			
			create pedestrian_path from: cn;
			save pedestrian_path type: shp to:"../includes/MediaLab/pedestrian_path"  +curFloor+ ".shp";
		} else {
			
			create pedestrian_path from: shape_file("../includes/MediaLab/pedestrian_path"  +curFloor+ ".shp") ;
			geometry walking_area_g <- copy(shape);
			ask StructuralElement {
				walking_area_g <- walking_area_g - (shape + 0.01);
				walking_area_g <- walking_area_g.geometries with_max_of each.area;
			}
			create walking_area from: walking_area_g.geometries;
			
			ask pedestrian_path {
				do initialize obstacles:[StructuralElement] distance: 2.0;
				free_space <- free_space inter walking_area_g;
			}
			network <- as_edge_graph(pedestrian_path);
		
		
			create people number: 1000 {
				location <- any_location_in(one_of(pedestrian_path).free_space);
				pedestrian_model <- P_pedestrian_model;
				avoid_other <- P_avoid_other;
				/*obstacle_distance_repulsion_coeff <- 1.0;
				obstacle_consideration_distance <- 500.0;
				overlapping_coefficient <- 0.5 ;
				perception_sensibility <- 1.0 ;
				shoulder_length <- 10.0;
				body_depth <- 10.0;
				avoid_other <- P_avoid_other;
				proba_detour <- 0.5;
				tolerance_target <- 100.0;
				min_repulsion_dist <- 10.0;
				other_people_distance_repulsion <- 500.0;*/
				
				obstacle_species <- [people, StructuralElement];
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
	
	//comportement de choix de la cible
	reflex choose_target when: final_target = nil  {
		final_target <- any_location_in(one_of(pedestrian_path).free_space);
		do compute_virtual_path pedestrian_graph:network final_target: final_target ;
		
	}
	
	 
	
	reflex move when: final_target != nil {
		do walk ;
	}	
	
	aspect default {
		draw circle(0.15) color: color;
		
	}
	
}

species StructuralElement
{
	string layer;
	rgb color;
	int floor;
	aspect default
	{
		if (layer!="0_Void"){
			draw shape color: rgb(38,38,38) border:#white empty:false;	
				}	
		else {
			 draw shape color: rgb(0,0,0) border:#white empty:false;
		}
	
	  
	}
	init {
		shape <- polygon(shape.points);
	}
}

species PhysicalElement
{
	string type;
	rgb color;
	
	
	aspect default
	{ 
		draw square(50#cm) color: #red;
	}	


}

experiment testpedestriannetwork type: gui {
	output {
		display map {
			species StructuralElement;
			species PhysicalElement;
			species pedestrian_path;
			species people;
		}
	}
}

experiment generatepedestriannetwork type: gui {
	action _init_ {
		create simulation with: [build_pedestrian_network::true];
	}
	output {
		display map {
			
			species StructuralElement;
			species PhysicalElement;
			species walking_area;
			species pedestrian_path;
		
		}
	}
}
