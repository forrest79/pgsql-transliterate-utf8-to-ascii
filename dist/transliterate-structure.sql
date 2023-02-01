CREATE SCHEMA IF NOT EXISTS system;

CREATE TABLE IF NOT EXISTS system.transliterate_to_ascii_rules
(
  chr text NOT NULL,
  trans text,
  CONSTRAINT transliterate_to_ascii_rules_pkey PRIMARY KEY (chr)
);

CREATE OR REPLACE FUNCTION system.transliterate_to_ascii(in_text text)
  RETURNS text AS
$BODY$
DECLARE
  r system.transliterate_to_ascii_rules;
BEGIN
  FOR r IN SELECT chr, trans FROM system.transliterate_to_ascii_rules WHERE chr IN (
    SELECT source_chr
      FROM (
        SELECT unnest(regexp_split_to_array(in_text, '')) AS source_chr
      ) x
     WHERE ascii(x.source_chr) > 127
  )
  LOOP
    in_text = replace(in_text, r.chr, r.trans);
  END LOOP;

  RETURN trim(in_text);
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


/*
-- PURE SQL VERSION, BUT SLOWER (approximately 1,5-2x)
CREATE OR REPLACE FUNCTION system.transliterate_to_ascii(in_text text)
  RETURNS text AS
$BODY$
  WITH RECURSIVE transliterate(text, arr_chr, arr_trans, i) AS (
    SELECT
        CASE WHEN array_length(replacements.arr_chr, 1) >= 1 THEN
          replace(in_text, replacements.arr_chr[1], replacements.arr_trans[1])
        ELSE
          in_text
        END, replacements.arr_chr, replacements.arr_trans, 2
      FROM (
        SELECT array_agg(chr) AS arr_chr, array_agg(trans) AS arr_trans
          FROM system.transliterate_to_ascii_rules
         WHERE chr IN (
           SELECT chr
             FROM (
               SELECT unnest(regexp_split_to_array(in_text, '')) AS chr
             ) x
            WHERE ascii(x.chr) > 127
         )
      ) AS replacements

    UNION

    SELECT replace(text, transliterate.arr_chr[i], transliterate.arr_trans[i]), transliterate.arr_chr, transliterate.arr_trans, i + 1
      FROM transliterate
     WHERE array_length(transliterate.arr_chr, 1) >= i
  )
    SELECT trim(text) FROM transliterate ORDER BY i DESC LIMIT 1;
$BODY$
  LANGUAGE sql IMMUTABLE;
*/
