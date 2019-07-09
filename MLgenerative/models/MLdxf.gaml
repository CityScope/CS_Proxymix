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

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(ML_file);
	map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), 
	"E14"::rgb(52,152,219), 
	"E15"::rgb(192,57,43), 
	"Elevators"::rgb(161,196,90), 
	"Facade_Glass"::#magenta, 
	"Facade_Wall"::rgb(161,196,90), 
	"Glass"::rgb(161,196,90), 
	"Labs"::rgb(161,196,90), 
	"Meeting rooms"::rgb(161,196,90), 
	"Misc"::rgb(161,196,90), 
	"Offices"::rgb(161,196,90), 
	"Railing"::rgb(161,196,90), 
	"Stairs"::rgb(161,196,90), 
	"Storage"::rgb(161,196,90), 
	"Toilets"::rgb(161,196,90), 
	"Void"::rgb(161,196,90), 
	"Walls"::rgb(161,196,90)];
	
	map<string,rgb> color_per_title <- ["Visitor"::#green, 
	"Staff"::#red, 
	"Student"::#yellow, 
	"Other"::#magenta, 
	"Visitor/Affiliate"::#green, 
	"Faculty/PI"::#blue];
	
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
				color <- col;
			}
		}
		
		ask ML_element {
			if (layer="0"){
			  do die;	
			}
			
		}
		
		//create people number: nb_people {
        //location <- any_location_in;
        //}
        
        //create iris agents from the CSV file (use of the header of the CSV file), the attributes of the agents are initialized from the CSV files: 
		//we set the header facet to true to directly read the values corresponding to the right column. If the header was set to false, we could use the index of the columns to initialize the agent attributes
		create ML_people from:csv_file( "../includes/mlpeople.csv",true) with:
			[people_status::string(get("ML_STATUS")), 
				people_type::string(get("PERSON_TYPE")), 
				people_lastname::string(get("LAST_NAME")),
				people_firstname::string(get("FIRST_NAME")), 
				people_title::string(get("TITLE")), 
				people_office::string(get("OFFICE")), 
				people_group::string(get("ML_GROUP"))
			];	
			
		ask ML_people{
			if (people_status = "FALSE"){
				do die;
			}
			if (people_office != "E15-3" or people_office != "E14-3"){
				//do die;
			}
		}
        
	}
}

species ML_element
{
	string layer;
	rgb color;
	aspect default
		{
		draw shape color: color;
	}
	init {
		shape <- polygon(shape.points);
	}
}


/* species people skills: [moving]{
    rgb color <- #red ;
    ML_element mySpace;
    
    reflex move{
    	do wander;
    }
    
    aspect base {
        draw circle(10) color: color;
    }
    int start_work ;
    int end_work  ;
    string objective ; 
    point the_target <- nil ;

} */

species ML_people {
	string people_status;
	string people_type;
	string people_lastname;
	string people_firstname;
	string people_title;
	string people_office;
	string people_group;
	string type;
	rgb color ;
	
	//init {
	//	color <- type ="Iris-setosa" ? #blue : ((type ="Iris-virginica") ? #red: #yellow);
	//}
	
	aspect default {
		draw circle(30) color: color_per_title[people_type]; 
	}
}

experiment DXFAgents type: gui
{   
	parameter "Number of people agents" var: nb_people category: "People";

	output
	{	layout #split;
		display map type: opengl
		{
			species ML_element;
			//species people aspect: base;
			species ML_people;
		}

		//display "As_Image" type: opengl
		//{
		//	graphics "ML"
		//	{
		//		draw ML_file at: {0,0} color: # brown;
		//	}

		}

	}
