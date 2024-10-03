import os
import pandas as pd

# Wurzelverzeichnis, in dem die Ordner JN.1_JN.2 etc. liegen
root_dir = '/home/vincent/Downloads/vaccine'

# Liste der Lineages, einschließlich Wuhan-Hu-1, der keinen eigenen Ordner hat
lineages1 = ['Wuhan-Hu-1', 'JN.1', 'JN.2', 'JN.3', 'KP.3', 'XBB.1.5', 'KP.2']
lineages2 = ['JN.1', 'JN.2', 'JN.3', 'KP.3', 'XBB.1.5', 'KP.2']
lineages3 = ['Wuhan-Hu-1', 'KP.2']
# Erstelle eine leere Matrix, um die Werte zu speichern

def create_empty_matrix(name):
    # Erstelle eine leere DataFrame mit den Lineages als Zeilen und Spalten
    df = pd.DataFrame('', index=lineages3, columns=lineages1)
    
    # Speichere die DataFrame als CSV
    df.to_csv(name, index_label='')

def update_csv_values(source_file, target_file):
    # 1. CSV-Dateien einlesen
    source_df = pd.read_csv(source_file, index_col=0)  # Erste Datei (Quellenwerte)
    target_df = pd.read_csv(target_file, index_col=0)  # Zweite Datei (Zielwerte)
    
    # 2. Über jede Zeile und Spalte in der ersten Datei (source_df) iterieren
    for row_index, row in source_df.iterrows():
        for col_name, cell_value in row.items():
            # 3. Den Wert aus der source_df in die entsprechende Position in target_df einfügen
            if row_index in target_df.index and col_name in target_df.columns:
                target_df.at[row_index, col_name] = cell_value
                print(f"Wert für Zeile '{row_index}' und Spalte '{col_name}' ist '{cell_value}'.")
            else:
                print(f"Wert für Zeile '{row_index}' und Spalte '{col_name}' konnte nicht gefunden werden.")
    
    # 4. Das aktualisierte DataFrame in die gleiche Datei zurückschreiben
    target_df.to_csv(target_file)
    print(f"Die Datei '{target_file}' wurde erfolgreich aktualisiert und gespeichert.")


# Funktion, um die Datei aus einem Ordner zu laden und die Werte an der richtigen Position einzutragen
def fill_combined_matrix(merged_matrix, name):
    for i in range(len(lineages2)):
        for j in range(i, len(lineages2)):
            lineage_1 = lineages2[i]
            lineage_2 = lineages2[j]
            # Für die anderen Kombinationen: Namen des Ordners (z.B. JN.1_JN.2 oder JN.2_JN.1)
            #folder_name = f'{lineage_1}_{lineage_2}' #if lineage_1 < lineage_2 else f'{lineage_2}_{lineage_1}'
            #folder_path = os.path.join(root_dir, folder_name)

            if os.path.exists(os.path.join(root_dir, f'{lineage_1}_{lineage_2}')):
                folder_name = f'{lineage_1}_{lineage_2}' #if lineage_1 < lineage_2 else f'{lineage_2}_{lineage_1}'
                folder_path = os.path.join(root_dir, folder_name)
                # CSV-Datei im entsprechenden Ordner laden
                csv_file = os.path.join(folder_path, name)
                
                if os.path.exists(csv_file):
                    update_csv_values(csv_file, merged_matrix)
                else:
                    print(f'CSV-Datei fehlt in {folder_path}')
            elif os.path.exists(os.path.join(root_dir, f'{lineage_2}_{lineage_1}')):
                folder_name = f'{lineage_2}_{lineage_1}' #if lineage_1 < lineage_2 else f'{lineage_2}_{lineage_1}'
                folder_path = os.path.join(root_dir, folder_name)
                # CSV-Datei im entsprechenden Ordner laden
                csv_file = os.path.join(folder_path, name)
                
                if os.path.exists(csv_file):
                    update_csv_values(csv_file, merged_matrix)
                else:
                    print(f'CSV-Datei fehlt in {folder_path}')
            
            else:
                print(f'Ordner {lineage_1}_{lineage_2} und {lineage_2}_{lineage_1} existiert nicht.')

# Speichere die kombinierte Matrix
antis = ['A', 'B', 'C', 'D1', 'D2', 'E3', 'E12', 'F1', 'F2', 'F3', 'NTD']
for i in antis:
        
    name = "major_Cross_React_AB_"+i+".csv"
    merged_matrix="merged_"+name
    create_empty_matrix(merged_matrix)
    fill_combined_matrix(merged_matrix, name)


    print("Die kombinierte Matrix wurde erfolgreich erstellt und gespeichert.")
