import sys
import csv
import array

def read_csv_file(file_path):
    """Legge un file CSV con una caratteristica speciale"""
    """Se un campo in una riga non è presente, ricorda 
          quello della riga precedente
    """

    try:
        with open(file_path, 'r') as file:
            # Flusso di lettura e scrittura del file
            csv_reader = csv.reader(file)
            csv_writer = csv.writer(sys.stdout)

            # Leggo l'intestazione del file CSV
            first_row = next(csv_reader)
            csv_writer.writerow(first_row)
            
            # Conto il numero di campi
            fieldCount = len(first_row);
            previousRowArray =  [""] * fieldCount;

            # Leggo le righe coi dati
            for row in csv_reader:
                
                for index in range(len(row)):
                    field = row[index] if row[index] != "" else previousRowArray[index]
                    previousRowArray[index] = field

                csv_writer.writerow(previousRowArray)
                
    except FileNotFoundError:
        print(f"Errore: Il file {file_path} non è stato trovato.")
    except csv.Error as e:
        print(f"Errore CSV: {e}")

def main():
    """Metodo main"""

    if len(sys.argv) != 2:
        print("Uso: python script.py <nome_del_file>")
        sys.exit(1)

    file_path = sys.argv[1]
    read_csv_file(file_path)

if __name__ == "__main__":
    main()