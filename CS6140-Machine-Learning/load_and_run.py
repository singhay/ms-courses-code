import sys
import test
import traceback


games = None
if __name__ == "__main__":
    #games = test.filt_all(test.load_csv_data())
    games = test.filt_all(test.load_pkl_data('data/data-1v1.pkl'))
    while True:
        try:
            test.run_test(games)
        except Exception, err:
            traceback.print_exc()
        print "Press enter to re-run the script, CTRL-C to exit"
        sys.stdin.readline()
        reload(test)
