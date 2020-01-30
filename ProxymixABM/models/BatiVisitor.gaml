/***
* Name: BatiSimple
* Author: chloe
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BatiSimple


global {
	file ML_file <- dxf_file("../includes/LC_final.dxf", #m);
	geometry shape <- envelope(ML_file);
	int nb_people <- 50;
    float step <- 1 #sec;
    int current_hour update: (time / #hour) mod 18;
    int nb_cols <- int(200);
	int nb_rows <- int(100);
	bool draw_grid <- false;
	bool grid <- true;
	bool draw_path <- false;
	bool drawStudentGraph <- false;
	bool drawAdminGraph <- false;
	bool drawAS <- false;
	graph<Etudiants, Etudiants> student_graph;
	graph<Admin1, Admin1> admin_graph;
	graph<Etudiants, Admin1> as_graph;
	int distance <- 10000;
    
	init {
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		ask ML_element where (each.layer="Murs"){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		create Etudiants number:nb_people{
			myoffice <- one_of(ML_element where (each.layer="Locaux_Etudiants"));
			//location <- any_location_in(one_of(ML_element where (each.layer="Administratif" and not(((cell overlapping each) accumulate each.is_wall) contains false))));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(10, 20)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(400, 500)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(800, 900)]<-any_location_in (one_of(ML_element where (each.layer="Amphitheatre")));
			myDayTrip[rnd(1000, 1200)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));			
		}
//		ask Etudiants{
//			if ((cell overlapping self) accumulate contains true){
//				do die;
//			}
//		}

//		ask Etudiants{
//			if (curTrip = 4 and target = location){
//				do die;
//			} 
//		}

		create Admin1 number:nb_people{
			myoffice <- one_of(ML_element where (each.layer="Administratif"));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(10, 20)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(400, 500)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(800, 900)]<-any_location_in (one_of(ML_element where (each.layer="Amphitheatre")));
			myDayTrip[rnd(1000, 1200)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));				
		}
//		ask Admin1{
//			if (curTrip = 4 and target = location){
//				do die;
//			} 
//		}
	
	}
	
	// GRAPHE ETU ETU
	
	reflex updateGraphS when: (drawStudentGraph = true) {
		student_graph <- graph<Etudiants, Etudiants>(Etudiants as_distance_graph (distance));
	}
	
	reflex updateAggregatedGraphS when: (drawStudentGraph = true){
		graph student_graph_tmp <- graph(Etudiants as_distance_graph (distance));
		if (student_graph = nil) {
			student_graph <- student_graph_tmp;
		} else {
			loop e over: student_graph_tmp.edges {
				Etudiants s <- student_graph_tmp source_of e;
				Etudiants t <- student_graph_tmp target_of e;
				if not (s in student_graph.vertices) or not (t in student_graph.vertices) {
					student_graph << edge(s::t);
				} else {
					if (student_graph edge_between (s::t)) = nil and (student_graph edge_between (t::s)) = nil {
						student_graph << edge(s::t);
					}
				}
			}
		}
	}
	
	// GRAPHE ADMIN ADMIN
	reflex updateGraphA when: (drawAdminGraph = true) {
		admin_graph <- graph<Admin1, Admin1>(Admin1 as_distance_graph (distance));
	}
	
	reflex updateAggregatedGraphA when: (drawAdminGraph = true){
		graph admin_graph_tmp <- graph(Admin1 as_distance_graph (distance));
		if (admin_graph = nil) {
			admin_graph <- admin_graph_tmp;
		} else {
			loop e over: admin_graph_tmp.edges {
				Admin1 s <- admin_graph_tmp source_of e;
				Admin1 t <- admin_graph_tmp target_of e;
				if not (s in admin_graph.vertices) or not (t in admin_graph.vertices) {
					admin_graph << edge(s::t);
				} else {
					if (admin_graph edge_between (s::t)) = nil and (admin_graph edge_between (t::s)) = nil {
						admin_graph << edge(s::t);
					}
				}
			}
		}
	}
	// GRAPHE ADMIN ETU
	reflex updateGraphAS when: (drawAS = true) {
		as_graph <- graph<Etudiants, Admin1>(Etudiants as_distance_graph (distance));
	}
	
	reflex updateAggregatedGraphAS when: (drawAS = true){
		graph as_graph_tmp <- graph(Etudiants as_distance_graph (distance));
		if (as_graph = nil) {
			as_graph <- as_graph_tmp;
		} else {
			loop e over: as_graph_tmp.edges {
				Admin1 s <- as_graph_tmp source_of e;
				Admin1 t <- as_graph_tmp target_of e;
				if not (s in as_graph.vertices) or not (t in as_graph.vertices) {
					as_graph << edge(s::t);
				} else {
					if (as_graph edge_between (s::t)) = nil and (as_graph edge_between (t::s)) = nil {
						as_graph << edge(s::t);
					}
				}
			}
		}
	}
}

//  ------- CRÉATION DE L'ESPACE ------------
species ML_element
{
	string layer;
	aspect {
		draw shape color: rgb(38,38,38) border:#white empty:true;
	}
	
	init {
		shape <- polygon(shape.points);
	}
	
}


// ------- CRÉATION DES Etudiants ----------
species Etudiants skills:[moving]{     
    
    //variable definition
	point target;
	path currentPath;
	ML_element myoffice;
	map<int,point> myDayTrip;
	float tmpTime;
	int curTrip<-0;
    
    //Déplacements :
	reflex move{
	 	if(time = myDayTrip.keys[curTrip]){	 // Duration day : [06:00, 23:00] 61200
	 		tmpTime <- time;
	 		target<-myDayTrip[int(tmpTime)] ;
	 		currentPath<-path_between(cell where (each.is_wall=false),location,target);
	 		//write 'i have a path';
	 	}
	 	if (grid = true){
	 		do follow path: currentPath speed: 2000;
	 	}
	 	else{
	 		do goto target: target speed: 2000;
	 	}

	 	
    	if (target = location and target!=nil and curTrip < 4){
    		//write 'curTrip +1';
			curTrip<-(curTrip+1);
			target<-nil;
		}
    }
    aspect default {
    	draw circle(500) color: rgb(255,255,255) border: rgb(255, 255, 255); 
//    	if (target != location){
//    		draw circle(500) color: rgb(0,125,255) border: rgb(0,125,255); 
//    	}
//    	if (target = nil){
//    		draw circle(500) color: rgb(255,255,255) border: rgb(255, 255, 255); 
//    	}
		if (draw_path = true and current_path != nil and target != nil and target != location) {
			draw current_path.shape color: #red width:1;
		}
	}
}

// ------- CRÉATION DES Vistieurs ----------
species Admin1 skills:[moving]{     
    
    //variable definition
	point target;
	path currentPath;
	ML_element myoffice;
	map<int,point> myDayTrip;
	float tmpTime;
	int curTrip<-0;
    
    //Déplacements :
	reflex move{
	 	if(time = myDayTrip.keys[curTrip]){	 // Duration day : [06:00, 23:00] 61200
	 		tmpTime <- time;
	 		target<-myDayTrip[int(tmpTime)] ;
	 		currentPath<-path_between(cell where (each.is_wall=false),location,target);
	 		//write 'i have a path';
	 	}
	 	if (grid = true){
	 		do follow path: currentPath speed: 2000;
	 	}
	 	else{
	 		do goto target: target speed: 2000;
	 	}

	 	
    	if (target = location and target!=nil and curTrip < 4){
    		//write 'curTrip +1';
			curTrip<-(curTrip+1);
			target<-nil;
		}
    }
    aspect default {
    	draw circle(500) color: rgb(0,125,255) border: rgb(0,125,255); 
//    	if (target != location){
//    		draw circle(500) color: rgb(0,125,255) border: rgb(0,125,255); 
//    	}
//    	if (target = nil){
//    		draw circle(500) color: rgb(255,255,255) border: rgb(255, 255, 255); 
//    	}
		if (draw_path = true and current_path != nil and target != nil and target != location) {
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
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:false;	
		}
	}	
}

experiment test type: gui {
	output {
		display map type:opengl rotate:180 draw_env:false background:rgb(0,0,0) autosave:false synchronized:true camera_pos: {44201.4139,15933.2568,47524.9197} camera_look_pos: {44201.4139,15932.4273,0.0863} camera_up_vector: {0.0,1.0,0.0}
		{
			species ML_element;
			species Etudiants;
			species Admin1;
			species cell aspect:default position:{0,0,-0.01};
			event 'c' action: {
				if draw_path = false{
					draw_path <- true;}
				else {
					draw_path <- false;
				}
			};
			event 'g' action: {
				if draw_grid = false{
					draw_grid <- true;}
				else {
					draw_grid <- false;
				}
			};
			event 'r' action: {
				if drawStudentGraph = false{
					drawStudentGraph <- true;}
				else {
					drawStudentGraph <- false;
				}
			};
			event 't' action: {
				if drawAdminGraph = false{
					drawAdminGraph <- true;}
				else {
					drawAdminGraph <- false;
				}
			};
			event 'y' action: {
				if drawAS = false{
					drawAS <- true;}
				else {
					drawAS <- false;
				}
			};
			graphics "student_graph" {
				if (student_graph != nil and drawStudentGraph = true) {
					loop eg over: student_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#white;
					}
				}
			}
			graphics "admin_graph" {
				if (admin_graph != nil and drawAdminGraph = true) {
					loop eg over: admin_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:rgb(0,125,255);
					}
				}
			}
			graphics "as_graph" {
				if (as_graph != nil and drawAS = true) {
					loop eg over: as_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:rgb(0,125,255);
					}
				}
			}
		}
	}
}