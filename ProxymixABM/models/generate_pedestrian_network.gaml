/***
* Name: generatepedestriannetwork
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model generatepedestriannetwork

global {
	int curFloor<-3;
	file ML_file <- dxf_file("../includes/ML_" + curFloor+".dxf",#m);
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
		
		
		
		//option par defaut.... voir si cela convient ou non
		list<geometry> pp <- generate_pedestrian_network([StructuralElement], [world],false,false,3.0,0.1, true,0.1,0.0,0.0,50.0);
		create pedestrian_path from: pp;
		save pedestrian_path type: shp to:"../includes/pedestrian_path"  +curFloor+ ".shp";
	}
}

species pedestrian_path {
	aspect default {
		draw shape color: #red;
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

experiment generatepedestriannetwork type: gui {
	output {
		display map {
			species StructuralElement;
			species PhysicalElement;
			species pedestrian_path;
		}
	}
}
