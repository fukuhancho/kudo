--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases (except postgres and template1)
--

DROP DATABASE "KUDO10";




--
-- Drop roles
--

DROP ROLE postgres;


--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:UjcOeC/zsK6aiQl9nfh4og==$CEsuzifHj8lJJfI98vaer9t3bvQ3Xdgr7qZwcQtfmGY=:bQthpbERt4rJe6fj/TfjMw493C53DBnYE6nBhzjDg8I=';

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

UPDATE pg_catalog.pg_database SET datistemplate = false WHERE datname = 'template1';
DROP DATABASE template1;
--
-- Name: template1; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE template1 OWNER TO postgres;

\connect template1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE template1; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: template1; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE template1 IS_TEMPLATE = true;


\connect template1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE template1; Type: ACL; Schema: -; Owner: postgres
--

REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- Database "KUDO10" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: KUDO10; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "KUDO10" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE "KUDO10" OWNER TO postgres;

\connect "KUDO10"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_timestamp() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: branch_m; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.branch_m (
    branch_id text NOT NULL,
    branch_nm text,
    branch_nm2 text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.branch_m OWNER TO postgres;

--
-- Name: category_m; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category_m (
    category_id text NOT NULL,
    category_nm text,
    age_min integer,
    age_max integer,
    physical_index_min real,
    physical_index_max real,
    sex_rule text,
    remarks text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.category_m OWNER TO postgres;

--
-- Name: league_brackets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.league_brackets (
    bracket_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tournament_id character varying(255) NOT NULL,
    category_id character varying(255) NOT NULL,
    league_data jsonb,
    match_results_data jsonb,
    standings_data jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.league_brackets OWNER TO postgres;

--
-- Name: player_m; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_m (
    branch_id text NOT NULL,
    player_id text NOT NULL,
    familyname text,
    familyname2 text,
    firstname text,
    firstname2 text,
    sex text,
    birthday text,
    admissionday text,
    xclass text,
    height real,
    weight real,
    remarks text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.player_m OWNER TO postgres;

--
-- Name: tournament_brackets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_brackets (
    bracket_id uuid NOT NULL,
    tournament_id character varying(255) NOT NULL,
    category_id character varying(255) NOT NULL,
    bracket_data jsonb NOT NULL,
    final_winner_data jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tournament_brackets OWNER TO postgres;

--
-- Name: tournament_category_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_category_map (
    tournament_id text NOT NULL,
    category_id text NOT NULL,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tournament_category_map OWNER TO postgres;

--
-- Name: tournament_m; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_m (
    tournament_id text NOT NULL,
    tournament_nm text,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    venue_id text,
    number_coat integer,
    remarks text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tournament_m OWNER TO postgres;

--
-- Name: tournament_participant; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_participant (
    tournament_id text NOT NULL,
    player_id text NOT NULL,
    branch_id text NOT NULL,
    category_id text NOT NULL,
    entry_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status text DEFAULT 'confirmed'::text
);


ALTER TABLE public.tournament_participant OWNER TO postgres;

--
-- Name: venue_m; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venue_m (
    venue_id text NOT NULL,
    venue_nm text,
    remarks text,
    created timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.venue_m OWNER TO postgres;

--
-- Data for Name: branch_m; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.branch_m (branch_id, branch_nm, branch_nm2, created) FROM stdin;
B001	東京城南支部	トウキョウジョウナンシブ	2025-06-28 06:42:52.267047+00
B002	大阪北支部	オオサカキタシブ	2025-06-28 06:42:52.267047+00
B003	名古屋栄支部	ナゴヤサカエシブ	2025-06-28 06:42:52.267047+00
B004	福岡博多支部	フクオカハカタシブ	2025-06-28 06:42:52.267047+00
B005	日進	ニッシン	2025-06-29 23:44:35.569583+00
B006	長久手	ナガクテ	2025-06-30 00:20:48.453865+00
B007	豊明	トヨアケ	2025-07-01 02:38:34.066851+00
\.


--
-- Data for Name: category_m; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.category_m (category_id, category_nm, age_min, age_max, physical_index_min, physical_index_max, sex_rule, remarks, created) FROM stdin;
U9	U9:9歳未満	\N	8	\N	\N	any	2025年12月31日時点で8歳以下	2025-06-28 06:42:52.267047+00
U12	U12:12歳未満	\N	11	\N	\N	any	2025年12月31日時点で11歳以下	2025-06-28 06:42:52.267047+00
U16_210	U16 210:16歳未満 体力指数210未満	\N	15	\N	209.9	any	2025年12月31日時点で15歳以下、体力指数210未満	2025-06-28 06:42:52.267047+00
U16_230	U16 230:16歳未満 体力指数230未満	\N	15	210	229.9	any	2025年12月31日時点で15歳以下、体力指数210以上230未満	2025-06-28 06:42:52.267047+00
U16_230+	U16 230+:16歳未満 体力指数230以上	\N	15	230	\N	any	2025年12月31日時点で15歳以下、体力指数230以上	2025-06-28 06:42:52.267047+00
U19_230-	U19 -230:19歳未満 体力指数230未満	\N	18	\N	229.9	any	2025年12月31日時点で18歳以下、体力指数230未満	2025-06-28 06:42:52.267047+00
U19_230+	U19 230+:19歳未満 体力指数230以上	\N	18	230	\N	any	2025年12月31日時点で18歳以下、体力指数230以上	2025-06-28 06:42:52.267047+00
M_230-	一般男子 -230	20	\N	\N	229.9	m	男性、20歳以上、体力指数230未満	2025-06-28 06:42:52.267047+00
M_240-	一般男子 -240	20	\N	230	239.9	m	男性、20歳以上、体力指数230以上240未満	2025-06-28 06:42:52.267047+00
M_250-	一般男子 -250	20	\N	240	249.9	m	男性、20歳以上、体力指数240以上250未満	2025-06-28 06:42:52.267047+00
M_260-	一般男子 -260	20	\N	250	259.9	m	男性、20歳以上、体力指数250以上260未満	2025-06-28 06:42:52.267047+00
M_270+	一般男子 270+	20	\N	270	\N	m	男性、20歳以上、体力指数270以上	2025-06-28 06:42:52.267047+00
F_OPEN	一般女子オープン	20	\N	\N	\N	f	女性、20歳以上、体力指数制限なし	2025-06-28 06:42:52.267047+00
\.


--
-- Data for Name: league_brackets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.league_brackets (bracket_id, tournament_id, category_id, league_data, match_results_data, standings_data, created_at, updated_at) FROM stdin;
d7a8d00d-0eb1-4061-91c3-afea407371a6	20250920-01	M_240-	[{"sex": "m", "height": 1700, "status": "confirmed", "weight": 680, "xclass": "弐段", "birthday": "1997-09-05", "branch_id": "B005", "branch_nm": "日進", "firstname": "大輔", "player_id": "P005", "entry_date": "2025-07-08T00:21:38.341Z", "familyname": "小林", "firstname2": "ダイスケ", "category_id": "M_240-", "familyname2": "コバヤシ", "admissionday": "2013-11-15", "tournament_id": "20250920-01"}, {"sex": "m", "height": 1700, "status": "confirmed", "weight": 670, "xclass": "参段", "birthday": "1997-01-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "純", "player_id": "P033", "entry_date": "2025-06-30T03:45:55.349Z", "familyname": "原田", "firstname2": "ジュン", "category_id": "M_240-", "familyname2": "ハラダ", "admissionday": "2013-02-01", "tournament_id": "20250920-01"}, {"sex": "m", "height": 1700, "status": "confirmed", "weight": 650, "xclass": "参段", "birthday": "1990-01-01", "branch_id": "B006", "branch_nm": "長久手", "firstname": "一郎", "player_id": "P051", "entry_date": "2025-07-08T00:21:41.916Z", "familyname": "伊藤", "firstname2": "イチロウ", "category_id": "M_240-", "familyname2": "イトウ", "admissionday": "2005-03-01", "tournament_id": "20250920-01"}, {"sex": "m", "height": 1750, "status": "confirmed", "weight": 600, "xclass": "二段", "birthday": "1990-09-25", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "誠", "player_id": "P011", "entry_date": "2025-06-30T03:45:52.801Z", "familyname": "井上", "firstname2": "マコト", "category_id": "M_240-", "familyname2": "イノウエ", "admissionday": "2008-04-01", "tournament_id": "20250920-01"}]	[{"score": "", "status": "未開始", "match_id": "M-P005-P011", "player1_id": "P005", "player2_id": "P011", "player1_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 680, "xclass": "弐段", "birthday": "1997-09-05", "branch_id": "B005", "branch_nm": "日進", "firstname": "大輔", "player_id": "P005", "entry_date": "2025-07-08T00:21:38.341Z", "familyname": "小林", "firstname2": "ダイスケ", "category_id": "M_240-", "familyname2": "コバヤシ", "admissionday": "2013-11-15", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1750, "status": "confirmed", "weight": 600, "xclass": "二段", "birthday": "1990-09-25", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "誠", "player_id": "P011", "entry_date": "2025-06-30T03:45:52.801Z", "familyname": "井上", "firstname2": "マコト", "category_id": "M_240-", "familyname2": "イノウエ", "admissionday": "2008-04-01", "tournament_id": "20250920-01"}}, {"score": "", "status": "未開始", "match_id": "M-P005-P051", "player1_id": "P005", "player2_id": "P051", "player1_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 680, "xclass": "弐段", "birthday": "1997-09-05", "branch_id": "B005", "branch_nm": "日進", "firstname": "大輔", "player_id": "P005", "entry_date": "2025-07-08T00:21:38.341Z", "familyname": "小林", "firstname2": "ダイスケ", "category_id": "M_240-", "familyname2": "コバヤシ", "admissionday": "2013-11-15", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 650, "xclass": "参段", "birthday": "1990-01-01", "branch_id": "B006", "branch_nm": "長久手", "firstname": "一郎", "player_id": "P051", "entry_date": "2025-07-08T00:21:41.916Z", "familyname": "伊藤", "firstname2": "イチロウ", "category_id": "M_240-", "familyname2": "イトウ", "admissionday": "2005-03-01", "tournament_id": "20250920-01"}}, {"score": "", "status": "未開始", "match_id": "M-P005-P033", "player1_id": "P005", "player2_id": "P033", "player1_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 680, "xclass": "弐段", "birthday": "1997-09-05", "branch_id": "B005", "branch_nm": "日進", "firstname": "大輔", "player_id": "P005", "entry_date": "2025-07-08T00:21:38.341Z", "familyname": "小林", "firstname2": "ダイスケ", "category_id": "M_240-", "familyname2": "コバヤシ", "admissionday": "2013-11-15", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 670, "xclass": "参段", "birthday": "1997-01-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "純", "player_id": "P033", "entry_date": "2025-06-30T03:45:55.349Z", "familyname": "原田", "firstname2": "ジュン", "category_id": "M_240-", "familyname2": "ハラダ", "admissionday": "2013-02-01", "tournament_id": "20250920-01"}}, {"score": "", "status": "未開始", "match_id": "M-P011-P051", "player1_id": "P011", "player2_id": "P051", "player1_data": {"sex": "m", "height": 1750, "status": "confirmed", "weight": 600, "xclass": "二段", "birthday": "1990-09-25", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "誠", "player_id": "P011", "entry_date": "2025-06-30T03:45:52.801Z", "familyname": "井上", "firstname2": "マコト", "category_id": "M_240-", "familyname2": "イノウエ", "admissionday": "2008-04-01", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 650, "xclass": "参段", "birthday": "1990-01-01", "branch_id": "B006", "branch_nm": "長久手", "firstname": "一郎", "player_id": "P051", "entry_date": "2025-07-08T00:21:41.916Z", "familyname": "伊藤", "firstname2": "イチロウ", "category_id": "M_240-", "familyname2": "イトウ", "admissionday": "2005-03-01", "tournament_id": "20250920-01"}}, {"score": "", "status": "未開始", "match_id": "M-P011-P033", "player1_id": "P011", "player2_id": "P033", "player1_data": {"sex": "m", "height": 1750, "status": "confirmed", "weight": 600, "xclass": "二段", "birthday": "1990-09-25", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "誠", "player_id": "P011", "entry_date": "2025-06-30T03:45:52.801Z", "familyname": "井上", "firstname2": "マコト", "category_id": "M_240-", "familyname2": "イノウエ", "admissionday": "2008-04-01", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 670, "xclass": "参段", "birthday": "1997-01-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "純", "player_id": "P033", "entry_date": "2025-06-30T03:45:55.349Z", "familyname": "原田", "firstname2": "ジュン", "category_id": "M_240-", "familyname2": "ハラダ", "admissionday": "2013-02-01", "tournament_id": "20250920-01"}}, {"score": "", "status": "未開始", "match_id": "M-P051-P033", "player1_id": "P051", "player2_id": "P033", "player1_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 650, "xclass": "参段", "birthday": "1990-01-01", "branch_id": "B006", "branch_nm": "長久手", "firstname": "一郎", "player_id": "P051", "entry_date": "2025-07-08T00:21:41.916Z", "familyname": "伊藤", "firstname2": "イチロウ", "category_id": "M_240-", "familyname2": "イトウ", "admissionday": "2005-03-01", "tournament_id": "20250920-01"}, "player2_data": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 670, "xclass": "参段", "birthday": "1997-01-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "純", "player_id": "P033", "entry_date": "2025-06-30T03:45:55.349Z", "familyname": "原田", "firstname2": "ジュン", "category_id": "M_240-", "familyname2": "ハラダ", "admissionday": "2013-02-01", "tournament_id": "20250920-01"}}]	{"P005": {"wins": 0, "draws": 0, "losses": 0, "points": 0, "player_id": "P005", "player_name": "小林 大輔（日進） 弐段"}, "P011": {"wins": 0, "draws": 0, "losses": 0, "points": 0, "player_id": "P011", "player_name": "井上 誠（大阪北支部） 二段"}, "P033": {"wins": 0, "draws": 0, "losses": 0, "points": 0, "player_id": "P033", "player_name": "原田 純（日進） 参段"}, "P051": {"wins": 0, "draws": 0, "losses": 0, "points": 0, "player_id": "P051", "player_name": "伊藤 一郎（長久手） 参段"}}	2025-07-08 00:22:26.04745+00	2025-07-08 00:24:00.932559+00
\.


--
-- Data for Name: player_m; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_m (branch_id, player_id, familyname, familyname2, firstname, firstname2, sex, birthday, admissionday, xclass, height, weight, remarks, created) FROM stdin;
B001	P001	山田	ヤマダ	太郎	タロウ	m	2017-01-01	2023-04-01	10級	1300	300	U9適格	2025-06-28 06:42:52.267047+00
B002	P002	佐藤	サトウ	花子	ハナコ	f	2018-03-15	2023-05-01	10級	1250	280	U9適格	2025-06-28 06:42:52.267047+00
B001	P003	田中	タナカ	一郎	イチロウ	m	2014-06-20	2022-09-01	8級	1450	400	U12適格	2025-06-28 06:42:52.267047+00
B003	P004	鈴木	スズキ	美咲	ミサキ	f	2015-02-10	2022-10-01	8級	1400	380	U12適格	2025-06-28 06:42:52.267047+00
B001	P005	高橋	タカハシ	健太	ケンタ	m	2010-04-05	2020-04-01	5級	1600	500	U16適格(体力指数210)	2025-06-28 06:42:52.267047+00
B002	P006	中村	ナカムラ	優子	ユウコ	f	2011-08-01	2021-06-01	5級	1550	450	U16適格(体力指数200)	2025-06-28 06:42:52.267047+00
B003	P007	小林	コバヤシ	大輔	ダイスケ	m	2010-11-20	2020-09-01	4級	1650	600	U16適格(体力指数225)	2025-06-28 06:42:52.267047+00
B001	P008	加藤	カトウ	あかり	アカリ	f	2007-07-07	2018-04-01	3級	1600	550	U19適格(体力指数215)	2025-06-28 06:42:52.267047+00
B004	P009	吉田	ヨシダ	拓也	タクヤ	m	2008-01-01	2019-03-01	3級	1700	650	U19適格(体力指数235)	2025-06-28 06:42:52.267047+00
B002	P011	井上	イノウエ	誠	マコト	m	1990-09-25	2008-04-01	二段	1750	600	一般男子適格(体力指数235)	2025-06-28 06:42:52.267047+00
B003	P012	木村	キムラ	翔太	ショウタ	m	1988-12-01	2006-04-01	三段	1800	650	一般男子適格(体力指数245)	2025-06-28 06:42:52.267047+00
B004	P013	林	ハヤシ	勇気	ユウキ	m	1985-03-03	2005-04-01	四段	1850	700	一般男子適格(体力指数255)	2025-06-28 06:42:52.267047+00
B001	P014	斎藤	サイトウ	竜馬	リョウマ	m	1980-07-12	2000-04-01	五段	1900	800	一般男子適格(体力指数270)	2025-06-28 06:42:52.267047+00
B002	P015	渡辺	ワタナベ	彩	アヤ	f	1998-11-11	2018-04-01	初段	1600	500	一般女子適格	2025-06-28 06:42:52.267047+00
B003	P016	橋本	ハシモト	恵	メグミ	f	1992-02-28	2012-04-01	二段	1650	550	一般女子適格	2025-06-28 06:42:52.267047+00
B005	P001	田中	タナカ	太郎	タロウ	m	1995-03-15	2010-04-01	参段	1750	700	備考1	2025-06-30 00:19:27.653839+00
B005	P002	佐藤	サトウ	花子	ハナコ	f	1998-07-22	2015-09-01	弐段	1620	550	備考2	2025-06-30 00:19:27.653839+00
B005	P003	鈴木	スズキ	健太	ケンタ	m	1993-11-01	2008-05-10	四段	1800	850	備考3	2025-06-30 00:19:27.653839+00
B005	P004	高橋	タカハシ	美咲	ミサキ	f	2000-01-20	2018-03-01	初段	1580	520	備考4	2025-06-30 00:19:27.653839+00
B005	P005	小林	コバヤシ	大輔	ダイスケ	m	1997-09-05	2013-11-15	弐段	1700	680	備考5	2025-06-30 00:19:27.653839+00
B005	P006	渡辺	ワタナベ	優子	ユウコ	f	1996-04-10	2011-06-20	参段	1650	580	備考6	2025-06-30 00:19:27.653839+00
B005	P007	中村	ナカムラ	翼	ツバサ	m	1999-12-03	2016-01-01	初段	1720	720	備考7	2025-06-30 00:19:27.653839+00
B005	P008	山本	ヤマモト	彩	アヤ	f	2001-06-18	2019-07-01	無級	1600	500	備考8	2025-06-30 00:19:27.653839+00
B005	P009	加藤	カトウ	拓海	タクミ	m	1994-02-28	2009-03-01	五段	1820	900	備考9	2025-06-30 00:19:27.653839+00
B005	P010	吉田	ヨシダ	愛	アイ	f	1997-08-08	2014-10-01	弐段	1680	600	備考10	2025-06-30 00:19:27.653839+00
B005	P011	山田	ヤマダ	晃	アキラ	m	1992-01-01	2007-02-01	参段	1780	750	備考11	2025-06-30 00:19:27.653839+00
B005	P012	佐々木	ササキ	恵	メグミ	f	1999-05-05	2017-06-01	初段	1630	560	備考12	2025-06-30 00:19:27.653839+00
B005	P013	井上	イノウエ	翔太	ショウタ	m	1996-10-25	2012-12-01	弐段	1730	730	備考13	2025-06-30 00:19:27.653839+00
B005	P014	木村	キムラ	真由美	マユミ	f	2002-03-03	2020-04-01	無級	1550	480	備考14	2025-06-30 00:19:27.653839+00
B005	P015	林	ハヤシ	悠太	ユウタ	m	1995-07-12	2011-08-01	四段	1850	920	備考15	2025-06-30 00:19:27.653839+00
B005	P016	斎藤	サイトウ	明美	アケミ	f	1998-11-11	2016-12-01	弐段	1670	590	備考16	2025-06-30 00:19:27.653839+00
B005	P017	清水	シミズ	剛	ツヨシ	m	1993-06-20	2008-07-01	参段	1760	780	備考17	2025-06-30 00:19:27.653839+00
B005	P018	森	モリ	香織	カオリ	f	2000-02-14	2018-03-10	初段	1610	530	備考18	2025-06-30 00:19:27.653839+00
B005	P019	池田	イケダ	亮	リョウ	m	1997-04-04	2013-05-01	弐段	1710	690	備考19	2025-06-30 00:19:27.653839+00
B005	P020	阿部	アベ	麻衣	マイ	f	1996-09-09	2012-10-01	参段	1640	570	備考20	2025-06-30 00:19:27.653839+00
B005	P021	橋本	ハシモト	淳	ジュン	m	1999-01-30	2017-02-01	初段	1740	740	備考21	2025-06-30 00:19:27.653839+00
B005	P022	山崎	ヤマザキ	結衣	ユイ	f	2001-08-28	2019-09-01	無級	1570	490	備考22	2025-06-30 00:19:27.653839+00
B005	P023	石川	イシカワ	隼人	ハヤト	m	1994-05-19	2009-06-01	五段	1830	910	備考23	2025-06-30 00:19:27.653839+00
B005	P024	中島	ナカジマ	玲奈	レナ	f	1997-10-10	2014-11-01	弐段	1690	610	備考24	2025-06-30 00:19:27.653839+00
B005	P025	藤田	フジタ	圭介	ケイスケ	m	1992-03-07	2007-04-01	参段	1790	760	備考25	2025-06-30 00:19:27.653839+00
B005	P026	岡田	オカダ	里奈	リナ	f	1999-07-07	2017-08-01	初段	1660	570	備考26	2025-06-30 00:19:27.653839+00
B005	P027	後藤	ゴトウ	健	ケン	m	1996-12-12	2012-01-01	弐段	1770	790	備考27	2025-06-30 00:19:27.653839+00
B005	P028	福田	フクダ	千尋	チヒロ	f	2002-05-25	2020-06-01	無級	1590	510	備考28	2025-06-30 00:19:27.653839+00
B005	P029	西村	ニシムラ	一馬	カズマ	m	1995-08-01	2011-09-01	四段	1810	880	備考29	2025-06-30 00:19:27.653839+00
B005	P030	佐藤	サトウ	沙織	サオリ	f	1998-04-14	2016-05-01	参段	1600	540	備考30	2025-06-30 00:19:27.653839+00
B005	P031	松本	マツモト	勇気	ユウキ	m	1993-09-29	2008-10-01	弐段	1740	710	備考31	2025-06-30 00:19:27.653839+00
B005	P032	三浦	ミウラ	由香	ユカ	f	2000-06-06	2018-07-01	初段	1620	560	備考32	2025-06-30 00:19:27.653839+00
B005	P033	原田	ハラダ	純	ジュン	m	1997-01-11	2013-02-01	参段	1700	670	備考33	2025-06-30 00:19:27.653839+00
B005	P034	高田	タカダ	咲	サキ	f	1996-03-23	2012-04-01	弐段	1650	580	備考34	2025-06-30 00:19:27.653839+00
B005	P035	中野	ナカノ	誠	マコト	m	1999-10-17	2017-11-01	初段	1780	800	備考35	2025-06-30 00:19:27.653839+00
B005	P036	大野	オオノ	美月	ミヅキ	f	2001-04-04	2019-05-01	無級	1580	500	備考36	2025-06-30 00:19:27.653839+00
B005	P037	杉山	スギヤマ	翔	ショウ	m	1994-08-18	2009-09-01	五段	1800	870	備考37	2025-06-30 00:19:27.653839+00
B005	P038	小川	オガワ	琴音	コトネ	f	1997-12-24	2014-01-01	弐段	1630	550	備考38	2025-06-30 00:19:27.653839+00
B005	P039	久保	クボ	勇人	ハヤト	m	1992-02-02	2007-03-01	参段	1750	720	備考39	2025-06-30 00:19:27.653839+00
B005	P040	松田	マツダ	陽菜	ハルナ	f	1999-09-01	2017-10-01	初段	1660	590	備考40	2025-06-30 00:19:27.653839+00
B005	P041	野村	ノムラ	晃司	コウジ	m	1996-05-15	2012-06-01	弐段	1720	700	備考41	2025-06-30 00:19:27.653839+00
B005	P042	竹内	タケウチ	咲良	サクラ	f	2002-01-01	2020-02-01	無級	1560	470	備考42	2025-06-30 00:19:27.653839+00
B005	P043	岡本	オカモト	圭	ケイ	m	1995-11-20	2011-12-01	四段	1840	930	備考43	2025-06-30 00:19:27.653839+00
B005	P044	吉田	ヨシダ	梨花	リカ	f	1998-06-26	2016-07-01	参段	1680	600	備考44	2025-06-30 00:19:27.653839+00
B005	P045	佐野	サノ	直樹	ナオキ	m	1993-04-09	2008-05-01	弐段	1770	760	備考45	2025-06-30 00:19:27.653839+00
B005	P046	横山	ヨコヤマ	葵	アオイ	f	2000-10-05	2018-11-01	初段	1600	520	備考46	2025-06-30 00:19:27.653839+00
B005	P047	川口	カワグチ	哲也	テツヤ	m	1997-03-13	2013-04-01	参段	1730	710	備考47	2025-06-30 00:19:27.653839+00
B005	P048	菊池	キクチ	美穂	ミホ	f	1996-08-08	2012-09-01	弐段	1640	570	備考48	2025-06-30 00:19:27.653839+00
B005	P049	高木	タカギ	雄大	ユウダイ	m	1999-07-01	2017-08-01	初段	1760	750	備考49	2025-06-30 00:19:27.653839+00
B005	P050	宮崎	ミヤザキ	遥	ハルカ	f	2001-02-28	2019-03-01	無級	1590	510	備考50	2025-06-30 00:19:27.653839+00
B006	P051	伊藤	イトウ	一郎	イチロウ	m	1990-01-01	2005-03-01	参段	1700	650	備考51	2025-06-30 00:22:52.80163+00
B006	P052	山本	ヤマモト	二葉	フタバ	f	1992-02-02	2008-04-01	弐段	1600	500	備考52	2025-06-30 00:22:52.80163+00
B006	P053	中野	ナカノ	三郎	サブロウ	m	1991-03-03	2006-05-01	四段	1780	750	備考53	2025-06-30 00:22:52.80163+00
B006	P054	小川	オガワ	四葉	ヨツバ	f	1994-04-04	2010-06-01	初段	1550	480	備考54	2025-06-30 00:22:52.80163+00
B006	P055	吉田	ヨシダ	五郎	ゴロウ	m	1993-05-05	2009-07-01	弐段	1720	680	備考55	2025-06-30 00:22:52.80163+00
B006	P056	田中	タナカ	六花	ロッカ	f	1996-06-06	2012-08-01	参段	1630	530	備考56	2025-06-30 00:22:52.80163+00
B006	P057	佐藤	サトウ	七朗	シチロウ	m	1995-07-07	2011-09-01	初段	1750	700	備考57	2025-06-30 00:22:52.80163+00
B006	P058	鈴木	スズキ	八重	ヤエ	f	1998-08-08	2014-10-01	無級	1580	490	備考58	2025-06-30 00:22:52.80163+00
B006	P059	高橋	タカハシ	九郎	クロウ	m	1997-09-09	2013-11-01	五段	1800	800	備考59	2025-06-30 00:22:52.80163+00
B006	P060	小林	コバヤシ	十和	トワ	f	2000-10-10	2016-12-01	弐段	1650	550	備考60	2025-06-30 00:22:52.80163+00
B006	P061	渡辺	ワタナベ	十一	ジュウイチ	m	1999-11-11	2015-01-01	参段	1730	720	備考61	2025-06-30 00:22:52.80163+00
B006	P062	中村	ナカムラ	十二	ジュウニ	f	2002-12-12	2018-02-01	初段	1610	510	備考62	2025-06-30 00:22:52.80163+00
B006	P063	山本	ヤマモト	十三	ジュウサン	m	2001-01-13	2017-03-01	弐段	1760	730	備考63	2025-06-30 00:22:52.80163+00
B006	P064	加藤	カトウ	十四	ジュウシ	f	2004-02-14	2020-04-01	無級	1570	470	備考64	2025-06-30 00:22:52.80163+00
B006	P065	吉田	ヨシダ	十五	ジュウゴ	m	2003-03-15	2019-05-01	四段	1820	850	備考65	2025-06-30 00:22:52.80163+00
B006	P066	山田	ヤマダ	十六	ジュウロク	f	2006-04-16	2022-06-01	弐段	1640	540	備考66	2025-06-30 00:22:52.80163+00
B006	P067	佐々木	ササキ	十七	ジュウシチ	m	2005-05-17	2021-07-01	参段	1710	690	備考67	2025-06-30 00:22:52.80163+00
B006	P068	井上	イノウエ	十八	ジュウハチ	f	2008-06-18	2024-08-01	初段	1590	500	備考68	2025-06-30 00:22:52.80163+00
B006	P069	木村	キムラ	十九	ジュウク	m	2007-07-19	2023-09-01	弐段	1740	710	備考69	2025-06-30 00:22:52.80163+00
B006	P070	林	ハヤシ	二十	ハタチ	f	2010-08-20	2026-10-01	無級	1560	460	備考70	2025-06-30 00:22:52.80163+00
B006	P071	斎藤	サイトウ	二十一	ニジュウイチ	m	2009-09-21	2025-11-01	五段	1850	900	備考71	2025-06-30 00:22:52.80163+00
B006	P072	清水	シミズ	二十二	ニジュウニ	f	2012-10-22	2028-12-01	弐段	1620	520	備考72	2025-06-30 00:22:52.80163+00
B006	P073	森	モリ	二十三	ニジュウサン	m	2011-11-23	2027-01-01	参段	1770	740	備考73	2025-06-30 00:22:52.80163+00
B006	P074	池田	イケダ	二十四	ニジュウシ	f	2014-12-24	2030-02-01	初段	1600	490	備考74	2025-06-30 00:22:52.80163+00
B006	P075	阿部	アベ	二十五	ニジュウゴ	m	2013-01-25	2029-03-01	弐段	1700	670	備考75	2025-06-30 00:22:52.80163+00
B006	P076	橋本	ハシモト	二十六	ニジュウロク	f	2016-02-26	2032-04-01	参段	1650	560	備考76	2025-06-30 00:22:52.80163+00
B006	P077	山崎	ヤマザキ	二十七	ニジュウシチ	m	2015-03-27	2031-05-01	初段	1790	780	備考77	2025-06-30 00:22:52.80163+00
B006	P078	石川	イシカワ	二十八	ニジュウハチ	f	2018-04-28	2034-06-01	無級	1550	450	備考78	2025-06-30 00:22:52.80163+00
B006	P079	中島	ナカジマ	二十九	ニジュウク	m	2017-05-29	2033-07-01	五段	1830	880	備考79	2025-06-30 00:22:52.80163+00
B006	P080	藤田	フジタ	三十	サンジュウ	f	2020-06-30	2036-08-01	弐段	1680	580	備考80	2025-06-30 00:22:52.80163+00
B006	P081	岡田	オカダ	三十一	サンジュウイチ	m	1989-01-01	2004-02-01	参段	1700	650	備考81	2025-06-30 00:22:52.80163+00
B006	P082	後藤	ゴトウ	三十二	サンジュウニ	f	1991-02-02	2007-03-01	弐段	1600	500	備考82	2025-06-30 00:22:52.80163+00
B006	P083	福田	フクダ	三十三	サンジュウサン	m	1990-03-03	2005-04-01	四段	1780	750	備考83	2025-06-30 00:22:52.80163+00
B006	P084	西村	ニシムラ	三十四	サンジュウシ	f	1993-04-04	2009-05-01	初段	1550	480	備考84	2025-06-30 00:22:52.80163+00
B006	P085	佐藤	サトウ	三十五	サンジュウゴ	m	1992-05-05	2008-06-01	弐段	1720	680	備考85	2025-06-30 00:22:52.80163+00
B006	P086	松本	マツモト	三十六	サンジュウロク	f	1995-06-06	2011-07-01	参段	1630	530	備考86	2025-06-30 00:22:52.80163+00
B006	P087	三浦	ミウラ	三十七	サンジュウシチ	m	1994-07-07	2010-08-01	初段	1750	700	備考87	2025-06-30 00:22:52.80163+00
B006	P088	原田	ハラダ	三十八	サンジュウハチ	f	1997-08-08	2013-09-01	無級	1580	490	備考88	2025-06-30 00:22:52.80163+00
B006	P089	高田	タカダ	三十九	サンジュウク	m	1996-09-09	2012-10-01	五段	1800	800	備考89	2025-06-30 00:22:52.80163+00
B006	P090	中野	ナカノ	四十	シジュウ	f	1999-10-10	2015-11-01	弐段	1650	550	備考90	2025-06-30 00:22:52.80163+00
B006	P091	大野	オオノ	四十一	シジュウイチ	m	1998-11-11	2014-12-01	参段	1730	720	備考91	2025-06-30 00:22:52.80163+00
B006	P092	杉山	スギヤマ	四十二	シジュウニ	f	2001-12-12	2017-01-01	初段	1610	510	備考92	2025-06-30 00:22:52.80163+00
B006	P093	小川	オガワ	四十三	シジュウサン	m	2000-01-13	2016-02-01	弐段	1760	730	備考93	2025-06-30 00:22:52.80163+00
B006	P094	久保	クボ	四十四	シジュウシ	f	2003-02-14	2019-03-01	無級	1570	470	備考94	2025-06-30 00:22:52.80163+00
B006	P095	松田	マツダ	四十五	シジュウゴ	m	2002-03-15	2018-04-01	四段	1820	850	備考95	2025-06-30 00:22:52.80163+00
B006	P096	野村	ノムラ	四十六	シジュウロク	f	2005-04-16	2021-05-01	弐段	1640	540	備考96	2025-06-30 00:22:52.80163+00
B006	P097	竹内	タケウチ	四十七	シジュウシチ	m	2004-05-17	2020-06-01	参段	1710	690	備考97	2025-06-30 00:22:52.80163+00
B006	P098	岡本	オカモト	四十八	シジュウハチ	f	2007-06-18	2023-07-01	初段	1590	500	備考98	2025-06-30 00:22:52.80163+00
B006	P099	吉田	ヨシダ	四十九	シジュウク	m	2006-07-19	2022-08-01	弐段	1740	710	備考99	2025-06-30 00:22:52.80163+00
B006	P100	佐野	サノ	五十	ゴジュウ	f	2009-08-20	2025-09-01	無級	1560	460	備考100	2025-06-30 00:22:52.80163+00
B006	P101	横山	ヨコヤマ	五十一	ゴジュウイチ	m	2008-09-21	2024-10-01	五段	1850	900	備考101	2025-06-30 00:22:52.80163+00
B006	P102	川口	カワグチ	五十二	ゴジュウニ	f	2011-10-22	2027-11-01	弐段	1620	520	備考102	2025-06-30 00:22:52.80163+00
B006	P103	菊池	キクチ	五十三	ゴジュウサン	m	2010-11-23	2026-12-01	参段	1770	740	備考103	2025-06-30 00:22:52.80163+00
B006	P104	高木	タカギ	五十四	ゴジュウシ	f	2013-12-24	2029-01-01	初段	1600	490	備考104	2025-06-30 00:22:52.80163+00
B006	P105	宮崎	ミヤザキ	五十五	ゴジュウゴ	m	2012-01-25	2028-02-01	弐段	1700	670	備考105	2025-06-30 00:22:52.80163+00
B006	P106	伊藤	イトウ	五十六	ゴジュウロク	f	2015-02-25	2031-03-01	参段	1650	560	備考106	2025-06-30 00:22:52.80163+00
B006	P107	山本	ヤマモト	五十七	ゴジュウシチ	m	2014-03-27	2030-04-01	初段	1790	780	備考107	2025-06-30 00:22:52.80163+00
B006	P108	中野	ナカノ	五十八	ゴジュウハチ	f	2017-04-28	2033-05-01	無級	1550	450	備考108	2025-06-30 00:22:52.80163+00
B006	P109	小川	オガワ	五十九	ゴジュウク	m	2016-05-29	2032-06-01	五段	1830	880	備考109	2025-06-30 00:22:52.80163+00
B006	P110	吉田	ヨシダ	六十	ロクジュウ	f	2019-06-30	2035-07-01	弐段	1680	580	備考110	2025-06-30 00:22:52.80163+00
B006	P111	田中	タナカ	六十一	ロクジュウイチ	m	1988-01-01	2003-02-01	参段	1700	650	備考111	2025-06-30 00:22:52.80163+00
B006	P112	佐藤	サトウ	六十二	ロクジュウニ	f	1990-02-02	2006-03-01	弐段	1600	500	備考112	2025-06-30 00:22:52.80163+00
B006	P113	鈴木	スズキ	六十三	ロクジュウサン	m	1989-03-03	2004-04-01	四段	1780	750	備考113	2025-06-30 00:22:52.80163+00
B006	P114	高橋	タカハシ	六十四	ロクジュウシ	f	1992-04-04	2008-05-01	初段	1550	480	備考114	2025-06-30 00:22:52.80163+00
B006	P115	小林	コバヤシ	六十五	ロクジュウゴ	m	1991-05-05	2007-06-01	弐段	1720	680	備考115	2025-06-30 00:22:52.80163+00
B006	P116	渡辺	ワタナベ	六十六	ロクジュウロク	f	1994-06-06	2010-07-01	参段	1630	530	備考116	2025-06-30 00:22:52.80163+00
B006	P117	中村	ナカムラ	六十七	ロクジュウシチ	m	1993-07-07	2009-08-01	初段	1750	700	備考117	2025-06-30 00:22:52.80163+00
B006	P118	山本	ヤマモト	六十八	ロクジュウハチ	f	1996-08-08	2012-09-01	無級	1580	490	備考118	2025-06-30 00:22:52.80163+00
B006	P119	加藤	カトウ	六十九	ロクジュウク	m	1995-09-09	2011-10-01	五段	1800	800	備考119	2025-06-30 00:22:52.80163+00
B006	P120	吉田	ヨシダ	七十	ナナジュウ	f	1998-10-10	2014-11-01	弐段	1650	550	備考120	2025-06-30 00:22:52.80163+00
B006	P121	山田	ヤマダ	七十一	ナナジュウイチ	m	1997-11-11	2013-12-01	参段	1730	720	備考121	2025-06-30 00:22:52.80163+00
B006	P122	佐々木	ササキ	七十二	ナナジュウニ	f	2000-12-12	2016-01-01	初段	1610	510	備考122	2025-06-30 00:22:52.80163+00
B006	P123	井上	イノウエ	七十三	ナナジュウサン	m	1999-01-13	2015-02-01	弐段	1760	730	備考123	2025-06-30 00:22:52.80163+00
B006	P124	木村	キムラ	七十四	ナナジュウシ	f	2002-02-14	2018-03-01	無級	1570	470	備考124	2025-06-30 00:22:52.80163+00
B006	P125	林	ハヤシ	七十五	ナナジュウゴ	m	2001-03-15	2017-04-01	四段	1820	850	備考125	2025-06-30 00:22:52.80163+00
B006	P126	斎藤	サイトウ	七十六	ナナジュウロク	f	2004-04-16	2020-05-01	弐段	1640	540	備考126	2025-06-30 00:22:52.80163+00
B006	P127	清水	シミズ	七十七	ナナジュウシチ	m	2003-05-17	2019-06-01	参段	1710	690	備考127	2025-06-30 00:22:52.80163+00
B006	P128	森	モリ	七十八	ナナジュウハチ	f	2006-06-18	2022-07-01	初段	1590	500	備考128	2025-06-30 00:22:52.80163+00
B006	P129	池田	イケダ	七十九	ナナジュウク	m	2005-07-19	2021-08-01	弐段	1740	710	備考129	2025-06-30 00:22:52.80163+00
B006	P130	阿部	アベ	八十	ハチジュウ	f	2008-08-20	2024-09-01	無級	1560	460	備考130	2025-06-30 00:22:52.80163+00
B001	P010	山本	ヤマモト	剛	ツヨシ	m	1995-05-10	2010-04-01	初段	1700	550	一般男子適格(体力指数225)	2025-06-28 06:42:52.267047+00
B002	P016	大阪	オオサカ	寅吉	トラキチ	m	2004-05-30	2019-06-30	3級	1680	600		2025-07-01 02:57:59.247359+00
\.


--
-- Data for Name: tournament_brackets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_brackets (bracket_id, tournament_id, category_id, bracket_data, final_winner_data, created_at, updated_at) FROM stdin;
4e7ff5df-2afe-4b3f-838c-15a1fbaefadb	20250920-01	M_230-	[[{"matchId": "R1-M1", "player1": {"sex": "m", "height": 1680, "status": "confirmed", "weight": 600, "xclass": "3級", "birthday": "2004-05-30", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "寅吉", "player_id": "P016", "entry_date": "2025-07-01T02:59:32.237Z", "familyname": "大阪", "firstname2": "トラキチ", "category_id": "M_230-", "familyname2": "オオサカ", "admissionday": "2019-06-30", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 550, "xclass": "初段", "birthday": "1995-05-10", "branch_id": "B001", "branch_nm": "東京城南支部", "firstname": "剛", "player_id": "P010", "entry_date": "2025-07-01T02:58:33.304Z", "familyname": "山本", "firstname2": "ツヨシ", "category_id": "M_230-", "familyname2": "ヤマモト", "admissionday": "2010-04-01", "tournament_id": "20250920-01"}}]]	{"winnerOf": "R1-M1", "isWinnerPlaceholder": true}	2025-07-03 00:01:39.568639+00	2025-07-03 09:58:54.348277+00
93bed5e6-bbaa-4fa6-9384-d74f9ee47b76	20250920-01	M_240-	[[{"matchId": "R1-M1", "player1": {"sex": "m", "height": 1750, "status": "confirmed", "weight": 600, "xclass": "二段", "birthday": "1990-09-25", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "誠", "player_id": "P011", "entry_date": "2025-06-30T03:45:52.801Z", "familyname": "井上", "firstname2": "マコト", "category_id": "M_240-", "familyname2": "イノウエ", "admissionday": "2008-04-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1700, "status": "confirmed", "weight": 670, "xclass": "参段", "birthday": "1997-01-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "純", "player_id": "P033", "entry_date": "2025-06-30T03:45:55.349Z", "familyname": "原田", "firstname2": "ジュン", "category_id": "M_240-", "familyname2": "ハラダ", "admissionday": "2013-02-01", "tournament_id": "20250920-01"}}]]	{"winnerOf": "R1-M1", "isWinnerPlaceholder": true}	2025-07-03 00:30:46.054019+00	2025-07-03 09:59:21.957614+00
e5a2e4d3-d0b9-43ad-a730-551f5c4e9485	20250920-01	F_OPEN	[[{"matchId": "R1-M1", "player1": {"sex": "f", "height": 1600, "status": "confirmed", "weight": 500, "xclass": "初段", "birthday": "1998-11-11", "branch_id": "B002", "branch_nm": "大阪北支部", "firstname": "彩", "player_id": "P015", "entry_date": "2025-07-01T02:40:10.282Z", "familyname": "渡辺", "firstname2": "アヤ", "category_id": "F_OPEN", "familyname2": "ワタナベ", "admissionday": "2018-04-01", "tournament_id": "20250920-01"}, "player2": {"sex": "f", "height": 1550, "status": "confirmed", "weight": 480, "xclass": "無級", "birthday": "2002-03-03", "branch_id": "B005", "branch_nm": "日進", "firstname": "真由美", "player_id": "P014", "entry_date": "2025-07-01T02:40:38.583Z", "familyname": "木村", "firstname2": "マユミ", "category_id": "F_OPEN", "familyname2": "キムラ", "admissionday": "2020-04-01", "tournament_id": "20250920-01"}}, {"matchId": "R1-M2", "player1": {"sex": "f", "height": 1650, "status": "confirmed", "weight": 580, "xclass": "参段", "birthday": "1996-04-10", "branch_id": "B005", "branch_nm": "日進", "firstname": "優子", "player_id": "P006", "entry_date": "2025-07-01T02:40:17.293Z", "familyname": "渡辺", "firstname2": "ユウコ", "category_id": "F_OPEN", "familyname2": "ワタナベ", "admissionday": "2011-06-20", "tournament_id": "20250920-01"}, "player2": {"sex": "f", "height": 1630, "status": "confirmed", "weight": 560, "xclass": "初段", "birthday": "1999-05-05", "branch_id": "B005", "branch_nm": "日進", "firstname": "恵", "player_id": "P012", "entry_date": "2025-07-01T02:40:20.752Z", "familyname": "佐々木", "firstname2": "メグミ", "category_id": "F_OPEN", "familyname2": "ササキ", "admissionday": "2017-06-01", "tournament_id": "20250920-01"}}, {"matchId": "R1-M3", "player1": {"sex": "f", "height": 1620, "status": "confirmed", "weight": 550, "xclass": "弐段", "birthday": "1998-07-22", "branch_id": "B005", "branch_nm": "日進", "firstname": "花子", "player_id": "P002", "entry_date": "2025-07-01T02:40:13.399Z", "familyname": "佐藤", "firstname2": "ハナコ", "category_id": "F_OPEN", "familyname2": "サトウ", "admissionday": "2015-09-01", "tournament_id": "20250920-01"}, "player2": {"sex": "f", "height": 1600, "status": "confirmed", "weight": 500, "xclass": "無級", "birthday": "2001-06-18", "branch_id": "B005", "branch_nm": "日進", "firstname": "彩", "player_id": "P008", "entry_date": "2025-07-01T02:40:23.834Z", "familyname": "山本", "firstname2": "アヤ", "category_id": "F_OPEN", "familyname2": "ヤマモト", "admissionday": "2019-07-01", "tournament_id": "20250920-01"}}, {"matchId": "R1-M4", "player1": {"sex": "f", "height": 1670, "status": "confirmed", "weight": 590, "xclass": "弐段", "birthday": "1998-11-11", "branch_id": "B005", "branch_nm": "日進", "firstname": "明美", "player_id": "P016", "entry_date": "2025-07-01T02:40:30.695Z", "familyname": "斎藤", "firstname2": "アケミ", "category_id": "F_OPEN", "familyname2": "サイトウ", "admissionday": "2016-12-01", "tournament_id": "20250920-01"}, "player2": {"sex": "f", "height": 1610, "status": "confirmed", "weight": 530, "xclass": "初段", "birthday": "2000-02-14", "branch_id": "B005", "branch_nm": "日進", "firstname": "香織", "player_id": "P018", "entry_date": "2025-07-01T02:40:26.741Z", "familyname": "森", "firstname2": "カオリ", "category_id": "F_OPEN", "familyname2": "モリ", "admissionday": "2018-03-10", "tournament_id": "20250920-01"}}], [{"matchId": "R2-M5", "player1": {"winnerOf": "R1-M1", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R1-M2", "isWinnerPlaceholder": true}}, {"matchId": "R2-M6", "player1": {"winnerOf": "R1-M3", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R1-M4", "isWinnerPlaceholder": true}}], [{"matchId": "R3-M7", "player1": {"winnerOf": "R2-M5", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R2-M6", "isWinnerPlaceholder": true}}]]	{"winnerOf": "R3-M7", "isWinnerPlaceholder": true}	2025-07-03 09:30:05.082104+00	2025-07-03 09:30:32.754798+00
3f236d01-d236-4608-a483-46240cf5776e	20250920-01	M_250-	[[{"matchId": "R1-M1", "player1": {"sex": "m", "height": 1740, "status": "confirmed", "weight": 740, "xclass": "初段", "birthday": "1999-01-30", "branch_id": "B005", "branch_nm": "日進", "firstname": "淳", "player_id": "P021", "entry_date": "2025-06-30T03:46:08.231Z", "familyname": "橋本", "firstname2": "ジュン", "category_id": "M_250-", "familyname2": "ハシモト", "admissionday": "2017-02-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1800, "status": "confirmed", "weight": 650, "xclass": "三段", "birthday": "1988-12-01", "branch_id": "B003", "branch_nm": "名古屋栄支部", "firstname": "翔太", "player_id": "P012", "entry_date": "2025-06-30T03:46:05.542Z", "familyname": "木村", "firstname2": "ショウタ", "category_id": "M_250-", "familyname2": "キムラ", "admissionday": "2006-04-01", "tournament_id": "20250920-01"}}]]	{"winnerOf": "R1-M1", "isWinnerPlaceholder": true}	2025-07-03 09:59:37.273183+00	2025-07-03 10:00:02.774352+00
9d80f901-f2ac-43f1-b4bf-72970c61b95d	20250920-01	M_260-	[[{"matchId": "R1-M1", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 750, "xclass": "四段", "birthday": "1990-03-03", "branch_id": "B006", "branch_nm": "長久手", "firstname": "三十三", "player_id": "P083", "entry_date": "2025-06-30T05:29:50.233Z", "familyname": "福田", "firstname2": "サンジュウサン", "category_id": "M_260-", "familyname2": "フクダ", "admissionday": "2005-04-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M1", "name": "BYE", "isBye": true}}, {"matchId": "R1-M2", "player1": {"sex": "m", "height": 1760, "status": "confirmed", "weight": 780, "xclass": "参段", "birthday": "1993-06-20", "branch_id": "B005", "branch_nm": "日進", "firstname": "剛", "player_id": "P017", "entry_date": "2025-06-30T03:46:17.280Z", "familyname": "清水", "firstname2": "ツヨシ", "category_id": "M_260-", "familyname2": "シミズ", "admissionday": "2008-07-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M2", "name": "BYE", "isBye": true}}, {"matchId": "R1-M3", "player1": {"sex": "m", "height": 1760, "status": "confirmed", "weight": 750, "xclass": "初段", "birthday": "1999-07-01", "branch_id": "B005", "branch_nm": "日進", "firstname": "雄大", "player_id": "P049", "entry_date": "2025-06-30T05:29:43.604Z", "familyname": "高木", "firstname2": "ユウダイ", "category_id": "M_260-", "familyname2": "タカギ", "admissionday": "2017-08-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M3", "name": "BYE", "isBye": true}}, {"matchId": "R1-M4", "player1": {"sex": "m", "height": 1790, "status": "confirmed", "weight": 760, "xclass": "参段", "birthday": "1992-03-07", "branch_id": "B005", "branch_nm": "日進", "firstname": "圭介", "player_id": "P025", "entry_date": "2025-06-30T05:45:16.366Z", "familyname": "藤田", "firstname2": "ケイスケ", "category_id": "M_260-", "familyname2": "フジタ", "admissionday": "2007-04-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M4", "name": "BYE", "isBye": true}}, {"matchId": "R1-M5", "player1": {"sex": "m", "height": 1850, "status": "confirmed", "weight": 700, "xclass": "四段", "birthday": "1985-03-03", "branch_id": "B004", "branch_nm": "福岡博多支部", "firstname": "勇気", "player_id": "P013", "entry_date": "2025-06-30T03:46:14.859Z", "familyname": "林", "firstname2": "ユウキ", "category_id": "M_260-", "familyname2": "ハヤシ", "admissionday": "2005-04-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M5", "name": "BYE", "isBye": true}}, {"matchId": "R1-M6", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 750, "xclass": "参段", "birthday": "1992-01-01", "branch_id": "B005", "branch_nm": "日進", "firstname": "晃", "player_id": "P011", "entry_date": "2025-06-30T05:29:40.658Z", "familyname": "山田", "firstname2": "アキラ", "category_id": "M_260-", "familyname2": "ヤマダ", "admissionday": "2007-02-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M6", "name": "BYE", "isBye": true}}, {"matchId": "R1-M7", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 800, "xclass": "初段", "birthday": "1999-10-17", "branch_id": "B005", "branch_nm": "日進", "firstname": "誠", "player_id": "P035", "entry_date": "2025-06-30T05:45:36.888Z", "familyname": "中野", "firstname2": "マコト", "category_id": "M_260-", "familyname2": "ナカノ", "admissionday": "2017-11-01", "tournament_id": "20250920-01"}, "player2": {"id": "BYE_R1-M7", "name": "BYE", "isBye": true}}, {"matchId": "R1-M8", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 750, "xclass": "四段", "birthday": "1991-03-03", "branch_id": "B006", "branch_nm": "長久手", "firstname": "三郎", "player_id": "P053", "entry_date": "2025-06-30T05:44:45.941Z", "familyname": "中野", "firstname2": "サブロウ", "category_id": "M_260-", "familyname2": "ナカノ", "admissionday": "2006-05-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1770, "status": "confirmed", "weight": 790, "xclass": "弐段", "birthday": "1996-12-12", "branch_id": "B005", "branch_nm": "日進", "firstname": "健", "player_id": "P027", "entry_date": "2025-06-30T05:29:47.276Z", "familyname": "後藤", "firstname2": "ケン", "category_id": "M_260-", "familyname2": "ゴトウ", "admissionday": "2012-01-01", "tournament_id": "20250920-01"}}], [{"matchId": "R2-M9", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 750, "xclass": "四段", "birthday": "1990-03-03", "branch_id": "B006", "branch_nm": "長久手", "firstname": "三十三", "player_id": "P083", "entry_date": "2025-06-30T05:29:50.233Z", "familyname": "福田", "firstname2": "サンジュウサン", "category_id": "M_260-", "familyname2": "フクダ", "admissionday": "2005-04-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1760, "status": "confirmed", "weight": 780, "xclass": "参段", "birthday": "1993-06-20", "branch_id": "B005", "branch_nm": "日進", "firstname": "剛", "player_id": "P017", "entry_date": "2025-06-30T03:46:17.280Z", "familyname": "清水", "firstname2": "ツヨシ", "category_id": "M_260-", "familyname2": "シミズ", "admissionday": "2008-07-01", "tournament_id": "20250920-01"}}, {"matchId": "R2-M10", "player1": {"sex": "m", "height": 1760, "status": "confirmed", "weight": 750, "xclass": "初段", "birthday": "1999-07-01", "branch_id": "B005", "branch_nm": "日進", "firstname": "雄大", "player_id": "P049", "entry_date": "2025-06-30T05:29:43.604Z", "familyname": "高木", "firstname2": "ユウダイ", "category_id": "M_260-", "familyname2": "タカギ", "admissionday": "2017-08-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1790, "status": "confirmed", "weight": 760, "xclass": "参段", "birthday": "1992-03-07", "branch_id": "B005", "branch_nm": "日進", "firstname": "圭介", "player_id": "P025", "entry_date": "2025-06-30T05:45:16.366Z", "familyname": "藤田", "firstname2": "ケイスケ", "category_id": "M_260-", "familyname2": "フジタ", "admissionday": "2007-04-01", "tournament_id": "20250920-01"}}, {"matchId": "R2-M11", "player1": {"sex": "m", "height": 1850, "status": "confirmed", "weight": 700, "xclass": "四段", "birthday": "1985-03-03", "branch_id": "B004", "branch_nm": "福岡博多支部", "firstname": "勇気", "player_id": "P013", "entry_date": "2025-06-30T03:46:14.859Z", "familyname": "林", "firstname2": "ユウキ", "category_id": "M_260-", "familyname2": "ハヤシ", "admissionday": "2005-04-01", "tournament_id": "20250920-01"}, "player2": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 750, "xclass": "参段", "birthday": "1992-01-01", "branch_id": "B005", "branch_nm": "日進", "firstname": "晃", "player_id": "P011", "entry_date": "2025-06-30T05:29:40.658Z", "familyname": "山田", "firstname2": "アキラ", "category_id": "M_260-", "familyname2": "ヤマダ", "admissionday": "2007-02-01", "tournament_id": "20250920-01"}}, {"matchId": "R2-M12", "player1": {"sex": "m", "height": 1780, "status": "confirmed", "weight": 800, "xclass": "初段", "birthday": "1999-10-17", "branch_id": "B005", "branch_nm": "日進", "firstname": "誠", "player_id": "P035", "entry_date": "2025-06-30T05:45:36.888Z", "familyname": "中野", "firstname2": "マコト", "category_id": "M_260-", "familyname2": "ナカノ", "admissionday": "2017-11-01", "tournament_id": "20250920-01"}, "player2": {"winnerOf": "R1-M8", "isWinnerPlaceholder": true}}], [{"matchId": "R3-M13", "player1": {"winnerOf": "R2-M9", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R2-M10", "isWinnerPlaceholder": true}}, {"matchId": "R3-M14", "player1": {"winnerOf": "R2-M11", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R2-M12", "isWinnerPlaceholder": true}}], [{"matchId": "R4-M15", "player1": {"winnerOf": "R3-M13", "isWinnerPlaceholder": true}, "player2": {"winnerOf": "R3-M14", "isWinnerPlaceholder": true}}]]	{"winnerOf": "R4-M15", "isWinnerPlaceholder": true}	2025-07-03 10:00:23.918378+00	2025-07-03 10:00:23.918378+00
\.


--
-- Data for Name: tournament_category_map; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_category_map (tournament_id, category_id, created) FROM stdin;
20241020-01	U9	2025-06-28 06:42:52.267047+00
20241020-01	U12	2025-06-28 06:42:52.267047+00
20241020-01	U16_210	2025-06-28 06:42:52.267047+00
20241020-01	U16_230+	2025-06-28 06:42:52.267047+00
20241020-01	M_240-	2025-06-28 06:42:52.267047+00
20241020-01	M_270+	2025-06-28 06:42:52.267047+00
20241020-01	F_OPEN	2025-06-28 06:42:52.267047+00
20250715-01	U16_230	2025-06-28 06:42:52.267047+00
20250715-01	U19_230-	2025-06-28 06:42:52.267047+00
20250715-01	M_230-	2025-06-28 06:42:52.267047+00
20250715-01	F_OPEN	2025-06-28 06:42:52.267047+00
20250920-01	M_240-	2025-06-30 00:12:46.756471+00
20250920-01	M_230-	2025-06-30 00:12:50.355881+00
20250920-01	M_250-	2025-06-30 00:12:54.168679+00
20250920-01	M_260-	2025-06-30 00:12:57.429336+00
20250920-01	M_270+	2025-06-30 00:13:00.524899+00
20250920-01	F_OPEN	2025-07-01 02:39:57.684767+00
\.


--
-- Data for Name: tournament_m; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_m (tournament_id, tournament_nm, start_date, end_date, venue_id, number_coat, remarks, created) FROM stdin;
20241020-01	全国大会	2024-10-20 00:00:00+00	2024-10-21 08:00:00+00	V001	4	メインイベント	2024-09-01 01:00:00+00
20250715-01	夏季支部交流戦	2025-07-15 01:00:00+00	2025-07-15 08:00:00+00	V002	2	現在開催中の大会	2025-06-01 01:00:00+00
20250920-01	中部地区予選(2025/9/20)	2025-09-19 00:00:00+00	2025-09-19 00:00:00+00	V010	2	・11月開催北斗旗予選	2025-06-30 00:10:42.764976+00
\.


--
-- Data for Name: tournament_participant; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_participant (tournament_id, player_id, branch_id, category_id, entry_date, status) FROM stdin;
20241020-01	P001	B001	U9	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P002	B002	U9	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P003	B001	U12	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P004	B003	U12	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P006	B002	U16_210	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P011	B002	M_240-	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P014	B001	M_270+	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P015	B002	F_OPEN	2025-06-28 06:42:52.267047+00	confirmed
20241020-01	P016	B003	F_OPEN	2025-06-28 06:42:52.267047+00	confirmed
20250715-01	P007	B003	U16_230	2025-06-28 06:42:52.267047+00	confirmed
20250715-01	P008	B001	U19_230-	2025-06-28 06:42:52.267047+00	confirmed
20250715-01	P010	B001	M_230-	2025-06-28 06:42:52.267047+00	confirmed
20250715-01	P015	B002	F_OPEN	2025-06-28 06:42:52.267047+00	confirmed
20250920-01	P011	B002	M_240-	2025-06-30 03:45:52.801658+00	confirmed
20250920-01	P033	B005	M_240-	2025-06-30 03:45:55.349161+00	confirmed
20250920-01	P012	B003	M_250-	2025-06-30 03:46:05.542984+00	confirmed
20250920-01	P021	B005	M_250-	2025-06-30 03:46:08.231254+00	confirmed
20250920-01	P013	B004	M_260-	2025-06-30 03:46:14.859407+00	confirmed
20250920-01	P017	B005	M_260-	2025-06-30 03:46:17.280637+00	confirmed
20250920-01	P011	B005	M_260-	2025-06-30 05:29:40.658511+00	confirmed
20250920-01	P049	B005	M_260-	2025-06-30 05:29:43.604033+00	confirmed
20250920-01	P027	B005	M_260-	2025-06-30 05:29:47.276265+00	confirmed
20250920-01	P083	B006	M_260-	2025-06-30 05:29:50.233665+00	confirmed
20250920-01	P053	B006	M_260-	2025-06-30 05:44:45.941735+00	confirmed
20250920-01	P025	B005	M_260-	2025-06-30 05:45:16.366979+00	confirmed
20250920-01	P035	B005	M_260-	2025-06-30 05:45:36.888634+00	confirmed
20250920-01	P015	B002	F_OPEN	2025-07-01 02:40:10.282198+00	confirmed
20250920-01	P002	B005	F_OPEN	2025-07-01 02:40:13.399233+00	confirmed
20250920-01	P006	B005	F_OPEN	2025-07-01 02:40:17.293287+00	confirmed
20250920-01	P012	B005	F_OPEN	2025-07-01 02:40:20.752313+00	confirmed
20250920-01	P008	B005	F_OPEN	2025-07-01 02:40:23.834455+00	confirmed
20250920-01	P018	B005	F_OPEN	2025-07-01 02:40:26.741448+00	confirmed
20250920-01	P016	B005	F_OPEN	2025-07-01 02:40:30.695508+00	confirmed
20250920-01	P014	B005	F_OPEN	2025-07-01 02:40:38.583025+00	confirmed
20250920-01	P010	B001	M_230-	2025-07-01 02:58:33.30465+00	confirmed
20250920-01	P016	B002	M_230-	2025-07-01 02:59:32.237179+00	confirmed
20250920-01	P005	B005	M_240-	2025-07-08 00:21:38.341815+00	confirmed
20250920-01	P051	B006	M_240-	2025-07-08 00:21:41.916447+00	confirmed
\.


--
-- Data for Name: venue_m; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venue_m (venue_id, venue_nm, remarks, created) FROM stdin;
V001	東京武道館	メインアリーナ	2025-06-28 06:42:52.267047+00
V002	大阪市中央体育館	多目的ホール	2025-06-28 06:42:52.267047+00
V003	名古屋国際会議場	イベントホール	2025-06-28 06:42:52.267047+00
V004	福岡国際センター	展示場	2025-06-28 06:42:52.267047+00
V005	札幌コンベンションセンター	会議棟	2025-06-28 06:42:52.267047+00
V010	豊田大谷高校武道場	・2面 ・空調完備 ・観客席なし	2025-06-30 00:02:43.654249+00
\.


--
-- Name: branch_m branch_m_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branch_m
    ADD CONSTRAINT branch_m_pkey PRIMARY KEY (branch_id);


--
-- Name: category_m category_m_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_m
    ADD CONSTRAINT category_m_pkey PRIMARY KEY (category_id);


--
-- Name: league_brackets league_brackets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.league_brackets
    ADD CONSTRAINT league_brackets_pkey PRIMARY KEY (bracket_id);


--
-- Name: league_brackets league_brackets_tournament_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.league_brackets
    ADD CONSTRAINT league_brackets_tournament_id_category_id_key UNIQUE (tournament_id, category_id);


--
-- Name: player_m player_m_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_m
    ADD CONSTRAINT player_m_pkey PRIMARY KEY (branch_id, player_id);


--
-- Name: tournament_brackets tournament_brackets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_brackets
    ADD CONSTRAINT tournament_brackets_pkey PRIMARY KEY (bracket_id);


--
-- Name: tournament_category_map tournament_category_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_category_map
    ADD CONSTRAINT tournament_category_map_pkey PRIMARY KEY (tournament_id, category_id);


--
-- Name: tournament_m tournament_m_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_m
    ADD CONSTRAINT tournament_m_pkey PRIMARY KEY (tournament_id);


--
-- Name: tournament_participant tournament_participant_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_participant
    ADD CONSTRAINT tournament_participant_pkey PRIMARY KEY (tournament_id, player_id, branch_id);


--
-- Name: tournament_brackets unique_tournament_category; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_brackets
    ADD CONSTRAINT unique_tournament_category UNIQUE (tournament_id, category_id);


--
-- Name: venue_m venue_m_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venue_m
    ADD CONSTRAINT venue_m_pkey PRIMARY KEY (venue_id);


--
-- Name: tournament_brackets update_tournament_brackets_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_tournament_brackets_timestamp BEFORE UPDATE ON public.tournament_brackets FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: tournament_category_map fk_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_category_map
    ADD CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES public.category_m(category_id) ON DELETE RESTRICT;


--
-- Name: tournament_participant fk_player; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_participant
    ADD CONSTRAINT fk_player FOREIGN KEY (branch_id, player_id) REFERENCES public.player_m(branch_id, player_id) ON DELETE RESTRICT;


--
-- Name: tournament_category_map fk_tournament; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_category_map
    ADD CONSTRAINT fk_tournament FOREIGN KEY (tournament_id) REFERENCES public.tournament_m(tournament_id) ON DELETE CASCADE;


--
-- Name: tournament_participant fk_tournament_category_map; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_participant
    ADD CONSTRAINT fk_tournament_category_map FOREIGN KEY (tournament_id, category_id) REFERENCES public.tournament_category_map(tournament_id, category_id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE postgres OWNER TO postgres;

\connect postgres

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

