import pandas as pd
import numpy as np
import json
import os
from main import *
from build_network import filterProjects,controlGroupAffiliation,filterNodes

from sklearn.linear_model import LinearRegression
from datetime import timedelta
from datetime import datetime
def inferStay():
    '''
    Infers how long (in days) a user spent at the Media Lab.
    The start date is inferred from the first project.
    The end data is inferred either from the last project, from the fact that the user is still active, or is imputed based on the user's group, number of projects, and how long ago they joined.
    '''
    firstRecord = loadProjects()[['username','start_on']].drop_duplicates().dropna()
    firstRecord['start_on'] = firstRecord['start_on'].apply(lambda x: datetime.strptime(x, '%Y-%m-%d'))
    firstRecord = firstRecord.groupby('username').min().reset_index()

    lastRecord = loadProjects()[['username','end_on']].drop_duplicates().dropna()
    lastRecord['end_on'] = lastRecord['end_on'].apply(lambda x: datetime.strptime(x, '%Y-%m-%d'))
    lastRecord = lastRecord.groupby('username').max().reset_index()

    nprojs = loadProjects()[['username','slug']].drop_duplicates().groupby('username').count().reset_index()

    ml_status = loadUsers()[['USERNAME','ML_STATUS']].rename(columns={"USERNAME":'username'})

    groupAfilliation = controlGroupAffiliation(loadUsers()).rename(columns={'USERNAME':'username'}).drop('is_affiliate',1)

    refDate = datetime.strptime('2019-06-01', '%Y-%m-%d')
    users = pd.merge(pd.merge(pd.merge(pd.merge(firstRecord,lastRecord,how='outer'),ml_status,how='left'),nprojs,how='left'),groupAfilliation,how='left')
    users.loc[users['ML_STATUS']==True,'end_on'] = refDate
    users.loc[users['end_on']>refDate,'end_on'] = np.nan
    users['diff'] = (users['end_on']-users['start_on']).apply(lambda x: x.days)
    users['diff2ref'] = (refDate-users['start_on']).apply(lambda x: x.days)
    print(len(set(users['username'])),len(users))

    to_impute = users[users['ML_STATUS']==False]

    inputData = to_impute[~to_impute['diff'].isna()][['ML_GROUP','slug','diff2ref']]
    inputData['slug'] = np.log(inputData['slug'])
    outputData = to_impute[~to_impute['diff'].isna()]['diff'].values
    outSample = to_impute[to_impute['diff'].isna()][['ML_GROUP','slug','diff2ref']]
    outSample['slug'] = np.log(outSample['slug'])

    for column in inputData.columns:
        if inputData[column].dtype==object:
            dummyCols=pd.get_dummies(inputData[column])
            dummyColsOut=pd.get_dummies(outSample[column])
            inputData=inputData.join(dummyCols)
            outSample=outSample.join(dummyColsOut)
            del inputData[column]
            del outSample[column]
    for c in set(inputData.columns).difference(set(outSample.columns)):
        outSample[c] = 0

    outSample = outSample[inputData.columns.values.tolist()]

    model_1=LinearRegression()
    model_1.fit(inputData,outputData)

    to_impute = to_impute[to_impute['diff'].isna()]
    to_impute['diff'] = list(model_1.predict(outSample))

    users = pd.concat([users[~users['diff'].isna()],to_impute])
    users.loc[users['diff']>users['diff2ref'],'diff'] = users[users['diff']>users['diff2ref']]['diff2ref']

    users['end_on'] = users['start_on'] + users['diff'].apply(lambda x: timedelta(days=x))
    return users

def inferOverlap(users,userSet=None):
	if userSet is None:
		userSet = set(users['username'])
	timeOverlap = []
	for u1 in userSet:
		u1_start = users[users['username']==u1]['start_on'].values[0]
		u1_end   = users[users['username']==u1]['end_on'].values[0]
		for u2 in userSet:
			if u1!=u2:
				u2_start = users[users['username']==u2]['start_on'].values[0]
				u2_end   = users[users['username']==u2]['end_on'].values[0]
				dt = (min(u1_end,u2_end)-max(u1_start,u2_start)).astype('timedelta64[D]')/np.timedelta64(1, 'D')
				timeOverlap.append((u1,u2,dt))
	timeOverlap = pd.DataFrame(timeOverlap,columns=['username_s','username_t','overlap'])
	return timeOverlap

def main():
	real_netowrk_path = '../ProxymixABM/includes/'
	simulated_netowrk_path = '../ProxymixABM/results/'
	out_path = 'results'

	with open(os.path.join(real_netowrk_path,'project-network.json')) as json_file:
		data = json.load(json_file)

	real = []
	for s in data:
		for t in data[s]:
			real.append((s,t[0],t[1]))
	real = pd.DataFrame(real,columns=['username_s','username_t','n_proj'])

	generated = pd.read_csv(os.path.join(simulated_netowrk_path,'generated_graph.txt'),skiprows=1,header=None)
	generated.columns=['username_s','username_t']
	generated['collisionPotential'] = 1

	userSet = (set(real['username_s'])|set(real['username_t'])).intersection(set(generated['username_s'])|set(generated['username_t']))

	users = inferStay()
	userSet = userSet.intersection(set(users['username']))

	users = users[users['username'].isin(userSet)]
	generated = generated[(generated['username_s'].isin(userSet))&(generated['username_t'].isin(userSet))]
	real = real[(real['username_s'].isin(userSet))&(real['username_t'].isin(userSet))]

	timeOverlap = inferOverlap(users,userSet=userSet)

	userData = users[['username','ML_GROUP','diff','diff2ref']]
	userData = pd.merge(userData,loadUsers()[['USERNAME','TITLE']].rename(columns={'USERNAME':'username'}),how='left')
	userData.loc[userData['TITLE']!='Research Assistant','TITLE'] = 'Other'

	# GENERATE OUTPUT TABLE
	net = pd.merge(timeOverlap,real,how='left').fillna(0)
	net = pd.merge(net,generated,how='left').fillna(0)
	net = pd.merge(net,userData.rename(columns=dict(zip(userData.columns,[c+'_s' for c in userData.columns]))))
	net = pd.merge(net,userData.rename(columns=dict(zip(userData.columns,[c+'_t' for c in userData.columns]))))

	net['ageOldestUser'] = net[['diff_s','diff_t']].min(1)
	net['ageYoungestUser'] = net[['diff_s','diff_t']].max(1)
	net['SAME_GROUP'] = 0
	net.loc[net['ML_GROUP_s']==net['ML_GROUP_t'],'SAME_GROUP'] = 1
	net['collab'] = 0 
	net.loc[net['n_proj']!=0,'collab']=1
	net['collabpm'] = 365.*net['collab']/(12.*net['overlap'])
	net['projectspm'] = 365.*net['n_proj']/(12.*net['overlap'])

	net.to_csv(os.path.join(out_path,'network4comparison.csv'),index=False)

if __name__ == '__main__':
	main()

