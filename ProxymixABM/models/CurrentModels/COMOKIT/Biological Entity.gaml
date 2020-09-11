/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Abstract species representing the dynamics of infection and clinical 
* states in a "biological" agent. Parent of the Individual species, it is 
* designed to be used for other species of agent that could be infected 
* by the virus
* 
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/

model BiologicalEntity

import "../CityScope_Coronaizer_COMOKIT.gaml"
import "../DailyRoutine.gaml"
import "Functions.gaml"

global {
	
}

//The biological entity is the mother species of the Individual agent, it could be used for other kinds of agent that
// could be infected by the virus
species BiologicalEntity control:fsm mirrors: people{
	
    geometry shape<-square(2.0);
    int nb_people_infected_by_me<-0;
    bool has_been_infected<-false;
    float infected_time;
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	//The latent period, i.e., the time between exposure and being infectious
	float latent_period;
	//The presymptomatic period, used only for soon to be symptomatic entity that are already infectious
	float presymptomatic_period;
	//The infectious period, used as the time between onset and not being infectious for symptomatic entity, or the time after the latent period for asymptomatic ones
	float infectious_period;
	//Time between hospitalisation and admission to intensive care unit
	string clinical_status <- no_need_hospitalisation;
	
	//Time attribute for the different epidemiological states of the entity
	float tick <- 0.0;
	float tick_hours -> {(tick/#hour)};
	
	//Boolean to determine if the agent is infected (i.e. latent, presymptomatic, symptomatic, asymptomatic)
	bool is_infected;
	//Boolean to determine if the agent is infectious (i.e. presymptomatic, symptomatic, asymptomatic)
	bool is_infectious;
	//Boolean to determine if the agent is asymptomatic (i.e. presymptomatic, asymptomatic)
	bool is_asymptomatic;
	//Boolean to determine if the agent is symptomatic
	bool is_symptomatic;
	//Age of the entity 
	int age <- target.age;
	//Factor for the beta and the basic viral release
	float viral_factor;
	//Factor of the contact rate for asymptomatic and presymptomatic individuals (might be age-dependent, hence its presence here)
	float factor_contact_rate_asymptomatic;
	//Basic viral release of the agent (might be age-dependent, hence its presence here)
	float basic_viral_release;
	//Basic contact rate of the agent (might be age-dependent, hence its presence here)
	float contact_rate;
	
	cell current_place update: cell(location) ;
	//#############################################################
	//Intervention related attributes
	//#############################################################
	//Reduction in the transmission when wearing a mask (coughing prevented)
	float factor_contact_rate_wearing_mask;
	
	//Probability of wearing a mask per time step
	float proba_wearing_mask;
	//Bool to represent wearing a mask
	bool is_wearing_mask;
	//Bool to uniquely count positive
	bool is_already_positive <- false;
	
	
	 
	 
	 init {
	 	factor_contact_rate_asymptomatic <- world.get_factor_contact_rate_asymptomatic(age);
		factor_contact_rate_wearing_mask <- world.get_factor_contact_rate_wearing_mask(age);
		basic_viral_release <- world.get_basic_viral_release(age);
		contact_rate <- world.get_contact_rate_human(age);
		proba_wearing_mask <- world.get_proba_wearing_mask(age);
		viral_factor <- world.get_viral_factor(age);
	}
	
	

	//#############################################################
	//Tools
	//#############################################################
	//Return the fact of the Individual being infectious (i.e. asymptomatic, presymptomatic, symptomatic)
	bool define_is_infectious {
		return [asymptomatic,presymptomatic, symptomatic] contains state;
	}
	
	//Return the fact of the Individual not being infectious yet but infected (i.e. latent)
	bool is_latent {
		return state = latent;
	}
	
	//Return the fact of the Individual being infected (i.e. latent, asymptomatic, presymptomatic or symptomatic)
	bool define_is_infected {
		return is_infectious or self.is_latent();
	}
	
	//Return the fact of the Individual not showing any symptoms (i.e. asymptomatic, presymptomatic)
	bool define_is_asymptomatic {
		return [asymptomatic,presymptomatic] contains state;
	}
	
	//Action to set the status of the entity
	action set_status {
		is_infectious <- define_is_infectious();
		is_infected <- define_is_infected();
		is_asymptomatic <- define_is_asymptomatic();
	}
	
	//Action to define a new case, initialising it to latent and computing its latent period, and whether or not it will be symptomatic
	action define_new_case(string state_) {
		state <- state_;
		if(world.is_asymptomatic(self.age)){
			is_symptomatic <- false;
			latent_period <- world.get_incubation_period_asymptomatic(self.age);
		}else{
			is_symptomatic <- true;
			presymptomatic_period <- world.get_serial_interval(self.age);
			latent_period <- presymptomatic_period<0?world.get_incubation_period_symptomatic(self.age)+presymptomatic_period:world.get_incubation_period_symptomatic(self.age);
		}
		
	}
	

	
	//Reflex to trigger transmission to other individuals and environmental contamination
	reflex infect_others when: is_infectious and not target.is_outside
	{
			//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- viral_factor;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		if(is_wearing_mask)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_wearing_mask;
		}
		
		//Performing environmental contamination
		if(current_place!=nil)and(allow_transmission_building)
		{
			ask current_place
			{
				do add_viral_load(reduction_factor*myself.basic_viral_release);
			}
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
			
			list<BiologicalEntity> others <- BiologicalEntity at_distance infectionDistance;
			others <- others where ((each.state = susceptible) and not each.target.is_outside);
			ask others {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					if empty(separator_ag overlapping line) {
						proba <- proba * (1 - diminution_infection_rate_separator);
					}
					if (flip(proba)) {
						
	        			do define_new_case(latent);
		            	ask (cell overlapping self.target){
							nbInfection<-nbInfection+1;
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
	
	//Reflex to update disease cycle
	reflex update_epidemiology when:(state!=removed) {
		if(allow_transmission_building and (not is_infected)and(self.current_place!=nil))
		{
			if(flip(current_place.viral_load*successful_contact_rate_building))
			{
				do define_new_case(latent);
			}
		}
	}
	
	
	//#############################################################
	//States
	//#############################################################
	//State when the entity is susceptible
	state susceptible initial: true{
		enter{
			do set_status;
		}
	}
	//State when the entity is latent
	state latent {
		enter{
			tick <- 0.0;
			do set_status;
		}
		tick <- tick+ step;
		
		transition to: symptomatic when: (tick_hours>=latent_period) and (self.is_symptomatic) and (presymptomatic_period>=0);
		transition to: presymptomatic when: (tick_hours>=latent_period) and (self.is_symptomatic) and (presymptomatic_period<0);
		transition to: asymptomatic when: (tick_hours>=latent_period) and (self.is_symptomatic=false);
	}
	//State when the entity is presymptomatic
	state presymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			presymptomatic_period <- abs(presymptomatic_period);
		}
		tick <- tick+step;
		transition to: symptomatic when: (tick_hours>=presymptomatic_period);
	}
	//State when the entity is symptomatic
	state symptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- world.get_infectious_period_symptomatic(self.age);
		}
		tick <- tick+ step;
		
		
		transition to: removed when: (tick_hours>=infectious_period){
			if(clinical_status=no_need_hospitalisation){
				clinical_status <- recovered;
			}else{
				clinical_status <- recovered;
		
			}
		}
	}
	
	//State when the entity is asymptomatic
	state asymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- world.get_infectious_period_asymptomatic(self.age);
		}
		tick <- tick+ step;
		transition to:removed when: (tick_hours>=infectious_period){
			clinical_status <- recovered;
		}
	}
	//State when the entity is not infectious anymore
	state removed{
		enter{
			do set_status;
		}
	}
	
	aspect base {
		if(showPeople){
			draw circle(is_infected ? 0.4#m : 0.3#m) color: state = latent ? #pink : ((state = symptomatic)or(state=asymptomatic)or(state=presymptomatic)? #red : #green);	
		}
	}
	
}