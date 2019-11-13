clear all
import delimited using "results/network4comparison.csv", clear

gen log_collisionpotential = log(collisionpotential_dis)
replace collisionpotential_dis = collisionpotential_dis/1000
gen same_group_dis = collisionpotential_dis*same_group

replace overlap =  12*overlap/365. // In months
// replace overlap = overlap/7. // In weeks
replace ageyoungestuser = 12*ageyoungestuser/365.
replace ageoldestuser = 12*ageoldestuser/365.

gen log_n_proj = log(n_proj+1)

// eststo clear
// eststo: zip n_proj log_collisionpotential overlap, inflate(log_collisionpotential overlap)
// eststo: zip n_proj log_collisionpotential overlap same_group, inflate(log_collisionpotential overlap same_group)
// esttab, replace se ar2 aic compress 

eststo clear
eststo: quietly regress log_n_proj collisionpotential_dis overlap
eststo: quietly regress log_n_proj collisionpotential_dis overlap if log_n_proj!=0
eststo: quietly regress collab collisionpotential_dis overlap
eststo: quietly regress collab collisionpotential_dis overlap same_group
eststo: quietly logit collab collisionpotential_dis overlap
eststo: quietly logit collab collisionpotential_dis overlap same_group
eststo: quietly logit collab collisionpotential_dis overlap same_group same_group_dis
esttab, replace se ar2 aic compress 



eststo clear
quietly logit collab collisionpotential_dis overlap
eststo: margins, dydx(*) post 
quietly logit collab same_group overlap
eststo: margins, dydx(*) post 
quietly logit collab collisionpotential_dis overlap same_group
eststo: margins, dydx(*) post
esttab, replace se margin compress 
//  using "results/logitcomparison.tex"
