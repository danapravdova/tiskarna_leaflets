-- ============================================================================
-- DATABÁZOVÉ SCHÉMA: TISKÁRNA LEAFLETS (STAR SCHEMA NÁVRH)
-- Autorka: Seniorní datová analytička
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `tiskarna_leaflets` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_czech_ci;
USE `tiskarna_leaflets`;

-- 1. DIMENZE: Číselník farmaceutických zakázek a klientů
CREATE TABLE `dim_zakazky` (
    `id_zakazky` VARCHAR(20) NOT NULL,
    `klient` VARCHAR(100) NOT NULL,
    `nazev_leku` VARCHAR(150) NOT NULL,
    `Cena_Zakazky_Celkem` DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (`id_zakazky`),
    INDEX `idx_klient` (`klient`)
) ENGINE=InnoDB;

-- 2. DIMENZE: Číselník tiskových strojů (Heidelberg vs. Xerox)
CREATE TABLE `dim_stroje` (
    `id_stroje` VARCHAR(10) NOT NULL,
    `nazev_stroje` VARCHAR(100) NOT NULL,
    `typ_technologie` ENUM('Ofset', 'Digitál') NOT NULL,
    PRIMARY KEY (`id_stroje`)
) ENGINE=InnoDB;

-- 3. DIMENZE: Číselník tiskařů a mzdových sazeb
CREATE TABLE `dim_zamestnanci` (
    `id_zamestnance` VARCHAR(10) NOT NULL,
    `jmeno_prijmeni` VARCHAR(100) NOT NULL,
    `hodinova_sazba_czk` DECIMAL(10,2) NOT NULL,
    `hodinova_sazba_prescas_czk` DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (`id_zamestnance`)
) ENGINE=InnoDB;

-- 4. DIMENZE: Skladové zásoby a karty papíru
CREATE TABLE `dim_sklad_material` (
    `id_papiru` VARCHAR(10) NOT NULL,
    `typ_papiru` VARCHAR(100) NOT NULL,
    `gramaz_g` INT NOT NULL,
    `cena_za_arch_czk` DECIMAL(6,2) NOT NULL,
    `mnozstvi_archu_skladem` INT NOT NULL,
    `dny_bez_pohybu` INT NOT NULL,
    PRIMARY KEY (`id_papiru`)
) ENGINE=InnoDB;

-- 5. TABULKA FAKTŮ: Výrobní a směnové záznamy tiskárny
CREATE TABLE `fact_vyrobni_zaznamy_tisk` (
    `id_zaznamu` INT AUTO_INCREMENT NOT NULL,
    `id_stroje` VARCHAR(10) NOT NULL,
    `id_zakazky` VARCHAR(20) NOT NULL,
    `id_papiru` VARCHAR(10) NOT NULL,
    `id_hlavni_tiskar` VARCHAR(10) NOT NULL,
    `datum_smeny` DATE NOT NULL,
    `typ_smeny` ENUM('Ranní', 'Odpolední', 'Noční') NOT NULL,
    `je_mimoradna_sobota` TINTYINT(1) DEFAULT 0,
    `pocet_hodin_prescasu_smena` DECIMAL(4,2) DEFAULT 0.00,
    `vytisteno_archu_celkem` INT NOT NULL,
    `zmetky_spatny_soutisk` INT DEFAULT 0,
    `zmetky_spatny_orez` INT DEFAULT 0,
    `zmetky_spatne_slovo` INT DEFAULT 0,
    `prostoje_hodiny` DECIMAL(4,2) DEFAULT 0.00,
    `provozni_naklady_smena_czk` DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (`id_zaznamu`),
    CONSTRAINT `fk_vyroba_stroj` FOREIGN KEY (`id_stroje`) REFERENCES `dim_stroje` (`id_stroje`),
    CONSTRAINT `fk_vyroba_zakazka` FOREIGN KEY (`id_zakazky`) REFERENCES `dim_zakazky` (`id_zakazky`),
    CONSTRAINT `fk_vyroba_material` FOREIGN KEY (`id_papiru`) REFERENCES `dim_sklad_material` (`id_papiru`),
    CONSTRAINT `fk_vyroba_tiskar` FOREIGN KEY (`id_hlavni_tiskar`) REFERENCES `dim_zamestnanci` (`id_zamestnance`)
) ENGINE=InnoDB;
