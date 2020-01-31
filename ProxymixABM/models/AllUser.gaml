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
	int nb_people <- 100;
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
	graph<People, People> as_graph;
	int distance <- 5000;
    
	init {
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		ask ML_element where (each.layer="Murs"){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		create People number:nb_people{
			id <- "Etudiant1";
			}
		create People number:50{
			id <- "Etudiant2";
			}
		create People number:nb_people{
			id <- "Admin";
			}
		create People number:20{
			id <- "Prof";
			}
		ask People{
			if (self.id = 'Etudiant1'){
			myoffice <- one_of(ML_element where (each.layer="Locaux_Etudiants"));
			//location <- any_location_in(one_of(ML_element where (each.layer="Administratif" and not(((cell overlapping each) accumulate each.is_wall) contains false))));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(10, 80)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(400, 500)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(800, 900)]<-any_location_in (one_of(ML_element where (each.layer="Amphitheatre")));
			myDayTrip[rnd(1200, 1400)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));
			}
			if (self.id = 'Etudiant2'){
			myoffice <- one_of(ML_element where (each.layer="Locaux_Etudiants"));
			//location <- any_location_in(one_of(ML_element where (each.layer="Administratif" and not(((cell overlapping each) accumulate each.is_wall) contains false))));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(300, 500)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(1200, 1400)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));
			}
			if (self.id = 'Admin'){
			myoffice <- one_of(ML_element where (each.layer="Administratif"));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(10, 20)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(400, 500)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(800, 900)]<-any_location_in (one_of(ML_element where (each.layer="Amphitheatre")));
			myDayTrip[rnd(1200, 1400)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));
			}
			if (self.id = 'Prof'){
			myoffice <- one_of(ML_element where (each.layer="Locaux_Etudiants"));
			location <- any_location_in(one_of(ML_element where (each.layer="Entree_Sortie")));
			myDayTrip[rnd(10, 20)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(400, 500)]<-any_location_in (one_of(ML_element where (each.layer="Magasins")));
			myDayTrip[rnd(700, 800)]<-any_location_in (one_of(ML_element where (each.layer="Entree_Sortie")));
			}
		}
	}
	// GRAPHE ADMIN ETU
	reflex updateGraphAS {
		if (drawStudentGraph = true){
		as_graph <- graph<People, People>(People where (each.id ='Etudiant') as_distance_graph (distance));
		}
		if (drawAdminGraph = true){
		as_graph <- graph<People, People>(People where (each.id ='Admin') as_distance_graph (distance));
		}
		if (drawAS = true){
		as_graph <- graph<People, People>(People as_distance_graph (distance));
		}
	}
	
	reflex updateAggregatedGraphAS{
		if (drawStudentGraph = true){
		graph as_graph_tmp <- graph(People where (each.id ='Etudiant') as_distance_graph (distance));	
			if (as_graph = nil) {
				as_graph <- as_graph_tmp;
			} else {
				loop e over: as_graph_tmp.edges {
					People s <- as_graph_tmp source_of e;
					People t <- as_graph_tmp target_of e;
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
		
		if (drawAdminGraph = true){
		graph as_graph_tmp <- graph(People where (each.id ='Admin') as_distance_graph (distance));
			if (as_graph = nil) {
				as_graph <- as_graph_tmp;
			} else {
				loop e over: as_graph_tmp.edges {
					People s <- as_graph_tmp source_of e;
					People t <- as_graph_tmp target_of e;
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
		if (drawAS = true){
		graph as_graph_tmp <- graph(People as_distance_graph (distance));
			if (as_graph = nil) {
				as_graph <- as_graph_tmp;
			} else {
				loop e over: as_graph_tmp.edges {
					People s <- as_graph_tmp source_of e;
					People t <- as_graph_tmp target_of e;
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
species People skills:[moving]{     
    
    //variable definition
	point target;
	string id;
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
	 	}
	 	if (grid = true){
	 		do follow path: currentPath speed: 2000;
	 	}
	 	else{
	 		do goto target: target speed: 2000;
	 	}

	 	if (target = location and target!=nil and id = 'Etudiant2' and curTrip < 1){
    		//write 'curTrip +1';
			curTrip<-(curTrip+1);
			target<-nil;
		}
		if (target = location and target!=nil and id = 'Prof' and curTrip < 3){
    		//write 'curTrip +1';
			curTrip<-(curTrip+1);
			target<-nil;
		}
    	if (target = location and target!=nil and id != 'Etudiant2' and id!="Prof" and curTrip < 4){
    		//write 'curTrip +1';
			curTrip<-(curTrip+1);
			target<-nil;
		}
    }
    aspect default {
    	if (id = 'Etudiant1' or id = 'Etudiant2'){
    		draw circle(500) color: rgb(255,255,255) border: rgb(255, 255, 255); 
    	}
    	if(id = 'Admin'){
    		draw circle(500) color: rgb(0,125,255) border: rgb(0,125,255);
    	}
    	if(id = 'Prof'){
    		draw circle(500) color: rgb(58, 137, 35) border: rgb(58, 137, 35);
    	}
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
		display map type:opengl rotate:180 draw_env:false background:rgb(0,0,0) autosave:false synchronized:true camera_pos: {157691.1176,70218.4834,185282.9836} camera_look_pos: {157691.1176,70215.2494,-0.8612} camera_up_vector: {0.0,1.0,0.0}
		{
			species ML_element;
			species People;
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
					drawAS <- true;
					drawAdminGraph <- false;
					drawStudentGraph <- false;
				}
				else {
					drawAS <- false;
				}
			};
			graphics "as_graph" {
				if (as_graph != nil and drawAS = true) {
					loop eg over: as_graph {
						geometry edge_geom <- geometry(eg);
							draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:rgb(225,225,255);
					}
				}
			}
		}
	}
}