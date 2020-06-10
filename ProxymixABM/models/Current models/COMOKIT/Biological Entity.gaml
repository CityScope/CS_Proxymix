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
    
	point location <- target.location update: {target.location.x,target.location.y,target.location.z};
	//The latent period, i.e., the time between exposure and being infectious
	float latent_period;
	//The presymptomatic period, used only for soon to be symptomatic entity that are already infectious
	float presymptomatic_period;
	//The infectious period, used as the time between onset and not being infectious for symptomatic entity, or the time after the latent period for asymptomatic ones
	float infectious_period;
	//Time between symptoms onset and hospitalisation of a symptomatic entity
	float time_symptoms_to_hospitalisation <- -1.0;
	//Time between hospitalisation and admission to intensive care unit
	float time_hospitalisation_to_ICU <- -1.0;
	//Time of stay in intensive care unit
	float time_stay_ICU;
	//Clinical status of the entity (no need hospitalisation, needing hospitalisation, needing ICU, dead, recovered)
	string clinical_status <- no_need_hospitalisation;
	//Define if the entity is currently being treated in a hospital (but not ICU)
	bool is_hospitalised <- false;
	//Define if the entity is currently admitted in ICU
	bool is_ICU <- false;
	//Time attribute to represent the time done in ICU
	float time_ICU;
	//Time attribute for the different epidemiological states of the entity
	float tick <- 0.0;
	//Time attribute for the time before death of the entity (i.e. the time allowed between needing ICU, and death due to not having been admitted to ICU
	float time_before_death;
	//Boolean to determine if the agent is infected (i.e. latent, presymptomatic, symptomatic, asymptomatic)
	bool is_infected;
	//Boolean to determine if the agent is infectious (i.e. presymptomatic, symptomatic, asymptomatic)
	bool is_infectious;
	//Boolean to determine if the agent is asymptomatic (i.e. presymptomatic, asymptomatic)
	bool is_asymptomatic;
	//Boolean to determine if the agent is symptomatic
	bool is_symptomatic;
	//Report status of the entity if it has been tested, or not
	string report_status <- not_tested;
	//Number of step of the last test
	int last_test <- 0;
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

	//Number of times negatively tested
	int number_negative_tests <- 0;
	
	
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
	action define_new_case{
		state <- "latent";
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
	reflex infect_others when: is_infectious
	{
		//Computation of the reduction of the transmission when being asymptomatic/presymptomatic and/or wearing mask
		float reduction_factor <- 1.0;
		if(is_asymptomatic)
		{
			reduction_factor <- reduction_factor * factor_contact_rate_asymptomatic;
		}
		
		//Perform human to human transmission
		if allow_transmission_human {
			float proba <- contact_rate*reduction_factor;
			list<BiologicalEntity> others <- BiologicalEntity at_distance infectionDistance;
			others <- others where (each.state = susceptible);
			ask others {
				geometry line <- line([myself,self]);
				if empty(wall overlapping line) {
					if empty(separator_ag overlapping line) {
						proba <- proba * (1 - diminution_infection_rate_separator);
					}
					if (flip(proba)) {
	        			do define_new_case;
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
	
	
	//Reflex to update the time before death when an entity need to be admitted in ICU, but is not in ICU
	reflex update_time_before_death when: (clinical_status = need_ICU) and (is_ICU = false) {
		time_before_death <- time_before_death -1;
		if(time_before_death<=0){
			clinical_status <- dead;
			state <- removed;
		}
	}
	//Reflex used to update the time in ICU of the entity, and change the entity status accordingly
	reflex update_time_in_ICU when: (clinical_status = need_ICU) and (is_ICU = true) {
		time_ICU <- time_ICU -1;
		if(time_ICU<=0){
			//In the case of the entity being treated in ICU, but still dying
			if(world.is_fatal(self.age)){
				clinical_status <- dead;
				state <- removed;
			}else{
				clinical_status <- need_hospitalisation;
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
		tick <- tick+1;
		
		transition to: symptomatic when: (tick>=latent_period) and (self.is_symptomatic) and (presymptomatic_period>=0);
		transition to: presymptomatic when: (tick>=latent_period) and (self.is_symptomatic) and (presymptomatic_period<0);
		transition to: asymptomatic when: (tick>=latent_period) and (self.is_symptomatic=false);
	}
	//State when the entity is presymptomatic
	state presymptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			presymptomatic_period <- abs(presymptomatic_period);
		}
		tick <- tick+1;
		transition to: symptomatic when: (tick>=presymptomatic_period);
	}
	//State when the entity is symptomatic
	state symptomatic {
		enter{
			tick <- 0.0;
			do set_status;
			infectious_period <- world.get_infectious_period_symptomatic(self.age);
			if(world.is_hospitalised(self.age)){
				//Compute the time before hospitalisation knowing the current biological status of the agent
				time_symptoms_to_hospitalisation <- world.get_time_onset_to_hospitalisation(self.age,self.infectious_period);
				if(time_symptoms_to_hospitalisation>infectious_period)
				{
					time_symptoms_to_hospitalisation <- infectious_period;
				}
				//Check if the Individual will need to go to ICU
				if(world.is_ICU(self.age))
				{
					//Compute the time before going to ICU once hospitalised
					time_hospitalisation_to_ICU <- world.get_time_hospitalisation_to_ICU(self.age, self.time_symptoms_to_hospitalisation);
					time_stay_ICU <- world.get_time_ICU(self.age);
					if(time_symptoms_to_hospitalisation+time_hospitalisation_to_ICU>=infectious_period)
					{
						time_symptoms_to_hospitalisation <- infectious_period-time_hospitalisation_to_ICU;
					}
				}
			}	
		}
		tick <- tick+1;
		if(tick>=time_symptoms_to_hospitalisation)and(clinical_status=no_need_hospitalisation)and(time_symptoms_to_hospitalisation>0){
			clinical_status <- need_hospitalisation;
		}
		
		if(tick>=time_hospitalisation_to_ICU+time_symptoms_to_hospitalisation)and(time_hospitalisation_to_ICU>0){
			clinical_status <- need_ICU;
			time_before_death <- time_stay_ICU;
			time_ICU <- time_stay_ICU;
		}
		
		
		transition to: removed when: (tick>=infectious_period){
			if(clinical_status=no_need_hospitalisation){
				clinical_status <- recovered;
			}else{
				//In case no hospital is taking care of the entity
				if(is_hospitalised=false){
					if(clinical_status=need_hospitalisation)and(time_hospitalisation_to_ICU<0){
						clinical_status <- recovered;
					}
				}
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
		tick <- tick+1;
		transition to:removed when: (tick>=infectious_period){
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