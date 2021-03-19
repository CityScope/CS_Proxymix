/**
* Name: generateCSVstochasticty
* Based on the internal skeleton template. 
* Author: admin_ptaillandie
* Tags: 
*/

model generateCSVstochasticty

global {
	string folder_path <- "../CurrentModels/results/stochasticity";
	string result_folder_path <- "results/stochasticity";


	init {
		map<string,list<float>> res_direct;
		map<string,list<float>> res_object;
		map<string,list<float>> res_air;
		loop f over: folder(folder_path) {
			matrix data <- matrix(csv_file(folder_path + "/" +f ,","));
			list<int> index_direct <- [3];
			list<int> index_object <- [4];
			list<int> index_air <- [5];
			loop i from: 0 to: data.rows -1 {
				string id <- string(data[1,i]);
				float val_direct <- 0.0;
				loop j over: index_direct{
					val_direct <- val_direct + float(data[j,i]);
				}
				if not (id in res_direct.keys) {
					res_direct[id] <- [val_direct];
				} else {
					res_direct[id] << val_direct;
				}
				float val_object <- 0.0;
				loop j over: index_object{
					val_object <- val_object + float(data[j,i]);
				}
				if not (id in res_object.keys) {
					res_object[id] <- [val_object];
				} else {
					res_object[id] << val_object;
				}
				
				float val_air <- 0.0;
				loop j over: index_air{
					val_air <- val_air + float(data[j,i]);
				}
				if not (id in res_air.keys) {
					res_air[id] <- [val_air];
				} else {
					res_air[id] << val_air;
				}
				
			}
		}
		int size_ref <- res_direct.values max_of (length(each));
		loop i over: res_direct.keys {
			loop while: length(res_direct[i]) < size_ref {
				res_direct[i] << last(res_direct[i]);
			}
		}
		loop i over: res_object.keys {
			loop while: length(res_object[i]) < size_ref {
				res_object[i] << last(res_object[i]);
			}
		}
		loop i over: res_air.keys {
			loop while: length(res_air[i]) < size_ref {
				res_air[i] << last(res_air[i]);
			}
		}
		
		string h <- "id";
		loop i from: 0 to: size_ref -1{
			h <- h + ",direct_" + i;
		}
		save h to: result_folder_path+"/result_stochasticity_direct.csv" type: text ; 
		loop r over: res_direct.keys {
			string tos <- r;
			if (length(res_direct[r]) = size_ref) {
				loop i over: res_direct[r] {
					tos <- tos + "," + i;
				}
				save tos to: result_folder_path +"/result_stochasticity_direct.csv" type: text rewrite: false; 
			}
			
		}
		
		h <- "id";
		loop i from: 0 to: size_ref -1{
			h <- h + ",object_" + i;
		}
		save h to: result_folder_path+"/result_stochasticity_object.csv" type: text ; 
		loop r over: res_object.keys {
			string tos <- r;
			if (length(res_object[r]) = size_ref) {
				
				loop i over: res_object[r] {
					tos <- tos + "," + i;
				}
				save tos to: result_folder_path+"/result_stochasticity_object.csv" type: text rewrite: false; 
		
			}
		}
		
		h <- "id";
		loop i from: 0 to: size_ref -1{
			h <- h + ",air_" + i;
		}
		save h to: result_folder_path+"/result_stochasticity_air.csv" type: text ; 
		loop r over: res_air.keys {
			string tos <- r;
			if (length(res_air[r]) = size_ref) {
				
				loop i over: res_air[r] {
					tos <- tos + "," + i;
				}
				save tos to: result_folder_path+"/result_stochasticity_air.csv" type: text rewrite: false; 
		
			}
		}
		
		
	
		
		
		h <- "id,direct,object,air";
		save h to: result_folder_path+"/result_stochasticity.csv" type: text ; 
		loop r over: res_object.keys {
			if (length(res_object[r]) = size_ref) {
				string tos <- r + "," + last(res_direct[r])+ "," + last(res_object[r]) +"," + last(res_air[r]) ;
				save tos to: result_folder_path+"/result_stochasticity.csv" type: text rewrite: false; 
			}
			
		}
		
		
	}
}

experiment generateCSVstochasticty type: gui ;