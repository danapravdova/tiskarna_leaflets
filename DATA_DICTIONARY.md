# Datový slovník (Data Dictionary)

Tento dokument popisuje strukturu a význam jednotlivých entit v relační databázi (Star Schema) našeho polygrafického provozu.

---

## Dimenze (Dimension Tables)

### 1. dim_kalendar
Základní časová dimenze pro správné časové zpravodajství, trendové analýzy a ošetření zkráceného roku 2026.
* **`datum`** (DATE, PK) - Kalendářní den (formát YYYY-MM-DD).
* **`rok`** (INT) - Kalendářní rok (např. 2023, 2024, 2025, 2026).
* **`nazev_mesice`** (VARCHAR) - Český název měsíce (např. Leden, Únor).
* **`poradi_mesice_klic`** (INT) - Číselné pořadí měsíce (1 až 12) pro správné řazení v grafech Power BI.

### 2. dim_zamestnanci
Číselník tiskařů obsahující základní mzdové podmínky a zákonné příplatky podle zákoníku práce.
* **`id_zamestnance`** (VARCHAR, PK) - Unikátní identifikační kód zaměstnance.
* **`jmeno`** (VARCHAR) - Celé jméno tiskaře (např. Jan Novák, Marek Dvořák, Petr Svoboda).
* **`pozice`** (VARCHAR) - Pracovní zařazení (všechny záznamy: Hlavní tiskař).
* **`hodinova_sazba_zaklad`** (DECIMAL) - Základní hodinová mzda v Kč bez příplatků.
* **`priplatek_sobota_procento`** (DECIMAL) - Procentuální příplatek za práci v sobotu.
* **`priplatek_svatek_procento`** (DECIMAL) - Procentuální příplatek za práci ve státní svátek.
* **`priplatek_prescas_procento`** (DECIMAL) - Procentuální příplatek za odpracovanou hodinu přesčasu.
* **`priplatek_nocni_procento`** (DECIMAL) - Procentuální příplatek za práci na noční směně (výchozí: 20.00 %).

### 3. dim_sklad_material
Katalog skladových zásob papíru s aktuálním stavem a cenou za jednotku.
* **`id_papiru`** (VARCHAR, PK) - Unikátní kód typu papíru.
* **`nazev_papiru`** (VARCHAR) - Komerční nebo technický název materiálu (např. Lékařský papír 40g).
* **`aktualni_stav_archu`** (INT) - Fyzické množství archů aktuálně dostupných na skladě.
* **`cena_za_arch_czk`** (DECIMAL) - Pořizovací cena za jeden tiskový arch v Kč.

### 4. dim_stroje
Přehled tiskových technologií a linek instalovaných ve výrobní hale.
* **`id_stroje`** (VARCHAR, PK) - Unikátní kód stroje.
* **`nazev_stroje`** (VARCHAR) - Obchodní název stroje (např. Heidelberg SM 102).
* **`typ_stroje`** (VARCHAR) - Technologická kategorie (např. Ofsetový tisk, Digitální tisk).

### 5. dim_zakazky
Kniha zakázek mapující odběratele a celkovou fakturovanou hodnotu.
* **`id_zakazky`** (VARCHAR, PK) - Unikátní evidenční číslo zakázky.
* **`klient`** (VARCHAR) - Název nadnárodní farmaceutické korporace (Zentiva, Sanofi, Novartis, Teva).
* **`nazev_leku`** (VARCHAR) - Název léčiva, pro které se leták tiskne (např. Paralen, Ibalgin).
* **`Cena_Zakazky_Celkem`** (DECIMAL) - Celková smluvní cena zakázky v Kč fakturovaná klientovi.

---

## Tabulky faktů (Fact Tables)

### 6. fact_vyrobni_zaznamy_tisk
Hlavní transakční tabulka projektu. Zaznamenává výsledky každé odpracované směny v nepřetržitém provozu.
* **`id_zaznamu`** (INT, PK, AI) - Automaticky generované ID výrobního záznamu (směny).
* **`id_stroje`** (VARCHAR, FK) - Vazba na tabulku `dim_stroje`.
* **`id_zakazky`** (VARCHAR, FK) - Vazba na tabulku `dim_zakazky`.
* **`id_papiru`** (VARCHAR, FK) - Vazba na tabulku `dim_sklad_material`.
* **`id_hlavni_tiskar`** (VARCHAR, FK) - Vazba na tabulku `dim_zamestnanci`.
* **`datum_smeny`** (DATE, FK) - Vazba na časovou dimenzi `dim_kalendar`.
* **`typ_smeny`** (VARCHAR) - Určení pracovní doby (Ranní, Odpolední, Noční).
* **`je_mimoradna_sobota`** (TINYINT/BOOLEAN) - Příznak, zda směna proběhla v sobotu (1 = Ano, 0 = Ne).
* **`pocet_hodin_prescasu_smena`** (DECIMAL) - Množství odpracovaných hodin nad rámec standardní 8hodinové směny.
* **`vytisteno_archu_celkem`** (INT) - Celkový hrubý objem produkce na směně včetně zmetků.
* **`zmetky_spatny_soutisk`** (INT) - Počet vyřazených archů z důvodu chyby soutisku na ofsetových linkách.
* **`zmetky_spatny_orez`** (INT) - Počet vyřazených archů z důvodu nepřesného ořezu.
* **`zmetky_spatne_slovo` (INT) - Počet vyřazených archů z důvodu textové legislativní neshody.
* **`prostoje_hodiny`** (DECIMAL) - Čas v hodinách, kdy stroj netiskl (seřizování, porucha, čekání).
* **`provozni_naklady_smena_czk`** (DECIMAL) - Variabilní a fixní režie směny (energie, barvy, opotřebení, bez mezd).

### 7. fact_sklad_zasoby
Snímková tabulka stavu skladových ležáků a vázaného kapitálu.
* **`id_papiru`** (VARCHAR, PK/FK) - Vazba na tabulku `dim_sklad_material`.
* **`id_zakazky`** (VARCHAR, FK) - Vazba na tabulku `dim_zakazky` (přiřazení materiálu k historické šarži).
* **`datum_posledniho_vydeje`** (DATE) - Den, kdy byl daný papír naposledy reálně vyskladněn do výroby.
* **`mnozstvi_archu_skladem`** (INT) - Aktuální fyzické množství neaktivních archů na skladě.
* **`dny_bez_pohybu_k_datu`** (INT) - Počet dní od `datum_posledniho_vydeje` pro výpočet Holding Costs.
