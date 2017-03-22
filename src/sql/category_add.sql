CREATE OR REPLACE FUNCTION public.category_add(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pCatName VARCHAR;
	pCatDesc VARCHAR;
	pCatType VARCHAR;
	pCatParent VARCHAR;
	pBy VARCHAR;
	vResult VARCHAR(100000);
	vStatus INT;
	vErrorCode VARCHAR;
	vErrorMessage VARCHAR;
BEGIN
	pCatName = vparams->>'cat_name';
	pCatDesc = vparams->>'cat_desc';
	pCatType = vparams->>'cat_type';
	pCatParent = vparams->>'cat_parent';
	pBy = vparams->>'by';
	
	vStatus = 0;

	INSERT INTO public.category(cat_id,
				 cat_name,
				 cat_desc,
				 cat_type,
				 cat_parent,
				 created_date,
				 updated_date,
				 created_by,
				 updated_by)
	VALUES((TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDhh24') || lpad(CAST(nextval('cat_id_seq') AS text), 5, '0')),
		pCatName,
		pCatDesc,
		pCatType,
		pCatParent,
		CURRENT_TIMESTAMP,
		CURRENT_TIMESTAMP,
		pBy,
		pBy
	);
	
	SELECT json_build_object('status',vStatus,'result',array_to_json(array_agg(temp))) INTO vResult
	FROM (SELECT cat_name, cat_desc, cat_type,cat_parent
		FROM public.category 
		WHERE 	cat_name = pCatName AND
			cat_desc = pCatDesc AND
			cat_type = pCatType AND
			cat_parent = pCatParent)temp;

	RETURN vResult;

	EXCEPTION WHEN OTHERS THEN
	  vErrorCode = 120;
	  vErrorMessage = 'FAILED TO CREATE NEW CATEGORY';
	  GET STACKED DIAGNOSTICS vErrorMessage = MESSAGE_TEXT;
	  SELECT json_build_object('status',-1,'error_code',vErrorCode,'error_msg',vErrorMessage,'result',null) INTO vResult;
	  RETURN vResult;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;