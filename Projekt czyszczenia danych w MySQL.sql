SELECT *
FROM employee_records;

-- Tworzę nowy TABLE, aby na nim pracować i mieć porównanie końcowe

CREATE TABLE clean_table
LIKE employee_records;

SELECT *
FROM clean_table;

INSERT clean_table
SELECT *
FROM employee_records;

-- Zczynam pracować na clean_table

-- Kolumna Date jest wadliwa i należy ją usunąć

ALTER TABLE clean_table
DROP Date;

-- Heidi (szusta kolumna) na nieprawidłowe ID

UPDATE clean_table
SET ID = 6
WHERE `Name` = 'Heidi' AND `Age` = '30' AND `Salary` = '60000';

-- Upewniam się że unikalnych ID jest tyle samo co wierszy (czyli 100)

SELECT COUNT(DISTINCT(ID))
FROM clean_table;

-- Zmieniam JoinDate z typu int na date

SELECT *
FROM clean_table;

ALTER TABLE clean_table ADD COLUMN JoinDate_new DATE;

UPDATE clean_table
SET JoinDate_new = STR_TO_DATE(CAST(JoinDate AS CHAR), '%Y%m%d');

ALTER TABLE clean_table DROP COLUMN JoinDate;

ALTER TABLE clean_table CHANGE COLUMN JoinDate_new JoinDate DATE;

-- Teraz pozbywam się duplikatów

SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Name`, Age, Email, Salary, JoinDate) AS row_num
FROM clean_table;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Name`, Age, Email, Salary, JoinDate) AS row_num
FROM clean_table
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Można ręcznie usunąć duplikat, ale gdyby było ich więcej, to zajeło by to
-- dużo czasu, zatem napiszę polecenia jakbym usuwał duplikaty hurtowo

-- Tworzę kolejny table

CREATE TABLE `clean_table2` (
  `ID` int DEFAULT NULL,
  `Name` text,
  `Age` text,
  `Email` text,
  `Salary` text,
  `JoinDate` date DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO clean_table2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Name`, Age, Email, Salary, JoinDate) AS row_nu
FROM clean_table;

SELECT *
FROM clean_table2;

DELETE
FROM clean_table2
WHERE row_num > 1;

SELECT COUNT(ID)
FROM clean_table2;

-- Tworzę kolejny table

CREATE TABLE `clean_table3` (
  `ID` int DEFAULT NULL,
  `Name` text,
  `Age` text,
  `Email` text,
  `Salary` text,
  `JoinDate` date DEFAULT NULL,
  `row_num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO clean_table3
SELECT *
FROM clean_table2;

SELECT *
FROM clean_table3;

SELECT COUNT(ID)
FROM clean_table3;

ALTER TABLE clean_table3 DROP COLUMN row_num;

-- Puste wiersze wypełniam wartościami null
-- oraz używam polecenia trim dla pewności

UPDATE clean_table3
SET
	`Name` = TRIM(`Name`),
    Age = TRIM(Age),
    Email = TRIM(Email),
    Salary = TRIM(Salary),
    JoinDate = TRIM(JoinDate);
    
UPDATE clean_table3
SET Age = NULL
WHERE Age = '';

UPDATE clean_table3
SET Email = NULL
WHERE Email = '';

UPDATE clean_table3
SET Salary = NULL
WHERE Salary = '';

SELECT *
FROM clean_table3;

-- Teraz chcę usunąć dziury wśród ID, które powstały
-- z powodu skasowania zduplikowanego wiersza oraz
-- posegregować całość względem ID rosnąco

-- Tworzę nowy table

CREATE TABLE `temp_clean_table3` (
  `ID` int AUTO_INCREMENT PRIMARY KEY,
  `Name` text,
  `Age` text,
  `Email` text,
  `Salary` text,
  `JoinDate` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO temp_clean_table3 (`Name`, Age, Email, Salary, JoinDate)
SELECT `Name`, Age, Email, Salary, JoinDate
FROM clean_table3
ORDER BY ID ASC;

ALTER TABLE temp_clean_table3 RENAME TO finish_clean_table;

-- Ostateczny wynik
SELECT *
FROM finish_clean_table;

SELECT *
FROM employee_records;

-- Opcjonalnie dodaję indeksy (w tym przypadku akurat ich nie
-- potrzeba, ale gdyby baza danych była większa, to należało by

CREATE INDEX idx_name ON clean_table3 (`Name`);
CREATE INDEX idx_age ON clean_table3 (Age);
CREATE INDEX idx_email ON clean_table3 (Email);
CREATE INDEX idx_salary ON clean_table3 (Salary);
CREATE INDEX idx_joindate ON clean_table3 (JoinDate);
