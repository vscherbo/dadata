-- DROP FUNCTION arc_energo.dd_addr(text);

CREATE OR REPLACE FUNCTION arc_energo.dd_addr(arg_addr text)
 RETURNS text
 LANGUAGE sql
AS $function$
SELECT regexp_replace(arg_addr, 'республика|[\s,]город|[\s,]ул(\.)*|п\.|ВКО|\(.*\)|\d*[\s,]|[\s,]кв', ' ', 'gi')
as RESULT;
$function$
;

