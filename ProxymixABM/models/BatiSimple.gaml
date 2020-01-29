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
    float step <- 10 #mn;
    
    int nb_cols <- int(50);
	int nb_rows <- int(30);
	bool draw_grid <- false;
    
	init {
		create ML_people number:nb_people;
		//ask ML_people {location <- any_location_in(one_of(ML_element where (each.layer="Restauration.PDF_Stylo_No__2")));}
		create ML_element from: ML_file with: [layer::string(get("layer"))];
		//map layers <- list(ML_element) group_by each.layer;
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
//		ask ML_element where (each.layer="Walls"){
//			ask cell overlapping self {
//				is_wall <- true;
//				}
//		}
		ask ML_element {
			loop i over: self.shape.points{
				ask cell overlapping i {
					is_wall <- true;
				}
			}
		}
	}
	
}


// ------- CRÉATION DES INDIVIDUS ----------
species ML_people skills:[moving]{     
    
    //variable definition
    point target;
    point location <- any_location_in(one_of(ML_element where (each.layer="Restauration.PDF_Stylo_No__2")));
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
	
	output {
		display map type:java2D draw_env:false background:rgb(0,0,0) autosave:false synchronized:true refresh:every(10#cycle)
		{
			species ML_element;
			species ML_people;
			species cell aspect:default position:{0,0,-0.01};
		}
	}
}