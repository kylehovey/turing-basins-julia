import numpy as np
import pandas as pd

print("Loading data...")
data = np.array(pd.read_csv("data.csv")).T
targets = np.array(pd.read_csv("targets.csv")).reshape(262144)
print("Loaded data of shape {}".format(data.shape))
print("Loaded targets of shape {}".format(targets.shape))
np.save("data.npy", data)
np.save("targets.npy", targets)
