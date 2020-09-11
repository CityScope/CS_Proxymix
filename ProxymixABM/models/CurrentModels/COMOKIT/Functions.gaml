/******************************************************************
* This file is part of COMOKIT, the GAMA CoVid19 Modeling Kit
* Relase 1.0, May 2020. See http://comokit.org for support and updates
* 
* Declares a set of global functions used throughout COMOKIT (principally 
* by the epidemiological sub-model)
* 
* Author: Damien Philippon
* Tags: covid19,epidemiology
******************************************************************/


@no_experiment

model CoVid19

import "Constants.gaml"
import "Parameters.gaml"
 
global
{
	
	map<int,map<string,list<string>>> map_epidemiological_parameters;
	
	//Action used to initialise epidemiological parameters according to the file and parameters forced by the user
	action init_epidemiological_parameters
	{
		
		//In the case no file was provided, then we simply create the matrix from the default parameters, that are not age dependent
		loop aYear from:0 to: max_age
		{
			map<string, list<string>> tmp_map;
			add list(epidemiological_fixed,string(init_all_ages_successful_contact_rate_human)) to: tmp_map at: epidemiological_successful_contact_rate_human;
			add list(epidemiological_fixed,string(init_all_ages_factor_contact_rate_asymptomatic)) to: tmp_map at: epidemiological_factor_asymptomatic;
			add list(epidemiological_fixed,string(init_all_ages_proportion_asymptomatic)) to: tmp_map at: epidemiological_proportion_asymptomatic;
			add list(epidemiological_fixed,string(init_all_ages_proportion_dead_symptomatic)) to: tmp_map at: epidemiological_proportion_death_symptomatic;
			add list(epidemiological_fixed,string(basic_viral_release)) to: tmp_map at: epidemiological_basic_viral_release;
			add list(epidemiological_fixed,string(init_all_ages_probability_true_positive)) to: tmp_map at: epidemiological_probability_true_positive;
			add list(epidemiological_fixed,string(init_all_ages_probability_true_negative)) to: tmp_map at: epidemiological_probability_true_negative;
			add list(epidemiological_fixed,string(init_all_ages_proportion_wearing_mask)) to: tmp_map at: epidemiological_proportion_wearing_mask;
			add list(epidemiological_fixed,string(init_all_ages_factor_contact_rate_wearing_mask)) to: tmp_map at: epidemiological_factor_wearing_mask;
			add list(init_all_ages_distribution_type_incubation_period_symptomatic,string(init_all_ages_parameter_1_incubation_period_symptomatic),string(init_all_ages_parameter_2_incubation_period_symptomatic)) to: tmp_map at: epidemiological_incubation_period_symptomatic;
			add list(init_all_ages_distribution_type_incubation_period_asymptomatic,string(init_all_ages_parameter_1_incubation_period_asymptomatic),string(init_all_ages_parameter_2_incubation_period_asymptomatic)) to: tmp_map at: epidemiological_incubation_period_asymptomatic;
			add list(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval),string(init_all_ages_parameter_2_serial_interval)) to: tmp_map at: epidemiological_serial_interval;
			add list(epidemiological_fixed,string(init_all_ages_proportion_hospitalisation)) to: tmp_map at: epidemiological_proportion_hospitalisation;
			add list(epidemiological_fixed,string(init_all_ages_proportion_icu)) to: tmp_map at: epidemiological_proportion_icu;
			add list(init_all_ages_distribution_type_infectious_period_symptomatic,string(init_all_ages_parameter_1_infectious_period_symptomatic),string(init_all_ages_parameter_2_infectious_period_symptomatic)) to: tmp_map at: epidemiological_infectious_period_symptomatic;
			add list(init_all_ages_distribution_type_infectious_period_asymptomatic,string(init_all_ages_parameter_1_infectious_period_asymptomatic),string(init_all_ages_parameter_2_infectious_period_asymptomatic)) to: tmp_map at: epidemiological_infectious_period_asymptomatic;
			add list(init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation)) to: tmp_map at: epidemiological_onset_to_hospitalisation;
			add list(init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU)) to: tmp_map at: epidemiological_hospitalisation_to_ICU;
			add list(init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU)) to: tmp_map at: epidemiological_stay_ICU;
			add list(init_all_ages_distribution_viral_individual_factor,string(init_all_ages_parameter_1_viral_individual_factor),string(init_all_ages_parameter_2_viral_individual_factor)) to: tmp_map at: epidemiological_viral_individual_factor;
			add tmp_map to: map_epidemiological_parameters at: aYear;
		}
		
		//If there are any file given as an epidemiological parameters, then we get the parameters value from it
		if(load_epidemiological_parameter_from_file and file_exists(epidemiological_parameters))
		{
			csv_parameters <- csv_file(epidemiological_parameters,true);
			matrix data <- matrix(csv_parameters);
			map<string, list<int>> map_parameters;
			//Loading the different rows number for the parameters in the file
			list possible_parameters <- distinct(data column_at epidemiological_csv_column_name);
			loop i from: 0 to: data.rows-1{
				if(contains(map_parameters.keys, data[epidemiological_csv_column_name,i] ))
				{
					add i to: map_parameters[string(data[epidemiological_csv_column_name,i])];
				}
				else
				{
					list<int> tmp_list;
					add i to: tmp_list;
					add tmp_list to: map_parameters at: string(data[epidemiological_csv_column_name,i]);
				}
			}
			//Initalising the matrix of age dependent parameters and other non-age dependent parameters
			loop aKey over: map_parameters.keys {
				switch aKey{
					//Four parameters are not age dependent : allowing human to human transmission, allowing environmental contamination, 
					//and the parameters for environmental contamination
					match epidemiological_transmission_human{
						allow_transmission_human <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_human;
					}
					match epidemiological_allow_viral_individual_factor{
						allow_viral_individual_factor <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_viral_individual_factor;
					}
					match epidemiological_transmission_building{
						allow_transmission_building <- bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?
							bool(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):allow_transmission_building;
					}
					match epidemiological_basic_viral_decrease{
						basic_viral_decrease <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):basic_viral_decrease;
					}
					match epidemiological_successful_contact_rate_building{
						successful_contact_rate_building <- float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])])!=nil?float(data[epidemiological_csv_column_parameter_one,first(map_parameters[aKey])]):successful_contact_rate_building;
					}
					//all the other parameters could be defined as age dependent, and therefore, stocked in the matrix of parameters
					default{
						loop i from: 0 to:length(map_parameters[aKey])-1
						{
							int index_column <- map_parameters[aKey][i];
							list<string> tmp_list <- list(string(data[epidemiological_csv_column_detail,index_column]),string(data[epidemiological_csv_column_parameter_one,index_column]),string(data[epidemiological_csv_column_parameter_two,index_column]));
							
							//If the parameter was provided only once in the file, then the value will be used for all ages, 
							// else, different values would be loaded according to the age categories given, hence the age dependent matrix
							if(i=length(map_parameters[aKey])-1)
							{
								loop aYear from:int(data[epidemiological_csv_column_age,index_column]) to: max_age
								{
									if(contains(map_epidemiological_parameters.keys,aYear))
									{
										add tmp_list to: map_epidemiological_parameters[aYear] at: string(data[epidemiological_csv_column_name,index_column]);
									}
									else
									{
										map<string, list<string>> tmp_map;
										add tmp_list to: tmp_map at: string(data[epidemiological_csv_column_name,index_column]);
										add tmp_map to: map_epidemiological_parameters at: aYear;
									}
								}
							}
							else
							{
								loop aYear from: int(data[epidemiological_csv_column_age,index_column]) to: int(data[epidemiological_csv_column_age,map_parameters[aKey][i+1]])-1
								{
									if(contains(map_epidemiological_parameters.keys,aYear))
									{
										add tmp_list to: map_epidemiological_parameters[aYear] at: string(data[epidemiological_csv_column_name,index_column]);
									}
									else
									{
										map<string, list<string>> tmp_map;
										add tmp_list to: tmp_map at: string(data[epidemiological_csv_column_name,index_column]);
										add tmp_map to: map_epidemiological_parameters at: aYear;
									}
								}
							}
						}
					}
				}
			}
		}
		
		//In the case the user wanted to load parameters from the file, but change the value of some of them for an experiment, 
		// the force_parameters list should contain the key for the parameter, so that the value given will replace the one already
		// defined in the matrix
		loop aParameter over: force_parameters
		{
			list<string> list_value;
			switch aParameter
			{
				match epidemiological_transmission_human{
					allow_transmission_human <- allow_transmission_human;
				}
				match epidemiological_allow_viral_individual_factor{
					allow_viral_individual_factor <- allow_viral_individual_factor;
				}
				match epidemiological_transmission_building{
					allow_transmission_building <- allow_transmission_building;
				}
				match epidemiological_basic_viral_decrease{
					basic_viral_decrease <- basic_viral_decrease;
				}
				match epidemiological_successful_contact_rate_building{
					successful_contact_rate_building <- successful_contact_rate_building;
				}
				match epidemiological_successful_contact_rate_human{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_successful_contact_rate_human);
				}
				match epidemiological_factor_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_factor_contact_rate_asymptomatic);
				}
				match epidemiological_proportion_asymptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_asymptomatic);
				}
				match epidemiological_proportion_death_symptomatic{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_dead_symptomatic);
				}
				match epidemiological_basic_viral_release{
					list_value <- list<string>(epidemiological_fixed,basic_viral_release);
				}
				match epidemiological_probability_true_positive{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_probability_true_positive);
				}
				match epidemiological_probability_true_negative{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_probability_true_negative);
				}
				match epidemiological_proportion_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_wearing_mask);
				}
				match epidemiological_factor_wearing_mask{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_factor_contact_rate_wearing_mask);
				}
				match epidemiological_incubation_period_symptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_incubation_period_symptomatic,string(init_all_ages_parameter_1_incubation_period_symptomatic),string(init_all_ages_parameter_2_incubation_period_symptomatic));
				}
				match epidemiological_incubation_period_asymptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_incubation_period_asymptomatic,string(init_all_ages_parameter_1_incubation_period_asymptomatic),string(init_all_ages_parameter_2_incubation_period_asymptomatic));
				}
				match epidemiological_serial_interval{
					list_value <- list<string>(init_all_ages_distribution_type_serial_interval,string(init_all_ages_parameter_1_serial_interval));
				}
				match epidemiological_infectious_period_symptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_infectious_period_symptomatic,string(init_all_ages_parameter_1_infectious_period_symptomatic),string(init_all_ages_parameter_2_infectious_period_symptomatic));
				}
				match epidemiological_infectious_period_asymptomatic{
					list_value <- list<string>(init_all_ages_distribution_type_infectious_period_asymptomatic,string(init_all_ages_parameter_1_infectious_period_asymptomatic),string(init_all_ages_parameter_2_infectious_period_asymptomatic));
				}
				match epidemiological_proportion_hospitalisation{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_hospitalisation);
				}
				match epidemiological_onset_to_hospitalisation{
					list_value <- list<string>(init_all_ages_distribution_type_onset_to_hospitalisation,string(init_all_ages_parameter_1_onset_to_hospitalisation),string(init_all_ages_parameter_2_onset_to_hospitalisation));
				}
				match epidemiological_proportion_icu{
					list_value <- list<string>(epidemiological_fixed,init_all_ages_proportion_icu);
				}
				match epidemiological_hospitalisation_to_ICU{
					list_value <- list<string>(init_all_ages_distribution_type_hospitalisation_to_ICU,string(init_all_ages_parameter_1_hospitalisation_to_ICU),string(init_all_ages_parameter_2_hospitalisation_to_ICU));
				}
				match epidemiological_stay_ICU{
					list_value <- list<string>(init_all_ages_distribution_type_stay_ICU,string(init_all_ages_parameter_1_stay_ICU),string(init_all_ages_parameter_2_stay_ICU));
				}
				default{
					
				}
				
			}
			if(list_value !=nil)
			{
				loop aYear from:0 to: max_age
				{
					map_epidemiological_parameters[aYear][aParameter] <- list_value;
				}
			}
		}
	}
	
	//Function to get a value from a random distribution (among Normal, Lognormal, Weibull, Gamma and Uniform)
	float get_rnd_from_distribution(string type, float param_1, float param_2)
	{
		switch type {
			match (epidemiological_lognormal) { return lognormal_rnd(param_1,param_2); }
			match (epidemiological_weibull) { return weibull_rnd(param_1,param_2); }
			match (epidemiological_gamma) { return gamma_rnd(param_1,param_2); }
			match (epidemiological_normal) { return gauss_rnd(param_1,param_2); }
			default {return rnd(param_1,param_2);}
		}
		// return type=epidemiological_lognormal?lognormal_rnd(param_1,param_2):(type=epidemiological_weibull?weibull_rnd(param_1,param_2):(type=epidemiological_gamma?gamma_rnd(param_1,param_2):(type=epidemiological_normal?gauss_rnd(param_1,param_2):rnd(param_1,param_2))));
	}
	
	//Function to get a value from a random distribution (among Normal, Lognormal, Weibull, Gamma and Uniform)
	float get_rnd_from_distribution_with_threshold(string type, float param_1, float param_2, float threshold, bool threshold_is_max)
	{
		switch type {
			match (epidemiological_lognormal) { return lognormal_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_weibull) { return weibull_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_gamma) { return gamma_trunc_rnd(param_1,param_2,threshold,threshold_is_max); }
			match (epidemiological_normal) { return truncated_gauss(param_1,param_2,threshold,threshold_is_max); }
			default {
				if(threshold_is_max)
				{
					return rnd(param_1,threshold);
				}
				else
				{
					return rnd(threshold,param_2);
				}
			}
		}
		// return type=epidemiological_lognormal?lognormal_rnd(param_1,param_2):(type=epidemiological_weibull?weibull_rnd(param_1,param_2):(type=epidemiological_gamma?gamma_rnd(param_1,param_2):(type=epidemiological_normal?gauss_rnd(param_1,param_2):rnd(param_1,param_2))));
	}
	
	//Successful contact rate of an infectious individual, expect the age in the case we want to represent different contact rates for different age categories - MUST BE FIXED (i.e not relying on a distribution)
	float get_contact_rate_human(int age)
	{
		return float(map_epidemiological_parameters[age][epidemiological_successful_contact_rate_human][1])/nb_step_for_one_day;
	}
	
	//Successful contact rate of the building - MUST BE FIXED (i.e not relying on a distribution)
	float get_contact_rate_building
	{
		return successful_contact_rate_building/nb_step_for_one_day;
	}
	
	//Reduction of the successful contact rate for asymptomatic infectious individual of a given age - MUST BE FIXED (i.e not relying on a distribution)
	float get_factor_contact_rate_asymptomatic(int age)
	{
		return float(map_epidemiological_parameters[age][epidemiological_factor_asymptomatic][1]);
	}
	
	//Basic viral release in the environment of an infectious individual of a given age
	float get_basic_viral_release(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_basic_viral_release][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_basic_viral_release][1])/nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_basic_viral_release][0],float(map_epidemiological_parameters[age][epidemiological_basic_viral_release][1]),float(map_epidemiological_parameters[age][epidemiological_basic_viral_release][2]))/nb_step_for_one_day;
		}
	}
	
	
	//Basic viral release in the environment of an infectious individual of a given age MUST BE A DISTRIBUTION
	float get_viral_factor(int age)
	{
		if(allow_viral_individual_factor=false)
		{
			//No difference between individuals
			return 1.0;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_viral_individual_factor][0],float(map_epidemiological_parameters[age][epidemiological_viral_individual_factor][1]),float(map_epidemiological_parameters[age][epidemiological_viral_individual_factor][2]));
		}
	}
	
	//Time between exposure and symptom onset of an individual of a given age
	float get_incubation_period_symptomatic(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_incubation_period_symptomatic][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_incubation_period_symptomatic][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_incubation_period_symptomatic][0],float(map_epidemiological_parameters[age][epidemiological_incubation_period_symptomatic][1]),float(map_epidemiological_parameters[age][epidemiological_incubation_period_symptomatic][2]))*nb_step_for_one_day;
		}
	}
	//Time between exposure and symptom onset of an individual of a given age
	float get_incubation_period_asymptomatic(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_incubation_period_asymptomatic][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_incubation_period_asymptomatic][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_incubation_period_asymptomatic][0],float(map_epidemiological_parameters[age][epidemiological_incubation_period_asymptomatic][1]),float(map_epidemiological_parameters[age][epidemiological_incubation_period_asymptomatic][2]))*nb_step_for_one_day;
		}
	}
	//Time between onset of a primary case of a given age and onset of secondary case 
	float get_serial_interval(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_serial_interval][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_serial_interval][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_serial_interval][0],float(map_epidemiological_parameters[age][epidemiological_serial_interval][1]),float(map_epidemiological_parameters[age][epidemiological_serial_interval][2]))*nb_step_for_one_day;
		}
	}
	
	//Time between onset and recovery for an infectious individual of a given age
	float get_infectious_period_symptomatic(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_infectious_period_symptomatic][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_infectious_period_symptomatic][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_infectious_period_symptomatic][0],float(map_epidemiological_parameters[age][epidemiological_infectious_period_symptomatic][1]),float(map_epidemiological_parameters[age][epidemiological_infectious_period_symptomatic][2]))*nb_step_for_one_day;
		}
	}
	
	//Time between onset and recovery for an infectious individual of a given age
	float get_infectious_period_asymptomatic(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_infectious_period_asymptomatic][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_infectious_period_asymptomatic][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_infectious_period_asymptomatic][0],float(map_epidemiological_parameters[age][epidemiological_infectious_period_asymptomatic][1]),float(map_epidemiological_parameters[age][epidemiological_infectious_period_asymptomatic][2]))*nb_step_for_one_day;
		}
	}
	//Reduction of the successful contact rate of an infectious individual of a given age
	float get_factor_contact_rate_wearing_mask(int age)
	{
	return float(map_epidemiological_parameters[age][epidemiological_factor_wearing_mask][1]);
	}
	
	//Give a boolean to say if an individual of a given age should be asymptomatic - MUST BE FIXED (i.e. not following a distribution)
	bool is_asymptomatic(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_proportion_asymptomatic][1]));
	}
	
	//Give a boolean to say if an infected individual of a given age is positive - MUST BE FIXED (i.e. not following a distribution)
	bool is_true_positive(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_probability_true_positive][1]));
	}
	
	//Give a boolean to say if a non-infected individual of a given age is negative - MUST BE FIXED (i.e. not following a distribution)
	bool is_true_negative(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_probability_true_negative][1]));
	}
	
	//Give a boolean to say if an individual of a given age should be hospitalised - MUST BE FIXED (i.e. not following a distribution)
	bool is_hospitalised(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_proportion_hospitalisation][1]));
	}
	
	//Give the number of steps between onset of symptoms and time for hospitalization
	float get_time_onset_to_hospitalisation(int age, float max_value)
	{
		if(map_epidemiological_parameters[age][epidemiological_onset_to_hospitalisation][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_onset_to_hospitalisation][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution_with_threshold(map_epidemiological_parameters[age][epidemiological_onset_to_hospitalisation][0],float(map_epidemiological_parameters[age][epidemiological_onset_to_hospitalisation][1]),float(map_epidemiological_parameters[age][epidemiological_onset_to_hospitalisation][2]),max_value/nb_step_for_one_day, true)*nb_step_for_one_day;
		}
	}
	
	//Give a boolean to say if an individual of a given age should be in intensive care unit - MUST BE FIXED (i.e. not following a distribution)
	bool is_ICU(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_proportion_icu][1]));
	}
	
	//Give the number of steps between hospitalization and ICU
	float get_time_hospitalisation_to_ICU(int age, float max_value)
	{
		if(map_epidemiological_parameters[age][epidemiological_hospitalisation_to_ICU][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_hospitalisation_to_ICU][1])*nb_step_for_one_day;
		}
		else
		{
			return get_rnd_from_distribution_with_threshold(map_epidemiological_parameters[age][epidemiological_hospitalisation_to_ICU][0],float(map_epidemiological_parameters[age][epidemiological_hospitalisation_to_ICU][1]),float(map_epidemiological_parameters[age][epidemiological_hospitalisation_to_ICU][2]), max_value/nb_step_for_one_day, true)*nb_step_for_one_day;
		}
	}
	
	//Give the number of steps in ICU
	float get_time_ICU(int age)
	{
		if(map_epidemiological_parameters[age][epidemiological_stay_ICU][0]=epidemiological_fixed)
		{
			return float(map_epidemiological_parameters[age][epidemiological_stay_ICU][1])*nb_step_for_one_day;
		}
	else
		{
			return get_rnd_from_distribution(map_epidemiological_parameters[age][epidemiological_stay_ICU][0],float(map_epidemiological_parameters[age][epidemiological_stay_ICU][1]),float(map_epidemiological_parameters[age][epidemiological_stay_ICU][2]))*nb_step_for_one_day;
		}
	}
	//Give a boolean to say if an individual of a given age would die - MUST BE FIXED (i.e. not following a distribution)
	bool is_fatal(int age)
	{
		return flip(float(map_epidemiological_parameters[age][epidemiological_proportion_death_symptomatic][1]));
	}
	
	//Give a boolean to say if an individual of a given age should be wearing a mask - MUST BE FIXED (i.e. not following a distribution)
	float get_proba_wearing_mask(int age)
	{
		return (float(map_epidemiological_parameters[age][epidemiological_proportion_wearing_mask][1]));
	}
	
	
}