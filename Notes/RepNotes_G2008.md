---
title: Replication Notes for "Trusting the Stock Market"
---

# Key results to replicate in the HRS data

1. Significance of trust for **participation and shares invested** should be retained when controlling for risk and ambiguity measures. Risk and ambiguity aversion measures should not be statistically significant. Number of stocks should be decreasing in risk tolerance but increasing in the level of trust.

2. “More loss-averse people should insure more, but… less trusting people insure themselves less” - is there a measure of insurance in the HRS data?

3. Distinguish trust and optimism: is there a measure of optimism in HRS similar to the one from the “Life Orientation Test”

4. See if the trust results are robust for general trust and trust measures more specific to the financial system (“confidence toward the bank as a broker”)

5. Make sure that the trust measures are *not* highly correlated with wealth so that we may be able to explain lack of participation even at high levels of wealth (does beliefs do this as well?). 

    1. "average level of the two measures of trust by quartile of financial assets" may increase with wealth midly.

Note: Of these results, 1,2, and 4 are the most important to replicate.

# Variables needed from HRS (2020)

Participation, shares, generalized trust measure, risk aversion, ambiguity aversion, optimism, more specific trust measures, demographics (race, gender, employment, education)

# Theoretical results 

Guiso et al. introduce a simple, but very insightful model of portfolio choice between a safe and risky asset which introduces a probability of being cheated to model trust. Noting the theoretical insights here is useful because *the empirical results will be a test of the theory and allow of to asses those results*. These propositions proved by Guiso et al. will serve as a guideline for the empirical results I want to test/replicate using the HRS data.

1. Only investors with high enough trust $((1-p) > (1-\bar{p}))$ will invest in the stock market.

2. The more an investor trusts, the higher his optimal portfolio share invested in stocks conditional on participation.

3. Adding a fixed cost of participating lowers the threshhold value of p that triggers nonparticipation. 

4. For any probability of being cheated $p$, there exists a wealth threashold $\bar{W}_p$ that triggers participation and $\bar{W}_p$ is increasing in $p$.

5. Diversification will always be nondecreasing in trust if $D > V$.

6. The incentives to diversity will always be nondecreasing in trust if an investor would have diversified in the absence of any trust issue ($i.e., D > c$).

# Summarizing data used in Guiso et al. (2008)

In this section, I describe the main (household-level) variables and data sources from the paper. The main goal is to (i) finding the variables in the HRS which are closest to those described here and (ii) reproduce comparable summary statistics for those variables.

* Trust: "Generally speaking, would you say that most people can be trusted or that you have to be very careful in dealing with people?"

* Risk aversion: "Consider the following hypothetical lottery. Imagine a large urn containing 100 balls. In this urn, there are exactly 50 red balls and the remaining 50 balls are black. One ball is randomly drawn from the urn. If the ball is red, you win 5,000 euros; otherwise, you win nothing. What is the maximum price you are willing to pay for a ticket that allows you to participate in this lottery?"

* Ambiguity aversion: "Consider now a case where there are two urns, A and B. As before, each one has 100 balls, but urn A contains 20 red balls and 80 blacks, while urn B contains 80 reds and 20 blacks. One ball is drawn either from urn A or from urn B (the two events are equally likely). As before, if the ball is red you win 5,000 euros; otherwise, you win nothing. What is the maximum price you are willing to pay for a ticket that allows you to participate in this lottery?"

* Optimisim: "'We now present you with the following statement.' 'I expect more good things to happen to me than bad things.' Individuals have to rate their level of agreement/disagreement with the content of the statement, where one means they strongly disagree and five strongly agree."

## Household Retirement Survey (HRS) variable counterparts

As it stands, the HRS does not have an analog for the risk aversion, ambiguity aversion, and optimism questions. Thus, this dataset can not be used to replicate the empirical results aimed at testing the theoretical predictions regarding distinguishing trust and risk aversion (using the number of stocks) and trust and optimism.

Note: I can consider the relationship between trust and the number of stocks though. With this in mind, variable sections B, Q, and V will be used to replicate the results that can be replicated given the discrepancies between the two datasets.

# Statistical model

