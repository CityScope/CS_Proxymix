import pandas as pd
import networkx as nx
import json
import os
import infomap
from seaborn import color_palette,palplot
from main import *

def filterProjects(projects,start_year=2014):
    '''
    Filter projects if needed (by date, for example)
    '''
    drop_list = ['scratch-in-practice','ml-learning-fellows-program','learning-creative-learning'] 
    projects = projects[~projects['slug'].isin(drop_list)]
    projects = projects[~projects['start_on'].isnull()]
    projects = projects[projects['start_on'].str.split('-').apply(lambda x: x[0]).astype(int)>=start_year]
    return projects

def generate_palette(df,col,show_palette=False):
	'''
	Assigns a unique color to each category of the given column

	Parameters
	----------
	df : pandas.DataFrame
		Table with column to assign colors to.
	col : str
		Column to assign colors to.
	show_palette : boolean (False)
		If True, it will display the generated palette.

	Returns
	-------
	df : pandas.DataFrame
		Copy of the given DataFrame with an extra column with colors in hex format.
	'''
	palette = color_palette("hls", len(set(df[col])))
	if show_palette:
		palplot(palette)
	palette = pd.DataFrame(zip(set(df[col]),palette.as_hex()),columns = [col,col+'_COLOR'])
	df = pd.merge(df,palette)
	return df

def controlGroupAffiliation(people,userCol = 'USERNAME',groupCol ='ML_GROUP',group_path = '../Data'):
	'''
	Uses the file mlgroups.csv to control the group names.

	Parameters
	----------
	people : pandas.DataFrame
		Table with username and group as columns.
	userCol : str ('USERNAME')
		Name of column with username.
	groupCol : str ('ML_GROUP')
		Name of column with group name

	Returns
	-------
	groupAfilliation : pandas.DataFrame
		Table with username, groupname and is_affiliate columns. It has one group per username. 
	'''
	simplifyGroups = dict(pd.read_csv(os.path.join(group_path,'mlgroups.csv')).values)
	groupAfilliation = []
	for u,g in people[[userCol,groupCol]].dropna().values:
		is_affiliate = False
		if ';' in g:
			multiGroups = [simplifyGroups[gg] for gg in g.split(';')]
			is_affiliate = ('Affiliates' in multiGroups)
			mainGroups  = [gg for gg in multiGroups if gg not in set(['Initiatives','Affiliates','Other'])]
			if len(set(mainGroups))==1:
				groupAfilliation.append((u,mainGroups[0],is_affiliate))
			else:
				groupAfilliation.append((u,multiGroups[0],is_affiliate))
		else:
			is_affiliate = (simplifyGroups[g] == 'Affiliates')
			groupAfilliation.append((u,simplifyGroups[g],is_affiliate))
	groupAfilliation = pd.DataFrame(groupAfilliation,columns=[userCol,groupCol,'is_affiliate'])
	return groupAfilliation

def filterNodes(net,remove_set):
	'''
	Removes nodes from a given set.
	'''
	remove_set = set(remove_set)
	net = net[(~net['username_s'].isin(remove_set))&(~net['username_t'].isin(remove_set))]
	return net

def runInfomap(wnet,sourceCol='username_s',targetCol='username_t',weightCol='f'):
	'''
	Runs infomap clustering on the given weighted network. 

	Parameters
	----------
	wnet : pandas.DataFrame
		Table with source, target, and weight
	sourceCol : str ('username_s')
	targetCol : str ('username_t')
	weightCol : str ('f')

	Returns
	-------
	communities : pandas.DataFrame
	'''

	inodes = pd.DataFrame(set(wnet[sourceCol])|set(wnet[targetCol]),columns=['USERNAME']).reset_index()
	df = pd.merge(wnet,inodes.rename(columns={'USERNAME':sourceCol,'index':'index_s'}))
	df = pd.merge(df,inodes.rename(columns={'USERNAME':targetCol,'index':'index_t'}))
	df = df.sort_values(by=['index_s','index_t'])

	# Command line flags can be added as a string to Infomap
	myInfomap = infomap.Infomap("--two-level --directed")

	# Access the default network to add links programmatically
	network = myInfomap.network()
	for s,t,w in df[['index_s','index_t',weightCol]].values:
	    network.addLink(int(s),int(t),weight=w)
	# Run the Infomap search algorithm to find optimal modules
	myInfomap.run()
	print("Found {} modules with codelength: {}".format(myInfomap.numTopModules(), myInfomap.codelength()))
	communities = [(node.physicalId, node.moduleIndex()) for node in myInfomap.iterTree() if node.isLeaf()]
	communities = pd.DataFrame(communities,columns=['index','community'])
	communities = pd.merge(inodes,communities).drop('index',1).rename(columns={'community':'infomap_community'})
	return communities

def main():
	net_path = 'results/cytoscapeFiles'
	people = loadUsers()
	groupAfilliation = controlGroupAffiliation(people)
	pis = set(people[people['PERSON_TYPE'].isin(['Faculty/PI'])]['USERNAME'])

	projects = loadProjects()
	projects = filterProjects(projects)

	net = generateNework(projects)
	net = filterNodes(net,pis)
	G = nx.from_pandas_edgelist(net,'username_s','username_t',['n_projects'])

	nodes = projects[['username','slug']].groupby('username').count().reset_index().rename(columns={'username':'USERNAME','slug':'N_projects'})
	nodes = pd.merge(nodes[nodes['USERNAME'].isin(set(net['username_s'])|set(net['username_t']))],groupAfilliation)
	nodes = generate_palette(nodes,'ML_GROUP')

	nodes = pd.merge(nodes,pd.DataFrame(G.degree(),columns=['USERNAME','degree']))
	nodes = pd.merge(nodes,pd.DataFrame(nx.betweenness_centrality(G).items(),columns=['USERNAME','betweenness_centrality']))
	nodes = pd.merge(nodes,pd.DataFrame(nx.eigenvector_centrality(G).items(),columns=['USERNAME','eigenvector_centrality']))

	wnet = pd.merge(net,nodes[['USERNAME','N_projects']].rename(columns={'USERNAME':'username_s','N_projects':'projects_s'}))
	wnet['f'] = wnet['n_projects']/wnet['projects_s'].astype(float)
	communities = runInfomap(wnet)

	nodes = pd.merge(nodes,communities)
	nodes = generate_palette(nodes,'infomap_community')

	net[net['username_s']>net['username_t']].to_csv(os.path.join(net_path,'edges_2014-onwards_all.csv'),index=False)
	nodes.to_csv(os.path.join(net_path,'nodes_2014-onwards_all.csv'),index=False)


if __name__ == '__main__':
	main()