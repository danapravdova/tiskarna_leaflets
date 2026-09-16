-- ============================================================================
-- DATOVÉ TRANSFORMACE, MODELOVÁNÍ 24/7 PROVOZU A VALIDAČNÍ AUDITY
-- ============================================================================

-- 1. TRANSFORMACE: Rozsekání 1 řádku na 3 samostatné směny se zachováním celkového objemu dne
DELIMITER //

CREATE PROCEDURE `Oprava_Smen_A_Doplneni_Final`()
BEGIN
    CREATE TEMPORARY TABLE temp_puvodni_vyroba AS SELECT * FROM `fact_vyrobni_zaznamy_tisk`;
    TRUNCATE TABLE `fact_vyrobni_zaznamy_tisk`;

    -- Vložení Ranní směny (36 % původního výkonu)
    INSERT INTO `fact_vyrobni_zaznamy_tisk`
    SELECT null, id_stroje, id_zakazky, id_papiru, 'TIS-01', datum_smeny, 'Ranní', je_mimoradna_sobota,
    ROUND(pocet_hodin_prescasu_smena * 0.33, 2), ROUND(vytisteno_archu_celkem * 0.36, 0),
    ROUND(zmetky_spatny_soutisk * 0.34, 0), ROUND(zmetky_spatny_orez * 0.35, 0), ROUND(zmetky_spatne_slovo * 0.32, 0),
    ROUND(prostoje_hodiny * 0.33, 2), ROUND(provozni_naklady_smena_czk * 0.34, 2) FROM temp_puvodni_vyroba;

    -- Vložení Odpolední směny (32 % původního výkonu)
    INSERT INTO `fact_vyrobni_zaznamy_tisk`
    SELECT null, id_stroje, id_zakazky, id_papiru, 'TIS-02', datum_smeny, 'Odpolední', je_mimoradna_sobota,
    ROUND(pocet_hodin_prescasu_smena * 0.33, 2), ROUND(vytisteno_archu_celkem * 0.32, 0),
    ROUND(zmetky_spatny_soutisk * 0.33, 0), ROUND(zmetky_spatny_orez * 0.30, 0), ROUND(zmetky_spatne_slovo * 0.33, 0),
    ROUND(prostoje_hodiny * 0.31, 2), ROUND(provozni_naklady_smena_czk * 0.33, 2) FROM temp_puvodni_vyroba;

    -- Vložení Noční směny (Matematický zbytek do 100 % pro neprůstřelnou finanční shodu)
    INSERT INTO `fact_vyrobni_zaznamy_tisk`
    SELECT null, id_stroje, id_zakazky, id_papiru, 'TIS-03', datum_smeny, 'Noční', je_mimoradna_sobota,
    ROUND(pocet_hodin_prescasu_smena * 0.34, 2),
    vytisteno_archu_celkem - ROUND(vytisteno_archu_celkem * 0.36, 0) - ROUND(vytisteno_archu_celkem * 0.32, 0),
    zmetky_spatny_soutisk - ROUND(zmetky_spatny_soutisk * 0.34, 0) - ROUND(zmetky_spatny_soutisk * 0.33, 0),
    zmetky_spatny_orez - ROUND(zmetky_spatny_orez * 0.35, 0) - ROUND(zmetky_spatny_orez * 0.30, 0),
    zmetky_spatne_slovo - ROUND(zmetky_spatne_slovo * 0.32, 0) - ROUND(zmetky_spatne_slovo * 0.33, 0),
    prostoje_hodiny - ROUND(prostoje_hodiny * 0.33, 2) - ROUND(prostoje_hodiny * 0.31, 2),
    provozni_naklady_smena_czk - ROUND(provozni_naklady_smena_czk * 0.34, 2) - ROUND(provozni_naklady_smena_czk * 0.33, 2) FROM temp_puvodni_vyroba;

    DROP TEMPORARY TABLE temp_puvodni_vyroba;
END //
DELIMITER ;

-- 2. HISTORICKÝ PROVOZNÍ AUDIT: Modelování nelineárních vnitrofiremních režií podle náročnosti šarží
UPDATE `fact_vyrobni_zaznamy_tisk` f
JOIN `dim_zakazky` z ON f.id_zakazky = z.id_zakazky
SET f.provozni_naklady_smena_czk = CASE 
    WHEN z.klient = 'Zentiva'  THEN CASE WHEN YEAR(f.datum_smeny) = 2024 THEN ROUND(z.Cena_Zakazky_Celkem * 0.52, 2) ELSE ROUND(z.Cena_Zakazky_Celkem * 0.44, 2) END
    WHEN z.klient = 'Sanofi'   THEN CASE WHEN YEAR(f.datum_smeny) = 2024 THEN ROUND(z.Cena_Zakazky_Celkem * 0.68, 2) ELSE ROUND(z.Cena_Zakazky_Celkem * 0.48, 2) END
    WHEN z.klient = 'Teva'     THEN CASE WHEN YEAR(f.datum_smeny) = 2026 THEN ROUND(z.Cena_Zakazky_Celkem * 0.58, 2) ELSE ROUND(z.Cena_Zakazky_Celkem * 0.50, 2) END
    WHEN z.klient = 'Novartis' THEN CASE WHEN YEAR(f.datum_smeny) = 2026 THEN ROUND(z.Cena_Zakazky_Celkem * 0.66, 2) ELSE ROUND(z.Cena_Zakazky_Celkem * 0.56, 2) END
END;

-- Finální doregulování na celkovou ROS průmyslovou hladinu (Plošný 25% posun nákladů)
UPDATE `fact_vyrobni_zaznamy_tisk` SET `provozni_naklady_smena_czk` = ROUND(`provozni_naklady_smena_czk` * 1.25, 2);

-- 3. VALIDACE: Automatizovaný audit datové integrity (Musí vrátit 0 řádků)
SELECT 'CHYBA: Prostoje nad limit 8h!' as Status, id_zaznamu, prostoje_hodiny FROM `fact_vyrobni_zaznamy_tisk` WHERE prostoje_hodiny > 8.00;
SELECT 'CHYBA: Záporné finanční náklady!' as Status, id_zaznamu, provozni_naklady_smena_czk FROM `fact_vyrobni_zaznamy_tisk` WHERE provozni_naklady_smena_czk <= 0;
