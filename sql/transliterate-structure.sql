CREATE SCHEMA IF NOT EXISTS system;

CREATE TABLE IF NOT EXISTS system.transliterate_to_ascii_rules
(
  original character varying NOT NULL,
  transliterate character varying,
  CONSTRAINT transliterate_to_ascii_rules_pkey PRIMARY KEY (original)
);

CREATE OR REPLACE FUNCTION system.transliterate_to_ascii(in_text character varying)
  RETURNS character varying AS
$BODY$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT original, transliterate FROM system.transliterate_to_ascii_rules WHERE original IN (
    SELECT chr
      FROM (
        SELECT unnest(regexp_split_to_array(in_text, '')) AS chr
      ) x
     WHERE x.chr NOT SIMILAR TO '[a-zA-Z1-9]'
     GROUP BY x.chr
  )
  LOOP
    in_text = replace(in_text, r.original, r.transliterate);
  END LOOP;

  RETURN trim(in_text);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 10;

/*
-- webalize strings (by using only a-z, 0-9 and - characters
CREATE OR REPLACE FUNCTION webalize(in_string character varying)
  RETURNS character varying AS
$BODY$
  SELECT trim(BOTH '-' FROM regexp_replace(lower(system.transliterate_to_ascii(translate($1, '@°', 'a '))), '[^a-z0-9]+', '-', 'g'));
$BODY$
  LANGUAGE sql IMMUTABLE
  COST 1;
*/
