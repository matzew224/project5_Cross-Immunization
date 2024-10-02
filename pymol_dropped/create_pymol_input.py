import os
from Bio import SeqIO

def translate_dna_to_protein(fasta_file, output_dir):
    # Parse the fasta file and get the DNA sequence
    record = SeqIO.read(fasta_file, "fasta")
    AA_seq = record.seq.translate()
    # SeqIO.write(AA_seq, output_dir + "/reference_AA_seq.txt", "pir")
    with open(output_dir + "/reference_AA_seq.txt", 'w') as f:
        f.write(str(AA_seq))
    return AA_seq

def apply_mutations(protein_seq, mutation_profile):
    deletion_mutations = []
    for mutation in mutation_profile.split():
        if mutation.startswith('del'):
            deletion_mutations.append(mutation)
        else:
            pos = int(mutation[1:-1])
            original_aa = mutation[0]
            new_aa = mutation[-1]
            if protein_seq[pos-1] == original_aa:
                protein_seq = protein_seq[:pos-1] + new_aa + protein_seq[pos:]
            else:
                print(f"Warning: Expected {original_aa} at position {pos}, found {protein_seq[pos-1]}")
    for mutation in deletion_mutations:
        start, end = map(int, mutation[3:].split('/'))
        protein_seq = protein_seq[:start - 1] + protein_seq[end:]
    return protein_seq

def process_files(fasta_file, txt_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    protein_seq = translate_dna_to_protein(fasta_file, output_dir)

    for txt_file in os.listdir(txt_dir):
        if txt_file.endswith(".txt"):
            with open(os.path.join(txt_dir, txt_file)) as f:
                mutations = f.read().strip()
            mutated_protein = apply_mutations(protein_seq, mutations)
            outname = txt_file.replace("__stripped", "_AA-seq")
            with open(os.path.join(output_dir, outname), 'w') as out_f:
                out_f.write(str(mutated_protein))

if __name__ == "__main__":
    import argparse

    # Command line argument parsing
    parser = argparse.ArgumentParser(description="Generate mutated amino acid sequences from a reference genome and mutation profiles.")
    parser.add_argument("--fasta_file", help="Path to the reference genome in FASTA format",
                        default="./SARS-CoV-2_wuhan-hu-1.fasta")
    parser.add_argument("--txt_dir", help="Directory containing mutation profile TXT files",
                        default="./downloads/stripped")
    parser.add_argument("--output_dir", help="Directory to save the mutated amino acid sequences",
                        default="./pymol_input")

    args = parser.parse_args()

    # Run the processing function with provided arguments
    process_files(args.fasta_file, args.txt_dir, args.output_dir)
