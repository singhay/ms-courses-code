import pickle
import json
import time
import csv
import concurrent.futures
from games import *
from os.path import exists
import WeightedElo
import WeightedTS
import glicko
import rankers

##  League        Full           1vs1           2vs2
##        # Games 136,144        50,134         86,010
##    Traditional 0.678164296627 0.683827342722 0.66064411115
##         Simple 0.64075537666  0.651813140783 0.643448436228
##            Elo 0.739577212363 0.718574221087 0.737774677363
##         Glicko 0.72718592079  0.714664698608 0.714463434484
##      TrueSkill 0.756955870255 0.742968843499 0.758051389373
##   Weighted Elo 0.750146903279 0.725136633821 0.749098941983


##Factoring features in Elo - same features used for winner and loser K:
##    Best: 0.708004117611
##[[5, 0.81, 0], [0, 0.94, 0], [0, 0.93, 0]]

##Factoring features in Elo - separate features used for winner and loser K:
##    Best: 0.750146903279
##[[9, 0.59, 0, 0], [0, 1.06, 0, 1]]



def load_csv_data(): 
    games = [0]*300000
    print "Loading games..."
    with open("data/games.csv") as f:
        gsv = csv.reader(f, delimiter=';', quotechar='"')
        for parts in gsv:
            if not parts or parts[0][0] == "i": continue
            g = Game(int(parts[0]))
            g.pack_id = int(parts[3])
            g.map_id = int(parts[4])
            g.time = int(parts[5])
            g.players = int(parts[6])
            g.rated = int(parts[7])
            games[g.id] = g

    print "Loading game details..."
    i = 1
    while exists("data/game_details"+str(i)+".csv"):
        with open("data/game_details"+str(i)+".csv") as f:
            gsv = csv.reader(f, delimiter=';', quotechar='"')
            for parts in gsv:
                if not parts or parts[0][0] == "g": continue
                game_id = int(parts[0])
                if not games[game_id]: continue
                gd = Game_Detail(game_id, int(parts[2]))
                gd.user_id = int(parts[1])
                gd.ping = int(parts[3])
                gd.tribe = int(parts[4])
                gd.status = int(parts[5], 16)
                gd.length = int(parts[8])
                gd.start_allies = int(parts[9])
                gd.end_allies = int(parts[10])
                gd.fights_won = int(parts[11])
                gd.fights_lost = int(parts[12])
                gd.followers_killed = int(parts[13])
                gd.buildings_destroyed = int(parts[14])
                gd.shamans_killed = int(parts[15])
                gd.followers_lost = int(parts[16])
                gd.buildings_lost = int(parts[17])
                gd.shaman_deaths = int(parts[18])
                gd.pop0 = int(parts[19])
                gd.pop1 = int(parts[20])
                gd.pop2 = int(parts[21])
                gd.pop3 = int(parts[22])
                games[gd.game_id][gd.player] = gd
        i += 1
    return games

def load_pkl_data(fn):
    print "Loading game data from",fn
    with open(fn, 'rb') as f:
        games = pickle.load(f)
    return games

def get_1v1(games):    
    new_games = [0]*300000
    for game in games:
        if game and len(game.winners) == 1 and len(game.losers) == 1 and game.rated == 0:
            new_games[game.id] = game
##    print "Storing game data..."
##    with open('data-1v1.pkl', 'wb') as f:
##        pickle.dump(new_games, f)
    return new_games

def filt_1v1(games):
    return [game for game in games
            if game and game.rated == 0 \
            and len(game.winners) == 1 and len(game.losers) == 1]

def get_2v2(games):    
    new_games = [0]*300000
    for game in games:
        if game and len(game.winners) == 2 and len(game.losers) == 2 and game.rated == 0:
            new_games[game.id] = game
##    print "Storing game data..."
##    with open('data-2v2.pkl', 'wb') as f:
##        pickle.dump(new_games, f)
    return new_games

def filt_2v2(games):
    return [game for game in games
            if game and game.rated == 0 \
            and len(game.winners) == 2 and len(game.losers) == 2]

def get_all(games):
    new_games = [0]*300000
    for game in games:
        if game and len(game.winners) == len(game.losers) and game.rated == 0:
            new_games[game.id] = game
##    print "Storing game data..."
##    with open('data.json', 'wb') as f:
##        json.dump(new_games, f)
    return new_games

def filt_all(games):
    return [game for game in games
            if game and game.rated == 0 and \
            len(game.winners) == len(game.losers)]

def ratio(feature, game, inverse):
    winsum = sum([feature(u) for u in game.winners])
    losesum = sum([feature(u) for u in game.losers])
    if inverse:
        if winsum == 0: return 1.0
        return max(min(1.0*losesum/winsum, 3), -3)
    if losesum == 0: return 1.0
    return max(min(1.0*winsum/losesum, 3), -3)
    

def store_game_details(fn, games):
    feats = [ lambda u: u.fights_won,
              lambda u: u.fights_lost,
              lambda u: u.followers_killed,
              
              lambda u: u.buildings_destroyed,
              lambda u: u.followers_lost,
              lambda u: u.buildings_lost,
              lambda u: u.shamans_killed,
              lambda u: u.shaman_deaths]
    minval = min([g.value for g in games])
    maxval = max([g.value for g in games])
    di = maxval - minval
    with open(fn+'.csv', 'r') as f1:
        with open(fn+'2.csv', 'wb') as f:
            f.write("game_id,user_id,map,length,fights_won,fights_lost,followers_killed,"+\
                    "buildings_destroyed,shamans_killed,followers_lost,buildings_lost,shaman_deaths,"+\
                    "fights_wonr,fights_lostr,followers_killedr,buildings_destroyedr,shamans_killedr,"+\
                    "followers_lostr,buildings_lostr,shaman_deathsr,"+\
                    "fights_wonri,fights_lostri,followers_killedri,buildings_destroyedri,shamans_killedri,"+\
                    "followers_lostri,buildings_lostri,shaman_deathsri,value,good\n")
            f1.readline()
            for game in games:
                val = (game.value - minval)/di
                good = game.value >= 0
                ratios = [ratio(feature, game, False) for feature in feats]
                ratios += [ratio(feature, game, True) for feature in feats]
                for u in game:
                    if not u: continue
                    line = f1.readline()
                    if not line or not u.fights_won: continue
                    data = [game.id,u.user_id,game.pack_id*16+game.map_id, u.length,u.fights_won,u.fights_lost,u.followers_killed,u.buildings_destroyed,
                            u.shamans_killed,u.followers_lost,u.buildings_lost,u.shaman_deaths]
                    data += ratios

                    parts = line.split(",")
                    val = parts[-2]
                    good = parts[-1].strip()
                    data += [val, good]
                    f.write(",".join([str(d) for d  in data])+"\n")


ggames = 0
def process_games(games, leaguein, skip=0):
    league = leaguein.__class__()
    if ggames: games = ggames
    correct = 0
    total = 0
    for game in games:
        if not game or game.rated != 0 or game.id == skip: continue
        
        # predict results
        if league.predict(game):
            correct += 1
        total += 1

        # process game
        league.process(game)

    return 1.0*correct/total


def exclusion_test(games, league):
    global ggames
    ggames = games
    minval = 0
    maxval = 0
    t = time.time()
    baseline = process_games(games, league)
    print "Baseline:",baseline
##    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
##    with concurrent.futures.ProcessPoolExecutor(max_workers=8) as executor:
##        future_to_game_id = {executor.submit(process_games, 0, league, game.id): game for game in games[:1000]}
##        for future in concurrent.futures.as_completed(future_to_game_id):
##            game = future_to_game_id[future]
##            score = future.result()
##            game.value = baseline - score
##            minval = min(minval, game.value)
##            maxval = max(maxval, game.value)
##            print game.id, game.value
    for game in games[50000:50000]:
        score = process_games(games, league, game.id)
        game.value = baseline - score
        minval = min(minval, game.value)
        maxval = max(maxval, game.value)
        print game.id, game.value
    print baseline - process_games(games, league)
    print "Time:",time.time()-t
    print "Min:",minval
    print "Max:",maxval
            
    print "Storing game data..."
    store_game_details('data-1v1', games[:50000])
##    with open('data-1v1.pkl', 'wb') as f:
##        pickle.dump(games, f)

def run_tests(games, league):
    print "%15s" % (league.name),
    print process_games(filt_all(games), league),
    print process_games(filt_1v1(games), league),
    print process_games(filt_2v2(games), league)

def best_factor(games, weights, weight):
    # baseline
    score = process_games(games, WeightedTS.WeightedTSLeague(weights+[weight]))
    factor = weight[1]
    new_weight = weight[:]
    #print
    #print weight, score

    # check higher
    change = 1.1
    new_weight[1] = factor*change
    #change = 0.1
    #new_weight[1] = factor+change
    new_score = process_games(games, WeightedTS.WeightedTSLeague(weights+[new_weight]))
    #print new_weight, new_score
    if new_score < score:
        change = 0.9
        #change = -0.1
        
        # check lower
        new_weight[1] = factor+change
        new_score = process_games(games, WeightedTS.WeightedTSLeague(weights+[new_weight]))
    factor *= change
    #factor += change

    # keep increasing factor until it's not as good
    #print new_weight, new_score
    while new_score > score:
        score = new_score
        weight = new_weight[:]
        
        factor *= change
        #factor += change
        new_weight[1] = factor
        new_score = process_games(games, WeightedTS.WeightedTSLeague(weights+[new_weight]))
        #print new_weight, new_score
    return weight, factor, score

def best_weights(games, weights, feature_factors, feature_use):
    best_weight = [0,0]
    best_score = 0.0
    base_score = 0.0
    for feat in range(0,len(WeightedTS.WeightedTSLeague.features_funcs)):
        for winner in range(2):
            for inv in range(2):
                if not feature_use[feat][winner][inv]: continue
                factor = feature_factors[feat][winner][inv]
                weight = [feat, factor, inv, winner]
                weight, factor, score = best_factor(games, weights, weight)
                print weight, score
                feature_factors[feat][winner][inv] = factor
                if score > best_score:
                    best_score = score
                    best_weight = weight[:]
                if feat == 0:
                    base_score = score

                # don't try features that won't help at all
                #if score < base_score:
                #    feature_use[feat][winner][inv] = False
    return best_weight, best_score

def calc_feature_weights(games):
    games = get_1v1(games)
    feature_factors = [[[1.0,1.0],[1.0,1.0]]
                       for feat in range(0,len(WeightedTS.WeightedTSLeague.features_funcs))]
    # first round of feature factors (saves some time)
    feature_use = [[[True, True],[True, True]]
                   for feat in range(0,len(WeightedTS.WeightedTSLeague.features_funcs))]
    
    weight = []
    weights = []
    while weight not in weights:
        if weight: weights.append(weight)
        weight,b = best_weights(games, weights, feature_factors, feature_use)
        print "Best:"
        print weight,b
        print weights+[weight]
        print

def run_test(games):
    reload(WeightedElo)
    reload(WeightedTS)
    reload(rankers)
    reload(glicko)
    
    #print len(filt_all(games)), len(filt_1v1(games)), len(filt_2v2(games))
    #run_tests(games, rankers.TrueSkillLeague())
    #run_tests(games, rankers.EloLeague())
    #run_tests(games, WeightedElo.WeightedEloLeague([[9, 0.59, 0, 0], [0, 1.06, 0, 1]]))
    #print process_games(get_2v2(games), WeightedTS.WeightedTSLeague([[0, 0, 0, 0]]))
    #print process_games(get_all(games), WeightedTS.WeightedTSLeague([[16, 0.4, 1, 0], [6, -0.3, 1, 0]]))
    #print best_factor(games, [], 16, 0.0, 1)
    #run_tests(games, rankers.TraditionalLeague())
    #run_tests(games, rankers.SimpleLeague())
    #run_tests(games, rankers.EloLeague())
    #run_tests(games, glicko.GlickoLeague())
    #run_tests(games, rankers.TrueSkillLeague())
    #print process_games(filt_1v1(games), rankers.EloLeague())
    #exclusion_test(filt_1v1(games), rankers.EloLeague())
    print process_games(filt_all(games), WeightedTS.WeightedTSLeague())
    #print process_games(get_1v1(games), WeightedTS.WeightedTSLeague([[9, 0.59, 0, 0]]))
    #calc_feature_weights(filt_1v1(games))
    

    
if __name__ == "__main__":
    ##t = time.time()
    #games = load_csv_data() # ~35s
    ##games = load_pkl_data('data.pkl') # ~125s 
    #games = load_pkl_data('data/data-1v1.pkl') # ~13s 
    ##games = load_pkl_data('data-2v2.pkl') # ~46s 
    ##print "Time:",time.time()-t

    ##games = get_all(games)
    ##games = get_1v1(games)
    ##games = get_2v2(games)
    ##
    ##run_tests(games, TraditionalLeague())
    ##run_tests(games, SimpleLeague())
    ##run_tests(games, EloLeague())
    ##run_tests(games, GlickoLeague())
    ##run_tests(games, TrueSkillLeague())

    ##factors = [0.9, 1.0, 1.1, 1.5]
    ##for i in range(0,12):
    ##    for f in factors:
    ##        run_tests(games, WeightedEloLeague(i,f))
    games = load_csv_data()
    run_test(games)

            
