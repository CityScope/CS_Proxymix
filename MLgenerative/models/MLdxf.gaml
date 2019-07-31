/***
* Name: MLdxf
* Author: Nicolas Ayoub
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model MLdxf

/* Insert your model definition here */

global {
	file ML_file <- dxf_file("../includes/ML_4.dxf",#m);
	
	int nb_people <- 100;
	int current_hour update: (time / #hour) mod 24;
	float step <- 60 #sec;
	bool drawInteraction <- false parameter: "Draw Interaction:" category: "Interaction";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	bool draw_grid <- true parameter: "Draw Grid:" category: "Interaction";
	bool updateGraph <- true parameter: "Update Graph:" category: "Interaction";
	int distance <- 200 parameter: "Distance:" category: "Interaction" min: 1 max: 1000;

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "E14"::rgb(175,175,175), "E15"::rgb(175,175,175), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75), "Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), "Offices"::rgb(175,175,175), 
	"Railing"::rgb(125,124,120), "Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Void"::rgb(10,10,10), "Walls"::rgb(175,175,175)];
	
	map<string,rgb> color_per_title <- ["Visitor"::#green,"Staff"::#red, "Student"::#yellow, "Other"::#magenta, "Visitor/Affiliate"::#green, "Faculty/PI"::#blue];
	
	graph<ML_people, ML_people> interaction_graph;
	
	//DImension of the grid agent
	int nb_cols <- 75*2;
	int nb_rows <- 50*2;
	
	init {
	//create house_element agents from the dxf file and initialized the layer attribute of the agents from the the file
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		
		//define a random color for each layer
		map layers <- list(ML_element) group_by each.layer;
		loop la over: layers.keys
		{
			rgb col <- rnd_color(255);
			ask layers[la]
			{   if(color_per_layer.keys contains la){
				   color <- color_per_layer[la];
				}else{
					color <-#gray;
				}
			}
		}
		
		ask ML_element {
			if (layer="0"){
			  do die;	
			}
			
		}
		
		create ML_people from:csv_file( "../includes/mlpeople_floors.csv",true) with:
			[   people_status::string(get("ML_STATUS")), 
				people_type::string(get("PERSON_TYPE")), 
				people_lastname::string(get("LAST_NAME")),
				people_firstname::string(get("FIRST_NAME")), 
				people_title::string(get("TITLE")), 
				people_office::string(get("OFFICE")), 
				people_group::string(get("ML_GROUP")),
				floor::int(get("FLOOR"))
			]{
			 //location <- any_location_in( one_of (ML_element where (each.layer="Offices")));
			 start_work <- 0 + rnd(12);
			 end_work <- 8 + rnd(16);
			 objective <- "resting";
			 myoffice <- first(ML_element where (each.layer = people_office));
			 if(myoffice != nil){
			 	location <- any_location_in (myoffice.shape);
			 	//location <- {0,0};
			 } 
		}
	
					
		ask ML_people{
			if (people_status = "FALSE"){
				do die;
			}
			if( floor!=4){
				do die;
			}
			if(myoffice=nil){
				do die;	
			}
		}
		
		ask ML_element where (each.layer="Walls" or each.layer="Void" ){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
        
	}
	
	reflex updateGraph when: (drawInteraction = true and updateGraph=true) {
		interaction_graph <- graph<ML_people, ML_people>(ML_people as_distance_graph (distance ));
	}
}

species ML_element
{
	string layer;
	rgb color;
	aspect default
	{   
	  draw shape color: color border:color empty:true;	
	}
	
	aspect extrusion
	{
		draw shape color: color depth:50;
	}
	init {
		shape <- polygon(shape.points);
	}
}

species ML_people skills:[moving]{
	string people_status;
	string people_type;
	string people_lastname;
	string people_firstname;
	string people_title;
	string people_office;
	string people_group;
	int floor;
	string type;
	rgb color ;
	point the_target;
	int start_work;
	int end_work;
	string objective;
	ML_element myoffice;


		
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in(myoffice);
	}
		
	reflex time_to_go_home when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		//the_target <- any_location_in( one_of (ML_element where (each.layer="Elevators_Primary"))); 
		the_target <- {0,0};
	} 
	
	 reflex move when: the_target != nil{
    	do goto target:the_target speed:0.5 on: (cell where not each.is_wall) recompute_path: false;
    	if the_target = location {
			the_target <- nil ;
		}
    }
	
	aspect default {
		draw circle(10) color: color_per_title[people_type] border: color_per_title[people_type]-50; 
		//draw circle(10) color: #white border: #gray; 
		if (current_path != nil and draw_trajectory=true) {
			draw current_path.shape color: #red width:2;
		}
	}
}

//Grid species to discretize space
grid cell width: nb_cols height: nb_rows neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	aspect default{
		if (draw_grid){
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:false;	
		}
		
	}	
}

experiment OneFloor type: gui
{   
	parameter "Number of people agents" var: nb_people category: "People";
	float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:false background:#black 
		{   
			species ML_element;
			species ML_people;
			species cell aspect:default position:{0,0,-0.01};
			
			graphics "interaction_graph" {
				if (interaction_graph != nil and drawInteraction = true) {
					loop eg over: interaction_graph.edges {
						//ML_people src <- interaction_graph source_of eg;
						//ML_people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) width:1 color: #white;
					}

				}
			}
			
		}
	}	
}


experiment AllLab type: gui
{   
	parameter "Number of people agents" var: nb_people category: "People";
	float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:false background:#black
		{
			species ML_element;
			species ML_people;
			
			species ML_element  position:{0,0,0.25};
			species ML_people position:{0,0,0.25};
			
			species ML_element  position:{0,0,0.5};
			species ML_people position:{0,0,0.5};
			
			species ML_element  position:{0,0,0.75};
			species ML_people position:{0,0,0.75};
		}
	}	
}
