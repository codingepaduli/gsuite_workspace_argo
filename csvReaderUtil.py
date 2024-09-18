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
            csv_reader_first_line = csv.reader(file)
            first_row = next(csv_reader_first_line)
            fieldCount = len(first_row);
            previousRowArray =  [""] * fieldCount;
            
            csv_reader = csv.reader(file)
            for row in csv_reader:
                
                for index in range(len(row)):
                    field = row[index] if row[index] != "" else previousRowArray[index]
                    previousRowArray[index] = field

                print(f"{previousRowArray}")
                    
                
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
    print(f"Aprendo il file: {file_path}")
    read_csv_file(file_path)

if __name__ == "__main__":
    main()