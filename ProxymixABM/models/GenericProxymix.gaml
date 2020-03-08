/***
* Name: Proxymix
* Author: Arnaud Grignard 
* Description: Adaptation of the original Proxymix for a more general framework 
***/

model Proxymix



global {
	int curFloor<-3;
	file ML_file <- dxf_file("../includes/ML_3.dxf",#m);
	file JsonFile <- json_file("../includes/project-network.json");
    map<string, unknown> collaborationFile <- JsonFile.contents;
	int nb_people <- 100;
	int current_hour update: (time / #hour) mod 18;
	float step <- 1 #sec;
	bool moveOnGrid <- false parameter: "Move on Grid:" category: "Model";
	bool drawSimulatedGraph <- false parameter: "Draw Simulated Graph:" category: "Vizu";
	bool draw_grid <- false parameter: "Draw Grid:" category: "Vizu";
	bool showML_element <- true parameter: "Draw ML element:" category: "Vizu";
	bool draw_trajectory <- false parameter: "Draw Trajectory:" category: "Interaction";
	
	bool instantaneaousGraph <- true parameter: "Instantaneous Graph:" category: "Interaction";
	bool saveGraph <- false parameter: "Save Graph:" category: "Interaction";
	int saveCycle <- 750;
	int distance <- 300 parameter: "Distance:" category: "Interaction" min: 100 max: 1000 step:100;
	
	
	//Rate for the infection success 
	float beta <- 0.1 parameter: "Rate for the infection success" category: "Corona" min:0.0 max:0.1;
	//Mortality rate for the host
	float nu <- 0.001 parameter: "Mortality rate for the host" category: "Corona" min:0.0 max:0.1;
	//Rate for resistance 
	float delta <- 0.001 parameter: "Rate for resistance " category: "Corona" min:0.0 max:0.1;
	int initI <- 10 parameter: "Initial Infected people" category: "Corona";
	int infectionUpdateTime <- 10 parameter: "Refresh infected status every:" category: "Corona" min:1 max:1000;
	
	
	

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "E14"::rgb(175,175,175), "E15"::rgb(175,175,175), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75), "Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), "Offices"::rgb(175,175,175), 
	"Railing"::rgb(125,124,120), "Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Void"::rgb(0,0,0), "Walls"::rgb(175,175,175)];
	
	map<string,rgb> color_per_title <- ["Visitor"::rgb(234,242,56),"Staff"::rgb(0,230,167), "Student"::rgb(255,66,109), "Other"::rgb(234,242,56), "Visitor/Affiliate"::rgb(234,242,56), "Faculty/PI"::rgb(37,211,250)];
	
	graph<people, people> real_graph;
	graph<people, people> simulated_graph;


	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	
	init {
		//--------------- ML ELEMENT CREATION-----------------------------//
		create StructuralElement from: dxf_file("../includes/ML_3.dxf",#m) with: [layer::string(get("layer"))]{
		  if (layer="0"){
		    do die;	
		  }
		}
		map layers <- list(StructuralElement) group_by each.layer;
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
		
		ask StructuralElement where (each.layer="Walls" or each.layer="Void" ){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		
		ask StructuralElement where (each.layer="Toilets" or each.layer="Elevators"  or each.layer="Meeting rooms" ){
			/*create PhysicalElement{
				location<-any_location_in(myself.shape);
			}*/
		}
		
		//--------------- ML PEOPLE CREATION-----------------------------//
		
		create people from:csv_file( "../includes/mlpeople_floors.csv",true) with:
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
			 myoffice <- first(StructuralElement where (each.layer = people_office));
			 if(myoffice != nil){
			 	location <- myoffice.shape.location;
			 } 
		}
		real_graph <- graph<people, people>([]);
				
		ask people{
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
			 location <- one_of(StructuralElement where (each.layer="Elevators_Primary"));
			 location <- any_location_in(myoffice.shape);
			 myDayTrip[rnd(3600*3)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*3+rnd(3600)]<-any_location_in(one_of(StructuralElement where (each.layer="Coffee")));
			 myDayTrip[3600*4+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*5+rnd(3600)]<-any_location_in(one_of(StructuralElement where (each.layer="Elevators_Primary")));
			 myDayTrip[3600*6+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*6+rnd(3600*2)]<-any_location_in(one_of(StructuralElement where (each.layer="Toilets")));
			 myDayTrip[3600*8+rnd(3600)]<-any_location_in (myoffice.shape);
			 myDayTrip[3600*10+rnd(3600)]<-any_location_in(one_of(StructuralElement where (each.layer="Elevators_Primary"))); 
			 
			 is_susceptible <- true;
        	 is_infected <-  false;
             is_immune <-  false; 
             color <-  #green;

		}
		
		ask 5  among people{
			is_susceptible <-  false;
            is_infected <-  true;
            is_immune <-  false; 
            color <-  #red;
		}
		
		ask people{
        	list<list<string>>  cells <- collaborationFile[people_username];            
        	loop mm over: cells {  
               people pp <- people first_with( each.people_username = string(mm[0])); //beaucoup plus optimisé que le where ici, car on s'arrête dès qu'on trouve
            	if (pp != nil) {
                		real_graph <<edge(self,pp,float(mm[1]));
                }
        	}
		}
	}
	
	reflex updateGraph when: (drawSimulatedGraph = true and instantaneaousGraph=true) {
		simulated_graph <- graph<people, people>(people as_distance_graph (distance ));
	}
	
	
	
	reflex updateAggregatedGraph when: (drawSimulatedGraph = true and instantaneaousGraph=false){
		graph simulated_graph_tmp <- graph(people as_distance_graph (distance));
		if (simulated_graph = nil) {
			simulated_graph <- simulated_graph_tmp;
		} else {
			loop e over: simulated_graph_tmp.edges {
				people s <- simulated_graph_tmp source_of e;
				people t <- simulated_graph_tmp target_of e;
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
		graph simulated_graph_tmp <- graph(people as_distance_graph (distance));
		loop e over: simulated_graph_tmp.edges {
				people s <- simulated_graph_tmp source_of e;
				people t <- simulated_graph_tmp target_of e;
				save (s.people_username +"," + t.people_username) to: "../results/generated_graph"+string(distance)+".txt" rewrite: false;			
			}
	}	
}

species StructuralElement
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

species PhysicalElement
{
	string type;
	float dirtyness;
	rgb color;
	int cleaningFrequency<-1+rnd(3600);
	
	reflex clean{
		dirtyness<-dirtyness+0.1;
		if(cycle mod cleaningFrequency=0){
		dirtyness<-0;	
		}
	}

	aspect default
	{ 
		draw square(50#m) color: blend(#red, #green, dirtyness/255);
	}	

	init {
		dirtyness<-rnd(255);
	}
}

species people skills:[moving]{
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
	rgb color;
	point the_target;
	int start_work;
	int end_work;
	string objective;
	StructuralElement myoffice;
	path currentPath;
	list<people> collaborators;
	map<people, int> collaboratorsandNumbers;
	map<people, string> collaboratorsandType;
	
	map<int,point> myDayTrip;
	float tmpTime;
	int curTrip<-0;
	
	bool is_susceptible <- true;
	bool is_infected <- false;
    bool is_immune <- false;

	
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
    
     //Reflex to make the agent infected if it is susceptible
     reflex become_infected when: (is_susceptible and cycle mod infectionUpdateTime = 0){
    	float rate  <- 0.0;
    	//computation of the infection according to the possibility of the disease to spread locally or not
    		int nb_hosts  <- 0;
    		int nb_hosts_infected  <- 0;
    		loop hst over: (people at_distance distance) {
    			nb_hosts <- nb_hosts + 1;
    			if (hst.is_infected) {
    				nb_hosts_infected <- nb_hosts_infected + 1;
    			}
    			
    		}
    		if(nb_hosts!=0){
    		  rate <- nb_hosts_infected / (nb_hosts);	
    		}else{
    			rate<-0.0;
    		}
    		

    	if (flip(beta * rate)) {
        	is_susceptible <-  false;
            is_infected <-  true;
            is_immune <-  false;
            color <-  #red;    
        }
    }
    //Reflex to make the agent recovered if it is infected and if it success the probability
    reflex become_immune when: (is_infected and flip(delta) and (cycle mod infectionUpdateTime = 0)) {
    	is_susceptible <- false;
    	is_infected <- false;
        is_immune <- true;
        color <- #blue;
    }
    
	
	aspect default {
		draw circle(20) color: color_per_title[people_type] border: color_per_title[people_type]-50; 
		if (current_path != nil and draw_trajectory=true) {
			draw current_path.shape color: #red width:2;
		}
	}
	
	
	aspect corona {
		draw circle(20) color: color ; 
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
		display map type:opengl draw_env:false background:rgb(0,0,0) synchronized:true refresh:every(10#cycle)
		{   
			species StructuralElement;
			species PhysicalElement;
			species people aspect:corona;
			species cell aspect:default position:{0,0,-0.01};
			graphics "simulated_graph" {
				if (simulated_graph != nil and drawSimulatedGraph = true) {
					loop eg over: simulated_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#white;
					}

				}
			}	
			chart "Susceptible" type: series background: #black style: exploded color:#white position:{1,0} {
				data "susceptible" value: people count (each.is_susceptible) color: #green;
				data "infected" value: people count (each.is_infected) color: #red;
				data "immune" value: people count (each.is_immune) color: #blue;
			}
			event ["g"] action:{drawSimulatedGraph<-!drawSimulatedGraph;};		
		}
	}	
}


