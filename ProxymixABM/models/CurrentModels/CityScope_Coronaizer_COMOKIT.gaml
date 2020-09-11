/***
* Name: CityScope Epidemiology
* Author: Patrick Taillandier et Arnaud Grignard
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CityScopeCoronaizer

import "COMOKIT/Biological Entity.gaml"
import "DailyRoutine.gaml" 

global{
	float infectionDistance <- 3#m;
	float maskRatio <- 0.0;
	float time_recovery <- 10 #d;
	
	float diminution_infection_rate_separator <- 0.9;
	
	bool a_boolean_to_disable_parameters <- true;
	int initial_nb_infected<-5;
	int initial_nb_infected_dyn<-initial_nb_infected;
	
	bool drawInfectionGraph <- false;
	bool drawSocialDistanceGraph <- false;
	bool draw_infection_grid <- false;
	bool showPeople<-true;
	

	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	
	int nb_susceptible  <- 0 update: (BiologicalEntity count not(each.state in [latent, asymptomatic, presymptomatic, symptomatic]));
	int nb_latent <- 0 update: (BiologicalEntity count (each.state = latent));
	int nb_infected <- 0 update: (BiologicalEntity count (each.state in [asymptomatic, presymptomatic, symptomatic]));
	graph<people, people> infection_graph <- graph<people, people>([]);
	graph<people, people> social_distance_graph <- graph<people, people>([]);
	
	init{
		do init_epidemiological_parameters;
	}
	
	reflex update_step_variables when: change_step  {
		nb_step_for_one_day <- #day/step;
		successful_contact_rate_building <- 2.5 * 1/(14.69973*nb_step_for_one_day);
		ask BiologicalEntity {
			basic_viral_release <- world.get_basic_viral_release(age);
			contact_rate <- world.get_contact_rate_human(age);
		}
	}
	
	
	
	
	reflex initCovid when:initial_nb_infected_dyn > 0 and not empty(BiologicalEntity where not(each.state in [latent, asymptomatic, presymptomatic, symptomatic])){
		ask one_of(BiologicalEntity where not(each.state in [latent, asymptomatic, presymptomatic, symptomatic])){
			do define_new_case(one_of([asymptomatic, symptomatic]));
			tick <- rnd(0, infectious_period) #hour;
			initial_nb_infected_dyn <- initial_nb_infected_dyn - 1;
			
		}
	}
	reflex updateGraph when: (drawSocialDistanceGraph = true) {
		social_distance_graph <- graph<people, people>(people as_distance_graph (infectionDistance));
	}
	
	reflex computeR0 when: every(5#mn){
		int totalNbInfection <- nb_latent + nb_infected;
		write "nbInfection: " + totalNbInfection;
		write "initial_nb_infected: " + initial_nb_infected;
		write "totalNbInfection/initial_nb_infected: " + totalNbInfection/initial_nb_infected;
		list<BiologicalEntity> tmp<-BiologicalEntity where (each.has_been_infected=true);
		list<float> tmp2 <- tmp collect (each.nb_people_infected_by_me*max((time_recovery/(0.00001+time- each.infected_time))),1);
		write "R0: " + mean(tmp2);
	}
	
}


grid cell cell_width: world.shape.width/100 cell_height:world.shape.width/100 neighbors: 8 schedules: cell where (each.viral_load > 0) {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	float firstInfectionTime<-0.0;
	int nbInfection;
	float viral_load;
	aspect default{
		if (draw_infection_grid){
			if(nbInfection>0){
			  draw shape color:blend(#white, #red, firstInfectionTime/time)  depth:nbInfection;		
			}
		}
	}
	
	//Action to add viral load to the building
	action add_viral_load(float value){
		if(allow_transmission_building)
		{
			viral_load <- min(1.0,viral_load+value);
		}
	}
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: allow_transmission_building {
		viral_load <- max(0.0,viral_load - basic_viral_decrease/nb_step_for_one_day);
	}
		
}

experiment Coronaizer type:gui autorun:true parent:DailyRoutine{

	//float minimum_cycle_duration<-0.02;
	parameter "Infection distance:" category: "Policy" var:infectionDistance min: 1.0 max: 100.0 step:1;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1;
	parameter "Separator" category: "Policy" var: separator_proba <- 0.5 min:0.0 max:1.0;
	bool a_boolean_to_disable_parameters <- true;
	parameter "Initial Infected"   category: "Corona" var: initial_nb_infected min:0 max:100;
	parameter "Social Distance Graph:" category: "Visualization" var:drawSocialDistanceGraph ;
	parameter "Infection Graph:" category: "Visualization" var:drawInfectionGraph ;
	parameter "Draw Infection Grid:" category: "Visualization" var:draw_infection_grid;
	parameter "Show People:" category: "Visualization" var:showPeople;
	parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" among: ["Factory","MediaLab"];
	
	output{
	  display CoronaMap type:opengl  background:#black draw_env:false synchronized:false{

	  	species BiologicalEntity aspect:base;
	  	species cell aspect:default;
	  	/*graphics "infection_graph" {
				if (infection_graph != nil and drawInfectionGraph = true) {
					loop eg over: infection_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#red;
					} 

				}
			}
		graphics "social_graph" {
				if (social_distance_graph != nil and drawSocialDistanceGraph = true) {
					loop eg over: social_distance_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#gray;
					}

				}
		}*/
		graphics "text" {
	      //draw "day" + string(current_day) + " - " + string(current_hour) + "h" color: #gray font: font("Helvetica", 25, #italic) at:{world.shape.width * 0.8, world.shape.height * 0.975};
	  	}	
	  	
	  	graphics "infectiousStatus"{
	  		point infectiousLegendPos<-{0,0};
	  		point textOffSet<-{0,20#px};
	  		draw "S:" + nb_susceptible color: #green at: infectiousLegendPos perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw "L:" + nb_latent color: #pink at: infectiousLegendPos+textOffSet+textOffSet perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw "I:" + nb_infected color: #red at: infectiousLegendPos+textOffSet perspective: true font:font("Helvetica", 20 , #plain); 
	  		
	  	}
	  }	
	 display CoronaChart refresh:every(5#mn) toolbar:false {
		//chart "Population in "+cityScopeCity type: series x_serie_labels: (current_day) x_label: 'Infection rate: '+infection_rate y_label: 'Case'{
		chart "Population in " type: series x_serie_labels: ("")  y_label: 'Case'{
			data "susceptible" value: nb_susceptible color: #green;
			data "latent" value: nb_latent color: #pink;
			data "infected" value: nb_infected color: #red;	
		}
	  }
	} 		
}

