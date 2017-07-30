max_bytes = 50000000

with open("data/game_details.csv") as f:
    i = 0
    written_bytes = max_bytes +1
    fo = 0
    head = ""
    last_line = ""
    for line in f:
        if not head:
            head = line
            continue
        if written_bytes >= max_bytes:
            if fo: fo.close()
            i += 1
            fo = open("data/game_details"+str(i)+".csv", "w")
            written_bytes = len(head)
            fo.write(head)
            if last_line:
                fo.write(last_line)
                written_bytes += len(last_line)
            last_line = ""
                
            
        if written_bytes + len(line) > max_bytes:
            last_line = line
        else:
            fo.write(line)
        written_bytes += len(line)
    fo.close()
                
