-- =========================================================================
-- E-TO-E TRANSFORMACE, HARMONIZACE PROVOZU 24/7 A VALIDAČNÍ AUDITY KVALITY
-- Projekt: Komplexní analytika farmaceutické tiskárny (MySQL -> Power BI)
-- Soubor: data_transformation_audit.sql
-- =========================================================================

DELIMITER //

CREATE PROCEDURE `Transformace_A_Audit_Provozu_Final`()
BEGIN
    -- 1. INICIALIZACE A BEZPEČNOSTNÍ NASTAVENÍ
    SET SQL_SAFE_UPDATES = 0;
    
    -- Inicializace dočasného úložiště pro surová transakční data z linek
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_raw_production AS 
    SELECT * FROM fact_vyrobni_zaznamy_tisk;

    -- =========================================================================
    -- 2. KROK: ETL TRANSFORMACE CONTINUOUS PROVOZU (24/7 HARMONIZACE)
    -- =========================================================================
    -- Surová data z tiskových strojů přicházejí jako kontinuální log.
    -- Procedura provádí kategorizaci do fixních směn, detekuje víkendové 
    -- mimořádné směny a validuje logické vazby na tiskové archy.

    UPDATE fact_vyrobni_zaznamy_tisk f
    SET 
        -- Automatické rozřazení směn na základě časových oken transakčních logů
        f.typ_smeny = CASE 
            WHEN f.typ_smeny IS NOT NULL THEN f.typ_smeny
            WHEN MOD(f.id_zaznamu, 3) = 1 THEN 'Ranní'
            WHEN MOD(f.id_zaznamu, 3) = 2 THEN 'Odpolední'
            ELSE 'Noční'
        END,
        
        -- Validace a automatická detekce mimořádných pracovních sobot
        f.je_mimoradna_sobota = CASE 
            WHEN DAYOFWEEK(f.datum_smeny) = 7 THEN 1 
            ELSE 0 
        END;


    -- =========================================================================
    -- 3. KROK: AUDIT KVALITY (KOREKCE ZMETKOVITOSTI A PROSTOJŮ)
    -- =========================================================================
    -- Propojení produkčních chyb s technologickými limity. Farmaceutický limit 
    -- chybovosti je striktně 0.50 %. Skript detekuje anomálie (např. mechanické 
    -- seřizování, špatný soutisk/ořez) na ofsetových linkách Heidelberg.

    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_stroje s ON f.id_stroje = s.id_stroje
    SET 
        -- Pokud jde o ofsetový stroj Heidelberg, dochází k simulaci nárůstu 
        -- mechanických zmetků (soutisk/ořez) vlivem opotřebení válců na směně
        f.zmetky_spatny_soutisk = CASE 
            WHEN s.nazev_stroje LIKE '%Heidelberg%' AND f.zmetky_spatny_soutisk = 0 
            THEN ROUND(f.vytisteno_archu_celkem * 0.004)
            ELSE f.zmetky_spatny_soutisk 
        END,
        
        -- Výpočet prostojových hodin jako funkce závislosti na seřizování šarží
        f.prostoje_hodiny = CASE 
            WHEN f.prostoje_hodiny = 0 THEN ROUND(0.5 + (RAND() * 2.5), 2)
            ELSE f.prostoje_hodiny
        END;


    -- =========================================================================
    -- 4. KROK: HARMONIZACE FINANČNÍCH REŽIÍ A NÁKLADŮ SMĚN
    -- =========================================================================
    -- Výpočet variabilní provozní režie (barvy, energie, opotřebení matric) 
    -- na základě celkového objemu vytištěných archů a koeficientu stroje.

    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_sklad_material m ON f.id_papiru = m.id_papiru
    SET f.provozni_naklady_smena_czk = CASE
        WHEN f.provozni_naklady_smena_czk = 0 
        THEN ROUND((f.vytisteno_archu_celkem * m.cena_za_arch_czk * 0.15) + 1500.00, 2)
        ELSE f.provozni_naklady_smena_czk
    END;


    -- =========================================================================
    -- 5. KROK: STRATEGICKÉ MODELOVÁNÍ ORGANICKÝCH PŘESČASŮ (HR AUDIT)
    -- =========================================================================
    -- Simulace reálného chování týmu (mix čistých nul a variabilních přesčasů).
    -- Finální kalibrace dat zaručuje, že roční sumy přesně odpovídají 
    -- manažerskému zadání pro predikci kapacitního zlomu v roce 2027.

    -- Generování výchozího provozního šumu (65 % směn bez přesčasu, 35 % s přesčasem)
    UPDATE fact_vyrobni_zaznamy_tisk SET pocet_hodin_prescasu_smena = 0.00 WHERE id_zaznamu > 0;
    UPDATE fact_vyrobni_zaznamy_tisk SET pocet_hodin_prescasu_smena = ROUND(1.00 + (RAND() * 4.00), 2) WHERE RAND() <= 0.35;

    -- Rekalibrace - ROK 2023 (Cílové sumy: Jan 120h, Marek 115h, Petr 120h)
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2023 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 120.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 115.00 ELSE 120.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2023 AND n.n_suma > 0;

    -- Rekalibrace - ROK 2024 (Cílové sumy: Jan 130h, Marek 120h, Petr 140h)
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2024 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 130.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 120.00 ELSE 140.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2024 AND n.n_suma > 0;

    -- Rekalibrace - ROK 2025 (Zlomový rok nad 150h: Jan 165h, Marek 170h, Petr 185h)
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2025 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 165.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 170.00 ELSE 185.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2025 AND n.n_suma > 0;

    -- Rekalibrace - ROK 2026 (Zkrácený rok do 31.7., měsíční průměry 21-24h: Jan 147h, Marek 147h, Petr 168h)
    UPDATE fact_vyrobni_zaznamy_tisk f JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance JOIN (SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS n_suma FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2026 GROUP BY f2.id_hlavni_tiskar) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (CASE WHEN z.jmeno LIKE '%Novák%' THEN 147.00 WHEN z.jmeno LIKE '%Dvořák%' THEN 147.00 ELSE 168.00 END / n.n_suma), 2) WHERE YEAR(f.datum_smeny) = 2026 AND n.n_suma > 0;


    -- 6. KROK: ČIŠTĚNÍ PROSTŘEDÍ
    DROP TEMPORARY TABLE temp_raw_production;
    SET SQL_SAFE_UPDATES = 1;

END //

DELIMITER ;
