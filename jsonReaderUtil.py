import json
import sys
import csv

def main():
    try:
        # Legge tutto l'input da stdin
        json_data = sys.stdin.read()

        # Parsa il JSON
        dati = json.loads(json_data)

        # Scrive l'output CSV su stdout
        csv_writer = csv.writer(sys.stdout)

        if type(dati) is dict:
            # Scrive l'intestazione (chiavi del primo elemento)
            csv_writer.writerow(dati.keys())
            # Scrive i dati
            csv_writer.writerow(dati.values())

        if type(dati) is list:
            # Scrive l'intestazione (chiavi del primo elemento)
            csv_writer.writerow(dati[0].keys())

            # Scrive i dati
            for item in dati:
                csv_writer.writerow(item.values())

    except json.JSONDecodeError:
        print("Errore: L'input non è un JSON valido.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Errore inaspettato: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
