from django.core.management.base import BaseCommand
from ...recombee import client
from recombee_api_client.api_requests import AddItemProperty, DeleteItemProperty

class Command(BaseCommand):
    help = 'Setup Recombee client and add initial data'

    def handle(self, *args, **kwargs):
        

        client.send(AddItemProperty('title', 'string')) #Yes
        client.send(AddItemProperty('brand', 'string')) #Yes
        client.send(AddItemProperty('model', 'string'))  # Yes
        client.send(AddItemProperty('description', 'string'))  # Yes
        client.send(AddItemProperty('sku', 'string')) #Yes
        client.send(AddItemProperty('slug', 'string')) #Yes
        client.send(AddItemProperty('category', 'string')) #Yes
        client.send(AddItemProperty('secondary_category', 'string')) #Yes
        client.send(AddItemProperty('upcoming', 'boolean')) #Yes
        client.send(AddItemProperty('updated_at', 'timestamp')) #Yes
        client.send(AddItemProperty('link', 'string')) #Yes
        client.send(AddItemProperty('colorway', 'set'))  # Yes 
        client.send(AddItemProperty('trait', 'boolean')) #Yes - means featured
        client.send(AddItemProperty('release_date', 'timestamp'))  # Yes
        client.send(AddItemProperty('retailprice', 'double')) # Yes
        client.send(AddItemProperty('Image', 'image')) 
        client.send(AddItemProperty('normalized_colorway', 'set'))
        client.send(AddItemProperty('sizes_available', 'set'))
        client.send(AddItemProperty('lowest_ask', 'set'))
        client.send(AddItemProperty('total_asks', 'set'))
        client.send(AddItemProperty('isMen', 'boolean'))
        client.send(AddItemProperty('isWomen', 'boolean'))
        client.send(AddItemProperty('isYouth', 'boolean'))
        client.send(AddItemProperty('isKids', 'boolean'))
        client.send(AddItemProperty('imageURL', 'string'))