/***
* Name: Proxymix
* Author: Arnaud Grignard 
* Description: Adaptation of the original Proxymix for a more general framework 
***/

model Proxymix



global {
	file ML_file <- dxf_file("../includes/FactoryGAMA.dxf",#cm);
	int nb_people <- 100;
	float step <- 10 #sec;
	int periodstep<-360;
	int dayStep<-3600;
	bool moveOnGrid <- false parameter: "Move on Grid:" category: "Model";
	bool drawDirectGraph <- true parameter: "Draw Simulated Graph:" category: "Vizu";
	bool draw_grid <- true parameter: "Draw Grid:" category: "Vizu";
	bool showPeople <- true parameter: "Draw Agent:" category: "Vizu";
	bool showML_element <- true parameter: "Draw ML element:" category: "Vizu";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	bool instantaneaousGraph <- true parameter: "Instantaneous Graph:" category: "Interaction";
	bool saveGraph <- false parameter: "Save Graph:" category: "Interaction";
	int saveCycle <- 750;
	
	
	int socialDistance <- 2 parameter: "Social distance:" category: "Corona" min: 1 max: 10 step:1;

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);

	
	
	map<string,rgb> standard_color_per_layer <- ["Offices"::rgb(161,196,90),"Entrance"::rgb(0,200,200),"Elevators"::rgb(200,200,200),"Meeting rooms"::rgb(125,125,125),"Coffee"::rgb(175,175,175),
	"Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Walls"::rgb(175,175,175), "Supermarket"::rgb(175,175,175)];
	
	
	map<string,rgb> color_per_title <- ["Visitor"::rgb(234,242,56),"Staff"::rgb(0,230,167), "Student"::rgb(255,66,109), "Other"::rgb(234,242,56), "Visitor/Affiliate"::rgb(234,242,56), "Faculty/PI"::rgb(37,211,250)];
	
	graph<people, people> social_distance_graph;
	
	
	list<int> activities <-[1*3600,6*3600,7*3600,8*3600,10*3600];


	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		create StructuralElement from: ML_file with: [layer::string(get("layer"))]{
		  if (layer="0"){
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
			
			 myoffice <- one_of(StructuralElement where (each.layer="Meeting rooms"));
			 myLunch <- one_of(StructuralElement where (each.layer="Supermarket"));
			 myEntrance <- one_of(StructuralElement where (each.layer="Entrance"));
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
	int start_work;
	int end_work;
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
	 	  //do goto target:the_target speed:10.0 on:cell where (each.is_wall=false) recompute_path:false;	
	 	  do follow path: currentPath;	
	 	}else{
	 	  do goto target:the_target speed:0.1;
	 	}
    }
        	
	aspect default {
		draw circle(0.5) color: color; 
		if (current_path != nil and draw_trajectory=true) {
			draw current_path.shape color: #red width:0.02;
		}
	}
}


grid cell width: nb_cols height: nb_rows neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	int nbCollision;
	aspect default{
		/*if (draw_grid){
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:false;	
		}*/
		if (draw_grid){
			if(nbCollision>0){
			  draw shape color:rgb(nbCollision)empty:false border:rgb(nbCollision);		
			}
		}
	}	
}




experiment Proxymix type: gui autorun:true
{   
	//float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:true background:rgb(0,0,0) synchronized:true refresh:every(10#cycle)
		{   
			species StructuralElement;
			//species PhysicalElement;
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
			/*chart "Susceptible" type: series background: rgb(50,50,50) style: exploded color:#white position:{1,0}  y_tick_line_visible:false x_tick_line_visible:false{
				data "susceptible" value: people count (each.is_susceptible) color: #green;
				data "infected" value: people count (each.is_infected) color: #red;
				data "immune" value: people count (each.is_immune) color: #blue;
			}*/
			event ["p"] action:{showPeople<-!showPeople;};
			event ["g"] action:{drawDirectGraph<-!drawDirectGraph;};
			event ["i"] action:{ask cell{nbCollision<-0;}};
			event ["m"] action:{showML_element<-!showML_element;};
			event ["h"] action:{draw_grid<-!draw_grid;};
					
			
			graphics "Legend" {
				    //draw cross(100,20) color: #green at: {0, -world.shape.height*0.1};
					//draw "Indirect Interaction" color: #green  at: {0+100, -world.shape.height*0.1+100} font:font("Helvetica", 20 , #bold);	
			}
				
		}
	}	
}



