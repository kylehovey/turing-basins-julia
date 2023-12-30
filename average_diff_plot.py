import numpy as np
import matplotlib.pyplot as plt
from environment import data_directory, params

'''
Use this file for generating plots of the sorted average differences
in entropy vectorizations for all rules in a given dataset.
'''

print("Loading data...")
data = np.load(f'{data_directory}/data.npy')
print(f"Loaded data of shape {data.shape}")

# Use n_initial_conditions that has been set based on dthresh or threshhold
# Remember to handle steps correctly from params, as it's extracted and converted to an integer
average_diffs = np.array([np.diff(x.reshape((params['n_initial_conditions'], params['steps'])), axis=1).mean() for x in data])
sorted_diffs = sorted(average_diffs)
plt.plot(sorted_diffs)

# Setting the title and axis labels
plt.title("Sorted Average Entropy Discrete Differences")
plt.xlabel("Index")
plt.ylabel("Bytes/Step")

# Save the plot with labels and title
plt.savefig(f"{data_directory}/average_diffs.png")
