import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine

# --- AYARLAR ---
# Senin sunucu adın (Python'da \ işareti özel olduğu için çift \\ koyuyoruz)
SERVER_NAME = 'EMIRHAN\\SQLEXPRESS' 
DATABASE_NAME = 'Northwind'

# Bağlantı Sihirli Cümlesi (Connection String)
# Windows Authentication (Trusted_Connection=yes) kullanıyoruz
connection_string = f"mssql+pyodbc://{SERVER_NAME}/{DATABASE_NAME}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"

try:
    # Motoru Çalıştır
    engine = create_engine(connection_string)
    print("✅ SQL Server bağlantısı başarılı!")

    # --- 1. AŞAMA: SQL'DEN VERİ ÇEKME (READ) ---
    print("📥 Veriler çekiliyor...")
    query = """
    SELECT ProductID, ProductName, UnitPrice, UnitsInStock, CategoryID 
    FROM Products
    """
    df = pd.read_sql(query, engine)
    
    # Ekrana ilk 5 satırı basalım ki görelim
    print(f"Çekilen Satır Sayısı: {len(df)}")
    print(df.head())

    # --- 2. AŞAMA: PYTHON İLE ANALİZ (PROCESS) ---
    print("\n⚙️ Analiz yapılıyor (Stok Riski Hesaplanıyor)...")
    
    # Basit bir analiz: Stok değeri (Fiyat * Adet) ve Kritik Stok Durumu
    df['ToplamStokDegeri'] = df['UnitPrice'] * df['UnitsInStock']
    
    # Pandas ile mantıksal işlem (SQL'deki CASE WHEN gibi)
    # Stok 10'dan azsa 'ACİL', 20'den azsa 'KRİTİK', yoksa 'NORMAL' yazalım
    def risk_hesapla(stok):
        if stok < 10: return 'ACİL SİPARİŞ'
        elif stok < 20: return 'KRİTİK SEVİYE'
        else: return 'NORMAL'
    
    df['StokDurumu'] = df['UnitsInStock'].apply(risk_hesapla)

    # Sadece riskli olanları filtreleyelim
    df_rapor = df[df['StokDurumu'] != 'NORMAL']
    
    # Raporu görelim
    print("⚠️ Riskli Ürünler Listesi:")
    print(df_rapor[['ProductName', 'StokDurumu', 'UnitsInStock']].head())

    # --- 3. AŞAMA: SQL'E GERİ YAZMA (WRITE) ---
    print("\n📤 Sonuçlar SQL'e 'Python_Stok_Raporu' tablosu olarak yazılıyor...")
    
    # if_exists='replace': Tablo varsa silip yeniden yaratır.
    # index=False: Pandas'ın satır numaralarını kaydetme.
    df_rapor.to_sql('Python_Stok_Raporu', engine, if_exists='replace', index=False)
    
    print("✅ İŞLEM TAMAM! SSMS'e gidip 'Python_Stok_Raporu' tablosunu kontrol et.")

except Exception as e:
    print("\n❌ HATA OLUŞTU:")
    print(e)
    print("\nİPUCU: 'ODBC Driver 17 for SQL Server' hatası alırsan sürücü yüklü olmayabilir.")