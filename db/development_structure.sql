--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- Name: gtrgm; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gtrgm;


--
-- Name: gtrgm_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_in(cstring) RETURNS gtrgm
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'gtrgm_in';


--
-- Name: gtrgm_out(gtrgm); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_out(gtrgm) RETURNS cstring
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'gtrgm_out';


--
-- Name: gtrgm; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gtrgm (
    INTERNALLENGTH = variable,
    INPUT = gtrgm_in,
    OUTPUT = gtrgm_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: audit_changes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION audit_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
                DECLARE
                  col information_schema.columns %ROWTYPE;
                  new_value text;
                  old_value text;
                  primary_key_column varchar;
                  primary_key_value varchar;
                  user_identifier integer;
                  unique_name varchar;
                  column_name varchar;
                BEGIN
                  FOR col IN SELECT * FROM information_schema.columns WHERE table_name = TG_RELNAME LOOP
                    new_value := NULL;
                    old_value := NULL;
                    primary_key_column := NULL;
                    primary_key_value:= NULL;
                    user_identifier := current_setting('audit.user_id');
                    unique_name := current_setting('audit.user_unique_name');
                    column_name := col.column_name;

                    EXECUTE 'SELECT pg_attribute.attname
                             FROM pg_index, pg_class, pg_attribute
                             WHERE pg_class.oid = $1::regclass
                             AND indrelid = pg_class.oid
                             AND pg_attribute.attrelid = pg_class.oid
                             AND pg_attribute.attnum = any(pg_index.indkey)
                             AND indisprimary'
                    INTO primary_key_column USING TG_RELNAME;

                    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
                      EXECUTE 'SELECT CAST($1 . '|| column_name ||' AS TEXT)' INTO new_value USING NEW;
                      IF primary_key_column IS NOT NULL THEN
                        EXECUTE 'SELECT CAST($1 . '|| primary_key_column ||' AS VARCHAR)' INTO primary_key_value USING NEW;
                      END IF;
                    END IF;
                    IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
                      EXECUTE 'SELECT CAST($1 . '|| column_name ||' AS TEXT)' INTO old_value USING OLD;
                      IF primary_key_column IS NOT NULL THEN
                        EXECUTE 'SELECT CAST($1 . '|| primary_key_column ||' AS VARCHAR)' INTO primary_key_value USING OLD;
                      END IF;
                    END IF;

                    IF TG_RELNAME = 'users' AND column_name = 'last_accessed_at' THEN
                      NULL;
                    ELSE
                      IF TG_OP != 'UPDATE' OR new_value != old_value OR (TG_OP = 'UPDATE' AND ( (new_value IS NULL AND old_value IS NOT NULL) OR (new_value IS NOT NULL AND old_value IS NULL))) THEN
                        INSERT INTO audit_log("operation",
                                              "table_name",
                                              "primary_key",
                                              "field_name",
                                              "field_value_old",
                                              "field_value_new",
                                              "user_id",
                                              "user_unique_name",
                                              "occurred_at"
                                             )
                        VALUES(TG_OP,
                              TG_RELNAME,
                              primary_key_value,
                              column_name,
                              old_value,
                              new_value,
                              user_identifier,
                              unique_name,
                              current_timestamp);
                      END IF;
                    END IF;
                  END LOOP;
                  RETURN NULL;
                END
                $_$;


--
-- Name: difference(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION difference(text, text) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'difference';


--
-- Name: dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION dmetaphone(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'dmetaphone';


--
-- Name: dmetaphone_alt(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION dmetaphone_alt(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'dmetaphone_alt';


--
-- Name: gin_extract_trgm(text, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_extract_trgm(text, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_extract_trgm';


--
-- Name: gin_extract_trgm(text, internal, smallint, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_extract_trgm(text, internal, smallint, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_extract_trgm';


--
-- Name: gin_trgm_consistent(internal, smallint, text, integer, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gin_trgm_consistent';


--
-- Name: gtrgm_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_compress';


--
-- Name: gtrgm_consistent(internal, text, integer, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_consistent(internal, text, integer, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_consistent';


--
-- Name: gtrgm_decompress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_decompress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_decompress';


--
-- Name: gtrgm_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_penalty';


--
-- Name: gtrgm_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_picksplit';


--
-- Name: gtrgm_same(gtrgm, gtrgm, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_same(gtrgm, gtrgm, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_same';


--
-- Name: gtrgm_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gtrgm_union(bytea, internal) RETURNS integer[]
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'gtrgm_union';


--
-- Name: levenshtein(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION levenshtein(text, text) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'levenshtein';


--
-- Name: levenshtein(text, text, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION levenshtein(text, text, integer, integer, integer) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'levenshtein_with_costs';


--
-- Name: metaphone(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION metaphone(text, integer) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'metaphone';


--
-- Name: pg_search_dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION pg_search_dmetaphone(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
$_$;


--
-- Name: set_limit(real); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION set_limit(real) RETURNS real
    LANGUAGE c STRICT
    AS '$libdir/pg_trgm', 'set_limit';


--
-- Name: show_limit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_limit() RETURNS real
    LANGUAGE c STABLE STRICT
    AS '$libdir/pg_trgm', 'show_limit';


--
-- Name: show_trgm(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION show_trgm(text) RETURNS text[]
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'show_trgm';


--
-- Name: similarity(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION similarity(text, text) RETURNS real
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/pg_trgm', 'similarity';


--
-- Name: similarity_op(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION similarity_op(text, text) RETURNS boolean
    LANGUAGE c STABLE STRICT
    AS '$libdir/pg_trgm', 'similarity_op';


--
-- Name: soundex(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION soundex(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'soundex';


--
-- Name: text_soundex(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION text_soundex(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/fuzzystrmatch', 'soundex';


--
-- Name: unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unaccent(text) RETURNS text
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/unaccent', 'unaccent_dict';


--
-- Name: unaccent(regdictionary, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unaccent(regdictionary, text) RETURNS text
    LANGUAGE c STRICT
    AS '$libdir/unaccent', 'unaccent_dict';


--
-- Name: unaccent_init(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unaccent_init(internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/unaccent', 'unaccent_init';


--
-- Name: unaccent_lexize(internal, internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION unaccent_lexize(internal, internal, internal, internal) RETURNS internal
    LANGUAGE c
    AS '$libdir/unaccent', 'unaccent_lexize';


--
-- Name: %; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR % (
    PROCEDURE = similarity_op,
    LEFTARG = text,
    RIGHTARG = text,
    COMMUTATOR = %,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: gin_trgm_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gin_trgm_ops
    FOR TYPE text USING gin AS
    STORAGE integer ,
    OPERATOR 1 %(text,text) ,
    FUNCTION 1 btint4cmp(integer,integer) ,
    FUNCTION 2 gin_extract_trgm(text,internal) ,
    FUNCTION 3 gin_extract_trgm(text,internal,smallint,internal,internal) ,
    FUNCTION 4 gin_trgm_consistent(internal,smallint,text,integer,internal,internal);


--
-- Name: gist_trgm_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_trgm_ops
    FOR TYPE text USING gist AS
    STORAGE gtrgm ,
    OPERATOR 1 %(text,text) ,
    FUNCTION 1 gtrgm_consistent(internal,text,integer,oid,internal) ,
    FUNCTION 2 gtrgm_union(bytea,internal) ,
    FUNCTION 3 gtrgm_compress(internal) ,
    FUNCTION 4 gtrgm_decompress(internal) ,
    FUNCTION 5 gtrgm_penalty(internal,internal,internal) ,
    FUNCTION 6 gtrgm_picksplit(internal,internal) ,
    FUNCTION 7 gtrgm_same(gtrgm,gtrgm,internal);


--
-- Name: unaccent; Type: TEXT SEARCH TEMPLATE; Schema: public; Owner: -
--

CREATE TEXT SEARCH TEMPLATE unaccent (
    INIT = unaccent_init,
    LEXIZE = unaccent_lexize );


--
-- Name: unaccent; Type: TEXT SEARCH DICTIONARY; Schema: public; Owner: -
--

CREATE TEXT SEARCH DICTIONARY unaccent (
    TEMPLATE = unaccent,
    rules = 'unaccent' );


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abuse_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE abuse_quizzes (
    id integer NOT NULL,
    n1 boolean,
    n2 character varying(255),
    n3 boolean,
    n4 text,
    n5 character varying(255),
    n6 text,
    n7 boolean,
    n8 boolean,
    n9 boolean,
    n10 boolean,
    n11 text,
    risk_assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: abuse_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE abuse_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abuse_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE abuse_quizzes_id_seq OWNED BY abuse_quizzes.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accounts (
    id integer NOT NULL,
    user_id integer,
    enabled boolean DEFAULT true,
    activation_code character varying(40),
    salt character varying(40) NOT NULL,
    remember_token character varying(255),
    activated_at timestamp without time zone,
    remember_token_expires_at timestamp without time zone,
    last_authenticated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: active_military_dependent_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE active_military_dependent_statuses (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    value boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: active_military_dependent_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE active_military_dependent_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_military_dependent_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE active_military_dependent_statuses_id_seq OWNED BY active_military_dependent_statuses.id;


--
-- Name: active_military_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE active_military_statuses (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    value boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: active_military_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE active_military_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_military_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE active_military_statuses_id_seq OWNED BY active_military_statuses.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    formatted text,
    legacy_id character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admin_style_guide_mock_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_style_guide_mock_people (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: admin_style_guide_mock_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_style_guide_mock_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_style_guide_mock_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_style_guide_mock_people_id_seq OWNED BY admin_style_guide_mock_people.id;


--
-- Name: admin_style_guide_object_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_style_guide_object_people (
    id integer NOT NULL,
    person_id integer,
    style_guide_object_id integer
);


--
-- Name: admin_style_guide_object_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_style_guide_object_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_style_guide_object_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_style_guide_object_people_id_seq OWNED BY admin_style_guide_object_people.id;


--
-- Name: admin_style_guide_object_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_style_guide_object_types (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: admin_style_guide_object_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_style_guide_object_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_style_guide_object_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_style_guide_object_types_id_seq OWNED BY admin_style_guide_object_types.id;


--
-- Name: admin_style_guide_objects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_style_guide_objects (
    id integer NOT NULL,
    style_guide_object_type_id integer,
    string_field_1 character varying(255),
    string_field_2 character varying(255),
    string_field_3 character varying(255),
    "boolean" boolean,
    string character varying(255),
    email character varying(255),
    url character varying(255),
    tel character varying(255),
    password character varying(255),
    search character varying(255),
    text text,
    file character varying(255),
    hidden character varying(255),
    "integer" integer,
    "float" double precision,
    "decimal" numeric,
    datetime timestamp without time zone,
    date date,
    "time" timestamp without time zone,
    select_id integer,
    radio_id integer,
    check_box_id integer,
    country character varying(255),
    time_zone character varying(255)
);


--
-- Name: admin_style_guide_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_style_guide_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_style_guide_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_style_guide_objects_id_seq OWNED BY admin_style_guide_objects.id;


--
-- Name: adverse_reaction_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE adverse_reaction_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: adverse_reaction_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE adverse_reaction_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adverse_reaction_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE adverse_reaction_names_id_seq OWNED BY adverse_reaction_names.id;


--
-- Name: adverse_reactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE adverse_reactions (
    id integer NOT NULL,
    person_id integer,
    adverse_reaction_name_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: adverse_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE adverse_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adverse_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE adverse_reactions_id_seq OWNED BY adverse_reactions.id;


--
-- Name: aid_to_families_with_dependent_children_limits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE aid_to_families_with_dependent_children_limits (
    id integer NOT NULL,
    number_of_people integer,
    amount_with_parent integer,
    amount_without_parent integer
);


--
-- Name: aid_to_families_with_dependent_children_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE aid_to_families_with_dependent_children_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aid_to_families_with_dependent_children_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE aid_to_families_with_dependent_children_limits_id_seq OWNED BY aid_to_families_with_dependent_children_limits.id;


--
-- Name: allegation_maltreatment_subtypes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allegation_maltreatment_subtypes (
    id integer NOT NULL,
    allegation_id integer,
    maltreatment_subtype_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: allegation_maltreatment_subtypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allegation_maltreatment_subtypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allegation_maltreatment_subtypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allegation_maltreatment_subtypes_id_seq OWNED BY allegation_maltreatment_subtypes.id;


--
-- Name: allegations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allegations (
    id integer NOT NULL,
    assessment_id integer,
    maltreatment_type_id integer,
    date_of_alleged_incident timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    victim_id integer,
    perpetrator_id integer,
    substantiated boolean,
    note_id integer,
    created_by_intake boolean DEFAULT false NOT NULL
);


--
-- Name: allegations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allegations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allegations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allegations_id_seq OWNED BY allegations.id;


--
-- Name: allergies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allergies (
    id integer NOT NULL,
    person_id integer,
    allergy_name_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: allergies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allergies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allergies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allergies_id_seq OWNED BY allergies.id;


--
-- Name: allergy_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE allergy_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: allergy_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allergy_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allergy_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allergy_names_id_seq OWNED BY allergy_names.id;


--
-- Name: applicants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE applicants (
    id integer NOT NULL,
    person_id integer,
    foster_family_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" integer
);


--
-- Name: applicants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE applicants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applicants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE applicants_id_seq OWNED BY applicants.id;


--
-- Name: archived_allegations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_allegations (
    id integer NOT NULL,
    assessment_id integer,
    maltreatment_type_id integer,
    date_of_alleged_incident timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    victim_id integer,
    perpetrator_id integer,
    substantiated boolean,
    note_id integer,
    created_by_intake boolean DEFAULT false NOT NULL
);


--
-- Name: archived_allegations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_allegations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_allegations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_allegations_id_seq OWNED BY archived_allegations.id;


--
-- Name: archived_assessment_legally_mandated_reasons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_assessment_legally_mandated_reasons (
    id integer NOT NULL,
    assessment_id integer,
    legally_mandated_reason_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: archived_assessment_legally_mandated_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_assessment_legally_mandated_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_assessment_legally_mandated_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_assessment_legally_mandated_reasons_id_seq OWNED BY archived_assessment_legally_mandated_reasons.id;


--
-- Name: archived_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_assessments (
    id integer NOT NULL,
    reported_on timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assignee_id integer,
    state character varying(255),
    reason_for_edits character varying(255),
    county_id integer,
    deleted_at timestamp without time zone,
    name character varying(255),
    restricted boolean DEFAULT false,
    uuid uuid,
    intake_worker_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    allegation_narrative text,
    worker_safety text,
    response_time_id integer,
    report_source_id integer,
    conclusion text,
    statement text DEFAULT ''::character varying,
    read_by_assignee boolean DEFAULT false,
    accepted_at timestamp without time zone,
    report_source_type character varying(255),
    intake_id integer,
    summary_of_preliminary_report text,
    scope_of_assessment text,
    initial_and_subsequent_child_safety text,
    notices text,
    legacy_initiation_time timestamp without time zone,
    initial_response_time_id integer NOT NULL,
    appeal_narrative text,
    historical boolean DEFAULT false NOT NULL,
    intake_alerts text,
    imported boolean DEFAULT false
);


--
-- Name: archived_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_assessments_id_seq OWNED BY archived_assessments.id;


--
-- Name: archived_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_attachments (
    id integer NOT NULL,
    parent_id integer,
    parent_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    asset character varying(255),
    attachment_type character varying(255),
    create_date date,
    description text
);


--
-- Name: archived_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_attachments_id_seq OWNED BY archived_attachments.id;


--
-- Name: archived_notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_notes (
    id integer NOT NULL,
    unit_of_work_id integer,
    unit_of_work_type character varying(255),
    content text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying
);


--
-- Name: archived_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_notes_id_seq OWNED BY archived_notes.id;


--
-- Name: archived_relationships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE archived_relationships (
    id integer NOT NULL,
    strong_side_person_id integer,
    weak_side_person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type_id integer,
    deleted_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    paternity_confirmed boolean,
    paternity_validation_method character varying(255)
);


--
-- Name: archived_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE archived_relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE archived_relationships_id_seq OWNED BY archived_relationships.id;


--
-- Name: assessed_people_safety_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessed_people_safety_assessments (
    id integer NOT NULL,
    person_id integer,
    safety_assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: assessed_people_safety_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessed_people_safety_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessed_people_safety_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessed_people_safety_assessments_id_seq OWNED BY assessed_people_safety_assessments.id;


--
-- Name: assessment_legally_mandated_reasons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessment_legally_mandated_reasons (
    id integer NOT NULL,
    assessment_id integer,
    legally_mandated_reason_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: assessment_legally_mandated_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_legally_mandated_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_legally_mandated_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_legally_mandated_reasons_id_seq OWNED BY assessment_legally_mandated_reasons.id;


--
-- Name: assessment_legally_mandated_reasons_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessment_legally_mandated_reasons_people (
    assessment_legally_mandated_reason_id integer,
    person_id integer
);


--
-- Name: assessment_report_source_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessment_report_source_types (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: assessment_report_source_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_report_source_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_report_source_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_report_source_types_id_seq OWNED BY assessment_report_source_types.id;


--
-- Name: assessment_response_times; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessment_response_times (
    id integer NOT NULL,
    amount integer,
    unit character varying(255),
    duration integer
);


--
-- Name: assessment_response_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_response_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_response_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_response_times_id_seq OWNED BY assessment_response_times.id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessments (
    id integer NOT NULL,
    reported_on timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assignee_id integer,
    state character varying(255),
    reason_for_edits character varying(255),
    county_id integer,
    name character varying(255),
    restricted boolean DEFAULT false,
    uuid uuid,
    intake_worker_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    allegation_narrative text,
    worker_safety text,
    response_time_id integer,
    report_source_id integer,
    conclusion text,
    statement text DEFAULT ''::character varying,
    read_by_assignee boolean DEFAULT false,
    accepted_at timestamp without time zone,
    report_source_type character varying(255),
    intake_id integer,
    summary_of_preliminary_report text,
    scope_of_assessment text,
    initial_and_subsequent_child_safety text,
    notices text,
    legacy_initiation_time timestamp without time zone,
    initial_response_time_id integer NOT NULL,
    appeal_narrative text,
    historical boolean DEFAULT false NOT NULL,
    intake_alerts text,
    imported boolean DEFAULT false
);


--
-- Name: assessments_authorized_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assessments_authorized_users (
    assessment_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessments_id_seq OWNED BY assessments.id;


--
-- Name: assistance_group_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assistance_group_people (
    id integer NOT NULL,
    person_id integer,
    eligibility_id integer,
    eligibility_type character varying(255)
);


--
-- Name: assistance_group_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assistance_group_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assistance_group_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assistance_group_people_id_seq OWNED BY assistance_group_people.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE attachments (
    id integer NOT NULL,
    parent_id integer,
    parent_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    asset character varying(255),
    attachment_type character varying(255),
    create_date date,
    description text
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachments_id_seq OWNED BY attachments.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE audit_log (
    id integer NOT NULL,
    user_id integer,
    user_unique_name character varying(255),
    operation character varying(255),
    table_name character varying(255),
    field_name character varying(255),
    field_value_new text,
    field_value_old text,
    occurred_at timestamp without time zone,
    primary_key character varying(255)
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE audit_log_id_seq OWNED BY audit_log.id;


--
-- Name: background_checks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE background_checks (
    id integer NOT NULL,
    person_id integer,
    check_type character varying(255),
    outcome character varying(255),
    date date,
    comments text
);


--
-- Name: background_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE background_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: background_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE background_checks_id_seq OWNED BY background_checks.id;


--
-- Name: cans_assessment_cans_tools; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cans_assessment_cans_tools (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: cans_assessment_cans_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cans_assessment_cans_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cans_assessment_cans_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cans_assessment_cans_tools_id_seq OWNED BY cans_assessment_cans_tools.id;


--
-- Name: cans_assessment_health_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cans_assessment_health_recommendations (
    id integer NOT NULL,
    name character varying(255),
    age_range character varying(255)
);


--
-- Name: cans_assessment_health_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cans_assessment_health_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cans_assessment_health_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cans_assessment_health_recommendations_id_seq OWNED BY cans_assessment_health_recommendations.id;


--
-- Name: cans_assessment_placement_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cans_assessment_placement_recommendations (
    id integer NOT NULL,
    name character varying(255),
    age_range character varying(255)
);


--
-- Name: cans_assessment_placement_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cans_assessment_placement_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cans_assessment_placement_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cans_assessment_placement_recommendations_id_seq OWNED BY cans_assessment_placement_recommendations.id;


--
-- Name: cans_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cans_assessments (
    id integer NOT NULL,
    unit_of_work_id integer,
    unit_of_work_type character varying(255),
    date date,
    focus_child_id integer,
    reason character varying(255),
    cans_tool_id integer,
    health_recommendation_id integer,
    placement_recommendation_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by_id integer,
    legacy_id character varying(255),
    historical boolean DEFAULT false NOT NULL
);


--
-- Name: cans_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cans_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cans_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cans_assessments_id_seq OWNED BY cans_assessments.id;


--
-- Name: caregiver_financial_risk_factor_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_financial_risk_factor_values (
    id integer NOT NULL,
    caregiver_financial_risk_id integer,
    caregiver_financial_risk_factor_id integer,
    value boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caregiver_financial_risk_factor_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_financial_risk_factor_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_financial_risk_factor_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_financial_risk_factor_values_id_seq OWNED BY caregiver_financial_risk_factor_values.id;


--
-- Name: caregiver_financial_risks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_financial_risks (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caregiver_financial_risks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_financial_risks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_financial_risks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_financial_risks_id_seq OWNED BY caregiver_financial_risks.id;


--
-- Name: caregiver_health_risk_factor_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_health_risk_factor_values (
    id integer NOT NULL,
    caregiver_health_risk_id integer,
    caregiver_health_risk_factor_id integer,
    value boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caregiver_health_risk_factor_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_health_risk_factor_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_health_risk_factor_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_health_risk_factor_values_id_seq OWNED BY caregiver_health_risk_factor_values.id;


--
-- Name: caregiver_health_risks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_health_risks (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caregiver_health_risks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_health_risks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_health_risks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_health_risks_id_seq OWNED BY caregiver_health_risks.id;


--
-- Name: caregiver_strengths_and_needs_assessment_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_strengths_and_needs_assessment_quizzes (
    id integer NOT NULL,
    r1 character varying(255),
    r2 character varying(255),
    r3 character varying(255),
    r4 character varying(255),
    r5 character varying(255),
    r6 character varying(255),
    r7 character varying(255),
    r8 character varying(255),
    r9 character varying(255),
    r10 character varying(255),
    r11 character varying(255),
    r12 character varying(255),
    r13 character varying(255),
    r14 character varying(255),
    r15 character varying(255),
    r16 character varying(255),
    r17 character varying(255),
    r18 character varying(255),
    r19 character varying(255),
    caregiver_strengths_and_needs_assessment_id integer,
    caregiver_id integer,
    "primary" boolean DEFAULT true,
    state character varying(255) DEFAULT 'caregiver_info'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    r20 character varying(255)
);


--
-- Name: caregiver_strengths_and_needs_assessment_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_strengths_and_needs_assessment_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_strengths_and_needs_assessment_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_strengths_and_needs_assessment_quizzes_id_seq OWNED BY caregiver_strengths_and_needs_assessment_quizzes.id;


--
-- Name: caregiver_strengths_and_needs_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caregiver_strengths_and_needs_assessments (
    id integer NOT NULL,
    date_of_assessment date,
    case_id integer,
    state character varying(255),
    secondary_caregiver boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: caregiver_strengths_and_needs_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caregiver_strengths_and_needs_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caregiver_strengths_and_needs_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caregiver_strengths_and_needs_assessments_id_seq OWNED BY caregiver_strengths_and_needs_assessments.id;


--
-- Name: case_focus_child_involvements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_focus_child_involvements (
    id integer NOT NULL,
    case_focus_child_id integer,
    involvement_type_id integer,
    supporting_authorization_id integer,
    supporting_authorization_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    start_date date,
    end_date date
);


--
-- Name: case_focus_child_involvements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_focus_child_involvements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_focus_child_involvements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_focus_child_involvements_id_seq OWNED BY case_focus_child_involvements.id;


--
-- Name: case_focus_children; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_focus_children (
    id integer NOT NULL,
    case_id integer NOT NULL,
    person_id integer NOT NULL,
    future_involvement_type_id integer,
    legacy_id character varying(255)
);


--
-- Name: case_focus_children_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_focus_children_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_focus_children_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_focus_children_id_seq OWNED BY case_focus_children.id;


--
-- Name: case_linked_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_linked_assessments (
    id integer NOT NULL,
    case_id integer NOT NULL,
    assessment_id integer NOT NULL
);


--
-- Name: case_linked_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_linked_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_linked_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_linked_assessments_id_seq OWNED BY case_linked_assessments.id;


--
-- Name: case_plan_caregivers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_plan_caregivers (
    id integer NOT NULL,
    person_id integer,
    case_plan_id integer,
    strengths text,
    needs text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: case_plan_caregivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_caregivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_caregivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_caregivers_id_seq OWNED BY case_plan_caregivers.id;


--
-- Name: case_plan_focus_child_planned_caregivers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_plan_focus_child_planned_caregivers (
    id integer NOT NULL,
    person_id integer,
    case_plan_focus_child_id integer
);


--
-- Name: case_plan_focus_child_planned_caregivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_focus_child_planned_caregivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_focus_child_planned_caregivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_focus_child_planned_caregivers_id_seq OWNED BY case_plan_focus_child_planned_caregivers.id;


--
-- Name: case_plan_focus_children; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_plan_focus_children (
    id integer NOT NULL,
    person_id integer,
    case_plan_id integer,
    permanency_goal character varying(255),
    concurrent_permanency_goal character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    permanency_estimated_date date,
    adoption_no_reunification_reasons text,
    adoption_discussed_with_caregivers boolean,
    adoption_discussed_with_caregivers_explanation text,
    adoption_adoptive_family_identified boolean,
    appla_no_reunification_reasons text,
    appla_reasonable_effort boolean,
    legal_guardianship_no_reunification_reasons text,
    legal_guardianship_no_adoption_reunification_steps text,
    legal_guardianship_discussed_with_caregivers boolean,
    legal_guardianship_discussed_with_caregivers_explanation text,
    legal_guardianship_best_interest text,
    legal_guardianship_efforts_made_to_discuss_with_parents text,
    legal_guardianship_discussed_with_child boolean,
    fit_willing_relative_no_reunification_reasons text,
    fit_willing_no_adoption_reunification_steps text,
    fit_willing_discussed_with_caregivers boolean,
    fit_willing_discussed_with_caregivers_explanation text,
    fit_willing_best_interest text,
    fit_willing_discussed_with_child boolean,
    permanency_best_interest text,
    permanency_child_disagreement text,
    permanency_child_consulted boolean,
    permanency_imminent_risk character varying(255),
    caregiver_made_aware_of_side_effects boolean,
    caregiver_made_aware_of_side_effects_explanation character varying(255),
    date_of_assessment date,
    diagnosis_following_assessment boolean,
    enrolled_in_bdds boolean,
    enrolled_in_bdds_explanation character varying(255),
    ssi_application_submission_date date,
    ssi_eligibility_date date,
    allergy_notes text,
    surgery_notes text
);


--
-- Name: case_plan_focus_children_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_focus_children_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_focus_children_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_focus_children_id_seq OWNED BY case_plan_focus_children.id;


--
-- Name: objective_activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE objective_activities (
    id integer NOT NULL,
    objective_id integer NOT NULL,
    description character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: case_plan_objective_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_objective_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_objective_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_objective_activities_id_seq OWNED BY objective_activities.id;


--
-- Name: objective_activity_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE objective_activity_people (
    id integer NOT NULL,
    objective_activity_id integer NOT NULL,
    person_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: case_plan_objective_activity_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_objective_activity_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_objective_activity_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_objective_activity_people_id_seq OWNED BY objective_activity_people.id;


--
-- Name: objectives; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE objectives (
    id integer NOT NULL,
    description character varying(255),
    start_date date,
    last_updated_on date,
    status character varying(255),
    challenges text,
    initiative_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    initiative_type character varying(255)
);


--
-- Name: case_plan_objectives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_objectives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_objectives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_objectives_id_seq OWNED BY objectives.id;


--
-- Name: case_plan_safety_plan_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_plan_safety_plan_links (
    id integer NOT NULL,
    case_plan_id integer NOT NULL,
    safety_plan_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: case_plan_safety_plan_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plan_safety_plan_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plan_safety_plan_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plan_safety_plan_links_id_seq OWNED BY case_plan_safety_plan_links.id;


--
-- Name: case_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE case_plans (
    id integer NOT NULL,
    case_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    state character varying(255) DEFAULT 'draft'::character varying NOT NULL,
    legacy_id character varying(255),
    historical boolean DEFAULT false NOT NULL
);


--
-- Name: case_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE case_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: case_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE case_plans_id_seq OWNED BY case_plans.id;


--
-- Name: cases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cases (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assignee_id integer,
    uuid uuid,
    county_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    read_by_assignee boolean DEFAULT false,
    state character varying(255),
    historical boolean DEFAULT false NOT NULL,
    visitation_plan_id integer,
    imported boolean DEFAULT false
);


--
-- Name: cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cases_id_seq OWNED BY cases.id;


--
-- Name: checklist_answers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE checklist_answers (
    id integer NOT NULL,
    checklist_id integer NOT NULL,
    checklist_question_id integer NOT NULL,
    date_completed date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    person_id integer
);


--
-- Name: checklist_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE checklist_answers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklist_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE checklist_answers_id_seq OWNED BY checklist_answers.id;


--
-- Name: checklist_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE checklist_types (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    family_foster_homes boolean DEFAULT false NOT NULL,
    residential_resources boolean DEFAULT false NOT NULL,
    sort_order integer
);


--
-- Name: checklist_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE checklist_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklist_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE checklist_types_id_seq OWNED BY checklist_types.id;


--
-- Name: checklists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE checklists (
    id integer NOT NULL,
    parent_resource_id integer NOT NULL,
    parent_resource_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    checklist_type_id integer NOT NULL
);


--
-- Name: checklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE checklists_id_seq OWNED BY checklists.id;


--
-- Name: child_risk_factor_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE child_risk_factor_values (
    id integer NOT NULL,
    child_risk_id integer,
    child_risk_factor_id integer,
    value boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: child_risk_factor_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE child_risk_factor_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: child_risk_factor_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE child_risk_factor_values_id_seq OWNED BY child_risk_factor_values.id;


--
-- Name: child_risks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE child_risks (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: child_risks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE child_risks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: child_risks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE child_risks_id_seq OWNED BY child_risks.id;


--
-- Name: client_referrals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE client_referrals (
    person_id integer,
    referral_id integer
);


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notes (
    id integer NOT NULL,
    unit_of_work_id integer,
    unit_of_work_type character varying(255),
    content text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY notes.id;


--
-- Name: contact_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_people (
    id integer NOT NULL,
    contact_id integer,
    person_id integer,
    regarding boolean,
    present boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: contact_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_people_id_seq OWNED BY contact_people.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contacts (
    id integer NOT NULL,
    mode character varying(255),
    occurred_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    other_reason_for_contact character varying(255),
    absent_parent_search boolean,
    case_plan_conference boolean,
    case_staffing boolean,
    child_protection_team boolean,
    local_coordinator_committee boolean,
    transition_planning_conference boolean,
    note_id integer,
    visit_with_family_members boolean,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    successful boolean DEFAULT true
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: corrective_action_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE corrective_action_plans (
    id integer NOT NULL,
    foster_family_id integer,
    probation character varying(255),
    effective_start_date date,
    effective_end_date date,
    non_compliance_items text,
    non_compliance_circumstances text,
    non_compliance_agency_steps text,
    non_compliance_licensee_steps text,
    licensees_date date,
    licensing_specialist_date date,
    licensing_supervisor_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: corrective_action_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE corrective_action_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: corrective_action_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE corrective_action_plans_id_seq OWNED BY corrective_action_plans.id;


--
-- Name: counties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE counties (
    id integer NOT NULL,
    name character varying(255),
    actual boolean
);


--
-- Name: counties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE counties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: counties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE counties_id_seq OWNED BY counties.id;


--
-- Name: court_hearing_hearing_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearing_hearing_outcomes (
    id integer NOT NULL,
    court_hearing_id integer NOT NULL,
    outcome_id integer NOT NULL,
    effective_at timestamp without time zone
);


--
-- Name: court_hearing_court_hearing_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_hearing_court_hearing_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_hearing_court_hearing_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_hearing_court_hearing_outcomes_id_seq OWNED BY court_hearing_hearing_outcomes.id;


--
-- Name: court_hearing_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearing_outcomes (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    action character varying(255)
);


--
-- Name: court_hearing_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_hearing_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_hearing_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_hearing_outcomes_id_seq OWNED BY court_hearing_outcomes.id;


--
-- Name: court_hearing_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearing_types (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: court_hearing_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_hearing_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_hearing_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_hearing_types_id_seq OWNED BY court_hearing_types.id;


--
-- Name: court_hearing_types_outcomes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearing_types_outcomes (
    court_hearing_type_id integer NOT NULL,
    outcome_id integer NOT NULL
);


--
-- Name: court_hearings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearings (
    id integer NOT NULL,
    unit_of_work_id integer,
    unit_of_work_type character varying(255),
    court_hearing_type_id integer,
    creator_id integer NOT NULL,
    date date,
    summary text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    state character varying(255) DEFAULT 'hearing_type'::character varying NOT NULL,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    person_id integer
);


--
-- Name: court_hearings_court_language_citations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_hearings_court_language_citations (
    id integer NOT NULL,
    court_language_citation_id integer,
    court_hearing_id integer
);


--
-- Name: court_hearings_court_language_citations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_hearings_court_language_citations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_hearings_court_language_citations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_hearings_court_language_citations_id_seq OWNED BY court_hearings_court_language_citations.id;


--
-- Name: court_hearings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_hearings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_hearings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_hearings_id_seq OWNED BY court_hearings.id;


--
-- Name: court_language_citations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE court_language_citations (
    id integer NOT NULL,
    quest_url character varying(255),
    quest_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: court_language_citations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE court_language_citations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: court_language_citations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE court_language_citations_id_seq OWNED BY court_language_citations.id;


--
-- Name: custom_provision_with_questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE custom_provision_with_questions (
    id integer NOT NULL,
    ia_plan_id integer,
    name character varying(255),
    description text,
    "group" character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    selected boolean DEFAULT false
);


--
-- Name: custom_provisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_provisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_provisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_provisions_id_seq OWNED BY custom_provision_with_questions.id;


--
-- Name: data_broker_event_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_broker_event_logs (
    id integer NOT NULL,
    current_user_id integer,
    model_id integer,
    model_type character varying(255),
    event_name character varying(255),
    data_received text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_id character varying(255),
    job_name character varying(255),
    status_code character varying(255),
    status_message character varying(255),
    entry_point character varying(255)
);


--
-- Name: data_broker_event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_broker_event_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_broker_event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_broker_event_logs_id_seq OWNED BY data_broker_event_logs.id;


--
-- Name: data_broker_traffic_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE data_broker_traffic_logs (
    id integer NOT NULL,
    status_code integer,
    url character varying(255),
    model_id integer,
    model_type character varying(255),
    action character varying(255),
    data_sent text,
    data_received text,
    current_user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    queue character varying(255)
);


--
-- Name: data_broker_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_broker_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_broker_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_broker_logs_id_seq OWNED BY data_broker_traffic_logs.id;


--
-- Name: deprivation_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deprivation_types (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deprivation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deprivation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deprivation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deprivation_types_id_seq OWNED BY deprivation_types.id;


--
-- Name: discretionary_overrides; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE discretionary_overrides (
    id integer NOT NULL,
    name text NOT NULL,
    overrideable_id integer NOT NULL,
    overrideable_type character varying(255) NOT NULL
);


--
-- Name: discretionary_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discretionary_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discretionary_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discretionary_overrides_id_seq OWNED BY discretionary_overrides.id;


--
-- Name: educational_overview_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE educational_overview_quizzes (
    id integer NOT NULL,
    case_plan_focus_child_id integer NOT NULL,
    enrolled boolean,
    enrolled_explanation text,
    performing_at_grade_level boolean,
    iep text,
    surrogate boolean,
    surrogate_explanation text,
    twenty_first_century boolean,
    standardized_testing text,
    graduation_testing text,
    extracurricular_activities text,
    disciplinary_actions text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: educational_overview_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE educational_overview_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: educational_overview_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE educational_overview_quizzes_id_seq OWNED BY educational_overview_quizzes.id;


--
-- Name: eligibility_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE eligibility_applications (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    focus_child_id integer,
    assignee_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    specified_relative_id integer,
    legacy_id character varying(255),
    lived_with_specified_relative_on_event_date boolean,
    submitted_at timestamp without time zone,
    end_date date,
    event_date date,
    court_language_citation_bictw_id integer,
    court_language_citation_re_id integer,
    court_language_citation_pc_id integer,
    court_language_citation_repp_id integer,
    iv_e_specified_relative_id integer,
    iv_e_judicial_removal_date date,
    iv_e_physical_removal_date date,
    iv_e_lived_with_specified_relative_on_event_date date,
    iv_e_deprivation_type_id integer,
    iv_e_deprived boolean,
    active_relevant_event_type character varying(255),
    active_relevant_event_id integer
);


--
-- Name: eligibility_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE eligibility_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eligibility_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE eligibility_applications_id_seq OWNED BY eligibility_applications.id;


--
-- Name: email_notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_notes (
    id integer NOT NULL,
    email_id integer,
    note_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: email_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_notes_id_seq OWNED BY email_notes.id;


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE emails (
    id integer NOT NULL,
    "to" character varying(255),
    "from" character varying(255),
    subject character varying(255),
    body text,
    raw text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    owner_id integer,
    owner_type character varying(255)
);


--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emails_id_seq OWNED BY emails.id;


--
-- Name: emergency_assistance_eligibilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE emergency_assistance_eligibilities (
    id integer NOT NULL,
    status character varying(255),
    eligibility_application_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: emergency_assistance_eligibilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emergency_assistance_eligibilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emergency_assistance_eligibilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emergency_assistance_eligibilities_id_seq OWNED BY emergency_assistance_eligibilities.id;


--
-- Name: employment_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE employment_records (
    id integer NOT NULL,
    person_id integer,
    employer_name character varying(255),
    employer_address character varying(255),
    start_date date,
    current boolean DEFAULT true,
    end_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    employer_phone_number character varying(255),
    comments text
);


--
-- Name: employment_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE employment_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employment_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE employment_records_id_seq OWNED BY employment_records.id;


--
-- Name: external_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE external_roles (
    id integer NOT NULL,
    type character varying(255),
    name character varying(255)
);


--
-- Name: external_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE external_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_roles_id_seq OWNED BY external_roles.id;


--
-- Name: external_roles_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE external_roles_users (
    external_role_id integer,
    user_id integer
);


--
-- Name: federal_poverty_income_limits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE federal_poverty_income_limits (
    id integer NOT NULL,
    year integer,
    household_member_count integer,
    amount integer,
    additional_member_amount integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: federal_poverty_income_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE federal_poverty_income_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: federal_poverty_income_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE federal_poverty_income_limits_id_seq OWNED BY federal_poverty_income_limits.id;


--
-- Name: foster_families; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE foster_families (
    id integer NOT NULL,
    number_in_household integer,
    previous_foster_experience boolean,
    previous_foster_experience_start_date date,
    previous_foster_experience_end_date date,
    agency_name character varying(255),
    description text,
    reason_for_interest text,
    source_of_referral character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    current boolean DEFAULT false,
    other_referral_source character varying(255),
    family_structure integer,
    supervising_agency_id integer
);


--
-- Name: foster_families_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE foster_families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: foster_families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE foster_families_id_seq OWNED BY foster_families.id;


--
-- Name: foster_family_other_household_members; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE foster_family_other_household_members (
    id integer NOT NULL,
    foster_family_id integer,
    person_id integer
);


--
-- Name: foster_family_other_household_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE foster_family_other_household_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: foster_family_other_household_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE foster_family_other_household_members_id_seq OWNED BY foster_family_other_household_members.id;


--
-- Name: health_care_provider_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE health_care_provider_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: health_care_provider_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE health_care_provider_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_care_provider_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE health_care_provider_names_id_seq OWNED BY health_care_provider_names.id;


--
-- Name: health_care_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE health_care_providers (
    id integer NOT NULL,
    person_id integer,
    health_care_provider_name_id integer,
    address character varying(255),
    phone_number character varying(255),
    specialty character varying(255),
    other_info character varying(255),
    start_date date,
    treating_special_need boolean DEFAULT false,
    primary_care_provider boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: health_care_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE health_care_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_care_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE health_care_providers_id_seq OWNED BY health_care_providers.id;


--
-- Name: health_exam_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE health_exam_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: health_exam_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE health_exam_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_exam_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE health_exam_names_id_seq OWNED BY health_exam_names.id;


--
-- Name: health_exams; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE health_exams (
    id integer NOT NULL,
    person_id integer,
    health_exam_name_id integer,
    date date,
    special_need boolean,
    what_special_need character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: health_exams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE health_exams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_exams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE health_exams_id_seq OWNED BY health_exams.id;


--
-- Name: hearing_outcomes_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE hearing_outcomes_people (
    person_id integer,
    hearing_outcome_id integer
);


--
-- Name: historical_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE historical_records (
    id integer NOT NULL,
    recordable_id integer NOT NULL,
    recordable_type character varying(255) NOT NULL,
    event_target_id integer NOT NULL,
    event_target_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: historical_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE historical_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historical_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE historical_records_id_seq OWNED BY historical_records.id;


--
-- Name: ia_court_consent_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_court_consent_people (
    id integer NOT NULL,
    ia_plan_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: ia_court_consent_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_court_consent_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_court_consent_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_court_consent_people_id_seq OWNED BY ia_court_consent_people.id;


--
-- Name: ia_hearing_waiver_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_hearing_waiver_people (
    id integer NOT NULL,
    ia_plan_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: ia_hearing_waiver_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_hearing_waiver_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_hearing_waiver_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_hearing_waiver_people_id_seq OWNED BY ia_hearing_waiver_people.id;


--
-- Name: ia_plan_child_supervisors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_plan_child_supervisors (
    id integer NOT NULL,
    person_id integer,
    ia_plan_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: ia_plan_child_supervisors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_plan_child_supervisors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_plan_child_supervisors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_plan_child_supervisors_id_seq OWNED BY ia_plan_child_supervisors.id;


--
-- Name: ia_plan_contact_and_visitation_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_plan_contact_and_visitation_types (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: ia_plan_contact_and_visitation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_plan_contact_and_visitation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_plan_contact_and_visitation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_plan_contact_and_visitation_types_id_seq OWNED BY ia_plan_contact_and_visitation_types.id;


--
-- Name: provision_question_answers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE provision_question_answers (
    id integer NOT NULL,
    ia_plan_id integer,
    person_id integer,
    question_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    properties text,
    question_type character varying(255)
);


--
-- Name: ia_plan_person_provision_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_plan_person_provision_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_plan_person_provision_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_plan_person_provision_questions_id_seq OWNED BY provision_question_answers.id;


--
-- Name: ia_plan_provisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_plan_provisions (
    id integer NOT NULL,
    ia_plan_id integer,
    provision_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: ia_plan_provisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_plan_provisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_plan_provisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_plan_provisions_id_seq OWNED BY ia_plan_provisions.id;


--
-- Name: ia_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_plans (
    id integer NOT NULL,
    case_id integer,
    meeting_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    dcs_situation character varying(255),
    judge_id integer,
    state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    reason_for_edits text,
    submitted_date date,
    approved_date date,
    legacy_id character varying(255),
    historical boolean DEFAULT false NOT NULL
);


--
-- Name: ia_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_plans_id_seq OWNED BY ia_plans.id;


--
-- Name: ia_progress_reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ia_progress_reports (
    id integer NOT NULL,
    compliance_narrative text,
    compliance_type character varying(255),
    additional_information text,
    team_meeting_information text,
    recommendation_type character varying(255),
    case_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    effective_date date
);


--
-- Name: ia_progress_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ia_progress_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ia_progress_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ia_progress_reports_id_seq OWNED BY ia_progress_reports.id;


--
-- Name: identification_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identification_types (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: identification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identification_types_id_seq OWNED BY identification_types.id;


--
-- Name: identifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identifications (
    id integer NOT NULL,
    type_id integer NOT NULL,
    person_id integer NOT NULL,
    identifier character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: identifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identifications_id_seq OWNED BY identifications.id;


--
-- Name: immunization_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE immunization_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: immunization_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE immunization_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: immunization_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE immunization_names_id_seq OWNED BY immunization_names.id;


--
-- Name: immunizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE immunizations (
    id integer NOT NULL,
    person_id integer,
    immunization_name_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: immunizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE immunizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: immunizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE immunizations_id_seq OWNED BY immunizations.id;


--
-- Name: income_record_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE income_record_types (
    id integer NOT NULL,
    name character varying(255),
    income_type character varying(255),
    "none" boolean DEFAULT false
);


--
-- Name: income_record_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE income_record_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: income_record_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE income_record_types_id_seq OWNED BY income_record_types.id;


--
-- Name: income_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE income_records (
    id integer NOT NULL,
    person_id integer,
    amount integer,
    income_record_type_id integer,
    income_record_verification_type_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    month integer,
    year integer
);


--
-- Name: income_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE income_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: income_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE income_records_id_seq OWNED BY income_records.id;


--
-- Name: insurance_provider_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE insurance_provider_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: insurance_provider_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE insurance_provider_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: insurance_provider_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE insurance_provider_names_id_seq OWNED BY insurance_provider_names.id;


--
-- Name: insurance_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE insurance_providers (
    id integer NOT NULL,
    person_id integer,
    insurance_provider_name_id integer,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    insurance_id_number character varying(255),
    address character varying(255),
    phone_number character varying(255),
    primary_insured_person character varying(255),
    group_code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: insurance_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE insurance_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: insurance_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE insurance_providers_id_seq OWNED BY insurance_providers.id;


--
-- Name: intake_allegations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intake_allegations (
    id integer NOT NULL,
    intake_id integer,
    victim_id integer,
    perpetrator_id integer,
    maltreatment_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: intake_allegations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intake_allegations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intake_allegations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intake_allegations_id_seq OWNED BY intake_allegations.id;


--
-- Name: intake_legally_mandated_reasons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intake_legally_mandated_reasons (
    id integer NOT NULL,
    intake_id integer,
    legally_mandated_reason_id integer
);


--
-- Name: intake_legally_mandated_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intake_legally_mandated_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intake_legally_mandated_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intake_legally_mandated_reasons_id_seq OWNED BY intake_legally_mandated_reasons.id;


--
-- Name: intake_legally_mandated_reasons_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intake_legally_mandated_reasons_people (
    intake_legally_mandated_reason_id integer,
    person_id integer
);


--
-- Name: intake_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intake_people (
    id integer NOT NULL,
    person_id integer,
    intake_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: intake_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intake_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intake_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intake_people_id_seq OWNED BY intake_people.id;


--
-- Name: intakes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE intakes (
    id integer NOT NULL,
    county_id integer,
    restricted boolean,
    emergency boolean,
    override_reason text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    family_language_id integer,
    worker_safety text,
    statement text,
    reported_on timestamp without time zone,
    date_of_alleged_incidents timestamp without time zone,
    allegation_narrative text,
    report_source_id integer,
    intake_worker_id integer,
    report_source_type character varying(255),
    safe_haven boolean,
    response_time_hours integer,
    imminent_danger boolean,
    supervisor_first_name character varying(255),
    supervisor_last_name character varying(255),
    incident_county_id integer,
    incident_address_id integer,
    resource_id integer,
    message_id character varying(255)
);


--
-- Name: intakes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intakes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intakes_id_seq OWNED BY intakes.id;


--
-- Name: involvement_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE involvement_types (
    id integer NOT NULL,
    name character varying(255),
    chins_for_eligibility boolean,
    is_future_type boolean DEFAULT false NOT NULL,
    out_of_home boolean,
    requires_supporting_authorization boolean
);


--
-- Name: involvement_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE involvement_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: involvement_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE involvement_types_id_seq OWNED BY involvement_types.id;


--
-- Name: iv_e_eligibilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE iv_e_eligibilities (
    id integer NOT NULL,
    status character varying(255),
    eligibility_application_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: iv_e_eligibilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE iv_e_eligibilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iv_e_eligibilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE iv_e_eligibilities_id_seq OWNED BY iv_e_eligibilities.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE languages (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE languages_id_seq OWNED BY languages.id;


--
-- Name: legally_mandated_reasons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE legally_mandated_reasons (
    id integer NOT NULL,
    name character varying(255),
    description character varying(255)
);


--
-- Name: legally_mandated_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE legally_mandated_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legally_mandated_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE legally_mandated_reasons_id_seq OWNED BY legally_mandated_reasons.id;


--
-- Name: licenses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE licenses (
    id integer NOT NULL,
    state character varying(255),
    placement_status character varying(255),
    capacity integer,
    application_date date,
    license_type character varying(255),
    resource_id integer,
    resource_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    recommendation boolean,
    approving_manager_id integer,
    assignee_id integer,
    ltc integer,
    esc integer,
    historical boolean DEFAULT false,
    effective_from_date date,
    effective_to_date date,
    current boolean DEFAULT false,
    reason_for_closure character varying(255)
);


--
-- Name: licenses_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE licenses_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: licenses_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE licenses_id_seq1 OWNED BY licenses.id;


--
-- Name: living_arrangements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE living_arrangements (
    id integer NOT NULL,
    person_id integer,
    assessment_id integer,
    value character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: living_arrangements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE living_arrangements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: living_arrangements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE living_arrangements_id_seq OWNED BY living_arrangements.id;


--
-- Name: medical_condition_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medical_condition_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: medical_condition_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medical_condition_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_condition_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medical_condition_names_id_seq OWNED BY medical_condition_names.id;


--
-- Name: medical_conditions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medical_conditions (
    id integer NOT NULL,
    diagnosing_physician_id integer,
    person_id integer,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    medical_condition_name_id integer,
    note_id integer
);


--
-- Name: medical_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medical_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medical_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medical_conditions_id_seq OWNED BY medical_conditions.id;


--
-- Name: medication_regimens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medication_regimens (
    id integer NOT NULL,
    condition character varying(255),
    dosage character varying(255),
    person_id integer,
    prescriber_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    medication_id integer,
    note_id integer
);


--
-- Name: medication_regimens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medication_regimens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medication_regimens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medication_regimens_id_seq OWNED BY medication_regimens.id;


--
-- Name: medications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE medications (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: medications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medications_id_seq OWNED BY medications.id;


--
-- Name: native_american_tribes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE native_american_tribes (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: native_american_tribes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE native_american_tribes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: native_american_tribes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE native_american_tribes_id_seq OWNED BY native_american_tribes.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE people (
    id integer NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    date_of_birth date,
    gender character varying(255),
    email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    middle_name character varying(255),
    ssn character varying(255),
    citizenship character varying(255),
    legacy_id character varying(255) DEFAULT NULL::character varying,
    hispanic_or_latino_origin character varying(255),
    religion_id integer DEFAULT 1,
    native_american_tribe_id integer,
    primary_language_id integer,
    secondary_language_id integer,
    profile_photo_file_name character varying(255),
    profile_photo_updated_at timestamp without time zone,
    race_uncertainty character varying(255),
    american_indian boolean,
    asian boolean,
    black boolean,
    pacific_islander boolean,
    white boolean,
    multi_racial boolean,
    suffix character varying(255),
    citizenship_verification character varying(255),
    citizenship_effective_date date,
    date_of_death date,
    death_verification character varying(255),
    has_died boolean,
    cpi_status boolean DEFAULT false,
    legacy_cpi_status boolean,
    earned_verify character varying(255),
    unearned_verify character varying(255),
    asset_verify character varying(255),
    medicaid_rid_number character varying(255),
    medicaid_date date,
    city_of_birth character varying(255),
    date_medical_passport date,
    health_care_questions date,
    plan_for_compliance date,
    imported boolean DEFAULT false NOT NULL
);


--
-- Name: relationship_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relationship_types (
    id integer NOT NULL,
    strong_name character varying(255) NOT NULL,
    weak_name character varying(255) NOT NULL,
    support_type character varying(255),
    generation_gap integer
);


--
-- Name: relationships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relationships (
    id integer NOT NULL,
    strong_side_person_id integer,
    weak_side_person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    paternity_confirmed boolean,
    paternity_validation_method character varying(255)
);


--
-- Name: validation_exceptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE validation_exceptions (
    id integer NOT NULL,
    unit_of_work_id integer,
    unit_of_work_type character varying(255),
    validation_item_id integer,
    reason character varying(255),
    validation_item_type character varying(255)
);


--
-- Name: ncands; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW ncands AS
    SELECT allegations.assessment_id, assessments.reported_on AS assessment_reported_on, CASE WHEN (assessments.legacy_initiation_time IS NOT NULL) THEN assessments.legacy_initiation_time ELSE initiation_times.assessment_initiation_time END AS assessment_initiation_time, assessments.accepted_at AS assessment_closed_at, allegations.id AS allegation_id, allegations.date_of_alleged_incident AS incident_date, allegations.substantiated AS allegation_substantiated, CASE WHEN (allegations.maltreatment_type_id = 1) THEN 'sexual abuse'::text WHEN (allegations.maltreatment_type_id = 2) THEN 'physical abuse'::text WHEN (allegations.maltreatment_type_id = 3) THEN 'neglect'::text ELSE 'unknown'::text END AS maltreatment_type, CASE WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 1) THEN 'Abusive Head Trauma'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 2) THEN 'Asphyxiation/Suffocation'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 3) THEN 'Bone Fracture'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 4) THEN 'Bruises/Cuts/Welts'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 5) THEN 'Burns/Scalds'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 6) THEN 'Death due to Physical Abuse'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 7) THEN 'Dislocation and Sprains'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 8) THEN 'Drowning'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 9) THEN 'Gunshot Wounds'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 10) THEN 'Illegal manufacturing of drug or controlled substance where child resides. (IC 31-34-1.2) Exposure to illegal drug manufacturing in child residence'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 11) THEN 'Inappropriate Discipline'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 12) THEN 'Internal Injury'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 13) THEN 'Near fatality due to physical abuse. Serious bodily injury requiring hospitalization in an intensive care unit'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 14) THEN 'Poisoning'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 15) THEN 'Wounds/Punctures/Bites'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 16) THEN 'Child Molesting - Under 14; performs or submits; sexual intercourse; deviate sexual conduct, touching, fondling'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 17) THEN 'Child Seduction - 16 or 17; sexual intercourse, deviate sexual conduct with step or adoptive parent, residential facility staff, etc.'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 18) THEN 'Criminal Deviate Conduct - Oral or anal sex or use of object; force, threat, or unaware'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 19) THEN 'Exploitation/Pornography - Child is photographed, videotaped, etc.'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 20) THEN 'Harmful/Obscene Performance - Parent allows child to participate in act that usually is photographed, videotaped, etc.'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 21) THEN 'Incest - Sexual intercourse, deviate sexual conduct w/relative (excluding cousins)'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 22) THEN 'Indecent Exposure - Child is a victim of or parent allows to commit; public place in public'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 23) THEN 'Living in home with sexual perpetrator and victim - Rebuttable presumptions related to living with a sex offender'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 24) THEN 'Prostitution - Child is a victim or parent allows to commit'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 25) THEN 'Rape - Sexual intercourse, force, threat, or unaware'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 26) THEN 'Sexual Misconduct with a Minor - 14 or 15, performs or submits, sexual intercourse, deviate sexual conduct, touching, fondling'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 27) THEN 'Environment Life/Health Endangering'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 28) THEN 'Abandonment'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 29) THEN 'Close/Confinement'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 30) THEN 'Death due to neglect'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 31) THEN 'Drug exposed infant'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 32) THEN 'Educational Neglect'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 33) THEN 'Emotional Abuse - Emotional abuse or injury'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 34) THEN 'Failure to Thrive'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 35) THEN 'Fetal Alcohol Syndrome'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 36) THEN 'Lack of Food, Shelter, Clothing'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 37) THEN 'Lack of Supervision'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 38) THEN 'Lock in/out'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 39) THEN 'Malnutrition'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 40) THEN 'Medical Neglect'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 41) THEN 'Near fatality due to neglect Serious bodily injury requiring hospitalization in an intensive care unit'::text WHEN (allegation_maltreatment_subtypes.maltreatment_subtype_id = 42) THEN 'Poor Hygiene'::text ELSE NULL::text END AS maltreatment_subtype, assessments.report_source_type, assessment_court_hearings.court_hearing_type, assessment_court_hearings.court_hearing_date, allegations.victim_id, victims.date_of_birth AS victim_date_of_birth, CASE WHEN (victims.race_uncertainty IS NOT NULL) THEN (victims.race_uncertainty)::text ELSE rtrim((((((CASE WHEN victims.american_indian THEN 'American Indian or Alaskan Native, '::text ELSE ''::text END || CASE WHEN victims.asian THEN 'Asian, '::text ELSE ''::text END) || CASE WHEN victims.black THEN 'Black or African American, '::text ELSE ''::text END) || CASE WHEN victims.pacific_islander THEN 'Native Hawaiian or Other Pacific Islander, '::text ELSE ''::text END) || CASE WHEN victims.white THEN 'White, '::text ELSE ''::text END) || CASE WHEN victims.multi_racial THEN 'Multi-racial and other race unknown, '::text ELSE ''::text END), ', '::text) END AS victim_race, victims.hispanic_or_latino_origin AS victim_hispanic_or_latino_origin, victims.gender AS victim_gender, living_arrangements.value AS victim_living_arrangements, victim_active_military_dependent_statuses.value AS victim_is_dependent_of_active_military, alcohol_abuse_risk_factors.value AS victim_alcohol_abuse, drug_abuse_risk_factors.value AS victim_drug_abuse, visually_hearing_impaired_risk_factors.value AS victim_visually_hearing_impaired, mental_retardation_risk_factors.value AS victim_mental_retardation, emotionally_disturbed_risk_factors.value AS victim_emotionally_disturbed, learning_disability_risk_factors.value AS victim_learning_disability, physically_disabled_risk_factors.value AS victim_physically_disabled, behavior_problem_risk_factors.value AS victim_behavior_problem, other_medical_condition_risk_factors.value AS victim_other_medical_condition, alcohol_abuse_caregiver_risk_factors.value AS caregiver_alcohol_abuse, drug_abuse_caregiver_risk_factors.value AS caregiver_drug_abuse, visually_hearing_impaired_caregiver_risk_factors.value AS caregiver_visually_hearing_impaired, mental_retardation_caregiver_risk_factors.value AS caregiver_mental_retardation, emotionally_disturbed_caregiver_risk_factors.value AS caregiver_emotionally_disturbed, learning_disability_caregiver_risk_factors.value AS caregiver_learning_disability, physically_disabled_caregiver_risk_factors.value AS caregiver_physically_disabled, domestic_violence_caregiver_risk_factors.value AS caregiver_domestic_violence, other_medical_condition_caregiver_risk_factors.value AS caregiver_other_medical_condition, public_assistance_caregiver_risk_factors.value AS caregiver_public_assistance, inadequate_housing_caregiver_risk_factors.value AS caregiver_inadequate_housing, financial_problems_caregiver_risk_factors.value AS caregiver_financial_problems, allegations.perpetrator_id, CASE WHEN (perpetrator_victim_relationships.strong_side_person_id = allegations.perpetrator_id) THEN perpetrator_victim_relationship_types.strong_name ELSE perpetrator_victim_relationship_types.weak_name END AS perpetrator_relationship_to_victim, CASE WHEN (perpetrators.race_uncertainty IS NOT NULL) THEN (perpetrators.race_uncertainty)::text ELSE rtrim((((((CASE WHEN perpetrators.american_indian THEN 'American Indian or Alaskan Native, '::text ELSE ''::text END || CASE WHEN perpetrators.asian THEN 'Asian, '::text ELSE ''::text END) || CASE WHEN perpetrators.black THEN 'Black or African American, '::text ELSE ''::text END) || CASE WHEN perpetrators.pacific_islander THEN 'Native Hawaiian or Other Pacific Islander, '::text ELSE ''::text END) || CASE WHEN perpetrators.white THEN 'White, '::text ELSE ''::text END) || CASE WHEN perpetrators.multi_racial THEN 'Multi-racial and other race unknown, '::text ELSE ''::text END), ', '::text) END AS perpetrator_race, perpetrators.hispanic_or_latino_origin AS perpetrator_hispanic_or_latino_origin, perpetrators.gender AS perpetrator_gender, perpetrators.date_of_birth AS perpetrator_date_of_birth, perpetrator_active_military_statuses.value AS perpetrator_is_active_military, CASE WHEN (assessments.county_id = 1) THEN 'Central Office'::text WHEN (assessments.county_id = 2) THEN 'Adams'::text WHEN (assessments.county_id = 3) THEN 'Allen'::text WHEN (assessments.county_id = 4) THEN 'Bartholomew'::text WHEN (assessments.county_id = 5) THEN 'Benton'::text WHEN (assessments.county_id = 6) THEN 'Blackford'::text WHEN (assessments.county_id = 7) THEN 'Boone'::text WHEN (assessments.county_id = 8) THEN 'Brown'::text WHEN (assessments.county_id = 9) THEN 'Carroll'::text WHEN (assessments.county_id = 10) THEN 'Cass'::text WHEN (assessments.county_id = 11) THEN 'Clark'::text WHEN (assessments.county_id = 12) THEN 'Clay'::text WHEN (assessments.county_id = 13) THEN 'Clinton'::text WHEN (assessments.county_id = 14) THEN 'Crawford'::text WHEN (assessments.county_id = 15) THEN 'Daviess'::text WHEN (assessments.county_id = 16) THEN 'Dearborn'::text WHEN (assessments.county_id = 17) THEN 'Decatur'::text WHEN (assessments.county_id = 18) THEN 'DeKalb'::text WHEN (assessments.county_id = 19) THEN 'Delaware'::text WHEN (assessments.county_id = 20) THEN 'Dubois'::text WHEN (assessments.county_id = 21) THEN 'Elkhart'::text WHEN (assessments.county_id = 22) THEN 'Fayette'::text WHEN (assessments.county_id = 23) THEN 'Floyd'::text WHEN (assessments.county_id = 24) THEN 'Fountain'::text WHEN (assessments.county_id = 25) THEN 'Franklin'::text WHEN (assessments.county_id = 26) THEN 'Fulton'::text WHEN (assessments.county_id = 27) THEN 'Gibson'::text WHEN (assessments.county_id = 28) THEN 'Grant'::text WHEN (assessments.county_id = 29) THEN 'Greene'::text WHEN (assessments.county_id = 30) THEN 'Hamilton'::text WHEN (assessments.county_id = 31) THEN 'Hancock'::text WHEN (assessments.county_id = 32) THEN 'Harrison'::text WHEN (assessments.county_id = 33) THEN 'Hendricks'::text WHEN (assessments.county_id = 34) THEN 'Henry'::text WHEN (assessments.county_id = 35) THEN 'Howard'::text WHEN (assessments.county_id = 36) THEN 'Huntington'::text WHEN (assessments.county_id = 37) THEN 'Jackson'::text WHEN (assessments.county_id = 38) THEN 'Jasper'::text WHEN (assessments.county_id = 39) THEN 'Jay'::text WHEN (assessments.county_id = 40) THEN 'Jefferson'::text WHEN (assessments.county_id = 41) THEN 'Jennings'::text WHEN (assessments.county_id = 42) THEN 'Johnson'::text WHEN (assessments.county_id = 43) THEN 'Knox'::text WHEN (assessments.county_id = 44) THEN 'Kosciusko'::text WHEN (assessments.county_id = 45) THEN 'LaGrange'::text WHEN (assessments.county_id = 46) THEN 'Lake'::text WHEN (assessments.county_id = 47) THEN 'LaPorte'::text WHEN (assessments.county_id = 48) THEN 'Lawrence'::text WHEN (assessments.county_id = 49) THEN 'Madison'::text WHEN (assessments.county_id = 50) THEN 'Marion'::text WHEN (assessments.county_id = 51) THEN 'Marshall'::text WHEN (assessments.county_id = 52) THEN 'Martin'::text WHEN (assessments.county_id = 53) THEN 'Miami'::text WHEN (assessments.county_id = 54) THEN 'Monroe'::text WHEN (assessments.county_id = 55) THEN 'Montgomery'::text WHEN (assessments.county_id = 56) THEN 'Morgan'::text WHEN (assessments.county_id = 57) THEN 'Newton'::text WHEN (assessments.county_id = 58) THEN 'Noble'::text WHEN (assessments.county_id = 59) THEN 'Ohio'::text WHEN (assessments.county_id = 60) THEN 'Orange'::text WHEN (assessments.county_id = 61) THEN 'Owen'::text WHEN (assessments.county_id = 62) THEN 'Parke'::text WHEN (assessments.county_id = 63) THEN 'Perry'::text WHEN (assessments.county_id = 64) THEN 'Pike'::text WHEN (assessments.county_id = 65) THEN 'Porter'::text WHEN (assessments.county_id = 66) THEN 'Posey'::text WHEN (assessments.county_id = 67) THEN 'Pulaski'::text WHEN (assessments.county_id = 68) THEN 'Putnam'::text WHEN (assessments.county_id = 69) THEN 'Randolph'::text WHEN (assessments.county_id = 70) THEN 'Ripley'::text WHEN (assessments.county_id = 71) THEN 'Rush'::text WHEN (assessments.county_id = 72) THEN 'Scott'::text WHEN (assessments.county_id = 73) THEN 'Shelby'::text WHEN (assessments.county_id = 74) THEN 'Spencer'::text WHEN (assessments.county_id = 75) THEN 'St. Joseph'::text WHEN (assessments.county_id = 76) THEN 'Starke'::text WHEN (assessments.county_id = 77) THEN 'Steuben'::text WHEN (assessments.county_id = 78) THEN 'Sullivan'::text WHEN (assessments.county_id = 79) THEN 'Switzerland'::text WHEN (assessments.county_id = 80) THEN 'Tippecanoe'::text WHEN (assessments.county_id = 81) THEN 'Tipton'::text WHEN (assessments.county_id = 82) THEN 'Union'::text WHEN (assessments.county_id = 83) THEN 'Vanderburgh'::text WHEN (assessments.county_id = 84) THEN 'Vermillion'::text WHEN (assessments.county_id = 85) THEN 'Vigo'::text WHEN (assessments.county_id = 86) THEN 'Wabash'::text WHEN (assessments.county_id = 87) THEN 'Warren'::text WHEN (assessments.county_id = 88) THEN 'Warrick'::text WHEN (assessments.county_id = 89) THEN 'Washington'::text WHEN (assessments.county_id = 90) THEN 'Wayne'::text WHEN (assessments.county_id = 91) THEN 'Wells'::text WHEN (assessments.county_id = 92) THEN 'White'::text WHEN (assessments.county_id = 93) THEN 'Whitley'::text ELSE 'unknown'::text END AS county FROM (((((((((((((((((((((((((((((((((((((allegations JOIN assessments ON ((((allegations.assessment_id = assessments.id) AND ((assessments.state)::text = 'accepted'::text)) AND (assessments.id IN (SELECT DISTINCT allegations.assessment_id FROM (allegations LEFT JOIN validation_exceptions exceptions ON (((exceptions.validation_item_id = allegations.id) AND ((exceptions.validation_item_type)::text = 'Allegation'::text)))) WHERE (exceptions.id IS NULL)))))) LEFT JOIN allegation_maltreatment_subtypes ON ((allegations.id = allegation_maltreatment_subtypes.allegation_id))) JOIN people victims ON ((allegations.victim_id = victims.id))) LEFT JOIN people perpetrators ON ((allegations.perpetrator_id = perpetrators.id))) LEFT JOIN living_arrangements ON ((allegations.victim_id = living_arrangements.person_id))) LEFT JOIN active_military_statuses perpetrator_active_military_statuses ON (((perpetrator_active_military_statuses.person_id = perpetrators.id) AND (perpetrator_active_military_statuses.assessment_id = assessments.id)))) LEFT JOIN active_military_dependent_statuses victim_active_military_dependent_statuses ON (((victim_active_military_dependent_statuses.person_id = victims.id) AND (victim_active_military_dependent_statuses.assessment_id = assessments.id)))) LEFT JOIN relationships caregiver_victim_relationships ON (((caregiver_victim_relationships.weak_side_person_id = victims.id) AND (caregiver_victim_relationships.type_id = 59)))) LEFT JOIN people caregivers ON ((caregiver_victim_relationships.strong_side_person_id = caregivers.id))) LEFT JOIN relationships perpetrator_victim_relationships ON ((((perpetrator_victim_relationships.strong_side_person_id = perpetrators.id) AND (perpetrator_victim_relationships.weak_side_person_id = victims.id)) OR ((perpetrator_victim_relationships.strong_side_person_id = victims.id) AND (perpetrator_victim_relationships.weak_side_person_id = perpetrators.id))))) LEFT JOIN relationship_types perpetrator_victim_relationship_types ON ((perpetrator_victim_relationships.type_id = perpetrator_victim_relationship_types.id))) LEFT JOIN child_risks ON ((victims.id = child_risks.person_id))) LEFT JOIN child_risk_factor_values alcohol_abuse_risk_factors ON (((alcohol_abuse_risk_factors.child_risk_id = child_risks.id) AND (alcohol_abuse_risk_factors.child_risk_factor_id = 101)))) LEFT JOIN child_risk_factor_values drug_abuse_risk_factors ON (((drug_abuse_risk_factors.child_risk_id = child_risks.id) AND (drug_abuse_risk_factors.child_risk_factor_id = 102)))) LEFT JOIN child_risk_factor_values visually_hearing_impaired_risk_factors ON (((visually_hearing_impaired_risk_factors.child_risk_id = child_risks.id) AND (visually_hearing_impaired_risk_factors.child_risk_factor_id = 103)))) LEFT JOIN child_risk_factor_values mental_retardation_risk_factors ON (((mental_retardation_risk_factors.child_risk_id = child_risks.id) AND (mental_retardation_risk_factors.child_risk_factor_id = 104)))) LEFT JOIN child_risk_factor_values emotionally_disturbed_risk_factors ON (((emotionally_disturbed_risk_factors.child_risk_id = child_risks.id) AND (emotionally_disturbed_risk_factors.child_risk_factor_id = 105)))) LEFT JOIN child_risk_factor_values learning_disability_risk_factors ON (((learning_disability_risk_factors.child_risk_id = child_risks.id) AND (learning_disability_risk_factors.child_risk_factor_id = 106)))) LEFT JOIN child_risk_factor_values physically_disabled_risk_factors ON (((physically_disabled_risk_factors.child_risk_id = child_risks.id) AND (physically_disabled_risk_factors.child_risk_factor_id = 107)))) LEFT JOIN child_risk_factor_values behavior_problem_risk_factors ON (((behavior_problem_risk_factors.child_risk_id = child_risks.id) AND (behavior_problem_risk_factors.child_risk_factor_id = 108)))) LEFT JOIN child_risk_factor_values other_medical_condition_risk_factors ON (((other_medical_condition_risk_factors.child_risk_id = child_risks.id) AND (other_medical_condition_risk_factors.child_risk_factor_id = 109)))) LEFT JOIN caregiver_health_risks ON ((caregivers.id = caregiver_health_risks.person_id))) LEFT JOIN caregiver_health_risk_factor_values alcohol_abuse_caregiver_risk_factors ON (((alcohol_abuse_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (alcohol_abuse_caregiver_risk_factors.caregiver_health_risk_factor_id = 205)))) LEFT JOIN caregiver_health_risk_factor_values drug_abuse_caregiver_risk_factors ON (((drug_abuse_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (drug_abuse_caregiver_risk_factors.caregiver_health_risk_factor_id = 206)))) LEFT JOIN caregiver_health_risk_factor_values visually_hearing_impaired_caregiver_risk_factors ON (((visually_hearing_impaired_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (visually_hearing_impaired_caregiver_risk_factors.caregiver_health_risk_factor_id = 201)))) LEFT JOIN caregiver_health_risk_factor_values mental_retardation_caregiver_risk_factors ON (((mental_retardation_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (mental_retardation_caregiver_risk_factors.caregiver_health_risk_factor_id = 207)))) LEFT JOIN caregiver_health_risk_factor_values emotionally_disturbed_caregiver_risk_factors ON (((emotionally_disturbed_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (emotionally_disturbed_caregiver_risk_factors.caregiver_health_risk_factor_id = 208)))) LEFT JOIN caregiver_health_risk_factor_values learning_disability_caregiver_risk_factors ON (((learning_disability_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (learning_disability_caregiver_risk_factors.caregiver_health_risk_factor_id = 209)))) LEFT JOIN caregiver_health_risk_factor_values physically_disabled_caregiver_risk_factors ON (((physically_disabled_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (physically_disabled_caregiver_risk_factors.caregiver_health_risk_factor_id = 203)))) LEFT JOIN caregiver_health_risk_factor_values other_medical_condition_caregiver_risk_factors ON (((other_medical_condition_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (other_medical_condition_caregiver_risk_factors.caregiver_health_risk_factor_id = 204)))) LEFT JOIN caregiver_health_risk_factor_values domestic_violence_caregiver_risk_factors ON (((domestic_violence_caregiver_risk_factors.caregiver_health_risk_id = caregiver_health_risks.id) AND (domestic_violence_caregiver_risk_factors.caregiver_health_risk_factor_id = 210)))) LEFT JOIN caregiver_financial_risks ON ((caregivers.id = caregiver_financial_risks.person_id))) LEFT JOIN caregiver_financial_risk_factor_values public_assistance_caregiver_risk_factors ON (((public_assistance_caregiver_risk_factors.caregiver_financial_risk_id = caregiver_financial_risks.id) AND (public_assistance_caregiver_risk_factors.caregiver_financial_risk_factor_id = 301)))) LEFT JOIN caregiver_financial_risk_factor_values inadequate_housing_caregiver_risk_factors ON (((inadequate_housing_caregiver_risk_factors.caregiver_financial_risk_id = caregiver_financial_risks.id) AND (inadequate_housing_caregiver_risk_factors.caregiver_financial_risk_factor_id = 302)))) LEFT JOIN caregiver_financial_risk_factor_values financial_problems_caregiver_risk_factors ON (((financial_problems_caregiver_risk_factors.caregiver_financial_risk_id = caregiver_financial_risks.id) AND (financial_problems_caregiver_risk_factors.caregiver_financial_risk_factor_id = 303)))) LEFT JOIN (SELECT notes.unit_of_work_id AS assessment_id, min(contacts.occurred_at) AS assessment_initiation_time FROM (((allegations JOIN notes ON (((notes.unit_of_work_id = allegations.assessment_id) AND ((notes.unit_of_work_type)::text = 'Assessment'::text)))) JOIN contacts ON ((contacts.note_id = notes.id))) JOIN contact_people ON (((contact_people.contact_id = contacts.id) AND (contact_people.present = true)))) WHERE ((((contacts.mode)::text = ANY (ARRAY[('Face to Face - Home'::character varying)::text, ('Face to Face - Office'::character varying)::text, ('Face to Face - Other'::character varying)::text])) AND (contact_people.person_id = allegations.victim_id)) OR ((((contact_people.person_id <> allegations.perpetrator_id) AND ((contacts.mode)::text = ANY (ARRAY[('Face to Face - Home'::character varying)::text, ('Face to Face - Office'::character varying)::text, ('Face to Face - Other'::character varying)::text, ('Telephone'::character varying)::text]))) AND (contact_people.person_id IN (SELECT contact_people.person_id FROM relationships WHERE ((relationships.strong_side_person_id = allegations.victim_id) OR (relationships.weak_side_person_id = allegations.victim_id))))) AND (contacts.occurred_at IS NOT NULL))) GROUP BY notes.unit_of_work_id) initiation_times ON ((initiation_times.assessment_id = assessments.id))) LEFT JOIN (SELECT court_hearings.id AS court_hearing_id, CASE WHEN ((court_hearings.unit_of_work_type)::text = 'Assessment'::text) THEN court_hearings.unit_of_work_id ELSE case_linked_assessments.assessment_id END AS assessment_id, court_hearings.court_hearing_type_id, court_hearings.date AS court_hearing_date, court_hearing_types.name AS court_hearing_type FROM ((court_hearings LEFT JOIN case_linked_assessments ON (((court_hearings.unit_of_work_id = case_linked_assessments.case_id) AND ((court_hearings.unit_of_work_type)::text = 'Case'::text)))) JOIN court_hearing_types ON ((court_hearings.court_hearing_type_id = court_hearing_types.id))) WHERE (((court_hearing_types.name)::text = 'CHINS - Initial'::text) OR ((court_hearing_types.name)::text = 'Detention/Emergency Detention'::text))) assessment_court_hearings ON ((((assessment_court_hearings.assessment_id = assessments.id) AND (assessment_court_hearings.court_hearing_date >= (assessments.reported_on)::date)) AND (assessment_court_hearings.court_hearing_date <= ((assessments.accepted_at + '90 days'::interval))::date))));


--
-- Name: neglect_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE neglect_quizzes (
    id integer NOT NULL,
    n1 boolean,
    n2 character varying(255),
    n3 boolean,
    n4 character varying(255),
    n5 character varying(255),
    n6 text,
    n7 character varying(255),
    n8 boolean,
    n9 character varying(255),
    n10 text,
    n11 text,
    n12 text,
    risk_assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: neglect_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE neglect_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neglect_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE neglect_quizzes_id_seq OWNED BY neglect_quizzes.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    subject_id integer,
    subject_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    content text,
    notification_type character varying(255),
    seen boolean DEFAULT false NOT NULL,
    user_id integer
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: offered_services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE offered_services (
    id integer NOT NULL,
    service_provider_id integer,
    service_id integer
);


--
-- Name: offered_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE offered_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offered_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE offered_services_id_seq OWNED BY offered_services.id;


--
-- Name: open_id_associations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE open_id_associations (
    id integer NOT NULL,
    server_url bytea,
    secret bytea,
    handle character varying(255),
    assoc_type character varying(255),
    issued integer,
    lifetime integer
);


--
-- Name: open_id_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE open_id_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_id_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE open_id_associations_id_seq OWNED BY open_id_associations.id;


--
-- Name: open_id_nonces; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE open_id_nonces (
    id integer NOT NULL,
    server_url character varying(255) NOT NULL,
    salt character varying(255) NOT NULL,
    "timestamp" integer NOT NULL
);


--
-- Name: open_id_nonces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE open_id_nonces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_id_nonces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE open_id_nonces_id_seq OWNED BY open_id_nonces.id;


--
-- Name: open_id_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE open_id_requests (
    id integer NOT NULL,
    token character varying(40),
    parameters text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: open_id_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE open_id_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_id_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE open_id_requests_id_seq OWNED BY open_id_requests.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organizations (
    id integer NOT NULL,
    name character varying(255),
    phone_number character varying(255),
    email character varying(255),
    address character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organizations_id_seq OWNED BY organizations.id;


--
-- Name: parental_deprivation_checklists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parental_deprivation_checklists (
    id integer NOT NULL,
    eligibility_application_id integer,
    parent_id integer,
    deprived boolean,
    event_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parental_deprivation_checklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parental_deprivation_checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parental_deprivation_checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parental_deprivation_checklists_id_seq OWNED BY parental_deprivation_checklists.id;


--
-- Name: parental_deprivation_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parental_deprivation_values (
    id integer NOT NULL,
    parental_deprivation_checklist_id integer,
    parental_deprivation_item_id integer,
    selected boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parental_deprivation_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parental_deprivation_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parental_deprivation_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parental_deprivation_values_id_seq OWNED BY parental_deprivation_values.id;


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE people_id_seq OWNED BY people.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pg_search_documents (
    id integer NOT NULL,
    content text,
    searchable_id integer,
    searchable_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pg_search_documents_id_seq OWNED BY pg_search_documents.id;


--
-- Name: phone_numbers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE phone_numbers (
    id integer NOT NULL,
    number character varying(255),
    label character varying(255),
    person_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    note_id integer
);


--
-- Name: phone_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phone_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phone_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phone_numbers_id_seq OWNED BY phone_numbers.id;


--
-- Name: physical_location_placements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE physical_location_placements (
    id integer NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    relationship_to_child character varying(255),
    relocating_to_non_custodial_parent boolean,
    removal_court_ordered boolean,
    result_of_voluntary_placement_agreement boolean,
    physical_abuse boolean,
    sexual_abuse boolean,
    neglect boolean,
    parent_alcohol_abuse boolean,
    parent_drug_abuse boolean,
    child_alcohol_abuse boolean,
    child_disability boolean,
    child_behavioral_problem boolean,
    death_of_parent boolean,
    incarceration_of_parent boolean,
    caretaker_inability_to_cope boolean,
    abandonment boolean,
    relinquishment boolean,
    approved_by_supervisor boolean,
    approving_supervisor_id integer,
    supervisor_approval_date date,
    court_hearing_type integer,
    court_hearing_date date,
    reason_for_change text,
    legacy_id character varying(255),
    resource_id integer,
    ends_episode boolean DEFAULT false,
    child_drug_abuse boolean,
    inadequate_housing boolean,
    family_structure character varying(255),
    ever_adopted boolean,
    ever_adopted_age character varying(255)
);


--
-- Name: physical_location_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE physical_location_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_location_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE physical_location_placements_id_seq OWNED BY physical_location_placements.id;


--
-- Name: physical_location_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE physical_location_records (
    id integer NOT NULL,
    person_id integer,
    physical_location_id integer,
    physical_location_type character varying(255)
);


--
-- Name: physical_location_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE physical_location_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_location_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE physical_location_records_id_seq OWNED BY physical_location_records.id;


--
-- Name: physical_location_runaways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE physical_location_runaways (
    id integer NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    ends_episode boolean DEFAULT false
);


--
-- Name: physical_location_runaways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE physical_location_runaways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_location_runaways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE physical_location_runaways_id_seq OWNED BY physical_location_runaways.id;


--
-- Name: physical_location_temporary_absences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE physical_location_temporary_absences (
    id integer NOT NULL,
    relationship_to_child character varying(255),
    temporary_absence_type character varying(255),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    resource_id integer,
    ends_episode boolean DEFAULT false,
    reason_for_change text
);


--
-- Name: physical_location_temporary_absences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE physical_location_temporary_absences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_location_temporary_absences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE physical_location_temporary_absences_id_seq OWNED BY physical_location_temporary_absences.id;


--
-- Name: physical_location_trial_home_visits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE physical_location_trial_home_visits (
    id integer NOT NULL,
    relationship_to_child character varying(255),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    resource_id integer,
    ends_episode boolean DEFAULT false,
    reason_for_change text
);


--
-- Name: physical_location_trial_home_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE physical_location_trial_home_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: physical_location_trial_home_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE physical_location_trial_home_visits_id_seq OWNED BY physical_location_trial_home_visits.id;


--
-- Name: placed_people_safety_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE placed_people_safety_assessments (
    id integer NOT NULL,
    person_id integer,
    safety_assessment_id integer
);


--
-- Name: placed_people_safety_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE placed_people_safety_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: placed_people_safety_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE placed_people_safety_assessments_id_seq OWNED BY placed_people_safety_assessments.id;


--
-- Name: placement_status_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE placement_status_quizzes (
    id integer NOT NULL,
    months_in_placement integer,
    recent_months_in_placement integer,
    moved_since_last_plan boolean,
    moved_since_last_plan_explanation character varying(255),
    least_restrictive boolean,
    least_restrictive_explanation character varying(255),
    siblings_together boolean,
    siblings_together_explanation character varying(255),
    essential_connections boolean,
    essential_connections_explanation character varying(255),
    connections_preserved boolean,
    connections_preserved_explanation character varying(255),
    tribal_membership boolean,
    tribal_relationship character varying(255),
    case_plan_focus_child_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: placement_status_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE placement_status_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: placement_status_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE placement_status_quizzes_id_seq OWNED BY placement_status_quizzes.id;


--
-- Name: plan_agreement_item_focus_children; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plan_agreement_item_focus_children (
    id integer NOT NULL,
    plan_agreement_item_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: plan_agreement_item_focus_children_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plan_agreement_item_focus_children_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_agreement_item_focus_children_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plan_agreement_item_focus_children_id_seq OWNED BY plan_agreement_item_focus_children.id;


--
-- Name: plan_agreement_item_monitors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plan_agreement_item_monitors (
    id integer NOT NULL,
    plan_agreement_item_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: plan_agreement_item_monitors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plan_agreement_item_monitors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_agreement_item_monitors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plan_agreement_item_monitors_id_seq OWNED BY plan_agreement_item_monitors.id;


--
-- Name: plan_agreement_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plan_agreement_items (
    id integer NOT NULL,
    safety_plan_id integer,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: plan_agreement_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plan_agreement_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_agreement_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plan_agreement_items_id_seq OWNED BY plan_agreement_items.id;


--
-- Name: potential_match_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE potential_match_records (
    id integer NOT NULL,
    person_id integer,
    first_name character varying(255),
    last_name character varying(255),
    middle_name character varying(255),
    ssn character varying(255),
    date_of_birth timestamp without time zone,
    gender character varying(255),
    asian boolean,
    black boolean,
    white boolean,
    race_uncertainty boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    score integer,
    confirmed boolean,
    source_system character varying(255),
    source_id character varying(255),
    source_id_type character varying(255)
);


--
-- Name: potential_match_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE potential_match_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: potential_match_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE potential_match_records_id_seq OWNED BY potential_match_records.id;


--
-- Name: previous_passwords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE previous_passwords (
    id integer NOT NULL,
    encrypted_password character varying(255) NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: previous_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE previous_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: previous_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE previous_passwords_id_seq OWNED BY previous_passwords.id;


--
-- Name: provision_questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE provision_questions (
    id integer NOT NULL,
    provision_id integer,
    text text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    kind character varying(255),
    sort_order integer
);


--
-- Name: provision_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE provision_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provision_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE provision_questions_id_seq OWNED BY provision_questions.id;


--
-- Name: provisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE provisions (
    id integer NOT NULL,
    "group" character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    sort_order integer
);


--
-- Name: provisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE provisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE provisions_id_seq OWNED BY provisions.id;


--
-- Name: reassessment_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reassessment_quizzes (
    id integer NOT NULL,
    r1 character varying(255),
    r2 boolean,
    r3 boolean,
    r4 text,
    r5 boolean,
    r6 text,
    r7 character varying(255),
    r8 boolean,
    r9 character varying(255),
    r10 text,
    complete boolean DEFAULT false NOT NULL,
    risk_reassessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: reassessment_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reassessment_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reassessment_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reassessment_quizzes_id_seq OWNED BY reassessment_quizzes.id;


--
-- Name: recovery_passwords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE recovery_passwords (
    id integer NOT NULL,
    password character varying(255),
    token character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: recovery_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recovery_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recovery_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recovery_passwords_id_seq OWNED BY recovery_passwords.id;


--
-- Name: referral_objectives; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE referral_objectives (
    id integer NOT NULL,
    text text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    referral_id integer
);


--
-- Name: referral_objectives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE referral_objectives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: referral_objectives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE referral_objectives_id_seq OWNED BY referral_objectives.id;


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE referrals (
    id integer NOT NULL,
    frequency character varying(255),
    start_date date,
    end_date date,
    unit_of_work_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    service_category_id integer NOT NULL,
    identified_on date,
    reason text,
    dcs_reason text,
    other_info text,
    state character varying(255),
    provider_id integer,
    legacy_id character varying(255),
    unit_of_work_type character varying(255)
);


--
-- Name: referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE referrals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE referrals_id_seq OWNED BY referrals.id;


--
-- Name: relationship_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE relationship_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relationship_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE relationship_types_id_seq OWNED BY relationship_types.id;


--
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE relationships_id_seq OWNED BY relationships.id;


--
-- Name: religions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE religions (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: religions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE religions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: religions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE religions_id_seq OWNED BY religions.id;


--
-- Name: residencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE residencies (
    id integer NOT NULL,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status character varying(255),
    legacy_id character varying(255) DEFAULT NULL::character varying,
    start_date date,
    end_date date,
    current boolean DEFAULT true,
    address_id integer
);


--
-- Name: residencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE residencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: residencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE residencies_id_seq OWNED BY residencies.id;


--
-- Name: residential_resource_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE residential_resource_types (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: residential_resource_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE residential_resource_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: residential_resource_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE residential_resource_types_id_seq OWNED BY residential_resource_types.id;


--
-- Name: residential_resources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE residential_resources (
    id integer NOT NULL,
    resource_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: residential_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE residential_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: residential_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE residential_resources_id_seq OWNED BY residential_resources.id;


--
-- Name: resources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE resources (
    id integer NOT NULL,
    name character varying(255),
    county_id integer,
    meta_resource_type character varying(255),
    meta_resource_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    fein character varying(255),
    parent_resource_id integer,
    phone character varying(255),
    resource_number character varying(255),
    legacy_id character varying(255),
    assignee_id integer,
    status_id integer DEFAULT 0,
    status_changed_by_id integer,
    duplicate_of_id integer,
    address_id integer,
    created_by_id integer
);


--
-- Name: resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE resources_id_seq OWNED BY resources.id;


--
-- Name: resque_job_to_retries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE resque_job_to_retries (
    id integer NOT NULL,
    json text NOT NULL,
    job_class character varying(255) NOT NULL,
    attempts integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: resque_job_to_retries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE resque_job_to_retries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resque_job_to_retries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE resque_job_to_retries_id_seq OWNED BY resque_job_to_retries.id;


--
-- Name: risk_assessment_decisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE risk_assessment_decisions (
    id integer NOT NULL,
    d1 text,
    d2 boolean,
    d3 boolean,
    d4 boolean,
    d5 boolean,
    d6 text,
    d7 text,
    d8 boolean,
    d9 boolean,
    risk_assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    d10 text
);


--
-- Name: risk_assessment_decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE risk_assessment_decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_assessment_decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE risk_assessment_decisions_id_seq OWNED BY risk_assessment_decisions.id;


--
-- Name: risk_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE risk_assessments (
    id integer NOT NULL,
    date_of_assessment date,
    assessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    q1 boolean,
    q2 boolean,
    q3 boolean,
    q4 boolean,
    override character varying(255),
    state character varying(255),
    closed_date date
);


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE risk_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE risk_assessments_id_seq OWNED BY risk_assessments.id;


--
-- Name: risk_factors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE risk_factors (
    id integer NOT NULL,
    name character varying(255),
    type character varying(255),
    sort_order integer
);


--
-- Name: risk_factors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE risk_factors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_factors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE risk_factors_id_seq OWNED BY risk_factors.id;


--
-- Name: risk_reassessment_focus_children; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE risk_reassessment_focus_children (
    id integer NOT NULL,
    person_id integer,
    risk_reassessment_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: risk_reassessment_focus_children_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE risk_reassessment_focus_children_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_reassessment_focus_children_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE risk_reassessment_focus_children_id_seq OWNED BY risk_reassessment_focus_children.id;


--
-- Name: risk_reassessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE risk_reassessments (
    id integer NOT NULL,
    date_of_assessment date,
    unit_of_work_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    unit_of_work_type character varying(255) NOT NULL,
    state character varying(255) DEFAULT 'scored_risk_level'::character varying,
    q1 boolean,
    q2 boolean,
    q3 boolean,
    q4 boolean,
    reassessment_type character varying(255),
    override character varying(255)
);


--
-- Name: risk_reassessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE risk_reassessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_reassessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE risk_reassessments_id_seq OWNED BY risk_reassessments.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles_users (
    role_id integer,
    user_id integer
);


--
-- Name: safety_assessments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE safety_assessments (
    id integer NOT NULL,
    unit_of_work_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    date_of_assessment date,
    safety_decision character varying(255),
    safety_threat1 text,
    safety_threat2 boolean,
    safety_threat3 boolean,
    safety_threat4 boolean,
    safety_threat5 boolean,
    safety_threat6 boolean,
    safety_threat7 boolean,
    safety_threat8 boolean,
    safety_threat9 boolean,
    safety_threat10 boolean,
    safety_threat11 boolean,
    safety_threat12 boolean,
    child_protective_factor1 boolean,
    caregiver_protective_factor1 boolean,
    caregiver_protective_factor2 boolean,
    caregiver_protective_factor3 boolean,
    caregiver_protective_factor4 boolean,
    caregiver_protective_factor5 boolean,
    caregiver_protective_factor6 boolean,
    caregiver_protective_factor7 boolean,
    caregiver_protective_factor8 boolean,
    caregiver_protective_factor9 boolean,
    safety_response1 boolean,
    safety_response2 boolean,
    safety_response3 boolean,
    safety_response4 boolean,
    safety_response5 boolean,
    safety_response7 boolean,
    household_name character varying(255),
    allegations_in_this_household boolean,
    initial_assessment boolean,
    all_children_placed boolean,
    safety_threat13 text,
    caregiver_protective_factor10 text,
    safety_response6 text,
    vulnerability_factor1 boolean,
    vulnerability_factor2 boolean,
    vulnerability_factor3 boolean,
    vulnerability_factor4 boolean,
    vulnerability_factor5 boolean,
    safety_decision_override_narrative text,
    unit_of_work_type character varying(255),
    state character varying(255),
    closed_date date
);


--
-- Name: safety_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE safety_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: safety_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE safety_assessments_id_seq OWNED BY safety_assessments.id;


--
-- Name: safety_plan_agreement_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE safety_plan_agreement_contacts (
    id integer NOT NULL,
    safety_plan_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: safety_plan_agreement_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE safety_plan_agreement_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: safety_plan_agreement_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE safety_plan_agreement_contacts_id_seq OWNED BY safety_plan_agreement_contacts.id;


--
-- Name: safety_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE safety_plans (
    id integer NOT NULL,
    unit_of_work_id integer,
    circumstances text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reporting_counties character varying(255),
    unit_of_work_type character varying(255) NOT NULL,
    effective_date date
);


--
-- Name: safety_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE safety_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: safety_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE safety_plans_id_seq OWNED BY safety_plans.id;


--
-- Name: scheduled_visits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scheduled_visits (
    id integer NOT NULL,
    visitation_plan_id integer,
    day_of_week character varying(255),
    contact_type character varying(255),
    "time" character varying(255),
    duration character varying(255),
    frequency character varying(255),
    location character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: scheduled_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scheduled_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scheduled_visits_id_seq OWNED BY scheduled_visits.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: school_change_quizzes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE school_change_quizzes (
    id integer NOT NULL,
    case_plan_focus_child_id integer NOT NULL,
    distance_from_school text,
    attend_same_school text,
    coordinate text,
    best_interest text,
    school_notified boolean,
    school_notified_explanation text,
    school_records boolean,
    school_records_explanation text,
    transition boolean,
    transition_explanation text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: school_change_quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE school_change_quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_change_quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE school_change_quizzes_id_seq OWNED BY school_change_quizzes.id;


--
-- Name: school_record_grade_levels; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE school_record_grade_levels (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: school_record_grade_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE school_record_grade_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_record_grade_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE school_record_grade_levels_id_seq OWNED BY school_record_grade_levels.id;


--
-- Name: school_record_new_school_reasons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE school_record_new_school_reasons (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: school_record_reasons_for_new_school_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE school_record_reasons_for_new_school_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_record_reasons_for_new_school_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE school_record_reasons_for_new_school_id_seq OWNED BY school_record_new_school_reasons.id;


--
-- Name: school_records; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE school_records (
    id integer NOT NULL,
    person_id integer,
    grade_level_id integer,
    start_date date,
    end_date date,
    contact_person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    current boolean DEFAULT true,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    enrolled boolean DEFAULT true NOT NULL,
    not_enrolled_reason text,
    extracurricular_activities text,
    disciplinary_actions text,
    reason_for_new_school_id integer,
    school_id integer
);


--
-- Name: school_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE school_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE school_records_id_seq OWNED BY school_records.id;


--
-- Name: schools; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schools (
    id integer NOT NULL,
    name character varying(255),
    address character varying(255),
    doe boolean DEFAULT true NOT NULL
);


--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schools_id_seq OWNED BY schools.id;


--
-- Name: service_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_categories (
    id integer NOT NULL,
    name character varying(255),
    description text,
    service_code_id character varying(255),
    start_date date,
    end_date date,
    service_code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    service_category_type_id integer,
    legacy_id character varying(255)
);


--
-- Name: service_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_categories_id_seq OWNED BY service_categories.id;


--
-- Name: service_category_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_category_types (
    id integer NOT NULL,
    name character varying(255),
    description text,
    service_code character varying(255),
    service_code_id character varying(255),
    start_date date,
    end_date date
);


--
-- Name: service_category_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_category_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_category_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_category_types_id_seq OWNED BY service_category_types.id;


--
-- Name: service_provider_types; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_provider_types (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: service_provider_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_provider_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_provider_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_provider_types_id_seq OWNED BY service_provider_types.id;


--
-- Name: service_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE service_providers (
    id integer NOT NULL,
    dba character varying(255),
    contact_email character varying(255),
    fax_number character varying(255),
    policy_person_name character varying(255),
    policy_person_email character varying(255),
    policy_person_phone character varying(255),
    policy_person_fax character varying(255),
    comments text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    resource_type_id integer
);


--
-- Name: service_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE service_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE service_providers_id_seq OWNED BY service_providers.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE services (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE services_id_seq OWNED BY services.id;


--
-- Name: signatories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE signatories (
    id integer NOT NULL,
    person_id integer,
    signable_id integer,
    signed boolean DEFAULT false,
    signed_on date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    signable_type character varying(255)
);


--
-- Name: signatories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE signatories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signatories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE signatories_id_seq OWNED BY signatories.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sites (
    id integer NOT NULL,
    account_id integer,
    url character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sites_id_seq OWNED BY sites.id;


--
-- Name: special_diet_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE special_diet_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: special_diet_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE special_diet_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_diet_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE special_diet_names_id_seq OWNED BY special_diet_names.id;


--
-- Name: special_diets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE special_diets (
    id integer NOT NULL,
    person_id integer,
    special_diet_name_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255)
);


--
-- Name: special_diets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE special_diets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_diets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE special_diets_id_seq OWNED BY special_diets.id;


--
-- Name: special_needs_checklists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE special_needs_checklists (
    id integer NOT NULL,
    license_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: special_needs_checklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE special_needs_checklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_needs_checklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE special_needs_checklists_id_seq OWNED BY special_needs_checklists.id;


--
-- Name: special_needs_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE special_needs_values (
    id integer NOT NULL,
    special_needs_checklist_id integer,
    special_needs_item_id integer,
    selected boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: special_needs_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE special_needs_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_needs_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE special_needs_values_id_seq OWNED BY special_needs_values.id;


--
-- Name: staff_members; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE staff_members (
    id integer NOT NULL,
    role character varying(255),
    person_id integer,
    residential_resource_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: staff_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE staff_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE staff_members_id_seq OWNED BY staff_members.id;


--
-- Name: status_determination_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE status_determination_events (
    id integer NOT NULL,
    eligibility_id integer,
    eligibility_type character varying(255),
    failing_criteria text,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status character varying(255),
    summary character varying(255),
    start_date date,
    end_date date
);


--
-- Name: status_determination_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE status_determination_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_determination_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE status_determination_events_id_seq OWNED BY status_determination_events.id;


--
-- Name: team_meeting_facilitators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE team_meeting_facilitators (
    id integer NOT NULL,
    team_meeting_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: team_meeting_facilitators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_meeting_facilitators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_meeting_facilitators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_meeting_facilitators_id_seq OWNED BY team_meeting_facilitators.id;


--
-- Name: team_meeting_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE team_meeting_people (
    id integer NOT NULL,
    team_meeting_id integer,
    person_id integer,
    regarding boolean,
    present boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: team_meeting_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_meeting_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_meeting_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_meeting_people_id_seq OWNED BY team_meeting_people.id;


--
-- Name: team_meetings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE team_meetings (
    id integer NOT NULL,
    mode character varying(255),
    occurred_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    successful boolean,
    location character varying(255),
    confidentiality_signed boolean,
    safety_level character varying(255),
    safety_plan text,
    ground_rules text,
    child_functional_strengths text,
    caregiver_functional_strengths text,
    changes_needed text,
    note_id integer,
    next_meeting_location character varying(255),
    next_meeting_date date,
    visitation_plan text,
    has_safety_concern boolean,
    safety_concerns text
);


--
-- Name: team_meetings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_meetings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_meetings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_meetings_id_seq OWNED BY team_meetings.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT NULL::character varying,
    encrypted_password character varying(255) DEFAULT ''::character varying,
    reset_password_token character varying(255),
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying(255),
    locked_at timestamp without time zone,
    authentication_token character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    manager_id integer,
    person_id integer,
    invitation_token character varying(60),
    invitation_sent_at timestamp without time zone,
    county_id integer,
    legacy_id character varying(255) DEFAULT NULL::character varying,
    enabled boolean DEFAULT true NOT NULL,
    password_changed_at timestamp without time zone,
    worker_id character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: validation_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE validation_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: validation_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE validation_exceptions_id_seq OWNED BY validation_exceptions.id;


--
-- Name: visitation_plan_people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visitation_plan_people (
    id integer NOT NULL,
    visitation_plan_id integer,
    person_id integer,
    permitted boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: visitation_plan_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visitation_plan_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visitation_plan_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visitation_plan_people_id_seq OWNED BY visitation_plan_people.id;


--
-- Name: visitation_plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE visitation_plans (
    id integer NOT NULL,
    unit_of_work_id integer,
    plan_child_id integer,
    visitation_goal text,
    additional_details text,
    supervisors_list text,
    protective_orders text,
    appropriate_activities text,
    code_of_conduct text,
    alt_contact_necessary boolean,
    alt_contact_arranged boolean,
    alt_contact_details text,
    transition_plan text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    legacy_id character varying(255),
    unit_of_work_type character varying(255),
    historical boolean DEFAULT false NOT NULL
);


--
-- Name: visitation_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visitation_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visitation_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visitation_plans_id_seq OWNED BY visitation_plans.id;


--
-- Name: waivers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE waivers (
    id integer NOT NULL,
    license_id integer,
    waiver_type character varying(255),
    reason text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: waivers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE waivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: waivers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE waivers_id_seq OWNED BY waivers.id;


--
-- Name: workflow_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflow_events (
    id integer NOT NULL,
    model_with_workflow_id integer NOT NULL,
    model_with_workflow_type character varying(255) NOT NULL,
    user_id integer,
    action character varying(255) NOT NULL,
    original_target_id integer,
    original_target_type character varying(255),
    legacy_id character varying(255),
    comment text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    properties text
);


--
-- Name: workflow_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflow_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflow_events_id_seq OWNED BY workflow_events.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE abuse_quizzes ALTER COLUMN id SET DEFAULT nextval('abuse_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE active_military_dependent_statuses ALTER COLUMN id SET DEFAULT nextval('active_military_dependent_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE active_military_statuses ALTER COLUMN id SET DEFAULT nextval('active_military_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE admin_style_guide_mock_people ALTER COLUMN id SET DEFAULT nextval('admin_style_guide_mock_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE admin_style_guide_object_people ALTER COLUMN id SET DEFAULT nextval('admin_style_guide_object_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE admin_style_guide_object_types ALTER COLUMN id SET DEFAULT nextval('admin_style_guide_object_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE admin_style_guide_objects ALTER COLUMN id SET DEFAULT nextval('admin_style_guide_objects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE adverse_reaction_names ALTER COLUMN id SET DEFAULT nextval('adverse_reaction_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE adverse_reactions ALTER COLUMN id SET DEFAULT nextval('adverse_reactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE aid_to_families_with_dependent_children_limits ALTER COLUMN id SET DEFAULT nextval('aid_to_families_with_dependent_children_limits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allegation_maltreatment_subtypes ALTER COLUMN id SET DEFAULT nextval('allegation_maltreatment_subtypes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allegations ALTER COLUMN id SET DEFAULT nextval('allegations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allergies ALTER COLUMN id SET DEFAULT nextval('allergies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE allergy_names ALTER COLUMN id SET DEFAULT nextval('allergy_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE applicants ALTER COLUMN id SET DEFAULT nextval('applicants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_allegations ALTER COLUMN id SET DEFAULT nextval('archived_allegations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_assessment_legally_mandated_reasons ALTER COLUMN id SET DEFAULT nextval('archived_assessment_legally_mandated_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_assessments ALTER COLUMN id SET DEFAULT nextval('archived_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_attachments ALTER COLUMN id SET DEFAULT nextval('archived_attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_notes ALTER COLUMN id SET DEFAULT nextval('archived_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE archived_relationships ALTER COLUMN id SET DEFAULT nextval('archived_relationships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assessed_people_safety_assessments ALTER COLUMN id SET DEFAULT nextval('assessed_people_safety_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assessment_legally_mandated_reasons ALTER COLUMN id SET DEFAULT nextval('assessment_legally_mandated_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assessment_report_source_types ALTER COLUMN id SET DEFAULT nextval('assessment_report_source_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assessment_response_times ALTER COLUMN id SET DEFAULT nextval('assessment_response_times_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assessments ALTER COLUMN id SET DEFAULT nextval('assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assistance_group_people ALTER COLUMN id SET DEFAULT nextval('assistance_group_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE attachments ALTER COLUMN id SET DEFAULT nextval('attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE audit_log ALTER COLUMN id SET DEFAULT nextval('audit_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE background_checks ALTER COLUMN id SET DEFAULT nextval('background_checks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cans_assessment_cans_tools ALTER COLUMN id SET DEFAULT nextval('cans_assessment_cans_tools_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cans_assessment_health_recommendations ALTER COLUMN id SET DEFAULT nextval('cans_assessment_health_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cans_assessment_placement_recommendations ALTER COLUMN id SET DEFAULT nextval('cans_assessment_placement_recommendations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cans_assessments ALTER COLUMN id SET DEFAULT nextval('cans_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_financial_risk_factor_values ALTER COLUMN id SET DEFAULT nextval('caregiver_financial_risk_factor_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_financial_risks ALTER COLUMN id SET DEFAULT nextval('caregiver_financial_risks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_health_risk_factor_values ALTER COLUMN id SET DEFAULT nextval('caregiver_health_risk_factor_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_health_risks ALTER COLUMN id SET DEFAULT nextval('caregiver_health_risks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_strengths_and_needs_assessment_quizzes ALTER COLUMN id SET DEFAULT nextval('caregiver_strengths_and_needs_assessment_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE caregiver_strengths_and_needs_assessments ALTER COLUMN id SET DEFAULT nextval('caregiver_strengths_and_needs_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_focus_child_involvements ALTER COLUMN id SET DEFAULT nextval('case_focus_child_involvements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_focus_children ALTER COLUMN id SET DEFAULT nextval('case_focus_children_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_linked_assessments ALTER COLUMN id SET DEFAULT nextval('case_linked_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_plan_caregivers ALTER COLUMN id SET DEFAULT nextval('case_plan_caregivers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_plan_focus_child_planned_caregivers ALTER COLUMN id SET DEFAULT nextval('case_plan_focus_child_planned_caregivers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_plan_focus_children ALTER COLUMN id SET DEFAULT nextval('case_plan_focus_children_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_plan_safety_plan_links ALTER COLUMN id SET DEFAULT nextval('case_plan_safety_plan_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE case_plans ALTER COLUMN id SET DEFAULT nextval('case_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE cases ALTER COLUMN id SET DEFAULT nextval('cases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE checklist_answers ALTER COLUMN id SET DEFAULT nextval('checklist_answers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE checklist_types ALTER COLUMN id SET DEFAULT nextval('checklist_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE checklists ALTER COLUMN id SET DEFAULT nextval('checklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE child_risk_factor_values ALTER COLUMN id SET DEFAULT nextval('child_risk_factor_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE child_risks ALTER COLUMN id SET DEFAULT nextval('child_risks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contact_people ALTER COLUMN id SET DEFAULT nextval('contact_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE corrective_action_plans ALTER COLUMN id SET DEFAULT nextval('corrective_action_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE counties ALTER COLUMN id SET DEFAULT nextval('counties_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_hearing_hearing_outcomes ALTER COLUMN id SET DEFAULT nextval('court_hearing_court_hearing_outcomes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_hearing_outcomes ALTER COLUMN id SET DEFAULT nextval('court_hearing_outcomes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_hearing_types ALTER COLUMN id SET DEFAULT nextval('court_hearing_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_hearings ALTER COLUMN id SET DEFAULT nextval('court_hearings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_hearings_court_language_citations ALTER COLUMN id SET DEFAULT nextval('court_hearings_court_language_citations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE court_language_citations ALTER COLUMN id SET DEFAULT nextval('court_language_citations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE custom_provision_with_questions ALTER COLUMN id SET DEFAULT nextval('custom_provisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE data_broker_event_logs ALTER COLUMN id SET DEFAULT nextval('data_broker_event_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE data_broker_traffic_logs ALTER COLUMN id SET DEFAULT nextval('data_broker_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE deprivation_types ALTER COLUMN id SET DEFAULT nextval('deprivation_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE discretionary_overrides ALTER COLUMN id SET DEFAULT nextval('discretionary_overrides_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE educational_overview_quizzes ALTER COLUMN id SET DEFAULT nextval('educational_overview_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE eligibility_applications ALTER COLUMN id SET DEFAULT nextval('eligibility_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE email_notes ALTER COLUMN id SET DEFAULT nextval('email_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE emails ALTER COLUMN id SET DEFAULT nextval('emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE emergency_assistance_eligibilities ALTER COLUMN id SET DEFAULT nextval('emergency_assistance_eligibilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE employment_records ALTER COLUMN id SET DEFAULT nextval('employment_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE external_roles ALTER COLUMN id SET DEFAULT nextval('external_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE federal_poverty_income_limits ALTER COLUMN id SET DEFAULT nextval('federal_poverty_income_limits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE foster_families ALTER COLUMN id SET DEFAULT nextval('foster_families_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE foster_family_other_household_members ALTER COLUMN id SET DEFAULT nextval('foster_family_other_household_members_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE health_care_provider_names ALTER COLUMN id SET DEFAULT nextval('health_care_provider_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE health_care_providers ALTER COLUMN id SET DEFAULT nextval('health_care_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE health_exam_names ALTER COLUMN id SET DEFAULT nextval('health_exam_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE health_exams ALTER COLUMN id SET DEFAULT nextval('health_exams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE historical_records ALTER COLUMN id SET DEFAULT nextval('historical_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_court_consent_people ALTER COLUMN id SET DEFAULT nextval('ia_court_consent_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_hearing_waiver_people ALTER COLUMN id SET DEFAULT nextval('ia_hearing_waiver_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_plan_child_supervisors ALTER COLUMN id SET DEFAULT nextval('ia_plan_child_supervisors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_plan_contact_and_visitation_types ALTER COLUMN id SET DEFAULT nextval('ia_plan_contact_and_visitation_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_plan_provisions ALTER COLUMN id SET DEFAULT nextval('ia_plan_provisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_plans ALTER COLUMN id SET DEFAULT nextval('ia_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ia_progress_reports ALTER COLUMN id SET DEFAULT nextval('ia_progress_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE identification_types ALTER COLUMN id SET DEFAULT nextval('identification_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE identifications ALTER COLUMN id SET DEFAULT nextval('identifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE immunization_names ALTER COLUMN id SET DEFAULT nextval('immunization_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE immunizations ALTER COLUMN id SET DEFAULT nextval('immunizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE income_record_types ALTER COLUMN id SET DEFAULT nextval('income_record_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE income_records ALTER COLUMN id SET DEFAULT nextval('income_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE insurance_provider_names ALTER COLUMN id SET DEFAULT nextval('insurance_provider_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE insurance_providers ALTER COLUMN id SET DEFAULT nextval('insurance_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE intake_allegations ALTER COLUMN id SET DEFAULT nextval('intake_allegations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE intake_legally_mandated_reasons ALTER COLUMN id SET DEFAULT nextval('intake_legally_mandated_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE intake_people ALTER COLUMN id SET DEFAULT nextval('intake_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE intakes ALTER COLUMN id SET DEFAULT nextval('intakes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE involvement_types ALTER COLUMN id SET DEFAULT nextval('involvement_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE iv_e_eligibilities ALTER COLUMN id SET DEFAULT nextval('iv_e_eligibilities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE languages ALTER COLUMN id SET DEFAULT nextval('languages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE legally_mandated_reasons ALTER COLUMN id SET DEFAULT nextval('legally_mandated_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE licenses ALTER COLUMN id SET DEFAULT nextval('licenses_id_seq1'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE living_arrangements ALTER COLUMN id SET DEFAULT nextval('living_arrangements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE medical_condition_names ALTER COLUMN id SET DEFAULT nextval('medical_condition_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE medical_conditions ALTER COLUMN id SET DEFAULT nextval('medical_conditions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE medication_regimens ALTER COLUMN id SET DEFAULT nextval('medication_regimens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE medications ALTER COLUMN id SET DEFAULT nextval('medications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE native_american_tribes ALTER COLUMN id SET DEFAULT nextval('native_american_tribes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE neglect_quizzes ALTER COLUMN id SET DEFAULT nextval('neglect_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE notes ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE objective_activities ALTER COLUMN id SET DEFAULT nextval('case_plan_objective_activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE objective_activity_people ALTER COLUMN id SET DEFAULT nextval('case_plan_objective_activity_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE objectives ALTER COLUMN id SET DEFAULT nextval('case_plan_objectives_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE offered_services ALTER COLUMN id SET DEFAULT nextval('offered_services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE open_id_associations ALTER COLUMN id SET DEFAULT nextval('open_id_associations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE open_id_nonces ALTER COLUMN id SET DEFAULT nextval('open_id_nonces_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE open_id_requests ALTER COLUMN id SET DEFAULT nextval('open_id_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE organizations ALTER COLUMN id SET DEFAULT nextval('organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE parental_deprivation_checklists ALTER COLUMN id SET DEFAULT nextval('parental_deprivation_checklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE parental_deprivation_values ALTER COLUMN id SET DEFAULT nextval('parental_deprivation_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE people ALTER COLUMN id SET DEFAULT nextval('people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE pg_search_documents ALTER COLUMN id SET DEFAULT nextval('pg_search_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE phone_numbers ALTER COLUMN id SET DEFAULT nextval('phone_numbers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE physical_location_placements ALTER COLUMN id SET DEFAULT nextval('physical_location_placements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE physical_location_records ALTER COLUMN id SET DEFAULT nextval('physical_location_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE physical_location_runaways ALTER COLUMN id SET DEFAULT nextval('physical_location_runaways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE physical_location_temporary_absences ALTER COLUMN id SET DEFAULT nextval('physical_location_temporary_absences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE physical_location_trial_home_visits ALTER COLUMN id SET DEFAULT nextval('physical_location_trial_home_visits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE placed_people_safety_assessments ALTER COLUMN id SET DEFAULT nextval('placed_people_safety_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE placement_status_quizzes ALTER COLUMN id SET DEFAULT nextval('placement_status_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE plan_agreement_item_focus_children ALTER COLUMN id SET DEFAULT nextval('plan_agreement_item_focus_children_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE plan_agreement_item_monitors ALTER COLUMN id SET DEFAULT nextval('plan_agreement_item_monitors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE plan_agreement_items ALTER COLUMN id SET DEFAULT nextval('plan_agreement_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE potential_match_records ALTER COLUMN id SET DEFAULT nextval('potential_match_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE previous_passwords ALTER COLUMN id SET DEFAULT nextval('previous_passwords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE provision_question_answers ALTER COLUMN id SET DEFAULT nextval('ia_plan_person_provision_questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE provision_questions ALTER COLUMN id SET DEFAULT nextval('provision_questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE provisions ALTER COLUMN id SET DEFAULT nextval('provisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reassessment_quizzes ALTER COLUMN id SET DEFAULT nextval('reassessment_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE recovery_passwords ALTER COLUMN id SET DEFAULT nextval('recovery_passwords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE referral_objectives ALTER COLUMN id SET DEFAULT nextval('referral_objectives_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE referrals ALTER COLUMN id SET DEFAULT nextval('referrals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE relationship_types ALTER COLUMN id SET DEFAULT nextval('relationship_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE relationships ALTER COLUMN id SET DEFAULT nextval('relationships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE religions ALTER COLUMN id SET DEFAULT nextval('religions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE residencies ALTER COLUMN id SET DEFAULT nextval('residencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE residential_resource_types ALTER COLUMN id SET DEFAULT nextval('residential_resource_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE residential_resources ALTER COLUMN id SET DEFAULT nextval('residential_resources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE resources ALTER COLUMN id SET DEFAULT nextval('resources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE resque_job_to_retries ALTER COLUMN id SET DEFAULT nextval('resque_job_to_retries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE risk_assessment_decisions ALTER COLUMN id SET DEFAULT nextval('risk_assessment_decisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE risk_assessments ALTER COLUMN id SET DEFAULT nextval('risk_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE risk_factors ALTER COLUMN id SET DEFAULT nextval('risk_factors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE risk_reassessment_focus_children ALTER COLUMN id SET DEFAULT nextval('risk_reassessment_focus_children_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE risk_reassessments ALTER COLUMN id SET DEFAULT nextval('risk_reassessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE safety_assessments ALTER COLUMN id SET DEFAULT nextval('safety_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE safety_plan_agreement_contacts ALTER COLUMN id SET DEFAULT nextval('safety_plan_agreement_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE safety_plans ALTER COLUMN id SET DEFAULT nextval('safety_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE scheduled_visits ALTER COLUMN id SET DEFAULT nextval('scheduled_visits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE school_change_quizzes ALTER COLUMN id SET DEFAULT nextval('school_change_quizzes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE school_record_grade_levels ALTER COLUMN id SET DEFAULT nextval('school_record_grade_levels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE school_record_new_school_reasons ALTER COLUMN id SET DEFAULT nextval('school_record_reasons_for_new_school_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE school_records ALTER COLUMN id SET DEFAULT nextval('school_records_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE schools ALTER COLUMN id SET DEFAULT nextval('schools_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE service_categories ALTER COLUMN id SET DEFAULT nextval('service_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE service_category_types ALTER COLUMN id SET DEFAULT nextval('service_category_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE service_provider_types ALTER COLUMN id SET DEFAULT nextval('service_provider_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE service_providers ALTER COLUMN id SET DEFAULT nextval('service_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE services ALTER COLUMN id SET DEFAULT nextval('services_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE signatories ALTER COLUMN id SET DEFAULT nextval('signatories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sites ALTER COLUMN id SET DEFAULT nextval('sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE special_diet_names ALTER COLUMN id SET DEFAULT nextval('special_diet_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE special_diets ALTER COLUMN id SET DEFAULT nextval('special_diets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE special_needs_checklists ALTER COLUMN id SET DEFAULT nextval('special_needs_checklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE special_needs_values ALTER COLUMN id SET DEFAULT nextval('special_needs_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE staff_members ALTER COLUMN id SET DEFAULT nextval('staff_members_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE status_determination_events ALTER COLUMN id SET DEFAULT nextval('status_determination_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE team_meeting_facilitators ALTER COLUMN id SET DEFAULT nextval('team_meeting_facilitators_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE team_meeting_people ALTER COLUMN id SET DEFAULT nextval('team_meeting_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE team_meetings ALTER COLUMN id SET DEFAULT nextval('team_meetings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE validation_exceptions ALTER COLUMN id SET DEFAULT nextval('validation_exceptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE visitation_plan_people ALTER COLUMN id SET DEFAULT nextval('visitation_plan_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE visitation_plans ALTER COLUMN id SET DEFAULT nextval('visitation_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE waivers ALTER COLUMN id SET DEFAULT nextval('waivers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE workflow_events ALTER COLUMN id SET DEFAULT nextval('workflow_events_id_seq'::regclass);


--
-- Name: abuse_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY abuse_quizzes
    ADD CONSTRAINT abuse_quizzes_pkey PRIMARY KEY (id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: active_military_dependent_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_military_dependent_statuses
    ADD CONSTRAINT active_military_dependent_statuses_pkey PRIMARY KEY (id);


--
-- Name: active_military_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_military_statuses
    ADD CONSTRAINT active_military_statuses_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_style_guide_mock_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_style_guide_mock_people
    ADD CONSTRAINT admin_style_guide_mock_people_pkey PRIMARY KEY (id);


--
-- Name: admin_style_guide_object_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_style_guide_object_people
    ADD CONSTRAINT admin_style_guide_object_people_pkey PRIMARY KEY (id);


--
-- Name: admin_style_guide_object_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_style_guide_object_types
    ADD CONSTRAINT admin_style_guide_object_types_pkey PRIMARY KEY (id);


--
-- Name: admin_style_guide_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_style_guide_objects
    ADD CONSTRAINT admin_style_guide_objects_pkey PRIMARY KEY (id);


--
-- Name: adverse_reaction_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY adverse_reaction_names
    ADD CONSTRAINT adverse_reaction_names_pkey PRIMARY KEY (id);


--
-- Name: adverse_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY adverse_reactions
    ADD CONSTRAINT adverse_reactions_pkey PRIMARY KEY (id);


--
-- Name: aid_to_families_with_dependent_children_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY aid_to_families_with_dependent_children_limits
    ADD CONSTRAINT aid_to_families_with_dependent_children_limits_pkey PRIMARY KEY (id);


--
-- Name: allegation_maltreatment_subtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allegation_maltreatment_subtypes
    ADD CONSTRAINT allegation_maltreatment_subtypes_pkey PRIMARY KEY (id);


--
-- Name: allegations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allegations
    ADD CONSTRAINT allegations_pkey PRIMARY KEY (id);


--
-- Name: allergies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allergies
    ADD CONSTRAINT allergies_pkey PRIMARY KEY (id);


--
-- Name: allergy_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY allergy_names
    ADD CONSTRAINT allergy_names_pkey PRIMARY KEY (id);


--
-- Name: applicants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_pkey PRIMARY KEY (id);


--
-- Name: archived_allegations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_allegations
    ADD CONSTRAINT archived_allegations_pkey PRIMARY KEY (id);


--
-- Name: archived_assessment_legally_mandated_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_assessment_legally_mandated_reasons
    ADD CONSTRAINT archived_assessment_legally_mandated_reasons_pkey PRIMARY KEY (id);


--
-- Name: archived_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_assessments
    ADD CONSTRAINT archived_assessments_pkey PRIMARY KEY (id);


--
-- Name: archived_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_attachments
    ADD CONSTRAINT archived_attachments_pkey PRIMARY KEY (id);


--
-- Name: archived_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_notes
    ADD CONSTRAINT archived_notes_pkey PRIMARY KEY (id);


--
-- Name: archived_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY archived_relationships
    ADD CONSTRAINT archived_relationships_pkey PRIMARY KEY (id);


--
-- Name: assessed_people_safety_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assessed_people_safety_assessments
    ADD CONSTRAINT assessed_people_safety_assessments_pkey PRIMARY KEY (id);


--
-- Name: assessment_legally_mandated_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assessment_legally_mandated_reasons
    ADD CONSTRAINT assessment_legally_mandated_reasons_pkey PRIMARY KEY (id);


--
-- Name: assessment_report_source_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assessment_report_source_types
    ADD CONSTRAINT assessment_report_source_types_pkey PRIMARY KEY (id);


--
-- Name: assessment_response_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assessment_response_times
    ADD CONSTRAINT assessment_response_times_pkey PRIMARY KEY (id);


--
-- Name: assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: assistance_group_people_person_id_eligibility_id_eligibilit_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assistance_group_people
    ADD CONSTRAINT assistance_group_people_person_id_eligibility_id_eligibilit_key UNIQUE (person_id, eligibility_id, eligibility_type);


--
-- Name: assistance_group_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assistance_group_people
    ADD CONSTRAINT assistance_group_people_pkey PRIMARY KEY (id);


--
-- Name: attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: background_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY background_checks
    ADD CONSTRAINT background_checks_pkey PRIMARY KEY (id);


--
-- Name: cans_assessment_cans_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cans_assessment_cans_tools
    ADD CONSTRAINT cans_assessment_cans_tools_pkey PRIMARY KEY (id);


--
-- Name: cans_assessment_health_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cans_assessment_health_recommendations
    ADD CONSTRAINT cans_assessment_health_recommendations_pkey PRIMARY KEY (id);


--
-- Name: cans_assessment_placement_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cans_assessment_placement_recommendations
    ADD CONSTRAINT cans_assessment_placement_recommendations_pkey PRIMARY KEY (id);


--
-- Name: cans_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cans_assessments
    ADD CONSTRAINT cans_assessments_pkey PRIMARY KEY (id);


--
-- Name: caregiver_financial_risk_factor_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_financial_risk_factor_values
    ADD CONSTRAINT caregiver_financial_risk_factor_values_pkey PRIMARY KEY (id);


--
-- Name: caregiver_financial_risks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_financial_risks
    ADD CONSTRAINT caregiver_financial_risks_pkey PRIMARY KEY (id);


--
-- Name: caregiver_health_risk_factor_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_health_risk_factor_values
    ADD CONSTRAINT caregiver_health_risk_factor_values_pkey PRIMARY KEY (id);


--
-- Name: caregiver_health_risks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_health_risks
    ADD CONSTRAINT caregiver_health_risks_pkey PRIMARY KEY (id);


--
-- Name: caregiver_strengths_and_needs_assessment_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_strengths_and_needs_assessment_quizzes
    ADD CONSTRAINT caregiver_strengths_and_needs_assessment_quizzes_pkey PRIMARY KEY (id);


--
-- Name: caregiver_strengths_and_needs_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caregiver_strengths_and_needs_assessments
    ADD CONSTRAINT caregiver_strengths_and_needs_assessments_pkey PRIMARY KEY (id);


--
-- Name: case_focus_child_involvements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_focus_child_involvements
    ADD CONSTRAINT case_focus_child_involvements_pkey PRIMARY KEY (id);


--
-- Name: case_focus_children_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_focus_children
    ADD CONSTRAINT case_focus_children_pkey PRIMARY KEY (id);


--
-- Name: case_linked_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_linked_assessments
    ADD CONSTRAINT case_linked_assessments_pkey PRIMARY KEY (id);


--
-- Name: case_plan_caregivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_plan_caregivers
    ADD CONSTRAINT case_plan_caregivers_pkey PRIMARY KEY (id);


--
-- Name: case_plan_focus_child_planned_caregivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_plan_focus_child_planned_caregivers
    ADD CONSTRAINT case_plan_focus_child_planned_caregivers_pkey PRIMARY KEY (id);


--
-- Name: case_plan_focus_children_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_plan_focus_children
    ADD CONSTRAINT case_plan_focus_children_pkey PRIMARY KEY (id);


--
-- Name: case_plan_objective_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY objective_activities
    ADD CONSTRAINT case_plan_objective_activities_pkey PRIMARY KEY (id);


--
-- Name: case_plan_objective_activity_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY objective_activity_people
    ADD CONSTRAINT case_plan_objective_activity_people_pkey PRIMARY KEY (id);


--
-- Name: case_plan_objectives_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY objectives
    ADD CONSTRAINT case_plan_objectives_pkey PRIMARY KEY (id);


--
-- Name: case_plan_safety_plan_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_plan_safety_plan_links
    ADD CONSTRAINT case_plan_safety_plan_links_pkey PRIMARY KEY (id);


--
-- Name: case_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY case_plans
    ADD CONSTRAINT case_plans_pkey PRIMARY KEY (id);


--
-- Name: cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cases
    ADD CONSTRAINT cases_pkey PRIMARY KEY (id);


--
-- Name: checklist_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklist_answers
    ADD CONSTRAINT checklist_answers_pkey PRIMARY KEY (id);


--
-- Name: checklist_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklist_types
    ADD CONSTRAINT checklist_types_pkey PRIMARY KEY (id);


--
-- Name: checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklists
    ADD CONSTRAINT checklists_pkey PRIMARY KEY (id);


--
-- Name: child_risk_factor_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY child_risk_factor_values
    ADD CONSTRAINT child_risk_factor_values_pkey PRIMARY KEY (id);


--
-- Name: child_risks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY child_risks
    ADD CONSTRAINT child_risks_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notes
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: contact_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_people
    ADD CONSTRAINT contact_people_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: corrective_action_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY corrective_action_plans
    ADD CONSTRAINT corrective_action_plans_pkey PRIMARY KEY (id);


--
-- Name: counties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY counties
    ADD CONSTRAINT counties_pkey PRIMARY KEY (id);


--
-- Name: court_hearing_court_hearing_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_hearing_hearing_outcomes
    ADD CONSTRAINT court_hearing_court_hearing_outcomes_pkey PRIMARY KEY (id);


--
-- Name: court_hearing_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_hearing_outcomes
    ADD CONSTRAINT court_hearing_outcomes_pkey PRIMARY KEY (id);


--
-- Name: court_hearing_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_hearing_types
    ADD CONSTRAINT court_hearing_types_pkey PRIMARY KEY (id);


--
-- Name: court_hearings_court_language_citations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_hearings_court_language_citations
    ADD CONSTRAINT court_hearings_court_language_citations_pkey PRIMARY KEY (id);


--
-- Name: court_hearings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_hearings
    ADD CONSTRAINT court_hearings_pkey PRIMARY KEY (id);


--
-- Name: court_language_citations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY court_language_citations
    ADD CONSTRAINT court_language_citations_pkey PRIMARY KEY (id);


--
-- Name: custom_provisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY custom_provision_with_questions
    ADD CONSTRAINT custom_provisions_pkey PRIMARY KEY (id);


--
-- Name: data_broker_event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_broker_event_logs
    ADD CONSTRAINT data_broker_event_logs_pkey PRIMARY KEY (id);


--
-- Name: data_broker_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY data_broker_traffic_logs
    ADD CONSTRAINT data_broker_logs_pkey PRIMARY KEY (id);


--
-- Name: deprivation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deprivation_types
    ADD CONSTRAINT deprivation_types_pkey PRIMARY KEY (id);


--
-- Name: discretionary_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY discretionary_overrides
    ADD CONSTRAINT discretionary_overrides_pkey PRIMARY KEY (id);


--
-- Name: educational_overview_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY educational_overview_quizzes
    ADD CONSTRAINT educational_overview_quizzes_pkey PRIMARY KEY (id);


--
-- Name: eligibility_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY eligibility_applications
    ADD CONSTRAINT eligibility_applications_pkey PRIMARY KEY (id);


--
-- Name: email_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_notes
    ADD CONSTRAINT email_notes_pkey PRIMARY KEY (id);


--
-- Name: emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: emergency_assistance_eligibilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emergency_assistance_eligibilities
    ADD CONSTRAINT emergency_assistance_eligibilities_pkey PRIMARY KEY (id);


--
-- Name: employment_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY employment_records
    ADD CONSTRAINT employment_records_pkey PRIMARY KEY (id);


--
-- Name: external_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_roles
    ADD CONSTRAINT external_roles_pkey PRIMARY KEY (id);


--
-- Name: federal_poverty_income_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY federal_poverty_income_limits
    ADD CONSTRAINT federal_poverty_income_limits_pkey PRIMARY KEY (id);


--
-- Name: foster_families_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY foster_families
    ADD CONSTRAINT foster_families_pkey PRIMARY KEY (id);


--
-- Name: foster_family_other_household_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY foster_family_other_household_members
    ADD CONSTRAINT foster_family_other_household_members_pkey PRIMARY KEY (id);


--
-- Name: health_care_provider_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY health_care_provider_names
    ADD CONSTRAINT health_care_provider_names_pkey PRIMARY KEY (id);


--
-- Name: health_care_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY health_care_providers
    ADD CONSTRAINT health_care_providers_pkey PRIMARY KEY (id);


--
-- Name: health_exam_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY health_exam_names
    ADD CONSTRAINT health_exam_names_pkey PRIMARY KEY (id);


--
-- Name: health_exams_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY health_exams
    ADD CONSTRAINT health_exams_pkey PRIMARY KEY (id);


--
-- Name: historical_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY historical_records
    ADD CONSTRAINT historical_records_pkey PRIMARY KEY (id);


--
-- Name: ia_court_consent_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_court_consent_people
    ADD CONSTRAINT ia_court_consent_people_pkey PRIMARY KEY (id);


--
-- Name: ia_hearing_waiver_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_hearing_waiver_people
    ADD CONSTRAINT ia_hearing_waiver_people_pkey PRIMARY KEY (id);


--
-- Name: ia_plan_child_supervisors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_plan_child_supervisors
    ADD CONSTRAINT ia_plan_child_supervisors_pkey PRIMARY KEY (id);


--
-- Name: ia_plan_contact_and_visitation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_plan_contact_and_visitation_types
    ADD CONSTRAINT ia_plan_contact_and_visitation_types_pkey PRIMARY KEY (id);


--
-- Name: ia_plan_person_provision_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY provision_question_answers
    ADD CONSTRAINT ia_plan_person_provision_questions_pkey PRIMARY KEY (id);


--
-- Name: ia_plan_provisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_plan_provisions
    ADD CONSTRAINT ia_plan_provisions_pkey PRIMARY KEY (id);


--
-- Name: ia_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_plans
    ADD CONSTRAINT ia_plans_pkey PRIMARY KEY (id);


--
-- Name: ia_progress_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ia_progress_reports
    ADD CONSTRAINT ia_progress_reports_pkey PRIMARY KEY (id);


--
-- Name: identification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identification_types
    ADD CONSTRAINT identification_types_pkey PRIMARY KEY (id);


--
-- Name: identifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_pkey PRIMARY KEY (id);


--
-- Name: immunization_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY immunization_names
    ADD CONSTRAINT immunization_names_pkey PRIMARY KEY (id);


--
-- Name: immunizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY immunizations
    ADD CONSTRAINT immunizations_pkey PRIMARY KEY (id);


--
-- Name: income_record_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY income_record_types
    ADD CONSTRAINT income_record_types_pkey PRIMARY KEY (id);


--
-- Name: income_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY income_records
    ADD CONSTRAINT income_records_pkey PRIMARY KEY (id);


--
-- Name: insurance_provider_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY insurance_provider_names
    ADD CONSTRAINT insurance_provider_names_pkey PRIMARY KEY (id);


--
-- Name: insurance_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY insurance_providers
    ADD CONSTRAINT insurance_providers_pkey PRIMARY KEY (id);


--
-- Name: intake_allegations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY intake_allegations
    ADD CONSTRAINT intake_allegations_pkey PRIMARY KEY (id);


--
-- Name: intake_legally_mandated_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY intake_legally_mandated_reasons
    ADD CONSTRAINT intake_legally_mandated_reasons_pkey PRIMARY KEY (id);


--
-- Name: intake_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY intake_people
    ADD CONSTRAINT intake_people_pkey PRIMARY KEY (id);


--
-- Name: intakes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY intakes
    ADD CONSTRAINT intakes_pkey PRIMARY KEY (id);


--
-- Name: involvement_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY involvement_types
    ADD CONSTRAINT involvement_types_pkey PRIMARY KEY (id);


--
-- Name: iv_e_eligibilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY iv_e_eligibilities
    ADD CONSTRAINT iv_e_eligibilities_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: legally_mandated_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY legally_mandated_reasons
    ADD CONSTRAINT legally_mandated_reasons_pkey PRIMARY KEY (id);


--
-- Name: licenses_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY licenses
    ADD CONSTRAINT licenses_pkey1 PRIMARY KEY (id);


--
-- Name: living_arrangements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY living_arrangements
    ADD CONSTRAINT living_arrangements_pkey PRIMARY KEY (id);


--
-- Name: medical_condition_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medical_condition_names
    ADD CONSTRAINT medical_condition_names_pkey PRIMARY KEY (id);


--
-- Name: medical_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medical_conditions
    ADD CONSTRAINT medical_conditions_pkey PRIMARY KEY (id);


--
-- Name: medications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medication_regimens
    ADD CONSTRAINT medications_pkey PRIMARY KEY (id);


--
-- Name: medications_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY medications
    ADD CONSTRAINT medications_pkey1 PRIMARY KEY (id);


--
-- Name: native_american_tribes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY native_american_tribes
    ADD CONSTRAINT native_american_tribes_pkey PRIMARY KEY (id);


--
-- Name: neglect_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY neglect_quizzes
    ADD CONSTRAINT neglect_quizzes_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: offered_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY offered_services
    ADD CONSTRAINT offered_services_pkey PRIMARY KEY (id);


--
-- Name: open_id_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY open_id_associations
    ADD CONSTRAINT open_id_associations_pkey PRIMARY KEY (id);


--
-- Name: open_id_nonces_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY open_id_nonces
    ADD CONSTRAINT open_id_nonces_pkey PRIMARY KEY (id);


--
-- Name: open_id_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY open_id_requests
    ADD CONSTRAINT open_id_requests_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: parental_deprivation_checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parental_deprivation_checklists
    ADD CONSTRAINT parental_deprivation_checklists_pkey PRIMARY KEY (id);


--
-- Name: parental_deprivation_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parental_deprivation_values
    ADD CONSTRAINT parental_deprivation_values_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY phone_numbers
    ADD CONSTRAINT phone_numbers_pkey PRIMARY KEY (id);


--
-- Name: physical_location_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY physical_location_placements
    ADD CONSTRAINT physical_location_placements_pkey PRIMARY KEY (id);


--
-- Name: physical_location_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY physical_location_records
    ADD CONSTRAINT physical_location_records_pkey PRIMARY KEY (id);


--
-- Name: physical_location_runaways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY physical_location_runaways
    ADD CONSTRAINT physical_location_runaways_pkey PRIMARY KEY (id);


--
-- Name: physical_location_temporary_absences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY physical_location_temporary_absences
    ADD CONSTRAINT physical_location_temporary_absences_pkey PRIMARY KEY (id);


--
-- Name: physical_location_trial_home_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY physical_location_trial_home_visits
    ADD CONSTRAINT physical_location_trial_home_visits_pkey PRIMARY KEY (id);


--
-- Name: placed_people_safety_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY placed_people_safety_assessments
    ADD CONSTRAINT placed_people_safety_assessments_pkey PRIMARY KEY (id);


--
-- Name: placement_status_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY placement_status_quizzes
    ADD CONSTRAINT placement_status_quizzes_pkey PRIMARY KEY (id);


--
-- Name: plan_agreement_item_focus_children_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plan_agreement_item_focus_children
    ADD CONSTRAINT plan_agreement_item_focus_children_pkey PRIMARY KEY (id);


--
-- Name: plan_agreement_item_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plan_agreement_item_monitors
    ADD CONSTRAINT plan_agreement_item_monitors_pkey PRIMARY KEY (id);


--
-- Name: plan_agreement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plan_agreement_items
    ADD CONSTRAINT plan_agreement_items_pkey PRIMARY KEY (id);


--
-- Name: potential_match_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY potential_match_records
    ADD CONSTRAINT potential_match_records_pkey PRIMARY KEY (id);


--
-- Name: previous_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY previous_passwords
    ADD CONSTRAINT previous_passwords_pkey PRIMARY KEY (id);


--
-- Name: provision_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY provision_questions
    ADD CONSTRAINT provision_questions_pkey PRIMARY KEY (id);


--
-- Name: provisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY provisions
    ADD CONSTRAINT provisions_pkey PRIMARY KEY (id);


--
-- Name: reassessment_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reassessment_quizzes
    ADD CONSTRAINT reassessment_quizzes_pkey PRIMARY KEY (id);


--
-- Name: recovery_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY recovery_passwords
    ADD CONSTRAINT recovery_passwords_pkey PRIMARY KEY (id);


--
-- Name: referral_objectives_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY referral_objectives
    ADD CONSTRAINT referral_objectives_pkey PRIMARY KEY (id);


--
-- Name: referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: relationship_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relationship_types
    ADD CONSTRAINT relationship_types_pkey PRIMARY KEY (id);


--
-- Name: relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: religions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY religions
    ADD CONSTRAINT religions_pkey PRIMARY KEY (id);


--
-- Name: residencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY residencies
    ADD CONSTRAINT residencies_pkey PRIMARY KEY (id);


--
-- Name: residential_resource_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY residential_resource_types
    ADD CONSTRAINT residential_resource_types_pkey PRIMARY KEY (id);


--
-- Name: residential_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY residential_resources
    ADD CONSTRAINT residential_resources_pkey PRIMARY KEY (id);


--
-- Name: resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: resque_job_to_retries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY resque_job_to_retries
    ADD CONSTRAINT resque_job_to_retries_pkey PRIMARY KEY (id);


--
-- Name: risk_assessment_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY risk_assessment_decisions
    ADD CONSTRAINT risk_assessment_decisions_pkey PRIMARY KEY (id);


--
-- Name: risk_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY risk_assessments
    ADD CONSTRAINT risk_assessments_pkey PRIMARY KEY (id);


--
-- Name: risk_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY risk_factors
    ADD CONSTRAINT risk_factors_pkey PRIMARY KEY (id);


--
-- Name: risk_reassessment_focus_children_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY risk_reassessment_focus_children
    ADD CONSTRAINT risk_reassessment_focus_children_pkey PRIMARY KEY (id);


--
-- Name: risk_reassessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY risk_reassessments
    ADD CONSTRAINT risk_reassessments_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: safety_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY safety_assessments
    ADD CONSTRAINT safety_assessments_pkey PRIMARY KEY (id);


--
-- Name: safety_plan_agreement_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY safety_plan_agreement_contacts
    ADD CONSTRAINT safety_plan_agreement_contacts_pkey PRIMARY KEY (id);


--
-- Name: safety_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY safety_plans
    ADD CONSTRAINT safety_plans_pkey PRIMARY KEY (id);


--
-- Name: scheduled_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scheduled_visits
    ADD CONSTRAINT scheduled_visits_pkey PRIMARY KEY (id);


--
-- Name: school_change_quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY school_change_quizzes
    ADD CONSTRAINT school_change_quizzes_pkey PRIMARY KEY (id);


--
-- Name: school_record_grade_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY school_record_grade_levels
    ADD CONSTRAINT school_record_grade_levels_pkey PRIMARY KEY (id);


--
-- Name: school_record_reasons_for_new_school_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY school_record_new_school_reasons
    ADD CONSTRAINT school_record_reasons_for_new_school_pkey PRIMARY KEY (id);


--
-- Name: school_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY school_records
    ADD CONSTRAINT school_records_pkey PRIMARY KEY (id);


--
-- Name: schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_categories
    ADD CONSTRAINT service_categories_pkey PRIMARY KEY (id);


--
-- Name: service_category_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_category_types
    ADD CONSTRAINT service_category_types_pkey PRIMARY KEY (id);


--
-- Name: service_provider_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_provider_types
    ADD CONSTRAINT service_provider_types_pkey PRIMARY KEY (id);


--
-- Name: service_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY service_providers
    ADD CONSTRAINT service_providers_pkey PRIMARY KEY (id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: signatories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY signatories
    ADD CONSTRAINT signatories_pkey PRIMARY KEY (id);


--
-- Name: sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: special_diet_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY special_diet_names
    ADD CONSTRAINT special_diet_names_pkey PRIMARY KEY (id);


--
-- Name: special_diets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY special_diets
    ADD CONSTRAINT special_diets_pkey PRIMARY KEY (id);


--
-- Name: special_needs_checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY special_needs_checklists
    ADD CONSTRAINT special_needs_checklists_pkey PRIMARY KEY (id);


--
-- Name: special_needs_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY special_needs_values
    ADD CONSTRAINT special_needs_values_pkey PRIMARY KEY (id);


--
-- Name: staff_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY staff_members
    ADD CONSTRAINT staff_members_pkey PRIMARY KEY (id);


--
-- Name: status_determination_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY status_determination_events
    ADD CONSTRAINT status_determination_events_pkey PRIMARY KEY (id);


--
-- Name: team_meeting_facilitators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY team_meeting_facilitators
    ADD CONSTRAINT team_meeting_facilitators_pkey PRIMARY KEY (id);


--
-- Name: team_meeting_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY team_meeting_people
    ADD CONSTRAINT team_meeting_people_pkey PRIMARY KEY (id);


--
-- Name: team_meetings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY team_meetings
    ADD CONSTRAINT team_meetings_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: validation_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY validation_exceptions
    ADD CONSTRAINT validation_exceptions_pkey PRIMARY KEY (id);


--
-- Name: visitation_plan_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visitation_plan_people
    ADD CONSTRAINT visitation_plan_people_pkey PRIMARY KEY (id);


--
-- Name: visitation_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY visitation_plans
    ADD CONSTRAINT visitation_plans_pkey PRIMARY KEY (id);


--
-- Name: waivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY waivers
    ADD CONSTRAINT waivers_pkey PRIMARY KEY (id);


--
-- Name: workflow_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflow_events
    ADD CONSTRAINT workflow_events_pkey PRIMARY KEY (id);


--
-- Name: activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX activity_id ON objective_activity_people USING btree (objective_activity_id);


--
-- Name: apsa; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX apsa ON assessed_people_safety_assessments USING btree (person_id, safety_assessment_id);


--
-- Name: assessments_search_tsearch; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX assessments_search_tsearch ON assessments USING gist (((to_tsvector('simple'::regconfig, (COALESCE(name, ''::character varying))::text) || to_tsvector('simple'::regconfig, COALESCE(allegation_narrative, ''::text)))));


--
-- Name: case_focus_child_involvements_case_focus_child_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX case_focus_child_involvements_case_focus_child_id ON case_focus_child_involvements USING btree (case_focus_child_id);


--
-- Name: case_focus_children_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX case_focus_children_person_id ON case_focus_children USING btree (person_id);


--
-- Name: index_active_military_dependent_statuses_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_military_dependent_statuses_on_assessment_id ON active_military_dependent_statuses USING btree (assessment_id);


--
-- Name: index_active_military_dependent_statuses_person_and_assessment; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_military_dependent_statuses_person_and_assessment ON active_military_dependent_statuses USING btree (person_id, assessment_id);


--
-- Name: index_addresses_on_formatted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_formatted ON addresses USING btree (formatted);


--
-- Name: index_addresses_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_addresses_on_legacy_id ON addresses USING btree (legacy_id);


--
-- Name: index_adverse_reaction_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_adverse_reaction_names_on_name ON adverse_reaction_names USING btree (name);


--
-- Name: index_adverse_reactions_on_adverse_reaction_name_id_and_person_; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_adverse_reactions_on_adverse_reaction_name_id_and_person_ ON adverse_reactions USING btree (adverse_reaction_name_id, person_id);


--
-- Name: index_adverse_reactions_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_adverse_reactions_on_legacy_id ON adverse_reactions USING btree (legacy_id);


--
-- Name: index_allegation_maltreatment_subtypes_on_allegation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_allegation_maltreatment_subtypes_on_allegation_id ON allegation_maltreatment_subtypes USING btree (allegation_id);


--
-- Name: index_allegations_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_allegations_on_assessment_id ON allegations USING btree (assessment_id);


--
-- Name: index_allegations_on_perpetrator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_allegations_on_perpetrator_id ON allegations USING btree (perpetrator_id);


--
-- Name: index_allegations_on_victim_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_allegations_on_victim_id ON allegations USING btree (victim_id);


--
-- Name: index_allergies_on_allergy_name_id_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_allergies_on_allergy_name_id_and_person_id ON allergies USING btree (allergy_name_id, person_id);


--
-- Name: index_allergies_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_allergies_on_legacy_id ON allergies USING btree (legacy_id);


--
-- Name: index_allergy_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_allergy_names_on_name ON allergy_names USING btree (name);


--
-- Name: index_assessment_legally_mandated_reasons_on_legally_mandated_r; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assessment_legally_mandated_reasons_on_legally_mandated_r ON assessment_legally_mandated_reasons USING btree (legally_mandated_reason_id, assessment_id);


--
-- Name: index_assessments_on_assignee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assessments_on_assignee_id ON assessments USING btree (assignee_id);


--
-- Name: index_assessments_on_county_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assessments_on_county_id ON assessments USING btree (county_id);


--
-- Name: index_assessments_on_intake_worker_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assessments_on_intake_worker_id ON assessments USING btree (intake_worker_id);


--
-- Name: index_assessments_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assessments_on_legacy_id ON assessments USING btree (legacy_id);


--
-- Name: index_assessments_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assessments_on_state ON assessments USING btree (state);


--
-- Name: index_cans_assessments_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_cans_assessments_on_legacy_id ON cans_assessments USING btree (legacy_id);


--
-- Name: index_caregiver_financial_risk_factor_values_on_risk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_financial_risk_factor_values_on_risk ON caregiver_financial_risk_factor_values USING btree (caregiver_financial_risk_factor_id);


--
-- Name: index_caregiver_financial_risk_factor_values_on_risk_and_factor; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_financial_risk_factor_values_on_risk_and_factor ON caregiver_financial_risk_factor_values USING btree (caregiver_financial_risk_id, caregiver_financial_risk_factor_id);


--
-- Name: index_caregiver_financial_risks_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_financial_risks_on_assessment_id ON caregiver_financial_risks USING btree (assessment_id);


--
-- Name: index_caregiver_financial_risks_on_person_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_financial_risks_on_person_id_and_assessment_id ON caregiver_financial_risks USING btree (person_id, assessment_id);


--
-- Name: index_caregiver_health_risk_factor_values_on_risk; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_health_risk_factor_values_on_risk ON caregiver_health_risk_factor_values USING btree (caregiver_health_risk_factor_id);


--
-- Name: index_caregiver_health_risk_factor_values_on_risk_and_factor; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_health_risk_factor_values_on_risk_and_factor ON caregiver_health_risk_factor_values USING btree (caregiver_health_risk_id, caregiver_health_risk_factor_id);


--
-- Name: index_caregiver_health_risks_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_health_risks_on_assessment_id ON caregiver_health_risks USING btree (assessment_id);


--
-- Name: index_caregiver_health_risks_on_person_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_caregiver_health_risks_on_person_id_and_assessment_id ON caregiver_health_risks USING btree (person_id, assessment_id);


--
-- Name: index_case_focus_children_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_case_focus_children_on_legacy_id ON case_focus_children USING btree (legacy_id);


--
-- Name: index_case_plan_caregivers_on_person_id_and_case_plan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_case_plan_caregivers_on_person_id_and_case_plan_id ON case_plan_caregivers USING btree (person_id, case_plan_id);


--
-- Name: index_case_plan_focus_children_on_person_id_and_case_plan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_case_plan_focus_children_on_person_id_and_case_plan_id ON case_plan_focus_children USING btree (person_id, case_plan_id);


--
-- Name: index_case_plan_objective_activities_on_case_plan_objective_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_case_plan_objective_activities_on_case_plan_objective_id ON objective_activities USING btree (objective_id);


--
-- Name: index_case_plan_objectives_on_case_plan_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_case_plan_objectives_on_case_plan_id ON objectives USING btree (initiative_id);


--
-- Name: index_case_plan_safety_plan_links_on_safety_plan_id_and_case_pl; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_case_plan_safety_plan_links_on_safety_plan_id_and_case_pl ON case_plan_safety_plan_links USING btree (safety_plan_id, case_plan_id);


--
-- Name: index_case_plans_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_case_plans_on_legacy_id ON case_plans USING btree (legacy_id);


--
-- Name: index_cases_on_assignee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cases_on_assignee_id ON cases USING btree (assignee_id);


--
-- Name: index_cases_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_cases_on_legacy_id ON cases USING btree (legacy_id);


--
-- Name: index_child_risk_factor_values_on_child_risk_factor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_child_risk_factor_values_on_child_risk_factor_id ON child_risk_factor_values USING btree (child_risk_factor_id);


--
-- Name: index_child_risk_factor_values_on_risk_and_factor; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_child_risk_factor_values_on_risk_and_factor ON child_risk_factor_values USING btree (child_risk_id, child_risk_factor_id);


--
-- Name: index_child_risks_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_child_risks_on_assessment_id ON child_risks USING btree (assessment_id);


--
-- Name: index_child_risks_on_person_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_child_risks_on_person_id_and_assessment_id ON child_risks USING btree (person_id, assessment_id);


--
-- Name: index_client_referrals_on_person_id_and_referral_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_client_referrals_on_person_id_and_referral_id ON client_referrals USING btree (person_id, referral_id);


--
-- Name: index_comments_on_unit_of_work_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_unit_of_work_id ON notes USING btree (unit_of_work_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_user_id ON notes USING btree (user_id);


--
-- Name: index_contact_people_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_people_on_contact_id ON contact_people USING btree (contact_id);


--
-- Name: index_contact_people_on_person_id_and_present; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contact_people_on_person_id_and_present ON contact_people USING btree (person_id, present);


--
-- Name: index_contacts_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_contacts_on_legacy_id ON contacts USING btree (legacy_id);


--
-- Name: index_contacts_on_mode; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contacts_on_mode ON contacts USING btree (mode);


--
-- Name: index_contacts_on_note_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_contacts_on_note_id ON contacts USING btree (note_id);


--
-- Name: index_court_hearings_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_court_hearings_on_legacy_id ON court_hearings USING btree (legacy_id);


--
-- Name: index_eligibility_applications_on_focus_child_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_eligibility_applications_on_focus_child_id ON eligibility_applications USING btree (focus_child_id);


--
-- Name: index_eligibility_applications_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_eligibility_applications_on_legacy_id ON eligibility_applications USING btree (legacy_id);


--
-- Name: index_email_notes_on_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_email_notes_on_email_id ON email_notes USING btree (email_id);


--
-- Name: index_email_notes_on_note_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_email_notes_on_note_id ON email_notes USING btree (note_id);


--
-- Name: index_emergency_assistance_eligibilities_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_emergency_assistance_eligibilities_on_legacy_id ON emergency_assistance_eligibilities USING btree (legacy_id);


--
-- Name: index_employment_records_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_employment_records_on_legacy_id ON employment_records USING btree (legacy_id);


--
-- Name: index_federal_poverty_income_limit_year_member_count; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_federal_poverty_income_limit_year_member_count ON federal_poverty_income_limits USING btree (year, household_member_count);


--
-- Name: index_health_care_provider_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_health_care_provider_names_on_name ON health_care_provider_names USING btree (name);


--
-- Name: index_health_care_providers_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_health_care_providers_on_legacy_id ON health_care_providers USING btree (legacy_id);


--
-- Name: index_health_exam_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_health_exam_names_on_name ON health_exam_names USING btree (name);


--
-- Name: index_health_exams_on_health_exam_name_id_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_health_exams_on_health_exam_name_id_and_person_id ON health_exams USING btree (health_exam_name_id, person_id);


--
-- Name: index_health_exams_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_health_exams_on_legacy_id ON health_exams USING btree (legacy_id);


--
-- Name: index_historical_records_on_event_target_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_historical_records_on_event_target_type ON historical_records USING btree (event_target_type);


--
-- Name: index_ia_plans_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_ia_plans_on_legacy_id ON ia_plans USING btree (legacy_id);


--
-- Name: index_ia_progress_reports_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_ia_progress_reports_on_legacy_id ON ia_progress_reports USING btree (legacy_id);


--
-- Name: index_immunization_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_immunization_names_on_name ON immunization_names USING btree (name);


--
-- Name: index_immunizations_on_immunization_name_id_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_immunizations_on_immunization_name_id_and_person_id ON immunizations USING btree (immunization_name_id, person_id);


--
-- Name: index_immunizations_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_immunizations_on_legacy_id ON immunizations USING btree (legacy_id);


--
-- Name: index_income_records_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_income_records_on_legacy_id ON income_records USING btree (legacy_id);


--
-- Name: index_insurance_provider_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_insurance_provider_names_on_name ON insurance_provider_names USING btree (name);


--
-- Name: index_insurance_providers_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_insurance_providers_on_legacy_id ON insurance_providers USING btree (legacy_id);


--
-- Name: index_intakes_on_incident_address_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_intakes_on_incident_address_id ON intakes USING btree (incident_address_id);


--
-- Name: index_iv_e_eligibilities_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_iv_e_eligibilities_on_legacy_id ON iv_e_eligibilities USING btree (legacy_id);


--
-- Name: index_living_arrangements_on_assessment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_living_arrangements_on_assessment_id ON living_arrangements USING btree (assessment_id);


--
-- Name: index_living_arrangements_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_living_arrangements_on_person_id ON living_arrangements USING btree (person_id);


--
-- Name: index_medical_condition_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_medical_condition_names_on_name ON medical_condition_names USING btree (name);


--
-- Name: index_medical_conditions_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_medical_conditions_on_legacy_id ON medical_conditions USING btree (legacy_id);


--
-- Name: index_medication_regimens_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_medication_regimens_on_legacy_id ON medication_regimens USING btree (legacy_id);


--
-- Name: index_medications_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_medications_on_legacy_id ON medication_regimens USING btree (legacy_id);


--
-- Name: index_medications_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_medications_on_name ON medications USING btree (name);


--
-- Name: index_notes_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_notes_on_legacy_id ON notes USING btree (legacy_id);


--
-- Name: index_notes_on_unit_of_work_id_and_unit_of_work_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_notes_on_unit_of_work_id_and_unit_of_work_type ON notes USING btree (unit_of_work_id, unit_of_work_type);


--
-- Name: index_open_id_requests_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_open_id_requests_on_token ON open_id_requests USING btree (token);


--
-- Name: index_people_on_date_of_birth_and_last_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_people_on_date_of_birth_and_last_name ON people USING btree (date_of_birth, lower((last_name)::text));


--
-- Name: index_people_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_people_on_legacy_id ON people USING btree (legacy_id);


--
-- Name: index_people_on_native_american_tribe_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_people_on_native_american_tribe_id ON people USING btree (native_american_tribe_id);


--
-- Name: index_people_on_religion_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_people_on_religion_id ON people USING btree (religion_id);


--
-- Name: index_people_on_ssn; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_people_on_ssn ON people USING btree (ssn);


--
-- Name: index_phone_numbers_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_phone_numbers_on_legacy_id ON phone_numbers USING btree (legacy_id);


--
-- Name: index_physical_location_placements_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_physical_location_placements_on_legacy_id ON physical_location_placements USING btree (legacy_id);


--
-- Name: index_physical_location_runaways_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_physical_location_runaways_on_legacy_id ON physical_location_runaways USING btree (legacy_id);


--
-- Name: index_physical_location_temporary_absences_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_physical_location_temporary_absences_on_legacy_id ON physical_location_temporary_absences USING btree (legacy_id);


--
-- Name: index_physical_location_trial_home_visits_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_physical_location_trial_home_visits_on_legacy_id ON physical_location_trial_home_visits USING btree (legacy_id);


--
-- Name: index_previous_passwords_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_previous_passwords_on_user_id ON previous_passwords USING btree (user_id);


--
-- Name: index_referrals_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_referrals_on_legacy_id ON referrals USING btree (legacy_id);


--
-- Name: index_relationship_types_on_strong_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_relationship_types_on_strong_name ON relationship_types USING btree (strong_name);


--
-- Name: index_relationship_types_on_weak_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_relationship_types_on_weak_name ON relationship_types USING btree (weak_name);


--
-- Name: index_relationships_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_relationships_on_legacy_id ON relationships USING btree (legacy_id);


--
-- Name: index_relationships_on_strong_side_and_weak_side; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_relationships_on_strong_side_and_weak_side ON relationships USING btree (strong_side_person_id, weak_side_person_id);


--
-- Name: index_relationships_on_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_relationships_on_type_id ON relationships USING btree (type_id);


--
-- Name: index_relationships_on_weak_side_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_relationships_on_weak_side_person_id ON relationships USING btree (weak_side_person_id);


--
-- Name: index_residencies_on_address_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_residencies_on_address_id ON residencies USING btree (address_id);


--
-- Name: index_residencies_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_residencies_on_legacy_id ON residencies USING btree (legacy_id);


--
-- Name: index_resources_on_address_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_resources_on_address_id ON resources USING btree (address_id);


--
-- Name: index_resources_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_resources_on_legacy_id ON resources USING btree (legacy_id);


--
-- Name: index_roles_users_on_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_users_on_role_id ON roles_users USING btree (role_id);


--
-- Name: index_roles_users_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_users_on_user_id_and_role_id ON roles_users USING btree (user_id, role_id);


--
-- Name: index_school_records_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_school_records_on_legacy_id ON school_records USING btree (legacy_id);


--
-- Name: index_schools_on_name_and_address; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_schools_on_name_and_address ON schools USING btree (name, address);


--
-- Name: index_service_categories_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_service_categories_on_legacy_id ON service_categories USING btree (legacy_id);


--
-- Name: index_sites_on_account_id_and_url; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_sites_on_account_id_and_url ON sites USING btree (account_id, url);


--
-- Name: index_sites_on_url_and_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_sites_on_url_and_account_id ON sites USING btree (url, account_id);


--
-- Name: index_special_diet_names_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_special_diet_names_on_name ON special_diet_names USING btree (name);


--
-- Name: index_special_diets_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_special_diets_on_legacy_id ON special_diets USING btree (legacy_id);


--
-- Name: index_special_diets_on_special_diet_name_id_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_special_diets_on_special_diet_name_id_and_person_id ON special_diets USING btree (special_diet_name_id, person_id);


--
-- Name: index_team_meetings_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_team_meetings_on_legacy_id ON team_meetings USING btree (legacy_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_legacy_id ON users USING btree (legacy_id);


--
-- Name: index_users_on_manager_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_manager_id ON users USING btree (manager_id);


--
-- Name: index_users_on_password_changed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_password_changed_at ON users USING btree (password_changed_at);


--
-- Name: index_users_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_person_id ON users USING btree (person_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: index_validation_exceptions_on_validation_item; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_validation_exceptions_on_validation_item ON validation_exceptions USING btree (validation_item_id, validation_item_type);


--
-- Name: index_visitation_plans_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_visitation_plans_on_legacy_id ON visitation_plans USING btree (legacy_id);


--
-- Name: index_workflow_events_on_legacy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_workflow_events_on_legacy_id ON workflow_events USING btree (legacy_id);


--
-- Name: people_dmetaphone; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX people_dmetaphone ON people USING gist (((to_tsvector('simple'::regconfig, pg_search_dmetaphone(unaccent((COALESCE(first_name, ''::character varying))::text))) || to_tsvector('simple'::regconfig, pg_search_dmetaphone(unaccent((COALESCE(last_name, ''::character varying))::text))))));


--
-- Name: people_search_by_name_trigram; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX people_search_by_name_trigram ON people USING gist (unaccent((((COALESCE(first_name, ''::character varying))::text || ' '::text) || (COALESCE(last_name, ''::character varying))::text)) gist_trgm_ops);


--
-- Name: people_search_by_name_tsearch; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX people_search_by_name_tsearch ON people USING gist (((to_tsvector('simple'::regconfig, unaccent((COALESCE(first_name, ''::character varying))::text)) || to_tsvector('simple'::regconfig, unaccent((COALESCE(last_name, ''::character varying))::text)))));


--
-- Name: pg_search_documents_dmetaphone; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pg_search_documents_dmetaphone ON pg_search_documents USING gist (to_tsvector('simple'::regconfig, pg_search_dmetaphone(unaccent(COALESCE(content, ''::text)))));


--
-- Name: pg_search_documents_trigram; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pg_search_documents_trigram ON pg_search_documents USING gist (unaccent(COALESCE(content, ''::text)) gist_trgm_ops);


--
-- Name: pg_search_documents_tsearch; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pg_search_documents_tsearch ON pg_search_documents USING gist (to_tsvector('simple'::regconfig, unaccent(COALESCE(content, ''::text))));


--
-- Name: phone_numbers_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX phone_numbers_person_id ON phone_numbers USING btree (person_id);


--
-- Name: residencies_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX residencies_person_id ON residencies USING btree (person_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: audit_abuse_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_abuse_quizzes AFTER INSERT OR DELETE OR UPDATE ON abuse_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_accounts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_accounts AFTER INSERT OR DELETE OR UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_active_military_dependent_statuses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_active_military_dependent_statuses AFTER INSERT OR DELETE OR UPDATE ON active_military_dependent_statuses FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_active_military_statuses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_active_military_statuses AFTER INSERT OR DELETE OR UPDATE ON active_military_statuses FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_addresses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_addresses AFTER INSERT OR DELETE OR UPDATE ON addresses FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_admin_style_guide_mock_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_admin_style_guide_mock_people AFTER INSERT OR DELETE OR UPDATE ON admin_style_guide_mock_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_admin_style_guide_object_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_admin_style_guide_object_people AFTER INSERT OR DELETE OR UPDATE ON admin_style_guide_object_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_admin_style_guide_object_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_admin_style_guide_object_types AFTER INSERT OR DELETE OR UPDATE ON admin_style_guide_object_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_admin_style_guide_objects; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_admin_style_guide_objects AFTER INSERT OR DELETE OR UPDATE ON admin_style_guide_objects FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_adverse_reaction_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_adverse_reaction_names AFTER INSERT OR DELETE OR UPDATE ON adverse_reaction_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_adverse_reactions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_adverse_reactions AFTER INSERT OR DELETE OR UPDATE ON adverse_reactions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_aid_to_families_with_dependent_children_limits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_aid_to_families_with_dependent_children_limits AFTER INSERT OR DELETE OR UPDATE ON aid_to_families_with_dependent_children_limits FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_allegation_maltreatment_subtypes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_allegation_maltreatment_subtypes AFTER INSERT OR DELETE OR UPDATE ON allegation_maltreatment_subtypes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_allegations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_allegations AFTER INSERT OR DELETE OR UPDATE ON allegations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_allergies; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_allergies AFTER INSERT OR DELETE OR UPDATE ON allergies FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_allergy_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_allergy_names AFTER INSERT OR DELETE OR UPDATE ON allergy_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_applicants; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_applicants AFTER INSERT OR DELETE OR UPDATE ON applicants FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_allegations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_allegations AFTER INSERT OR DELETE OR UPDATE ON archived_allegations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_assessment_legally_mandated_reasons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_assessment_legally_mandated_reasons AFTER INSERT OR DELETE OR UPDATE ON archived_assessment_legally_mandated_reasons FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_assessments AFTER INSERT OR DELETE OR UPDATE ON archived_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_attachments AFTER INSERT OR DELETE OR UPDATE ON archived_attachments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_notes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_notes AFTER INSERT OR DELETE OR UPDATE ON archived_notes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_archived_relationships; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_archived_relationships AFTER INSERT OR DELETE OR UPDATE ON archived_relationships FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessed_people_safety_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessed_people_safety_assessments AFTER INSERT OR DELETE OR UPDATE ON assessed_people_safety_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessment_legally_mandated_reasons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessment_legally_mandated_reasons AFTER INSERT OR DELETE OR UPDATE ON assessment_legally_mandated_reasons FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessment_legally_mandated_reasons_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessment_legally_mandated_reasons_people AFTER INSERT OR DELETE OR UPDATE ON assessment_legally_mandated_reasons_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessment_report_source_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessment_report_source_types AFTER INSERT OR DELETE OR UPDATE ON assessment_report_source_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessment_response_times; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessment_response_times AFTER INSERT OR DELETE OR UPDATE ON assessment_response_times FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessments AFTER INSERT OR DELETE OR UPDATE ON assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assessments_authorized_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assessments_authorized_users AFTER INSERT OR DELETE OR UPDATE ON assessments_authorized_users FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_assistance_group_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_assistance_group_people AFTER INSERT OR DELETE OR UPDATE ON assistance_group_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_attachments AFTER INSERT OR DELETE OR UPDATE ON attachments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_background_checks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_background_checks AFTER INSERT OR DELETE OR UPDATE ON background_checks FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_cans_assessment_cans_tools; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cans_assessment_cans_tools AFTER INSERT OR DELETE OR UPDATE ON cans_assessment_cans_tools FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_cans_assessment_health_recommendations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cans_assessment_health_recommendations AFTER INSERT OR DELETE OR UPDATE ON cans_assessment_health_recommendations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_cans_assessment_placement_recommendations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cans_assessment_placement_recommendations AFTER INSERT OR DELETE OR UPDATE ON cans_assessment_placement_recommendations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_cans_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cans_assessments AFTER INSERT OR DELETE OR UPDATE ON cans_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_financial_risk_factor_values; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_financial_risk_factor_values AFTER INSERT OR DELETE OR UPDATE ON caregiver_financial_risk_factor_values FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_financial_risks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_financial_risks AFTER INSERT OR DELETE OR UPDATE ON caregiver_financial_risks FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_health_risk_factor_values; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_health_risk_factor_values AFTER INSERT OR DELETE OR UPDATE ON caregiver_health_risk_factor_values FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_health_risks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_health_risks AFTER INSERT OR DELETE OR UPDATE ON caregiver_health_risks FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_strengths_and_needs_assessment_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_strengths_and_needs_assessment_quizzes AFTER INSERT OR DELETE OR UPDATE ON caregiver_strengths_and_needs_assessment_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_caregiver_strengths_and_needs_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_caregiver_strengths_and_needs_assessments AFTER INSERT OR DELETE OR UPDATE ON caregiver_strengths_and_needs_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_focus_child_involvements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_focus_child_involvements AFTER INSERT OR DELETE OR UPDATE ON case_focus_child_involvements FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_focus_children; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_focus_children AFTER INSERT OR DELETE OR UPDATE ON case_focus_children FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_linked_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_linked_assessments AFTER INSERT OR DELETE OR UPDATE ON case_linked_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_plan_caregivers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_plan_caregivers AFTER INSERT OR DELETE OR UPDATE ON case_plan_caregivers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_plan_focus_child_planned_caregivers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_plan_focus_child_planned_caregivers AFTER INSERT OR DELETE OR UPDATE ON case_plan_focus_child_planned_caregivers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_plan_focus_children; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_plan_focus_children AFTER INSERT OR DELETE OR UPDATE ON case_plan_focus_children FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_plan_safety_plan_links; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_plan_safety_plan_links AFTER INSERT OR DELETE OR UPDATE ON case_plan_safety_plan_links FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_case_plans; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_case_plans AFTER INSERT OR DELETE OR UPDATE ON case_plans FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_cases; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_cases AFTER INSERT OR DELETE OR UPDATE ON cases FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_checklist_answers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_checklist_answers AFTER INSERT OR DELETE OR UPDATE ON checklist_answers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_checklist_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_checklist_types AFTER INSERT OR DELETE OR UPDATE ON checklist_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_checklists; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_checklists AFTER INSERT OR DELETE OR UPDATE ON checklists FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_child_risk_factor_values; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_child_risk_factor_values AFTER INSERT OR DELETE OR UPDATE ON child_risk_factor_values FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_child_risks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_child_risks AFTER INSERT OR DELETE OR UPDATE ON child_risks FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_client_referrals; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_client_referrals AFTER INSERT OR DELETE OR UPDATE ON client_referrals FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_contact_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_contact_people AFTER INSERT OR DELETE OR UPDATE ON contact_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_contacts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_contacts AFTER INSERT OR DELETE OR UPDATE ON contacts FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_corrective_action_plans; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_corrective_action_plans AFTER INSERT OR DELETE OR UPDATE ON corrective_action_plans FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_counties; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_counties AFTER INSERT OR DELETE OR UPDATE ON counties FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearing_hearing_outcomes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearing_hearing_outcomes AFTER INSERT OR DELETE OR UPDATE ON court_hearing_hearing_outcomes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearing_outcomes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearing_outcomes AFTER INSERT OR DELETE OR UPDATE ON court_hearing_outcomes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearing_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearing_types AFTER INSERT OR DELETE OR UPDATE ON court_hearing_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearing_types_outcomes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearing_types_outcomes AFTER INSERT OR DELETE OR UPDATE ON court_hearing_types_outcomes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearings AFTER INSERT OR DELETE OR UPDATE ON court_hearings FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_hearings_court_language_citations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_hearings_court_language_citations AFTER INSERT OR DELETE OR UPDATE ON court_hearings_court_language_citations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_court_language_citations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_court_language_citations AFTER INSERT OR DELETE OR UPDATE ON court_language_citations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_custom_provision_with_questions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_custom_provision_with_questions AFTER INSERT OR DELETE OR UPDATE ON custom_provision_with_questions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_data_broker_event_logs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_data_broker_event_logs AFTER INSERT OR DELETE OR UPDATE ON data_broker_event_logs FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_data_broker_traffic_logs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_data_broker_traffic_logs AFTER INSERT OR DELETE OR UPDATE ON data_broker_traffic_logs FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_deprivation_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_deprivation_types AFTER INSERT OR DELETE OR UPDATE ON deprivation_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_discretionary_overrides; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_discretionary_overrides AFTER INSERT OR DELETE OR UPDATE ON discretionary_overrides FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_educational_overview_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_educational_overview_quizzes AFTER INSERT OR DELETE OR UPDATE ON educational_overview_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_eligibility_applications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_eligibility_applications AFTER INSERT OR DELETE OR UPDATE ON eligibility_applications FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_email_notes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_email_notes AFTER INSERT OR DELETE OR UPDATE ON email_notes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_emails; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_emails AFTER INSERT OR DELETE OR UPDATE ON emails FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_emergency_assistance_eligibilities; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_emergency_assistance_eligibilities AFTER INSERT OR DELETE OR UPDATE ON emergency_assistance_eligibilities FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_employment_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_employment_records AFTER INSERT OR DELETE OR UPDATE ON employment_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_external_roles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_external_roles AFTER INSERT OR DELETE OR UPDATE ON external_roles FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_external_roles_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_external_roles_users AFTER INSERT OR DELETE OR UPDATE ON external_roles_users FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_federal_poverty_income_limits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_federal_poverty_income_limits AFTER INSERT OR DELETE OR UPDATE ON federal_poverty_income_limits FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_foster_families; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_foster_families AFTER INSERT OR DELETE OR UPDATE ON foster_families FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_foster_family_other_household_members; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_foster_family_other_household_members AFTER INSERT OR DELETE OR UPDATE ON foster_family_other_household_members FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_health_care_provider_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_health_care_provider_names AFTER INSERT OR DELETE OR UPDATE ON health_care_provider_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_health_care_providers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_health_care_providers AFTER INSERT OR DELETE OR UPDATE ON health_care_providers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_health_exam_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_health_exam_names AFTER INSERT OR DELETE OR UPDATE ON health_exam_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_health_exams; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_health_exams AFTER INSERT OR DELETE OR UPDATE ON health_exams FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_hearing_outcomes_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_hearing_outcomes_people AFTER INSERT OR DELETE OR UPDATE ON hearing_outcomes_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_historical_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_historical_records AFTER INSERT OR DELETE OR UPDATE ON historical_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_court_consent_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_court_consent_people AFTER INSERT OR DELETE OR UPDATE ON ia_court_consent_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_hearing_waiver_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_hearing_waiver_people AFTER INSERT OR DELETE OR UPDATE ON ia_hearing_waiver_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_plan_child_supervisors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_plan_child_supervisors AFTER INSERT OR DELETE OR UPDATE ON ia_plan_child_supervisors FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_plan_contact_and_visitation_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_plan_contact_and_visitation_types AFTER INSERT OR DELETE OR UPDATE ON ia_plan_contact_and_visitation_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_plan_provisions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_plan_provisions AFTER INSERT OR DELETE OR UPDATE ON ia_plan_provisions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_plans; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_plans AFTER INSERT OR DELETE OR UPDATE ON ia_plans FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_ia_progress_reports; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ia_progress_reports AFTER INSERT OR DELETE OR UPDATE ON ia_progress_reports FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_identification_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_identification_types AFTER INSERT OR DELETE OR UPDATE ON identification_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_identifications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_identifications AFTER INSERT OR DELETE OR UPDATE ON identifications FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_immunization_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_immunization_names AFTER INSERT OR DELETE OR UPDATE ON immunization_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_immunizations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_immunizations AFTER INSERT OR DELETE OR UPDATE ON immunizations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_income_record_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_income_record_types AFTER INSERT OR DELETE OR UPDATE ON income_record_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_income_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_income_records AFTER INSERT OR DELETE OR UPDATE ON income_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_insurance_provider_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_insurance_provider_names AFTER INSERT OR DELETE OR UPDATE ON insurance_provider_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_insurance_providers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_insurance_providers AFTER INSERT OR DELETE OR UPDATE ON insurance_providers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_intake_allegations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_intake_allegations AFTER INSERT OR DELETE OR UPDATE ON intake_allegations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_intake_legally_mandated_reasons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_intake_legally_mandated_reasons AFTER INSERT OR DELETE OR UPDATE ON intake_legally_mandated_reasons FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_intake_legally_mandated_reasons_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_intake_legally_mandated_reasons_people AFTER INSERT OR DELETE OR UPDATE ON intake_legally_mandated_reasons_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_intake_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_intake_people AFTER INSERT OR DELETE OR UPDATE ON intake_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_intakes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_intakes AFTER INSERT OR DELETE OR UPDATE ON intakes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_involvement_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_involvement_types AFTER INSERT OR DELETE OR UPDATE ON involvement_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_iv_e_eligibilities; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_iv_e_eligibilities AFTER INSERT OR DELETE OR UPDATE ON iv_e_eligibilities FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_languages; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_languages AFTER INSERT OR DELETE OR UPDATE ON languages FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_legally_mandated_reasons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_legally_mandated_reasons AFTER INSERT OR DELETE OR UPDATE ON legally_mandated_reasons FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_licenses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_licenses AFTER INSERT OR DELETE OR UPDATE ON licenses FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_living_arrangements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_living_arrangements AFTER INSERT OR DELETE OR UPDATE ON living_arrangements FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_medical_condition_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_medical_condition_names AFTER INSERT OR DELETE OR UPDATE ON medical_condition_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_medical_conditions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_medical_conditions AFTER INSERT OR DELETE OR UPDATE ON medical_conditions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_medication_regimens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_medication_regimens AFTER INSERT OR DELETE OR UPDATE ON medication_regimens FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_medications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_medications AFTER INSERT OR DELETE OR UPDATE ON medications FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_native_american_tribes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_native_american_tribes AFTER INSERT OR DELETE OR UPDATE ON native_american_tribes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_neglect_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_neglect_quizzes AFTER INSERT OR DELETE OR UPDATE ON neglect_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_notes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_notes AFTER INSERT OR DELETE OR UPDATE ON notes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_notifications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_notifications AFTER INSERT OR DELETE OR UPDATE ON notifications FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_objective_activities; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_objective_activities AFTER INSERT OR DELETE OR UPDATE ON objective_activities FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_objective_activity_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_objective_activity_people AFTER INSERT OR DELETE OR UPDATE ON objective_activity_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_objectives; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_objectives AFTER INSERT OR DELETE OR UPDATE ON objectives FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_offered_services; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_offered_services AFTER INSERT OR DELETE OR UPDATE ON offered_services FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_open_id_associations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_open_id_associations AFTER INSERT OR DELETE OR UPDATE ON open_id_associations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_open_id_nonces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_open_id_nonces AFTER INSERT OR DELETE OR UPDATE ON open_id_nonces FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_open_id_requests; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_open_id_requests AFTER INSERT OR DELETE OR UPDATE ON open_id_requests FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_organizations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_organizations AFTER INSERT OR DELETE OR UPDATE ON organizations FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_parental_deprivation_checklists; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_parental_deprivation_checklists AFTER INSERT OR DELETE OR UPDATE ON parental_deprivation_checklists FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_parental_deprivation_values; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_parental_deprivation_values AFTER INSERT OR DELETE OR UPDATE ON parental_deprivation_values FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_people AFTER INSERT OR DELETE OR UPDATE ON people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_phone_numbers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_phone_numbers AFTER INSERT OR DELETE OR UPDATE ON phone_numbers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_physical_location_placements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_physical_location_placements AFTER INSERT OR DELETE OR UPDATE ON physical_location_placements FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_physical_location_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_physical_location_records AFTER INSERT OR DELETE OR UPDATE ON physical_location_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_physical_location_runaways; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_physical_location_runaways AFTER INSERT OR DELETE OR UPDATE ON physical_location_runaways FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_physical_location_temporary_absences; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_physical_location_temporary_absences AFTER INSERT OR DELETE OR UPDATE ON physical_location_temporary_absences FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_physical_location_trial_home_visits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_physical_location_trial_home_visits AFTER INSERT OR DELETE OR UPDATE ON physical_location_trial_home_visits FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_placed_people_safety_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_placed_people_safety_assessments AFTER INSERT OR DELETE OR UPDATE ON placed_people_safety_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_placement_status_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_placement_status_quizzes AFTER INSERT OR DELETE OR UPDATE ON placement_status_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_plan_agreement_item_focus_children; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_plan_agreement_item_focus_children AFTER INSERT OR DELETE OR UPDATE ON plan_agreement_item_focus_children FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_plan_agreement_item_monitors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_plan_agreement_item_monitors AFTER INSERT OR DELETE OR UPDATE ON plan_agreement_item_monitors FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_plan_agreement_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_plan_agreement_items AFTER INSERT OR DELETE OR UPDATE ON plan_agreement_items FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_potential_match_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_potential_match_records AFTER INSERT OR DELETE OR UPDATE ON potential_match_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_previous_passwords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_previous_passwords AFTER INSERT OR DELETE OR UPDATE ON previous_passwords FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_provision_question_answers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_provision_question_answers AFTER INSERT OR DELETE OR UPDATE ON provision_question_answers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_provision_questions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_provision_questions AFTER INSERT OR DELETE OR UPDATE ON provision_questions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_provisions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_provisions AFTER INSERT OR DELETE OR UPDATE ON provisions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_reassessment_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_reassessment_quizzes AFTER INSERT OR DELETE OR UPDATE ON reassessment_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_recovery_passwords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_recovery_passwords AFTER INSERT OR DELETE OR UPDATE ON recovery_passwords FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_referral_objectives; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_referral_objectives AFTER INSERT OR DELETE OR UPDATE ON referral_objectives FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_referrals; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_referrals AFTER INSERT OR DELETE OR UPDATE ON referrals FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_relationship_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_relationship_types AFTER INSERT OR DELETE OR UPDATE ON relationship_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_relationships; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_relationships AFTER INSERT OR DELETE OR UPDATE ON relationships FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_religions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_religions AFTER INSERT OR DELETE OR UPDATE ON religions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_residencies; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_residencies AFTER INSERT OR DELETE OR UPDATE ON residencies FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_residential_resource_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_residential_resource_types AFTER INSERT OR DELETE OR UPDATE ON residential_resource_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_residential_resources; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_residential_resources AFTER INSERT OR DELETE OR UPDATE ON residential_resources FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_resources; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_resources AFTER INSERT OR DELETE OR UPDATE ON resources FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_resque_job_to_retries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_resque_job_to_retries AFTER INSERT OR DELETE OR UPDATE ON resque_job_to_retries FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_risk_assessment_decisions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_risk_assessment_decisions AFTER INSERT OR DELETE OR UPDATE ON risk_assessment_decisions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_risk_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_risk_assessments AFTER INSERT OR DELETE OR UPDATE ON risk_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_risk_factors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_risk_factors AFTER INSERT OR DELETE OR UPDATE ON risk_factors FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_risk_reassessment_focus_children; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_risk_reassessment_focus_children AFTER INSERT OR DELETE OR UPDATE ON risk_reassessment_focus_children FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_risk_reassessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_risk_reassessments AFTER INSERT OR DELETE OR UPDATE ON risk_reassessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_roles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_roles AFTER INSERT OR DELETE OR UPDATE ON roles FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_roles_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_roles_users AFTER INSERT OR DELETE OR UPDATE ON roles_users FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_safety_assessments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_safety_assessments AFTER INSERT OR DELETE OR UPDATE ON safety_assessments FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_safety_plan_agreement_contacts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_safety_plan_agreement_contacts AFTER INSERT OR DELETE OR UPDATE ON safety_plan_agreement_contacts FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_safety_plans; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_safety_plans AFTER INSERT OR DELETE OR UPDATE ON safety_plans FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_scheduled_visits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_scheduled_visits AFTER INSERT OR DELETE OR UPDATE ON scheduled_visits FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_school_change_quizzes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_school_change_quizzes AFTER INSERT OR DELETE OR UPDATE ON school_change_quizzes FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_school_record_grade_levels; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_school_record_grade_levels AFTER INSERT OR DELETE OR UPDATE ON school_record_grade_levels FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_school_record_new_school_reasons; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_school_record_new_school_reasons AFTER INSERT OR DELETE OR UPDATE ON school_record_new_school_reasons FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_school_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_school_records AFTER INSERT OR DELETE OR UPDATE ON school_records FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_schools; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_schools AFTER INSERT OR DELETE OR UPDATE ON schools FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_service_categories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_service_categories AFTER INSERT OR DELETE OR UPDATE ON service_categories FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_service_category_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_service_category_types AFTER INSERT OR DELETE OR UPDATE ON service_category_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_service_provider_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_service_provider_types AFTER INSERT OR DELETE OR UPDATE ON service_provider_types FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_service_providers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_service_providers AFTER INSERT OR DELETE OR UPDATE ON service_providers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_services; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_services AFTER INSERT OR DELETE OR UPDATE ON services FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_signatories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_signatories AFTER INSERT OR DELETE OR UPDATE ON signatories FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_sites; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_sites AFTER INSERT OR DELETE OR UPDATE ON sites FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_special_diet_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_special_diet_names AFTER INSERT OR DELETE OR UPDATE ON special_diet_names FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_special_diets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_special_diets AFTER INSERT OR DELETE OR UPDATE ON special_diets FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_special_needs_checklists; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_special_needs_checklists AFTER INSERT OR DELETE OR UPDATE ON special_needs_checklists FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_special_needs_values; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_special_needs_values AFTER INSERT OR DELETE OR UPDATE ON special_needs_values FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_staff_members; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_staff_members AFTER INSERT OR DELETE OR UPDATE ON staff_members FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_status_determination_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_status_determination_events AFTER INSERT OR DELETE OR UPDATE ON status_determination_events FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_team_meeting_facilitators; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_team_meeting_facilitators AFTER INSERT OR DELETE OR UPDATE ON team_meeting_facilitators FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_team_meeting_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_team_meeting_people AFTER INSERT OR DELETE OR UPDATE ON team_meeting_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_team_meetings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_team_meetings AFTER INSERT OR DELETE OR UPDATE ON team_meetings FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_users AFTER INSERT OR DELETE OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_validation_exceptions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_validation_exceptions AFTER INSERT OR DELETE OR UPDATE ON validation_exceptions FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_visitation_plan_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_visitation_plan_people AFTER INSERT OR DELETE OR UPDATE ON visitation_plan_people FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_visitation_plans; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_visitation_plans AFTER INSERT OR DELETE OR UPDATE ON visitation_plans FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_waivers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_waivers AFTER INSERT OR DELETE OR UPDATE ON waivers FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: audit_workflow_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_workflow_events AFTER INSERT OR DELETE OR UPDATE ON workflow_events FOR EACH ROW EXECUTE PROCEDURE audit_changes();


--
-- Name: assistance_group_people_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assistance_group_people
    ADD CONSTRAINT assistance_group_people_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);


--
-- Name: intakes_incident_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intakes
    ADD CONSTRAINT intakes_incident_address_id_fkey FOREIGN KEY (incident_address_id) REFERENCES addresses(id);


--
-- Name: residencies_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY residencies
    ADD CONSTRAINT residencies_address_id_fkey FOREIGN KEY (address_id) REFERENCES addresses(id);


--
-- Name: users_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20110831133750');

INSERT INTO schema_migrations (version) VALUES ('20110901125155');

INSERT INTO schema_migrations (version) VALUES ('20110901220106');

INSERT INTO schema_migrations (version) VALUES ('20110902150629');

INSERT INTO schema_migrations (version) VALUES ('20110902184057');

INSERT INTO schema_migrations (version) VALUES ('20110902201030');

INSERT INTO schema_migrations (version) VALUES ('20110906185715');

INSERT INTO schema_migrations (version) VALUES ('20110907134709');

INSERT INTO schema_migrations (version) VALUES ('20110907152129');

INSERT INTO schema_migrations (version) VALUES ('20110907173631');

INSERT INTO schema_migrations (version) VALUES ('20110908125747');

INSERT INTO schema_migrations (version) VALUES ('20110908150328');

INSERT INTO schema_migrations (version) VALUES ('20110908150943');

INSERT INTO schema_migrations (version) VALUES ('20110908195732');

INSERT INTO schema_migrations (version) VALUES ('20110909181543');

INSERT INTO schema_migrations (version) VALUES ('20110912133357');

INSERT INTO schema_migrations (version) VALUES ('20110912134048');

INSERT INTO schema_migrations (version) VALUES ('20110912142202');

INSERT INTO schema_migrations (version) VALUES ('20110912145500');

INSERT INTO schema_migrations (version) VALUES ('20110912155953');

INSERT INTO schema_migrations (version) VALUES ('20110912211000');

INSERT INTO schema_migrations (version) VALUES ('20110913152528');

INSERT INTO schema_migrations (version) VALUES ('20110913161447');

INSERT INTO schema_migrations (version) VALUES ('20110913190627');

INSERT INTO schema_migrations (version) VALUES ('20110913221748');

INSERT INTO schema_migrations (version) VALUES ('20110914141237');

INSERT INTO schema_migrations (version) VALUES ('20110914184024');

INSERT INTO schema_migrations (version) VALUES ('20110914184314');

INSERT INTO schema_migrations (version) VALUES ('20110914191702');

INSERT INTO schema_migrations (version) VALUES ('20110914212820');

INSERT INTO schema_migrations (version) VALUES ('20110914215456');

INSERT INTO schema_migrations (version) VALUES ('20110915141207');

INSERT INTO schema_migrations (version) VALUES ('20110915204544');

INSERT INTO schema_migrations (version) VALUES ('20110916141027');

INSERT INTO schema_migrations (version) VALUES ('20110916154000');

INSERT INTO schema_migrations (version) VALUES ('20110916173844');

INSERT INTO schema_migrations (version) VALUES ('20110919160158');

INSERT INTO schema_migrations (version) VALUES ('20110919162003');

INSERT INTO schema_migrations (version) VALUES ('20110919183612');

INSERT INTO schema_migrations (version) VALUES ('20110919184410');

INSERT INTO schema_migrations (version) VALUES ('20110920143608');

INSERT INTO schema_migrations (version) VALUES ('20110920200409');

INSERT INTO schema_migrations (version) VALUES ('20110921144122');

INSERT INTO schema_migrations (version) VALUES ('20110921155024');

INSERT INTO schema_migrations (version) VALUES ('20110921205340');

INSERT INTO schema_migrations (version) VALUES ('20110921210734');

INSERT INTO schema_migrations (version) VALUES ('20110922135646');

INSERT INTO schema_migrations (version) VALUES ('20110922153230');

INSERT INTO schema_migrations (version) VALUES ('20110923150602');

INSERT INTO schema_migrations (version) VALUES ('20110923150816');

INSERT INTO schema_migrations (version) VALUES ('20110923160920');

INSERT INTO schema_migrations (version) VALUES ('20110926140152');

INSERT INTO schema_migrations (version) VALUES ('20110926142626');

INSERT INTO schema_migrations (version) VALUES ('20110926210422');

INSERT INTO schema_migrations (version) VALUES ('20110927161930');

INSERT INTO schema_migrations (version) VALUES ('20110927182430');

INSERT INTO schema_migrations (version) VALUES ('20110927182642');

INSERT INTO schema_migrations (version) VALUES ('20110927185900');

INSERT INTO schema_migrations (version) VALUES ('20110927202409');

INSERT INTO schema_migrations (version) VALUES ('20110927204444');

INSERT INTO schema_migrations (version) VALUES ('20110927210052');

INSERT INTO schema_migrations (version) VALUES ('20110928135221');

INSERT INTO schema_migrations (version) VALUES ('20110928175742');

INSERT INTO schema_migrations (version) VALUES ('20110928190802');

INSERT INTO schema_migrations (version) VALUES ('20110928193730');

INSERT INTO schema_migrations (version) VALUES ('20110928201432');

INSERT INTO schema_migrations (version) VALUES ('20110928202209');

INSERT INTO schema_migrations (version) VALUES ('20110928202817');

INSERT INTO schema_migrations (version) VALUES ('20110928202818');

INSERT INTO schema_migrations (version) VALUES ('20110928202820');

INSERT INTO schema_migrations (version) VALUES ('20110928202822');

INSERT INTO schema_migrations (version) VALUES ('20110928202901');

INSERT INTO schema_migrations (version) VALUES ('20110928202905');

INSERT INTO schema_migrations (version) VALUES ('20110928202965');

INSERT INTO schema_migrations (version) VALUES ('20110929191858');

INSERT INTO schema_migrations (version) VALUES ('20110929205934');

INSERT INTO schema_migrations (version) VALUES ('20110930150156');

INSERT INTO schema_migrations (version) VALUES ('20110930193445');

INSERT INTO schema_migrations (version) VALUES ('20111003182004');

INSERT INTO schema_migrations (version) VALUES ('20111003185415');

INSERT INTO schema_migrations (version) VALUES ('20111003203939');

INSERT INTO schema_migrations (version) VALUES ('20111003205235');

INSERT INTO schema_migrations (version) VALUES ('20111003210553');

INSERT INTO schema_migrations (version) VALUES ('20111003212856');

INSERT INTO schema_migrations (version) VALUES ('20111003224028');

INSERT INTO schema_migrations (version) VALUES ('20111004133804');

INSERT INTO schema_migrations (version) VALUES ('20111004134952');

INSERT INTO schema_migrations (version) VALUES ('20111004140037');

INSERT INTO schema_migrations (version) VALUES ('20111004141341');

INSERT INTO schema_migrations (version) VALUES ('20111004142825');

INSERT INTO schema_migrations (version) VALUES ('20111004144703');

INSERT INTO schema_migrations (version) VALUES ('20111004145444');

INSERT INTO schema_migrations (version) VALUES ('20111004150606');

INSERT INTO schema_migrations (version) VALUES ('20111004161533');

INSERT INTO schema_migrations (version) VALUES ('20111004162515');

INSERT INTO schema_migrations (version) VALUES ('20111004180440');

INSERT INTO schema_migrations (version) VALUES ('20111004183824');

INSERT INTO schema_migrations (version) VALUES ('20111004190128');

INSERT INTO schema_migrations (version) VALUES ('20111004191018');

INSERT INTO schema_migrations (version) VALUES ('20111004192017');

INSERT INTO schema_migrations (version) VALUES ('20111004192434');

INSERT INTO schema_migrations (version) VALUES ('20111004193031');

INSERT INTO schema_migrations (version) VALUES ('20111005120321');

INSERT INTO schema_migrations (version) VALUES ('20111005124351');

INSERT INTO schema_migrations (version) VALUES ('20111005124719');

INSERT INTO schema_migrations (version) VALUES ('20111005133447');

INSERT INTO schema_migrations (version) VALUES ('20111005135759');

INSERT INTO schema_migrations (version) VALUES ('20111005141746');

INSERT INTO schema_migrations (version) VALUES ('20111005145420');

INSERT INTO schema_migrations (version) VALUES ('20111005150736');

INSERT INTO schema_migrations (version) VALUES ('20111005153104');

INSERT INTO schema_migrations (version) VALUES ('20111005190401');

INSERT INTO schema_migrations (version) VALUES ('20111005193843');

INSERT INTO schema_migrations (version) VALUES ('20111005202442');

INSERT INTO schema_migrations (version) VALUES ('20111005204504');

INSERT INTO schema_migrations (version) VALUES ('20111005205131');

INSERT INTO schema_migrations (version) VALUES ('20111005212030');

INSERT INTO schema_migrations (version) VALUES ('20111006140942');

INSERT INTO schema_migrations (version) VALUES ('20111006141006');

INSERT INTO schema_migrations (version) VALUES ('20111006154015');

INSERT INTO schema_migrations (version) VALUES ('20111006154325');

INSERT INTO schema_migrations (version) VALUES ('20111006154515');

INSERT INTO schema_migrations (version) VALUES ('20111006155444');

INSERT INTO schema_migrations (version) VALUES ('20111006162643');

INSERT INTO schema_migrations (version) VALUES ('20111006213207');

INSERT INTO schema_migrations (version) VALUES ('20111007142838');

INSERT INTO schema_migrations (version) VALUES ('20111007171324');

INSERT INTO schema_migrations (version) VALUES ('20111008165235');

INSERT INTO schema_migrations (version) VALUES ('20111010152623');

INSERT INTO schema_migrations (version) VALUES ('20111010155351');

INSERT INTO schema_migrations (version) VALUES ('20111010161221');

INSERT INTO schema_migrations (version) VALUES ('20111010174327');

INSERT INTO schema_migrations (version) VALUES ('20111010195956');

INSERT INTO schema_migrations (version) VALUES ('20111011091436');

INSERT INTO schema_migrations (version) VALUES ('20111011152549');

INSERT INTO schema_migrations (version) VALUES ('20111011184849');

INSERT INTO schema_migrations (version) VALUES ('20111011203828');

INSERT INTO schema_migrations (version) VALUES ('20111011210252');

INSERT INTO schema_migrations (version) VALUES ('20111012032858');

INSERT INTO schema_migrations (version) VALUES ('20111012033835');

INSERT INTO schema_migrations (version) VALUES ('20111012153742');

INSERT INTO schema_migrations (version) VALUES ('20111012160743');

INSERT INTO schema_migrations (version) VALUES ('20111012173531');

INSERT INTO schema_migrations (version) VALUES ('20111013134837');

INSERT INTO schema_migrations (version) VALUES ('20111013135241');

INSERT INTO schema_migrations (version) VALUES ('20111013141205');

INSERT INTO schema_migrations (version) VALUES ('20111013155909');

INSERT INTO schema_migrations (version) VALUES ('20111013155957');

INSERT INTO schema_migrations (version) VALUES ('20111013162214');

INSERT INTO schema_migrations (version) VALUES ('20111013162943');

INSERT INTO schema_migrations (version) VALUES ('20111013171502');

INSERT INTO schema_migrations (version) VALUES ('20111013175149');

INSERT INTO schema_migrations (version) VALUES ('20111013181522');

INSERT INTO schema_migrations (version) VALUES ('20111013191639');

INSERT INTO schema_migrations (version) VALUES ('20111013195519');

INSERT INTO schema_migrations (version) VALUES ('20111013201803');

INSERT INTO schema_migrations (version) VALUES ('20111013210511');

INSERT INTO schema_migrations (version) VALUES ('20111013235908');

INSERT INTO schema_migrations (version) VALUES ('20111014083745');

INSERT INTO schema_migrations (version) VALUES ('20111014143649');

INSERT INTO schema_migrations (version) VALUES ('20111014154320');

INSERT INTO schema_migrations (version) VALUES ('20111014193359');

INSERT INTO schema_migrations (version) VALUES ('20111014195712');

INSERT INTO schema_migrations (version) VALUES ('20111017145011');

INSERT INTO schema_migrations (version) VALUES ('20111017151359');

INSERT INTO schema_migrations (version) VALUES ('20111017152802');

INSERT INTO schema_migrations (version) VALUES ('20111017160826');

INSERT INTO schema_migrations (version) VALUES ('20111017185034');

INSERT INTO schema_migrations (version) VALUES ('20111017194535');

INSERT INTO schema_migrations (version) VALUES ('20111017201803');

INSERT INTO schema_migrations (version) VALUES ('20111018061144');

INSERT INTO schema_migrations (version) VALUES ('20111018153026');

INSERT INTO schema_migrations (version) VALUES ('20111018154031');

INSERT INTO schema_migrations (version) VALUES ('20111018161146');

INSERT INTO schema_migrations (version) VALUES ('20111018174543');

INSERT INTO schema_migrations (version) VALUES ('20111018175441');

INSERT INTO schema_migrations (version) VALUES ('20111018193159');

INSERT INTO schema_migrations (version) VALUES ('20111018205137');

INSERT INTO schema_migrations (version) VALUES ('20111019150547');

INSERT INTO schema_migrations (version) VALUES ('20111019155219');

INSERT INTO schema_migrations (version) VALUES ('20111019155816');

INSERT INTO schema_migrations (version) VALUES ('20111019161114');

INSERT INTO schema_migrations (version) VALUES ('20111019162039');

INSERT INTO schema_migrations (version) VALUES ('20111019163426');

INSERT INTO schema_migrations (version) VALUES ('20111019180515');

INSERT INTO schema_migrations (version) VALUES ('20111019203909');

INSERT INTO schema_migrations (version) VALUES ('20111019211848');

INSERT INTO schema_migrations (version) VALUES ('20111019211937');

INSERT INTO schema_migrations (version) VALUES ('20111019211959');

INSERT INTO schema_migrations (version) VALUES ('20111019211960');

INSERT INTO schema_migrations (version) VALUES ('20111019220109');

INSERT INTO schema_migrations (version) VALUES ('20111020144425');

INSERT INTO schema_migrations (version) VALUES ('20111020144442');

INSERT INTO schema_migrations (version) VALUES ('20111020145117');

INSERT INTO schema_migrations (version) VALUES ('20111020145242');

INSERT INTO schema_migrations (version) VALUES ('20111020154836');

INSERT INTO schema_migrations (version) VALUES ('20111020155259');

INSERT INTO schema_migrations (version) VALUES ('20111020175423');

INSERT INTO schema_migrations (version) VALUES ('20111020182808');

INSERT INTO schema_migrations (version) VALUES ('20111020182853');

INSERT INTO schema_migrations (version) VALUES ('20111020222417');

INSERT INTO schema_migrations (version) VALUES ('20111021140118');

INSERT INTO schema_migrations (version) VALUES ('20111021165253');

INSERT INTO schema_migrations (version) VALUES ('20111024022644');

INSERT INTO schema_migrations (version) VALUES ('20111024181210');

INSERT INTO schema_migrations (version) VALUES ('20111024183022');

INSERT INTO schema_migrations (version) VALUES ('20111025161601');

INSERT INTO schema_migrations (version) VALUES ('20111025183347');

INSERT INTO schema_migrations (version) VALUES ('20111025205013');

INSERT INTO schema_migrations (version) VALUES ('20111026042946');

INSERT INTO schema_migrations (version) VALUES ('20111026143324');

INSERT INTO schema_migrations (version) VALUES ('20111026155459');

INSERT INTO schema_migrations (version) VALUES ('20111026175048');

INSERT INTO schema_migrations (version) VALUES ('20111026191857');

INSERT INTO schema_migrations (version) VALUES ('20111026194029');

INSERT INTO schema_migrations (version) VALUES ('20111026195610');

INSERT INTO schema_migrations (version) VALUES ('20111026200324');

INSERT INTO schema_migrations (version) VALUES ('20111026201320');

INSERT INTO schema_migrations (version) VALUES ('20111026204125');

INSERT INTO schema_migrations (version) VALUES ('20111026210215');

INSERT INTO schema_migrations (version) VALUES ('20111026211126');

INSERT INTO schema_migrations (version) VALUES ('20111026212430');

INSERT INTO schema_migrations (version) VALUES ('20111026212911');

INSERT INTO schema_migrations (version) VALUES ('20111026221623');

INSERT INTO schema_migrations (version) VALUES ('20111027124126');

INSERT INTO schema_migrations (version) VALUES ('20111027141707');

INSERT INTO schema_migrations (version) VALUES ('20111027142222');

INSERT INTO schema_migrations (version) VALUES ('20111028135408');

INSERT INTO schema_migrations (version) VALUES ('20111028152138');

INSERT INTO schema_migrations (version) VALUES ('20111028160206');

INSERT INTO schema_migrations (version) VALUES ('20111031151500');

INSERT INTO schema_migrations (version) VALUES ('20111031193823');

INSERT INTO schema_migrations (version) VALUES ('20111031193921');

INSERT INTO schema_migrations (version) VALUES ('20111031200321');

INSERT INTO schema_migrations (version) VALUES ('20111101153714');

INSERT INTO schema_migrations (version) VALUES ('20111101184859');

INSERT INTO schema_migrations (version) VALUES ('20111101203337');

INSERT INTO schema_migrations (version) VALUES ('20111102141920');

INSERT INTO schema_migrations (version) VALUES ('20111102160012');

INSERT INTO schema_migrations (version) VALUES ('20111102161248');

INSERT INTO schema_migrations (version) VALUES ('20111102181750');

INSERT INTO schema_migrations (version) VALUES ('20111102195637');

INSERT INTO schema_migrations (version) VALUES ('20111103143212');

INSERT INTO schema_migrations (version) VALUES ('20111103144633');

INSERT INTO schema_migrations (version) VALUES ('20111104135713');

INSERT INTO schema_migrations (version) VALUES ('20111104140858');

INSERT INTO schema_migrations (version) VALUES ('20111104160402');

INSERT INTO schema_migrations (version) VALUES ('20111104163240');

INSERT INTO schema_migrations (version) VALUES ('20111104182245');

INSERT INTO schema_migrations (version) VALUES ('20111104185026');

INSERT INTO schema_migrations (version) VALUES ('20111104185840');

INSERT INTO schema_migrations (version) VALUES ('20111104192328');

INSERT INTO schema_migrations (version) VALUES ('20111104192646');

INSERT INTO schema_migrations (version) VALUES ('20111104201111');

INSERT INTO schema_migrations (version) VALUES ('20111104202221');

INSERT INTO schema_migrations (version) VALUES ('20111107143629');

INSERT INTO schema_migrations (version) VALUES ('20111107164553');

INSERT INTO schema_migrations (version) VALUES ('20111107164948');

INSERT INTO schema_migrations (version) VALUES ('20111107191124');

INSERT INTO schema_migrations (version) VALUES ('20111107195429');

INSERT INTO schema_migrations (version) VALUES ('20111107200909');

INSERT INTO schema_migrations (version) VALUES ('20111108115546');

INSERT INTO schema_migrations (version) VALUES ('20111108144010');

INSERT INTO schema_migrations (version) VALUES ('20111108151047');

INSERT INTO schema_migrations (version) VALUES ('20111108151754');

INSERT INTO schema_migrations (version) VALUES ('20111108162001');

INSERT INTO schema_migrations (version) VALUES ('20111108192042');

INSERT INTO schema_migrations (version) VALUES ('20111108192329');

INSERT INTO schema_migrations (version) VALUES ('20111108194622');

INSERT INTO schema_migrations (version) VALUES ('20111108201051');

INSERT INTO schema_migrations (version) VALUES ('20111108221101');

INSERT INTO schema_migrations (version) VALUES ('20111109061101');

INSERT INTO schema_migrations (version) VALUES ('20111109151940');

INSERT INTO schema_migrations (version) VALUES ('20111109194333');

INSERT INTO schema_migrations (version) VALUES ('20111109213458');

INSERT INTO schema_migrations (version) VALUES ('20111109215749');

INSERT INTO schema_migrations (version) VALUES ('20111110130350');

INSERT INTO schema_migrations (version) VALUES ('20111110150125');

INSERT INTO schema_migrations (version) VALUES ('20111110151449');

INSERT INTO schema_migrations (version) VALUES ('20111110172113');

INSERT INTO schema_migrations (version) VALUES ('20111110172901');

INSERT INTO schema_migrations (version) VALUES ('20111110200950');

INSERT INTO schema_migrations (version) VALUES ('20111110202213');

INSERT INTO schema_migrations (version) VALUES ('20111110205918');