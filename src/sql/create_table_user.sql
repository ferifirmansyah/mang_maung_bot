CREATE TABLE public."user"
(
  user_id character varying NOT NULL,
  password character varying,
  fullname character varying,
  refresh_token character varying,
  role character varying,
  created_by character varying,
  created_date timestamp with time zone,
  updated_by character varying,
  updated_date timestamp with time zone,
  CONSTRAINT user_pk PRIMARY KEY (user_id)
)
WITH (
  OIDS=FALSE
);