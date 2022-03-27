import requests
import json
import re
import os
import sys

weight_name = sys.argv[1]

SAMPLE = None
BLOCK = None

re_result = re.search('b([0-9]+)', weight_name, re.IGNORECASE)
if re_result and re_result.group(1):
    BLOCK=re_result.group(1)
re_result = re.search('([0-9]+)b', weight_name, re.IGNORECASE)
if re_result and re_result.group(1):
    BLOCK=re_result.group(1)
re_result = re.search('([0-9]{3,})', weight_name, re.IGNORECASE)
if re_result and re_result.group(1):
    SAMPLE=re_result.group(1)
if BLOCK == None:
    BLOCK='40'
use_new=False
if re.search('-new', weight_name, re.IGNORECASE) is not None:
    use_new=True
if SAMPLE == None:
    # find the strongest network in the first 5 pages
    url = "https://katagotraining.org/api/networks/?format=json"
    pageNum=0
    max_elo=-1
    while True:
        for i in range(3):
            try:
                response = requests.get(url=url)
                break
            except:
                if i == 2:
                    print('cannot connect to the server at this time')
                    sys.exit(1)
        next_page = response.json()['next']
        if next_page:
            url = next_page+"&format=json"
        infos = response.json()['results']
        for info in infos:
            pattern='kata1-b'+BLOCK
            model_name = info['name']
            re_result = re.search(pattern, model_name, re.IGNORECASE)
            if re_result is None:
                continue
            elo=info['log_gamma']
            if elo is None:
                continue
            if elo < max_elo:
                continue
            max_elo=elo
            re_result2 = re.search('s([0-9]{3,})', model_name, re.IGNORECASE)
            if re_result2 and re_result2.group(1):
                SAMPLE=re_result2.group(1)
            if use_new:
                break
        if use_new and SAMPLE is not None:
            break
        pageNum=pageNum+1
        if pageNum > 3: 
            break
if SAMPLE is None:
    print('failed to find weight for block: ' + BLOCK)
    sys.exit(1)

url = "https://katagotraining.org/api/networks/?format=json"
use_model=None
use_model_url=None
while True:
    for i in range(3):
        try:
            response = requests.get(url=url)
            break
        except:
            if i == 2:
                print('cannot connect to the server at this time')
                sys.exit(1)
    next_page = response.json()['next']
    if next_page:
        url = next_page+"&format=json"
    infos = response.json()['results']
    for info in infos:
        pattern='kata1-b'+BLOCK+'.*s'+SAMPLE
        model_name = info['name']
        re_result = re.search(pattern, model_name, re.IGNORECASE)
        if re_result is None:
            continue
        use_model=model_name
        use_model_url=info['model_file']
        print('using model: ' + use_model)
        print('using use_model_url: ' + use_model_url)
        break
    if use_model is not None:
        break
if use_model is None:
    print('failed to find weight for block: ' + BLOCK + ' and sample: ' + SAMPLE)
    sys.exit(1)
model_path = './data/weights/' + BLOCK + 'b.bin.gz'
command = 'wget '+use_model_url+' -O '+model_path
for i in range(3):
    try:
        os.system(command)
        break
    except:
        if i == 2:
            print('failed downloading network')
            #os.system('touch not_done')
            sys.exit(1)
