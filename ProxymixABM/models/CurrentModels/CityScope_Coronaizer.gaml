/***
* Name: CityScope Epidemiology
* Author: Arnaud Grignard
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CityScopeCoronaizer


import "DailyRoutine.gaml"

global{
	
	bool use_SIR_model <- false;
	bool fixed_infected_people_localization <- true;
	bool direct_infection <- true;
	bool objects_infection <- true;
	bool air_infection <- true;
	float infectionDistance <- 1#m;
	float maskRatio <- 0.0;
	float direct_infection_factor<-0.05; //increasement of the infection risk per second
	
	float indirect_infection_factor<-0.003; //increasement of the viral load of cells per second 
	float basic_viral_decrease_cell <- 0.0003; //decreasement of the viral load of cells per second 
	
	float air_infection_factor <- 0.002; //decreasement of the viral load of cells per second 
	float basic_viral_decrease_room <- 0.0001; //decreasement of the viral load of cells per second 
	float ventilated_viral_decrease_room <- 0.01; //decreasement of the viral load of cells per second 
	
	float diminution_infection_risk_sanitation <- 10.0;
	float hand_cleaning_time_effect <- 1#h;
	float diminution_infection_risk_mask <- 0.7; //1.0 masks are totaly efficient to avoid direct transmission
	float diminution_infection_risk_separator <- 0.9;
	
	
	bool a_boolean_to_disable_parameters <- true;
    
    int number_day_recovery<-10;
	int time_recovery<-1440*number_day_recovery*60;
	float infection_rate<-0.05;
    //float step<-1#mn;
	int totalNbInfection;
   	int initial_nb_infected<-10;
   	map<room, int> infected_per_room;
   	float Low_Risk_of_Infection_threshold<-30.0;
   	float Medium_Risk_of_Infection_threshold<-60.0;
	
	bool drawInfectionGraph <- false;
	bool draw_infection_grid <- false;
	bool draw_viral_load_by_touching_grid<-false;
	bool draw_viral_load_per_room<-true;
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
		if fixed_infected_people_localization {
			int nb_i;
			map<room,list<ViralPeople>> pp_per_room <- ViralPeople group_by each.target.working_place;
			list<room> r_ord <- pp_per_room.keys  sort_by each.name;
			int direction_i <- 0;
			loop r over: r_ord {
				list<ViralPeople> pps <- pp_per_room[r];
				int nb_infected_room <- round(initial_nb_infected * length(pps)/ length(ViralPeople));
				nb_infected_room <- min(nb_infected_room, initial_nb_infected - nb_i);
				if nb_infected_room > 0 and not empty(pps){
					int direction <- direction_i;
					
					loop times: nb_infected_room {
						ViralPeople vp;
						if direction = 0 {
							vp <- pps with_min_of (each.target.working_desk.location distance_to each.target.working_place.location);
						}else if direction = 1 {
							vp <- (pps sort_by (each.target.working_desk.location.y - each.target.working_desk.location.x)) [min(4, length(pps) - 1)];
						} else if direction = 2 {
							vp <- (pps sort_by (each.target.working_desk.location.x - each.target.working_desk.location.y)) [min(2, length(pps) - 1)];
						} else {
							vp <- pps with_max_of (each.target.working_desk.location distance_to each.target.working_place.location);
						}
						ask vp{
							has_been_infected<-true;
							is_susceptible <-  false;
					        is_infected <-  true;
					        is_immune <-  false;
					        is_recovered<-false;
					        pps >> self;
						}
						direction <- (direction + 1 ) mod 4;
					}
					
					
					pp_per_room[r] <- pps;
					nb_i <- nb_i + nb_infected_room;
				}
				direction_i <- (direction_i + 1) mod 4;
				
				
			}
			if nb_i < initial_nb_infected {
				list<room> ror <- pp_per_room.keys sort_by length(pp_per_room[each]);
				
				int direction <- 0;
				
				loop while: nb_i < initial_nb_infected {
					loop r over: ror {
						if (nb_i = initial_nb_infected) {
							break;
						} else {
							list<ViralPeople> pps <- pp_per_room[r];
							ViralPeople vp;
							
							if direction = 0 {
								vp <- pps with_min_of (each.target.working_desk.location distance_to each.target.working_place.location);
							}else if direction = 1 {
								vp <- (pps sort_by (each.target.working_desk.location.y - each.target.working_desk.location.x)) [min(4, length(pps) - 1)];
							} else if direction = 2 {
								vp <- (pps sort_by (each.target.working_desk.location.x - each.target.working_desk.location.y)) [min(2, length(pps) - 1)];
							} else {
								vp <- pps with_max_of (each.target.working_desk.location distance_to each.target.working_place.location);
							}
							ask vp{
								has_been_infected<-true;
								is_susceptible <-  false;
						        is_infected <-  true;
						        is_immune <-  false;
						        is_recovered<-false;
						        pps >> self;
							}
							direction <- (direction + 1 ) mod 4;
						
							pp_per_room[r] <- pps;
							nb_i <- nb_i + 1;
								
						}
					}
				}
			}
		
		} else {
			ask initial_nb_infected among ViralPeople{
				has_been_infected<-true;
				is_susceptible <-  false;
				is_infected <-  true;
				is_immune <-  false;
				is_recovered<-false;
			}
		}
		
	}
	
	
	reflex increaseRate when:use_SIR_model and cycle= 1440*7{
		//infection_rate<-0.0;//infection_rate/2;
	}
	
	reflex computeRo when: use_SIR_model and (cycle mod 100 = 0){
		/*write "yo je suis le Ro ";
		write "nbInfection" + totalNbInfection;
		write "initial_nb_infected" + initial_nb_infected;
		write "totalNbInfection/initial_nb_infected" + totalNbInfection/initial_nb_infected;*/
		list<ViralPeople> tmp<-ViralPeople where (each.has_been_infected=true);
		list<float> tmp2 <- tmp collect (each.nb_people_infected_by_me*max((time_recovery/(0.00001+time- each.infected_time))),1);
		R0<- mean(tmp2);
	}

}


species ViralBuildingEntrance mirrors: building_entrance parent: ViralRoom ;

species ViralCommonArea mirrors: common_area parent: ViralRoom ;

species ViralRoom mirrors: room {
	float viral_load min: 0.0 max: 10.0;
	init {
		shape <- target.shape;
	}
	
	reflex update_viral_load when: not use_SIR_model and air_infection{
		if (target.isVentilated) {
			viral_load <- viral_load - (ventilated_viral_decrease_room * step);
		} else {
			viral_load <- viral_load - (basic_viral_decrease_room * step);
		}
		
	}
	
	//Action to add viral load to the room
	action add_viral_load(float value){
		viral_load <- viral_load + (value/ shape.area);
	}
	
	aspect default {
		if(draw_viral_load_per_room){
		  if (air_infection) {draw shape color: blend(rgb(169,0,0), rgb(62,232,5), viral_load*1000);//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);	
		}		
		}
	}
}


species ViralPeople  mirrors:people{
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	float infection_risk min: 0.0 max: 100.0;
	bool is_susceptible <- true;
	bool is_infected <- false;
    bool is_immune <- false;
    bool is_recovered<-false;
    float infected_time<-0.0;
    geometry shape<-circle(1); 
  	int nb_people_infected_by_me<-0;
    bool has_been_infected<-false;
    bool has_mask<-flip(maskRatio);
    float time_since_last_hand_cleaning update: time_since_last_hand_cleaning + step;


	reflex infected_contact_risk when: not target.end_of_day and not use_SIR_model and is_infected and not target.is_outside and not target.using_sanitation {
		if (direct_infection) {
			ask (ViralPeople at_distance infectionDistance) where (not each.target.end_of_day and not each.is_infected and not each.target.using_sanitation and not each.target.is_outside) {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					float direct_infection_factor_real <- direct_infection_factor * step;
					if empty(separator_ag overlapping line) {
						direct_infection_factor_real <- direct_infection_factor_real * (1 - diminution_infection_risk_separator);
					}
					if myself.has_mask {
						direct_infection_factor_real <- direct_infection_factor_real * (1 - diminution_infection_risk_mask);
					}
					 infection_risk <- infection_risk + direct_infection_factor_real;
				} 
			}
		}
		if (objects_infection) and (time_since_last_hand_cleaning < hand_cleaning_time_effect){
			ViralCell vc <- ViralCell(self.target.location);
			if (vc != nil) {
				ask (vc){
					do add_viral_load(indirect_infection_factor * step);
				}
			}
		}
		if (air_infection) {
			ViralRoom my_room <- first(ViralRoom overlapping location);
			if (my_room != nil) {ask my_room{do add_viral_load(air_infection_factor * step);}}
			ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
			if (my_rca != nil) {ask my_rca{do add_viral_load(air_infection_factor * step);}}
			
		}
	}
	
	reflex using_sanitation when: not target.end_of_day and not use_SIR_model and target.using_sanitation {
		infection_risk <- infection_risk - diminution_infection_risk_sanitation * step;
		time_since_last_hand_cleaning <- 0.0;
	}
	reflex infection_by_objects when:not target.end_of_day and  objects_infection and not use_SIR_model and not is_infected and not target.is_outside and not target.using_sanitation {
		ViralCell vrc <- ViralCell(location);
		if (vrc != nil) {infection_risk <- infection_risk + step * vrc.viral_load_by_touching;}
	}
	reflex infection_by_air when: not target.end_of_day and air_infection and not use_SIR_model and not is_infected and not target.is_outside and not target.using_sanitation {
		ViralRoom my_room <- first(ViralRoom overlapping location);
		if (my_room != nil) {infection_risk <- infection_risk + step * my_room.viral_load;}
		ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
		if (my_rca != nil) {infection_risk <- infection_risk + step * my_rca.viral_load;}
	}
	
	reflex infected_contact when: not target.end_of_day and use_SIR_model and is_infected and not target.is_outside and !has_mask {
		ask (ViralPeople where (not each.target.end_of_day and !each.has_mask and not each.is_infected)) at_distance infectionDistance {
			if (not target.is_outside) {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					float infectio_rate_real <- infection_rate;
					if empty(separator_ag overlapping line) {
						infectio_rate_real <- infectio_rate_real * (1 - diminution_infection_risk_separator);
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
	
	reflex recover when:not target.end_of_day and use_SIR_model and (is_infected and (time - infected_time) >= time_recovery){
		is_infected<-false;
		is_recovered<-true;
	}
	
	
	aspect base {
		if not target.end_of_day {
			if(showPeople) and not target.is_outside{
			  draw circle(is_infected ? peopleSize*1.25 : peopleSize) color:
			  	use_SIR_model ? ((is_susceptible) ? #green : ((is_infected) ? #red : #blue)) :
			  	((is_infected) ? #blue : blend(#red, #green, infection_risk/100.0));
				if (has_mask){
					draw square(peopleSize*0.5) color:#white border:rgb(70,130,180)-100;	
				}
			}
		}	
	}
}


grid ViralCell cell_width: 1.0 cell_height:1.0 neighbors: 8 {
	rgb color <- #white;
	
	float viral_load_by_touching min: 0.0 max: 10.0;
	
	//Action to add viral load to the cell
	action add_viral_load(float value){
		viral_load_by_touching <- viral_load_by_touching+value;
	}
	//Action to update the viral load (i.e. trigger decreases)
	reflex update_viral_load when: not use_SIR_model {
		viral_load_by_touching <- viral_load_by_touching - (basic_viral_decrease_cell * step);
	}
	aspect default{
		if (draw_viral_load_by_touching_grid){
			if not use_SIR_model and (viral_load_by_touching > 0){
				draw shape color:blend(#white, #red, viral_load_by_touching/1.0);		
			}
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
			if use_SIR_model {
				if(nbInfection>0){
				  draw shape color:blend(#white, #red, firstInfectionTime/time)  depth:nbInfection;		
				}
			} 
		}
	}	
}

experiment Coronaizer type:gui autorun:true{

	//float minimum_cycle_duration<-0.02;
	parameter "Infection distance:" category: "Policy" var:infectionDistance min: 1.0 max: 100.0 step:1;
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1;
	bool a_boolean_to_disable_parameters <- true;
	parameter "Disable following parameters" category:"Corona" var: a_boolean_to_disable_parameters disables: [time_recovery,infection_rate,initial_nb_infected,step];
	parameter "Nb recovery day"   category: "Corona" var:number_day_recovery min: 1 max: 30;
	parameter "Infection Rate"   category: "Corona" var:infection_rate min:0.0 max:1.0;
	parameter "Initial Infected"   category: "Corona" var: initial_nb_infected min:0 max:100;
	parameter "Infection Graph:" category: "Visualization" var:drawInfectionGraph ;
	parameter "Draw Infection Grid (only available with SIR):" category: "Risk Visualization" var:draw_infection_grid;
	parameter "Draw Infection by Touching Grid:" category: "Risk Visualization" var:draw_viral_load_by_touching_grid;
	parameter "Draw Viral Load:" category: "Risk Visualization" var:draw_viral_load_per_room<-true;
	parameter "Show People:" category: "Visualization" var:showPeople;
    parameter 'fileName:' var: useCase category: 'file' <- "UDG/CUAAD" among: ["UDG/CUCS/Campus","UDG/CUSUR","UDG/CUCEA","UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	parameter "Density Scenario" var: density_scenario category:'Initialization'  <- "num_people_room" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Visualization' min:0.0 max:5.0#m <- 5.0#m;
	parameter 'People per Building (only working if density_scenario is num_people_building):' var: num_people_per_building category:'Initialization' min:0 max:1000 <- 10;
	parameter 'People per Room (only working if density_scenario is num_people_building):' var: num_people_per_room category:'Initialization' min:0 max:100 <- 10;
	parameter "Simulation Step"   category: "Corona" var:step min:0.0 max:100.0;
	parameter "unit" var: unit category: "file" <- #cm;
	parameter "Simulation information:" category: "Visualization" var:drawSimuInfo ;
	parameter "Social Distance Graph:" category: "Visualization" var:drawSocialDistanceGraph ;
	parameter "Draw Flow Grid:" category: "Visualization" var:draw_flow_grid;
	parameter "Draw Proximity Grid:" category: "Visualization" var:draw_proximity_grid;
	parameter "Draw Pedestrian Path:" category: "Visualization" var:display_pedestrian_path;
	parameter "Show available desk:" category: "Visualization" var:showAvailableDesk <-false;
	parameter "Show bottlenecks:" category: "Visualization" var:show_dynamic_bottleneck <-false;
	parameter "Bottlenecks lifespan:" category: "Visualization" var:bottleneck_livespan min:0 max:100 <-10;
	parameter "Show droplets:" category: "Droplet" var:show_droplet <-false;
	parameter "Droplets lifespan:" category: "Droplet" var:droplet_livespan min:0 max:100 <-10;
	parameter "Droplets distance:" category: "Droplet" var:droplet_distance min:0.0 max:10.0 <-2.0;
	parameter "Ventilated room ratio (appears in Green):" category: "Ventilation" var:ventilation_ratio min:0.0 max:1.0 <-0.2;
		
	output{
	  layout #split;
	  display Simulation type:opengl  background:#black draw_env:false synchronized:false autosave:false{
	  	species room  refresh: false;
		species room aspect: available_places_info refresh: true;
		species ViralRoom transparency:0.75 position:{0,0,0.00};
		species ViralCommonArea transparency:0.85 position:{0,0,0.001};
		species building_entrance refresh: true;
		species common_area refresh: true;
		species wall refresh: false;
		species room_entrance;
		species pedestrian_path ;
		species separator_ag refresh: false;
		agents "flowCell" value:draw_flow_grid ? flowCell : [] transparency:0.5;
		agents "proximityCell" value:draw_proximity_grid ? proximityCell : [] ;
		species bottleneck transparency: 0.5;
		species droplet aspect:base; 
	    species ViralPeople aspect:base position:{0,0,0.002};
	    species ViralCell aspect:default;
	  	species cell aspect:default;
	
		graphics 'title'{
		  point titlePos<-{-world.shape.width*0.25,-world.shape.width*0.1};
		  draw string(title) color: #white at: {titlePos.x,titlePos.y-200#px,0.01} perspective: true font:font("Helvetica", 90 , #bold);
		}	
		graphics "time" {
		  point timeLegendPos<-{-world.shape.width*0.25,world.shape.height*0.5};
	      draw "TIME:" color: #white font: font("Helvetica", 30, #bold) at:{timeLegendPos.x,timeLegendPos.y,0.01};
	      draw string(current_date, "HH:mm:ss") color: #white font: font("Helvetica", 20, #bold) at:{timeLegendPos.x,timeLegendPos.y+20#px,0.01};
	      draw string("step: "+ step) color: #white font: font("Helvetica", 20, #bold) at:{timeLegendPos.x,timeLegendPos.y+40#px,0.01};
	  	}
	  	graphics "infectiousStatus"{
	  		point infectiousLegendPos<-{world.shape.width*0.25,-world.shape.width*0.2};
	  		//draw "SIMULATION PROJECTION" color:#white at:{infectiousLegendPos.x,infectiousLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 50 , #bold);
	  		if (use_SIR_model) {
	  			draw "Initial infected new comers:" + initial_nb_infected + " people" color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  			draw "Susceptible:" + nb_susceptible color: #green at: {infectiousLegendPos.x,infectiousLegendPos.y+20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
		  		draw circle(peopleSize) color:#green at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y+20#px-5#px,0.01} perspective: true;
		  		draw "Infected:" + nb_infected  color: #red at: {infectiousLegendPos.x,infectiousLegendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
		  		draw circle(peopleSize) color:#red at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y+40#px-5#px,0.01} perspective: true font:font("Helvetica", 20 , #plain);
		  	
	  		}
	  		else {
	  			draw "Initial infected new comers:" + initial_nb_infected + " people" color: #blue at: {infectiousLegendPos.x,infectiousLegendPos.y,0.01} perspective: true font:font("Helvetica", 40 , #plain); 
	  			draw circle(peopleSize*2) color:#blue at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y-5#px,0.01} perspective: true;
	  			draw "Low Risk of Infection:" + (ViralPeople count (each.infection_risk < Low_Risk_of_Infection_threshold)) + " people"color: #green at: {infectiousLegendPos.x,infectiousLegendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 40 , #plain); 
	  			draw circle(peopleSize*2) color:#green at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y+40#px-5#px,0.01} perspective: true;
	  			draw "Medium Risk of Infection:" + (ViralPeople count (each.infection_risk >= Low_Risk_of_Infection_threshold and each.infection_risk < Medium_Risk_of_Infection_threshold)) + " people"color: #orange at: {infectiousLegendPos.x,infectiousLegendPos.y+80#px,0.01} perspective: true font:font("Helvetica", 40 , #plain); 
	  			draw circle(peopleSize*2) color:#orange at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y+80#px-5#px,0.01} perspective: true;
	  			draw "High Risk of Infection:" + (ViralPeople count (each.infection_risk >= Medium_Risk_of_Infection_threshold))  + " people" color: #red at: {infectiousLegendPos.x,infectiousLegendPos.y+120#px,0.01} perspective: true font:font("Helvetica", 40 , #plain); 
	  			draw circle(peopleSize*2) color:#red at:{infectiousLegendPos.x-5#px,infectiousLegendPos.y+120#px-5#px,0.01} perspective: true font:font("Helvetica", 20 , #plain);
	  		}
	  	}
	  	
	  graphics "intervention"{
	  		point simLegendPos<-{-world.shape.width*0.25,world.shape.height*1.5};
	  		draw "INTERVENTION" color:#white at:{simLegendPos.x,simLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 30 , #bold);
	  		draw string("Physical distance: " +  (density_scenario="data" ? "none" : with_precision(distance_people,2))) color: #white at: {simLegendPos.x,simLegendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain);
	  		draw "Percentage of user wearing masks:" + maskRatio*100 + "%" color: #white at: {simLegendPos.x,simLegendPos.y+20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw "Type of Ventilation: " + ventilationType color:#white at:{simLegendPos.x,simLegendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 20 , #plain);
	  		draw "Time Spent in classrooms: " + timeSpent/#hour + "h" color:#white at:{simLegendPos.x,simLegendPos.y+60#px,0.01} perspective: true font:font("Helvetica", 20 , #plain);
	  	}
	  	graphics "legend"{
	  		point legendPos<-{world.shape.width*1,world.shape.height*1.5};
	  		/*draw "LEGEND" color:#white at:{legendPos.x-30#px,legendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 30 , #bold);
	  		draw "Stairwell"color: #darkgray at: {legendPos.x,legendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw rectangle(20#px,10#px) color:#darkgray at:{legendPos.x-20#px,legendPos.y+-5#px,0.01} perspective: true;
	  		draw "Classrooms"color: #white at: {legendPos.x,legendPos.y+20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw rectangle(20#px,10#px) color:#darkgrey at:{legendPos.x-20#px,legendPos.y+20#px-5#px,0.01} perspective: true;
	  		draw "Meeting Rooms"color: #white at: {legendPos.x,legendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw rectangle(20#px,10#px) color:#lightgrey at:{legendPos.x-20#px,legendPos.y+40#px-5#px,0.01} perspective: true;
	  		*/
	  		draw "Desk"color: #white at: {legendPos.x,legendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw rectangle(10#px,10#px) color:#white at:{legendPos.x-20#px,legendPos.y-20#px-5#px,0.01} perspective: true;
	  		draw "Entrance"color: #white at: {legendPos.x,legendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  		draw circle(8#px)-circle(4#px) color:#yellow at:{legendPos.x-20#px,legendPos.y-5#px,0.01} perspective: true;
	  	}	  	
	  	graphics 'site'{
			  point sitlegendPos<-{world.shape.width*0.25,world.shape.height*1.5};
			  draw string("SITE:" + useCase) color: #white at: {sitlegendPos.x,sitlegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 30 , #bold);
		      draw string("Building Type: " +  useCaseType ) color: #white at: {sitlegendPos.x,sitlegendPos.y,0.01} perspective: true font:font("Helvetica", 20 , #plain);
		      draw string("Floor area: " + with_precision(totalArea,2) + "m2") color: #white at: {sitlegendPos.x,sitlegendPos.y+20#px,0.01} perspective: true font:font("Helvetica", 20 , #plain); 	      
		      draw string("Total Occupants: " +  length(people) ) color: #white at: {sitlegendPos.x,sitlegendPos.y+40#px,0.01} perspective: true font:font("Helvetica", 20 , #plain);  	
		}	
		
	  	graphics "infection_graph" {
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
		}

	  }	
	 /*display CoronaChart refresh:every(#mn) toolbar:false background:#black{
		chart "Population in " size:{1.0,1.0}style:line background:#black type: series x_serie_labels: ("") x_label: 'Infection rate: '+infection_rate y_label: 'Case'{
			data "susceptible" value: nb_susceptible color: #green;
			data "infected" value: nb_infected color: #red;	
			//data "recovered" value: nb_recovered color: #blue;
		}
		
		chart "People Distribution" background:#black  type: pie size: {1.0,1.0} position: {world.shape.width*1.1,world.shape.height*0.5} color: #white axes: #yellow title_font: 'Helvetica' title_font_size: 12.0 
		tick_font: 'Helvetica' tick_font_size: 10 tick_font_style: 'bold' label_font: 'Helvetica' label_font_size: 32 label_font_style: 'bold' x_label: 'Nice Xlabel' y_label:'Nice Ylabel'
		{
			data "Low Risk" value: nb_susceptible color:#green;
			data "High Risk" value: nb_infected color:#red;
		}
		
	  }*/
	}		
}

