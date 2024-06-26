PGDMP   (                     |           projekt2    16.2    16.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    16911    projekt2    DATABASE     {   CREATE DATABASE projekt2 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Polish_Poland.1250';
    DROP DATABASE projekt2;
                postgres    false            �            1255    16912    oblicz_cene()    FUNCTION     �  CREATE FUNCTION public.oblicz_cene() RETURNS pg_trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE zamowienie_klienta
        SET cena_sumaryczna = (SELECT SUM(cena * ilosc_zamowiona) FROM "Zamowienie_klienta_szczegoly" WHERE id_zamowienia_klient = NEW.id_zamowienia_klient);
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE zamowienie_klienta
        SET cena_sumaryczna = (SELECT SUM(cena * ilosc_zamowiona) FROM "Zamowienie_klienta_szczegoly" WHERE id_zamowienia_klient = NEW.id_zamowienia_klient)
        WHERE id_zamowienia_klienta = NEW.id_zamowienia_klient;
    END IF;
    
    RETURN NEW;
END;$$;
 $   DROP FUNCTION public.oblicz_cene();
       public          postgres    false            
           1255    16913 &   przyjecie_zamowienia(integer, integer) 	   PROCEDURE     ,  CREATE PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer)
    LANGUAGE plpgsql
    AS $$BEGIN
    -- Sprawdzenie czy istnieje niezfinalizowane zamówienie o podanym id
    IF EXISTS (
        SELECT 1
        FROM "Zamowienie_do_magazynu"
        WHERE id_zamowienia = p_id_zamowienia
        AND id_pracownika_przyjmujacego IS NULL
    ) THEN
        -- Aktualizacja ilości dostępnych produktów
        UPDATE "Produkt"
        SET dostepna_ilosc = dostepna_ilosc + szczegol.ilosc_w_zamowienia
        FROM "Zamowienie_do_magazynu_szczegoly" szczegol
        WHERE szczegol.id_zamowienia_do_magazynu = p_id_zamowienia
        AND "Produkt".id_produktu = szczegol.id_produktu;

        -- Komunikat sukcesu
        RAISE NOTICE 'Zamówienie o ID % zostało przyjęte do magazynu.', p_id_zamowienia;
    ELSE
        -- Komunikat o braku niezfinalizowanego zamówienia o podanym ID
        RAISE EXCEPTION 'Nie znaleziono niezfinalizowanego zamówienia o podanym ID: %.', p_id_zamowienia;
    END IF;
END;$$;
 r   DROP PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer);
       public          postgres    false            �           0    0 d   PROCEDURE przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer)    ACL     &  REVOKE ALL ON PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer) FROM postgres;
GRANT ALL ON PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer) TO "Kierownik";
GRANT ALL ON PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer) TO "Sprzedawca";
GRANT ALL ON PROCEDURE public.przyjecie_zamowienia(IN p_id_zamowienia integer, IN p_id_pracownika_przyjmujacego integer) TO "Magazynier";
          public          postgres    false    266                       1255    16914    zapisz_cene()    FUNCTION     �  CREATE FUNCTION public.zapisz_cene() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE public.zamowienie_klienta z
        SET cena_sumaryczna = (
            SELECT SUM(s.ilosc_zamowiona * p.cena)
            FROM public."Zamowienie_klienta_szczegoly" s
            JOIN public."Produkt" p ON s.id_produktu = p.id_produktu
            WHERE s.id_zamowienia_klient = NEW.id_zamowienia_klient
        )
        WHERE z.id_zamowienia_klienta = NEW.id_zamowienia_klient;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.zamowienie_klienta z
        SET cena_sumaryczna = (
            SELECT SUM(s.ilosc_zamowiona * p.cena)
            FROM public."Zamowienie_klienta_szczegoly" s
            JOIN public."Produkt" p ON s.id_produktu = p.id_produktu
            WHERE s.id_zamowienia_klient = OLD.id_zamowienia_klient
        )
        WHERE z.id_zamowienia_klienta = OLD.id_zamowienia_klient;
    END IF;
    RETURN NEW;
END;
$$;
 $   DROP FUNCTION public.zapisz_cene();
       public          postgres    false            �           0    0    FUNCTION zapisz_cene()    ACL     <   GRANT ALL ON FUNCTION public.zapisz_cene() TO "Sprzedawca";
          public          postgres    false    261                       1255    16915    zmiana_ceny(integer, numeric) 	   PROCEDURE     �  CREATE PROCEDURE public.zmiana_ceny(IN id_temp integer DEFAULT 0, IN nowa_cena numeric DEFAULT 0)
    LANGUAGE plpgsql
    AS $$BEGIN
    IF EXISTS (SELECT * FROM public."Produkt" WHERE id_produktu = id_temp) THEN

        UPDATE public."Produkt"
        SET cena = nowa_cena
        WHERE id_produktu = id_temp;
        
        RAISE NOTICE 'Cena produktu o ID % została zmieniona.', id_temp;
    ELSE
        RAISE EXCEPTION 'Podane ID produktu lub stara cena są niepoprawne.';
    END IF;
END;$$;
 M   DROP PROCEDURE public.zmiana_ceny(IN id_temp integer, IN nowa_cena numeric);
       public          postgres    false            �           0    0 ?   PROCEDURE zmiana_ceny(IN id_temp integer, IN nowa_cena numeric)    ACL     d   GRANT ALL ON PROCEDURE public.zmiana_ceny(IN id_temp integer, IN nowa_cena numeric) TO "Kierownik";
          public          postgres    false    262                       1255    16916 .   zmiana_drugie_imie(integer, character varying) 	   PROCEDURE       CREATE PROCEDURE public.zmiana_drugie_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying)
    LANGUAGE plpgsql
    AS $$BEGIN
    IF EXISTS (SELECT * FROM public."Pracownik" WHERE id_pracownika = p_id_pracownika) THEN
        UPDATE public."Pracownik"
        SET drugie_imie = p_nowe_imie
        WHERE id_pracownika = p_id_pracownika;
        
        RAISE NOTICE 'Imię pracownika o ID % zostało zmienione.', p_id_pracownika;
    ELSE
        RAISE EXCEPTION 'Podane ID pracownika jest niepoprawne.';
    END IF;
END;$$;
 h   DROP PROCEDURE public.zmiana_drugie_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying);
       public          postgres    false            �           0    0 Z   PROCEDURE zmiana_drugie_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying)    ACL        GRANT ALL ON PROCEDURE public.zmiana_drugie_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying) TO "Kierownik";
          public          postgres    false    263                       1255    16917 ;   zmiana_hasla(integer, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.zmiana_hasla(IN id_temp integer DEFAULT 0, IN stare_haslo character varying DEFAULT 0, IN nowe_haslo character varying DEFAULT 0)
    LANGUAGE plpgsql
    AS $$BEGIN
    -- Sprawdzenie, czy podane stare hasło jest poprawne
    IF EXISTS (SELECT * FROM public."Pracownik" WHERE id_pracownika = id_temp AND haslo = stare_haslo) THEN
        -- Aktualizacja hasła pracownika
        UPDATE public."Pracownik"
        SET haslo = nowe_haslo
        WHERE id_pracownika = id_temp;
        
        RAISE NOTICE 'Hasło pracownika o ID % zostało zmienione.', id_temp;
    ELSE
        RAISE EXCEPTION 'Podane ID pracownika lub stare hasło są niepoprawne.';
    END IF;
END;$$;
 {   DROP PROCEDURE public.zmiana_hasla(IN id_temp integer, IN stare_haslo character varying, IN nowe_haslo character varying);
       public          postgres    false            �           0    0 m   PROCEDURE zmiana_hasla(IN id_temp integer, IN stare_haslo character varying, IN nowe_haslo character varying)    ACL     �  GRANT ALL ON PROCEDURE public.zmiana_hasla(IN id_temp integer, IN stare_haslo character varying, IN nowe_haslo character varying) TO "Kierownik";
GRANT ALL ON PROCEDURE public.zmiana_hasla(IN id_temp integer, IN stare_haslo character varying, IN nowe_haslo character varying) TO "Magazynier";
GRANT ALL ON PROCEDURE public.zmiana_hasla(IN id_temp integer, IN stare_haslo character varying, IN nowe_haslo character varying) TO "Sprzedawca";
          public          postgres    false    264            �            1255    16918 '   zmiana_imie(integer, character varying) 	   PROCEDURE       CREATE PROCEDURE public.zmiana_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying)
    LANGUAGE plpgsql
    AS $$BEGIN
    IF EXISTS (SELECT * FROM public."Pracownik" WHERE id_pracownika = p_id_pracownika) THEN
        UPDATE public."Pracownik"
        SET imie = p_nowe_imie
        WHERE id_pracownika = p_id_pracownika;
        
        RAISE NOTICE 'Imię pracownika o ID % zostało zmienione.', p_id_pracownika;
    ELSE
        RAISE EXCEPTION 'Podane ID pracownika jest niepoprawne.';
    END IF;
END;$$;
 a   DROP PROCEDURE public.zmiana_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying);
       public          postgres    false            �           0    0 S   PROCEDURE zmiana_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying)    ACL     x   GRANT ALL ON PROCEDURE public.zmiana_imie(IN p_id_pracownika integer, IN p_nowe_imie character varying) TO "Kierownik";
          public          postgres    false    255                        1255    16919 5   zmiana_jednostki_produktu(integer, character varying) 	   PROCEDURE       CREATE PROCEDURE public.zmiana_jednostki_produktu(IN p_id_produktu integer, IN p_nowa_jednostka character varying)
    LANGUAGE plpgsql
    AS $$BEGIN

    IF EXISTS (SELECT * FROM public."Produkt" WHERE id_produktu = p_id_produktu) THEN

        UPDATE public."Produkt"
        SET jednostka = p_nowa_jednostka
        WHERE id_produktu = p_id_produktu;
        
        RAISE NOTICE 'Jednostka produktu o ID % została zmieniona.', p_id_produktu;
    ELSE
        RAISE EXCEPTION 'Podane ID produktu jest niepoprawne.';
    END IF;
END;$$;
 r   DROP PROCEDURE public.zmiana_jednostki_produktu(IN p_id_produktu integer, IN p_nowa_jednostka character varying);
       public          postgres    false            �           0    0 d   PROCEDURE zmiana_jednostki_produktu(IN p_id_produktu integer, IN p_nowa_jednostka character varying)    ACL     �   GRANT ALL ON PROCEDURE public.zmiana_jednostki_produktu(IN p_id_produktu integer, IN p_nowa_jednostka character varying) TO "Kierownik";
          public          postgres    false    256                       1255    16920 5   zmiana_kategorii_produktu(integer, character varying) 	   PROCEDURE       CREATE PROCEDURE public.zmiana_kategorii_produktu(IN p_id_produktu integer, IN p_nowa_kategoria character varying)
    LANGUAGE plpgsql
    AS $$BEGIN

    IF EXISTS (SELECT * FROM public."Produkt" WHERE id_produktu = p_id_produktu) THEN

        UPDATE public."Produkt"
        SET kategoria = p_nowa_kategoria
        WHERE id_produktu = p_id_produktu;
        
        RAISE NOTICE 'Kategoria produktu o ID % została zmieniona.', p_id_produktu;
    ELSE
        RAISE EXCEPTION 'Podane ID produktu jest niepoprawne.';
    END IF;
END;$$;
 r   DROP PROCEDURE public.zmiana_kategorii_produktu(IN p_id_produktu integer, IN p_nowa_kategoria character varying);
       public          postgres    false            �           0    0 d   PROCEDURE zmiana_kategorii_produktu(IN p_id_produktu integer, IN p_nowa_kategoria character varying)    ACL     �   GRANT ALL ON PROCEDURE public.zmiana_kategorii_produktu(IN p_id_produktu integer, IN p_nowa_kategoria character varying) TO "Kierownik";
          public          postgres    false    257                       1255    16921 (   zmiana_login(integer, character varying) 	   PROCEDURE       CREATE PROCEDURE public.zmiana_login(IN p_id_pracownika integer, IN p_nowe_login character varying)
    LANGUAGE plpgsql
    AS $$BEGIN
    IF EXISTS (SELECT * FROM public."Pracownik" WHERE id_pracownika = p_id_pracownika) THEN
        UPDATE public."Pracownik"
        SET login = p_nowe_login
        WHERE id_pracownika = p_id_pracownika;
        
        RAISE NOTICE 'Login pracownika o ID % zostało zmienione.', p_id_pracownika;
    ELSE
        RAISE EXCEPTION 'Podane ID pracownika jest niepoprawne.';
    END IF;
END;$$;
 c   DROP PROCEDURE public.zmiana_login(IN p_id_pracownika integer, IN p_nowe_login character varying);
       public          postgres    false            �           0    0 U   PROCEDURE zmiana_login(IN p_id_pracownika integer, IN p_nowe_login character varying)    ACL     z   GRANT ALL ON PROCEDURE public.zmiana_login(IN p_id_pracownika integer, IN p_nowe_login character varying) TO "Kierownik";
          public          postgres    false    258                       1255    16922 +   zmiana_nazwisko(integer, character varying) 	   PROCEDURE     "  CREATE PROCEDURE public.zmiana_nazwisko(IN p_id_pracownika integer, IN p_nowe_nazwisko character varying)
    LANGUAGE plpgsql
    AS $$BEGIN
    IF EXISTS (SELECT * FROM public."Pracownik" WHERE id_pracownika = p_id_pracownika) THEN
        UPDATE public."Pracownik"
        SET nazwisko = p_nowe_nazwisko
        WHERE id_pracownika = p_id_pracownika;
        
        RAISE NOTICE 'Nazwisko pracownika o ID % zostało zmienione.', p_id_pracownika;
    ELSE
        RAISE EXCEPTION 'Podane ID pracownika jest niepoprawne.';
    END IF;
END;$$;
 i   DROP PROCEDURE public.zmiana_nazwisko(IN p_id_pracownika integer, IN p_nowe_nazwisko character varying);
       public          postgres    false            �           0    0 [   PROCEDURE zmiana_nazwisko(IN p_id_pracownika integer, IN p_nowe_nazwisko character varying)    ACL     �   GRANT ALL ON PROCEDURE public.zmiana_nazwisko(IN p_id_pracownika integer, IN p_nowe_nazwisko character varying) TO "Kierownik";
          public          postgres    false    259                       1255    16923 1   zmiana_nazwy_produktu(integer, character varying) 	   PROCEDURE     
  CREATE PROCEDURE public.zmiana_nazwy_produktu(IN p_id_produktu integer, IN p_nowa_nazwa character varying)
    LANGUAGE plpgsql
    AS $$BEGIN

    IF EXISTS (SELECT * FROM public."Produkt" WHERE id_produktu = p_id_produktu) THEN

        UPDATE public."Produkt"
        SET nazwa = p_nowa_nazwa
        WHERE id_produktu = p_id_produktu;
        
        RAISE NOTICE 'Nazwa produktu o ID % została zmieniona.', p_id_produktu;
    ELSE
        RAISE EXCEPTION 'Podane ID produktu jest niepoprawne.';
    END IF;
END;$$;
 j   DROP PROCEDURE public.zmiana_nazwy_produktu(IN p_id_produktu integer, IN p_nowa_nazwa character varying);
       public          postgres    false            �           0    0 \   PROCEDURE zmiana_nazwy_produktu(IN p_id_produktu integer, IN p_nowa_nazwa character varying)    ACL     �   GRANT ALL ON PROCEDURE public.zmiana_nazwy_produktu(IN p_id_produktu integer, IN p_nowa_nazwa character varying) TO "Kierownik";
          public          postgres    false    260            	           1255    16924 +   zmiana_popularnosci_produktu(integer, real) 	   PROCEDURE     �  CREATE PROCEDURE public.zmiana_popularnosci_produktu(IN p_id_produktu integer, IN p_nowa_popularnosc real)
    LANGUAGE plpgsql
    AS $$BEGIN

    IF EXISTS (SELECT * FROM public."Produkt" WHERE id_produktu = p_id_produktu) THEN

		IF p_nowa_popularnosc <= 1 AND p_nowa_popularnosc >= 0 THEN

        	UPDATE public."Produkt"
        	SET popularnosc = p_nowa_popularnosc
        	WHERE id_produktu = p_id_produktu;
        
        	RAISE NOTICE 'Popularnosc produktu o ID % została zmieniona.', p_id_produktu;
	    ELSE
        	RAISE EXCEPTION 'Wartosc jest poza zakresem.';
    	END IF;
	ELSE
		RAISE EXCEPTION 'Podane ID produktu jest niepoprawne.';
	END IF;
END;

$$;
 j   DROP PROCEDURE public.zmiana_popularnosci_produktu(IN p_id_produktu integer, IN p_nowa_popularnosc real);
       public          postgres    false            �           0    0 \   PROCEDURE zmiana_popularnosci_produktu(IN p_id_produktu integer, IN p_nowa_popularnosc real)    ACL     �   GRANT ALL ON PROCEDURE public.zmiana_popularnosci_produktu(IN p_id_produktu integer, IN p_nowa_popularnosc real) TO "Kierownik";
          public          postgres    false    265            �            1259    16925    Decyzja    TABLE     s   CREATE TABLE public."Decyzja" (
    id_decyji integer NOT NULL,
    id_pracownika_decydujacego integer NOT NULL
);
    DROP TABLE public."Decyzja";
       public         heap    postgres    false            �           0    0    COLUMN "Decyzja".id_decyji    ACL     B   GRANT SELECT(id_decyji) ON TABLE public."Decyzja" TO "Kierownik";
          public          postgres    false    215            �           0    0 +   COLUMN "Decyzja".id_pracownika_decydujacego    ACL     �   GRANT SELECT(id_pracownika_decydujacego) ON TABLE public."Decyzja" TO "Kierownik";
GRANT SELECT(id_pracownika_decydujacego) ON TABLE public."Decyzja" TO "Magazynier";
GRANT SELECT(id_pracownika_decydujacego) ON TABLE public."Decyzja" TO "Sprzedawca";
          public          postgres    false    215            �            1259    16928    Decyzja_id_decyji_seq    SEQUENCE     �   CREATE SEQUENCE public."Decyzja_id_decyji_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public."Decyzja_id_decyji_seq";
       public          postgres    false    215            �           0    0    Decyzja_id_decyji_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public."Decyzja_id_decyji_seq" OWNED BY public."Decyzja".id_decyji;
          public          postgres    false    216            �           0    0     SEQUENCE "Decyzja_id_decyji_seq"    ACL     G   GRANT USAGE ON SEQUENCE public."Decyzja_id_decyji_seq" TO "Kierownik";
          public          postgres    false    216            �            1259    16929    Harmonogram    TABLE       CREATE TABLE public."Harmonogram" (
    id_harmonogramu integer NOT NULL,
    id_pracownika integer NOT NULL,
    id_decyzji integer NOT NULL,
    data date NOT NULL,
    czas_rozpoczecia time without time zone NOT NULL,
    czas_zakonczenia time without time zone NOT NULL
);
 !   DROP TABLE public."Harmonogram";
       public         heap    postgres    false            �           0    0 $   COLUMN "Harmonogram".id_harmonogramu    ACL     L   GRANT SELECT(id_harmonogramu) ON TABLE public."Harmonogram" TO "Kierownik";
          public          postgres    false    217            �           0    0 "   COLUMN "Harmonogram".id_pracownika    ACL     �   GRANT SELECT(id_pracownika) ON TABLE public."Harmonogram" TO "Kierownik";
GRANT SELECT(id_pracownika) ON TABLE public."Harmonogram" TO "Magazynier";
GRANT SELECT(id_pracownika) ON TABLE public."Harmonogram" TO "Sprzedawca";
          public          postgres    false    217            �           0    0    COLUMN "Harmonogram".id_decyzji    ACL     �   GRANT SELECT(id_decyzji),INSERT(id_decyzji),UPDATE(id_decyzji) ON TABLE public."Harmonogram" TO "Kierownik";
GRANT SELECT(id_decyzji) ON TABLE public."Harmonogram" TO "Magazynier";
GRANT SELECT(id_decyzji) ON TABLE public."Harmonogram" TO "Sprzedawca";
          public          postgres    false    217            �           0    0    COLUMN "Harmonogram".data    ACL     �   GRANT SELECT(data),INSERT(data),UPDATE(data) ON TABLE public."Harmonogram" TO "Kierownik";
GRANT SELECT(data) ON TABLE public."Harmonogram" TO "Magazynier";
GRANT SELECT(data) ON TABLE public."Harmonogram" TO "Sprzedawca";
          public          postgres    false    217            �           0    0 %   COLUMN "Harmonogram".czas_rozpoczecia    ACL       GRANT SELECT(czas_rozpoczecia),INSERT(czas_rozpoczecia),UPDATE(czas_rozpoczecia) ON TABLE public."Harmonogram" TO "Kierownik";
GRANT SELECT(czas_rozpoczecia) ON TABLE public."Harmonogram" TO "Magazynier";
GRANT SELECT(czas_rozpoczecia) ON TABLE public."Harmonogram" TO "Sprzedawca";
          public          postgres    false    217            �           0    0 %   COLUMN "Harmonogram".czas_zakonczenia    ACL       GRANT SELECT(czas_zakonczenia),INSERT(czas_zakonczenia),UPDATE(czas_zakonczenia) ON TABLE public."Harmonogram" TO "Kierownik";
GRANT SELECT(czas_zakonczenia) ON TABLE public."Harmonogram" TO "Magazynier";
GRANT SELECT(czas_zakonczenia) ON TABLE public."Harmonogram" TO "Sprzedawca";
          public          postgres    false    217            �            1259    16932    Harmonogram_id_harmonogramu_seq    SEQUENCE     �   CREATE SEQUENCE public."Harmonogram_id_harmonogramu_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public."Harmonogram_id_harmonogramu_seq";
       public          postgres    false    217            �           0    0    Harmonogram_id_harmonogramu_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public."Harmonogram_id_harmonogramu_seq" OWNED BY public."Harmonogram".id_harmonogramu;
          public          postgres    false    218            �           0    0 *   SEQUENCE "Harmonogram_id_harmonogramu_seq"    ACL     Q   GRANT USAGE ON SEQUENCE public."Harmonogram_id_harmonogramu_seq" TO "Kierownik";
          public          postgres    false    218            �            1259    16933 	   Pracownik    TABLE     9  CREATE TABLE public."Pracownik" (
    id_pracownika integer NOT NULL,
    id_stanowiska integer NOT NULL,
    imie character varying(40) NOT NULL,
    drugie_imie character varying(40),
    nazwisko character varying(40) NOT NULL,
    login character varying(40) NOT NULL,
    haslo character varying NOT NULL
);
    DROP TABLE public."Pracownik";
       public         heap    postgres    false            �           0    0     COLUMN "Pracownik".id_pracownika    ACL     H   GRANT SELECT(id_pracownika) ON TABLE public."Pracownik" TO "Kierownik";
          public          postgres    false    219            �           0    0     COLUMN "Pracownik".id_stanowiska    ACL       GRANT SELECT(id_stanowiska),INSERT(id_stanowiska),UPDATE(id_stanowiska) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(id_stanowiska) ON TABLE public."Pracownik" TO "Magazynier";
GRANT SELECT(id_stanowiska) ON TABLE public."Pracownik" TO "Sprzedawca";
          public          postgres    false    219            �           0    0    COLUMN "Pracownik".imie    ACL     �   GRANT SELECT(imie),INSERT(imie),UPDATE(imie) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(imie) ON TABLE public."Pracownik" TO "Sprzedawca";
GRANT SELECT(imie) ON TABLE public."Pracownik" TO "Magazynier";
          public          postgres    false    219            �           0    0    COLUMN "Pracownik".drugie_imie    ACL     �   GRANT SELECT(drugie_imie),INSERT(drugie_imie),UPDATE(drugie_imie) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(drugie_imie) ON TABLE public."Pracownik" TO "Magazynier";
GRANT SELECT(drugie_imie) ON TABLE public."Pracownik" TO "Sprzedawca";
          public          postgres    false    219            �           0    0    COLUMN "Pracownik".nazwisko    ACL     �   GRANT SELECT(nazwisko),INSERT(nazwisko),UPDATE(nazwisko) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(nazwisko) ON TABLE public."Pracownik" TO "Magazynier";
GRANT SELECT(nazwisko) ON TABLE public."Pracownik" TO "Sprzedawca";
          public          postgres    false    219            �           0    0    COLUMN "Pracownik".login    ACL     �   GRANT SELECT(login),INSERT(login),UPDATE(login) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(login) ON TABLE public."Pracownik" TO "Magazynier";
GRANT SELECT(login) ON TABLE public."Pracownik" TO "Sprzedawca";
          public          postgres    false    219            �           0    0    COLUMN "Pracownik".haslo    ACL     �   GRANT SELECT(haslo),INSERT(haslo),UPDATE(haslo) ON TABLE public."Pracownik" TO "Kierownik";
GRANT SELECT(haslo),UPDATE(haslo) ON TABLE public."Pracownik" TO "Magazynier";
GRANT SELECT(haslo),UPDATE(haslo) ON TABLE public."Pracownik" TO "Sprzedawca";
          public          postgres    false    219            �            1259    16938    Harmonogramy_pracownikow    VIEW     	  CREATE VIEW public."Harmonogramy_pracownikow" AS
 SELECT p.imie,
    p.drugie_imie,
    p.nazwisko,
    h.czas_rozpoczecia,
    h.czas_zakonczenia,
    h.data
   FROM (public."Pracownik" p
     JOIN public."Harmonogram" h ON ((p.id_pracownika = h.id_pracownika)));
 -   DROP VIEW public."Harmonogramy_pracownikow";
       public          postgres    false    217    217    217    217    219    219    219    219            �           0    0     TABLE "Harmonogramy_pracownikow"    ACL     �   GRANT SELECT ON TABLE public."Harmonogramy_pracownikow" TO "Kierownik";
GRANT SELECT ON TABLE public."Harmonogramy_pracownikow" TO "Magazynier";
GRANT SELECT ON TABLE public."Harmonogramy_pracownikow" TO "Sprzedawca";
          public          postgres    false    220            �            1259    16942    Pracownik_id_pracownika_seq    SEQUENCE     �   CREATE SEQUENCE public."Pracownik_id_pracownika_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public."Pracownik_id_pracownika_seq";
       public          postgres    false    219            �           0    0    Pracownik_id_pracownika_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public."Pracownik_id_pracownika_seq" OWNED BY public."Pracownik".id_pracownika;
          public          postgres    false    221            �           0    0 &   SEQUENCE "Pracownik_id_pracownika_seq"    ACL     M   GRANT USAGE ON SEQUENCE public."Pracownik_id_pracownika_seq" TO "Kierownik";
          public          postgres    false    221            �            1259    16943    Produkt    TABLE     +  CREATE TABLE public."Produkt" (
    id_produktu integer NOT NULL,
    cena numeric(10,2) NOT NULL,
    popularnosc real NOT NULL,
    dostepna_ilosc integer NOT NULL,
    nazwa character varying NOT NULL,
    jednostka character varying(20) NOT NULL,
    kategoria character varying(20) NOT NULL
);
    DROP TABLE public."Produkt";
       public         heap    postgres    false            �           0    0    COLUMN "Produkt".id_produktu    ACL     �   GRANT SELECT(id_produktu) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(id_produktu) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(id_produktu) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".cena    ACL     �   GRANT SELECT(cena),INSERT(cena),UPDATE(cena) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(cena) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(cena) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".popularnosc    ACL     �   GRANT SELECT(popularnosc),INSERT(popularnosc),UPDATE(popularnosc) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(popularnosc) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(popularnosc) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".dostepna_ilosc    ACL     3  GRANT SELECT(dostepna_ilosc),INSERT(dostepna_ilosc),UPDATE(dostepna_ilosc) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(dostepna_ilosc),UPDATE(dostepna_ilosc) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(dostepna_ilosc),UPDATE(dostepna_ilosc) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".nazwa    ACL     �   GRANT SELECT(nazwa),INSERT(nazwa),UPDATE(nazwa) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(nazwa) ON TABLE public."Produkt" TO "Sprzedawca";
GRANT SELECT(nazwa) ON TABLE public."Produkt" TO "Magazynier";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".jednostka    ACL     �   GRANT SELECT(jednostka),INSERT(jednostka),UPDATE(jednostka) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(jednostka) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(jednostka) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �           0    0    COLUMN "Produkt".kategoria    ACL     �   GRANT SELECT(kategoria),INSERT(kategoria),UPDATE(kategoria) ON TABLE public."Produkt" TO "Kierownik";
GRANT SELECT(kategoria) ON TABLE public."Produkt" TO "Magazynier";
GRANT SELECT(kategoria) ON TABLE public."Produkt" TO "Sprzedawca";
          public          postgres    false    222            �            1259    16948    Produkt_id_produktu_seq    SEQUENCE     �   CREATE SEQUENCE public."Produkt_id_produktu_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public."Produkt_id_produktu_seq";
       public          postgres    false    222            �           0    0    Produkt_id_produktu_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public."Produkt_id_produktu_seq" OWNED BY public."Produkt".id_produktu;
          public          postgres    false    223            �           0    0 "   SEQUENCE "Produkt_id_produktu_seq"    ACL     I   GRANT USAGE ON SEQUENCE public."Produkt_id_produktu_seq" TO "Kierownik";
          public          postgres    false    223            �            1259    16949    Seanse    TABLE     S  CREATE TABLE public."Seanse" (
    id_seansu integer NOT NULL,
    nazwa_filmu character varying NOT NULL,
    kategoria_wiekowa integer NOT NULL,
    ilosc_sprzednaych_biletow integer NOT NULL,
    czas_rozpoczecia timestamp without time zone NOT NULL,
    czas_zakonczenia timestamp without time zone NOT NULL,
    id_decyzji integer
);
    DROP TABLE public."Seanse";
       public         heap    postgres    false            �           0    0    TABLE "Seanse"    ACL     �   GRANT SELECT ON TABLE public."Seanse" TO "Kierownik";
GRANT SELECT ON TABLE public."Seanse" TO "Sprzedawca";
GRANT SELECT ON TABLE public."Seanse" TO "Magazynier";
          public          postgres    false    224            �            1259    16954    Seanse_id_seansu_seq    SEQUENCE     �   CREATE SEQUENCE public."Seanse_id_seansu_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public."Seanse_id_seansu_seq";
       public          postgres    false    224            �           0    0    Seanse_id_seansu_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public."Seanse_id_seansu_seq" OWNED BY public."Seanse".id_seansu;
          public          postgres    false    225            �            1259    17160 *   Stan_magazynu_z_oczekującymi_zamowieniami    VIEW     �   CREATE VIEW public."Stan_magazynu_z_oczekującymi_zamowieniami" AS
SELECT
    NULL::character varying AS nazwa_produktu,
    NULL::integer AS obecnie_dostepna_ilosc,
    NULL::bigint AS ilosc_dostepna_po_zamowieniach;
 ?   DROP VIEW public."Stan_magazynu_z_oczekującymi_zamowieniami";
       public          postgres    false            �           0    0 2   TABLE "Stan_magazynu_z_oczekującymi_zamowieniami"    ACL     �   GRANT SELECT ON TABLE public."Stan_magazynu_z_oczekującymi_zamowieniami" TO "Kierownik";
GRANT SELECT ON TABLE public."Stan_magazynu_z_oczekującymi_zamowieniami" TO "Magazynier";
          public          postgres    false    242            �            1259    16959 
   Stanowisko    TABLE     �   CREATE TABLE public."Stanowisko" (
    id_stanowiska integer NOT NULL,
    nazwa character varying(40) NOT NULL,
    zarobki numeric(10,2) NOT NULL,
    id_uprawnien integer NOT NULL
);
     DROP TABLE public."Stanowisko";
       public         heap    postgres    false            �           0    0 !   COLUMN "Stanowisko".id_stanowiska    ACL     I   GRANT SELECT(id_stanowiska) ON TABLE public."Stanowisko" TO "Kierownik";
          public          postgres    false    226            �           0    0    COLUMN "Stanowisko".nazwa    ACL     �   GRANT SELECT(nazwa),INSERT(nazwa),UPDATE(nazwa) ON TABLE public."Stanowisko" TO "Kierownik";
GRANT SELECT(nazwa) ON TABLE public."Stanowisko" TO "Magazynier";
GRANT SELECT(nazwa) ON TABLE public."Stanowisko" TO "Sprzedawca";
          public          postgres    false    226            �           0    0    COLUMN "Stanowisko".zarobki    ACL     �   GRANT SELECT(zarobki),INSERT(zarobki),UPDATE(zarobki) ON TABLE public."Stanowisko" TO "Kierownik";
GRANT SELECT(zarobki) ON TABLE public."Stanowisko" TO "Magazynier";
GRANT SELECT(zarobki) ON TABLE public."Stanowisko" TO "Sprzedawca";
          public          postgres    false    226            �           0    0     COLUMN "Stanowisko".id_uprawnien    ACL       GRANT SELECT(id_uprawnien),INSERT(id_uprawnien),UPDATE(id_uprawnien) ON TABLE public."Stanowisko" TO "Kierownik";
GRANT SELECT(id_uprawnien) ON TABLE public."Stanowisko" TO "Magazynier";
GRANT SELECT(id_uprawnien) ON TABLE public."Stanowisko" TO "Sprzedawca";
          public          postgres    false    226            �            1259    16962    Stanowisko_id_stanowiska_seq    SEQUENCE     �   CREATE SEQUENCE public."Stanowisko_id_stanowiska_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public."Stanowisko_id_stanowiska_seq";
       public          postgres    false    226            �           0    0    Stanowisko_id_stanowiska_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public."Stanowisko_id_stanowiska_seq" OWNED BY public."Stanowisko".id_stanowiska;
          public          postgres    false    227            �           0    0 '   SEQUENCE "Stanowisko_id_stanowiska_seq"    ACL     N   GRANT USAGE ON SEQUENCE public."Stanowisko_id_stanowiska_seq" TO "Kierownik";
          public          postgres    false    227            �            1259    16963    Stanowisko_pracownikow    VIEW     �   CREATE VIEW public."Stanowisko_pracownikow" AS
 SELECT p.imie,
    p.drugie_imie,
    p.nazwisko,
    s.nazwa AS nazwa_stanowiska
   FROM (public."Pracownik" p
     JOIN public."Stanowisko" s ON ((p.id_stanowiska = s.id_stanowiska)));
 +   DROP VIEW public."Stanowisko_pracownikow";
       public          postgres    false    219    226    219    219    226    219            �           0    0    TABLE "Stanowisko_pracownikow"    ACL     F   GRANT SELECT ON TABLE public."Stanowisko_pracownikow" TO "Kierownik";
          public          postgres    false    228            �            1259    16967    Uprawnienia    TABLE     h   CREATE TABLE public."Uprawnienia" (
    id_uprawnien integer NOT NULL,
    uprawnienia text NOT NULL
);
 !   DROP TABLE public."Uprawnienia";
       public         heap    postgres    false            �           0    0 !   COLUMN "Uprawnienia".id_uprawnien    ACL     I   GRANT SELECT(id_uprawnien) ON TABLE public."Uprawnienia" TO "Kierownik";
          public          postgres    false    229            �           0    0     COLUMN "Uprawnienia".uprawnienia    ACL       GRANT SELECT(uprawnienia),INSERT(uprawnienia),UPDATE(uprawnienia) ON TABLE public."Uprawnienia" TO "Kierownik";
GRANT SELECT(uprawnienia) ON TABLE public."Uprawnienia" TO "Magazynier";
GRANT SELECT(uprawnienia) ON TABLE public."Uprawnienia" TO "Sprzedawca";
          public          postgres    false    229            �            1259    16972    Uprawnienia_id_uprawnien_seq    SEQUENCE     �   CREATE SEQUENCE public."Uprawnienia_id_uprawnien_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public."Uprawnienia_id_uprawnien_seq";
       public          postgres    false    229            �           0    0    Uprawnienia_id_uprawnien_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public."Uprawnienia_id_uprawnien_seq" OWNED BY public."Uprawnienia".id_uprawnien;
          public          postgres    false    230            �           0    0 '   SEQUENCE "Uprawnienia_id_uprawnien_seq"    ACL     N   GRANT USAGE ON SEQUENCE public."Uprawnienia_id_uprawnien_seq" TO "Kierownik";
          public          postgres    false    230            �            1259    16973    Uprawnienia_stanowisk    VIEW     �   CREATE VIEW public."Uprawnienia_stanowisk" AS
 SELECT s.nazwa AS nazwa_stanowiska,
    u.uprawnienia
   FROM (public."Stanowisko" s
     JOIN public."Uprawnienia" u ON ((s.id_uprawnien = u.id_uprawnien)));
 *   DROP VIEW public."Uprawnienia_stanowisk";
       public          postgres    false    226    229    229    226            �           0    0    TABLE "Uprawnienia_stanowisk"    ACL     E   GRANT SELECT ON TABLE public."Uprawnienia_stanowisk" TO "Kierownik";
          public          postgres    false    231            �            1259    16977    Zamowienie_do_magazynu    TABLE     H  CREATE TABLE public."Zamowienie_do_magazynu" (
    id_zamowienia integer NOT NULL,
    id_pracownika_zamawiajacego integer NOT NULL,
    data_zlozenia timestamp without time zone NOT NULL,
    data_zrealizowania timestamp without time zone,
    id_pracownika_przyjmujacego integer,
    cena_sumaryczna numeric(10,2) NOT NULL
);
 ,   DROP TABLE public."Zamowienie_do_magazynu";
       public         heap    postgres    false            �           0    0 -   COLUMN "Zamowienie_do_magazynu".id_zamowienia    ACL       GRANT SELECT(id_zamowienia) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(id_zamowienia) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(id_zamowienia) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �           0    0 ;   COLUMN "Zamowienie_do_magazynu".id_pracownika_zamawiajacego    ACL     s  GRANT SELECT(id_pracownika_zamawiajacego),INSERT(id_pracownika_zamawiajacego) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(id_pracownika_zamawiajacego),INSERT(id_pracownika_zamawiajacego) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(id_pracownika_zamawiajacego) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �           0    0 -   COLUMN "Zamowienie_do_magazynu".data_zlozenia    ACL     -  GRANT SELECT(data_zlozenia),INSERT(data_zlozenia) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(data_zlozenia),INSERT(data_zlozenia) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(data_zlozenia) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �           0    0 2   COLUMN "Zamowienie_do_magazynu".data_zrealizowania    ACL     F  GRANT SELECT(data_zrealizowania),UPDATE(data_zrealizowania) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(data_zrealizowania),UPDATE(data_zrealizowania) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(data_zrealizowania) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �           0    0 ;   COLUMN "Zamowienie_do_magazynu".id_pracownika_przyjmujacego    ACL     O  GRANT SELECT(id_pracownika_przyjmujacego) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(id_pracownika_przyjmujacego) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(id_pracownika_przyjmujacego),UPDATE(id_pracownika_przyjmujacego) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �           0    0 /   COLUMN "Zamowienie_do_magazynu".cena_sumaryczna    ACL     7  GRANT SELECT(cena_sumaryczna),INSERT(cena_sumaryczna) ON TABLE public."Zamowienie_do_magazynu" TO "Kierownik";
GRANT SELECT(cena_sumaryczna),INSERT(cena_sumaryczna) ON TABLE public."Zamowienie_do_magazynu" TO "Magazynier";
GRANT SELECT(cena_sumaryczna) ON TABLE public."Zamowienie_do_magazynu" TO "Sprzedawca";
          public          postgres    false    232            �            1259    16980    Zamowienia_w_toku    VIEW     �  CREATE VIEW public."Zamowienia_w_toku" AS
 SELECT z.id_zamowienia,
    z.cena_sumaryczna,
    z.data_zlozenia,
    s.imie AS imie_skladajacego,
    s.nazwisko AS nazwisko_skladajacego
   FROM (public."Zamowienie_do_magazynu" z
     JOIN public."Pracownik" s ON ((z.id_pracownika_zamawiajacego = s.id_pracownika)))
  WHERE ((z.data_zrealizowania IS NULL) AND (z.id_pracownika_przyjmujacego IS NULL));
 &   DROP VIEW public."Zamowienia_w_toku";
       public          postgres    false    219    219    232    232    232    232    219    232    232            �           0    0    TABLE "Zamowienia_w_toku"    ACL     �   GRANT SELECT ON TABLE public."Zamowienia_w_toku" TO "Kierownik";
GRANT SELECT ON TABLE public."Zamowienia_w_toku" TO "Magazynier";
          public          postgres    false    233            �            1259    16984 (   Zamowienie_do_magazynu_id_zamowienia_seq    SEQUENCE     �   CREATE SEQUENCE public."Zamowienie_do_magazynu_id_zamowienia_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 A   DROP SEQUENCE public."Zamowienie_do_magazynu_id_zamowienia_seq";
       public          postgres    false    232            �           0    0 (   Zamowienie_do_magazynu_id_zamowienia_seq    SEQUENCE OWNED BY     y   ALTER SEQUENCE public."Zamowienie_do_magazynu_id_zamowienia_seq" OWNED BY public."Zamowienie_do_magazynu".id_zamowienia;
          public          postgres    false    234            �           0    0 3   SEQUENCE "Zamowienie_do_magazynu_id_zamowienia_seq"    ACL     �   GRANT USAGE ON SEQUENCE public."Zamowienie_do_magazynu_id_zamowienia_seq" TO "Kierownik";
GRANT USAGE ON SEQUENCE public."Zamowienie_do_magazynu_id_zamowienia_seq" TO "Magazynier";
          public          postgres    false    234            �            1259    16985     Zamowienie_do_magazynu_szczegoly    TABLE       CREATE TABLE public."Zamowienie_do_magazynu_szczegoly" (
    id_szczegolow_zamowienia integer NOT NULL,
    id_zamowienia_do_magazynu integer NOT NULL,
    id_produktu integer NOT NULL,
    ilosc_w_zamowienia integer NOT NULL,
    cena numeric(10,2) NOT NULL
);
 6   DROP TABLE public."Zamowienie_do_magazynu_szczegoly";
       public         heap    postgres    false            �           0    0 B   COLUMN "Zamowienie_do_magazynu_szczegoly".id_szczegolow_zamowienia    ACL     j   GRANT SELECT(id_szczegolow_zamowienia) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Kierownik";
          public          postgres    false    235            �           0    0 C   COLUMN "Zamowienie_do_magazynu_szczegoly".id_zamowienia_do_magazynu    ACL     �  GRANT SELECT(id_zamowienia_do_magazynu),INSERT(id_zamowienia_do_magazynu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Kierownik";
GRANT SELECT(id_zamowienia_do_magazynu),INSERT(id_zamowienia_do_magazynu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Magazynier";
GRANT SELECT(id_zamowienia_do_magazynu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Sprzedawca";
          public          postgres    false    235            �           0    0 5   COLUMN "Zamowienie_do_magazynu_szczegoly".id_produktu    ACL     U  GRANT SELECT(id_produktu),INSERT(id_produktu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Sprzedawca";
GRANT SELECT(id_produktu),INSERT(id_produktu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Kierownik";
GRANT SELECT(id_produktu),INSERT(id_produktu) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Magazynier";
          public          postgres    false    235            �           0    0 <   COLUMN "Zamowienie_do_magazynu_szczegoly".ilosc_w_zamowienia    ACL     d  GRANT SELECT(ilosc_w_zamowienia),INSERT(ilosc_w_zamowienia) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Kierownik";
GRANT SELECT(ilosc_w_zamowienia),INSERT(ilosc_w_zamowienia) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Magazynier";
GRANT SELECT(ilosc_w_zamowienia) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Sprzedawca";
          public          postgres    false    235            �           0    0 .   COLUMN "Zamowienie_do_magazynu_szczegoly".cena    ACL       GRANT SELECT(cena),INSERT(cena) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Kierownik";
GRANT SELECT(cena),INSERT(cena) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Magazynier";
GRANT SELECT(cena) ON TABLE public."Zamowienie_do_magazynu_szczegoly" TO "Sprzedawca";
          public          postgres    false    235            �            1259    16988 =   Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq    SEQUENCE     �   CREATE SEQUENCE public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 V   DROP SEQUENCE public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq";
       public          postgres    false    235            �           0    0 =   Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq" OWNED BY public."Zamowienie_do_magazynu_szczegoly".id_szczegolow_zamowienia;
          public          postgres    false    236            �           0    0 H   SEQUENCE "Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq"    ACL     �   GRANT USAGE ON SEQUENCE public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq" TO "Kierownik";
GRANT USAGE ON SEQUENCE public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq" TO "Magazynier";
          public          postgres    false    236            �            1259    17157 .   zamowienie_klienta_szczegoly_id_szczegolow_seq    SEQUENCE     �   CREATE SEQUENCE public.zamowienie_klienta_szczegoly_id_szczegolow_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 E   DROP SEQUENCE public.zamowienie_klienta_szczegoly_id_szczegolow_seq;
       public          postgres    false            �           0    0 7   SEQUENCE zamowienie_klienta_szczegoly_id_szczegolow_seq    ACL     �   GRANT USAGE ON SEQUENCE public.zamowienie_klienta_szczegoly_id_szczegolow_seq TO "Kierownik";
GRANT USAGE ON SEQUENCE public.zamowienie_klienta_szczegoly_id_szczegolow_seq TO "Sprzedawca";
          public          postgres    false    241            �            1259    16989    Zamowienie_klienta_szczegoly    TABLE     B  CREATE TABLE public."Zamowienie_klienta_szczegoly" (
    id_szczegolow integer DEFAULT nextval('public.zamowienie_klienta_szczegoly_id_szczegolow_seq'::regclass) NOT NULL,
    id_zamowienia_klient integer NOT NULL,
    id_produktu integer NOT NULL,
    ilosc_zamowiona integer NOT NULL,
    cena numeric(10,2) NOT NULL
);
 2   DROP TABLE public."Zamowienie_klienta_szczegoly";
       public         heap    postgres    false    241            �           0    0 3   COLUMN "Zamowienie_klienta_szczegoly".id_szczegolow    ACL     �   GRANT SELECT(id_szczegolow) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Kierownik";
GRANT SELECT(id_szczegolow) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Sprzedawca";
          public          postgres    false    237            �           0    0 :   COLUMN "Zamowienie_klienta_szczegoly".id_zamowienia_klient    ACL     �   GRANT SELECT(id_zamowienia_klient) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Kierownik";
GRANT SELECT(id_zamowienia_klient),INSERT(id_zamowienia_klient) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Sprzedawca";
          public          postgres    false    237            �           0    0 1   COLUMN "Zamowienie_klienta_szczegoly".id_produktu    ACL     �   GRANT SELECT(id_produktu) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Kierownik";
GRANT SELECT(id_produktu),INSERT(id_produktu) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Sprzedawca";
          public          postgres    false    237            �           0    0 5   COLUMN "Zamowienie_klienta_szczegoly".ilosc_zamowiona    ACL     �   GRANT SELECT(ilosc_zamowiona) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Kierownik";
GRANT SELECT(ilosc_zamowiona),INSERT(ilosc_zamowiona) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Sprzedawca";
          public          postgres    false    237            �           0    0 *   COLUMN "Zamowienie_klienta_szczegoly".cena    ACL     �   GRANT SELECT(cena) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Kierownik";
GRANT SELECT(cena),INSERT(cena) ON TABLE public."Zamowienie_klienta_szczegoly" TO "Sprzedawca";
          public          postgres    false    237            �            1259    16992    historia_zamowien_do_magazynu    VIEW       CREATE VIEW public.historia_zamowien_do_magazynu AS
 SELECT z.id_zamowienia,
    z.cena_sumaryczna,
    z.data_zlozenia,
    z.data_zrealizowania,
    s.imie AS imie_skladajacego,
    s.nazwisko AS nazwisko_skladajacego,
    p.imie AS imie_przyjmujacego,
    p.nazwisko AS nazwisko_przyjmujacego
   FROM ((public."Zamowienie_do_magazynu" z
     JOIN public."Pracownik" s ON ((z.id_pracownika_zamawiajacego = s.id_pracownika)))
     JOIN public."Pracownik" p ON ((z.id_pracownika_przyjmujacego = p.id_pracownika)));
 0   DROP VIEW public.historia_zamowien_do_magazynu;
       public          postgres    false    232    219    232    232    232    219    232    232    219            �           0    0 #   TABLE historia_zamowien_do_magazynu    ACL     �   GRANT SELECT ON TABLE public.historia_zamowien_do_magazynu TO "Kierownik";
GRANT SELECT ON TABLE public.historia_zamowien_do_magazynu TO "Magazynier";
          public          postgres    false    238            �            1259    16997    zamowienie_klienta    TABLE     �   CREATE TABLE public.zamowienie_klienta (
    id_zamowienia_klienta integer NOT NULL,
    data_zlozenia timestamp without time zone NOT NULL,
    cena_sumaryczna numeric(10,2) NOT NULL
);
 &   DROP TABLE public.zamowienie_klienta;
       public         heap    postgres    false            �           0    0 /   COLUMN zamowienie_klienta.id_zamowienia_klienta    ACL     �   GRANT SELECT(id_zamowienia_klienta) ON TABLE public.zamowienie_klienta TO "Kierownik";
GRANT SELECT(id_zamowienia_klienta) ON TABLE public.zamowienie_klienta TO "Sprzedawca";
          public          postgres    false    239            �           0    0 '   COLUMN zamowienie_klienta.data_zlozenia    ACL     �   GRANT SELECT(data_zlozenia) ON TABLE public.zamowienie_klienta TO "Kierownik";
GRANT INSERT(data_zlozenia) ON TABLE public.zamowienie_klienta TO "Sprzedawca";
          public          postgres    false    239            �           0    0 )   COLUMN zamowienie_klienta.cena_sumaryczna    ACL     �   GRANT SELECT(cena_sumaryczna) ON TABLE public.zamowienie_klienta TO "Kierownik";
GRANT INSERT(cena_sumaryczna),UPDATE(cena_sumaryczna) ON TABLE public.zamowienie_klienta TO "Sprzedawca";
          public          postgres    false    239            �            1259    17000 ,   zamowienie_klienta_id_zamowienia_klienta_seq    SEQUENCE     �   CREATE SEQUENCE public.zamowienie_klienta_id_zamowienia_klienta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 C   DROP SEQUENCE public.zamowienie_klienta_id_zamowienia_klienta_seq;
       public          postgres    false    239            �           0    0 ,   zamowienie_klienta_id_zamowienia_klienta_seq    SEQUENCE OWNED BY     }   ALTER SEQUENCE public.zamowienie_klienta_id_zamowienia_klienta_seq OWNED BY public.zamowienie_klienta.id_zamowienia_klienta;
          public          postgres    false    240            �           0    0 5   SEQUENCE zamowienie_klienta_id_zamowienia_klienta_seq    ACL     �   GRANT USAGE ON SEQUENCE public.zamowienie_klienta_id_zamowienia_klienta_seq TO "Kierownik";
GRANT USAGE ON SEQUENCE public.zamowienie_klienta_id_zamowienia_klienta_seq TO "Sprzedawca";
          public          postgres    false    240            �           2604    17145    Decyzja id_decyji    DEFAULT     z   ALTER TABLE ONLY public."Decyzja" ALTER COLUMN id_decyji SET DEFAULT nextval('public."Decyzja_id_decyji_seq"'::regclass);
 B   ALTER TABLE public."Decyzja" ALTER COLUMN id_decyji DROP DEFAULT;
       public          postgres    false    216    215            �           2604    17146    Harmonogram id_harmonogramu    DEFAULT     �   ALTER TABLE ONLY public."Harmonogram" ALTER COLUMN id_harmonogramu SET DEFAULT nextval('public."Harmonogram_id_harmonogramu_seq"'::regclass);
 L   ALTER TABLE public."Harmonogram" ALTER COLUMN id_harmonogramu DROP DEFAULT;
       public          postgres    false    218    217            �           2604    17147    Pracownik id_pracownika    DEFAULT     �   ALTER TABLE ONLY public."Pracownik" ALTER COLUMN id_pracownika SET DEFAULT nextval('public."Pracownik_id_pracownika_seq"'::regclass);
 H   ALTER TABLE public."Pracownik" ALTER COLUMN id_pracownika DROP DEFAULT;
       public          postgres    false    221    219            �           2604    17148    Produkt id_produktu    DEFAULT     ~   ALTER TABLE ONLY public."Produkt" ALTER COLUMN id_produktu SET DEFAULT nextval('public."Produkt_id_produktu_seq"'::regclass);
 D   ALTER TABLE public."Produkt" ALTER COLUMN id_produktu DROP DEFAULT;
       public          postgres    false    223    222            �           2604    17149    Seanse id_seansu    DEFAULT     x   ALTER TABLE ONLY public."Seanse" ALTER COLUMN id_seansu SET DEFAULT nextval('public."Seanse_id_seansu_seq"'::regclass);
 A   ALTER TABLE public."Seanse" ALTER COLUMN id_seansu DROP DEFAULT;
       public          postgres    false    225    224            �           2604    17150    Stanowisko id_stanowiska    DEFAULT     �   ALTER TABLE ONLY public."Stanowisko" ALTER COLUMN id_stanowiska SET DEFAULT nextval('public."Stanowisko_id_stanowiska_seq"'::regclass);
 I   ALTER TABLE public."Stanowisko" ALTER COLUMN id_stanowiska DROP DEFAULT;
       public          postgres    false    227    226            �           2604    17151    Uprawnienia id_uprawnien    DEFAULT     �   ALTER TABLE ONLY public."Uprawnienia" ALTER COLUMN id_uprawnien SET DEFAULT nextval('public."Uprawnienia_id_uprawnien_seq"'::regclass);
 I   ALTER TABLE public."Uprawnienia" ALTER COLUMN id_uprawnien DROP DEFAULT;
       public          postgres    false    230    229            �           2604    17152 $   Zamowienie_do_magazynu id_zamowienia    DEFAULT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu" ALTER COLUMN id_zamowienia SET DEFAULT nextval('public."Zamowienie_do_magazynu_id_zamowienia_seq"'::regclass);
 U   ALTER TABLE public."Zamowienie_do_magazynu" ALTER COLUMN id_zamowienia DROP DEFAULT;
       public          postgres    false    234    232            �           2604    17153 9   Zamowienie_do_magazynu_szczegoly id_szczegolow_zamowienia    DEFAULT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly" ALTER COLUMN id_szczegolow_zamowienia SET DEFAULT nextval('public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq"'::regclass);
 j   ALTER TABLE public."Zamowienie_do_magazynu_szczegoly" ALTER COLUMN id_szczegolow_zamowienia DROP DEFAULT;
       public          postgres    false    236    235            �           2604    17154 (   zamowienie_klienta id_zamowienia_klienta    DEFAULT     �   ALTER TABLE ONLY public.zamowienie_klienta ALTER COLUMN id_zamowienia_klienta SET DEFAULT nextval('public.zamowienie_klienta_id_zamowienia_klienta_seq'::regclass);
 W   ALTER TABLE public.zamowienie_klienta ALTER COLUMN id_zamowienia_klienta DROP DEFAULT;
       public          postgres    false    240    239            �          0    16925    Decyzja 
   TABLE DATA           J   COPY public."Decyzja" (id_decyji, id_pracownika_decydujacego) FROM stdin;
    public          postgres    false    215   �G      �          0    16929    Harmonogram 
   TABLE DATA           }   COPY public."Harmonogram" (id_harmonogramu, id_pracownika, id_decyzji, data, czas_rozpoczecia, czas_zakonczenia) FROM stdin;
    public          postgres    false    217   �G      �          0    16933 	   Pracownik 
   TABLE DATA           n   COPY public."Pracownik" (id_pracownika, id_stanowiska, imie, drugie_imie, nazwisko, login, haslo) FROM stdin;
    public          postgres    false    219   �G      �          0    16943    Produkt 
   TABLE DATA           p   COPY public."Produkt" (id_produktu, cena, popularnosc, dostepna_ilosc, nazwa, jednostka, kategoria) FROM stdin;
    public          postgres    false    222   �J      �          0    16949    Seanse 
   TABLE DATA           �   COPY public."Seanse" (id_seansu, nazwa_filmu, kategoria_wiekowa, ilosc_sprzednaych_biletow, czas_rozpoczecia, czas_zakonczenia, id_decyzji) FROM stdin;
    public          postgres    false    224   �O      �          0    16959 
   Stanowisko 
   TABLE DATA           S   COPY public."Stanowisko" (id_stanowiska, nazwa, zarobki, id_uprawnien) FROM stdin;
    public          postgres    false    226   �U      �          0    16967    Uprawnienia 
   TABLE DATA           B   COPY public."Uprawnienia" (id_uprawnien, uprawnienia) FROM stdin;
    public          postgres    false    229   �V      �          0    16977    Zamowienie_do_magazynu 
   TABLE DATA           �   COPY public."Zamowienie_do_magazynu" (id_zamowienia, id_pracownika_zamawiajacego, data_zlozenia, data_zrealizowania, id_pracownika_przyjmujacego, cena_sumaryczna) FROM stdin;
    public          postgres    false    232   W      �          0    16985     Zamowienie_do_magazynu_szczegoly 
   TABLE DATA           �   COPY public."Zamowienie_do_magazynu_szczegoly" (id_szczegolow_zamowienia, id_zamowienia_do_magazynu, id_produktu, ilosc_w_zamowienia, cena) FROM stdin;
    public          postgres    false    235   lY      �          0    16989    Zamowienie_klienta_szczegoly 
   TABLE DATA           �   COPY public."Zamowienie_klienta_szczegoly" (id_szczegolow, id_zamowienia_klient, id_produktu, ilosc_zamowiona, cena) FROM stdin;
    public          postgres    false    237   �[      �          0    16997    zamowienie_klienta 
   TABLE DATA           c   COPY public.zamowienie_klienta (id_zamowienia_klienta, data_zlozenia, cena_sumaryczna) FROM stdin;
    public          postgres    false    239   #^      �           0    0    Decyzja_id_decyji_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public."Decyzja_id_decyji_seq"', 1, false);
          public          postgres    false    216            �           0    0    Harmonogram_id_harmonogramu_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public."Harmonogram_id_harmonogramu_seq"', 1, false);
          public          postgres    false    218            �           0    0    Pracownik_id_pracownika_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public."Pracownik_id_pracownika_seq"', 7, true);
          public          postgres    false    221            �           0    0    Produkt_id_produktu_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public."Produkt_id_produktu_seq"', 33, true);
          public          postgres    false    223            �           0    0    Seanse_id_seansu_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public."Seanse_id_seansu_seq"', 20, true);
          public          postgres    false    225            �           0    0    Stanowisko_id_stanowiska_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public."Stanowisko_id_stanowiska_seq"', 8, true);
          public          postgres    false    227            �           0    0    Uprawnienia_id_uprawnien_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public."Uprawnienia_id_uprawnien_seq"', 3, true);
          public          postgres    false    230            �           0    0 (   Zamowienie_do_magazynu_id_zamowienia_seq    SEQUENCE SET     Y   SELECT pg_catalog.setval('public."Zamowienie_do_magazynu_id_zamowienia_seq"', 14, true);
          public          postgres    false    234                        0    0 =   Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq    SEQUENCE SET     n   SELECT pg_catalog.setval('public."Zamowienie_do_magazynu_szczegoly_id_szczegolow_zamowienia_seq"', 29, true);
          public          postgres    false    236                       0    0 ,   zamowienie_klienta_id_zamowienia_klienta_seq    SEQUENCE SET     [   SELECT pg_catalog.setval('public.zamowienie_klienta_id_zamowienia_klienta_seq', 21, true);
          public          postgres    false    240                       0    0 .   zamowienie_klienta_szczegoly_id_szczegolow_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.zamowienie_klienta_szczegoly_id_szczegolow_seq', 33, true);
          public          postgres    false    241            �           2606    17012    Decyzja Decyzja_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public."Decyzja"
    ADD CONSTRAINT "Decyzja_pkey" PRIMARY KEY (id_decyji);
 B   ALTER TABLE ONLY public."Decyzja" DROP CONSTRAINT "Decyzja_pkey";
       public            postgres    false    215            �           2606    17014    Harmonogram Harmonogram_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public."Harmonogram"
    ADD CONSTRAINT "Harmonogram_pkey" PRIMARY KEY (id_harmonogramu);
 J   ALTER TABLE ONLY public."Harmonogram" DROP CONSTRAINT "Harmonogram_pkey";
       public            postgres    false    217            �           2606    17016    Pracownik Pracownik_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public."Pracownik"
    ADD CONSTRAINT "Pracownik_pkey" PRIMARY KEY (id_pracownika);
 F   ALTER TABLE ONLY public."Pracownik" DROP CONSTRAINT "Pracownik_pkey";
       public            postgres    false    219            �           2606    17018    Produkt Produkt_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public."Produkt"
    ADD CONSTRAINT "Produkt_pkey" PRIMARY KEY (id_produktu);
 B   ALTER TABLE ONLY public."Produkt" DROP CONSTRAINT "Produkt_pkey";
       public            postgres    false    222            �           2606    17020    Seanse Seanse_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public."Seanse"
    ADD CONSTRAINT "Seanse_pkey" PRIMARY KEY (id_seansu);
 @   ALTER TABLE ONLY public."Seanse" DROP CONSTRAINT "Seanse_pkey";
       public            postgres    false    224            �           2606    17022    Stanowisko Stanowisko_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public."Stanowisko"
    ADD CONSTRAINT "Stanowisko_pkey" PRIMARY KEY (id_stanowiska);
 H   ALTER TABLE ONLY public."Stanowisko" DROP CONSTRAINT "Stanowisko_pkey";
       public            postgres    false    226            �           2606    17024    Uprawnienia Uprawnienia_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public."Uprawnienia"
    ADD CONSTRAINT "Uprawnienia_pkey" PRIMARY KEY (id_uprawnien);
 J   ALTER TABLE ONLY public."Uprawnienia" DROP CONSTRAINT "Uprawnienia_pkey";
       public            postgres    false    229            �           2606    17026 2   Zamowienie_do_magazynu Zamowienie_do_magazynu_pkey 
   CONSTRAINT        ALTER TABLE ONLY public."Zamowienie_do_magazynu"
    ADD CONSTRAINT "Zamowienie_do_magazynu_pkey" PRIMARY KEY (id_zamowienia);
 `   ALTER TABLE ONLY public."Zamowienie_do_magazynu" DROP CONSTRAINT "Zamowienie_do_magazynu_pkey";
       public            postgres    false    232            �           2606    17028 F   Zamowienie_do_magazynu_szczegoly Zamowienie_do_magazynu_szczegoly_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly"
    ADD CONSTRAINT "Zamowienie_do_magazynu_szczegoly_pkey" PRIMARY KEY (id_szczegolow_zamowienia);
 t   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly" DROP CONSTRAINT "Zamowienie_do_magazynu_szczegoly_pkey";
       public            postgres    false    235            �           2606    17030 >   Zamowienie_klienta_szczegoly Zamowienie_klienta_szczegoly_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly"
    ADD CONSTRAINT "Zamowienie_klienta_szczegoly_pkey" PRIMARY KEY (id_szczegolow);
 l   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly" DROP CONSTRAINT "Zamowienie_klienta_szczegoly_pkey";
       public            postgres    false    237            �           2606    17032 *   zamowienie_klienta zamowienie_klienta_pkey 
   CONSTRAINT     {   ALTER TABLE ONLY public.zamowienie_klienta
    ADD CONSTRAINT zamowienie_klienta_pkey PRIMARY KEY (id_zamowienia_klienta);
 T   ALTER TABLE ONLY public.zamowienie_klienta DROP CONSTRAINT zamowienie_klienta_pkey;
       public            postgres    false    239            �           1259    17033    cena_sumaryczna_k    INDEX     {   CREATE INDEX cena_sumaryczna_k ON public.zamowienie_klienta USING btree (cena_sumaryczna) WITH (deduplicate_items='true');
 %   DROP INDEX public.cena_sumaryczna_k;
       public            postgres    false    239            �           1259    17034    fki_id_decyzji    INDEX     I   CREATE INDEX fki_id_decyzji ON public."Seanse" USING btree (id_decyzji);
 "   DROP INDEX public.fki_id_decyzji;
       public            postgres    false    224            �           1259    17035    fki_id_pracownika    INDEX     ]   CREATE INDEX fki_id_pracownika ON public."Decyzja" USING btree (id_pracownika_decydujacego);
 %   DROP INDEX public.fki_id_pracownika;
       public            postgres    false    215            �           1259    17036    fki_id_pracownika_przyjmujacego    INDEX     {   CREATE INDEX fki_id_pracownika_przyjmujacego ON public."Zamowienie_do_magazynu" USING btree (id_pracownika_przyjmujacego);
 3   DROP INDEX public.fki_id_pracownika_przyjmujacego;
       public            postgres    false    232            �           1259    17037    fki_id_pracownika_zamawiajacego    INDEX     {   CREATE INDEX fki_id_pracownika_zamawiajacego ON public."Zamowienie_do_magazynu" USING btree (id_pracownika_zamawiajacego);
 3   DROP INDEX public.fki_id_pracownika_zamawiajacego;
       public            postgres    false    232            �           1259    17038    fki_id_produktu    INDEX     e   CREATE INDEX fki_id_produktu ON public."Zamowienie_do_magazynu_szczegoly" USING btree (id_produktu);
 #   DROP INDEX public.fki_id_produktu;
       public            postgres    false    235            �           1259    17039    fki_id_produktu_k    INDEX     �   CREATE INDEX fki_id_produktu_k ON public."Zamowienie_klienta_szczegoly" USING btree (id_produktu) WITH (deduplicate_items='true');
 %   DROP INDEX public.fki_id_produktu_k;
       public            postgres    false    237            �           1259    17040    fki_id_stanowiska    INDEX     R   CREATE INDEX fki_id_stanowiska ON public."Pracownik" USING btree (id_stanowiska);
 %   DROP INDEX public.fki_id_stanowiska;
       public            postgres    false    219            �           1259    17041    fki_id_uprawnien    INDEX     Q   CREATE INDEX fki_id_uprawnien ON public."Stanowisko" USING btree (id_uprawnien);
 $   DROP INDEX public.fki_id_uprawnien;
       public            postgres    false    226            �           1259    17042    fki_id_zamowienia_do_magazynu    INDEX     �   CREATE INDEX fki_id_zamowienia_do_magazynu ON public."Zamowienie_do_magazynu_szczegoly" USING btree (id_zamowienia_do_magazynu);
 1   DROP INDEX public.fki_id_zamowienia_do_magazynu;
       public            postgres    false    235            �           1259    17043    fki_id_zamowienia_klienta    INDEX     t   CREATE INDEX fki_id_zamowienia_klienta ON public."Zamowienie_klienta_szczegoly" USING btree (id_zamowienia_klient);
 -   DROP INDEX public.fki_id_zamowienia_klienta;
       public            postgres    false    237            �           1259    17044 
   idx_cena_k    INDEX     u   CREATE INDEX idx_cena_k ON public."Zamowienie_klienta_szczegoly" USING btree (cena) WITH (deduplicate_items='true');
    DROP INDEX public.idx_cena_k;
       public            postgres    false    237            �           1259    17045 
   idx_cena_m    INDEX     y   CREATE INDEX idx_cena_m ON public."Zamowienie_do_magazynu_szczegoly" USING btree (cena) WITH (deduplicate_items='true');
    DROP INDEX public.idx_cena_m;
       public            postgres    false    235            �           1259    17046    idx_cena_produktu    INDEX     g   CREATE INDEX idx_cena_produktu ON public."Produkt" USING btree (cena) WITH (deduplicate_items='true');
 %   DROP INDEX public.idx_cena_produktu;
       public            postgres    false    222            �           1259    17047    idx_cena_sumaryczna    INDEX     �   CREATE INDEX idx_cena_sumaryczna ON public."Zamowienie_do_magazynu" USING btree (cena_sumaryczna) WITH (deduplicate_items='true');
 '   DROP INDEX public.idx_cena_sumaryczna;
       public            postgres    false    232            �           1259    17048    idx_data    INDEX     b   CREATE INDEX idx_data ON public."Harmonogram" USING btree (data) WITH (deduplicate_items='true');
    DROP INDEX public.idx_data;
       public            postgres    false    217            �           1259    17049    idx_data_zlozenia    INDEX        CREATE INDEX idx_data_zlozenia ON public."Zamowienie_do_magazynu" USING btree (data_zlozenia) WITH (deduplicate_items='true');
 %   DROP INDEX public.idx_data_zlozenia;
       public            postgres    false    232            �           1259    17050    idx_data_zlozenia_klient    INDEX     �   CREATE INDEX idx_data_zlozenia_klient ON public.zamowienie_klienta USING btree (data_zlozenia) WITH (deduplicate_items='true');
 ,   DROP INDEX public.idx_data_zlozenia_klient;
       public            postgres    false    239            �           1259    17051    idx_dostepna_ilosc    INDEX     r   CREATE INDEX idx_dostepna_ilosc ON public."Produkt" USING btree (dostepna_ilosc) WITH (deduplicate_items='true');
 &   DROP INDEX public.idx_dostepna_ilosc;
       public            postgres    false    222            �           1259    17052    idx_imie_nazwisko    INDEX     s   CREATE INDEX idx_imie_nazwisko ON public."Pracownik" USING btree (imie, nazwisko) WITH (deduplicate_items='true');
 %   DROP INDEX public.idx_imie_nazwisko;
       public            postgres    false    219    219            �           1259    17053    idx_kategoria_produktu    INDEX     q   CREATE INDEX idx_kategoria_produktu ON public."Produkt" USING btree (kategoria) WITH (deduplicate_items='true');
 *   DROP INDEX public.idx_kategoria_produktu;
       public            postgres    false    222            �           1259    17054 	   idx_login    INDEX     b   CREATE INDEX idx_login ON public."Pracownik" USING btree (login) WITH (deduplicate_items='true');
    DROP INDEX public.idx_login;
       public            postgres    false    219            �           1259    17055    idx_nazwa_filmu    INDEX     k   CREATE INDEX idx_nazwa_filmu ON public."Seanse" USING btree (nazwa_filmu) WITH (deduplicate_items='true');
 #   DROP INDEX public.idx_nazwa_filmu;
       public            postgres    false    224            �           1259    17056    idx_nazwa_produktu    INDEX     i   CREATE INDEX idx_nazwa_produktu ON public."Produkt" USING btree (nazwa) WITH (deduplicate_items='true');
 &   DROP INDEX public.idx_nazwa_produktu;
       public            postgres    false    222            �           1259    17057    idx_nazwa_stanowisko    INDEX     n   CREATE INDEX idx_nazwa_stanowisko ON public."Stanowisko" USING btree (nazwa) WITH (deduplicate_items='true');
 (   DROP INDEX public.idx_nazwa_stanowisko;
       public            postgres    false    226            �           1259    17058    idx_popularnosc    INDEX     l   CREATE INDEX idx_popularnosc ON public."Produkt" USING btree (popularnosc) WITH (deduplicate_items='true');
 #   DROP INDEX public.idx_popularnosc;
       public            postgres    false    222            �           1259    17059    idx_uprawnienia    INDEX     p   CREATE INDEX idx_uprawnienia ON public."Uprawnienia" USING btree (uprawnienia) WITH (deduplicate_items='true');
 #   DROP INDEX public.idx_uprawnienia;
       public            postgres    false    229            �           1259    17060    ilosc_sprzedanych_biletow    INDEX     �   CREATE INDEX ilosc_sprzedanych_biletow ON public."Seanse" USING btree (ilosc_sprzednaych_biletow) WITH (deduplicate_items='true');
 -   DROP INDEX public.ilosc_sprzedanych_biletow;
       public            postgres    false    224            �           2618    17163 2   Stan_magazynu_z_oczekującymi_zamowieniami _RETURN    RULE     N  CREATE OR REPLACE VIEW public."Stan_magazynu_z_oczekującymi_zamowieniami" AS
 SELECT p.nazwa AS nazwa_produktu,
    p.dostepna_ilosc AS obecnie_dostepna_ilosc,
    (p.dostepna_ilosc + COALESCE(sum(sz.ilosc_w_zamowienia), (0)::bigint)) AS ilosc_dostepna_po_zamowieniach
   FROM ((public."Produkt" p
     LEFT JOIN public."Zamowienie_do_magazynu_szczegoly" sz ON ((p.id_produktu = sz.id_produktu)))
     LEFT JOIN public."Zamowienie_do_magazynu" z ON (((sz.id_zamowienia_do_magazynu = z.id_zamowienia) AND (z.data_zrealizowania IS NULL))))
  GROUP BY p.id_produktu
  ORDER BY p.id_produktu;
 �   CREATE OR REPLACE VIEW public."Stan_magazynu_z_oczekującymi_zamowieniami" AS
SELECT
    NULL::character varying AS nazwa_produktu,
    NULL::integer AS obecnie_dostepna_ilosc,
    NULL::bigint AS ilosc_dostepna_po_zamowieniach;
       public          postgres    false    235    232    232    222    4798    222    235    235    222    242            �           2620    17062 ,   Zamowienie_klienta_szczegoly cena_sumaryczna    TRIGGER     �   CREATE TRIGGER cena_sumaryczna AFTER INSERT OR DELETE OR UPDATE OF id_zamowienia_klient, id_produktu, ilosc_zamowiona, cena ON public."Zamowienie_klienta_szczegoly" FOR EACH ROW EXECUTE FUNCTION public.zapisz_cene();
 G   DROP TRIGGER cena_sumaryczna ON public."Zamowienie_klienta_szczegoly";
       public          postgres    false    237    261    237    237    237    237            �           2606    17063    Seanse id_decyzji    FK CONSTRAINT     �   ALTER TABLE ONLY public."Seanse"
    ADD CONSTRAINT id_decyzji FOREIGN KEY (id_decyzji) REFERENCES public."Decyzja"(id_decyji);
 =   ALTER TABLE ONLY public."Seanse" DROP CONSTRAINT id_decyzji;
       public          postgres    false    224    4787    215            �           2606    17068    Harmonogram id_decyzji    FK CONSTRAINT     �   ALTER TABLE ONLY public."Harmonogram"
    ADD CONSTRAINT id_decyzji FOREIGN KEY (id_decyzji) REFERENCES public."Decyzja"(id_decyji);
 B   ALTER TABLE ONLY public."Harmonogram" DROP CONSTRAINT id_decyzji;
       public          postgres    false    4787    217    215            �           2606    17073    Decyzja id_pracownika    FK CONSTRAINT     �   ALTER TABLE ONLY public."Decyzja"
    ADD CONSTRAINT id_pracownika FOREIGN KEY (id_pracownika_decydujacego) REFERENCES public."Pracownik"(id_pracownika);
 A   ALTER TABLE ONLY public."Decyzja" DROP CONSTRAINT id_pracownika;
       public          postgres    false    219    4793    215            �           2606    17078    Harmonogram id_pracownika    FK CONSTRAINT     �   ALTER TABLE ONLY public."Harmonogram"
    ADD CONSTRAINT id_pracownika FOREIGN KEY (id_pracownika) REFERENCES public."Pracownik"(id_pracownika);
 E   ALTER TABLE ONLY public."Harmonogram" DROP CONSTRAINT id_pracownika;
       public          postgres    false    4793    217    219            �           2606    17083 2   Zamowienie_do_magazynu id_pracownika_przyjmujacego    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu"
    ADD CONSTRAINT id_pracownika_przyjmujacego FOREIGN KEY (id_pracownika_przyjmujacego) REFERENCES public."Pracownik"(id_pracownika);
 ^   ALTER TABLE ONLY public."Zamowienie_do_magazynu" DROP CONSTRAINT id_pracownika_przyjmujacego;
       public          postgres    false    219    4793    232            �           2606    17088 2   Zamowienie_do_magazynu id_pracownika_zamawiajacego    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu"
    ADD CONSTRAINT id_pracownika_zamawiajacego FOREIGN KEY (id_pracownika_zamawiajacego) REFERENCES public."Pracownik"(id_pracownika);
 ^   ALTER TABLE ONLY public."Zamowienie_do_magazynu" DROP CONSTRAINT id_pracownika_zamawiajacego;
       public          postgres    false    219    232    4793            �           2606    17093 ,   Zamowienie_do_magazynu_szczegoly id_produktu    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly"
    ADD CONSTRAINT id_produktu FOREIGN KEY (id_produktu) REFERENCES public."Produkt"(id_produktu);
 X   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly" DROP CONSTRAINT id_produktu;
       public          postgres    false    4798    235    222            �           2606    17098 (   Zamowienie_klienta_szczegoly id_produktu    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly"
    ADD CONSTRAINT id_produktu FOREIGN KEY (id_produktu) REFERENCES public."Produkt"(id_produktu);
 T   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly" DROP CONSTRAINT id_produktu;
       public          postgres    false    222    237    4798            �           2606    17103    Pracownik id_stanowiska    FK CONSTRAINT     �   ALTER TABLE ONLY public."Pracownik"
    ADD CONSTRAINT id_stanowiska FOREIGN KEY (id_stanowiska) REFERENCES public."Stanowisko"(id_stanowiska);
 C   ALTER TABLE ONLY public."Pracownik" DROP CONSTRAINT id_stanowiska;
       public          postgres    false    219    226    4810            �           2606    17108    Stanowisko id_uprawnien    FK CONSTRAINT     �   ALTER TABLE ONLY public."Stanowisko"
    ADD CONSTRAINT id_uprawnien FOREIGN KEY (id_uprawnien) REFERENCES public."Uprawnienia"(id_uprawnien);
 C   ALTER TABLE ONLY public."Stanowisko" DROP CONSTRAINT id_uprawnien;
       public          postgres    false    229    226    4814            �           2606    17113 :   Zamowienie_do_magazynu_szczegoly id_zamowienia_do_magazynu    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly"
    ADD CONSTRAINT id_zamowienia_do_magazynu FOREIGN KEY (id_zamowienia_do_magazynu) REFERENCES public."Zamowienie_do_magazynu"(id_zamowienia);
 f   ALTER TABLE ONLY public."Zamowienie_do_magazynu_szczegoly" DROP CONSTRAINT id_zamowienia_do_magazynu;
       public          postgres    false    235    232    4817            �           2606    17118 2   Zamowienie_klienta_szczegoly id_zamowienia_klienta    FK CONSTRAINT     �   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly"
    ADD CONSTRAINT id_zamowienia_klienta FOREIGN KEY (id_zamowienia_klient) REFERENCES public.zamowienie_klienta(id_zamowienia_klienta);
 ^   ALTER TABLE ONLY public."Zamowienie_klienta_szczegoly" DROP CONSTRAINT id_zamowienia_klienta;
       public          postgres    false    237    4835    239            �      \.


      �      \.


      �   P   1	1	Jan	Adam	Kowalski	jan.kowalski	BKh1Qg5z5mbkbKiOMAWS/mPziQuG4RW/0P/PAqodZcE=
 J   2	2	Anna	\N	Nowak	anna.nowak	oHXRfz1FMHOFP4E4OMFbgCO4xIcDhDY1T+WZw5QuH5U=
 W   3	3	Piotr	\N	Wiśniewski	piotr.wisniewski	K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=
 X   4	4	Katarzyna	Maria	Zając	katarzyna.zajac	m4dppKdClZotApjDb7cGI/LfrNqENiN98I2N/Vs3N0w=
 Q   5	5	Tomasz	\N	Wójcik	tomasz.wojcik	Bg5sgYsRGApiYIgd2tsE5ZzXsUyGznUvZthUfxZcGNc=
 b   6	6	Magdalena	Agnieszka	Kamińska	magdalena.kaminska	MwKYFJFSESdw71nLtDWOZ8zSxGbZNaIMh6/G9XI6tbw=
 Y   7	7	Paweł	\N	Lewandowski	pawel.lewandowski	WZRHGrsBESr8wYFZ9sx0tPURuZgG2lmzyvWpwXPKz8U=
    \.


      �   8   18	2.49	0.5	90	Baton owocowy	sztuka	Przekąski słodkie
 )   14	3.99	0.4	120	Lemoniada	butelka	Napoje
 .   15	1.99	0.6	150	Woda mineralna	butelka	Napoje
 4   12	3.49	0.6	150	Nachos	opakowanie	Przekąski słone
 C   19	1.99	0.5	180	Duży baton czekoladowy	sztuka	Przekąski słodkie
 G   21	2.99	0.6	140	Chipsy o smaku paprykowym	opakowanie	Przekąski słone
 D   22	2.79	0.6	150	Chipsy o smaku serowym	opakowanie	Przekąski słone
 A   23	1.49	0.5	170	Duże chipsy solone	opakowanie	Przekąski słone
 J   24	1.99	0.6	160	Duże chipsy o smaku papryki	opakowanie	Przekąski słone
 B   25	0.99	0.4	180	Cukierki karmelowe	opakowanie	Przekąski słodkie
 @   26	1.49	0.5	170	Cukierki owocowe	opakowanie	Przekąski słodkie
 9   17	3.99	0.7	0	Baton orzechowy	sztuka	Przekąski słodkie
 <   9	5.99	0.3	520	Popcorn maślany	opakowane	Przekąski słone
 &   30	15.99	0	202077	Pepsi	puszka	Napoje
 +   33	7.00	0	0	Coca Cola	butelka 0.6 l	Napoje
 <   16	4.49	0.6	17	Baton czekoladowy	sztuka	Przekąski słodkie
 E   20	3.29	0.7	126	Chipsy o smaku barbecue	opakowanie	Przekąski słone
 A   31	2.00	0	2009	Chrupki kukurydziane	opakowanie	Przekąski słone
 )   32	5.99	0	298	Sok owocowy	butelka	Napoje
 A   10	5.99	0.8	500	Popcorn karmelowy	opakowanie	Przekąski słodkie
 <   11	5.99	0.8	550	Popcorn solony	opakowanie	Przekąski słone
 "   13	4.99	0.5	0	Cola	butelka	Napoje
    \.


      �   F   1	Avengers: Endgame	12	250	2024-05-06 18:00:00	2024-05-06 20:30:00	\N
 >   2	Inception	16	180	2024-05-06 20:45:00	2024-05-06 23:00:00	\N
 D   3	The Dark Knight	16	200	2024-05-07 17:30:00	2024-05-07 19:45:00	\N
 B   4	The Godfather	18	150	2024-05-07 20:00:00	2024-05-07 22:45:00	\N
 A   5	Pulp Fiction	18	170	2024-05-08 18:15:00	2024-05-08 21:00:00	\N
 A   6	Forrest Gump	12	220	2024-05-08 21:15:00	2024-05-09 00:00:00	\N
 M   7	The Shawshank Redemption	16	190	2024-05-09 17:45:00	2024-05-09 20:30:00	\N
 E   8	Schindler's List	18	160	2024-05-09 20:45:00	2024-05-09 23:30:00	\N
 ?   9	The Matrix	16	210	2024-05-10 18:30:00	2024-05-10 21:15:00	\N
 @   10	Fight Club	18	180	2024-05-10 21:30:00	2024-05-11 00:15:00	\N
 J   11	Inglourious Basterds	18	200	2024-05-11 17:00:00	2024-05-11 19:45:00	\N
 N   12	The Silence of the Lambs	18	170	2024-05-11 20:00:00	2024-05-11 22:45:00	\N
 @   13	Goodfellas	18	180	2024-05-12 18:15:00	2024-05-12 21:00:00	\N
 g   14	The Lord of the Rings: The Fellowship of the Ring	12	240	2024-05-12 21:15:00	2024-05-13 00:00:00	\N
 B   15	The Departed	18	190	2024-05-13 17:45:00	2024-05-13 20:30:00	\N
 D   16	The Green Mile	16	170	2024-05-13 20:45:00	2024-05-13 23:30:00	\N
 H   17	The Usual Suspects	18	200	2024-05-14 18:30:00	2024-05-14 21:15:00	\N
 I   18	Saving Private Ryan	16	210	2024-05-14 21:30:00	2024-05-15 00:15:00	\N
 B   19	The Lion King	0	280	2024-05-15 17:00:00	2024-05-15 19:45:00	\N
 >   20	Toy Story	0	260	2024-05-15 20:00:00	2024-05-15 22:45:00	\N
    \.


      �      1	Kierownik Baru	7000.00	1
    2	Magazynier	5000.00	2
    3	Sprzedawca 1	4500.00	3
    4	Sprzedawca 2	4700.00	3
    5	Sprzedawca 3	4700.00	3
    6	Sprzedawca 4	4700.00	3
    7	Sprzedawca 5	4700.00	3
    \.


      �      1	kierownik
    2	magazynier
    3	sprzedawca
    \.


      �   D   6	1	2024-05-29 20:07:39.006187	2024-05-31 18:31:31.949515	3	2000.00
 B   7	1	2024-05-31 19:02:19.512943	2024-06-01 15:27:46.595958	3	20.00
 C   8	1	2024-06-01 15:27:14.615385	2024-06-01 15:27:48.255443	3	100.00
 *   9	1	2024-06-01 15:32:02.731434	\N	\N	1.00
 B   10	2	2024-06-01 16:50:46.38098	2024-06-01 16:51:01.970938	3	23.00
 C   11	2	2024-06-01 17:00:28.394213	2024-06-01 17:01:49.819819	\N	2.00
 .   13	1	2024-06-03 12:24:58.761399	\N	\N	1366.00
 E   12	1	2024-06-03 12:03:03.020381	2024-06-03 12:29:23.453845	\N	303.00
 ,   14	1	2024-06-03 15:18:22.434486	\N	\N	10.00
    \.


      �      8	6	30	20000	1000.00
    9	6	30	20000	1000.00
    10	7	31	2000	10.00
    11	7	30	2000	10.00
    12	8	32	300	50.00
    13	8	32	300	50.00
    14	9	30	34	1.00
    15	10	30	76	23.00
    16	11	31	6	2.00
    17	12	16	5	1.00
    18	12	16	5	1.00
    19	12	16	5	1.00
    20	12	20	10	100.00
    21	12	20	10	100.00
    22	12	20	10	100.00
    23	13	33	100	700.00
    24	13	20	99	666.00
    25	14	33	1000	2.00
    26	14	33	1000	2.00
    27	14	33	1000	2.00
    28	14	33	1000	2.00
    29	14	33	1000	2.00
    \.


      �      1	1	30	20	119.80
    2	2	19	8	15.92
    3	2	19	8	15.92
    4	2	19	8	15.92
    5	2	19	8	15.92
    6	2	19	8	15.92
    7	2	19	8	15.92
    8	2	19	8	15.92
    9	2	19	8	15.92
    10	2	19	8	15.92
    11	2	19	8	15.92
    12	3	20	2	6.58
    16	9	17	3	11.97
    17	10	13	5	24.95
    18	11	13	95	474.05
    19	12	18	60	149.40
    20	12	18	3	7.47
    21	13	18	7	17.43
    22	14	16	95	426.55
    23	14	16	2	8.98
    24	15	16	13	58.37
    25	15	16	8	35.92
    26	16	16	23	103.27
    27	17	17	100	399.00
    28	18	17	37	147.63
    29	19	17	3	11.97
    30	20	16	4	17.96
    31	20	20	4	13.16
    32	21	31	3	6.00
    33	21	32	2	11.98
    \.


      �   $   1	2024-05-29 20:09:11.873457	119.80
 $   2	2024-05-29 20:19:03.337904	159.20
 "   3	2024-06-01 16:10:47.489963	6.58
 #   9	2024-06-01 16:35:00.829096	11.97
 $   10	2024-06-01 17:14:30.880128	24.95
 %   11	2024-06-01 17:23:00.058328	474.05
 %   12	2024-06-01 17:31:36.400116	156.87
 #   13	2024-06-01 17:32:30.04992	17.43
 $   14	2024-06-01 17:34:07.92009	435.53
 $   15	2024-06-01 17:36:30.636156	94.29
 %   16	2024-06-01 17:36:43.394576	103.27
 $   17	2024-06-01 17:38:08.89324	399.00
 %   18	2024-06-01 17:39:48.802764	147.63
 $   19	2024-06-01 17:39:57.404244	11.97
 $   20	2024-06-14 16:11:07.401626	31.12
 #   21	2024-06-14 16:21:15.32452	17.98
    \.


     