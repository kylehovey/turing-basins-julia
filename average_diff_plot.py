import numpy as np
import matplotlib.pyplot as plt
from dotenv import dotenv_values
import re

'''
Use this file for generating plots of the sorted average differences
in entropy vectorizations for all rules in a given dataset.
'''

config = dotenv_values(".env")

data_directory = config["DATA_DIR"]

# Extract parameters using regex
params_pattern = r"steps-(?P<steps>\d+)_size-(?P<size>\d+)_dthresh-(?P<dthresh>[0-9.]+)_averages-(?P<averages>\d+)"
match = re.search(params_pattern, data_directory)

# If the pattern matches, create the params dictionary
if match:
    params = {key: float(val) if '.' in val else int(val) for key, val in match.groupdict().items()}
else:
    raise ValueError("The data directory does not contain the required parameters in the expected format.")

print("Loading data...")
data = np.load(f'{data_directory}/data.npy')
print(f"Loaded data of shape {data.shape}")

n_initial_conditions = round(1/params['dthresh']) + 1

average_diffs = np.array([np.diff(x.reshape((n_initial_conditions, params['steps'])), axis=1).mean() for x in data])
sorted_diffs = sorted(average_diffs)
plt.plot(sorted_diffs)

# Setting the title and axis labels
plt.title("Sorted Average Entropy Discrete Differences")
plt.xlabel("Index")
plt.ylabel("Bytes/Step")

# Save the plot with labels and title
plt.savefig(f"{data_directory}/average_diffs.png")
