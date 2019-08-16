import pandas as pd
import json
import os

def parseUsers(projects):
	'''
	Parses the users from the projects provided in a dataframe.

	Parameters
	----------
	projects : pandas.DataFrame
	    Table of projects. Must have columns 'people' and a 'slug'.
	'''
	out = []
	for slug,people in projects[['slug','people']].values:
		if len(people)!=0:
			for person in people:
				if '@media.mit.edu' in person: # Keep only media lab users
					out.append((slug,person.replace('@media.mit.edu','').strip()))
	return pd.DataFrame(out,columns=['slug','username'])

def loadProjects(in_path='../Data/'):
	'''
	Loads projects into a DataFrame from a given path. It takes care of putting user data into first normal form.

	Parameters
	----------
	in_path : str (optional)
		Path of projects-active.json and projects-inactive.json.
	'''
	fnameActive = 'projects-active.json'
	fnameInactive = 'projects-inactive.json'
	activeProjects   = pd.read_json(os.path.join(in_path,fnameActive))
	inactiveProjects = pd.read_json(os.path.join(in_path,fnameInactive))
	activeProjects['is_active'] = True
	inactiveProjects['is_active'] = False

	activeProjects = pd.merge(parseUsers(activeProjects),activeProjects.drop(['people','groups'],1))
	inactiveProjects = pd.merge(parseUsers(inactiveProjects),inactiveProjects.drop(['people','groups'],1))

	projects = pd.concat([inactiveProjects,activeProjects])
	return projects

def loadUsers(in_path='../Data'):
	'''
	Loads raw data about ML users. 

	Parameters
	----------
	in_path : str (optional)
		Path to mlpeople.csv.
	'''
	people = pd.read_csv(os.path.join(in_path,'mlpeople.csv'))
	return people

def generateNework(projects,keepProjectData=False):
	'''
	Generates network of users connected when they worked together on a project.

	Parameters
	----------
	projects : pandas.DataFrame
		Table with columns slug and username

	Returns
	-------
	net : pandas.DataFrame
		Table with username_s, username_t, and number of projets.
	'''
	if keepProjectData:
		df = projects[['slug','username','title']]
		net = pd.merge(df.rename(columns={'username':'username_s'}),df.rename(columns={'username':'username_t'}))
		net = net[net['username_s']!=net['username_t']]
		net = net[['username_s','username_t','slug','title']]
	else:
		df = projects[['slug','username']]
		net = pd.merge(df.rename(columns={'username':'username_s'}),df.rename(columns={'username':'username_t'}))
		net = net[net['username_s']!=net['username_t']]
		net = net.groupby(['username_s','username_t']).count().rename(columns={'slug':'n_projects'}).reset_index()
	return net

def formatNetwork(net):
	'''
	Formats the network into a dictonary that can be written in a json file.

	Parameters
	----------
	net : pandas.DataFrame
		Table with username_s,username_t, and n_projects.
	'''
	net['username_t*n_projects']=net[['username_t','n_projects']].values.tolist()
	return dict(net.groupby('username_s')['username_t*n_projects'].apply(list))

def filterProjects(projects):
	'''
	Filter projects if needed (by date, for example)
	'''
	drop_list = ['scratch-in-practice','ml-learning-fellows-program','learning-creative-learning'] # 'scratch'
	projects = projects[~projects['slug'].isin(drop_list)]
	return projects

def main():
	out_path = '../ProxymixABM/includes/'
	projects = loadProjects()

	projects = filterProjects(projects)

	net = generateNework(projects)
	data_out = formatNetwork(net)
	with open(os.path.join(out_path,'project-network.json'), 'w') as fp:
		json.dump(data_out, fp)

if __name__ == '__main__':
	main()