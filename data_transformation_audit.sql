-- =========================================================================
-- DATIOVÉ TRANSFORMAČNÍ PROVOZNÍ SKRIPTY, MODELOVÁNÍ 24/7 A VALIDAČNÍ AUDITY
-- Projekt: End-to-End analytika farmaceutické tiskárny
-- =========================================================================

DELIMITER //

CREATE PROCEDURE `Oprava_Smen_A_Doplneni_Final`()
BEGIN
    -- 1. KROK: Inicializace a ošetření bezpečného režimu pro hromadné úpravy
    SET SQL_SAFE_UPDATES = 0;

    -- 2. KROK: Příprava prostředí a záloha surových dat
    -- Vytvoříme dočasnou tabulku pro transformaci kontinuálního provozu
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_puvodni_vyroba AS 
    SELECT * FROM fact_vyrobni_zaznamy_tisk;

    -- Vyčištění cílové tabulky faktů pro zajištění elasticity a čistého importu
    UPDATE fact_vyrobni_zaznamy_tisk SET pocet_hodin_prescasu_smena = 0.00 WHERE id_zaznamu > 0;


    -- =========================================================================
    -- 3. KROK: SIMULACE REÁLNÉHO PROVOZNÍHO ŠUMU (ORGANICKÉ PŘESČASY)
    -- =========================================================================
    -- V reálné výrobní fabrice nemá zaměstnanec každý den strojově stejný přesčas.
    -- Nastavujeme logiku, kde cca 65 % směn končí čistou nulou (standardní fond)
    -- a zbylých 35 % směn generuje náhodný přesčasový výkon v rozmezí 1.00 až 5.00 hodin.
    
    UPDATE fact_vyrobni_zaznamy_tisk
    SET pocet_hodin_prescasu_smena = CASE 
        WHEN RAND() > 0.35 THEN 0.00
        ELSE ROUND(1.00 + (RAND() * 4.00), 2)
    END
    WHERE id_zaznamu > 0;


    -- =========================================================================
    -- 4. KROK: MATEMATICKÁ KALIBRACE NA SCHVÁLENÉ MANAŽERSKÉ MILNÍKY
    -- =========================================================================
    -- Vygenerovaný náhodný šum proporcionálně přepočítáme tak, aby roční sumy 
    -- a průměrné měsíční hodnoty v Power BI přesně odpovídaly požadovaným byznysovým cílům.

    -- --- ROK 2023 (Cílové sumy: Jan Novák 120h, Marek Dvořák 115h, Petr Svoboda 120h) ---
    -- Výsledek v Power BI: Stabilní měsíční fond pod zákonným limitem
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance
    JOIN (
        SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS nova_suma
        FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2023 GROUP BY f2.id_hlavni_tiskar
    ) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (
        CASE 
            WHEN z.jmeno LIKE '%Novák%' THEN 120.00 
            WHEN z.jmeno LIKE '%Dvořák%' THEN 115.00 
            ELSE 120.00 
        END / n.nova_suma), 2)
    WHERE YEAR(f.datum_smeny) = 2023 AND n.nova_suma > 0;


    -- --- ROK 2024 (Cílové sumy: Jan Novák 130h, Marek Dvořák 120h, Petr Svoboda 140h) ---
    -- Výsledek v Power BI: Mírný růst, mzdové náklady stále optimální
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance
    JOIN (
        SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS nova_suma
        FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2024 GROUP BY f2.id_hlavni_tiskar
    ) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (
        CASE 
            WHEN z.jmeno LIKE '%Novák%' THEN 130.00 
            WHEN z.jmeno LIKE '%Dvořák%' THEN 120.00 
            ELSE 140.00 
        END / n.nova_suma), 2)
    WHERE YEAR(f.datum_smeny) = 2024 AND n.nova_suma > 0;


    -- --- ROK 2025 (Zlomový rok: Jan Novák 165h, Marek Dvořák 170h, Petr Svoboda 185h) ---
    -- Výsledek v Power BI: Zlomový růst zakázek, překročení zákonného limitu 150h na osobu
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance
    JOIN (
        SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS nova_suma
        FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2025 GROUP BY f2.id_hlavni_tiskar
    ) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (
        CASE 
            WHEN z.jmeno LIKE '%Novák%' THEN 165.00 
            WHEN z.jmeno LIKE '%Dvořák%' THEN 170.00 
            ELSE 185.00 
        END / n.nova_suma), 2)
    WHERE YEAR(f.datum_smeny) = 2025 AND n.nova_suma > 0;


    -- --- ROK 2026 (Zkrácené období do 31. července: Jan Novák 147h, Marek Dvořák 147h, Petr Svoboda 168h) ---
    -- Výsledek v Power BI: Kapacitní kolaps, průměrné měsíční hodnoty dramaticky rostou na 21 až 24 hodin
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance
    JOIN (
        SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS nova_suma
        FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2026 GROUP BY f2.id_hlavni_tiskar
    ) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (
        CASE 
            WHEN z.jmeno LIKE '%Novák%' THEN 147.00 
            WHEN z.jmeno LIKE '%Dvořák%' THEN 147.00 
            ELSE 168.00 
        END / n.nova_suma), 2)
    WHERE YEAR(f.datum_smeny) = 2026 AND n.nova_suma > 0;


    -- 5. KROK: Úklid dočasných objektů a reaktivace bezpečného režimu
    DROP TEMPORARY TABLE temp_puvodni_vyroba;
    SET SQL_SAFE_UPDATES = 1;

END //

DELIMITER ;
