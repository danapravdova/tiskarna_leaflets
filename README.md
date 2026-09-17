# End-to-End analytika farmaceutické tiskárny: Od MySQL Star Schema po What-If simulace v Power BI

## Přehled projektu
Tento repozitář obsahuje komplexní datový a BI projekt (end-to-end), který simuluje reálný polygrafický provoz specializovaný na tisk příbalových letáků pro nadnárodní farmaceutické korporace (Zentiva, Sanofi, Novartis, Teva). **Prezentované výsledky a analýzy představují souhrn produkčních a finančních dat za ucelené období od ledna 2023 do datové uzávěrky k 31. červenci 2026.**

Projekt demonstruje kompletní datový cyklus. Ten sahá od pokročilého návrhu databáze, přes automatizované audity kvality dat a transformaci nepřetržitého 24/7 provozu v MySQL, až po exekutivní finanční reporting a scénářové analýzy v Power BI.

### Klíčové byznysové výsledky v reportu
*   **Celkový objem výroby:** Tiskárna vyprodukovala celkem 25,2 milionu vytištěných archů.
*   **Provozní zisk EBIT:** Při plném třísměnném provozu dosáhl provozní zisk výše 65,5 milionu Kč.
*   **Průměrná rentabilita tržeb (ROS):** Průměrná hodnota rentability činí 24,90 %.
*   **Identifikované ležáky na skladě:** Na skladě byly identifikovány zásoby v hodnotě 90 000 Kč, které generují skryté holdingové náklady ve výši 46 060 Kč ročně.

---

## Architektura a technologický stack
*   **Databázové prostředí:** Využívám MySQL Server, ve kterém jsem nasadila pokročilé DDL/DML, uložené procedury, harmonizační skripty a simulaci provozního šumu.
*   **Datový model:** Vytvořila jsem striktní hvězdicové schéma (Star Schema – 2 tabulky faktů, 5 rozměrových dimenzí) s jednosměrnými relacemi 1:N pro eliminaci ambiguity.
*   **BI & Analytics:** Hlavním nástrojem vizualizace je Power BI Desktop.
*   **Pokročilé výpočty (DAX):** Model využívá iterativní vyhodnocování kontextu řádků (`SUMX`), dynamic What-If parametry pro simulaci tržních fluktuací materiálu a predikční HR modely.

---

## Klíčové analytické okruhy a struktura reportu

Interaktivní Power BI report je rozdělen do 4 klíčových manažerských oblastí, z nichž každá obsahuje automatizovanou textovou interpretaci pro top management.

### 1. Výrobní efektivita a audit kvality
*   **Manažerský vhled:** Report sleduje přísný farmaceutický limit chybovosti (0,50 %). Celková průměrná zmetkovitost dosahuje 0,63 % a generuje materiálové ztráty 203 626 Kč, přičemž největší odpad vzniká mechanickým seřizováním (špatný soutisk a ořez) na ofsetových linkách Heidelberg.
*   **Metrika průchodnosti:** Analýza zavádí metriku **Objem produkce na hodinu prostojů**. Matematicky dokazuje, že **Zentiva** je lídrem efektivity s výkonem **9 343 arch/hod**, čehož je dosaženo strategickým seskupováním velkoobjemových šarží se stejným formátem.

![Výrobní efektivita a kvalita tisku](Power_bi_strana1.png)

### 2. Skladové hospodářství a analýza ležáků
*   **Manažerský vhled:** Výkaz využívá pokročilé podmíněné formátování pro analýzu stárnutí zásob na základě dnů od posledního výdeje.
*   **Finanční dopad:** Model přesně vyčísluje skryté náklady na držení zásob (Holding Costs), které tvoří interní sazba 20 % z vázaného kapitálu. Tato částka zahrnuje reálné výdaje na specifickou klimatizaci haly, pojištění a také riziko legislativních změn v textech léčiv. Analýza navíc izoluje kritické ležáky (např. lékařský papír skladovaný již 1 150 dní) a manažerům okamžitě nabízí scénáře pro jejich odpis nebo alternativní využití ve výrobě.


![Skladové hospodářství a ležáky](Power_bi_strana2.png)

### 3. HR kapacity a predikce přesčasové práce
*   **Manažerský vhled:** Sekce kontroluje dodržování zákonného limitu přesčasů (150 hodin ročně na osobu). Sleduje individuální produktivitu tiskařů, která si drží stabilní průměr **635 arch/hod** díky vysoké efektivitě výkonnostních mzdových příplatků.
*   **Predikční model:** Graficky vizualizuje vývoj mzdových nákladů a přesně izoluje kapacitní zlom na průsečíku mezi lety 2027 a 2028, kdy náklady na unavený stávající tým začínají fixní úvazek nového zaměstnance prokazatelně přeplácet. Slouží jako podklad pro včasné schválení náboru čtvrtého tiskaře již na začátku roku 2027.

![HR kapacitní a mzdový audit](Power_bi_strana3.png)

### 4. Finanční profitabilita a simulace tržních rizik
*   **Manažerský vhled:** Strana poskytuje kompletní manažerský výkaz zisků a ztrát (P&L) rozpadnutý na jednotlivé roky a klienty. Marže organicky reflektují reálné byznysové vlivy (propad ziskovosti v roce 2024 vs. maržový vrchol 34,53 % v roce 2025).
*   **What-If Simulace:** Report obsahuje plně responzivní posuvník simulace cen materiálu. Umožňuje top managementu modelovat finanční šoky při zdražení papíru na globálním trhu a okamžitě sledovat degradaci celkového firemního zisku EBIT.

![Finanční analýza ziskovosti a marží](Power_bi_strana4.png)

---

## Obsah repozitáře
*   `database_schema.sql` - Tento soubor obsahuje kompletní DDL skript definující tabulky, primární/cizí klíče a datová omezení.
*   `data_transformation_audit.sql` - Skript obsahuje pokročilé SQL dotazy použité pro harmonizaci dat, dočasnou proceduru pro rozdělení směn 24/7 a automatizované testy datové integrity.
*   `Power_bi_strana1.png` až `Power_bi_strana4.png` - Složka obsahuje screenshoty jednotlivých stran interaktivního Power BI reportu ve vysokém rozlišení.

---

## O autorce
Jsem datová analytička s exaktním matematicko-statistickým vzděláním z **Vysoké školy ekonomické v Praze (Fakulta informatiky a statistiky)** a 9 lety reálné praxe v průmyslovém a finančním controllingu polygrafického provozu. 

Díky unikátní kombinaci hard-skills (MySQL, Power BI, DAX), dlouholeté praxi v ekonomické žurnalistice a literární tvorbě se specializuji na datový storytelling. To znamená, že transformuji chladné transakční logy do srozumitelných, neprůstřelných byznysových příběhů pro top management firem.
