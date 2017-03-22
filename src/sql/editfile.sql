
-- Function: public.editfile(json)

-- DROP FUNCTION public.editfile(json);

CREATE OR REPLACE FUNCTION public.editfile(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pFId varchar;
	pFName varchar;
	pFDesc varchar;
	pFType varchar;
	pFPath varchar;
	pUName varchar;
	pCId varchar;
	vStatus INT;
	vErrorCode INT;	
	vErrorMsg varchar;
	vResult varchar;
	vTemp varchar;
BEGIN
	pFId = vparams->>'pFId';
	pFName = vparams->>'pFName';
	pFDesc = vparams->>'pFDesc';
	pFType = vparams->>'pFType';
	pFPath = vparams->>'pFPath';
	pFDesc = vparams->>'pFDesc';
	pCId = vparams->>'pCId';
	pUName = vparams->>'pUName';
	vStatus = 0;

	IF (pFId  = '' or pFId  IS NULL) THEN
		vStatus = -1;
		vErrorCode = 5005;
		vErrorMsg = 'Invalid Parameters';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	ELSE 
		select file_path from public.file where file_id = pFId into vTemp;
		IF pFName = 'EXISTING' then
			select file_name,file_type,file_path from public.file where file_id = pFId into pFName,pFType,pFPath;
		end if;
		UPDATE public.file
		   SET file_name=pFName, file_desc=pFDesc, file_type=pFType, file_path=pFPath, 
		       cat_id=pCId, updated_date=CURRENT_TIMESTAMP,updated_by=pUName
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
ALTER FUNCTION public.editfile(json)
  OWNER TO postgres;