# source files are FB70752_all_qp_2017.csv thru FB70752_all_qp_2013.csv (total of 5 CSV files)

#
# NOW READ IN THE 2017 DATA FOR all FB70752 customers
#
FB70752_all_pq_2017 = CSV.read("FB70752_all_qp_2017.csv") # load the Farberware 70752 year 2017 all ln(q) and p data into julia
# this data includes only unique price observations with total units purchased by all customers at those unique prices 
# 20 data rows
#
ols_FB707752_2017 = lm(@formula(ln_q ~ p), FB70752_all_pq_2017) # ln(q) regressed on p and a constant
#
julia> ols_FB707752_2017 = lm(@formula(ln_q ~ p), FB70752_all_pq_2017) # ln(q) regressed on p and a constant
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

ln_q ~ 1 + p

Coefficients:
─────────────────────────────────────────────────────────────────────────────
              Estimate  Std. Error   t value  Pr(>|t|)  Lower 95%   Upper 95%
─────────────────────────────────────────────────────────────────────────────
(Intercept)  12.5658      4.00323    3.13891    0.0057    4.15531  20.9763   
p            -0.641981    0.296087  -2.16822    0.0438   -1.26404  -0.0199252
─────────────────────────────────────────────────────────────────────────────


#############################################################################
 
################ year 2016 ###############

#
# NOW READ IN THE 2016 DATA FOR all FB70752 customers
#
FB70752_all_pq_2016 = CSV.read("FB70752_all_qp_2016.csv") # load the Farberware 70752 year 2016 all ln(q) and p data into julia
# this data includes only unique price observations with total units purchased by all customers at those unique prices 
# 17 data rows
#
ols_FB707752_2016 = lm(@formula(ln_q ~ p), FB70752_all_pq_2016) # ln(q) regressed on p and a constant
#
julia> ols_FB707752_2016 = lm(@formula(ln_q ~ p), FB70752_all_pq_2016) # ln(q) regressed on p and a constant
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

ln_q ~ 1 + p

Coefficients:
───────────────────────────────────────────────────────────────────────────
             Estimate  Std. Error   t value  Pr(>|t|)  Lower 95%  Upper 95%
───────────────────────────────────────────────────────────────────────────
(Intercept)  19.0903     4.1143     4.63999    0.0003   10.3209   27.8598  
p            -1.09697    0.308806  -3.55229    0.0029   -1.75518  -0.438766
───────────────────────────────────────────────────────────────────────────

#############################################################################
 
################ year 2015 ###############

#
# NOW READ IN THE 2015 DATA FOR all FB70752 customers
#
FB70752_all_pq_2015 = CSV.read("FB70752_all_qp_2015.csv") # load the Farberware 70752 year 2015 all ln(q) and p data into julia
# this data includes only unique price observations with total units purchased by all customers at those unique prices 
# 17 data rows
#
ols_FB707752_2015 = lm(@formula(ln_q ~ p), FB70752_all_pq_2015) # ln(q) regressed on p and a constant
#
julia> ols_FB707752_2015 = lm(@formula(ln_q ~ p), FB70752_all_pq_2015) # ln(q) regressed on p and a constant
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

ln_q ~ 1 + p

Coefficients:
─────────────────────────────────────────────────────────────────────────────
              Estimate  Std. Error    t value  Pr(>|t|)  Lower 95%  Upper 95%
─────────────────────────────────────────────────────────────────────────────
(Intercept)   7.42693     3.04988    2.43516     0.0278   0.926267  13.9276  
p            -0.211742    0.217566  -0.973233    0.3459  -0.675473   0.251989
─────────────────────────────────────────────────────────────────────────────


#############################################################################
 
################ year 2014 ###############

#
# NOW READ IN THE 2014 DATA FOR all FB70752 customers
#
FB70752_all_pq_2014 = CSV.read("FB70752_all_qp_2014.csv") # load the Farberware 70752 year 2014 all ln(q) and p data into julia
# this data includes only unique price observations with total units purchased by all customers at those unique prices 
# 30 data rows
#
ols_FB707752_2014 = lm(@formula(ln_q ~ p), FB70752_all_pq_2014) # ln(q) regressed on p and a constant
#
julia> ols_FB707752_2014 = lm(@formula(ln_q ~ p), FB70752_all_pq_2014) # ln(q) regressed on p and a constant
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

ln_q ~ 1 + p

Coefficients:
────────────────────────────────────────────────────────────────────────────
              Estimate  Std. Error   t value  Pr(>|t|)  Lower 95%  Upper 95%
────────────────────────────────────────────────────────────────────────────
(Intercept)  11.6351      1.90708    6.10101    <1e-5    7.72866    15.5416 
p            -0.508705    0.140614  -3.61774    0.0012  -0.796741   -0.22067
────────────────────────────────────────────────────────────────────────────


#############################################################################
 
################ year 2013 ###############

#
# NOW READ IN THE 2013 DATA FOR all FB70752 customers
#
FB70752_all_pq_2013 = CSV.read("FB70752_all_qp_2013.csv") # load the Farberware 70752 year 2013 all ln(q) and p data into julia
# this data includes only unique price observations with total units purchased by all customers at those unique prices 
# 37 data rows
#
ols_FB707752_2013 = lm(@formula(ln_q ~ p), FB70752_all_pq_2013) # ln(q) regressed on p and a constant
#
julia> ols_FB707752_2013 = lm(@formula(ln_q ~ p), FB70752_all_pq_2013) # ln(q) regressed on p and a constant
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Cholesky{Float64,Array{Float64,2}}}},Array{Float64,2}}

ln_q ~ 1 + p

Coefficients:
──────────────────────────────────────────────────────────────────────────────
              Estimate  Std. Error   t value  Pr(>|t|)  Lower 95%    Upper 95%
──────────────────────────────────────────────────────────────────────────────
(Intercept)   8.8529      2.18858    4.04503    0.0003   4.40984   13.296     
p            -0.338124    0.166039  -2.03641    0.0493  -0.675201  -0.00104583
──────────────────────────────────────────────────────────────────────────────

##############################################################################
# the r-squared for each OLS model above is shown below:

r2(ols_FB707752_2017)
r2(ols_FB707752_2016)
r2(ols_FB707752_2015)
r2(ols_FB707752_2014)
r2(ols_FB707752_2013)

julia> r2(ols_FB707752_2019)
0.10170158209181301

julia> r2(ols_FB707752_2018)
0.2459825040633462

julia> r2(ols_FB707752_2017)
0.20708917280592098

julia> r2(ols_FB707752_2016)
0.45689157998998153

julia> r2(ols_FB707752_2015)
0.059394944400703586

julia> r2(ols_FB707752_2014)
0.3185359372216642

julia> r2(ols_FB707752_2013)
0.1059329467042166
