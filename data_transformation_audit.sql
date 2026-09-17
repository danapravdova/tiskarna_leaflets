DELIMITER //

CREATE PROCEDURE `Oprava_Smen_A_Doplneni_Final`()
BEGIN
    -- 1. KROK: Ošetření bezpečného režimu pro hromadné úpravy
    SET SQL_SAFE_UPDATES = 0;

    -- 2. KROK: Kompletní vynulování přesčasů pro čistý start transformace
    UPDATE fact_vyrobni_zaznamy_tisk 
    SET pocet_hodin_prescasu_smena = 0.00 
    WHERE id_zaznamu > 0;

    -- 3. KROK: Generování organických přesčasů s realistickým provozním šumem
    -- Simulujeme běžnou fabriku: cca 65 % směn je bez přesčasů (čistá nula), 
    -- na zbytku směn tiskaři táhnou náhodné přesčasy mezi 1 až 5 hodinami.
    UPDATE fact_vyrobni_zaznamy_tisk
    SET pocet_hodin_prescasu_smena = CASE 
        WHEN RAND() > 0.35 THEN 0.00
        ELSE ROUND(1.00 + (RAND() * 4.00), 2)
    END
    WHERE id_zaznamu > 0;

    -- 4. KROK: Matematická kalibrace na přesné byznysové milníky
    -- Tento krok proporcionálně přepočítá vygenerovaný šum tak, aby roční sumy 
    -- a měsíční průměry v Power BI přesně odpovídaly schválenému manažerskému zadání.

    -- --- ROK 2023 (Cílové sumy: Jan 120h, Marek 115h, Petr 120h) ---
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

    -- --- ROK 2024 (Cílové sumy: Jan 130h, Marek 120h, Petr 140h) ---
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

    -- --- ROK 2025 (Zlomový rok nad limitem 150h + plošné navýšení o 15h) ---
    UPDATE fact_vyrobni_zaznamy_tisk f
    JOIN dim_zamestnanci z ON f.id_hlavni_tiskar = z.id_zamestnance
    JOIN (
        SELECT f2.id_hlavni_tiskar, SUM(f2.pocet_hodin_prescasu_smena) AS nova_suma
        FROM fact_vyrobni_zaznamy_tisk f2 WHERE YEAR(f2.datum_smeny) = 2025 GROUP BY f2.id_hlavni_tiskar
    ) AS n ON f.id_hlavni_tiskar = n.id_hlavni_tiskar
    SET f.pocet_hodin_prescasu_smena = ROUND(f.pocet_hodin_prescasu_smena * (
        CASE 
            WHEN z.jmeno LIKE '%Novák%' THEN (150.00 + 15.00) 
            WHEN z.jmeno LIKE '%Dvořák%' THEN (155.00 + 15.00) 
            ELSE (170.00 + 15.00) 
        END / n.nova_suma), 2)
    WHERE YEAR(f.datum_smeny) = 2025 AND n.nova_suma > 0;

    -- --- ROK 2026 (Kritické přetížení, měsíční průměry 21h až 24h) ---
    -- Zohledňuje zkrácené období do 31. července (7 měsíců).
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

    -- 5. KROK: Obnovení bezpečného režimu
    SET SQL_SAFE_UPDATES = 1;
END //

DELIMITER ;
