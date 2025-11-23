import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# 1. BAĞLANTI (Standart)
SERVER_NAME = 'EMIRHAN\\SQLEXPRESS'
DATABASE_NAME = 'Northwind'
connection_string = f"mssql+pyodbc://{SERVER_NAME}/{DATABASE_NAME}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
engine = create_engine(connection_string)

# 2. SQL'DEN VERİYİ ÖZETLEYEREK ÇEK (GROUP BY)
# SQL'in hamallığını SQL'e yaptırıyoruz, Python'a özet veri çekiyoruz.
query = """
SELECT 
    C.CategoryName, 
    SUM(P.UnitsInStock) as ToplamStok
FROM Products P
JOIN Categories C ON P.CategoryID = C.CategoryID
GROUP BY C.CategoryName
"""
df = pd.read_sql(query, engine)

# 3. PYTHON İLE GÖRSEL OLUŞTURMA (Matplotlib)
print("🎨 Grafik çiziliyor...")

# Grafik boyutunu ayarla
plt.figure(figsize=(10, 6))

# Bar grafiği çiz (X ekseni: Kategori, Y ekseni: Stok)
plt.bar(df['CategoryName'], df['ToplamStok'], color='teal')

# Süslemeler
plt.title('Kategorilere Göre Toplam Stok Durumu', fontsize=14)
plt.xlabel('Kategori', fontsize=12)
plt.ylabel('Stok Adedi', fontsize=12)
plt.xticks(rotation=45) # Yazılar sığsın diye eğiyoruz

# 4. KAYDETME (Otomasyon Kısmı)
dosya_adi = "Gunluk_Stok_Raporu.png"
plt.tight_layout() # Kenar boşluklarını düzelt
plt.savefig(dosya_adi)

print(f"✅ Rapor oluşturuldu: {dosya_adi}")
print("Klasörünü kontrol et, orada bir resim dosyası var!")