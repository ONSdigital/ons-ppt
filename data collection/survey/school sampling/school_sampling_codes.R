# formula [DEFF*Np(1-p)]/ [(d2/Z21-α/2(N-1) +p*(1-p)] to sample size 
DEFF <- 1.5
N <- 10000
Z <- 1.96
p <- 0.5
d <- 0.05

# inputting the values within the formula
n <- (DEFF * N * Z^2 * p * (1-p)) / (d^2 * (N-1) + Z^2 * p * (1-p))

# rounding up the sample size value 
n <- ceiling(n)

# printing the value of sample size
print(n)




# Install the pwr package (run once)
install.packages("pwr")
# Load the package
library(pwr)
# Power calculation for two proportions
pwr::pwr.2p.test(  h = 0.5,  sig.level = 0.05,  power = 0.95,  alternative = "two.sided"
)



# Install the pwr package (run once)
install.packages("pwr")
# Load the package
library(pwr)

pwr::pwr.2p.test(h = 0.5, sig.level = 0.05,    power = 0.95, alternative = "two.sided")
