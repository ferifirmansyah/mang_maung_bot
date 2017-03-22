-- Function: public.category_update(json)

-- DROP FUNCTION public.category_update(json);

CREATE OR REPLACE FUNCTION public.category_update(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pCatId VARCHAR;
	pCatName VARCHAR;
	pCatDesc VARCHAR;
	pCatType VARCHAR;
	pCatParent VARCHAR;
	pBy VARCHAR;
	vResult VARCHAR(100000);
	vStatus INT;
	vErrorCode VARCHAR;
	vErrorMessage VARCHAR;
	vIsExist VARCHAR;
BEGIN
	pCatId = vparams->>'cat_id';
	pCatName = vparams->>'cat_name';
	pCatDesc = vparams->>'cat_desc';
	pCatType = vparams->>'cat_type';
	pCatParent = vparams->>'cat_parent';
	pBy = vparams->>'by';
	
	vStatus = 0;

	select cat_id from category into vIsExist where cat_id = pCatId;
	if vIsExist = '' or vIsExist is null then
		vStatus = -1;
		vErrorCode = 5008;
		vErrorMessage = 'Category does not exist';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	else
		update category set 
		cat_name = pCatName,
		cat_desc = pCatDesc,
		cat_type = pCatType,
		cat_parent = pCatParent,
		updated_by = pBy,
		updated_date = CURRENT_TIMESTAMP
		where cat_id = pCatId;
		SELECT json_build_object('status',vStatus,'result', pCatId) INTO vResult;
	end if;

	RETURN vResult;

	EXCEPTION WHEN OTHERS THEN
	  vErrorCode = 120;
	  vErrorMessage = 'FAILED TO UPDATE CATEGORY';
	  GET STACKED DIAGNOSTICS vErrorMessage = MESSAGE_TEXT;
	  SELECT json_build_object('status',-1,'error_code',vErrorCode,'error_msg',vErrorMessage,'result',null) INTO vResult;
	  RETURN vResult;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;