import pandas as pd
import os
from main import loadProjects,loadUsers
from build_network import filterProjects,controlGroupAffiliation,filterNodes,generateNework

def main():
	net_path = 'results/cytoscapeFiles'

	people = loadUsers()
	groupAfilliation = controlGroupAffiliation(people)[['USERNAME','ML_GROUP']]

	pis = set(people[people['PERSON_TYPE'].isin(['Faculty/PI'])]['USERNAME'])

	projects = loadProjects()
	projects = filterProjects(projects)

	net = generateNework(projects,keepProjectData=True)
	net = filterNodes(net,pis)

	net = pd.merge(net,groupAfilliation.rename(columns={'USERNAME':'username_s','ML_GROUP':'group_s'}))
	net = pd.merge(net,groupAfilliation.rename(columns={'USERNAME':'username_t','ML_GROUP':'group_t'}))

	net.to_csv(os.path.join(net_path,'edges_2014-onwards_all-withprojects.csv'),index=False,encoding='utf-8')

if __name__ == '__main__':
	main()