# PostgreSQL - transliterate UTF-8 to ASCII

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/forrest79/pgsql-transliterate-utf8-to-ascii/blob/master/LICENSE.md)
[![Build](https://github.com/forrest79/pgsql-transliterate-utf8-to-ascii/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/forrest79/pgsql-transliterate-utf8-to-ascii/actions/workflows/build.yml)

Provides functionality to transliterate all UTF-8 characters to ASCII in pure PostgreSQL.

**Example:**

```sql
SELECT system.transliterate_to_ascii('Příliš žluťoučký kůň úpěl ďábelské ódy'); -- will print "Prilis zlutoucky kun upel dabelske ody"
SELECT system.transliterate_to_ascii('stößt'); -- will print "stosst"
SELECT system.transliterate_to_ascii('鍖椾喊'); -- will print "Chen Zhan Han"
SELECT system.transliterate_to_ascii('Питер. Лето. Любов'); -- will print "Piter. Leto. Liubov"
SELECT system.transliterate_to_ascii('10°C'); -- will print "10degC"
```

## How to use it:

**First**, import `dist/transliterate-structure.sql` file, which create schema `system` with table `transliterate_to_ascii_rules` and function `transliterate_to_ascii`.

**Second**, import `dist/transliterate-data.sql` file with rules to transliterate all UTF-8 characters to ASCII.

Optional **third**, import `dist/transliterate-webalize.sql` file with DB function `webalize()` that provide converting string for nice URLs

```bash
psql dbname < dist/transliterate-structure.sql
psql dbname < dist/transliterate-data.sql
psql dbname < dist/transliterate-webalize.sql
```
Now, you can use function `system.transliterate_to_ascii` in your SQL queries or in PL/pgSQL functions, and you will always get pure ASCII string.

```sql
-- in query
SELECT system.transliterate_to_ascii('Příliš žluťoučký kůň úpěl ďábelské ódy');

-- in Pl/pgSQL
CREATE FUNCTION lower_unaccent(in_string character varying)
  RETURNS character varying AS
$BODY$
  RETURN lower(system.transliterate_to_ascii(in_string));
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
```


## How it works:

In `system.transliterate_to_ascii_rules` table are all transliterations form `UTF-8` chars to `ASCII` chars. You can update existing rules, if you're not satisfied with the original one.

Existing rules are taken from the great Perl library **[Text-Unidecode](https://metacpan.org/release/Text-Unidecode)** by *Sean M. Burke*. You can use PHP script `bin/build-sql` to generate actual rules `dist/transliterate-data.sql` from library source.

Copy all `lib/Text/Unidecode/*.pm` files to `data/Unidecode` and run `bin/build-sql`. You will get new rules definition and log in `data` directory.

Database function `system.transliterate_to_ascii` is written in `PL/pgSQL` and just quick replace all UTF-8 characters in a given string by rules from `system.transliterate_to_ascii_rules` table.


## Webalize string for URL slug:

This mechanism is great for example for creating URL slugs from strings. Just import into DB also file `dist/transliterate-webalize.sql`.

Then create URL slugs like this:

```sql
SELECT system.webalize('Příliš žluťoučký kůň úpěl ďábelské ódy'); -- will print "prilis-zlutoucky-kun-upel-dabelske-ody"
SELECT system.webalize('stößt'); -- will print "stosst"
SELECT system.webalize('鍖椾喊'); -- will print "chen-zhan-han"
SELECT system.webalize('Питер. Лето. Любов'); -- will print "piter-leto-liubov"
SELECT system.webalize('10°C'); -- will print "10-c"
SELECT system.webalize('@utonomous'); -- will print "autonomous"
```


## Unaccent

On Debian/Ubuntu copy `dist/transliterate_utf8_to_ascii.rules` to `/usr/share/postgresql/15/tsearch_data/transliterate_utf8_to_ascii.rules`.

```sql
ALTER TEXT SEARCH DICTIONARY unaccent (RULES='transliterate_utf8_to_ascii');
SELECT unaccent('Hôtel');

CREATE TEXT SEARCH DICTIONARY transliterate_utf8_to_ascii (TEMPLATE = unaccent, RULES='transliterate_utf8_to_ascii');
SELECT unaccent('transliterate_utf8_to_ascii', 'Hôtel');
```


# How to build

The easiest way to get Perl library source is in Debian like Linux system with `cpan` command.

```bash
cpan Text::Unidecode
```

Sources are placed in `/usr/share/perl5/Text` directory. Just copy `*.pm` from `/usr/share/perl5/Text/Unidecode` directory to `data/Unidecode` and run `bin/build-sql` (you will need PHP > 8.0 installed on the system). 
