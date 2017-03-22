CREATE OR REPLACE FUNCTION public.category_delete(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pCatId VARCHAR;
	vResult VARCHAR(100000);
	vStatus INT;
	vErrorCode VARCHAR;
	vErrorMessage VARCHAR;
	vIsExist VARCHAR;
BEGIN
	pCatId = vparams->>'cat_id';
	
	vStatus = 0;

	select cat_id from category into vIsExist where cat_id = pCatId;
	if vIsExist = '' or vIsExist is null then
		vStatus = -1;
		vErrorCode = 5008;
		vErrorMessage = 'Category does not exist';
		SELECT json_build_object('status',vStatus,'error_code',vErrorCode,'error_msg',vErrorMsg) INTO vResult;
	else
		DELETE FROM category
		WHERE cat_id = pCatId;


		DELETE FROM category
		WHERE cat_parent = pCatId;
		
		SELECT json_build_object('status',vStatus,'result', pCatId) INTO vResult;
	end if;

	RETURN vResult;

	EXCEPTION WHEN OTHERS THEN
	  vErrorCode = 120;
	  vErrorMessage = 'FAILED TO DELETE CATEGORY';
	  GET STACKED DIAGNOSTICS vErrorMessage = MESSAGE_TEXT;
	  SELECT json_build_object('status',-1,'error_code',vErrorCode,'error_msg',vErrorMessage,'result',null) INTO vResult;
	  RETURN vResult;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
