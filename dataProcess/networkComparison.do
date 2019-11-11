clear all
import delimited using "results/network4comparison.csv", clear

replace overlap =  12*overlap/365.
replace ageyoungestuser = 12*ageyoungestuser/365.
replace ageoldestuser = 12*ageoldestuser/365.

gen log_n_proj = log10(n_proj+1)


eststo clear
eststo: regress log_n_proj collisionpotential overlap
eststo: regress log_n_proj collisionpotential overlap if log_n_proj!=0
eststo: logit collab collisionpotential overlap
eststo: logit collab collisionpotential overlap same_group
eststo: zip n_proj collisionpotential overlap, inflate(collisionpotential overlap)
eststo: zip n_proj collisionpotential overlap same_group, inflate(collisionpotential overlap same_group)
esttab, replace se ar2 aic compress 

