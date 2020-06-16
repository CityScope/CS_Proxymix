/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* This is where all the parameters of the model are being declared and, 
* for some, initialised with default values.
* 
* Author: Huynh Quang Nghi, Benoit Gaudou, Damien Philippon, Patrick Taillandier
* Tags: covid19,epidemiology
******************************************************************/

//@no_experiment

model CoVid19

import "Constants.gaml"

global {
	int num_infected_init <- 2; //number of infected individuals at the initialization of the simulation
	int num_recovered_init <- 0; //The number of people that have already been infected in the past
	int max_age <- 100;
	//Epidemiological parameters
	float nb_step_for_one_day <- #day/step; //Used to define the different period used in the model
	
	bool load_epidemiological_parameter_from_file <- true; //Allowing parameters being loaded from a csv file 
	string epidemiological_parameters <- "/Parameters/Epidemiological Parameters.csv"; //File for the parameters
	file csv_parameters <- file_exists(epidemiological_parameters)?csv_file(epidemiological_parameters):nil;
	
	//Dynamics
	bool allow_transmission_human <- true; //Allowing human to human transmission
	bool allow_transmission_building <- true; //Allowing environment contamination and infection
	bool allow_viral_individual_factor <- false; //Allowing individual effects on the beta and viral release
	
	
	//Environmental contamination
	float successful_contact_rate_building <- 2.5 * 1/(14.69973*nb_step_for_one_day);//Contact rate for environment to human transmission derivated from the R0 and the mean infectious period
	float reduction_coeff_all_buildings_inhabitants <- 0.01; //reduction of the contact rate for individuals belonging to different households leaving in the same building
	float reduction_coeff_all_buildings_individuals <- 0.05; //reduction of the contact rate for individuals belonging to different households leaving in the same building
	float basic_viral_release <- 3.0; //Viral load released in the environment by infectious individual
	float basic_viral_decrease <- 0.33; //Value to decrement the viral load in the environment
	
	
	//These parameters are used when no CSV is loaded to build the matrix of parameters per age
	float init_all_ages_successful_contact_rate_human <- 2.5 * 1/(14.69973);//Contact rate for human to human transmission derivated from the R0 and the mean infectious period
	float init_all_ages_factor_contact_rate_asymptomatic <- 0.55; //Factor of the reduction for successful contact rate for  human to human transmission for asymptomatic individual
	float init_all_ages_proportion_asymptomatic <- 0.3; //Proportion of asymptomatic infections
	float init_all_ages_proportion_dead_symptomatic <- 0.01; //Proportion of symptomatic infections dying
	float init_all_ages_probability_true_positive <- 0.89; //Probability of successfully identifying an infected
	float init_all_ages_probability_true_negative <- 0.92; //Probability of successfully identifying a non infected
	float init_all_ages_proportion_wearing_mask <- 0.0; //Proportion of people wearing a mask
	float init_all_ages_factor_contact_rate_wearing_mask <- 0.5; //Factor of reduction for successful contact rate of an infectious individual wearing mask
	string init_all_ages_distribution_type_incubation_period_symptomatic <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	float init_all_ages_parameter_1_incubation_period_symptomatic <- 1.57; //First parameter of the incubation period distribution for symptomatic
	float init_all_ages_parameter_2_incubation_period_symptomatic <- 0.65; //Second parameter of the incubation period distribution for symptomatic
	string init_all_ages_distribution_type_incubation_period_asymptomatic <- "Lognormal"; //Type of distribution of the incubation period; Among normal, lognormal, weibull, gamma
	float init_all_ages_parameter_1_incubation_period_asymptomatic <- 1.57; //First parameter of the incubation period distribution for asymptomatic
	float init_all_ages_parameter_2_incubation_period_asymptomatic <- 0.65; //Second parameter of the incubation period distribution for asymptomatic
	string init_all_ages_distribution_type_serial_interval <- "Normal"; //Type of distribution of the serial interval
	float init_all_ages_parameter_1_serial_interval <- 3.96;//First parameter of the serial interval distribution
	float init_all_ages_parameter_2_serial_interval <- 3.75;//Second parameter of the serial interval distribution
	string init_all_ages_distribution_type_infectious_period_symptomatic <- "Lognormal";//Type of distribution of the time from onset to recovery
	float init_all_ages_parameter_1_infectious_period_symptomatic <- 3.034953;//First parameter of the time from onset to recovery distribution
	float init_all_ages_parameter_2_infectious_period_symptomatic <- 0.34;//Second parameter of the time from onset to recovery distribution
	string init_all_ages_distribution_type_infectious_period_asymptomatic <- "Lognormal";//Type of distribution of the time from onset to recovery
	float init_all_ages_parameter_1_infectious_period_asymptomatic <- 3.034953;//First parameter of the time from onset to recovery distribution
	float init_all_ages_parameter_2_infectious_period_asymptomatic <- 0.34;//Second parameter of the time from onset to recovery distribution
	float init_all_ages_proportion_hospitalisation <- 0.2; //Proportion of symptomatic cases hospitalized
	string init_all_ages_distribution_type_onset_to_hospitalisation <- "Lognormal";//Type of distribution of the time from onset to hospitalization
	float init_all_ages_parameter_1_onset_to_hospitalisation  <- 3.034953;//First parameter of the time from onset to hospitalization distribution
	float init_all_ages_parameter_2_onset_to_hospitalisation  <- 0.34;//Second parameter of the time from onset to hospitalization distribution
	float init_all_ages_proportion_icu <- 0.1; //Proportion of hospitalized cases going through ICU
	string init_all_ages_distribution_type_hospitalisation_to_ICU <- "Lognormal";//Type of distribution of the time from hospitalization to ICU
	float init_all_ages_parameter_1_hospitalisation_to_ICU  <- 3.034953;//First parameter of the time from hospitalization to ICU
	float init_all_ages_parameter_2_hospitalisation_to_ICU  <- 0.34;//Second parameter of the time from hospitalization to ICU
	string init_all_ages_distribution_type_stay_ICU <- "Lognormal";//Type of distribution of the time to stay in ICU
	float init_all_ages_parameter_1_stay_ICU <- 3.034953;//First parameter of the time to stay in ICU
	float init_all_ages_parameter_2_stay_ICU <- 0.34;//Second parameter of the time to stay in ICU
	string init_all_ages_distribution_viral_individual_factor <- "Lognormal"; //Type of distribution of the individual factor for beta and viral release
	float init_all_ages_parameter_1_viral_individual_factor <- -0.125; //First parameter of distribution of the individual factor for beta and viral release
	float init_all_ages_parameter_2_viral_individual_factor <- 0.5; //Second parameter of distribution of the individual factor for beta and viral release
	list<string> force_parameters;

	
}