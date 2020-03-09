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
	file ML_file <- dxf_file("../includes/ML_" + curFloor+".dxf",#m);
	graph network;
	
	float P_shoulder_length <- 0.45 parameter: true;
	float P_body_depth <- 0.28 parameter: true;
	bool P_use_body_geometry <- false parameter: true ;
	float P_proba_detour <- 0.5 parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 1.0 parameter: true ;
	
	
	string P_pedestrian_model among: ["simple", "SFM"] <- "simple" parameter: true ;
	float P_obstacle_distance_repulsion_coeff <- 5.0 category: "simple model" parameter: true ;
	float P_overlapping_coefficient <- 2.0 category: "simple model" parameter: true ;
	float P_perception_sensibility <- 1.0 category: "simple model" parameter: true ;
	
	float P_A_SFM parameter: true <- 4.5 category: "SFM" ;
	float P_relaxion_SFM parameter: true <- 0.54 category: "SFM" ;
	float P_gama_SFM parameter: true <- 0.35 category: "SFM" ;
	float P_n_SFM <- 2.0 parameter: true category: "SFM" ;
	float P_n_prime_SFM <- 3.0 parameter: true category: "SFM";
	float P_lambda_SFM <- 2.0 parameter: true category: "SFM" ;
	
	geometry shape <- envelope(ML_file);
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		create StructuralElement from: dxf_file("../includes/ML_3.dxf",#m) with: [layer::string(get("layer"))]{
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
		
		
		if (build_pedestrian_network) {
			//option par defaut.... voir si cela convient ou non
			list<geometry> pp <- generate_pedestrian_network([StructuralElement], [world],false,false,3.0,0.1, true,0.1,0.0,0.0,50.0);
			create pedestrian_path from: pp;
			save pedestrian_path type: shp to:"../includes/pedestrian_path"  +curFloor+ ".shp";
		} else {
			
			create pedestrian_path from: file("../includes/pedestrian_path"  +curFloor+ ".shp") ;
			
			ask pedestrian_path {
				do initialize obstacles:[StructuralElement] distance: 20.0;
			}
			network <- as_edge_graph(pedestrian_path);
		
			create people number: 100 {
				location <- any_location_in(one_of(pedestrian_path).free_space);
				pedestrian_model <- P_pedestrian_model;
				obstacle_distance_repulsion_coeff <- P_obstacle_distance_repulsion_coeff;
				obstacle_consideration_distance <- P_obstacle_consideration_distance;
				overlapping_coefficient <- P_overlapping_coefficient;
				perception_sensibility <- P_perception_sensibility ;
				shoulder_length <- P_shoulder_length;
				avoid_other <- P_avoid_other;
				proba_detour <- P_proba_detour;
				A_SFM <- P_A_SFM;
				relaxion_SFM <- P_relaxion_SFM;
				gama_SFM <- P_gama_SFM;
				n_SFM <- P_n_SFM;
				n_prime_SFM <- P_n_prime_SFM;
				lambda_SFM <- P_lambda_SFM;
				
				obstacle_species <- [people, StructuralElement];
			}
		}
	}
}

species pedestrian_path skills: [pedestrian_road] {
	aspect default {
		//if(free_space != nil) {draw free_space color: #lightpink border: #black;}
		draw shape color: #red;
	}
}

species people skills: [escape_pedestrian] {
	rgb color <- rnd_color(255);
	float speed <- gauss(5,1.5) #km/#h min: 2 #km/#h;
	
	//comportement de choix de la cible
	reflex choose_target when: final_target = nil  {
		final_target <- any_location_in(one_of(pedestrian_path).free_space);
		do compute_virtual_path pedestrian_graph:network final_target: final_target ;		
		
	}
	
	 
	
	reflex move when: final_target != nil {
		do walk ;
	}	
	
	aspect default {
		//draw triangle(P_shoulder_length) rotate: heading + 90 color: color depth: 1;
		draw triangle(100) rotate: heading + 90 color: color depth: 1;
		
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
		draw square(50#m) color: #red;
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
			species pedestrian_path;
		
		}
	}
}
