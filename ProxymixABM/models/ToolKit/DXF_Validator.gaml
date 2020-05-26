/**
* Name: DXF to Agents Model
* Author:  Arnaud Grignard
* Description: Model which shows how to create agents by importing data of a DXF file
* Tags:  dxf, load_file
*/
model DXFAgents

import "DXF_Loader.gaml"
global
{

}


experiment ValidatedDXF type: gui
{   
	init
	{   
        create simulation with: [useCase::"MediaLab"];
		create simulation with: [useCase::"Hotel-Dieu"];
		create simulation with: [useCase::"ENSAL"];
	}
	parameter 'fileName:' var: useCase category: 'file' <- "Factory" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL"];
	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}

experiment WorkInProgressDXF type: gui
{   
	init
	{   

        create simulation with: [useCase::"ENSAL",validator::true];
		create simulation with: [useCase::"ENSAL-1",validator::true];
	}

	
	parameter 'fileName:' var: useCase category: 'file' <- "Learning_Center" among: ["Learning_Center"];

	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}