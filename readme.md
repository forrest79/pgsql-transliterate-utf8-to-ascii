PostgreSQL - transliterate UTF-8 to ASCII
=========================================

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/forrest79/pgsql-transliterateutf8toascii/blob/master/LICENSE.md)

Provides functionality to transliterate all UTF-8 characters to ASCII for PostgreSQL.

*Example:*

```sql
SELECT system.transliterate_to_ascii('Příliš žluťoučký kůň úpěl ďábelské ódy'); -- will print "Prilis zlutoucky kun upel dabelske ody"
SELECT system.transliterate_to_ascii('stößt'); -- will print "stosst"
SELECT system.transliterate_to_ascii('鍖椾喊'); -- will print "Chen Zhan Han"
SELECT system.transliterate_to_ascii('Питер. Лето. Любов'); -- will print "Piter. Leto. Liubov"
SELECT system.transliterate_to_ascii('10°C'); -- will print "10degC"
```

How to use it:
--------------

First, import `sql/transliterate-structure.sql` file, which create schema `system` with table `transliterate_to_ascii_rules` and function `transliterate_to_ascii`.
Second, import `sql/transliterate-data.sql` file with rules to transliterate all UTF-8 characters to ASCII.

```bash
psql dbname < sql/transliterate-structure.sql
psql dbname < sql/transliterate-data.sql
```

```sql
-- in query
SELECT system.transliterate_to_ascii('Příliš žluťoučký kůň úpěl ďábelské ódy');

-- in Pl/pgSQL
CREATE FUNCTION lower_unaccent(in_string character varying)
  RETURNS character varying AS
$BODY$
  RETURN lower(system.transliterate_to_ascii(in_string));
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 10;
```


Now, you can use function `system.transliterate_to_ascii` in your SQL queries or in PL/pgSQL functions and you will always get pure ASCII string.

How it works:
-------------

In `system.transliterate_to_ascii_rules` table are all transliterations `UTF-8 char` to `ASCII char(s)`. You can update update existing rule, if you're not satisfied with the original one.

Existing rules are taken from great Perl library **[Text-Unidecode](https://metacpan.org/release/Text-Unidecode)** from *Sean M. Burke*. You can use PHP skript `php/transliterate.php` to generate actual rules `sql/transliterate-data.sql` from library. Just copy all `lib/Text/Unidecode/*.pm` files to `php/Unidecode` and run `php php/transliterate.php`. You will get new rules definition and log in `php/output` and PHP arrays with rules in `php/UnidecodePHP`.

Database function `system.transliterate_to_ascii` is written in PL/pgSQL and just quick replace all UTF-8 characters in a given string by rules from `system.transliterate_to_ascii_rules` table.

Webalize string for URL slug:
-----------------------------

This mechanism is great for example for creating URL slugs from strings. You can have SQL function like this, that will create string only with a-z, 0-9 and - characters:

```sql
CREATE OR REPLACE FUNCTION webalize(in_string character varying)
  RETURNS character varying AS
$BODY$
  SELECT trim(BOTH '-' FROM regexp_replace(lower(system.transliterate_to_ascii(translate($1, '@°', 'a '))), '[^a-z0-9]+', '-', 'g'));
$BODY$
  LANGUAGE sql IMMUTABLE
  COST 1;
```

And create URL slugs like this:

```sql
SELECT webalize('Příliš žluťoučký kůň úpěl ďábelské ódy'); -- will print "prilis-zlutoucky-kun-upel-dabelske-ody"
SELECT webalize('stößt'); -- will print "stosst"
SELECT webalize('鍖椾喊'); -- will print "chen-zhan-han"
SELECT webalize('Питер. Лето. Любов'); -- will print "piter-leto-liubov"
SELECT webalize('10°C'); -- will print "10-c"
SELECT webalize('@utonomous'); -- will print "autonomous"
```
