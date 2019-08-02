/***
* Name: MLdxf
* Author: Nicolas Ayoub
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model MLdxf



global {
	int curFloor<-3;
	file ML_file <- dxf_file("../includes/ML_"+curFloor+".dxf",#m);
	file JsonFile <- json_file("../includes/project-network.json");
    map<string, unknown> c <- JsonFile.contents;
	int nb_people <- 100;
	int current_hour update: (time / #hour) mod 24;
	float step <- 60 #sec;
	bool drawInteraction <- false parameter: "Draw Interaction:" category: "Interaction";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	bool draw_grid <- false parameter: "Draw Grid:" category: "Interaction";
	bool updateGraph <- true parameter: "Update Graph:" category: "Interaction";
	int distance <- 200 parameter: "Distance:" category: "Interaction" min: 1 max: 1000;

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "E14"::rgb(175,175,175), "E15"::rgb(175,175,175), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75), "Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), "Offices"::rgb(175,175,175), 
	"Railing"::rgb(125,124,120), "Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Void"::rgb(10,10,10), "Walls"::rgb(175,175,175)];
	
	map<string,rgb> color_per_title <- ["Visitor"::rgb(234,242,56),"Staff"::rgb(0,230,167), "Student"::rgb(255,66,109), "Other"::rgb(234,242,56), "Visitor/Affiliate"::rgb(234,242,56), "Faculty/PI"::rgb(37,211,250)];
	
	graph<ML_people, ML_people> interaction_graph;

	int nb_cols <- 75*1.5;
	int nb_rows <- 50*1.5;
	
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		loop i from:3 to:curFloor{
			create ML_element from: dxf_file("../includes/ML_"+i+".dxf",#m) with: [layer::string(get("layer"))]{
				floor<-i;
				if (layer="0"){
				  do die;	
				}
				shape<-shape translated_by {0,0,world.shape.width*floor/6}; 
			}
		}
		map layers <- list(ML_element) group_by each.layer;
		loop la over: layers.keys
		{
			ask layers[la]
			{   if(color_per_layer.keys contains la){
				   color <- color_per_layer[la];
				}else{
					color <-#gray;
				}
			}
		}
		
		ask ML_element where (each.layer="Walls" or each.layer="Void" ){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		
		//--------------- ML PEOPLE CREATION-----------------------------//
		
		create ML_people from:csv_file( "../includes/mlpeople_floors.csv",true) with:
			[   people_status::string(get("ML_STATUS")),
				people_username::string(get("USERNAME")),  
				people_type::string(get("PERSON_TYPE")), 
				people_lastname::string(get("LAST_NAME")),
				people_firstname::string(get("FIRST_NAME")), 
				people_title::string(get("TITLE")), 
				people_office::string(get("OFFICE")), 
				people_group::string(get("ML_GROUP")),
				floor::int(get("FLOOR"))
			]{
			 start_work <- 0 + rnd(4);
			 end_work <- 4 + rnd(8);
			 objective <- "resting";
			 myoffice <- first(ML_element where (each.layer = people_office));
			 if(myoffice != nil){
			 	location <- any_location_in (myoffice.shape);
			 	location<-{location.x,location.y,world.shape.width*floor/6};
			 } 
		}
				
		ask ML_people{
			if (people_status = "FALSE"){
				do die;
			}
			if( floor!=curFloor){
				//do die;
			}
			if(myoffice=nil){
				do die;	
			}
			
		}
		
		ask ML_people{
        	list<list<string,string>> cells <- c[people_username];
        	write people_username + "is collborating with: ";
        	loop mm over: cells {  
               ML_people pp <- ML_people first_with( each.people_username= string(mm[0])); //beaucoup plus optimisé que le where ici, car on s'arrête dès qu'on trouve
            	if (pp != nil) {
            			write pp;
            			write mm[1] + "times"; 
                          collaborators<<pp;
            	          collaboratorsandNumbers[pp]<-mm[1];
            	          collaboratorsandType[pp]<-pp.people_type;
                }

        	}
        	myCollabOffice <- one_of(collaborators).myoffice;
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
	int floor;
	aspect default
	{   
	  draw shape at:{location.x,location.y,world.shape.width*floor/6}color: color border:color empty:true;	
	}
	
	init {
		shape <- polygon(shape.points);
	}
}

species ML_people skills:[moving]{
	string people_status;
	string people_username;
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
	ML_element myCollabOffice;
	list<ML_people> collaborators;
	map<ML_people, int> collaboratorsandNumbers;
	map<ML_people, string> collaboratorsandType;


		
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in(myCollabOffice);
	}
		
	reflex time_to_colaborate when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		//the_target <- any_location_in( one_of (ML_element where (each.layer="Elevators_Primary"))); 
		the_target <- any_location_in(myoffice);
	} 
	
	 reflex move when: the_target != nil{
	 	do goto target:the_target speed:5;
    	//do goto target:the_target speed:5 on: (cell where not each.is_wall) recompute_path: false;
    	//do goto target:the_target speed:5 on: (cell where not each.is_wall) recompute_path: false;
    	if the_target = location {
			the_target <- nil ;
		}
    }
	
	aspect default {
		draw circle(20) color: color_per_title[people_type] border: color_per_title[people_type]-50; 
		if (current_path != nil and draw_trajectory=true) {
			draw current_path.shape color: #red width:2;
		}
	}
	
	aspect collaboration{
			if(people_group = "City Science"){
				loop col over: collaborators {
					draw line(col.location, location) width:1+collaboratorsandNumbers[col]/5 color: rgb(0,collaboratorsandNumbers[col]*10,0);
					if(collaboratorsandNumbers[col]>0){
					  draw curve(col.location,location, 0.25, 200, 90) color:collaboratorsandNumbers[col]>0 ? #green : rgb(32,32,54);	
					}
				}
			}

		
	}
}


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




experiment AllFloor type: gui
{   
	float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:false background:rgb(32,32,54)
		{   
			species ML_element;
			species ML_people;
			species ML_people aspect:collaboration;
			species cell aspect:default position:{0,0,-0.01};
			
			graphics "interaction_graph" {
				if (interaction_graph != nil and drawInteraction = true) {
					loop eg over: interaction_graph.edges {
						geometry edge_geom <- geometry(eg);
						//draw line(edge_geom.points) width:1 color: #white;
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90);
					}

				}
			}
			
		}
	}	
}


