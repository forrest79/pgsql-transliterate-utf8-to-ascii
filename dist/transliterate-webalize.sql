-- webalize strings (by using only a-z, 0-9 and - characters)

CREATE OR REPLACE FUNCTION system.webalize(in_string text)
  RETURNS text AS
$BODY$
  SELECT trim(BOTH '-' FROM regexp_replace(lower(system.transliterate_to_ascii(translate(in_string, '@°', 'a '))), '[^a-z0-9]+', '-', 'g'));
$BODY$
  LANGUAGE sql IMMUTABLE;
