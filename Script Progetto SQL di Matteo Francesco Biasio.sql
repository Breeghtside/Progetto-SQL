/*
    Script per la creazione del database "SQLProject".
    In esso verranno create le diverse tabelle, prima
    fra tutte il "WorldData2023"
*/
CREATE DATABASE "SQLProject"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United Kingdom.1252'
    LC_CTYPE = 'English_United Kingdom.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


/*
    creazione della tabella "WorldData2023". Le tipologie,
    la dimensione delle variabili e la non nullità sono state
    valutate in funzione del dataset orginale. Le valutazioni possono
    essere monitorate in "world-data-2023_cleaning_procedure.csv",
    in cui sono presenti i calcoli delle dimensioni delle stringhe
    con le funzioni disponibili in excel, per ridurre lo spazio allocato
    nel DB [sfruttando in excel annidamenti MAX(LUNGHEZZA(colonna)))], 
    (usando poi su postgres una varchar - character varying)
    e dove ho valutato la dimensione delle variabile intere
    (smallint o int-integer). Inoltre:
        - Ogni variabile intera è stata formattata come numero
          senza separatori delle migliaia, per risolvere i problemi
          in importazione del CSV su PostgreSQL (su STATA e Excel
          non davano mai problemi) ["," come separatore dei campi].
          Ho usato come separatori quelli che uso di sistema
          (derivazione anglosassione): punto per il decimale,
          virgola per le migliaia (in questo caso evitata per non dare
          problemi in fase di importazione).
        - Le percentuali, come spiegato nel suddetto .csv sono state
          riformattate in base "1" per il 100%, con un range per le cifre
          significative variabile, in funzione del tipo di dato proposto.
          Ho usato una variabile decimal-numeric.
        - Estrazione del valore numerico della valuta usando un annidamento
          STRINGA.ESTRAI(testo, inizio,LUNGHEZZA(testo)).

*/

CREATE TABLE IF NOT EXISTS public.worlddata2023
(
    country character varying(34) COLLATE pg_catalog."default" NOT NULL,
    density_pop_km2 smallint NOT NULL,
    countrycode character(2) COLLATE pg_catalog."default",
    agrilandperc numeric(5,4),
    landarea_km2 integer,
    armedforcessize integer,
    birthrate numeric(4,2),
    callingcode smallint,
    capital_majorcity character varying(25) COLLATE pg_catalog."default",
    co2emissions integer,
    cpi numeric(6,2),
    cpichangeperc numeric(5,4),
    currencycode character(3) COLLATE pg_catalog."default",
    fertilityrate numeric(3,2),
    forestedareaperc numeric(5,4),
    gasolineprice numeric(3,2),
    gdp bigint,
    grossprimaryeducationenrollmentperc numeric(5,4),
    grosstertiaryeducationenrollmentperc numeric(5,4),
    infantmortality numeric(3,1),
    largestcity character varying(27) COLLATE pg_catalog."default",
    lifeexpectancy numeric(3,1),
    maternalmortalityratio smallint,
    minimumwage numeric(4,2),
    officiallanguage character varying(22) COLLATE pg_catalog."default",
    outofpockethealthexpenditure numeric(5,4),
    physiciansperthousand numeric(3,2),
    population integer,
    population_laborforceparticipationperc numeric(5,4),
    taxrevenueperc numeric(5,4),
    totaltaxrate numeric(5,4),
    unemploymentrate numeric(5,4),
    urban_population integer,
    latitude numeric(10,8),
    longitude numeric(13,10),
    CONSTRAINT worddata2023_pkey PRIMARY KEY (country)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.worlddata2023
    OWNER to postgres;




/*
    NB: non posso usare countrycode come Primary key
    perchè Città del Vaticano, ad esempio, non presenta
    countrycode
*/


/*
    Comando di importazione del .csv "world-data-2023_cleaned.csv"
    ripulito. Non ho trovato un modo più dinamico per accedere al percorso
    nel PC in cui è salvato il file sorgente e usarlo come variabile locale
    dinamica per l'apertura in qualunue "macchina" si trovi, come faccio
    su STATA.
*/

--command " "\\copy public.worlddata2023 (country, density_pop_km2, countrycode, agrilandperc, landarea_km2, armedforcessize, birthrate, callingcode, capital_majorcity, co2emissions, cpi, cpichangeperc, currencycode, fertilityrate, forestedareaperc, gasolineprice, gdp, grossprimaryeducationenrollmentperc, grosstertiaryeducationenrollmentperc, infantmortality, largestcity, lifeexpectancy, maternalmortalityratio, minimumwage, officiallanguage, outofpockethealthexpenditure, physiciansperthousand, population, population_laborforceparticipationperc, taxrevenueperc, totaltaxrate, unemploymentrate, urban_population, latitude, longitude) FROM 'C:/DIRECTORY_PATH/WORLD-DATA-2023_CLEANED.CSV' DELIMITER ',' CSV HEADER ENCODING 'UTF8' QUOTE '\"' ESCAPE '''';""

/*
    Purtroppo non funziona ma, adottando la strategia di importazione 
    -   Tasto DX sulla tabella "worlddata2023"
    -   Import/Export Data...
    -   Selezionando correttamente "world-data-2023_cleaned.csv" che mostra
        il DB ripulito e pronto all'importazione, come spiegato nei commenti
        precedenti, originato da "world-data-2023.csv" e che vede le modifiche
        in "world-data-2023_cleaning_procedure.csv" e "world-data-2023_cleaning_procedure.xlsx"
*/

/*
    aggiornamento di una nazione che in origine aveva una formattazione
    della chiave primaria non appropriata: ho recuperato l'informazione
    del countrycode e del callingcode online
*/
update worlddata2023
set country = 'São Tomé and Príncipe'
where countrycode = 'ST' and callingcode = 239


/*
    creazione di view per valutazioni di statistica
    descrittiva al 2023
*/


/*
    correlazione tra la "percentuale di aree forestali" e la "percentuale
    di area adibita a destinazione agricola"
*/

create view EnvEcoWorld2023 as
select country, density_pop_km2, agrilandperc, landarea_km2, forestedareaperc, gasolineprice, co2emissions, gdp, grossprimaryeducationenrollmentperc, grosstertiaryeducationenrollmentperc, infantmortality, lifeexpectancy, maternalmortalityratio, physiciansperthousand, population, population_laborforceparticipationperc, unemploymentrate, totaltaxrate, taxrevenueperc
from worlddata2023;

create view Environmental2023 as
select country, density_pop_km2, agrilandperc, landarea_km2, forestedareaperc, gasolineprice, co2emissions
from EnvEcoWorld2023;

select * from Environmental2023;

create view corr_1 as
SELECT corr(agrilandperc, forestedareaperc) as corr_agri_forest
from Environmental2023;

select * from corr_1;
/*
    Correlazione tra le due variabili appena citate
        -0.434569556619751
    La correlazione tra le due variabili è abbastanza banale
    ma può darci già una indicazione circa la bontà del dato offerto:
    la correlazione "spaziale" sulla copertura territoriale 
    indica una correlazione negativa: all'aumentare del tasso di terreno
    destinato ai fini agricoli, si riduce il territorio "incontaminato",
    coperto da foreste.
    Rappresenta, in modo abbastanza agevole, il tipico fenomeno di "sottrazione"
    di territorio incontaminato ai fini del soddisfacimento del fabbisogno
    primario si sostentamento, attraverso la produzione agricola.
    Questa ha sicuramente un impatto ambientale non indifferente,
    soprattuto quando si parla di coltura intensiva, nella produzione di co2.
    L'effetto combinato della deforestazione può indurre al crearsi di un effetto a catena:
    la riduzione di copertura di foreste porta a non avere sufficiente quota "GREEN"
    per compensare la crescita di produzione di co2.
    MA il tema agricolo non necessariamente può spiegare complessivamente
    la questione CO2: occorrebbe avere informazione anche circa la concentrazione
    di imprese ad alto tasso inquinante, così come informazioni sul tasso di concentrazione
    della popolazione
*/

/*
    correlazione 2: "percentuale di iscrizioni lorde presso poli di educazione terziaria" e
    "aspettative di vita"
*/
create view corr_2 as
SELECT corr(grosstertiaryeducationenrollmentperc, lifeexpectancy) as corr_ter_life
from EnvEcoWorld2023;

select * from corr_2;
/*
    Un altro indicatore di interesse collettivo potrebbe essere
    rappresentato dall'aspettativa di vita. Quest'ultima è fortemente
    collegata alle scelte che un individuo prende nell'economia
    della propria esistenza. Come certo è anche collegata ai contesti
    economico-strutturali che le diverse nazioni propongono. Sotto
    queste ipotesi è bene considerare come potenzialmente un individuo
    consapevole, con gli strumenti giusti, creandosi una rete di contatti
    adeguata, possa aspirare ad una aspettativa di vita più longeva.

    Per questo motivo ho provato ad analizzare una correlazione tra il
    tasso di partecipazione e iscrizione ad educazione terziaria e l'aspettativa
    di vita (sopracitate): l'output mostra una correlazione pari a:
    
        0.7225347334725586
    
    La cosa sarà sicuramente in parte motivata da una questione strutturale
    delle nazioni, anche dipendente dal livello della sanità.
    Ma, sicuramente, la partecipazione a contesti accademici superiori-universitari
    può incidere fortemente sulle scelte del quotidiano: l'apertura mentale,
    la comunicazione con diverse culture, l'allargamento dello spettro conoscitivo
    che tali contesti possono offrire, mettono nelle condizioni, se disponibili
    ad "accettare il nuovo", a creare una maggiore consapevolezza nelle scelte del
    quotidiano (dalla scelta delle materie prime in un supermercato, fino all'aumento
    di proprensione al rischio in fase di scelte finanziare [investimenti, accesso
    ad un mutuo]). Nell'economia comportamentale, il parametro istruzione gioca
    un ruolo fondamentale, in quanto permette di prendere scelte con più raziocinio
    e calma, riducendo lo stress.
    La componente scelta quotidiana e la conseguente riduzione dello stress possono
    incidere inevitabilmente sull'aumento di aspettativa di vita.
    L'istruzione e il sapere rendono liberi, e la libertà incide sul benessere.
*/

create view corr_3 as
SELECT corr(infantmortality, lifeexpectancy) as corr_infant_life
from EnvEcoWorld2023;

select * from corr_3;

create view corr_4 as
SELECT corr(MaternalMortalityRatio, lifeexpectancy) as corr_mater_life
from EnvEcoWorld2023;

select * from corr_4;

/*
    Quasi sicuramente queste coppie di variabili saranno autocorrelate fra loro,
    ma è necessario fare un appunto sulla mortalià infantile/mortalità materna
    e la correlazione con l'aspettativa di vita:

        corr_3:     -0.9246753226745087
        corr_4:     -0.8317965161194117

    è inevitabile che la mortalità prematura e la mortalità materna si correli
    in qualche modo, con l'aspettativa di vita. Le opportunità sanitarie ridotte
    incidono in modo pregante sull'aspettativa di vita.
*/

/*
    TOP 10 e WORST 10 2023: health_table
*/
create view health_table as
select country, lifeexpectancy, InfantMortality, maternalmortalityratio
from EnvEcoWorld2023;


/*
    LIFE EXPECTANCY: Top 10
*/

create view top_life_exp as
select country, lifeexpectancy
from health_table
where lifeexpectancy != 0
order by lifeexpectancy desc
limit 10;

select * from top_life_exp;

/*
    Come può mostrare la view "top_life_exp" le nazioni nella top 10
    per aspettativa sono in gran parte rappresentate da nazioni europee,
    fatta eccezione per il Giappone e Singapore.
    I casi italiani e giapponesi sono ormai noti da anni: sono tra le
    nazioni più anziane sul globo terracqueo. Nel caso italiano in più
    sappiamo quanto questo dato sia influenziato dall'alto tasso di
    pensionati, che non partecipato più direttamente alla produzione di
    GDP/PIL nazionale.
*/

create view corr_5 as
SELECT corr(gdp/population, lifeexpectancy) as corr_gdp_lifeexp
from EnvEcoWorld2023;

select * from corr_5;

/*
    Dunque, servirebbe dare un'occhiata a se la produzione di benessere
    per la collettività sia in qualche modo correlata con l'aspettativa di vita.
    Prendendo in esame il gdp pro-capite (GDP/population) e "lifeexpectancy" si può chiaramente
    evidenziare che le nazioni con più alta produzione di Prodotto interno lordo - pro-capite -
    si troverebbero mediamente in una situazione strutturale tale da garantire un sistema
    "salubre", favorendo la crescita dell'aspettativa di vita.

    corr_5:     0.6150761448655165
*/

/*
    LIFE EXPECTANCY: worst 10
*/

create view worst_life_exp as
select country, lifeexpectancy
from health_table
where lifeexpectancy != 0
order by lifeexpectancy asc
limit 10;

select * from worst_life_exp;

/*
    la situazione peggiore per la lifeexpectancy la si può osservare invece
    nei paesi centrafricani equatoriali
*/

/*
    INFANT MORTALITY: Top 10 and Worst 10
*/

create view worst_infant_mortality as
select country, infantmortality
from health_table
where infantmortality != 0
order by infantmortality desc
limit 10;

select * from worst_infant_mortality;

/*
    come conferma questa vista, il livello più alto di mortalità infantile
    è osservabile in quelle nazioni il cui contesto sanitario è debole, tavolta
    quasi assente, come nei territori centrafricani
*/


create view best_infant_mortality as
select country, infantmortality
from health_table
where infantmortality != 0
order by infantmortality asc
limit 10;

select * from best_infant_mortality;


/*
    all'altro lato della distribuzione osserviamo la grande maggioranza
    di nazioni europee, fatta eccezione per il Giappone. Non compare l'Italia ai primi
    posti, ma solo al 14esimo.

    select country, infantmortality
    from health_table
    where infantmortality != 0
*/





/*
    MATERNAL MORTALITY: Top 10 and Worst 10
*/

create view worst_maternal_mortality as
select country, maternalmortalityratio
from health_table
where maternalmortalityratio != 0
order by maternalmortalityratio desc
limit 10;

select * from worst_maternal_mortality;

/*
    come conferma questa vista, il livello più alto di mortalità materna
    è osservabile in quelle nazioni il cui contesto sanitario è debole, tavolta
    quasi assente, come nei territori centrafricani o in Afghanistan.
*/


create view best_maternal_mortality as
select country, maternalmortalityratio
from health_table
where maternalmortalityratio != 0
order by maternalmortalityratio asc
limit 10;

select * from best_maternal_mortality;


/*
    all'altro lato della distribuzione osserviamo la grande maggioranza
    di nazioni europee, fatta eccezione per gli EAU.

    select country, infantmortality
    from health_table
    where infantmortality != 0
*/


/*
    TOP 10 e WORST 10 2023: education_table
*/
create view education_table as
select country, grossprimaryeducationenrollmentperc, grosstertiaryeducationenrollmentperc
from EnvEcoWorld2023;

select * from education_table;

create view top_ter_edu as
select country, grosstertiaryeducationenrollmentperc
from education_table
where grosstertiaryeducationenrollmentperc != 0
order by grosstertiaryeducationenrollmentperc desc
limit 10;

select * from top_ter_edu;

/*
    il livello educativo vede una distribuzione alquanto differenziata
    fra le varie parti nel mondo: al lordo di potenziali studenti e cittadini
    stranieri, trovaiamo la Grecia in testa, seguita dall'Autralia, Grenada,
    South Korea, Argetina, Spagna...
*/

create view worst_ter_edu as
select country, grosstertiaryeducationenrollmentperc
from education_table
where grosstertiaryeducationenrollmentperc != 0
order by grosstertiaryeducationenrollmentperc asc
limit 10;

select * from worst_ter_edu;


/*
    come prevedibile, le nazioni con il più basso tasso di iscrizione a percorsi
    di educazione terziaria sono centrafricane, fatta eccezione per Haiti
*/


/*
    riprendendo il discorso sulla correlazione positiva tra la life expectancy
    e la percentuale di iscrizione a percorsi di educazione terziaria,
    possiamo vedere se vi sono nazioni che risultano nella top 10
    di entrambi gli indicatori
*/


create view top_life_terziaryED as
select top_life_exp.country, lifeexpectancy, grosstertiaryeducationenrollmentperc
from top_life_exp
inner join top_ter_edu
on top_life_exp.country = top_ter_edu.country;


select * from top_life_terziaryED;

/*
    la view creata mostra come solo la Spagna si trovi nella TOP 10
    come aspettativa di vita e come percentuale lorda di iscrizione
    a percorsi di formazione terziaria
*/



create view worst_life_terziaryED as
select worst_life_exp.country, lifeexpectancy, grosstertiaryeducationenrollmentperc
from worst_life_exp
inner join worst_ter_edu
on worst_life_exp.country = worst_ter_edu.country;


select * from worst_life_terziaryED;

/*
    in questa lista viene mostrata una situazione alquanto prevista e
    preoccupante: su 10 delle precedenti due liste, 6 nazioni risulatano tra
    le peggiori situazioni sia in termini di istruzione che di aspettativa di vita
    e sono tutte del contesto centroafricano.
*/


/*
    SUSTAINABLE ENERGY DB CREATION AND IMPORT
    per le ragioni già motivate per il dataset WorldData2023,
    sono state fatte degli adattamenti sul formato dei dati sorgente:
    -   le modifiche sono osservabili nei file "global-data-on-sustainable-energy (1)_cleaning_procedure"
        in .csv/.xlsx
    -   Per le stringhe viene identificata la lunghezza massima e utilizzato il tipo
        di dato VARCHAR - CHARACTER VARYING, in modo da rendere adattivo lo spazio allocato su disco
    -   per le percentuali viene adottata una trasformazione in base 1 per il 100%: vengono
        identificate a monte le cifre significative ed adattate in funzione della trasfromazione.
        Formato DECIMAL/NUMERIC Y cifre significative. (PostgreSQL converte automaticamente il formato)
    -   per i decimal/float/numeric si identificano le lunghezze massime delle stinghe SENZA pointer,
        valutato il MAX e il MIN della serie e valutate le cifre significative da adottare
    -   gli interi vengono valutati in funzione della dimensione massima del numero (allocando smallint-int
        -bigint in base alla necessità)
    -   rappresentazione dei dati della densità di popolazione senza separatori delle migliaia ("," dava problemi
        in fase di importazione, legge tale carattere come separatore di valore, sempre per la questione dello standard
        anglosassone che uso sul PC).
*/


CREATE TABLE IF NOT EXISTS public.sustainableenergy
(
    entity character varying(32) COLLATE pg_catalog."default" NOT NULL,
    year smallint NOT NULL,
    accesselectricitypercpop numeric(9,8) NOT NULL,
    accesscleanfuelcook numeric(4,3),
    renewelectrgenpercap numeric(6,2),
    financflowsdelevopusdoll bigint,
    renewenershareperctotenerconsumpt numeric(5,4) NOT NULL,
    elecfossfuel_twh numeric(6,2),
    elecnucl_twh numeric(5,2),
    elecrenew_twh numeric(6,2),
    lowcarelec_percelec numeric(10,9) NOT NULL,
    primenerconsumpt_kwh_percap numeric(10,4) NOT NULL,
    energyintlevprimarener_mj_2017dollar_ppp_gdp numeric(9,7),
    co2_emissions_kt numeric(16,8),
    renewableseqpercprimarener numeric(12,11) NOT NULL,
    gdp_growth_perc numeric(12,11) NOT NULL,
    gdp_per_capita numeric(13,7),
    density_person_km2 smallint,
    landarea_km2 integer,
    latitude numeric(7,5),
    longitude numeric(8,5),
    CONSTRAINT sustainableenergy_pkey PRIMARY KEY (entity, year)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.sustainableenergy
    OWNER to postgres;






/*
    comando utilizzato per l'importazione
    per la stessa motivazione spiegata in precedenza,
    il percorso non è stato slavato dinamicamente.
    è stato sotituito con "PATH"
*/

--command " "\\copy public.sustainableenergy (entity, year, accesselectricitypercpop, accesscleanfuelcook, renewelectrgenpercap, financflowsdelevopusdoll, renewenershareperctotenerconsumpt, elecfossfuel_twh, elecnucl_twh, elecrenew_twh, lowcarelec_percelec, primenerconsumpt_kwh_percap, energyintlevprimarener_mj_2017dollar_ppp_gdp, co2_emissions_kt, renewableseqpercprimarener, gdp_growth_perc, gdp_per_capita, density_person_km2, landarea_km2, latitude, longitude) FROM 'C:/PATH/GLOBAL-DATA-ON-SUSTAINABLE-ENERGY (1)_CLEANED.CSV' DELIMITER ',' CSV HEADER ENCODING 'UTF8' QUOTE '\"' ESCAPE '''';""

/*
    Non funzionando, utilizzo la stesa procedura di WordData2023
    -   Tasto DX sulla tabella "sustainableenergy"
    -   Import/Export Data...
    -   Selezionando correttamente "global-data-on-sustainable-energy (1)_cleaned.csv" che mostra
        il DB ripulito e pronto all'importazione, come spiegato nei commenti
        precedenti, originato da "global-data-on-sustainable-energy (1).csv" e che vede le modifiche
        in "global-data-on-sustainable-energy (1)_cleaning_procedure.csv" e "global-data-on-sustainable-energy (1)_cleaning_procedure.xlsx"
*/


/*
    dopo questo step introduttivo, procedo con il join del dataset WorldData2023(nell versione a vista EnvEcoWorld2023) con sustainableenergy:
    -   l'obiettivo è avere un dataset unico, con chiave primaria rappresentata da
        -   Country
        -   anno
        la granularità è su base annuale.
    -   per monitorare agilmente alcune metriche negli anni, senza l'ausilio di plot, ho pensato di sfruttare un monitoraggio,
        generando la media mondiale annuale di specifici indicaotori, dei trend nel tempo
        -   produzioni nazionali di Twh di elettricità con fonti rinnovabili
        -   percentuali della quota di energia rinnovabile nazionale utilizzata in ragione del consumo totale nazionale
    -   le metriche nazionali, per anno vengono rimodulate in ragione della MEDIA MONDIALE ANNUALE. Quindi queste veranno intese
        come METRICHE ANNUALI RELATIVE
        -   > 1 se la metrica nazionale annuale rimane sopra il valore di SOGLIA della media mondiale annuale
        -   = 1 se la metrica nazionale annuale rispecchia quella mondiale
        -   < 1 se la metrica nazionale annuale è sotto il valore di SOGLIA della media mondiale annuale

        nationale_METRIC_yearXXXX_relative = national_metric_yearXXXX/world_average_yearXXXX  
*/

/*
    landarea_km2 è una variabile comune: monitorando la sua
    uguaglianza nel tempo posso escludere una delle due, permettendo
    la creazione di una vista
*/

select *
from EnvEcoWorld2023
inner join sustainableenergy
on country = entity;

/*
    sono 3417 osservazioni senza controllo
*/
select *
from EnvEcoWorld2023
inner join sustainableenergy
on country = entity
where EnvEcoWorld2023.landarea_km2 = sustainableenergy.landarea_km2;

/*
    stesso risultato: posso quindi eliminare una delle due
*/

ALTER TABLE sustainableenergy DROP COLUMN landarea_km2;

/*
    creo la vista EnvEco2023_SusEne del dataset con join
*/

create view EnvEco2023_SusEne as
select *
from EnvEcoWorld2023
inner join sustainableenergy
on country = entity;

select * from EnvEco2023_SusEne;




/*
    Caso 1: Electricity from renewables(TWh): Electricity generated from renewable sources (hydro, solar, wind, etc.) in terawatt-hours.
*/
create view elec_renew_twh as
select country, EnvEco2023_SusEne.year, elecrenew_twh, world_annual_average, elecrenew_twh/world_annual_average as elecrenew_relative,
rank() over(
	partition by EnvEco2023_SusEne.year
    order by elecrenew_twh/world_annual_average desc
)
from EnvEco2023_SusEne
inner join (select avg(elecrenew_twh) as world_annual_average, year
            from EnvEco2023_SusEne
            group by year) as year_avg
on EnvEco2023_SusEne.year = year_avg.year
where elecrenew_twh is not null or elecrenew_twh > 0
order by year desc, elecrenew_relative desc;


select *
from elec_renew_twh
where rank < 11 and country = 'China';

select *
from elec_renew_twh
where rank > 130 and elecrenew_relative !=0;


/*
    Come è possibile osservare dalla view appena creata,
    -   la Cina si mostra fra le prime nazioni per
        generazione di energia rinnovabile come Twh. Presenta
        una media largamente superiore alla media annuale mondiale
        'world_annual_average', con valori di produzione che passano
        dalle 15 volte la media mondiale al 2000 a 42 volte (come osservabile attraverso
        la variabile elecrenew_relative). Rispetto ai primi
        anni 2000, nel 2005 assume una posizione di leadership
        nella produzione (rank = 1) e la mantiene fino al 2020.
        Rispetto alla media mondiale, la produzione tenderebbe
        ad avere un andamento divergente. Ma occorre monitorare
        l'andamento con l'ausilio di un grafico.
    -   Nel periodo 2000-2020 possiamo osservare come, in larga parte,
        le posizioni di testa, rispetto alla media mondiale annuale, siano occupate
        dal blocco Canada-Stati Uniti-Brasile-Cina-Norvegia, con India e Giappone
        che si fanno strada nel tempo.
    
    Per quanto riguarda le posizioni in fondo alla classifica (ecludendo nazioni con campo
    vuoto o pari a 0) possiamo trovare, nel tempo, realtà depresse
    o che potrebbero aver iniziato progetti di conversione solo negli ultimi anni.
    quali:
    -   Oman, Niger, Somalia, Qatar, Libya
*/




/*
    percenutale "renewenershareperctotenerconsumpt" - Percentage of renewable energy in final energy consumption.
*/

create view elec_renew_share_cons as
select country, EnvEco2023_SusEne.year, renewenershareperctotenerconsumpt, world_annual_average, renewenershareperctotenerconsumpt/world_annual_average as renew_share_relative,
rank() over(
	partition by EnvEco2023_SusEne.year
    order by renewenershareperctotenerconsumpt/world_annual_average desc
)
from EnvEco2023_SusEne

inner join (select avg(renewenershareperctotenerconsumpt) as world_annual_average, year
            from EnvEco2023_SusEne
            group by year) as year_avg
on EnvEco2023_SusEne.year = year_avg.year
where (renewenershareperctotenerconsumpt is not null or renewenershareperctotenerconsumpt > 0) and (EnvEco2023_SusEne.year<2020)
order by year desc, renewenershareperctotenerconsumpt desc;

select *
from elec_renew_share_cons
where rank < 10;


select *
from elec_renew_share_cons
where rank > 150;

/*
    Analizzando la percentuale di energia rinnovabile nel consumo energetico finale,
    usando lo stesso principio, quindi
    -   rappresentando tale percentuale annuale nazionale come RELATIVA, ovvero
        -   come rapporto rispetto alla MEDIA mondiale annuale
    -   Nel tempo, nelle posizioni di testa, si attestano le regioni africane, con qualche
        comparsa di regioni asiatiche come il Nepal o il Buthan. Il risultato potrebbe
        destare stupore. La lezione che potrebbe darci il dato, in realtà, potrebbe essere
        il fatto che, benchè queste regioni non siano tra le principali produttrici di 
        energia rinnovabile, in queste vi sia in atto un processo di "educazione" all'energia
        pulita.
        Per intenderci: si tratta di regioni a scarso livello produttivo e probabilmente anche
        con una rete di distribuzione non troppo evoluta. Ma, la quota principale di consumo di
        energia viene disposta attraverso lo sfruttamento di energia rinnovabile.
        Sembrerebbe dunque che la direzione intrapresa, dagli investitori in territori
        depressi, sia quella del "salto generazionale", a livello di produzione e comportamento
        nei consumi, che veicolorebbe la comunità verso a un consumo di energia la cui produzione
        comporta un impatto meno rilevante in termini di produzione di co2 (come con le energie
        rinnovabili).
    -   Nelle regioni che troviamo in fondo alla classifica, vegono mostrate realtà, come Algeria,
        EAU, Qatar, Arabia Saudita, Oman, Bahrain, la cui quota di consumo di energia rinnovabile
        è prossimam allo zero. Trattandosi dei principali produttori di petrolio, il risultato
        non sembra destare stupore. Si tenga conta che, comunque, queste realtà stiano convertendo
        buona parte degli ingressi della vendita di petrolio in progetti green. Progetti che, seppur
        avveniristici, portano con sè parecchie contraddizioni.
*/