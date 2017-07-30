from league import League

class WeightedEloLeague(League):
    """ A league based on the Elo system with modifications for 2v2
        Class takes a feature to modify and a factor to multiply that by   
    """
    name = "Elo"
    users = 0
    lowK = 16
    midK = 24
    highK = 32
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
                      
                      lambda u: u.user[1] if u.status > 9 else 1,
                      lambda u: u.user[1] if u.status < 9 else 1
                      ]
                      

    def init_user(self):
        return [0,0]
    
    def points(self, user_id):
        return self.user(user_id)[0]
    
    def __init__(self, weights):
        self.weights = weights
        self.users = {}

    def process(self, game):
        winK = self.getK(game, True)
        loseK = self.getK(game, False)
        winsum = sum([self.points(u.user_id) for u in game.winners])
        losesum = sum([self.points(u.user_id) for u in game.losers])
        try:
            Ew = 1.0/(1+10**((losesum - winsum)/400))
            El = 1.0/(1+10**((winsum - losesum)/400))
            for player in game.winners:
                self.users[player.user_id][0] += winK * (1.0 - Ew)
                self.users[player.user_id][1] += 1
            for player in game.losers:
                self.users[player.user_id][0] += loseK * (0.0 - El)
                self.users[player.user_id][1] += 1
        except:
            pass#print winsum, losesum


    def getK(self, game, winner):
        for u in game:
            if u: u.user = self.user(u.user_id)
        ret = self.highK
        for weight in self.weights:
            if weight[3] == winner:
                ret *= self.mult(game, self.features_funcs[weight[0]], weight[1], weight[2])
        #for weight in self.weights:
        #    ret += self.mult2(game, self.features_funcs[weight[0]], weight[1], weight[2])
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



##    feature_factors = [[[0.6561000000000001, 0.6561000000000001], [1.4641000000000006, 1.4641000000000006]],
##                        [[0.7290000000000001, 0.38742048900000015], [1.6105100000000008, 1.4641000000000006]],
##                        [[0.7290000000000001, 0.47829690000000014], [1.6105100000000008, 1.6105100000000008]],
##                        [[0.5314410000000002, 0.47829690000000014], [1.3310000000000004, 1.9487171000000014]],
##                        [[1.1, 0.25418658283290013],[2.5937424601000023, 1.1]],
##                        [[0.38742048900000015, 0.5314410000000002],[1.0, 2.853116706110003]],
##                        [[0.16677181699666577, 0.7290000000000001],[0.7290000000000001, 5.559917313492239]],
##                        [[1.2100000000000002, 0.28242953648100017],[2.5937424601000023, 0.9]],
##                        [[1.6105100000000008, 0.13508517176729928],[6.72749994932561, 1.1]],
##                        [[0.5904900000000002, 0.47829690000000014],[1.3310000000000004, 1.9487171000000014]],
##                        [[0.9, 0.38742048900000015],[1.9487171000000014, 1.3310000000000004]],
##                        [[0.43046721000000016, 0.5314410000000002],[1.3310000000000004, 28.102436848064315]],
##                        [[0.81, 0.5904900000000002],[1.9487171000000014, 3.797498335832415]],
##                        [[0.81, 0.81],[1.6105100000000008, 11.91817653772723]],
##                        [[0.38742048900000015, 0.81],[1.3310000000000004, 13.109994191499954]],
##                        [[0.38742048900000015, 0.47829690000000014],[1.2100000000000002, 3.797498335832415]],
##                        [[1.0, 2.1435888100000016],[1.1, 2253.240236044026]],
##                        [[1.9487171000000014, 1.9487171000000014],[66.26407607736661, 1.1]]]
