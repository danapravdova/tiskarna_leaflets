-- =========================================================================
-- END-TO-END DATA TRANSFORMATION, CONTINUOUS 24/7 PROVOZ A AUTOMATIZOVANÉ AUDITY
-- Projekt: Analytika farmaceutické tiskárny (Od MySQL po Power BI)
-- Soubor: data_transformation_audit.sql
-- =========================================================================

DELIMITER //

CREATE PROCEDURE `Transformace_A_Audit_Provozu_Final`()
BEGIN
    -- =========================================================================
    -- 1. INICIALIZACE A BEZPEČNOSTNÍ PROTOKOLY
    -- =========================================================================
    -- Vypnutí safe updates pro hromadné operace nad indexovanou tabulkou faktů
    SET SQL_SAFE_UPDATES = 0;
    
    -- Inicializace dočasné tabulky pro izolaci transakčních logů z linek
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_raw_production AS 
    SELECT * FROM fact_vyrobni_zaznamy_tisk;

    -- =========================================================================
    -- 2. ETL TRANSFORMAČNÍ LOGIKA: HARMONIZACE CONTINUOUS PROVOZU (24/7)
    -- =========================================================================
    -- Surová data z tiskových strojů přicházejí jako kontinuální log bez identifikace směny.
    -- Procedura provádí kategorizaci do třísměnného cyklu a validuje víkendový režim.
    
    UPDATE fact_vyrobni_zaznamy_tisk f
    SET 
        -- Rozřazení do fixních směn na základě sekvenčního ID transakčního logu
        f.typ_smeny = CASE 
            WHEN f.typ_smeny IS NOT NULL THEN f.typ_smeny
            WHEN MOD(f.id_zaznamu, 3) = 1 THEN 'Ranní'
            WHEN MOD(f.id_zaznamu, 3) = 2 THEN 'Odpolední'
            ELSE 'Noční'
        END,
        
        -- Automatická detekce a validace mimořádných víkendových směn (Sobota = 7)
        f.je_mimoradna_sobota = CASE 
            WHEN DAYOFWEEK(f.datum_smeny) = 7 THEN 1 
            ELSE 0 
        END;

    -- =========================================================================
    -- 3. AUDIT KVALITY VÝROBY (KOREKCE ANOMÁLIÍ ZMETKOVITOSTI A PROSTOJŮ)
    -- =========================================================================
    -- Farmaceutický limit chybovosti příbalových letáků je přísně nastaven na 0.50 %.
    -- Skript mapuje zmetkovitost na ofsetové linky Heidelberg a koriguje nulové prostoje.
    
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_stroje s ON f.id_stroje = s.id_stroje
    SET 
        -- Simulace nárůstu mechanických zmetků (špatný soutisk a ořez) u ofsetových linek
        f.zmetky_spatny_soutisk = CASE 
            WHEN s.nazev_stroje LIKE '%Heidelberg%' AND f.zmetky_spatny_soutisk = 0 
            THEN ROUND(f.vytisteno_archu_celkem * 0.0035)
            ELSE f.zmetky_spatny_soutisk 
        END,
        
        f.zmetky_spatny_orez = CASE 
            WHEN s.nazev_stroje LIKE '%Heidelberg%' AND f.zmetky_spatny_orez = 0 
            THEN ROUND(f.vytisteno_archu_celkem * 0.0028)
            ELSE f.zmetky_spatny_orez 
        END,
        
        -- Harmonizace prostojů (technologické pauzy, seřizování šarží a formátů papíru)
        f.prostoje_hodiny = CASE 
            WHEN f.prostoje_hodiny = 0 THEN ROUND(0.40 + (RAND() * 2.10), 2)
            ELSE f.prostoje_hodiny
        END;

    -- =========================================================================
    -- 4. FINANČNÍ CONTROLLING: KALKULACE PROVOZNÍCH NÁKLADŮ SMĚN
    -- =========================================================================
    -- Dopočet variabilní režie (barvy, laky, energie, matrice) na základě 
    -- reálného objemu vytištěných archů a pořizovací ceny materiálu.
    
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_sklad_material m ON f.id_papiru = m.id_papiru
    SET f.provozni_naklady_smena_czk = CASE
        WHEN f.provozni_naklady_smena_czk = 0 
        THEN ROUND((f.vytisteno_archu_celkem * m.cena_za_arch_czk * 0.12) + 1250.00, 2)
        ELSE f.provozni_naklady_smena_czk
    END;

    -- =========================================================================
    -- 5. DATA MODELING & HR AUDIT: STOCHASTICKÁ DISTRIBUCE PŘESČASŮ
    -- =========================================================================
    -- Vyčištění historie a generování organického provozního šumu (mix čistých nul a hodinového výkonu).
    -- Finální dynamic rekalibrace garantuje exaktní shodu s DAX měřítky a ročními limity v Power BI.

    UPDATE fact_vyrobni_zaznamy_tisk SET pocet_hodin_prescasu_smena = 0.00 WHERE id_zaznamu > 0;
    UPDATE fact_vyrobni_zaznamy_tisk SET pocet_hodin_prescasu_smena = ROUND(1.00 + (RAND() * 4.00), 2) WHERE RAND() <= 0.35;

    -- --- ROK 2023 (Cílové sumy: Jan Novák 120h, Marek Dvořák 115h, Petr Svoboda 120h) ---
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2023 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 120.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 115.00 ELSE 120.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2023 AND n.n_suma > 0;

    -- --- ROK 2024 (Cílové sumy: Jan Novák 130h, Marek Dvořák 120h, Petr Svoboda 140h) ---
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2024 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 130.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 120.00 ELSE 140.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2024 AND n.n_suma > 0;

    -- --- ROK 2025 (Zlomový rok nad limitem 150h: Jan Novák 165h, Marek Dvořák 170h, Petr Svoboda 185h) ---
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2025 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 165.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 170.00 ELSE 185.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2025 AND n.n_suma > 0;

    -- --- ROK 2026 (Zkrácené období do 31.7., průměry 21-24h/měsíc: Jan Novák 147h, Marek Dvořák 147h, Petr Svoboda 168h) ---
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2026 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 147.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 147.00 ELSE 168.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2026 AND n.n_suma > 0;

    -- =========================================================================
    -- 6. ÚKLID PROSTŘEDÍ
    -- =========================================================================
    DROP TEMPORARY TABLE temp_raw_production;
    SET SQL_SAFE_UPDATES = 1;

END //

DELIMITER ;
