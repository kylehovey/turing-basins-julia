import numpy as np
import pandas as pd

print("Loading data...")
df = np.array(pd.read_csv("targets.csv")).reshape(262144)
print("Loaded data of shape {}".format(df.shape))
np.save("targets.npy", df)
