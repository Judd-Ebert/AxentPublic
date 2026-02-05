from recombee_api_client.api_client import RecombeeClient, Region
import os

client = RecombeeClient(
    database_id=os.getenv('RECOMBEE_DATABASE_ID'),
    token=os.getenv('RECOMBEE_PRIVATE_TOKEN'),
    region=Region.US_WEST,
)