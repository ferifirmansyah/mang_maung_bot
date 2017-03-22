CREATE OR REPLACE FUNCTION public.category_getlist()
  RETURNS json AS
$BODY$
DECLARE
	vResult json;
	vStatus INT;
	vErrorCode INT;
	vErrorMsg varchar;
BEGIN
	vStatus = 0;

	SELECT json_build_object('status',vStatus,'result',array_to_json(array_agg(temp))) INTO vResult
	FROM (SELECT
		  c.cat_id,c.cat_name,c.cat_desc, c.cat_type,c.cat_parent,
		  CASE WHEN f.cat_id is not NULL THEN json_agg(f.*) ELSE null END AS file
		FROM category c
		LEFT OUTER JOIN (select file_id,file_name,file_desc,file_type,file_path,cat_id from file) f USING (cat_id)
		GROUP BY c.cat_id,c.cat_name,c.cat_desc, c.cat_type,c.cat_parent,f.cat_id)as temp;

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