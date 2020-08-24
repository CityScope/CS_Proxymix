/***
* Name: CityScope Epidemiology
* Author: Arnaud Grignard
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CityScopeCoronaizer


import "DailyRoutine.gaml"

global{
	float infectionDistance <- 2#m;
	float maskRatio <- 0.0;
	
	float diminution_infection_rate_separator <- 0.9;
	
	bool a_boolean_to_disable_parameters <- true;
    int number_day_recovery<-10;
	int time_recovery<-1440*number_day_recovery*60;
	float infection_rate<-0.05;
	int initial_nb_infected<-10;
	float step<-1#mn;
	int totalNbInfection;
	
	bool drawInfectionGraph <- false;
	bool draw_infection_grid <- false;
	bool showPeople<-true;
	

	int nb_cols <- int(75*1.5);
	int nb_rows <- int(50*1.5);
	

	int nb_susceptible  <- 0 update: length(ViralPeople where (each.is_susceptible));
	int nb_infected <- 0 update: length(ViralPeople where (each.is_infected));
	int nb_recovered <- 0 update: length(ViralPeople where (each.is_recovered));
	graph<people, people> infection_graph <- graph<people, people>([]);


	
	init{
			
	}
	
	reflex initCovid when:cycle=10{
		ask initial_nb_infected among ViralPeople{
			has_been_infected<-true;
			is_susceptible <-  false;
	        is_infected <-  true;
	        is_immune <-  false;
	        is_recovered<-false;
		}

		
	}
	
	reflex updateMask{
		ask ViralPeople{
		  if (flip(maskRatio)){
		    as_mask<-true;
		  }
	    }
	}

	
	
	reflex increaseRate when:cycle= 1440*7{
		//infection_rate<-0.0;//infection_rate/2;
	}
	
	reflex computeRo when: (cycle mod 100 = 0){
		/*write "yo je suis le Ro ";
		write "nbInfection" + totalNbInfection;
		write "initial_nb_infected" + initial_nb_infected;
		write "totalNbInfection/initial_nb_infected" + totalNbInfection/initial_nb_infected;*/
		list<ViralPeople> tmp<-ViralPeople where (each.has_been_infected=true);
		list<float> tmp2 <- tmp collect (each.nb_people_infected_by_me*max((time_recovery/(0.00001+time- each.infected_time))),1);
		R0<- mean(tmp2);
	}
	

}


species ViralPeople  mirrors:people{
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	bool is_susceptible <- true;
	bool is_infected <- false;
    bool is_immune <- false;
    bool is_recovered<-false;
    float infected_time<-0.0;
    geometry shape<-circle(1);
    int nb_people_infected_by_me<-0;
    bool has_been_infected<-false;
    bool as_mask<-false;

		
	reflex infected_contact when: is_infected and not target.is_outside and !as_mask {
		ask ViralPeople where !each.as_mask at_distance infectionDistance {
			if (not target.is_outside) {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					float infectio_rate_real <- infection_rate;
					if empty(separator_ag overlapping line) {
						infectio_rate_real <- infectio_rate_real * (1 - diminution_infection_rate_separator);
					}
					if (flip(infectio_rate_real)) {
		        		is_susceptible <-  false;
		            	is_infected <-  true;
		            	infected_time <- time; 
		            	ask (cell overlapping self.target){
							nbInfection<-nbInfection+1;
							myself.nb_people_infected_by_me<-myself.nb_people_infected_by_me+1;
							myself.has_been_infected<-true;
							if(firstInfectionTime=0){
								firstInfectionTime<-time;
							}
						}
						infection_graph <<edge(self,myself);
	        		}
				}
			} 
		}
	}
	
	reflex recover when: (is_infected and (time - infected_time) >= time_recovery){
		is_infected<-false;
		is_recovered<-true;
	}
	
	
	aspect base {
		if(showPeople) and not target.is_outside{
		  draw circle(is_infected ? 0.4#m : 0.3#m) color:(is_susceptible) ? #green : ((is_infected) ? #red : #blue);	
		}
		if (as_mask){
		  draw square(0.2#m) color:#white border:rgb(70,130,180)-100;	
		}	
	}
}
grid cell cell_width: world.shape.width/100 cell_height:world.shape.width/100 neighbors: 8 {
	bool is_wall <- false;
	bool is_exit <- false;
	rgb color <- #white;
	float firstInfectionTime<-0.0;
	int nbInfection;
	aspect default{
		if (draw_infection_grid){
			if(nbInfection>0){
			  draw shape color:blend(#white, #red, firstInfectionTime/time)  depth:nbInfection;		
			}
		}
	}	
}

experiment Coronaizer type:gui autorun:true parent:DailyRoutine{

	//float minimum_cycle_duration<-0.02;
	parameter "Infection distance:" category: "Policy" var:infectionDistance min: 1.0 max: 100.0 step:1;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1;
	bool a_boolean_to_disable_parameters <- true;
	parameter "Disable following parameters" category:"Corona" var: a_boolean_to_disable_parameters disables: [time_recovery,infection_rate,initial_nb_infected,step];
	parameter "Nb recovery day"   category: "Corona" var:number_day_recovery min: 1 max: 30;
	parameter "Infection Rate"   category: "Corona" var:infection_rate min:0.0 max:1.0;
	parameter "Initial Infected"   category: "Corona" var: initial_nb_infected min:0 max:100;
	parameter "Infection Graph:" category: "Visualization" var:drawInfectionGraph ;
	parameter "Draw Infection Grid:" category: "Visualization" var:draw_infection_grid;
	parameter "Show People:" category: "Visualization" var:showPeople;
	parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" among: ["UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	
	
	output{
	  display CoronaMap type:opengl parent:map background:#black draw_env:false synchronized:false{

	  	species ViralPeople aspect:base;
	  	species cell aspect:default;
	  	graphics "infection_graph" {
				if (infection_graph != nil and drawInfectionGraph = true) {
					loop eg over: infection_graph.edges {
						geometry edge_geom <- geometry(eg);
						draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#red;
					}

				}
			}

		graphics "text" {
	      //draw "day" + string(current_day) + " - " + string(current_hour) + "h" color: #gray font: font("Helvetica", 25, #italic) at:{world.shape.width * 0.8, world.shape.height * 0.975};
	  	}	
	  	
	  	graphics "infectiousStatus"{
	  		point infectiousLegendPos<-{world.shape.width*0.75,-world.shape.width*0.1};
	  		draw "PROJECTION" color:#white at:{infectiousLegendPos.x,infectiousLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 30 , #bold);
	  		draw "Infected new comers (based on local official statistics):" + initial_nb_infected color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw "Low Risk of Infection:" + nb_susceptible color: #green at: {infectiousLegendPos.x,infectiousLegendPos.y+20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw "High Risk of Infection:" + nb_infected color: #red at: {infectiousLegendPos.x,infectiousLegendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		//draw "R:" + nb_recovered color: #blue at: infectiousLegendPos+textOffSet+textOffSet perspective: true font:font("Helvetica", 20 , #plain); 
	  	}
	  	
	  	
	  	graphics "simu"{
	  		point simLegendPos<-{world.shape.width*0.25,world.shape.height*1.5};
	  		draw "PARAMETERS" color:#white at:{simLegendPos.x,simLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 30 , #bold);
	  		draw "Mask Ratio:" + maskRatio color: #white at: {simLegendPos.x,simLegendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  	}
	  	
	  	 /*graphics 'ro'{
			  point roPos<-{0,world.shape.height*1.1};
			  draw string("Ro: " + R0) color: #white at: roPos perspective: true font:font("Helvetica", 20 , #bold); 	
		 }*/
	  }	
	 /*display CoronaChart refresh:every(#mn) toolbar:false {
		//chart "Population in "+cityScopeCity type: series x_serie_labels: (current_day) x_label: 'Infection rate: '+infection_rate y_label: 'Case'{
		chart "Population in " type: series x_serie_labels: ("") x_label: 'Infection rate: '+infection_rate y_label: 'Case'{
			data "susceptible" value: nb_susceptible color: #green;
			data "infected" value: nb_infected color: #red;	
			data "recovered" value: nb_recovered color: #blue;
		}
	  }*/
	}		
}

