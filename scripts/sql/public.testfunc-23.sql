CREATE OR REPLACE FUNCTION public.testfunc(arg integer)
 RETURNS text
 LANGUAGE sql
AS $function$
select 'The answer is ' || arg::text as the_answer
$function$
