import numpy as np
import json
from environment import data_directory

if __name__ == "__main__":
    out_file = '{}/embedding.json'.format(data_directory)
    embedding = np.load('{}/embedding.npy'.format(data_directory))
    target = np.load('{}/targets.npy'.format(data_directory))
    diffs = np.load('{}/average_diffs.npy'.format(data_directory))

    print (embedding.max(axis=0))
    print (embedding.min(axis=0))

    out = [{ "rule": int(rule), "diff": round(diff, 3), "loc": list(map(lambda x: round(float(x), 3), location)) } for rule, location, diff in zip(target, embedding, diffs)]

    with open(out_file, 'w') as out_file:
        json.dump(out, out_file)
