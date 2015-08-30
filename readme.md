# Nástroj na tvorbu rozvrhu MUNI

Tento nástroj slúži ako pomôcka na tvorbu rozvrhu pre MUNI.

## Ako ho nainštalovať?

Na localhoste stačí mať XAMPP, netreba mať DB. Na komplikáciu Coffee, Jade a Less odporúčam Prepos.
Ak netušíš, o čom rozprávam, kašli nato a využi online verziu na http://schedule.comper.sk

## Chcem sa zapojiť

To je super. Na druhej strane neľahká úloha. Mal som málo času na tvorbu scriptu, takže ťa nesmú prekvapiť hlúpo pomenované premenné/funkcie, chýbajúce komentáre a podobne.
V podstate vždy bolo niečo užitočnejšie na práci než údržba a to je vlastne dôvod, prečo je to open source - nech to nemusím udržiavať (len) ja :D

Ak to chceš spraviť správne odporúčam forknúť si vetvu, spraviť zmeny a zaslať pull-request. Ak máš otázky ku kódu nato sú tu Issues.

## Kam by to malo ďalej smerovať podľa mňa?

Aktuálna verzia rieši najväčší problém, napriek tomu sú tu dve cesty, ako to ďalej rozvinúť:
1. Vytiahnuť vykresľovacú časť, vytvoriť plugin do prehliadača a parsovať rovno v IS v reálnom čase (pri zobrazení rozvrhu). To by zmazalo všetky bezpečnostné rizika, potrebu akejkoľvek stránky ale nemalo všetky featury.
2. Vytvoriť DB a umožniť výsledky ukladať a prípadne vytvoriť API, ktoré by sa dalo využiť inými službami (napríklad mobilná app, zdieľanie s kamarátom alebo čokoľvek). Asi najlepší spôsob tu vidím neukladť heslo, iba UČO (ako identifikátor) a ponechať prihlasovanie na ISe.