import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

DB_CONFIG = {
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "dbname": os.getenv("DB_NAME")
}

DATABASE_URL = (
    f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
    f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"
)

engine = create_engine(DATABASE_URL)
DATA_DIR = './data'

def ingest_data():
    """Ingère les fichiers CSV du dossier /data vers PostgreSQL en normalisant les noms de tables."""
    files = [f for f in os.listdir(DATA_DIR) if f.endswith('.csv')]
    
    if not files:
        print("Aucun fichier CSV trouvé dans le répertoire source.")
        return

    for file in files:
        # Nettoyage du nom de fichier pour obtenir un nom de table standardisé
        table_name = f"stg_{file.replace('.csv', '').replace('olist_', '').replace('_dataset', '')}"
        
        try:
            df = pd.read_csv(os.path.join(DATA_DIR, file))
            
            # Normalisation des headers : passage en minuscule et remplacement des espaces par des underscores
            df.columns = [c.lower().replace(' ', '_') for c in df.columns]
            
            # Chargement dans la base de données (remplace la table si elle existe déjà)
            df.to_sql(table_name, engine, if_exists='replace', index=False)
            
            print(f"Table '{table_name}' mise à jour avec succès ({len(df)} lignes).")
            
        except Exception as e:
            print(f"Erreur lors de l'ingestion de {file}: {e}")

if __name__ == "__main__":
    ingest_data()
