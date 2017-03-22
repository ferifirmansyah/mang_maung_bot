-- Function: public.login(json)

-- DROP FUNCTION public.login(json);

CREATE OR REPLACE FUNCTION public.changepass(vparams json)
  RETURNS json AS
$BODY$

DECLARE
	vUserId varchar;
	vOldPassword varchar;
	vNewPassword varchar;

	vCurPassword varchar DEFAULT '';

	vResult varchar;
	vErrorCode int;
	vErrorMsg varchar;
	vStatus int DEFAULT 0;
BEGIN
	vUserId = vparams->>'userid';
	vOldPassword = vparams->>'oldpass';
	vNewPassword = vparams->>'newpass';

	SELECT password 
	INTO vCurPassword 
	FROM public.user
	WHERE user_id = pUserid;

	IF pCurPassword = '' THEN
	   SELECT json_build_object('status',1,'error_code',103,'error_msg','Invalid password','result',null) into vResult;
	   RETURN vResult;
	ELSE
	   UPDATE public.user
	   SET password = vNewPassword
	   WHERE user_id = vUserId;
	   SELECT json_build_object('status',0,'result','OK') into vResult;
	   RETURN vResult;
	END IF;
	
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
  OWNER TO fpeyygwqqmjndw;
