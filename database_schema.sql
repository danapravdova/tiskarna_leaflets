-- =========================================================================
-- DATABÁZOVÉ SCHÉMA: TISKÁRNA LEAFLETS (STAR SCHEMA NÁVRH)
-- Projekt: End-to-End analytika farmaceutické tiskárny
-- Soubor: database_schema.sql
-- =========================================================================

CREATE DATABASE IF NOT EXISTS `tiskarna_leaflets` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_czech_ci;
USE `tiskarna_leaflets`;

-- =========================================================================
-- 1. DIMENZE: Číselník farmaceutických zakázek a klientů
-- =========================================================================
CREATE TABLE `dim_zakazky` (
  `id_zakazky` VARCHAR(20) NOT NULL,
  `klient` VARCHAR(100) NOT NULL,
  `nazev_leku` VARCHAR(100) NOT NULL,
  `Cena_Zakazky_Celkem` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id_zakazky`),
  INDEX `idx_klient` (`klient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 2. DIMENZE: Číselník tiskových strojů (Heidelberg vs. Xerox)
-- =========================================================================
CREATE TABLE `dim_stroje` (
  `id_stroje` VARCHAR(10) NOT NULL,
  `nazev_stroje` VARCHAR(50) NOT NULL,
  `typ_stroje` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`id_stroje`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 3. DIMENZE: Číselník tiskařů a mzdových sazeb
-- =========================================================================
CREATE TABLE `dim_zamestnanci` (
  `id_zamestnance` VARCHAR(10) NOT NULL,
  `jmeno` VARCHAR(100) NOT NULL,
  `pozice` VARCHAR(50) NOT NULL,
  `hodinova_sazba_zaklad` DECIMAL(10,2) NOT NULL,
  `priplatek_sobota_procento` DECIMAL(5,2) DEFAULT 0.00,
  `priplatek_svatek_procento` DECIMAL(5,2) DEFAULT 0.00,
  `priplatek_prescas_procento` DECIMAL(5,2) DEFAULT 0.00,
  `priplatek_nocni_procento` DECIMAL(5,2) DEFAULT 20.00,
  PRIMARY KEY (`id_zamestnance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 4. DIMENZE: Katalog skladového materiálu (papíru)
-- =========================================================================
CREATE TABLE `dim_sklad_material` (
  `id_papiru` VARCHAR(10) NOT NULL,
  `nazev_papiru` VARCHAR(100) NOT NULL,
  `aktualni_stav_archu` INT(11) DEFAULT 0,
  `cena_za_arch_czk` DECIMAL(10,4) NOT NULL,
  PRIMARY KEY (`id_papiru`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 5. DIMENZE: Harmonizovaný časový kalendář
-- =========================================================================
CREATE TABLE `dim_kalendar` (
  `datum` DATE NOT NULL,
  `rok` INT(11) NOT NULL,
  `nazev_mesice` VARCHAR(20) NOT NULL,
  `poradi_mesice_klic` INT(11) NOT NULL,
  PRIMARY KEY (`datum`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 6. TABULKA FAKTŮ: Skladové zásoby a analýza stárnutí ležáků
-- =========================================================================
CREATE TABLE `fact_sklad_zasoby` (
  `id_papiru` VARCHAR(10) NOT NULL,
  `id_zakazky` VARCHAR(20) DEFAULT NULL,
  `datum_posledniho_vydeje` DATE NOT NULL,
  `mnozstvi_archu_skladem` INT(11) NOT NULL,
  `dny_bez_pohybu_k_datu` INT(11) NOT NULL,
  PRIMARY KEY (`id_papiru`),
  KEY `fk_zasoby_zakazky` (`id_zakazky`),
  CONSTRAINT `fk_zasoby_material` FOREIGN KEY (`id_papiru`) REFERENCES `dim_sklad_material` (`id_papiru`),
  CONSTRAINT `fk_zasoby_zakazky` FOREIGN KEY (`id_zakazky`) REFERENCES `dim_zakazky` (`id_zakazky`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;

-- =========================================================================
-- 7. TABULKA FAKTŮ: Výrobní transakční záznamy a audit kvality
-- =========================================================================
CREATE TABLE `fact_vyrobni_zaznamy_tisk` (
  `id_zaznamu` INT(11) NOT NULL AUTO_INCREMENT,
  `id_stroje` VARCHAR(10) NOT NULL,
  `id_zakazky` VARCHAR(20) NOT NULL,
  `id_papiru` VARCHAR(10) NOT NULL,
  `id_hlavni_tiskar` VARCHAR(10) NOT NULL,
  `datum_smeny` DATE NOT NULL,
  `typ_smeny` VARCHAR(20) DEFAULT NULL,
  `je_mimoradna_sobota` TINYINT(1) DEFAULT 0,
  `pocet_hodin_prescasu_smena` DECIMAL(4,2) DEFAULT 0.00,
  `vytisteno_archu_celkem` INT(11) DEFAULT 0,
  `zmetky_spatny_soutisk` INT(11) DEFAULT 0,
  `zmetky_spatny_orez` INT(11) DEFAULT 0,
  `zmetky_spatne_slovo` INT(11) DEFAULT 0,
  `prostoje_hodiny` DECIMAL(5,2) DEFAULT 0.00,
  `provozni_naklady_smena_czk` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id_zaznamu`),
  KEY `fk_tisk_stroje` (`id_stroje`),
  KEY `fk_tisk_zakazky` (`id_zakazky`),
  KEY `fk_tisk_material` (`id_papiru`),
  KEY `fk_tisk_zamestnanci` (`id_hlavni_tiskar`),
  KEY `fk_tisk_kalendar` (`datum_smeny`),
  CONSTRAINT `fk_tisk_stroje` FOREIGN KEY (`id_stroje`) REFERENCES `dim_stroje` (`id_stroje`),
  CONSTRAINT `fk_tisk_zakazky` FOREIGN KEY (`id_zakazky`) REFERENCES `dim_zakazky` (`id_zakazky`),
  CONSTRAINT `fk_tisk_material` FOREIGN KEY (`id_papiru`) REFERENCES `dim_sklad_material` (`id_papiru`),
  CONSTRAINT `fk_tisk_zamestnanci` FOREIGN KEY (`id_hlavni_tiskar`) REFERENCES `dim_zamestnanci` (`id_zamestnance`),
  CONSTRAINT `fk_tisk_kalendar` FOREIGN KEY (`datum_smeny`) REFERENCES `dim_kalendar` (`datum`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_czech_ci;
