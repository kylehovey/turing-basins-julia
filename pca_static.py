import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from dotenv import dotenv_values

'''
Use this file for generating PCA charts treating dataset as 1D vectors. For
varied initial condition data, the slices will be concatenated into a single
vector and you will see the slices in the PCA's that are found. To get a better
representation, generate a surface plot of the PCA's for varied initial conditions.
'''

config = dotenv_values(".env")

data_directory = config["DATA_DIR"]

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

# Enable horizontal grid lines for the first subplot
ax[0].grid(True, which='both', axis='y', linewidth=0.5, color='gray')

pca_display_count = 5

# Create a plotting color map
colors = plt.cm.hsv(np.linspace(0.3, 1, pca_display_count))

# Define line styles for principal components
line_styles = ['-', '--', '-.', ':', (0, (3, 5, 1, 5))]

# Second subplot for the first 20 principal component vectors
for i in range(pca_display_count):
    ax[1].plot(pca.components_[i], label=f'PC {i+1}', color=colors[i], linestyle=line_styles[i])
ax[1].set_xlabel('Principal Component Index')
ax[1].set_ylabel('Principal Component Value')
ax[1].set_title('First 5 Principal Components')

# Create a custom legend for the second subplot with line styles
custom_lines = [plt.Line2D([0], [0], color=colors[i], linestyle=line_styles[i], lw=2) for i in range(pca_display_count)]
ax[1].legend(custom_lines, [f'PC {i+1}' for i in range(pca_display_count)], loc='upper right', bbox_to_anchor=(1.1, 1))

# Adjust layout to prevent the subplots from overlapping
plt.tight_layout()

# Display the plots
plt.savefig(f"{data_directory}/pca.png")
