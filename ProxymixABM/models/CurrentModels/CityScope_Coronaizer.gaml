/***
* Name: CityScope Epidemiology
* Author: Arnaud Grignard
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CityScopeCoronaizer

import "DailyRoutine.gaml"


global{
//	bool dummy_very_weird_variable;
//	bool fixed_infected_people_localization <- true;
//	bool large_droplet_infection <- true;
	bool fomite_infection <- true;
	bool aerosol_infection <- true;
	float maskRatio <- 0.0;
	

	//MASK
	float droplet_mask_emission_efficiency <- 0.70; 
	float droplet_reception_mask_efficiency <- 0.70; 
	float fomite_mask_emmision_efficiency<-0.70;
	float fomite_mask_reception_efficiency<-0.70;
	float aerosol_mask_emmision_efficiency<-0.70;
	float aerosol_mask_reception_efficiency<-0.70;
	
    //FOMITE
	float hand_to_mouth<-0.2; //Ratio of fomite transmiteed from hands to mouth;
	float proportion_of_fomite_viral_load_transmission_per_second<-0.01;// proportion of fomite viral load taken when touching a fomite.
	list<fomitableSurface> fomitableSurfaces; 
		
	//DROPLET
	float droplet_viral_load_per_time_unit<-1.0; //increasement of the infection risk per second
	float viral_load_to_fomite_infection_per_time_unit<-0.2; //increasement of the viral load of cells per second 
	float breathing_volume <- 8*10^-3*#m^3/#mn;// volume of air inspired/expired per minute
	float virus_concentration_in_breath <- 10000.0; //virus concentration in expired air
	float DEFAULT_HEIGHT <- 2.0*#m^3; //default height for rooms
	float largeDropletRange <- 1#m;
	

	//SANITATION
	float diminution_cumulated_viral_load_sanitation <- 0.1;
	float hand_cleaning_time_effect <- 1#h;
	
	//VENTILATION
	float basic_viral_decrease_room <- 0.0001; //decreasement of the viral load of cells per second 
	float ventilated_viral_decrease_room <- 0.001; //decreasement of the viral load of cells per second 
	
	//SEPARATOR
	float separator_efficiency <- 0.9;

   	//INIT
   	int initial_nb_infected<-10;
    
   	
   	//OUTPUT
   	float Low_Risk_of_Infection_threshold<-30.0;
   	float Medium_Risk_of_Infection_threshold<-60.0;
	
	//VISUALIZATION
	bool draw_fomite_viral_load<-false;
	bool draw_viral_load_per_room<-true;
	bool showDropletRange<-false;
	bool showPeople<-true;

	string type_explo <- "normal" among: ["normal", "stochasticity"];
	string path_ <-  "results/" +type_explo+"/results_" + type_explo+ "_" + int(self)+".csv";
	

	init{	
     queueing <-false;
     peopleSize  <-0.3#m;
	 step_arrival <- 1#s;
	 arrival_time_interval <- 3 #mn;
	 filePathName <-"../results/output/"+useCase+".csv";
	}
	
	bool savetoCSV<-true;
	string filePathName;
		
	reflex initCovid when:cycle = 1{
	//	if fixed_infected_people_localization {
		if true {
			int nb_i;
			list<ViralPeople> concerned_people <- ViralPeople where (each.target.working_desk != nil);
			map<room,list<ViralPeople>> pp_per_room <- concerned_people group_by each.target.working_place;
			list<room> r_ord <- pp_per_room.keys  sort_by each.name;
			int direction_i <- 0;
			float sum_area <- r_ord sum_of each.shape.area;
			loop r over: r_ord {
				list<ViralPeople> pps <- pp_per_room[r];
				int nb_infected_room <- round(initial_nb_infected * r.shape.area/ sum_area);
				nb_infected_room <- min([nb_infected_room, initial_nb_infected - nb_i, length(pps)]);
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
				list<room> ror <- pp_per_room.keys sort_by each.name;
				
				int direction <- 0;
				
				loop while: nb_i < initial_nb_infected {
					loop r over: ror {
						if (nb_i = initial_nb_infected) {
							break;
						} else {
							list<ViralPeople> pps <- pp_per_room[r];
							if (not empty(pps))  {
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
		fomitableSurfaces<-agents of_generic_species fomitableSurface;

		
	}

	
	reflex save_result when: batch_mode and every(10 #cycle){
		
		float direct <- sum(ViralPeople collect each.cumulated_viral_load[0]);
		float object <-  sum(ViralPeople collect each.cumulated_viral_load[1]) ;
		float air <- sum(ViralPeople collect each.cumulated_viral_load[2]);
		
		string 	results <- ""+ 
		int(self)+"," + world.seed+","+time+","+ direct + "," + object + "," + air;
		
		
		save results to:path_ type:text rewrite: false;
		
	}

			
	reflex save_model_output when: time=timeSpent and savetoCSV {
		write "save to csv at time:" + time + "Sim:" + int(self);
		save [time,title,sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople),sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople),sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople),float(sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople)) with_precision 2
		] to: filePathName type:"csv" rewrite: false;

	}
}


species ViralBuildingEntrance mirrors: building_entrance parent: ViralRoom ;

species ViralCommonArea mirrors: common_area parent: ViralRoom ;

species ViralRoom mirrors: room {
	list<rgb> room_color_map<-[rgb(109, 112, 0),rgb(175, 190, 49),rgb(211, 186, 25),rgb(247, 181, 0),rgb(246, 143, 18),rgb(245, 105, 36),rgb(244, 67, 54)];	
	float viral_load;
	init {
		shape <- target.shape;
	}
	
	reflex update_viral_load when: aerosol_infection{
		if (target.isVentilated) {
			viral_load <- viral_load * (1-ventilated_viral_decrease_room)^ step;
		} else {
			viral_load <- viral_load * (1-basic_viral_decrease_room) ^ step;
		}
	}
	//Action to add viral load to the room
	action add_viral_load(float value){
		viral_load <- viral_load + value;
	}
	
	aspect default {
		if(draw_viral_load_per_room){
		  if (aerosol_infection) {
		  	//draw shape color: room_color_map[rnd(length(color_map))];//blend(color_map["red"], color_map["green"], viral_load*1000);//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);		
		  	//draw shape color: room_color_map[int(min (1,viral_load/0.1)*(length(color_map)-1))];//blend(color_map["red"], color_map["green"], viral_load*1000);//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);	
			draw shape color: blend(color_map["red"], color_map["green"], min(1,viral_load*2000/(shape.area*DEFAULT_HEIGHT)));//;blend(rgb(169,0,0), rgb(125,239,66), viral_load*1000); //blend(#red, #green, viral_load*1000);
			}		
	 	}
	}
}



species ViralPeople  mirrors:people{
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	list<float> cumulated_viral_load<-[0.0,0.0,0.0];
	int infectionRiskStatus;
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


	reflex virus_propagation when: not target.not_yet_active and not target.end_of_day and is_infected and not target.is_outside and not target.using_sanitation {
	//	if (large_droplet_infection) {
		if (true) {

		//	ask (ViralPeople at_distance largeDropletRange) where (not each.target.end_of_day and not target.not_yet_active and not each.is_infected and not each.target.using_sanitation and not each.target.is_outside) {
			ask ViralPeople where ((each.location.x-self.location.x)^2+(each.location.y-self.location.y)^2<largeDropletRange^2 and not each.target.end_of_day and not target.not_yet_active and not each.is_infected and not each.target.using_sanitation and not each.target.is_outside) {
	        geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					float transmited_droplet_viral_load <- droplet_viral_load_per_time_unit * step;
					if empty(separator_ag overlapping line) {
						transmited_droplet_viral_load <- transmited_droplet_viral_load * (1 - separator_efficiency);
					}
					if myself.has_mask {
						transmited_droplet_viral_load <- transmited_droplet_viral_load * (1 - droplet_mask_emission_efficiency);
					}
					if self.has_mask{
						transmited_droplet_viral_load <- transmited_droplet_viral_load * (1 - droplet_reception_mask_efficiency);
					}
					cumulated_viral_load[0] <- cumulated_viral_load[0] + transmited_droplet_viral_load;
				} 
			}
		}
		if (fomite_infection) and (time_since_last_hand_cleaning < hand_cleaning_time_effect){
			list<fomitableSurface> fS <- (fomitableSurfaces) overlapping self;
			if (fS != nil) {
				ask (fS){
					do add_viral_load((myself.has_mask ? (1-fomite_mask_emmision_efficiency) : 1 )* viral_load_to_fomite_infection_per_time_unit * step);
				}
			}
		}
		if (aerosol_infection) {
			ViralRoom my_room <- first(ViralRoom overlapping location);
			if (my_room != nil) {ask my_room{do add_viral_load((myself.has_mask ? (1-aerosol_mask_emmision_efficiency) :1) * virus_concentration_in_breath*breathing_volume * step);}}		
			ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
			if (my_rca != nil) {ask my_rca{do add_viral_load((myself.has_mask ? (1-aerosol_mask_emmision_efficiency) :1 ) * virus_concentration_in_breath*breathing_volume * step);}}	
		}
	}
	
	reflex using_sanitation when: not target.not_yet_active and not target.end_of_day  and target.using_sanitation {
		cumulated_viral_load[1] <- cumulated_viral_load[1] * (1- diminution_cumulated_viral_load_sanitation)  ^ step;
		time_since_last_hand_cleaning <- 0.0;
	}
	reflex infection_by_fomite when:not target.not_yet_active and not target.end_of_day and  fomite_infection and not is_infected and not target.is_outside and not target.using_sanitation {
		list<fomitableSurface> fS <- (fomitableSurfaces) overlapping self;
		ask fS{
			float transmitted_viral_load <- self.viral_load* (1-(1-proportion_of_fomite_viral_load_transmission_per_second)^step);
			myself.cumulated_viral_load[1] <- myself.cumulated_viral_load[1] + hand_to_mouth *(myself.has_mask? (1-fomite_mask_reception_efficiency) : 1) * transmitted_viral_load;
			do remove_viral_load(transmitted_viral_load);	
		}
		
		
	}
	reflex infection_by_aerosol when: not target.not_yet_active and not target.end_of_day and aerosol_infection and not is_infected and not target.is_outside and not target.using_sanitation {
		ViralRoom my_room <- first(ViralRoom overlapping location);
		if (my_room != nil) {
			float transmitted_viral_load <-  (self.has_mask ? (1-aerosol_mask_reception_efficiency) : 1 ) * (1-(1-breathing_volume/(my_room.shape.area*DEFAULT_HEIGHT))^step) * my_room.viral_load;
			cumulated_viral_load[2] <- cumulated_viral_load[2] + transmitted_viral_load;
			ask my_room{
				do add_viral_load(-transmitted_viral_load);
			}
		}
		ViralCommonArea my_rca <- first(ViralCommonArea overlapping location);
		if (my_rca != nil) {
			float transmitted_viral_load <-  (self.has_mask ? (1-aerosol_mask_reception_efficiency) : 1 ) * (1-(1-breathing_volume/(my_rca.shape.area*DEFAULT_HEIGHT))^step) * my_rca.viral_load;
			cumulated_viral_load[2] <- cumulated_viral_load[2] + transmitted_viral_load;
			ask my_rca{
				do add_viral_load(-transmitted_viral_load);
			}
		}
	}
	
	
	reflex infectionRiskStatus{		
		if(sum(cumulated_viral_load) < Low_Risk_of_Infection_threshold){
			infectionRiskStatus<-0;
		}
		if(sum(cumulated_viral_load) >= Low_Risk_of_Infection_threshold and sum(cumulated_viral_load) < Medium_Risk_of_Infection_threshold){
			infectionRiskStatus<-1;
		}
		if(sum(cumulated_viral_load) >= Medium_Risk_of_Infection_threshold){
			infectionRiskStatus<-2;
		}
	}
			
	aspect base {
		if not target.end_of_day and not target.not_yet_active{
			if(showPeople) and not target.is_outside{
			  //GRADIENT	
			//  draw circle(peopleSize) color:(is_infected) ? color_map["blue"] : blend(color_map["red"], color_map["green"], sum(cumulated_viral_load)/100.0);	
			  //DISCRET	
			  draw circle(peopleSize) color:(is_infected) ? #blue : ((infectionRiskStatus = 0) ? #green : ((infectionRiskStatus = 1) ? #orange : #red));			
				if (has_mask){
					draw square(peopleSize*0.5) color:#white border:rgb(70,130,180)-100;	
				}
			if(showDropletRange){
			 draw circle(largeDropletRange) color:#white empty:true;	
			} 
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
}

experiment Coronaizer type:gui autorun:false{

	//See issue #180
	/*action _init_ {
		title <- "Reference";
		useCase <- "MediaLab"; 
		maskRatio <-0.0;
		density_scenario <- "data";
		distance_people <- 2.0#m;
		ventilationType <- "Natural";
		timeSpent <- 2.0 #h;
		agenda_scenario  <-"simple";
		
	    initial_nb_infected <-10;
		queueing  <-false;
		peopleSize  <-0.3#m;
		step_arrival <- 1#s;
		arrival_time_interval <- 3 #mn;
	}*/
	parameter 'title:' var: title category: 'Initialization' <- "Reference";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "UDG/CUCS/Level 2" among: ["UDG/CUCS/Campus","UDG/CUSUR","UDG/CUCEA","UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	parameter "Agenda Scenario:" category: 'Initialization' var: agenda_scenario  <-"simple";
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 2.0 #h;
	

	
	parameter "Draw Infection by Touching Grid:" category: "Visualization" var:draw_fomite_viral_load;
	parameter "Draw Viral Load:" category: "Visualization" var:draw_viral_load_per_room<-true;
	parameter "Show People:" category: "Visualization" var:showPeople;
    parameter "Social Distance Graph:" category: "Visualization" var:drawSocialDistanceGraph ;
	parameter "Draw Flow Grid:" category: "Visualization" var:draw_flow_grid;
	parameter "Draw Proximity Grid:" category: "Visualization" var:draw_proximity_grid;
	parameter "Draw Pedestrian Path:" category: "Visualization" var:display_pedestrian_path;
	parameter "Show available desk:" category: "Visualization" var:showAvailableDesk <-false;
	parameter "Show bottlenecks:" category: "Visualization" var:show_dynamic_bottleneck <-false;
	parameter "Bottlenecks lifespan:" category: "Visualization" var:bottleneck_livespan min:0 max:100 <-10;
	parameter "Show droplets:" category: "Visualization" var:show_droplet <-false;
	parameter "Droplets lifespan:" category: "Visualization" var:droplet_livespan min:0 max:100 <-10;
	parameter "Droplets distance:" category: "Visualization" var:droplet_distance min:0.0 max:10.0 <-2.0;
		
	output{
	  layout #split;
	  display Simulation type:opengl  background:#black draw_env:false synchronized:false autosave:false toolbar:false	{
	   	species room  refresh: false;
		species room aspect: available_places_info refresh: true position:{0,0,0.001};
		species ViralRoom transparency:0.75 position:{0,0,0.001};
		species ViralCommonArea transparency:0.85 position:{0,0,0.001};
		species building_entrance refresh: true;
		species room_entrance aspect:default position:{0,0,0.001};
		species place_in_room aspect:default position:{0,0,0.001};
		species common_area refresh: true;
		species wall refresh: false;
		//species room_entrance;
		species pedestrian_path position:{0.0,0.0,0.01};
		species separator_ag refresh: false;
		agents "flowCell" value:draw_flow_grid ? flowCell : [] transparency:0.5 position:{0.0,0.0,0.01};
		agents "proximityCell" value:draw_proximity_grid ? proximityCell : [] position:{0.0,0.0,0.01};
		species bottleneck transparency: 0.5;
		species droplet aspect:base; 
		species fomitableSurface aspect:default;
	    species ViralPeople aspect:base position:{0,0,0.002};
	    
	
		graphics 'title'{
		  point titlePos;
		  titlePos<-{-world.shape.width*0.5,0};
	 
		  draw "SCENARIO" color: #white at: {titlePos.x,titlePos.y,0.01} perspective: true font:font("Helvetica", 20 , #bold);
		  draw string(title) color: #white at: {titlePos.x,titlePos.y+50#px,0.01} perspective: true font:font("Helvetica", 40 , #plain);
		}
		graphics 'site'{
			  point sitlegendPos;
			  sitlegendPos<-{-world.shape.width*0.5,world.shape.height*0.2};
			  int fontSize<-20;
			  draw string("SITE") color: #white at: {sitlegendPos.x,sitlegendPos.y,0.01} perspective: true font:font("Helvetica", fontSize*1.5 , #plain);
		      draw string(useCase) color: #white at: {sitlegendPos.x,sitlegendPos.y+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 
		      
		      draw string("Floor area ") color: #white at: {sitlegendPos.x,sitlegendPos.y+2*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain); 
		      draw string("" + with_precision(totalArea,2) + "m2") color: #white at: {sitlegendPos.x,sitlegendPos.y+2*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 		      
		}	
		 graphics "intervention"{
		 	point simLegendPos;
		 	simLegendPos<-{-world.shape.width*0.5,world.shape.height*0.6};	
	  		int fontSize<-20;
	  		draw "INTERVENTION" color:#white at:{simLegendPos.x,simLegendPos.y,0.01} perspective: true font:font("Helvetica", fontSize*1.5 , #plain);
	  		
	  		draw string("Physical distance") color: #white at: {simLegendPos.x,simLegendPos.y+2*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
	  		draw string(" " +  (density_scenario="data" ? "none" : with_precision(distance_people,2))) color: #white at: {simLegendPos.x,simLegendPos.y+2*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  		
	  		draw "Masks" color: #white at: {simLegendPos.x,simLegendPos.y+4*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain); 
	  		draw "" + maskRatio*100 + "%" color: #white at: {simLegendPos.x,simLegendPos.y+4*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold); 
	  		
	  		draw "Ventilation type "color:#white at:{simLegendPos.x,simLegendPos.y+6*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
	  		draw "" + ventilationType color:#white at:{simLegendPos.x,simLegendPos.y+6*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  		
	  		draw "Time spent in classrooms"color:#white at:{simLegendPos.x,simLegendPos.y+8*fontSize*1.5#px,0.01} perspective: true font:font("Helvetica", fontSize , #plain);
			draw "" + timeSpent/#hour + "hr" color:#white at:{simLegendPos.x,simLegendPos.y+8*fontSize*1.5#px+fontSize#px,0.01} perspective: true font:font("Helvetica", fontSize , #bold);
	  	  	
	  	}
	  	
		graphics "time" {
		  point timeLegendPos;
		  timeLegendPos<-{world.shape.width*1.1,world.shape.height*0.1};
	      draw "TIME" color: #white font: font("Helvetica", 20, #plain) at:{timeLegendPos.x,timeLegendPos.y,0.01};
	      draw string(current_date, "HH:mm:ss") color: #white font: font("Helvetica", 30, #bold) at:{timeLegendPos.x,timeLegendPos.y+30#px,0.01};
	      //draw string("step: "+ step) color: #white font: font("Helvetica", 20, #bold) at:{timeLegendPos.x,timeLegendPos.y+40#px,0.01};
	    		
	  	}
	  	graphics "Population"{
	  		point infectiousLegendPos;
	  		infectiousLegendPos<-{world.shape.width*1.1,world.shape.height*0.25};	
	  		draw "POPULATION"color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y,0.01}  perspective: true font:font("Helvetica", 30 , #plain);
	  		draw "" + length(people) color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y+30#px,0.01}  perspective: true font:font("Helvetica", 30 , #bold); 
	  		draw "VIRAL LOAD"color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y+60#px,0.01}  perspective: true font:font("Helvetica", 30 , #plain);
	  		draw "" + int(sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople)) color: #white at: {infectiousLegendPos.x,infectiousLegendPos.y+90#px,0.01}  perspective: true font:font("Helvetica", 30 , #bold); 
	  		
	  		 
	  	}
	  	
	  	
	  	graphics "Projection"{
	  		float bar_fill;
	  		point infectiousLegendPos;
	  		infectiousLegendPos<-{world.shape.width*1.1,world.shape.height*0.5};	
	  		point bar_size <- {300#px,10#px};
	  		float x_offset <- 300#px;
	  		float y_offset <- 50#px;
	  		map<string,int> infection_data <- ["Initial infected"::initial_nb_infected, 
	  										   "Low risk"::(length (ViralPeople where (each.infectionRiskStatus = 0))- initial_nb_infected),
	  										   "Medium risk"::(length (ViralPeople where (each.infectionRiskStatus = 1))),
	  										   "High risk"::(length (ViralPeople where (each.infectionRiskStatus = 2)))
	  					];
	  		list<string> risk_colors <- ["blue", "green","orange","red"];
	  		//draw "SIMULATION PROJECTION" color:#white at:{infectiousLegendPos.x,infectiousLegendPos.y-20#px,0.01} perspective: true font:font("Helvetica", 50 , #bold);
			geometry g <- (rectangle(bar_size.x-bar_size.y,bar_size.y) at_location {0,0,0})+(circle(bar_size.y/2) at_location {bar_size.x/2-bar_size.y/2,0})+(circle(bar_size.y/2) at_location {-bar_size.x/2+bar_size.y/2,0});	
			loop i from:0 to: length(infection_data)-1{
				draw infection_data.keys[i] anchor: #left_center color: color_map[risk_colors[i]] at: {infectiousLegendPos.x,infectiousLegendPos.y+i*y_offset,0.01} perspective: true font:font("Helvetica", 20 , #plain); 
	  			draw string(infection_data.values[i])  anchor: #left_center color: color_map[risk_colors[i]] at: {infectiousLegendPos.x,infectiousLegendPos.y+i*y_offset+y_offset/2,0.01} perspective: true font:font("Helvetica", 20 , #bold); 
	  			//draw g color: color_map[risk_colors[i]]-140 at: {infectiousLegendPos.x+x_offset,infectiousLegendPos.y+i*y_offset,0.01};
	  			bar_fill <- length(ViralPeople) = 0 ?0:(infection_data.values[i] / length(ViralPeople)*bar_size.x);
	  			geometry g2 <- (g at_location {0,0,0}) inter (g at_location {-bar_size.x+bar_fill,0,0}) ;
	  			draw g2 color: color_map[risk_colors[i]] at: {infectiousLegendPos.x+x_offset-bar_size.x/2+bar_fill/2,infectiousLegendPos.y+i*y_offset,0.015};
			}
	  	}
	  	
	  	/*graphics "scale"{
	  		float base_scale<-5#m;
	  		if(episode=1){
	  		  base_scale<-3#m;	
	  		}
	  		if(episode=2){
	  		  base_scale<-1#m;	
	  		}
	  		if(episode=3){
	  		  base_scale<-1.5#m;	
	  		}
	  		if(episode=5){
	  			base_scale<-25#m;
	  		}
	  		point scalePos;
	  		scalePos<-{world.shape.width*1.1,world.shape.height};
	  		 
	  		draw "SCALE"color: #white at: {scalePos.x,scalePos.y-30#px,0.01}  perspective: true font:font("Helvetica", 20 , #plain);
	  		
	  		float rectangle_width <- base_scale/6;
	  		list<float> scale_markers <- [0, 1*base_scale, 2*base_scale, 3*base_scale, 5*base_scale];
	  		int side <- 1;
	  		loop i from: 0 to: length(scale_markers)-2{
	  			draw rectangle({scalePos.x+scale_markers[i],scalePos.y},{scalePos.x+scale_markers[i+1],scalePos.y-side*rectangle_width})  color:#white;
	 	 		draw string(int(scale_markers[i])) anchor: i=0? #bottom_left: #bottom_center color: #white font: font("Helvetica", 15, #bold) at:{scalePos.x+scale_markers[i],scalePos.y+rectangle_width+16#px,0.01};
				side <- - side;
	  		}	  		
	  		draw string(int(last(scale_markers)))+ "m" anchor: #bottom_right color: #white font: font("Helvetica", 15, #bold) at:{scalePos.x+last(scale_markers),scalePos.y+rectangle_width+16#px,0.01};
	  	} */
	  	
		graphics "social_graph" {
			if (social_distance_graph != nil and drawSocialDistanceGraph = true) {
				loop eg over: social_distance_graph.edges {
					geometry edge_geom <- geometry(eg);
					draw curve(edge_geom.points[0],edge_geom.points[1], 0.5, 200, 90) color:#gray;
			}
		  }
		}
	  }
	  
	  display "Infection Risk" type: java2D background:#black toolbar:false
	  {
		
		
		chart "Cumulative Infection Risk: "+ title  type: series color:#white background:#black y_range:{0,200}
		{
			data "DROPLET" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople) color:#mistyrose style: "area";
			data "FOMITE" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople) color: #pink style: "area";
			data "AEROSOL" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople) color: #hotpink style: "area";
		}
		graphics "Viral Load" {
			draw "VIRAL LOAD: " + float(sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople)) with_precision 2 
			color: #white at: {world.shape.width/4,30#px,0.01}  perspective: true font:font("Helvetica", 20 , #plain);
		}
	  }	  
	}	
}

experiment CoronaizerHeadless type:gui autorun:false{

	parameter 'title:' var: title category: 'Initialization' <- "Reference";
	parameter 'fileName:' var: useCase category: 'Initialization' <- "MediaLab" among: ["UDG/CUCS/Campus","UDG/CUSUR","UDG/CUCEA","UDG/CUAAD","UDG/CUT/campus","UDG/CUT/lab","UDG/CUT/room104","UDG/CUCS/Level 2","UDG/CUCS/Ground","UDG/CUCS_Campus","UDG/CUCS/Level 1","Factory", "MediaLab","CityScience","Learning_Center","ENSAL","SanSebastian"];
	parameter "Agenda Scenario:" category: 'Initialization' var: agenda_scenario  <-"simple";
	parameter "Mask Ratio:" category: "Policy" var: maskRatio min: 0.0 max: 1.0 step:0.1 <-0.0;
	parameter "Density Scenario" var: density_scenario category:'Policy'  <- "data" among: ["data", "distance", "num_people_building", "num_people_room"];
	parameter 'distance people:' var: distance_people category:'Policy' min:0.0 max:5.0#m <- 2.0#m;
	parameter 'ventilationType:' var: ventilationType category: 'Initialization' <- "Natural";
	parameter 'timeSpent:' var: timeSpent category: 'Initialization' <- 2.0 #h;
	

	parameter "Draw Infection by Touching Grid:" category: "Visualization" var:draw_fomite_viral_load;
	parameter "Draw Viral Load:" category: "Visualization" var:draw_viral_load_per_room<-true;
	parameter "Show People:" category: "Visualization" var:showPeople;
    parameter "Social Distance Graph:" category: "Visualization" var:drawSocialDistanceGraph ;
	parameter "Draw Flow Grid:" category: "Visualization" var:draw_flow_grid;
	parameter "Draw Proximity Grid:" category: "Visualization" var:draw_proximity_grid;
	parameter "Draw Pedestrian Path:" category: "Visualization" var:display_pedestrian_path;
	parameter "Show available desk:" category: "Visualization" var:showAvailableDesk <-false;
	parameter "Show bottlenecks:" category: "Visualization" var:show_dynamic_bottleneck <-false;
	parameter "Bottlenecks lifespan:" category: "Visualization" var:bottleneck_livespan min:0 max:100 <-10;
	parameter "Show droplets:" category: "Visualization" var:show_droplet <-false;
	parameter "Droplets lifespan:" category: "Visualization" var:droplet_livespan min:0 max:100 <-10;
	parameter "Droplets distance:" category: "Visualization" var:droplet_distance min:0.0 max:10.0 <-2.0;
		
	output{
		layout #split;	
	  display "Infection Risk" type: java2D background:#white toolbar:false
	  {
		
		
		chart "Cumulative Infection Risk: "+ title  type: series color:#white background:#black y_range:{0,200}
		{
			data "DROPLET" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople) color:#mistyrose style: "area";
			data "FOMITE" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople) color: #pink style: "area";
			data "AEROSOL" value: sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople) color: #hotpink style: "area";
		}
		graphics "Viral Load" {
			draw "VIRAL LOAD: " + float(sum(ViralPeople collect each.cumulated_viral_load[0])/length(ViralPeople)+ sum(ViralPeople collect each.cumulated_viral_load[1])/length(ViralPeople)+sum(ViralPeople collect each.cumulated_viral_load[2])/length(ViralPeople)) with_precision 2 
			color: #white at: {world.shape.width/4,30#px,0.01}  perspective: true font:font("Helvetica", 20 , #plain);
		}
	  }	  
	}	
}



