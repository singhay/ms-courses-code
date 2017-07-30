# -*- coding: utf-8 -*-
"""
    glicko2
    ~~~~~~~
    The Glicko2 rating system.
    :copyright: (c) 2012 by Heungsub Lee
    :license: BSD, see LICENSE for more details.
"""
import math
from league import League

__version__ = '0.0.dev'


#: The actual score for win
WIN = 1.
#: The actual score for draw
DRAW = 0.5
#: The actual score for loss
LOSS = 0.


MU      = 1500
PHI     = 350
SIGMA   = 0.06
TAU     = 1.0
EPSILON = 0.000001
#: A constant which is used to standardize the logistic function to
#: `1/(1+exp(-x))` from `1/(1+10^(-r/400))`
Q = math.log(10) / 400


class Rating(object):

    def __init__(self, mu=MU, phi=PHI, sigma=SIGMA):
        self.mu    = mu
        self.phi   = phi
        self.sigma = sigma

    def __repr__(self):
        c = type(self)
        args = (c.__module__, c.__name__, self.mu, self.phi, self.sigma)
        return '%s.%s(mu=%.3f, phi=%.3f, sigma=%.3f)' % args

    def update(self, old_rate, new_rate, split):
        #print self.mu, self.phi, self.sigma
        self.mu += (new_rate.mu - old_rate.mu)/split
        self.phi += (new_rate.phi - old_rate.phi)/split
        self.sigma = min(new_rate.sigma, self.sigma)
        #print self.mu, self.phi, self.sigma
        #print


class GlickoLeague(League):
    name = "Glicko"

    def __init__(self, mu=MU, phi=PHI, sigma=SIGMA, tau=TAU, epsilon=EPSILON):
        self.mu      = mu
        self.phi     = phi
        self.sigma   = sigma
        self.tau     = tau
        self.epsilon = epsilon
        self.users   = {}

    def create_rating(self, mu=None, phi=None, sigma=None):
        if mu is None:    mu = self.mu
        if phi is None:   phi = self.phi
        if sigma is None: sigma = self.sigma
        return Rating(mu, phi, sigma)

    def scale_down(self, rating, ratio=173.7178):
        mu = (rating.mu - self.mu) / ratio
        phi = rating.phi / ratio
        return self.create_rating(mu, phi, rating.sigma)

    def scale_up(self, rating, ratio=173.7178):
        mu = rating.mu * ratio + self.mu
        phi = rating.phi * ratio
        return self.create_rating(mu, phi, rating.sigma)

    def reduce_impact(self, rating):
        """The original form is `g(RD)`. This function reduces the impact of
        games as a function of an opponent's RD.
        """
        return 1 / math.sqrt(1 + (3 * rating.phi ** 2) / (math.pi ** 2))

    def expect_score(self, rating, other_rating, impact):
        x = 1. / (1 + math.exp(-impact * (rating.mu - other_rating.mu)))
        if x == 0:
            return 1.0E-10
        if x == 1:
            return 1 - 1.0E-10
        return x

    def determine_sigma(self, rating, difference, variance):
        """Determines new sigma."""
        phi = rating.phi
        difference_squared = difference ** 2
        # 1. Let a = ln(s^2), and define f(x)
        alpha = math.log(rating.sigma ** 2)
        def f(x):
            """This function is twice the conditional log-posterior density of
            phi, and is the optimality criterion.
            """
            tmp = phi ** 2 + variance + math.exp(x)
            a = math.exp(x) * (difference_squared - tmp) / (2 * tmp ** 2)
            b = (x - alpha) / (self.tau ** 2)
            return a - b
        # 2. Set the initial values of the iterative algorithm.
        a = alpha
        if difference_squared > phi ** 2 + variance:
            b = math.log(difference_squared - phi ** 2 - variance)
        else:
            k = 1
            while f(alpha - k * math.sqrt(self.tau ** 2)) < 0:
                k += 1
            b = alpha - k * math.sqrt(self.tau ** 2)
        # 3. Let fA = f(A) and f(B) = f(B)
        f_a, f_b = f(a), f(b)
        # 4. While |B-A| > e, carry out the following steps.
        # (a) Let C = A + (A - B)fA / (fB-fA), and let fC = f(C).
        # (b) If fCfB < 0, then set A <- B and fA <- fB; otherwise, just set
        #     fA <- fA/2.
        # (c) Set B <- C and fB <- fC.
        # (d) Stop if |B-A| <= e. Repeat the above three steps otherwise.
        while abs(b - a) > self.epsilon:
            c = a + (a - b) * f_a / (f_b - f_a)
            f_c = f(c)
            if f_c * f_b < 0:
                a, f_a = b, f_b
            else:
                f_a /= 2
            b, f_b = c, f_c
        # 5. Once |B-A| <= e, set s' <- e^(A/2)
        return math.exp(1) ** (a / 2)

    def rate(self, rating, series):
        # Step 2. For each player, convert the rating and RD's onto the
        #         Glicko-2 scale.
        rating = self.scale_down(rating)
        # Step 3. Compute the quantity v. This is the estimated variance of the
        #         team's/player's rating based only on game outcomes.
        # Step 4. Compute the quantity difference, the estimated improvement in
        #         rating by comparing the pre-period rating to the performance
        #         rating based only on game outcomes.
        d_square_inv = 0
        variance_inv = 0
        difference   = 0

        for actual_score, other_rating in series:
            other_rating   = self.scale_down(other_rating)
            impact         = self.reduce_impact(other_rating)
            expected_score = self.expect_score(rating, other_rating, impact)
            variance_inv   += impact ** 2 * expected_score * (1 - expected_score)
            difference     += impact * (actual_score - expected_score)
            d_square_inv   += (expected_score * (1 - expected_score) * (Q ** 2) * (impact ** 2))

        difference /= variance_inv
        variance   = 1. / variance_inv
        denom      = rating.phi ** -2 + d_square_inv
        mu         = rating.mu + Q / denom * (difference / variance_inv)
        phi        = math.sqrt(1 / denom)
        # Step 5. Determine the new value, Sigma', ot the sigma. This
        #         computation requires iteration.
        sigma      = self.determine_sigma(rating, difference, variance)
        # Step 6. Update the rating deviation to the new pre-rating period
        #         value, Phi*.
        phi_star   = math.sqrt(phi ** 2 + sigma ** 2)
        # Step 7. Update the rating and RD to the new values, Mu' and Phi'.
        phi        = 1 / math.sqrt(1 / phi_star ** 2 + 1 / variance)
        mu         = rating.mu + phi ** 2 * (difference / variance)
        # Step 8. Convert ratings and RD's back to original scale.
        return self.scale_up(self.create_rating(mu, phi, sigma))

    def rate_1vs1(self, rating1, rating2, drawn=False):
        return (self.rate(rating1, [(DRAW if drawn else WIN, rating2)]),
                self.rate(rating2, [(DRAW if drawn else LOSS, rating1)]))

    def quality_1vs1(self, rating1, rating2):
        expected_score1 = self.expect_score(rating1, rating2, self.reduce_impact(rating1))
        expected_score2 = self.expect_score(rating2, rating1, self.reduce_impact(rating2))
        expected_score  = (expected_score1 + expected_score2) / 2
        return 2 * (0.5 - abs(0.5 - expected_score))

    def user(self, user_id):
        if user_id not in self.users:
            self.users[user_id] = self.create_rating()
        return self.users[user_id]

    def user_points(self, user_id):
        u = self.user(user_id)
        return u.mu-3*u.sigma
        

    def predict(self, game):
        winsum  = sum([self.user_points(u.user_id) for u in game.winners])
        losesum = sum([self.user_points(u.user_id) for u in game.losers])
        return winsum > losesum

    def process(self, game):
        # only 1v1 or 2v2
        if len(game.winners) != len(game.losers) or not game.losers: return

        # 1v1
        if len(game.winners) == 1 and len(game.losers) == 1:
            w = game.winners[0].user_id
            l = game.losers[0].user_id
            a = self.rate(self.users[w], [[WIN, self.users[l]]])
            self.users[l] = self.rate(self.users[l], [[LOSS, self.users[w]]])
            self.users[w] = a
            return
        
        # 1v1
        if len(game.winners) == 2 and len(game.losers) == 2:
            mu_win = sum([self.users[p.user_id].mu for p in game.winners])
            mu_lose = sum([self.users[p.user_id].mu for p in game.losers])
            phi_win = min([self.users[p.user_id].phi for p in game.winners])
            phi_lose = min([self.users[p.user_id].phi for p in game.losers])
            sigma_win = max([self.users[p.user_id].sigma for p in game.winners])
            sigma_lose = max([self.users[p.user_id].sigma for p in game.losers])
            winner = Rating(mu_win, phi_win, sigma_win)
            loser = Rating(mu_lose, phi_lose, sigma_lose)
            new_winner = self.rate(winner, [[WIN, loser]])
            new_loser = self.rate(loser, [[LOSS, winner]])
            
            for p in game.winners:
                self.users[p.user_id].update(winner, new_winner, len(game.winners))
            for p in game.losers:
                self.users[p.user_id].update(loser, new_loser, len(game.losers))
##        print
##        print winner
##        print new_winner
##        print loser
##        print new_loser
            
##        for winner, loser in zip(game.winners, game.losers):
##            self.users[winner.user_id] = self.rate(self.users[winner.user_id], [[WIN, self.users[loser.user_id]]] )
##            self.users[loser.user_id] = self.rate(self.users[loser.user_id], [[LOSS, self.users[winner.user_id]]] )
##            # Ignoring the matching b/w individual players even in a..
##            # ..2v2 match but that should be put into consideration i.e. avg of both teams

##env = GlickoLeague()
##r1 = env.create_rating(1500, 200)
##r2 = env.create_rating(1400, 30)
##r3 = env.create_rating(1550, 100)
##r4 = env.create_rating(1700, 300)
##rated = env.rate(r1, [(WIN, r2), (LOSS, r3), (LOSS, r4)])            
##print rated         
# print env.process()

