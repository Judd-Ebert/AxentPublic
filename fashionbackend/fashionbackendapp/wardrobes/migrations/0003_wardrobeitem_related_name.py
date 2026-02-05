# Generated manually to add related_name to WardrobeItem.wardrobe

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('wardrobes', '0002_wardrobe_product_ids'),
    ]

    operations = [
        migrations.AlterField(
            model_name='wardrobeitem',
            name='wardrobe',
            field=models.ForeignKey(on_delete=models.CASCADE, related_name='items', to='wardrobes.wardrobe'),
        ),
    ] 