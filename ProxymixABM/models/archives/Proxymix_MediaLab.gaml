/***
* Name: Proxymix
* Author: Arnaud Grignard , Nicolas Ayoub
* Description: This is the original Proxymix for the Media Lab Project
***/

model Proxymix



global {
	int curFloor<-3;
	file ML_file <- dxf_file("./../../includes/MediaLab/ML_3.dxf",#m);
	file JsonFile <- json_file("./../../includes/MediaLab/project-network.json");
    map<string, unknown> collaborationFile <- JsonFile.contents;
	int nb_people <- 100;
	int current_hour update: (time / #hour) mod 18;
	float step <- 1 #sec;
	bool moveOnGrid <- false parameter: "Move on Grid:" category: "Model";
	bool drawRealGraph <- false parameter: "Draw Real Graph:" category: "Vizu";
	bool drawSimulatedGraph <- false parameter: "Draw Simulated Graph:" category: "Vizu";
	bool draw_grid <- false parameter: "Draw Grid:" category: "Vizu";
	bool showML_element <- true parameter: "Draw ML element:" category: "Vizu";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	
	bool instantaneaousGraph <- true parameter: "Instantaneous Graph:" category: "Interaction";
	bool saveGraph <- false parameter: "Save Graph:" category: "Interaction";
	int saveCycle <- 750;
	int distance <- 200 parameter: "Distance:" category: "Interaction" min: 1 max: 10000;

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "E14"::rgb(175,175,175), "E15"::rgb(175,175,175), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75), "Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), "Offices"::rgb(175,175,175), 
	"Railing"::rgb(125,124,120), "Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Void"::rgb(0,0,0), "Walls"::rgb(175,175,175)];
	
	map<string,rgb> color_per_title <- ["Visitor"::rgb(234,242,56),"Staff"::rgb(0,230,167), "Student"::rgb(255,66,109), "Other"::rgb(234,242,56), "Visitor/Affiliate"::rgb(234,242,56), "Faculty/PI"::rgb(37,211,250)];
	
	graph<ML_people, ML_people> real_graph;
	graph<ML_people, ML_people> simulated_graph;


	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		loop i from:3 to:curFloor{
			create ML_element from: dxf_file("./../../includes/MediaLab/ML_"+i+".dxf",#m) with: [layer::string(get("layer"))]{
				floor<-i;
				if (layer="0"){
				  do die;	
				}
				//shape<-shape translated_by {0,0,world.shape.width*floor/6}; 
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
		
		create ML_people from:csv_file( "./../../includes/MediaLab/mlpeople_floors.csv",true) with:
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
			 	location <- myoffice.shape.location;
			 } 
		}
		real_graph <- graph<ML_people, ML_people>([]);
				
		ask ML_people{
			if (people_status = "FALSE"){
				do die;
			}
			if( floor!=curFloor){
				do die;
			}
			if(myoffice=nil){
				do die;	
			}
			 real_graph <<node(self);
			 location <- one_of(ML_element where (each.layer="Elevators_Primary"));
			 location <- any_location_in(myoffice.shape);
			 myDayTrip[rnd(3600*3)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*3+rnd(3600)]<-any_location_in(one_of(ML_element where (each.layer="Coffee")));
			 myDayTrip[3600*4+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*5+rnd(3600)]<-any_location_in(one_of(ML_element where (each.layer="Elevators_Primary")));
			 myDayTrip[3600*6+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*6+rnd(3600*2)]<-any_location_in(one_of(ML_element where (each.layer="Toilets")));
			 myDayTrip[3600*8+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*10+rnd(3600)]<-any_location_in(one_of(ML_element where (each.layer="Elevators_Primary"))); 
		}
		
		ask ML_people{
        	list<list<string>>  cells <- collaborationFile[people_username];            
        	loop mm over: cells {  
               ML_people pp <- ML_people first_with( each.people_username = string(mm[0])); //beaucoup plus optimisé que le where ici, car on s'arrête dès qu'on trouve
            	if (pp != nil) {
                		real_graph <<edge(self,pp,float(mm[1]));
                }
        	}
		}
	}
	
	reflex updateGraph when: (drawSimulatedGraph = true and instantaneaousGraph=true) {
		simulated_graph <- graph<ML_people, ML_people>(ML_people as_distance_graph (distance ));
	}
	
	
	
	reflex updateAggregatedGraph when: (drawSimulatedGraph = true and instantaneaousGraph=false){
		graph simulated_graph_tmp <- graph(ML_people as_distance_graph (distance));
		if (simulated_graph = nil) {
			simulated_graph <- simulated_graph_tmp;
		} else {
			loop e over: simulated_graph_tmp.edges {
				ML_people s <- simulated_graph_tmp source_of e;
				ML_people t <- simulated_graph_tmp target_of e;
				if not (s in simulated_graph.vertices) or not (t in simulated_graph.vertices) {
					simulated_graph << edge(s::t);
				} else {
					if (simulated_graph edge_between (s::t)) = nil and (simulated_graph edge_between (t::s)) = nil {
						simulated_graph << edge(s::t);
					}

				}

			}

		}

	}
	
	reflex saveCurrentGraph when:saveGraph and cycle=saveCycle {
		save ("header: if needed graphc created at cycle:" + cycle) to: "../results/generated_graph"+string(distance)+".txt" rewrite: true;
		graph simulated_graph_tmp <- graph(ML_people as_distance_graph (distance));
		loop e over: simulated_graph_tmp.edges {
				ML_people s <- simulated_graph_tmp source_of e;
				ML_people t <- simulated_graph_tmp target_of e;
				save (s.people_username +"," + t.people_username) to: "../results/generated_graph"+string(distance)+".txt" rewrite: false;			
			}
	}	
}

species ML_element
{
	string layer;
	rgb color;
	int floor;
	
	
	
	aspect default
	{ if(showML_element){
		if (layer!="0_Void"){
			draw shape color: rgb(38,38,38) border:#white empty:false;	
				}	
		else {
			 draw shape color: rgb(0,0,0) border:#white empty:false;
				}
	}  
	  
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
	path currentPath;
	list<ML_people> collaborators;
	map<ML_people, int> collaboratorsandNumbers;
	map<ML_people, string> collaboratorsandType;
	
	map<int,point> myDayTrip;
	float tmpTime;
	int curTrip<-0;

	
	 reflex move{
	 	if((time mod 36000) = myDayTrip.keys[curTrip]){	
	 		tmpTime <- time;
	 		the_target<-myDayTrip[int(tmpTime)] ;
	 		currentPath<-path_between(cell where (each.is_wall=false),location,the_target);
	 	}
	 	if(moveOnGrid){
	 	  //do goto target:the_target speed:10.0 on:cell where (each.is_wall=false) recompute_path:false;	
	 	  do follow path: currentPath;	
	 	}else{
	 	  do goto target:the_target speed:10.0;
	 	}
	 	
    	if (the_target = location and the_target!=nil){
			curTrip<-(curTrip+1);
			the_target<-nil;
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




experiment Proxymix type: gui autorun:true
{   
	//float minimum_cycle_duration<-0.02;
	output
	{	layout #split;
		display map type:opengl draw_env:false background:rgb(0,0,0) autosave:false synchronized:true refresh:every(10#cycle)
		{   
			species ML_element;
			species ML_people;
			species cell aspect:default position:{0,0,-0.01};
			graphics "simulated_graph" {
				if (simulated_graph != nil and drawSimulatedGraph = true) {
					loop eg over: simulated_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#white;
					}

				}
			}
			
			graphics "real_graph" {
				if (real_graph != nil and drawRealGraph = true) {
					loop eg over: real_graph.edges {
						geometry edge_geom <- geometry(eg);
						float w <- real_graph weight_of eg;
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90)color:#green;//rgb(0,w*10,0);
						//draw line(edge_geom.points[0],edge_geom.points[1]) width: w/2 color:rgb(0,255,0);
					}

				}
			}
			
		}
	}	
}


