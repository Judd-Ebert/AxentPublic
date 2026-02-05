from django.core.management.base import BaseCommand
from recombee_api_client.api_requests import ListItems, DeleteItem, Batch
from ...recombee import client


class Command(BaseCommand):
    help = 'Delete all items from Recombee database'

    def handle(self, *args, **kwargs):
        try:
            # Step 1: List all items (up to 10000)
            response = client.send(ListItems(count=10000))
            items = response  # This is a list of item IDs

            print(f"Total items to delete: {len(items)}")

            # Step 2: Batch delete items
            batch_size = 100
            for i in range(0, len(items), batch_size):
                batch = [DeleteItem(item_id=id_) for id_ in items[i:i + batch_size]]
                client.send(Batch(batch))

            print("✅ All items deleted from Recombee.")

        except Exception as e:
            self.stderr.write(f"⚠️ Error: {e}")

#! ONLY UNDO THIS UNDER VERY SPECIAL CIRCUMSTANCES- DO NOT WANNA DELETE THE DATABASE 🥀