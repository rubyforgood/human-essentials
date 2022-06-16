# expects $DIAPER_DB_HOST, $DIAPER_DB_USERNAME, $DIAPER_DB_PASSWORD, $DIAPER_DB_DATABASE,
# $PARTNER_DB_HOST, $PARTNER_DB_USERNAME, $PARTNER_DB_PASSWORD, $PARTNER_DB_DATABASE
# to be set

echo "Copying data..."
echo "PARTNER_DB_DATABASE $PARTNER_DB_DATABASE"
echo "PARTNER_DB_HOST $PARTNER_DB_HOST"
echo "PARTNER_DB_USERNAME $PARTNER_DB_USERNAME"
echo "PARTNER_DB_PASSWORD $PARTNER_DB_PASSWORD"
echo "DIAPER_DB_DATABASE $DIAPER_DB_DATABASE"
echo "DIAPER_DB_HOST $DIAPER_DB_HOST"
echo "DIAPER_DB_USERNAME $DIAPER_DB_USERNAME"
echo "DIAPER_DB_PASSWORD $DIAPER_DB_PASSWORD"

echo "Creating partner_users..."

PGPASSWORD=$PARTNER_DB_PASSWORD psql -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -c "CREATE TABLE partner_users AS TABLE users";
PGPASSWORD=$PARTNER_DB_PASSWORD psql -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -c "CREATE TABLE partner_profiles AS TABLE partners";

echo "Creating partner_profiles..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t partner_profiles | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying families..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t families | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying children..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t children | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying authorized_family_members..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t authorized_family_members | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying item_requests..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t item_requests | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying child_item_requests..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t child_item_requests | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying partner_forms..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t partner_forms | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying partner_users..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t partner_users | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "Copying partner_requests..."

PGPASSWORD=$PARTNER_DB_PASSWORD pg_dump -a -h $PARTNER_DB_HOST \
  -U $PARTNER_DB_USERNAME \
  -d $PARTNER_DB_DATABASE \
  -t partner_requests | \
  psql -h $DIAPER_DB_HOST \
  -U $DIAPER_DB_USERNAME \
  -d $DIAPER_DB_DATABASE

echo "All done!"
