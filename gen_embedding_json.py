from tqdm import tqdm
import numpy as np
import json

if __name__ == "__main__":
    out_file = './embedding.json'
    embedding = np.load('./embedding.npy')
    target = np.load('./targets.npy')
    diffs = np.load('./average_diffs.npy')

    print (embedding.max(axis=0))
    print (embedding.min(axis=0))

    out = [{ "rule": int(rule), "diff": round(diff, 3), "loc": list(map(lambda x: round(float(x), 3), location)) } for rule, location, diff in zip(target, embedding, diffs)]

    with open(out_file, 'w') as out_file:
        json.dump(out, out_file)
