/*Senaryo: Depo sorumlusu geldi ve "Fiyatı 50 dolardan pahalı olan ürünlerin listesini ver, en pahalı en üstte olsun" dedi.*/
SELECT ProductName, UnitPrice from
Products
where UnitPrice>50
order by UnitPrice DESC

/*Senaryo: Satış müdürü soruyor: "Hangi ülkeden kaç müşterimiz var? En çok müşterimiz olan ülkeyi bilmek istiyorum."*/
SELECT COUNT(CustomerID) as MüşteriSayısı, Country
from Customers
group by Country
order by MüşteriSayısı DESC

/*Bana sipariş veren şirketlerin isimleri ve sipariş tarihlerini dök." 
Sıkıntı şu: Şirket ismi Customers tablosunda, Sipariş tarihi Orders tablosunda. İkisini birbirine bağlaman (Dikiş atman) lazım.*/
SELECT c.CompanyName, o.orderDate
from Customers c 
inner join Orders o on c.CustomerID= o.CustomerID
ORDER BY O.OrderDate DESC;

/*Senaryo: "Bana Müşteri Adını, Sipariş Tarihini, Aldığı Ürünü ve Kaç Adet aldığını listele." */
SELECT c.CompanyName, o.orderDate, od.Quantity,od.UnitPrice, p.ProductName
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od  on o.OrderID = od.OrderID
inner join Products p on od.ProductID=p.ProductID

/*Patron geldi ve dedi ki: "En çok ciro (para) yapan satış temsilcimiz kim? Prim vereceğiz.*/
SELECT E.FirstName+' '+E.LastName as FullName, 
COUNT(DISTINCT O.OrderID)      AS ToplamSiparisSayisi, -- Kaç farklı sipariş almış?
FORMAT(SUM(od.UnitPrice * od.Quantity), 'C', 'en-US') AS ToplamCiro -- Para formatında göster
from Employees E
inner join Orders o on E.EmployeeID=o.EmployeeID
inner join [Order Details] od on o.OrderID=od.OrderID
GROUP BY E.FirstName, E.LastName
ORDER BY SUM(od.UnitPrice * od.Quantity) DESC;

/*Sisteme kaydolmuş ama henüz hiç sipariş vermemiş müşterileri (Potansiyel Müşteri) bana listele. */

SELECT c.CompanyName
from Customers c
left join Orders o on c.CustomerID=o.CustomerID
WHERE o.OrderID IS NULL;

/*Senaryo: Şirkette herkesin sürekli ihtiyaç duyduğu "Hangi siparişi, hangi müşteri vermiş, hangi çalışan ilgilenmiş ve tutarı ne kadar?" sorusunu tek bir paket haline getirelim.*/
GO
CREATE VIEW Vw_SatisRaporu AS
SELECT c.CompanyName,E.FirstName+' '+E.LastName as Employee, O.OrderID, O.OrderDate, P.ProductName, od.UnitPrice,od.Quantity, od.Quantity * od.UnitPrice AS Total, cat.CategoryName
from Customers c
inner join Orders o on c.CustomerID=o.CustomerID
inner join Employees E on E.EmployeeID=o.EmployeeID
inner join [Order Details] od on o.OrderID=od.OrderID
inner join Products p on od.ProductID=p.ProductID
inner join Categories cat on p.CategoryID=cat.CategoryID


SELECT * FROM Vw_SatisRaporu
WHERE ProductName = 'Chai';

/*Soru: "Nancy Davolio (Çalışan) toplam ne kadarlık satış yapmış?" (Eskiden 4 tablo birleştirirdik, şimdi tek satır):*/

SELECT Employee,SUM(TOTAL) AS CİRO FROM Vw_SatisRaporu
WHERE Employee = 'Nancy Davolio'
GROUP BY Employee

/* Enflasyon geldi! Patron dedi ki: "İstediğim kategoriye, istediğim oranda zam yapacak bir sistem kur. Tek tek uğraşmayalım.*/
GO
CREATE PROCEDURE Sp_FiyatGuncelle
(
    @KategoriID INT,   -- Dışarıdan gelecek 1. bilgi
    @ZamOrani FLOAT    -- Dışarıdan gelecek 2. bilgi (Örn: 1.10 = %10 zam)
)
AS
BEGIN
    UPDATE Products
    SET UnitPrice = UnitPrice * @ZamOrani
    WHERE CategoryID = @KategoriID;
    PRINT 'Fiyatlar başarıyla güncellendi!';
END;
EXEC Sp_FiyatGuncelle 1, 2.0;
/* Prosedürleri akıllı yapan şey mantıktır. Senaryo: Patron dedi ki: "Bir kategoriye zam yapmadan önce bak. 
Eğer o kategorideki en pahalı ürün zaten 100 doları geçiyorsa zam yapma! Müşteriyi kaçırmayalım.*/
ALTER PROCEDURE Sp_FiyatGuncelle
(
	@KategoriID INT,
	@ZamOrani FLOAT
)
AS
BEGIN
DECLARE @EnPahaliUrun MONEY;

SELECT @EnPahaliUrun = MAX(UnitPrice)
from Products
where CategoryID = @KategoriID
	IF @EnPahaliUrun>100
	BEGIN
PRINT 'DUR! Bu kategoride zaten çok pahalı ürünler var. Zam İptal.';
END
    ELSE
	BEGIN
	UPDATE Products
    SET UnitPrice = UnitPrice * @ZamOrani
    WHERE CategoryID = @KategoriID;
    PRINT 'Fiyatlar başarıyla güncellendi!';
	END
END;

SELECT ProductName, UnitPrice FROM Products WHERE CategoryID = 1;
EXEC Sp_FiyatGuncelle 1, 1.10;

/*ID'si 1 olan çalışanın (Nancy) Adını ve Soyadını bulup, ekrana "Aradığınız kişi: Nancy Davolio" yazdıralım.*/
DECLARE @Ad NVARCHAR(20);
DECLARE @Soyad NVARCHAR(20);
DECLARE @TamIsim NVARCHAR(50);
SELECT 
    @Ad = FirstName, 
    @Soyad = LastName 
FROM Employees 
WHERE EmployeeID = 1;
SET @TamIsim = @Ad + ' ' + @Soyad;
PRINT 'Aradığınız Kişi Bulundu: ' + @TamIsim;

/*Değişkenlerle matematik yapmak. Senaryo: Bir ürünün fiyatını alacağız, 
üzerine %18 KDV ekleyip "Etiket Fiyatı"nı hesaplayacağız. Veritabanındaki veriyi değiştirmeden sadece hesap yapacağız.*/
DECLARE @urunAdi NVARCHAR(50);
DECLARE @unitPrice INT;
DECLARE @sellingPrice INT;
SELECT
	@urunAdi = ProductName,
	@unitPrice = UnitPrice
from Products
where ProductID = 1
SET @sellingPrice=@unitPrice*1.18;
PRINT 'Ürün: ' + @UrunAdi;
PRINT 'Raf Fiyatı: ' + CAST(@unitPrice AS NVARCHAR(20)); 
PRINT 'KDV Dahil Fiyat: ' + CAST(@sellingPrice AS NVARCHAR(20));

/*Senaryo: Ekrana 1'den 5'e kadar sayı saydıralım.*/
DECLARE @Sayac INT;
SET @Sayac = 1;
WHILE @Sayac <= 5
BEGIN
    PRINT CAST(@Sayac AS NVARCHAR(10));
       SET @Sayac = @Sayac + 1;
END

PRINT 'Döngü bitti!';

/*@StokDurumu diye bir tamsayı (INT) değişkeni tanımla.
Products tablosunda ID'si 11 olan ürünün (UnitsInStock) stok bilgisini bu değişkene ata.
IF kullanarak kontrol et:
Eğer stok 10'dan azsa ekrana "ACİL! Sipariş verilmeli." yazdır.
Değilse "Stok durumu iyi, sorun yok." yazdır.*/
DECLARE @StokDurumu INT;
SELECT @StokDurumu=UnitsInStock
from Products
where ProductID=11
IF @StokDurumu<10
PRINT'ACİL! Sipariş verilmeli';
ELSE
PRINT'Stok durumu iyi, sorun yok.'

/*Her sorguda Fiyat * 1.18 yazmaktan yorulduk. Buna bir fonksiyon yazalım, biz ona ham fiyatı verelim, o bize KDV'li fiyatı geri atsın.*/
GO
CREATE FUNCTION Fn_KDVHesapla
(
    @HamFiyat MONEY 
)
RETURNS MONEY       
AS
BEGIN
    DECLARE @Sonuc MONEY;
    SET @Sonuc = @HamFiyat * 1.18;
    RETURN @Sonuc;
END;

SELECT 
    ProductName, 
    UnitPrice AS HamFiyat, 
    dbo.Fn_KDVHesapla(UnitPrice) AS KDVliFiyat -- Kendi yazdığın fonksiyon!
FROM Products;

/* Senaryo:
Stok miktarı 50'den fazlaysa ürün "İndirimli" kategorisine girsin (%10 indirim).
50'den azsa fiyat aynı kalsın.*/
GO
CREATE FUNCTION Fn_IndirimliFiyat
(
@Stok INT,
@Fiyat MONEY
)
RETURNS MONEY
AS
BEGIN
DECLARE @YeniFiyat MONEY;
IF @Stok>50
SET @YeniFiyat=@Fiyat*0.90
ELSE
SET @YeniFiyat=@Fiyat
RETURN @YeniFiyat;
End;

SELECT 
    ProductName, 
    UnitsInStock AS Stok,
    UnitPrice AS EskiFiyat,
    dbo.Fn_IndirimliFiyat(UnitsInStock, UnitPrice) AS YeniFiyat 
FROM Products
ORDER BY UnitsInStock DESC;

CREATE INDEX IX_SiparisTarihi
ON Orders (OrderDate);

/*Silinen Siparişleri Yakalayan Trigger */
CREATE TRIGGER Trg_SiparisSilinince
ON Orders
AFTER DELETE -- Olay: SİLME işleminden SONRA çalış
AS
BEGIN
    -- 'deleted' adlı sanal tablodan veriyi alıp log tablosuna atıyoruz
    INSERT INTO SilinenSiparisLoglari (SiparisID, SilenKullanici, SilinmeTarihi)
    SELECT OrderID, SYSTEM_USER, GETDATE()
    FROM deleted; -- SQL Server silinen satırı geçici olarak 'deleted' tablosunda tutar

    PRINT 'Bir sipariş silindi ve kayıt altına alındı!';
END;
-- 1. Önce siparişin içindeki kalemleri sil
DELETE FROM [Order Details] WHERE OrderID = 10248;
-- 2. Şimdi siparişin kendisini sil (Trigger burada devreye girecek)
DELETE FROM Orders WHERE OrderID = 10248;
SELECT * FROM SilinenSiparisLoglari;

/*İki tarih arasını verdiğimizde, o tarihlerde satış yapan personellerin performansını döken bir fonksiyon yaz.*/
CREATE FUNCTION Fn_PersonelPerformansGetir
(
	@startDate DATE,
	@endDate DATE
)
RETURNS TABLE
AS
RETURN
(
SELECT E.FirstName+' '+E.LastName as Employee,COUNT(O.OrderID) AS ToplamSiparisSayisi,FORMAT(SUM(OD.Quantity *OD.UnitPrice), 'C', 'en-US') AS ToplamCiro
from Employees E
inner join Orders O on E.EmployeeID=O.EmployeeID
inner join [Order Details] OD on O.OrderID=OD.OrderID
WHERE O.OrderDate BETWEEN @startDate AND @endDate
GROUP BY E.FirstName, E.LastName
);
SELECT * FROM dbo.Fn_PersonelPerformansGetir('1997-01-01', '1997-12-31')
ORDER BY ToplamSiparisSayisi DESC;
/*Fiyat Değişim Geçmişi*/
create table FiyatDegisimLoglari
(
LogID INT IDENTITY(1,1) PRIMARY KEY,
    UrunID INT,
    UrunAdi NVARCHAR(50),
    EskiFiyat MONEY,
    YeniFiyat MONEY,
    DegistirenKisi NVARCHAR(50),
    DegisimTarihi DATETIME
);

CREATE TRIGGER Trg_FiyatTakip
on Products
After update
as
begin
IF UPDATE(UnitPrice)
BEGIN
INSERT INTO FiyatDegisimLoglari (UrunID, UrunAdi, EskiFiyat, YeniFiyat, DegistirenKisi, DegisimTarihi)
SELECT
	i.ProductID,
	i.ProductName, 
    d.UnitPrice,  
	i.UnitPrice,  
	SYSTEM_USER,
	GETDATE()
    FROM inserted i
	INNER JOIN deleted d ON i.ProductID = d.ProductID;
	PRINT 'Fiyat değişikliği tespit edildi ve loglandı.';
    END
END;

UPDATE Products SET UnitPrice = 25 WHERE ProductID = 1;
SELECT * FROM FiyatDegisimLoglari;


/*Ürünlerin önem derecesini belirlemek istiyoruz.*/
CREATE VIEW Vw_UrunPerformansAnalizi AS
SELECT 
    P.ProductName,
    C.CategoryName,
    SUM(D.Quantity * D.UnitPrice) AS ToplamCiro,
    
    -- Ciroya göre sıralama yapıp 1, 2, 3 diye grup numarası veriyoruz (NTILE)
    NTILE(3) OVER (ORDER BY SUM(D.Quantity * D.UnitPrice) DESC) AS CiroGrubu
FROM Products P
JOIN [Order Details] D ON P.ProductID = D.ProductID
JOIN Categories C ON P.CategoryID = C.CategoryID
GROUP BY P.ProductName, C.CategoryName;

SELECT * FROM Vw_UrunPerformansAnalizi
WHERE CiroGrubu = 1; -- 1: En yüksek ciro, 3: En düşük ciro

SELECT * FROM Musteri_Segmentleri ORDER BY ToplamHarcama DESC;