/***
* Name: Proxymix
* Author: Arnaud Grignard 
* Description: Adaptation of the original Proxymix for a more general framework 
***/

model Proxymix

import "Constants.gaml"
import "./ToolKit/DXF_Loader.gaml" 

global {
	float unit <- #cm;
	file the_dxf_file <- dxf_file(dataset_path + useCase +"/building.dxf",#cm);
	int nb_people <- 25;
	float step <- 30 #sec;
	int current_hour update: 6 + (time / #hour) mod 24;
	int periodstep<-360;
	int dayStep<-3600;
	bool moveOnGrid <- false parameter: "Move on Grid:" category: "Model";
	bool drawDirectGraph <- false parameter: "Draw Simulated Graph:" category: "Vizu";
	bool draw_wall_grid <- false parameter: "Draw Wall Grid:" category: "Vizu";
	bool draw_heatmap <- false parameter: "Draw Heatmap:" category: "Vizu";
	bool showPeople <- true parameter: "Draw Agent:" category: "Vizu";
	bool showML_element <- true parameter: "Draw ML element:" category: "Vizu";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	bool instantaneaousGraph <- true parameter: "Instantaneous Graph:" category: "Interaction";
	bool saveGraph <- false parameter: "Save Graph:" category: "Interaction";
	int saveCycle <- 750;
	int socialDistance <- 2 parameter: "Social distance:" category: "Corona" min: 1 max: 10 step:1;
	geometry shape <- envelope(the_dxf_file);

	map<string,rgb> standard_color_per_layer <- 
	["Offices"::#blue,"Meeting rooms"::#darkblue,
	"Entrance"::#yellow,"Elevators"::#orange,
	"Coffee"::#green,"Supermarket"::#darkgreen,
	"Storage"::#brown, "Furnitures"::#maroon, 
	"Toilets"::#purple, "Toilets_Details"::#magenta, 
	"Walls"::#gray, "Doors"::#lightgray,
	"Stairs"::#white,"Path"::#red];
	
	graph<people, people> social_distance_graph;
	list<int> activities <-[1*3600,6*3600,7*3600,8*3600,10*3600];	
	int cellSize <- 1;
	
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		create StructuralElement from: the_dxf_file with: [layer::string(get("layer"))]{
		  if (layer="Path"){
		    do die;	
		  }
		}
		map layers <- list(StructuralElement) group_by each.layer;
		loop la over: layers.keys
		{
			ask layers[la]
			{ 
				if(standard_color_per_layer.keys contains la){
				   color <- standard_color_per_layer[la];
				}else{
					color <-#gray;
				}
			}
		}
		
		ask StructuralElement where (each.layer="Walls" or each.layer="Void" ){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		
		create people number:nb_people{
			 color<-#orange;
			 myEntrance <- one_of(StructuralElement where (each.layer="Entrance"));
			 myoffice <- one_of(StructuralElement where (each.layer="Offices"));
			 myLunch <- one_of(StructuralElement where (each.layer="Supermarket"));
			 myExit <- one_of(StructuralElement where (each.layer="Entrance"));
			 location<-any_location_in(myEntrance);
		}


	}
	
	reflex updateGraph when: (drawDirectGraph = true and instantaneaousGraph=true) {
		social_distance_graph <- graph<people, people>(people as_distance_graph (socialDistance));
	}	
}

species StructuralElement
{
	string layer;
	rgb color;
	int floor;
	aspect default
	{ if(showML_element){
			draw shape color: color border:#white empty:false;	

	}  
	  
	}
	init {
		shape <- polygon(shape.points);
	}
}



species people skills:[moving] control: fsm{

	string people_type;
	int floor;
	string type;
	rgb color;
	point the_target;
	string objective;
	StructuralElement myEntrance;
	StructuralElement myExit;
	StructuralElement myoffice;
	StructuralElement myLunch;
	path currentPath;	

	
	state init initial: true {
		transition to: working when: time = activities[0] {
    	}
	}
	
	state working{
		enter{
		the_target<-any_location_in(myoffice);
	 	currentPath<-path_between(cell where (each.is_wall=false),location,the_target);
	 	}
		
		transition  to:lunching when:time = activities[1]{}
	}
	
	state lunching{
		enter{
		the_target<-any_location_in(myLunch);
	 	currentPath<-path_between(cell where (each.is_wall=false),location,the_target);	
		}
		
		transition  to:reworking when:time = activities[2]{}
	}
	state reworking{
		enter{
		the_target<-any_location_in(myoffice);
	 	currentPath<-path_between(cell where (each.is_wall=false),location,the_target);	
		}
		transition  to:gohome when:time = activities[3]{}
	}
	state gohome{
		enter{
		the_target<-any_location_in(myExit);
	 	currentPath<-path_between(cell where (each.is_wall=false),location,the_target);	
		}
		transition  to:working when:time = activities[4]{}
	}

	
	 reflex move{
	 	if(moveOnGrid){	
	 	  do follow path: currentPath;	
	 	}else{
	 	  do goto target:the_target speed:0.1;
	 	}
    }
  	aspect default {
		if(showPeople){
		  draw circle(0.5) color: color; 
		  if (current_path != nil and draw_trajectory=true) {
			draw current_path.shape color: #red width:0.02;
		  }	
		}
		
	}
}


grid cell cell_width: cellSize cell_height: cellSize neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	int nbCollision;
	aspect default{
		if (draw_wall_grid){
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:false;	
		}
		if (draw_heatmap){
			if(nbCollision>0){
			  draw shape color:rgb(nbCollision)empty:false border:rgb(nbCollision);		
			}
		}
	}	
}




experiment Proxymix type: gui autorun:true
{   parameter 'fileName:' var: useCase category: 'file' <- "Factory" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL"];
	parameter "unit" var: unit category: "file" <- #cm;
	//float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:false background:#white synchronized:true refresh:every(10#cycle)
		{   
			species StructuralElement;
			species cell aspect:default;// position:{0,0,0.01};
			species people aspect:default;
			graphics "simulated_graph" {
				if (social_distance_graph != nil and drawDirectGraph = true) {
					loop eg over: social_distance_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#white;
						ask (cell overlapping edge_geom){
							nbCollision<-nbCollision+1;
						}
					}

				}
			}	
			event ["p"] action:{showPeople<-!showPeople;};
			event ["g"] action:{drawDirectGraph<-!drawDirectGraph;};
			event ["i"] action:{ask cell{nbCollision<-0;}};
			event ["f"] action:{showML_element<-!showML_element;};
			event ["h"] action:{draw_heatmap<-!draw_heatmap;};

			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background: # black transparency: 0.0 border: #black {
				    
				    draw string ("KeyBoard Interaction:(p)eople: " + showPeople + ", (g)raph: " + drawDirectGraph + ", (h)eatmap: " + draw_heatmap
				    + ", (f)loor plan: " + showML_element) color:#white at:{0,0} font:font("Helvetica", 20 , #bold);
				    
				    draw string ("Time: " + string(current_hour) + "h") color:#white at:{0,25#px} font:font("Helvetica", 20 , #bold);
				    
					float verticalSpace <- world.shape.width * 0.025;
					float squareSize<-world.shape.width*0.02;
					loop i from:0 to:length(standard_color_per_layer)-1{
						point curPos<-{(i mod 2) * world.shape.width*0.1,((i mod 2 = 1)  ? i*verticalSpace : (i+1)*verticalSpace)+ world.shape.height/4};
						draw square(squareSize) color: standard_color_per_layer.values[i] at: curPos;
						draw standard_color_per_layer.keys[i] color: standard_color_per_layer.values[i] at: {curPos.x-30#px,curPos.y+verticalSpace} perspective: true font:font("Helvetica", 20 , #bold);
					}
			}
				
		}
	}	
}