-- Function: public.deletefile(json)

-- DROP FUNCTION public.deletefile(json);

CREATE OR REPLACE FUNCTION public.deletefile(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pFId varchar;
	vStatus INT;
	vErrorCode INT;	
	vErrorMsg varchar;
	vResult varchar;
	vTemp varchar;
BEGIN
	pFId = vparams->>'pFId';
	vStatus = 0;

	IF (pFId  = '' or pFId  IS NULL) THEN
		vStatus = -1;
		vErrorCode = 5005;
		vErrorMsg = 'Invalid Parameters';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	ELSE
		select file_path from public.file where file_id = pFId into vTemp;
		DELETE FROM public.file
		WHERE file_id = PFId;
		SELECT json_build_object('status',vStatus,'result',vTemp) INTO vResult;
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
ALTER FUNCTION public.deletefile(json)
  OWNER TO postgres;
