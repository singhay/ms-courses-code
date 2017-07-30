
#: The actual score for win
WIN = 1.
#: The actual score for draw
DRAW = 0.5
#: The actual score for loss
LOSS = 0.
SPECTATE = -1

class Game:
    id = 0
    pack_id = 0
    map_id = 0
    time = 0
    length = 0
    rated = 0
    players = 0
    player_details = []
    winners = []
    losers = []
    value = 0

    def __init__(self, id):
        self.id = id
        self.player_details = []
        self.winners = []
        self.losers = []
        self.value = 0

    # get player detail
    def __getitem__(self, key):
        return self.player_details[key]

    # set player detail
    def __setitem__(self, key, value):
        if not self.player_details:
            self.player_details = [0]*self.players
        self.player_details[key] = value
        if self.player_details[key].result() == WIN:
            self.winners.append(self.player_details[key])
        elif self.player_details[key].result() == LOSS:
            self.losers.append(self.player_details[key])
        
class Game_Detail:
    game_id = 0
    user_id = 0
    player = 0
    ping = 0
    tribe = 0
    status = 0
    length = 0
    start_allies = 0
    end_allies = 0
    fights_won = 0
    fights_lost = 0
    followers_killed = 0
    buildings_destroyed = 0
    shamans_killed = 0
    followers_lost = 0
    buildings_lost = 0
    shaman_deaths = 0
    pop0 = 0
    pop1 = 0
    pop2 = 0
    pop3 = 0

    def result(self):
        if self.status > 9:
            return WIN
        elif self.status < 9:
            return LOSS
        return SPECTATE

    def __init__(self, id, player):
        self.game_id = id
        self.player = player
        self.user = 0
