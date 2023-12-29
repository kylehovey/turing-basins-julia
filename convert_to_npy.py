import numpy as np
import pandas as pd

# Change to the currently active data directory
data_directory = "CHANGEME"

print("Loading data...")
data = np.array(pd.read_csv("{}/data.csv".format(data_directory))).T
targets = np.array(pd.read_csv("{}/targets.csv".format(data_directory))).reshape(262144)
print("Loaded data of shape {}".format(data.shape))
print("Loaded targets of shape {}".format(targets.shape))
np.save("{}/data.npy".format(data_directory), data)
np.save("{}/targets.npy".format(data_directory), targets)
