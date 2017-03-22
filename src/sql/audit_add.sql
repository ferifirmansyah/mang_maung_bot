CREATE OR REPLACE FUNCTION public.audit_add(vparams json)
  RETURNS json AS
$BODY$
DECLARE
	pUserId VARCHAR;
	pAction VARCHAR;
	pDetails VARCHAR(100000);
	vResult VARCHAR(100000);
	vStatus INT;
	vErrorCode VARCHAR;
	vErrorMessage VARCHAR;
BEGIN
	pUserId = vparams->>'user_id';
	pAction = vparams->>'action';
	pDetails = vparams->>'details';
	
	vStatus = 0;

	INSERT INTO public.audit_log(id,
				 user_id,
				 created_date,
				 action,
				 details)
	VALUES((TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDhh24') || lpad(CAST(nextval('audit_id_seq') AS text), 5, '0')),
		pUserId,
		CURRENT_TIMESTAMP,
		pAction,
		pDetails
	);
	
	SELECT json_build_object('status',vStatus,'result',array_to_json(array_agg(temp))) INTO vResult
	FROM (SELECT user_id, action, details
		FROM public.audit_log 
		WHERE 	user_id = pUserId AND
			action = pAction AND
			details = pDetails)temp;

	RETURN vResult;

	EXCEPTION WHEN OTHERS THEN
	  vErrorCode = 120;
	  vErrorMessage = 'FAILED TO INSERT AUDIT';
	  GET STACKED DIAGNOSTICS vErrorMessage = MESSAGE_TEXT;
	  SELECT json_build_object('status',-1,'error_code',vErrorCode,'error_msg',vErrorMessage,'result',null) INTO vResult;
	  RETURN vResult;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;