/**
* Name: Constants. 
* Author: Patrick Taillandier
* Description: constants used in the model 
*/


model Constants

global {
	
	string layer <- "layer";
	string walls <- "Walls";
	string windows <- "Windows";	
	string entrance <-"Entrance";
	string offices <- "Offices";
	string meeting_rooms <- "Meeting rooms";
	string library<-"Library";
	string lab<-"Labs";
	string sanitation<-"Sanitation";	
	string coffee <- "Coffee";
	string supermarket <-"Supermarket";	
	string furnitures <- "Furniture";
	string toilets <- "Toilets";
	string elevators <- "Elevators";
	string stairs <- "Stairs";
	string doors <- "Doors";
	string chairs <- "Chair";

	
	string going_home <- "going home";
	string eating_outside <-"eating outside";
	
	string moving_skill <- "moving skill";
	string pedestrian_skill <- "pedestrian skill";
	
	string SFM <- "SFM";
	string simple <- "simple";
	
	 map<string,rgb> color_per_layer <- ["0"::rgb(161,196,90), "Chair"::rgb(50,50,50), "Coffee"::#orange, "Doors"::rgb(225,0,0),"Entrance"::rgb(175,0,0), "Elevators"::rgb(200,200,200), "Facade_Glass"::#darkgray, 
	"Facade_Wall"::rgb(175,175,175), "Furniture"::rgb(50,50,50),"Glass"::rgb(150,150,150), "Labs"::rgb(75,75,75),"Library"::rgb(75,75,75), "Offices"::rgb(75,75,75),"Meeting rooms"::rgb(125,125,125), "Misc"::rgb(161,196,90), 
	"Railing"::rgb(125,124,120), "Supermarket"::#purple,"Stairs"::rgb(225,225,225), "Storage"::rgb(25,25,25), "Toilets"::rgb(225,225,225), "Sanitation"::rgb(225,225,225), "Void"::rgb(0,0,0), "Walls"::rgb(175,175,175),"Windows"::rgb(175,175,175)];
	
	
}
