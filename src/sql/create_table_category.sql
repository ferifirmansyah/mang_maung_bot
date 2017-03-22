CREATE TABLE public.category
(
  cat_id character varying NOT NULL,
  cat_name character varying,
  cat_desc character varying,
  cat_type character varying,
  cat_parent character varying,
  created_by character varying,
  created_date timestamp with time zone,
  updated_by character varying,
  updated_date timestamp with time zone,
  CONSTRAINT category_pk PRIMARY KEY (cat_id)
)
WITH (
  OIDS=FALSE
);