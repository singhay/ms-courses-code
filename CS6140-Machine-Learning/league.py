

class League(object):
    users = 0
    sorted_users = []

    def __init__(self):
        self.users = {}
    
    def user(self, user_id):
        if user_id not in self.users:
            self.users[user_id] = self.init_user()
            #self.sorted_users.append(user_id)
        return self.users[user_id]

    def update_league(self):        
        #self.sorted_users.sort(key = lambda x:self.points(x))
        pass

    def rank(self, user_id):
        if user_id not in self.users: 
            self.users[user_id] = self.init_user()
            #self.sorted_users.append(user_id)
        return self.sorted_users.index(user_id)  

    def predict(self, game):
        winsum = sum([self.points(u.user_id) for u in game.winners])
        losesum = sum([self.points(u.user_id) for u in game.losers])
        return winsum > losesum
    
