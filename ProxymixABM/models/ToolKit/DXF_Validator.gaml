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
	init {
		do initiliaze_dxf;
	}
}


experiment ValidatedDXF type: gui
{   
	init
	{   create simulation with: [useCase::"ENSAL"];
		create simulation with: [useCase::"Hotel-Dieu"];
		create simulation with: [useCase::"Factory"];
		create simulation with: [useCase::"Learning_Center"];
		create simulation with: [useCase::"SanSebastian"];
	}
	parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" among: ["Factory", "MediaLab","Hotel-Dieu","ENSAL","Learning_Center","SanSebastian"];
	output
	{	layout #split;
		display map type: opengl background:#black toolbar:false draw_env:false
		{
			species dxf_element;
			graphics 'legend'{
			  draw useCase color: #white at: {-world.shape.width*0.1,-world.shape.height*0.1} perspective: true font:font("Helvetica", 20 , #bold);
			}
		}
	}
}



experiment WorkInProgressDXF type: gui
{   
	init
	{   

        //create simulation with: [useCase::"SanSebastian",validator::true];
	}

	
	parameter 'fileName:' var: useCase category: 'file' <- "MediaLab" ;

	output
	{	layout #split;
		display map type: opengl
		{
			species dxf_element;
		}
	}
}