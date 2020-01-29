/***
* Name: campus
* Author: Thibaut
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Campus

/* Insert your model definition here */

global {
	//Load of the different shapefiles used by the model
	file shape_file_buildings <- shape_file('../includes/campus.shp', 0);
	//file shape_file_roads <- shape_file('../includes/road.shp', 0);
	file shape_file_bounds <- shape_file('../includes/environ.shp', 0);
	//file shape_tram <- shape_file('../include/tram.shp', 0);
	
		
    float step <- 1 #s parameter: "Time speed" category: "Model"; 
    
    int nb_cols <- int(50);
	int nb_rows <- int(30);
	bool draw_grid <- false;
	
	//Definition of the shape of the world as the bounds of the shapefiles to show everything contained
	// by the area delimited by the bounds
	geometry shape <- envelope(shape_file_bounds);
	int nb_people <- 2;
	int day_time update: cycle mod 144;
	int min_work_start <- 36;
	int max_work_start <- 60;
	int min_work_end <- 84;
	int max_work_end <- 132;
	float min_speed <- 50.0;
	float max_speed <- 100.0;
	list<building> work_buildings;
	//building learning_center;
	
	//Declaration of a graph that will represent our road network
	graph the_graph;
	
	/* Get the list of point for the when the road cross the boarder. It's to get the possible entrance and exit */
	list<point> get_all_entrance_exit_point(road road_data, Tram tram_data){
		list<point> ret <- [point(rnd(10), rnd(10)), point(rnd(10), rnd(10)), point(rnd(10), rnd(10)), point(rnd(10), rnd(10))];
		return ret;
	}
	
	/* Get a random set of building that will be visited by the people */
	list<building> get_visited_building(list<building> all_buildings){
		int nbr_building <- (1 + rnd(3));
		list<building> ret;

		loop times: nbr_building {
			ret <- ret + one_of(all_buildings);
		}
		return ret;
	}
	
	init
	{
		create building from: shape_file_buildings //with: [type:: string(read('NATURE'))]
		{
			if type = "Industrial"
			{
				color <- # blue;
			}
			write "height";
			height <- 10 + rnd(90);
		}

		//work_buildings <- building where (each.type = 'Residential');
		work_buildings <- list(building);
		//industrial_buildings <- building where (each.type = 'Industrial');
		//create road from: shape_file_roads;
		//the_graph <- as_edge_graph(road);
		create people number: nb_people;
		
		
		//create ML_people number:nb_people;
		//ask ML_people {location <- any_location_in(one_of(ML_element));}
		//create ML_element from: ML_file;// with: [layer::string(get("layer"))];
		//map layers <- list(ML_element) group_by each.layer;
	}
	


}

//  ------- CRÉATION DE L'ESPACE ------------
species Tram{
	string type;
	rgb color <- # red;
	//int height;
	aspect base
	{
		//draw shape color: color depth: height;
		draw shape color: color border:#white;
	}
}

species building
{
	string type;
	rgb color <- # gray;
	int height;
	aspect base
	{
		draw shape color: color;// depth: height;
	}

}


species road
{
	rgb color <- # black;
	aspect base
	{
		draw shape color: color;
	}

}

species people skills: [moving]
{
	float speed <- min_speed + rnd(max_speed - min_speed);
	rgb color <- rnd_color(255);
	
	//list<building> place_visited <- one_of(residential_buildings);
	//building working_place <- one_of(industrial_buildings);
	
	building living_place <- one_of(work_buildings);
	building working_place <- one_of(work_buildings);
	
	//point location <- any_location_in(living_place) + { 0, 0, living_place.height };
	point location <- any_location_in(living_place) + { 0, 0, living_place.height };
	int start_work <- min_work_start + rnd(max_work_start - min_work_start);
	int end_work <- min_work_end + rnd(max_work_end - min_work_end);
	string objectif;
	point the_target <- nil;
	reflex time_to_work when: day_time = start_work
	{
		objectif <- 'working';
		the_target <- any_location_in(working_place);
	}

	reflex time_to_go_home when: day_time = end_work
	{
		objectif <- 'go home';
		the_target <- any_location_in(living_place);
	}

	reflex move when: the_target != nil
	{
		do goto( target: the_target ,on: the_graph);
		switch the_target
		{
			match location
			{
				the_target <- nil;
				location <- { location.x, location.y, objectif = 'go home' ? living_place.height : working_place.height };
			}

		}

	}

	aspect base
	{
		draw sphere(3) color: color;
	}

}

species ML_element
{
	string layer;
	aspect {
		draw shape color: rgb(38,38,38) border:#white empty:true;
	}
	
	init {
		shape <- polygon(shape.points);
		ask ML_element where (each.layer="Walls"){
			ask cell overlapping self {
				is_wall <- true;
				}
		}
//		ask ML_element {
//			loop i over: self.shape.points{
//				ask cell overlapping i {
//					is_wall <- true;
//				}
//			}
//		}
	}
	
}


// ------- CRÉATION DES INDIVIDUS ----------
species ML_people skills:[moving]{     
    
    //variable definition
    point target;
   	path currentPath;
    
    //Déplacements :
    reflex stay when: target = nil {
        if flip(0.05) {
            target <- any_location_in (one_of(ML_element));
        }
    }
        
    reflex move when: target != nil{
    	currentPath<-path_between(cell where (each.is_wall=false),location,target);
    	do follow path: currentPath;
        //do goto target: target;
        if (location = target) {
            target <- nil;
        } 
    }
    aspect default {
    	if (target != location){
    		draw circle(500) color: rgb(0,125,255) border: rgb(0,125,255); 
    	}
    	if (target = nil){
    		draw circle(500) color: rgb(255,255,255) border: rgb(255, 255, 255); 
    	}
		if (current_path != nil and target != nil) {
			draw current_path.shape color: #red width:1;
		}
	}
}

// ----------- CREATION DE LA GRILLE --------
grid cell width: nb_cols height: nb_rows neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	aspect default{
		if (draw_grid){
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:true;	
		}
	}	
}

experiment test type: gui {

	
	// Define parameters here if necessary
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
		display map type:java2D draw_env:false background:rgb(0,0,0) autosave:false synchronized:true refresh:every(10#cycle)
		{
			species ML_element;
			species ML_people;
			species cell aspect:default position:{0,0,-0.01};
		}
	}
}

experiment road_traffic type: gui
{   float minimun_cycle_duration <- 0.025;
	parameter 'Shapefile for the buildings:' var: shape_file_buildings category: 'GIS';
//	parameter 'Shapefile for the roads:' var: shape_file_roads category: 'GIS';
	parameter 'Shapefile for the bounds:' var: shape_file_bounds category: 'GIS';
	parameter 'Earliest hour to start work' var: min_work_start category: 'People';
	parameter 'Latest hour to start work' var: max_work_start category: 'People';
	parameter 'Earliest hour to end work' var: min_work_end category: 'People';
	parameter 'Latest hour to end work' var: max_work_end category: 'People';
	parameter 'minimal speed' var: min_speed category: 'People';
	parameter 'maximal speed' var: max_speed category: 'People';
	parameter 'Number of people agents' var: nb_people category: 'People' min: 0 max: 1000 on_change:
	{
		int nb <- length(people);
		ask simulation
		{
			if (nb_people > nb)
			{
				create people number: nb_people - nb;
			} else
			{
				ask (nb - nb_people) among people
				{
					do die;
				}
			}
		}
	};
	output
	{	
		display city_display type:opengl synchronized:true camera_pos: {292.3925,360.1845,286.8195} camera_look_pos: {292.3975,360.1842,-0.0015} camera_up_vector: {0.9991,0.0428,0.0}
		{
			species building aspect: base refresh: true;
//			species road aspect: base ;
			species people aspect: base;
		}
	}

}