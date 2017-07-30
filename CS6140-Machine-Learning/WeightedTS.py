from league import League
import trueskill

class Rating(trueskill.Gaussian):
    """Represents a player's skill as Gaussian distrubution.
    The default mu and sigma value follows the global environment's settings.
    If you don't want to use the global, use :meth:`TrueSkill.create_rating` to
    create the rating object.
    :param mu: the mean.
    :param sigma: the standard deviation.
    """

    games = 0
    last_game = 0

    def __init__(self, mu=None, sigma=None):
        if isinstance(mu, tuple):
            mu, sigma = mu
        elif isinstance(mu, trueskill.Gaussian):
            mu, sigma = mu.mu, mu.sigma
        if mu is None:
            mu = trueskill.global_env().mu
        if sigma is None:
            sigma = trueskill.global_env().sigma
        self.games = 0
        self.last_game = 0
        super(Rating, self).__init__(mu, sigma)

    def __int__(self):
        return int(self.mu)

    def __long__(self):
        return long(self.mu)

    def __float__(self):
        return float(self.mu)

    def __iter__(self):
        return iter((self.mu, self.sigma))

    def __repr__(self):
        c = type(self)
        args = ('.'.join([c.__module__, c.__name__]), self.mu, self.sigma)
        return '%s(mu=%.3f, sigma=%.3f)' % args


class WeightedTSLeague(League):
    """ A league based on the Elo system with modifications for 2v2
        Class takes a feature to modify and a factor to multiply that by   
    """
    name = "WeightedTS"
    trueskill.setup( beta=5, tau=0.4, draw_probability=0.01)
    users = 0
    weights = 0
    features_funcs = [0,
                      lambda u: u.ping,
                      lambda u: u.length,
                      lambda u: u.fights_won,
                      lambda u: u.fights_lost,
                      lambda u: u.followers_killed,
                      
                      lambda u: u.buildings_destroyed,
                      lambda u: u.followers_lost,
                      lambda u: u.buildings_lost,
                      lambda u: u.shamans_killed,
                      lambda u: u.shaman_deaths,
                      
                      lambda u: u.pop0 if u.player == 0 else \
                                u.pop1 if u.player == 1 else \
                                u.pop2 if u.player == 2 else \
                                u.pop3,
                      lambda u: 10 if not u.shaman_deaths else u.shamans_killed/u.shaman_deaths,
                      lambda u: 10 if not u.followers_lost else u.followers_killed/u.followers_lost,
                      lambda u: 10 if not u.buildings_lost else u.buildings_destroyed/u.buildings_lost,
                      lambda u: 10 if not u.fights_lost else u.fights_won/u.fights_lost,
                      
                      lambda u: u.user.games if u.status > 9 else 1,
                      lambda u: u.user.games if u.status < 9 else 1
                      ]
                      

    def init_user(self):
        return Rating()
    
    def points(self, user_id):
        r = self.user(user_id)
        return r.mu-3*r.sigma
    
    def __init__(self, weights):
        self.weights = weights
        self.users = {}

    def process(self, game):
        winners = {}
        losers = {}
        weights = {}
        #mgames = min( [self.user(u.user_id).games for u in game.winners+game.losers] )

        for u in game.winners+game.losers:
            if u: u.user = self.user(u.user_id)            

        winweight = self.get_weight(game, 1)
        loseweight = self.get_weight(game, 0)
        for u in game.winners:
            winners[u.user_id] = self.user(u.user_id)
            #weights[(0,u.user_id)] = winweight
        for u in game.losers:
            losers[u.user_id] = self.user(u.user_id)
            #weights[(1,u.user_id)] = loseweight  
        weights.update(self.get_user_weights(game.winners, 0))
        weights.update(self.get_user_weights(game.losers, 1))
        
        updates = trueskill.rate([winners, losers], weights=weights, ranks=[0, 1])
        for d in updates:
            for user_id, rating in d.iteritems():
                games = self.users[user_id].games
                self.users[user_id] = rating
                self.users[user_id].games = games + 1

    def get_user_weights(self, players, i):
        weights = {}
        highest = max([u.followers_killed for u in players])*1.0
        for u in players:
            if u.followers_killed == highest:
                if i == 0: weights[(i, u.user_id)] = 1.0
                else: weights[(i, u.user_id)] = 1.0
            else:
                if i == 0: weights[(i, u.user_id)] = 1.0
                else: weights[(i, u.user_id)] = 1.0
        return weights
            


    def get_weight(self, game, winner):
        ret = 0.5
        for weight in self.weights:
            if weight[3] == winner:
                ret *= self.mult(game, self.features_funcs[weight[0]], weight[1], weight[2])
        return ret

    def mult(self, game, feature, factor, inverse):
        if not feature: return factor
        winsum = sum([feature(u) for u in game.winners])
        losesum = sum([feature(u) for u in game.losers])
        if inverse:
            if winsum == 0: return factor
            return max(min(1.0*losesum/winsum*factor, 3), -3)
        if losesum == 0: return factor
        return max(min(1.0*winsum/losesum*factor, 3), -3)

    def mult2(self, game, feature, factor, inverse):
        if not feature: return factor
        winsum = sum([feature(u) for u in game.winners])
        losesum = sum([feature(u) for u in game.losers])
        if inverse:
            if not winsum: return 0
            return factor/winsum
        return factor*winsum
        
