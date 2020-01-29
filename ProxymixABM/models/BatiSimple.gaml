/***
* Name: BatiSimple
* Author: chloe
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BatiSimple

/* Insert your model definition here */

global {
	file ML_file <- dxf_file("../includes/Learning_Center_Base_Arnaud_Filaire.dxf", #m);
	geometry shape <- envelope(ML_file);
	int nb_people <- 50;
    float step <- 50 #mn;
    
    int nb_cols <- int(200);
	int nb_rows <- int(100);
	bool draw_grid <- false;
    
	init {
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		ask ML_element where (each.layer="Walls.PDF_Stylo_No__149"){
			ask cell overlapping self {
				is_wall <- true;
			}
		}
		create ML_people number:nb_people{
			location <- any_location_in(one_of(ML_element where (each.layer="Restauration.PDF_Stylo_No__2")));
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
species ML_people skills:[moving]{     
    
    //variable definition
    point target;
    point location;
   	path currentPath;
    
    //Déplacements :
 
    reflex stay when: target = nil {
        if flip(0.05) {
            target <- any_location_in (one_of(ML_element where (each.layer="Activités Etudiantes.PDF_Stylo_No__6")));
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
		  draw shape color:is_wall? #red:#black border:rgb(75,75,75) empty:false;	
		}
	}	
}

experiment test type: gui {
	
	output {
		display map type:opengl rotate:180 draw_env:false background:rgb(0,0,0) autosave:false synchronized:true camera_pos: {44201.4139,15933.2568,47524.9197} camera_look_pos: {44201.4139,15932.4273,0.0863} camera_up_vector: {0.0,1.0,0.0}
		{
			species ML_element;
			species ML_people;
			species cell aspect:default position:{0,0,-0.01};
		}
	}
}