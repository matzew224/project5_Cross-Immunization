import os
import pymol
from pymol import cmd
from pathlib import Path

def color_mutations(cif_file, mutation_file, output_dir):
    # Load the protein structure from the .cif file
    cmd.load(cif_file)

    # Set residues to be slightly translucent (non-mutated residues)
    cmd.show_as("cartoon")
    cmd.set("transparency", 0.5, "all")

    mutation_log = []

    # Read the mutation file and apply the mutations
    with open(mutation_file, 'r') as f:
        for line in f:
            line = line.strip()
            if len(line) < 4 or not line[1:-1].isdigit():
                print(f"Invalid mutation format: {line}")
                continue

            original_aa = line[0]
            position = int(line[1:-1])
            mutated_aa = line[-1]

            # PyMOL uses three-letter codes, so we need to convert
            one_to_three = {
                'A': 'ALA', 'C': 'CYS', 'D': 'ASP', 'E': 'GLU', 'F': 'PHE',
                'G': 'GLY', 'H': 'HIS', 'I': 'ILE', 'K': 'LYS', 'L': 'LEU',
                'M': 'MET', 'N': 'ASN', 'P': 'PRO', 'Q': 'GLN', 'R': 'ARG',
                'S': 'SER', 'T': 'THR', 'V': 'VAL', 'W': 'TRP', 'Y': 'TYR'
            }

            original_aa_3l = one_to_three.get(original_aa.upper())
            mutated_aa_3l = one_to_three.get(mutated_aa.upper())

            if not original_aa_3l or not mutated_aa_3l:
                print(f"Invalid amino acid code: {line}")
                continue

            # Select the residue at the given position
            selection = f"(resi {position} and name CA)"

            # Verify  residue is the expected AA
            resi_name = cmd.get_fastastr(f"(resi {position})")[0]

            if original_aa_3l not in resi_name:
                print(f"Warning: Expected {original_aa_3l} at position {position}, but found {resi_name}")
                continue

            # Color the mutated residue red
            cmd.color("red", selection)

            # Log for exporting to .cfg file
            mutation_log.append(f"Mutation at position {position}: {original_aa_3l} -> {mutated_aa_3l}\n")

    # Make  non-mutated residues slightly translucent
    cmd.set("transparency", 0.5, "not resi " + " ".join(str(position)))

    # Ensure output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Write mutation log to .cfg file
    cfg_file = os.path.join(output_dir, "mutations.cfg")
    with open(cfg_file, 'w') as cfg:
        cfg.writelines(mutation_log)

    print(f"Mutation results saved to {cfg_file}")

    # Refresh PyMOL view
    cmd.zoom()

# Example usage
if __name__ == "__main__":
    cif_file = Path("data/JN-1.cif")
    mutation_file = "downloads/stripped/mutation_JN.1_stripped.txt"
    output_dir = "data/marked_" + cif_file.name

    # Initialize PyMOL and run the color mutations script
    pymol.finish_launching()
    color_mutations(cif_file, mutation_file, output_dir)
    pymol.cmd.quit()
