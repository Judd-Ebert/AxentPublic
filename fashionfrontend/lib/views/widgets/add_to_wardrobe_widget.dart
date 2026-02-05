import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Axent/models/wardrobe_model.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:Axent/providers/wardrobes_provider.dart';

class AddToWardrobeWidget extends StatefulWidget {
  final CardData product;

  const AddToWardrobeWidget({
    super.key,
    required this.product,
  });

  @override
  State<AddToWardrobeWidget> createState() => _AddToWardrobeWidgetState();
}

class _AddToWardrobeWidgetState extends State<AddToWardrobeWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobesProvider>(
      builder: (context, wardrobesProvider, child) {
        final wardrobes = wardrobesProvider.wardrobes;
        final containingWardrobes = wardrobesProvider.getWardrobesContainingProduct(widget.product.id);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header

            // Wardrobes List
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: wardrobes.isEmpty
                  ? _buildEmptyWardrobesState()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: wardrobes.length,
                      itemBuilder: (context, index) {
                        final wardrobe = wardrobes[index];
                        final isInWardrobe = containingWardrobes.any((w) => w.id == wardrobe.id);
                        
                        return _buildWardrobeItem(
                          wardrobe,
                          isInWardrobe,
                          wardrobesProvider,
                        );
                      },
                    ),
            ),

            // Create New Wardrobe Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _createWardrobe(wardrobesProvider),
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Creating...' : 'Create New Wardrobe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyWardrobesState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No wardrobes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first wardrobe to organize your style',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeItem(
    Wardrobe wardrobe,
    bool isInWardrobe,
    WardrobesProvider wardrobesProvider,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInWardrobe
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isInWardrobe
                ? scheme.primary.withValues(alpha: 0.1)
                : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isInWardrobe ? Icons.folder_rounded : Icons.folder_outlined,
            color: isInWardrobe ? scheme.primary : scheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          wardrobe.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${wardrobe.productIds.length} items',
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInWardrobe
                      ? scheme.primary.withValues(alpha: 0.1)
                      : scheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isInWardrobe ? 'Remove' : 'Add',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isInWardrobe ? scheme.primary : scheme.onPrimary,
                  ),
                ),
              ),
        onTap: _isLoading
            ? null
            : () => _toggleWardrobe(wardrobe, isInWardrobe, wardrobesProvider),
      ),
    );
  }

  Future<void> _toggleWardrobe(
    Wardrobe wardrobe,
    bool isInWardrobe,
    WardrobesProvider wardrobesProvider,
  ) async {
    setState(() => _isLoading = true);
    final scheme = Theme.of(context).colorScheme;

    try {
      bool success;
      if (isInWardrobe) {
        success = await wardrobesProvider.removeFromWardrobe(wardrobe.id, widget.product.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from ${wardrobe.name}'),
              backgroundColor: scheme.primary,
            ),
          );
        }
      } else {
        success = await wardrobesProvider.addToWardrobe(wardrobe.id, widget.product.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to ${wardrobe.name}'),
              backgroundColor: scheme.primary,
            ),
          );
        }
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isInWardrobe ? 'remove from' : 'add to'} ${wardrobe.name}'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createWardrobe(WardrobesProvider wardrobesProvider) async {
    final scheme = Theme.of(context).colorScheme;
    final name = await _showCreateWardrobeDialog();
    if (name == null || name.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final success = await wardrobesProvider.createWardrobe(name);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "$name" wardrobe'),
            backgroundColor: scheme.primary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create wardrobe'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showCreateWardrobeDialog() async {
    final TextEditingController controller = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create New Wardrobe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Wardrobe Name',
            hintText: 'Enter wardrobe name...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
} 