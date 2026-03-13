-- Customer Insert Trigger
-- This trigger is executed when a new customer is inserted
-- It can be used for validation, logging, or additional processing

CREATE OR REPLACE FUNCTION handle_customer_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Add any custom logic here, e.g., validation, logging, etc.
  -- For example, ensure required fields are present

  IF NEW.full_name IS NULL OR NEW.full_name = '' THEN
    RAISE EXCEPTION 'Full name is required';
  END IF;

  IF NEW.email IS NULL OR NEW.email = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;

  -- Log the insertion (optional)
  -- INSERT INTO audit_log (table_name, operation, record_id, user_id)
  -- VALUES ('customers', 'INSERT', NEW.id, NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_insert_trigger
BEFORE INSERT ON customers
FOR EACH ROW EXECUTE FUNCTION handle_customer_insert();