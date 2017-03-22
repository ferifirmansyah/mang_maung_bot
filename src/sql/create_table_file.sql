CREATE TABLE public.file
(
  file_id character varying NOT NULL,
  file_name character varying,
  file_desc character varying,
  file_type character varying,
  file_path character varying,
  cat_id character varying,
  created_by character varying,
  created_date timestamp with time zone,
  updated_by character varying,
  updated_date timestamp with time zone,
  CONSTRAINT file_pk PRIMARY KEY (file_id),
  CONSTRAINT file_fk FOREIGN KEY (cat_id)
      REFERENCES tsel.category (cat_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);