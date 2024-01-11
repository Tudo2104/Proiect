
CREATE TABLE login (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL
);
INSERT INTO login (email, password) VALUES ('ana', 'tudo');
select * from login ;


ALTER TABLE login
ADD COLUMN role VARCHAR(50) NOT NULL DEFAULT 'user';


-- a) Creare tabelă pentru relația Furnizori
CREATE TABLE Furnizori (
  idf INT PRIMARY KEY, -- Cheia primară pentru identificarea unică a furnizorilor
  numef VARCHAR(50),   -- Numele furnizorului
  adresa VARCHAR(100)  -- Adresa furnizorului
);

-- b) Creare tabelă pentru relația Piese
CREATE TABLE Piese (
  idp INT PRIMARY KEY,  -- Cheia primară pentru identificarea unică a pieselor
  numep VARCHAR(50),    -- Numele piesei
  culoare VARCHAR(20)   -- Culoarea piesei
);

-- c) Creare tabelă pentru relația Catalog
CREATE TABLE Catalog (
  idf INT,                  -- Cheie străină pentru idf din Furnizori
  idp INT,                  -- Cheie străină pentru idp din Piese
  pret DECIMAL(10, 2),      -- Pretul piesei în catalog
  PRIMARY KEY (idf, idp),   -- Cheia primară compusă din idf și idp
  FOREIGN KEY (idf) REFERENCES Furnizori(idf), -- Cheie străină pentru idf
  FOREIGN KEY (idp) REFERENCES Piese(idp)      -- Cheie străină pentru idp
);

-- d) Creare tabelă pentru relația Comenzi
CREATE TABLE Comenzi (
  idc INT,                  -- Identificator unic pentru comanda
  idf INT,                  -- Cheie străină pentru idf din Furnizori
  idp INT,                  -- Cheie străină pentru idp din Piese
  cantitate INT,           -- Cantitatea de piese comandate
  PRIMARY KEY (idc, idf, idp),   -- Cheie primară compusă din idc, idf, și idp
  FOREIGN KEY (idf) REFERENCES Furnizori(idf), -- Cheie străină pentru idf
  FOREIGN KEY (idp) REFERENCES Piese(idp)      -- Cheie străină pentru idp
);


ALTER TABLE Catalog ADD COLUMN moneda VARCHAR(3);

ALTER TABLE Catalog
ADD CONSTRAINT positive_pret CHECK (pret >= 0);

ALTER TABLE Piese
ADD CONSTRAINT piulita_constraint CHECK (
  NOT (numep LIKE '%piuliță%' AND culoare <> 'alb') 

);


-- ex 1

DELIMITER //

CREATE PROCEDURE FilterFurnizoriByLastDigit(IN lastDigit CHAR(1))
BEGIN
    SELECT *
    FROM Furnizori
    WHERE SUBSTR(adresa, -1) = lastDigit
    ORDER BY adresa;
END //

DELIMITER ;

-- ex 2

DELIMITER //

CREATE PROCEDURE GetComenziByCantitateExcluding(
  IN cantitateMin INT,
  IN cantitateExclude INT
)
BEGIN
  SELECT *
  FROM Comenzi
  WHERE cantitate > cantitateMin AND cantitate <> cantitateExclude;
END //

DELIMITER ;

-- ex 3

DELIMITER //

CREATE PROCEDURE GetComenziByPriceRangeAndCurrency(
  IN minimum DECIMAL(10, 2),
  IN maximum DECIMAL(10, 2),
  IN currency VARCHAR(50)
)
BEGIN
  SELECT *
  FROM Comenzi c
  JOIN Catalog t ON c.idf = t.idf AND c.idp = t.idp
  WHERE t.pret >= minimum AND t.pret <= maximum AND t.moneda = currency;
END //

DELIMITER ;


-- ex 4 
DELIMITER //

CREATE PROCEDURE GetDistinctSupplierPairsBySameOrder(
  IN piesaId INT,
  IN cantitate INT
)
BEGIN
  SELECT c1.idf AS idf1, c2.idf AS idf2
  FROM Comenzi c1
  JOIN Comenzi c2 ON c1.idp = piesaId AND c2.idp = piesaId
  WHERE c1.cantitate = cantitate AND c2.cantitate = cantitate
    AND c1.idc < c2.idc
  GROUP BY idf1, idf2
  HAVING COUNT(*) = 1;
END //

DELIMITER ;


  -- ex 5
  
  DELIMITER //

CREATE PROCEDURE FurnizoriCuToatePiesele(IN furnizor_id INT)
BEGIN
    SELECT DISTINCT F.numef
    FROM Furnizori F
    JOIN Catalog C1 ON F.idf = C1.idf
    WHERE F.idf != furnizor_id
    AND NOT EXISTS (
        SELECT 1
        FROM Catalog C2
        WHERE C2.idf = furnizor_id
        AND C2.idp NOT IN (
            SELECT C3.idp
            FROM Catalog C3
            WHERE C3.idf = F.idf
        )
    );
END //

DELIMITER ;
-- ex 6
  
  DELIMITER //

CREATE PROCEDURE GetMaxPricedPiece()
BEGIN
  SELECT idp, numep, culoare
  FROM Piese
  WHERE idp = (
    SELECT idp
    FROM Catalog c1
    WHERE NOT EXISTS (
      SELECT 1
      FROM Catalog c2
      WHERE c2.pret > c1.pret
    )
    ORDER BY idp DESC
    LIMIT 1
  );
END //

DELIMITER ;

-- ex 7 
SELECT idf, moneda, MIN(pret), MAX(pret) from Catalog GROUP BY idf, moneda;

-- ex 8
DELIMITER //

CREATE PROCEDURE CountDistinctPiecesPerOrder()
BEGIN
  SELECT idc, SUM(cantitate) AS suma_totala_piese
  FROM (
    SELECT idc, idp, MAX(cantitate) AS cantitate
    FROM Comenzi
    GROUP BY idc, idp
  ) AS distinct_pieces
  GROUP BY idc;
END //

DELIMITER ; 



