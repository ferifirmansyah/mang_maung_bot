-- Function: public.login(json)

-- DROP FUNCTION public.login(json);

CREATE OR REPLACE FUNCTION public.login(vparams json)
  RETURNS json AS
$BODY$

DECLARE
	pUserid varchar;
	pPassword varchar;
	vStatus INT;
	vErrorCode INT;	
	vErrorMsg varchar;
	vLogin varchar;
	vResult varchar;
BEGIN
	pUserid = vparams->>'userid';
	pPassword = vparams->>'password';
	vStatus = 0;

	IF (pUserid = '' or pUserid IS NULL) or (pPassword = '' or pPassword IS NULL) then
		vStatus = -1;
		vErrorCode = 1001;
		vErrorMsg = 'Invalid login parameters';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	ELSE
		SELECT json_build_object('status',vStatus,'result',array_agg(temp)) INTO vResult
		FROM (select * from "user" where user_id = pUserid and password = pPassword) temp;
	END IF;
	RETURN vResult;
	EXCEPTION WHEN OTHERS THEN
	vErrorCode = 120;
	vStatus = -1;
	GET STACKED DIAGNOSTICS vErrorMsg = MESSAGE_TEXT;
	SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg,'result',null) into vResult;
	RETURN vResult;
END

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.login(json)
  OWNER TO postgres;
