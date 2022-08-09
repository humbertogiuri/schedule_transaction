-- function signature (PostgreSQL 10)
CREATE OR REPLACE FUNCTION testeEquivalenciaPorConflito () 
RETURNS integer AS $$
    BEGIN
    	RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;
