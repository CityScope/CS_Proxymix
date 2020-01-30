/***
* Name: BatiSimple
* Author: chloe
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BatiSimple


global {
	file ML_file <- dxf_file("../includes/LCBigPorte.dxf", #m);
	geometry shape <- envelope(ML_file);
	int nb_people <- 50;
    float step <- 1 #sec;
    int current_hour update: (time / #hour) mod 18;
    int nb_cols <- int(200);
	int nb_rows <- int(100);
	bool draw_grid <- false;
	bool grid <- true;
	bool draw_path <- false;
    
	init {
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		ask ML_element where (each.layer="Murs"){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		create Visitors number:nb_people{
			//start_work <- 0 + rnd(4);
			//end_work <- 13 + rnd(4);
			//objective <- "resting";
			myoffice <- one_of(ML_element where (each.layer="Locaux_Etudiants"));
			location <- any_location_in(one_of(ML_element where (each.layer="Administratif")));
//			if(myoffice != nil){
//				location <- myoffice.shape.location;
			myDayTrip[rnd(10, 20)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(200, 250)]<-any_location_in (one_of(ML_element where (each.layer="Restauration")));
			myDayTrip[rnd(300, 400)]<-any_location_in (myoffice.shape);
			myDayTrip[rnd(500, 600)]<-any_location_in (one_of(ML_element where (each.layer="Magasins")));			
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


// ------- CRÉATION DES INDIVIDUS ----------
species Visitors skills:[moving]{     
    
    //variable definition
	point target;
//	point the_start;
	int start_work; // start day
	int end_work; //end day
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

	 	
    	if (target = location and target!=nil and curTrip < 3){
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
	//float minimum_cycle_duration <- 0.02 #sec;
	
	output {
		display map type:opengl rotate:180 draw_env:false background:rgb(0,0,0) autosave:false synchronized:true camera_pos: {44201.4139,15933.2568,47524.9197} camera_look_pos: {44201.4139,15932.4273,0.0863} camera_up_vector: {0.0,1.0,0.0}
		{
			species ML_element;
			species Visitors;
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
		}
	}
}