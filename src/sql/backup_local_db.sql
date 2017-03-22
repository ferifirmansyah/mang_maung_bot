--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

-- Started on 2017-02-01 17:59:14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- TOC entry 570 (class 1255 OID 26907)
-- Name: addfile(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION addfile(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
	pCId = vparams->>'pCId';
	pUName = vparams->>'pUName';
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
$$;


ALTER FUNCTION public.addfile(vparams json) OWNER TO postgres;

--
-- TOC entry 565 (class 1255 OID 26903)
-- Name: audit_add(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION audit_add(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.audit_add(vparams json) OWNER TO postgres;

--
-- TOC entry 569 (class 1255 OID 26880)
-- Name: category_add(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION category_add(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.category_add(vparams json) OWNER TO postgres;

--
-- TOC entry 540 (class 1255 OID 26883)
-- Name: category_delete(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION category_delete(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.category_delete(vparams json) OWNER TO postgres;

--
-- TOC entry 349 (class 1255 OID 26879)
-- Name: category_getlist(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION category_getlist() RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.category_getlist() OWNER TO postgres;

--
-- TOC entry 564 (class 1255 OID 26882)
-- Name: category_update(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION category_update(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.category_update(vparams json) OWNER TO postgres;

--
-- TOC entry 567 (class 1255 OID 26906)
-- Name: deletefile(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION deletefile(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.deletefile(vparams json) OWNER TO postgres;

--
-- TOC entry 568 (class 1255 OID 26905)
-- Name: editfile(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION editfile(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.editfile(vparams json) OWNER TO postgres;

--
-- TOC entry 566 (class 1255 OID 26904)
-- Name: login(json); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION login(vparams json) RETURNS json
    LANGUAGE plpgsql
    AS $$

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

$$;


ALTER FUNCTION public.login(vparams json) OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 26901)
-- Name: audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
    CYCLE;


ALTER TABLE audit_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 292 (class 1259 OID 26884)
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE audit_log (
    id character varying NOT NULL,
    user_id character varying,
    created_date timestamp with time zone,
    action character varying,
    details character varying(2000)
);


ALTER TABLE audit_log OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 26829)
-- Name: cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
    CYCLE;


ALTER TABLE cat_id_seq OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 26802)
-- Name: category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE category (
    cat_id character varying NOT NULL,
    cat_name character varying,
    cat_desc character varying,
    cat_type character varying,
    cat_parent character varying,
    created_by character varying,
    created_date timestamp with time zone,
    updated_by character varying,
    updated_date timestamp with time zone
);


ALTER TABLE category OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 26810)
-- Name: file; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE file (
    file_id character varying NOT NULL,
    file_name character varying,
    file_desc character varying,
    file_type character varying,
    file_path character varying,
    cat_id character varying,
    created_by character varying,
    created_date timestamp with time zone,
    updated_by character varying,
    updated_date timestamp with time zone
);


ALTER TABLE file OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 26831)
-- Name: file_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999
    CACHE 1
    CYCLE;


ALTER TABLE file_id_seq OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 26833)
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "user" (
    user_id character varying NOT NULL,
    password character varying,
    fullname character varying,
    refresh_token character varying,
    role character varying,
    created_by character varying,
    created_date timestamp with time zone,
    updated_by character varying,
    updated_date timestamp with time zone
);


ALTER TABLE "user" OWNER TO postgres;

--
-- TOC entry 2687 (class 0 OID 0)
-- Dependencies: 293
-- Name: audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('audit_id_seq', 12, true);


--
-- TOC entry 2679 (class 0 OID 26884)
-- Dependencies: 292
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011600004', 'admin', '2017-02-01 16:16:32.322639+07', 'getCatAndFile', 'aadddddddddddddddddddddddddddddddddddddddddddddsssssssssssssssssssssssss');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011600005', 'admin', '2017-02-01 16:24:48.399901+07', 'getCatAndFile', '{
    "name": "asd",
    "haud": "asda",
    "kwwaw": "adasd"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700006', 'admin', '2017-02-01 17:16:01.932602+07', 'Add New Category', '{
    "cat_name": "Report_Insert3",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba3",
    "cat_parent": "1"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700007', 'admin', '2017-02-01 17:19:17.51471+07', 'Edit Category', '{
    "cat_name": "Report_Insert30",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba30",
    "cat_parent": "1",
    "cat_id": "201702011700003"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700008', 'admin', '2017-02-01 17:20:11.62603+07', 'Delete Category', '{
    "cat_id": "201702011700003"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700009', 'admin', '2017-02-01 17:24:43.490392+07', 'Add New Category', '{
    "cat_name": "Report_Insert44",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba4444",
    "cat_parent": "1"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700010', 'admin', '2017-02-01 17:26:42.056601+07', 'Add New Category', '{
    "cat_name": "Report_Insert44123123",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba4444123123",
    "cat_parent": "1",
    "by": "admin"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700011', 'admin', '2017-02-01 17:29:01.256935+07', 'Add New Category', '{
    "cat_name": "Report_Insert555555",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba1111111",
    "cat_parent": "1",
    "by": "admin"
}');
INSERT INTO audit_log (id, user_id, created_date, action, details) VALUES ('201702011700012', 'admin', '2017-02-01 17:33:25.837841+07', 'Edit Category', '{
    "cat_name": "Report_Insert555555-keupdate",
    "cat_type": "directory",
    "cat_desc": "Report Insert Coba-Coba1111111-keupdate",
    "cat_parent": "1",
    "cat_id": "201702011700006",
    "by": "admin"
}');


--
-- TOC entry 2688 (class 0 OID 0)
-- Dependencies: 288
-- Name: cat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cat_id_seq', 6, true);


--
-- TOC entry 2674 (class 0 OID 26802)
-- Dependencies: 286
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('1', 'Report', 'Report General Explanation', 'directory', NULL, 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('2', 'Framework', 'Framework General  Description', 'directory', NULL, 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('3', 'Processes', 'Processes General Description', 'directory', NULL, 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('4', 'Report A', 'Report A General Description', 'container', '1', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('5', 'Report B', 'Report B General Description', 'container', '1', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('6', 'Report C', 'Report C General Description', 'directory', '1', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('7', 'Report C1', 'Report C1 General Description', 'container', '6', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('8', 'Report C2', 'Report C2 General Description', 'container', '6', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('9', 'Framework A', 'Framework A General Description', 'container', '2', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('10', 'Processes A', 'Processes A General Description', 'container', '3', 'admin', NULL, 'admin', NULL);
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('201702011700001', 'Report_Insert', 'Report Insert Coba-Coba', 'directory', '1', NULL, '2017-02-01 17:11:49.778181+07', NULL, '2017-02-01 17:11:49.778181+07');
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('201702011700002', 'Report_Insert2', 'Report Insert Coba-Coba2', 'directory', '1', NULL, '2017-02-01 17:14:36.601039+07', NULL, '2017-02-01 17:14:36.601039+07');
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('201702011700004', 'Report_Insert44', 'Report Insert Coba-Coba4444', 'directory', '1', NULL, '2017-02-01 17:24:43.434381+07', NULL, '2017-02-01 17:24:43.434381+07');
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('201702011700005', 'Report_Insert44123123', 'Report Insert Coba-Coba4444123123', 'directory', '1', NULL, '2017-02-01 17:26:42.024094+07', NULL, '2017-02-01 17:26:42.024094+07');
INSERT INTO category (cat_id, cat_name, cat_desc, cat_type, cat_parent, created_by, created_date, updated_by, updated_date) VALUES ('201702011700006', 'Report_Insert555555-keupdate', 'Report Insert Coba-Coba1111111-keupdate', 'directory', '1', 'admin', '2017-02-01 17:29:01.225929+07', 'admin', '2017-02-01 17:33:25.809835+07');


--
-- TOC entry 2675 (class 0 OID 26810)
-- Dependencies: 287
-- Data for Name: file; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO file (file_id, file_name, file_desc, file_type, file_path, cat_id, created_by, created_date, updated_by, updated_date) VALUES ('1', 'Telkomsel Operating Framework', 'Telkomsel Operating Framework', 'pdf', 'C:/Telkomsel Operating Framework.pdf', '4', NULL, NULL, NULL, NULL);
INSERT INTO file (file_id, file_name, file_desc, file_type, file_path, cat_id, created_by, created_date, updated_by, updated_date) VALUES ('2', 'Telkomsel Operation asdasd', 'asdas', 'docx', NULL, '4', NULL, NULL, NULL, NULL);
INSERT INTO file (file_id, file_name, file_desc, file_type, file_path, cat_id, created_by, created_date, updated_by, updated_date) VALUES ('3', 'Telkomsel asda', 'asda', 'pdf', NULL, '5', NULL, NULL, NULL, NULL);


--
-- TOC entry 2689 (class 0 OID 0)
-- Dependencies: 289
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- TOC entry 2678 (class 0 OID 26833)
-- Dependencies: 290
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "user" (user_id, password, fullname, refresh_token, role, created_by, created_date, updated_by, updated_date) VALUES ('admin', 'admin', 'admin_tsel', NULL, 'admin', NULL, NULL, NULL, NULL);


--
-- TOC entry 2558 (class 2606 OID 26891)
-- Name: audit_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_pk PRIMARY KEY (id);


--
-- TOC entry 2551 (class 2606 OID 26809)
-- Name: category_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY category
    ADD CONSTRAINT category_pk PRIMARY KEY (cat_id);


--
-- TOC entry 2553 (class 2606 OID 26817)
-- Name: file_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_pk PRIMARY KEY (file_id);


--
-- TOC entry 2556 (class 2606 OID 26840)
-- Name: user_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- TOC entry 2554 (class 1259 OID 26823)
-- Name: fki_file_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_file_fk ON file USING btree (cat_id);


--
-- TOC entry 2559 (class 2606 OID 26824)
-- Name: file_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fk FOREIGN KEY (cat_id) REFERENCES category(cat_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2686 (class 0 OID 0)
-- Dependencies: 30
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2017-02-01 17:59:15

--
-- PostgreSQL database dump complete
--

