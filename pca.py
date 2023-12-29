import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA

# Change to the currently active data directory
data_directory = "CHANGEME"

print("Loading data...")
data = np.load(f'{data_directory}/data.npy')
print(f"Loaded data of shape {data.shape}")

(_, n_components) = np.shape(data)

pca = PCA(n_components=n_components)
pca.fit(data)

# Create a subplot grid of 2 rows and 1 column
fig, ax = plt.subplots(2, 1, figsize=(12, 12))  # Adjust the figure size as needed

# First subplot for explained variance
ax[0].plot(pca.explained_variance_, label='Explained Variance', color='blue')
ax[0].set_yscale('log')
ax[0].set_xlabel('Principal Component Index')
ax[0].set_ylabel('Explained Variance (log scale)')
ax[0].set_title('Explained Variance by Principal Components')
ax[0].legend()

pca_display_count = 5

# Create a plotting color map
colors = plt.cm.hsv(np.linspace(0.3, 1, pca_display_count))

# Second subplot for the first 20 principal component vectors
for i in range(pca_display_count):
    ax[1].plot(pca.components_[i], label=f'PC {i+1}', color=colors[i])
ax[1].set_xlabel('Principal Component Index')
ax[1].set_ylabel('Principal Component Value')
ax[1].set_title('First 5 Principal Components')

# Create a custom legend for the second subplot
custom_lines = [plt.Line2D([0], [0], color=colors[i], lw=2) for i in range(pca_display_count)]
ax[1].legend(custom_lines, [f'PC {i+1}' for i in range(pca_display_count)], loc='upper right', bbox_to_anchor=(1.1, 1))

# Adjust layout to prevent the subplots from overlapping
plt.tight_layout()

# Display the plots
plt.savefig(f"{data_directory}/pca.png")
