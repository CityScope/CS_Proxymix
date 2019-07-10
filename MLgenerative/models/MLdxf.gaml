/***
* Name: MLdxf
* Author: Nicolas Ayoub
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model MLdxf

/* Insert your model definition here */

global {
	file ML_file <- dxf_file("../includes/E14-15_3-gama2.dxf",#m);
	
	int nb_people <- 100;
	int current_hour update: (time / #hour) mod 24;
	float step <- 60 #sec;
	bool drawInteraction <- false parameter: "Draw Interaction:" category: "Interaction";
	bool updateGraph <- true parameter: "Update Graph:" category: "Interaction";
	int distance <- 20 parameter: "Distance:" category: "Interaction" min: 1 max: 100;

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "E14"::rgb(175,175,175), "E15"::rgb(175,175,175), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75), "Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), "Offices"::rgb(175,175,175), 
	"Railing"::rgb(125,124,120), "Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Void"::rgb(10,10,10), "Walls"::rgb(175,175,175)];
	
	map<string,rgb> color_per_title <- ["Visitor"::#green,"Staff"::#red, "Student"::#yellow, "Other"::#magenta, "Visitor/Affiliate"::#green, "Faculty/PI"::#blue];
	
	graph<ML_people, ML_people> interaction_graph;
	
	init {
	//create house_element agents from the dxf file and initialized the layer attribute of the agents from the the file
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		
		//define a random color for each layer
		map layers <- list(ML_element) group_by each.layer;
		loop la over: layers.keys
		{
			rgb col <- rnd_color(255);
			ask layers[la]
			{
				color <- color_per_layer[la];
				//color <- col;
			}
		}
		
		ask ML_element {
			if (layer="0"){
			  do die;	
			}
			
		}
		
		create ML_people from:csv_file( "../includes/mlpeople.csv",true) with:
			[people_status::string(get("ML_STATUS")), 
				people_type::string(get("PERSON_TYPE")), 
				people_lastname::string(get("LAST_NAME")),
				people_firstname::string(get("FIRST_NAME")), 
				people_title::string(get("TITLE")), 
				people_office::string(get("OFFICE")), 
				people_group::string(get("ML_GROUP"))
			]{
			 location <- any_location_in( one_of (ML_element where (each.layer="Elevators")));
			 start_work <- 0 + rnd(12);
			 end_work <- 8 + rnd(16);
			 objective <- "resting";
		}
			
		ask ML_people{
			if (people_status = "FALSE"){
				do die;
			}
			if (people_office != "E15-3" or people_office != "E14-3"){
				//do die;
			}
			if( flip(0.5)){
				do die;
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
		draw shape color: color empty:true;
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
	string type;
	rgb color ;
	point the_target;
	int start_work;
	int end_work;
	string objective;

		
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in( one_of (ML_element where (each.layer="Labs")));
	}
		
	reflex time_to_go_home when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in( one_of (ML_element where (each.layer="Offices"))); 
	} 
	
	 reflex move when: the_target != nil{
    	do goto target:the_target speed:0.5;
    	//do wander speed:0.01;
    	if the_target = location {
			the_target <- nil ;
		}
    }
	
	aspect default {
		//draw circle(10) color: color_per_title[people_type] border: color_per_title[people_type]-50; 
		draw circle(10) color: #white border: #gray; 
	}
}

experiment OneFloor type: gui
{   
	parameter "Number of people agents" var: nb_people category: "People";
	float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:java2D draw_env:false background:#black
		{
			species ML_element;
			species ML_people;
			graphics "interaction_graph" {
				if (interaction_graph != nil and drawInteraction = true) {
					loop eg over: interaction_graph.edges {
						ML_people src <- interaction_graph source_of eg;
						ML_people target <- interaction_graph target_of eg;
						geometry edge_geom <- geometry(eg);
						draw line(edge_geom.points) width:1.5 color: #white;
					}

				}
			}
			species ML_people;
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
