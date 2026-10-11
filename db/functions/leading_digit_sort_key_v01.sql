-- Sort key that treats a run of digits *at the start* of the string as a
-- number instead of a sequence of characters, so "2" sorts before "10".
-- Anything past the leading digits (or the whole string, if it doesn't start
-- with a digit) is compared as plain lowercased text - a digit run elsewhere
-- in the string (e.g. "Store 9" vs. "Store 10") is not natural-sorted. That
-- narrower scope, instead of full natural sort, was the deliberate tradeoff
-- settled on in https://github.com/rubyforgood/human-essentials/pull/5656.
CREATE FUNCTION leading_digit_sort_key(value text) RETURNS text AS $$
  SELECT CASE
    WHEN lower(coalesce(value, '')) ~ '^[0-9]+'
    THEN lpad(substring(lower(value) from '^[0-9]+'), 20, '0')
         || substring(lower(value) from '^[0-9]+(.*)$')
    ELSE lower(coalesce(value, ''))
  END;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;
