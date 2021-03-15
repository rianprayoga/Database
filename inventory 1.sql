CREATE DATABASE inventory

USE inventory 

CREATE TABLE pemasok(
	id_pemasok CHAR(10)NOT NULL CONSTRAINT pk_pemasok_id_pemasok PRIMARY KEY ,
	nama_pemasok CHAR(20),
	contact INT,
	status INT CONSTRAINT ck_pemasok_status CHECK(status = 1 OR status = 0)  
)

CREATE TABLE kategori(
	id_kategori CHAR(10) NOT NULL CONSTRAINT pk_kategori_id_kategori PRIMARY KEY,
	nama_kategori CHAR(15) NOT NULL
)

CREATE TABLE rak_barang(
	id_rak CHAR(10) NOT NULL CONSTRAINT pk_rak_id_rak PRIMARY KEY,
	nama_rak CHAR(20) NOT NULL,
	kapasitas_rak INT,
	status INT CONSTRAINT ck_rak_status CHECK(status = 1 OR status = 0)
)

CREATE TABLE pengguna(
	id_user CHAR(10) CONSTRAINT pk_pengguna_id_user PRIMARY KEY,
	nama_user CHAR(20),
	password CHAR(10) NOT NULL,
	level_usr INT CONSTRAINT ck_penggunaa_level CHECK(level_usr = 0 OR level_usr = 1)
)

CREATE TABLE transaksi_masuk(
	idn_masuk CHAR(15) NOT NULL CONSTRAINT pk_transaksi_masuk_idn_masuk PRIMARY KEY,
	id_user CHAR(10) CONSTRAINT fk_transaksi_masuk_id_user FOREIGN KEY REFERENCES pengguna(id_user) 
)

CREATE TABLE detail_masuk(	
	idn_masuk CHAR(15) NOT NULL CONSTRAINT fk_detail_masuk_idn_masuk FOREIGN KEY REFERENCES transaksi_masuk(idn_masuk),
	kode_barang CHAR(10) NOT NULL CONSTRAINT fk_detail_masuk_kode_barang FOREIGN KEY REFERENCES barang(kode_barang),
	jml_masuk INT,
	tgl_masuk DATETIME DEFAULT GETDATE()
)


CREATE TABLE transaksi_keluar(
	idn_keluar CHAR(15) NOT NULL CONSTRAINT pk_transaksi_keluar_idn_keluar PRIMARY KEY,
	id_user CHAR(10) CONSTRAINT fk_transaksi_keluar_id_user FOREIGN KEY REFERENCES pengguna(id_user) 
)

CREATE TABLE detail_keluar(
	idn_keluar CHAR(15) NOT NULL CONSTRAINT fk_detail_masuk_idn_keluar FOREIGN KEY REFERENCES transaksi_keluar(idn_keluar),
	kode_barang CHAR(10) NOT NULL CONSTRAINT fk_detail_keluar_kode_barang FOREIGN KEY REFERENCES barang(kode_barang),
	jml_keluar INT,
	tgl_keluar DATETIME DEFAULT GETDATE()
)

CREATE TABLE barang(
	kode_barang CHAR(10) NOT NULL CONSTRAINT pk_barang_kode_barang PRIMARY KEY,
	nama_barang CHAR(15) NOT NULL,
	jumlah_barang INT,
	id_pemasok CHAR(10) NOT NULL CONSTRAINT fk_barang_id_pemasok FOREIGN KEY REFERENCES pemasok(id_pemasok)
		ON UPDATE CASCADE ON DELETE NO ACTION,
	id_kategori	CHAR(10) NOT NULL CONSTRAINT fk_barang_id_kategori FOREIGN KEY REFERENCES kategori(id_kategori)
		ON UPDATE CASCADE ON DELETE NO ACTION,		
	id_rak CHAR(10) NOT NULL CONSTRAINT fk_barang_id_rak FOREIGN KEY REFERENCES rak_barang(id_rak)
		ON UPDATE CASCADE ON DELETE NO ACTION
)

--------------------------------------- VIEW ----------------------------------------------------
--------------------------------------- VIEW ----------------------------------------------------
CREATE VIEW vTransaksiMasuk AS
	SELECT idn_masuk, dm.kode_barang, nama_barang, jml_masuk FROM
	detail_masuk dm JOIN barang b ON dm.kode_barang = b.kode_barang 
	
CREATE VIEW vTransaksiKeluar AS
	SELECT idn_keluar, dk.kode_barang, nama_barang, jml_keluar FROM
	detail_keluar dk JOIN barang b ON dk.kode_barang = b.kode_barang 

CREATE VIEW vBarang AS
	SELECT kode_barang, nama_barang, jumlah_barang, nama_kategori,nama_rak,kapasitas_rak,
	nama_pemasok 
	FROM barang b JOIN kategori k ON b.id_kategori = k.id_kategori JOIN rak_barang rk
	ON b.id_rak = rk.id_rak JOIN pemasok p ON b.id_pemasok = p.id_pemasok


--INSERT INTO pengguna VALUES ('01','user','123','0')
--INSERT INTO transaksi_masuk VALUES('TM1','01')
--INSERT INTO transaksi_keluar  VALUES('TK1','01')
--INSERT INTO rak_barang VALUES('R01','Rak bolpen','100','0')
--INSERT INTO kategori VALUES('K01','Alat Tulis')
--INSERT INTO pemasok VALUES('PEM01','PT.XYZ',null,null)
--INSERT INTO barang VALUES ('B01','Bolpoin AE07','0','PEM01','K01','R01')
--SELECT * FROM barang


--------------------------------------- FUNCTION & PROCEDURE ----------------------------------------------------

------------------------- fungsi mendapatkan jumlah barang berdasarkan kode_barang -------------------------------
CREATE FUNCTION fcStokBarang(@kdbarang CHAR(5)) RETURNS INT
BEGIN
	DECLARE @stok INT
		SELECT @stok = jumlah_barang FROM barang WHERE kode_barang = @kdbarang
	RETURN @stok
END

-------------------- procedure barang keluar (insert barang keluar ke table detail_keluar) -------------------
CREATE PROCEDURE spKurangBarang @idnkeluar CHAR(10),@kdbarang CHAR(10),@jml INT AS
	DECLARE @stok INT
	EXEC @stok = fcStokBarang @kdbarang
		IF @stok >= @jml	
			INSERT INTO detail_keluar VALUES(@idnkeluar,@kdbarang,@jml,GETDATE())
		ELSE
			ROLLBACK TRANSACTION
	IF @@ERROR = 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

----------------------- fungsi mendapatkan available space rak barang -----------------------------------------
ALTER CREATE FUNCTION fcMaxBarang( @kdbarang CHAR(5) ) RETURNS INT 
BEGIN
	DECLARE @max INT
		SELECT @max =  kapasitas_rak FROM rak_barang r JOIN barang b ON r.id_rak = b.id_rak WHERE kode_barang = @kdbarang  
	DECLARE @stok INT
		SELECT @stok =  jumlah_barang FROM barang WHERE kode_barang = @kdbarang
	RETURN @max - @stok
END

--------------------- procedure barang masuk(insert barang masuk le table detail_masuk)---------------
CREATE PROCEDURE spTambahBarang @idnmasuk CHAR(10),@kdbarang CHAR(10),@jml INT AS
	DECLARE @max INT
	EXEC @max = fcMaxBarang @kdbarang 		
		IF @jml <= @max	
			INSERT INTO detail_masuk VALUES (@idnmasuk,@kdbarang,@jml,GETDATE())
		ELSE 
			ROLLBACK TRANSACTION
	IF	@@ERROR = 0
		COMMIT TRANSACTION
	ELSE		
		ROLLBACK TRANSACTION
-----------------------------------------------------------------------------------------		

--SELECT * FROM detail_masuk
--SELECT * FROM detail_keluar
--SELECT * FROM barang
--SELECT * FROM transaksi_masuk
--SELECT * FROM transaksi_keluar 
--SELECT * FROM rak_barang 
--EXEC spTambahBarang 'TM1','B01','50'
--EXEC spKurangBarang 'TK1','B01','100'
--INSERT INTO detail_keluar VALUES ('TK1','B01','50',GETDATE())
--DELETE FROM detail_keluar  		


--------------------------------------- TRIGGER ----------------------------------------------------
--trigger menambah barang di table barang saat ada insert di detail_masuk
CREATE TRIGGER tgTambahBarang ON detail_masuk FOR INSERT AS 	
  	DECLARE 
		@kdbarang CHAR(5),@jml INT 
	BEGIN TRANSACTION
		SELECT @kdbarang = kode_barang, @jml = jml_masuk   FROM inserted
		UPDATE barang SET jumlah_barang = @jml + jumlah_barang WHERE kode_barang = @kdbarang


--trigger mengurangi barang di table barang saat ada insert di detail_keluar
CREATE TRIGGER tgKurangBarang ON detail_keluar FOR INSERT AS
	DECLARE
		@kdbarang CHAR(5),@jml INT
	BEGIN TRANSACTION 
		SELECT @kdbarang = kode_barang, @jml = jml_keluar   FROM inserted
		UPDATE barang SET jumlah_barang =jumlah_barang - @jml  WHERE kode_barang = @kdbarang

