CREATE OR REPLACE FUNCTION random_timestamp_between (
    low TIMESTAMP,
    high TIMESTAMP
) 
RETURNS TIMESTAMP 
LANGUAGE 'plpgsql' 
AS
$$
BEGIN
   RETURN low + random() * (high - low);
END;
$$;