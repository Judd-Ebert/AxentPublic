import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:Axent/models/wardrobe_model.dart';
import 'package:Axent/views/pages/product_info_page.dart';
import 'package:Axent/data/wardrobes_service.dart';
import 'package:provider/provider.dart';
import 'package:Axent/providers/wardrobes_provider.dart';

class WardrobeDetailsPage extends StatefulWidget {
  final Wardrobe wardrobe;

  const WardrobeDetailsPage({super.key, required this.wardrobe});

  @override
  State<WardrobeDetailsPage> createState() => _WardrobeDetailsPageState();
}

class _WardrobeDetailsPageState extends State<WardrobeDetailsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedBrand = 'All';
  String _selectedSortBy = 'Recent';
  bool _isLoading = true;
  bool _isSearchFocused = false;
  List<CardData> _products = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<CardData> get _allProducts => _products;

  List<CardData> get _filteredProducts {
    List<CardData> filtered = _allProducts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final query = _searchQuery.toLowerCase();
        return product.title.toLowerCase().contains(query) ||
            product.brand.toLowerCase().contains(query) ||
            (product.model?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply brand filter
    if (_selectedBrand != 'All') {
      filtered =
          filtered.where((product) => product.brand == _selectedBrand).toList();
    }

    // Apply sorting
    switch (_selectedSortBy) {
      case 'Recent':
        // Already sorted by most recent first from backend
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) {
          final aPrice = a.lowestAsk ?? double.infinity;
          final bPrice = b.lowestAsk ?? double.infinity;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          final aPrice = a.lowestAsk ?? 0;
          final bPrice = b.lowestAsk ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'Brand A-Z':
        filtered.sort((a, b) => a.brand.compareTo(b.brand));
        break;
      case 'Name A-Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filtered;
  }

  List<String> get _availableBrands {
    final brands =
        _allProducts.map((product) => product.brand).toSet().toList();
    brands.sort();
    return ['All', ...brands];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _fetchWardrobeProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  Future<void> _fetchWardrobeProducts() async {
    try {
      setState(() => _isLoading = true);
      final products =
          await WardrobesService.getWardrobeProducts(widget.wardrobe.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load wardrobe products: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          _buildSearchAndFilters(),
          _buildProductsGrid(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final scheme = Theme.of(context).colorScheme;
    
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(Icons.delete, color: scheme.onSurface, size: 20),
            onPressed: _deleteWardrobe,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primary.withValues(alpha: 0.05),
                const Color(0xFFF8FAFC),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.wardrobe.name,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: scheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_allProducts.length} items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.folder,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Wardrobe Collection',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final scheme = Theme.of(context).colorScheme;
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Enhanced Search Bar
            _buildEnhancedSearchBar(),
            const SizedBox(height: 20),

            // Modern Filters
            _buildModernFilters(),

            // Results count with animation
            if (_searchQuery.isNotEmpty || _selectedBrand != 'All') ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredProducts.length} of ${_allProducts.length} products',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    final scheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSearchFocused
              ? scheme.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          width: _isSearchFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? scheme.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isSearchFocused ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search in ${widget.wardrobe.name}...',
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSearchFocused
                  ? scheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: _isSearchFocused
                  ? scheme.primary
                  : Colors.grey.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernFilters() {
    return Row(
      children: [
        // Brand Filter
        Expanded(
          child: _buildModernFilterDropdown(
            value: _selectedBrand,
            items: _availableBrands,
            onChanged: (value) {
              setState(() {
                _selectedBrand = value!;
              });
            },
            label: 'Brand',
            icon: Icons.branding_watermark_rounded,
          ),
        ),
        const SizedBox(width: 12),

        // Sort Filter
        Expanded(
          child: _buildModernFilterDropdown(
            value: _selectedSortBy,
            items: [
              'Recent',
              'Price: Low to High',
              'Price: High to Low',
              'Brand A-Z',
              'Name A-Z',
            ],
            onChanged: (value) {
              setState(() {
                _selectedSortBy = value!;
              });
            },
            label: 'Sort',
            icon: Icons.sort_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildModernFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: scheme.primary, size: 16),
                dropdownColor: Colors.white,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
                isExpanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    final scheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No products found'
                    : 'This wardrobe is empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search or filters'
                    : 'Add products to ${widget.wardrobe.name} to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return _buildEnhancedProductCard(product, index);
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildEnhancedProductCard(CardData product, int index) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = product.images.isNotEmpty
        ? product.images.first
        : 'assets/images/default_shoe.jpg';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductInfoPage(product: product),
          ),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 50)),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Product Image with Floating Elements
              Stack(
                children: [
                  // Main Image with Gradient Overlay
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                          // Gradient overlay for better text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Brand Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product.brand.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),

                  // Floating Price Badge
                  if (product.lowestAsk != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.lowestAsk!.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Floating Remove Button
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _showRemoveConfirmation(product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 16,
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Enhanced Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          product.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price (if not shown in badge)
                      if (product.lowestAsk == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Price unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveConfirmation(CardData product) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove from Wardrobe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${product.title}" from ${widget.wardrobe.name}?',
          style: TextStyle(
            fontSize: 16,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFromWardrobe(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWardrobe() async {
    try {
      await WardrobesService.deleteWardrobe(widget.wardrobe.id);

      // Update provider to reflect that this wardrobe is gone
      final wardrobesProvider =
          Provider.of<WardrobesProvider>(context, listen: false);
      await wardrobesProvider.deleteWardrobe(widget.wardrobe.id);
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wardrobe deleted'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Optionally, navigate away from the current screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete wardrobe: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeFromWardrobe(String productId) async {
    try {
      await WardrobesService.removeFromWardrobe(widget.wardrobe.id, productId);

      // Update local products list
      setState(() {
        _products.removeWhere((product) => product.id == productId);
      });

      // Update provider's wardrobe data to reflect the change
      final wardrobesProvider =
          Provider.of<WardrobesProvider>(context, listen: false);
      await wardrobesProvider.removeFromWardrobe(widget.wardrobe.id, productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product removed from wardrobe'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove product: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
