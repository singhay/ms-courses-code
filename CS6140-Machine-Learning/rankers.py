from WeightedElo import *
from glicko import *
import trueskill
from WeightedTS import Rating
from league import League

class TraditionalLeague(League):
    """ The traditional league used for Populous
        1 win = 1 point"""
    name = "Traditional"

    def init_user(self):
        return 0

    def points(self, user_id):
        return self.user(user_id)

    def process(self, game):
        for player in game.winners:
            self.users[player.user_id] += 1
        self.update_league()

class SimpleLeague(League):
    """ A simple league system
        1 win = 1 point, 1 loss = -1 point"""
    name = "Simple"

    def init_user(self):
        return 0

    def points(self, user_id):
        return self.user(user_id)

    def process(self, game):
        for player in game.winners:
            self.users[player.user_id] += 1
        for player in game.losers:
            self.users[player.user_id] -= 1
        self.update_league()

class EloLeague(League):
    """ A league based on the Elo system with modifications for 2v2
        
    """
    name = "Elo"
    lowK = 16
    midK = 24
    highK = 32

    def init(self):
        self.users = {}

    def init_user(self):
        return 0

    def points(self, user_id):
        return self.user(user_id)
    
    def process(self, game):
        K = self.highK
        winsum = sum([self.user(u.user_id) for u in game.winners])
        losesum = sum([self.user(u.user_id) for u in game.losers])
        Ew = 1.0/(1+10**((losesum - winsum)/400))
        El = 1.0/(1+10**((winsum - losesum)/400))
        for player in game.winners:
            self.users[player.user_id] += K * (1.0 - Ew) 
        for player in game.losers:
            self.users[player.user_id] += K * (0.0 - El) 
        self.update_league()
            
            
class TrueSkillLeague(League):
    """ A league based on the Trueskill system on trueskill.org
        
    """
    name = "TrueSkill"
    users = {}
    trueskill.setup( beta=5, tau=0.4, draw_probability=0.01)

    def init_user(self):
        return Rating()

    def points(self, user_id):
        r = self.user(user_id)
        return r.mu-3*r.sigma
    
    def process(self, game):
        if not game.winners or not game.losers: return
        winners = {}
        losers = {}
        for u in game.winners: winners[u.user_id] = self.user(u.user_id)
        for u in game.losers: losers[u.user_id] = self.user(u.user_id)
        updates = trueskill.rate([winners, losers], ranks=[0, 1])
        for d in updates:
            for user_id, rating in d.iteritems():
                self.users[user_id] = rating
        self.update_league()
            

