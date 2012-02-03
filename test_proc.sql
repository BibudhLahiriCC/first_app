DROP FUNCTION IF EXISTS test_proc(integer);
CREATE FUNCTION test_proc(person_id integer) RETURNS integer AS $$

DECLARE
  number_of_contacts integer;
  statement varchar(500);

BEGIN

  EXECUTE 'select COALESCE(count(contacts),0) from contacts, contact_people where contacts.mode like ''Face to Face%'' and contacts.id = contact_people.contact_id and contact_people.person_id = $1 and contact_people.regarding = ''t'' and date_part(''month'', contacts.occurred_at) = date_part(''month'', current_timestamp)' INTO number_of_contacts USING person_id;
  RETURN number_of_contacts;

END;
$$ LANGUAGE plpgsql;
