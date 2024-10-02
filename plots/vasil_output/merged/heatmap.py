import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Verzeichnis mit den CSV-Dateien
directory = '/home/vincent/sarsProject/project5_Cross-Immunization/plots/vasil_output/merged'

# Gehe durch jede Datei im Verzeichnis
for filename in os.listdir(directory):
    if filename.endswith(".csv"):
        file_path = os.path.join(directory, filename)
        substring = filename.split('_')[-1].split('.')[0]
        # Lese die CSV-Datei ein
        data = pd.read_csv(file_path)

        # Setze die erste Spalte als Index (Varianten)
        data_cleaned = data.set_index(data.columns[0])

        # Erstelle eine Heatmap
        plt.figure(figsize=(10, 8))
        sns.heatmap(data_cleaned, annot=True, cmap="coolwarm", linewidths=.5, cbar_kws={'label': 'Cross Reactivity'})
        plt.title(f'Cross-Resistance to {substring} (log10)', fontsize=16)
        plt.xlabel('Variant')
        plt.ylabel('Variant')

        # Speichername für das PNG
        output_file = os.path.join(directory, f"{filename[:-4]}_heatmap.png")

        # Heatmap speichern
        plt.tight_layout()
        plt.savefig(output_file)
        plt.close()

print("Heatmaps wurden erfolgreich für alle CSV-Dateien erstellt und gespeichert.")
