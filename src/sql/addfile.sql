-- Function: public.addfile(json)

-- DROP FUNCTION public.addfile(json);

CREATE OR REPLACE FUNCTION public.addfile(vparams json)
  RETURNS json AS
$BODY$
DECLARE
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
	
BEGIN
	pFName = vparams->>'pFName';
	pFDesc = vparams->>'pFDesc';
	pFType = vparams->>'pFType';
	pFPath = vparams->>'pFPath';
	pFDesc = vparams->>'pFDesc';
	pUName = vparams->>'pUName';
	pCId = vparams->>'pCId';
	vStatus = 0;

	IF (pFName = '' or pFName IS NULL) or (pFPath = '' or pFPath IS NULL) or (pCId = '' or pCId IS NULL) THEN
		vStatus = -1;
		vErrorCode = 5005;
		vErrorMsg = 'Invalid Parameters';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	ELSE 
		INSERT INTO public.file
			(file_id, file_name, file_desc, file_type, file_path, cat_id, 
            created_by,created_date,updated_by, updated_date)
		VALUES
			((TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDhh24miss') || lpad(CAST(nextval('public.file_id_seq') AS text), 6, '0')),
			pFName,
			pFDesc,
			pFType,
			pFPath,
			pCId,
			pUName,
			CURRENT_TIMESTAMP,
			pUName,
			CURRENT_TIMESTAMP
			) RETURNING file_id INTO vResult;
		SELECT json_build_object('status',vStatus,'result',vResult) INTO vResult;
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
ALTER FUNCTION public.addfile(json)
  OWNER TO postgres;
