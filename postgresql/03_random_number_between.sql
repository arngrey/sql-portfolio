CREATE OR REPLACE FUNCTION random_number_between (
    low INT,
    high INT
) 
RETURNS INT 
LANGUAGE 'plpgsql'
AS
$$
BEGIN
   RETURN floor(random()*(high-low + 1) + low);
END;
$$;