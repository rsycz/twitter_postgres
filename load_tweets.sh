#!/bin/sh

# list all of the files that will be loaded into the database
# for the first part of this assignment, we will only load a small test zip file with ~10000 tweets
# but we will write are code so that we can easily load an arbitrary number of files
files='
test-data.zip
'

echo 'load normalized'
for file in $files; do
    python3 load_tweets.py \
        --db postgresql://postgres:pass@localhost:10992 \
        --inputs $file
done

echo 'load denormalized'
for file in $files; do
    unzip -p $file | python3 -c "
import sys
import json
import re
for line in sys.stdin:
    line = line.strip()
    if line:
        tweet = json.loads(line)
        out = json.dumps(tweet)
        out = re.sub(r'\\\\u0000', '', out)
        out = re.sub(r'\\u0000', '', out)
        print(out)
" | psql postgresql://postgres:pass@localhost:1099 -c "\COPY tweets_jsonb (data) FROM STDIN WITH (FORMAT csv, quote e'\x01', delimiter e'\x02')"
done
