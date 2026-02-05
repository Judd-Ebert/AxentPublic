import 'package:Axent/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:Axent/views/pages/product_info_page.dart';
import 'package:Axent/views/pages/all_liked_products_page.dart';

class LikedProductsCarousel extends StatefulWidget {
  final List<dynamic> likedProducts;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const LikedProductsCarousel({
    super.key,
    required this.likedProducts,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<LikedProductsCarousel> createState() => _LikedProductsCarouselState();
}

class _LikedProductsCarouselState extends State<LikedProductsCarousel> {
  late ScrollController _scrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.offset;
      final itemsPerPage = 3;
      final itemWidth = 160.0 + 16.0; // card width + margin
      final totalPages = (widget.likedProducts.length / itemsPerPage).ceil();
      
      if (totalPages > 1) {
        final currentPage = (position / (itemWidth * itemsPerPage)).floor();
        final clampedPage = currentPage.clamp(0, totalPages - 1);
        
        if (clampedPage != _currentPage) {
          setState(() {
            _currentPage = clampedPage;
          });
        }
      } else {
        // Reset to 0 if there's only one page or no pages
        if (_currentPage != 0) {
          setState(() {
            _currentPage = 0;
          });
        }
      }
    }
  }

  void _jumpToPage(int page) {
    if (_scrollController.hasClients) {
      final itemsPerPage = 3;
      final itemWidth = 160.0 + 16.0;
      final jumpTo = page * itemsPerPage * itemWidth;
      
      _scrollController.animateTo(
        jumpTo,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<dynamic> get _recentProducts {
    // Get the most recent 15 products
    final recent = widget.likedProducts.take(15).toList();
    return recent.reversed.toList(); // Show newest first
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (_recentProducts.isEmpty) {
      return _buildEmptyState();
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withAlpha(128),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCarousel(),
          if (_recentProducts.length > 3) ...[
            const SizedBox(height: 16),
            _buildScrollIndicator(),
          ],
          const SizedBox(height: 16),
          _buildSeeMoreButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withAlpha(38),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 32,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No liked products yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to build your collection',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.favorite, color: scheme.error, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recently Liked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_recentProducts.length} recent items',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(153),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_recentProducts.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSecondary
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _recentProducts.length,
        itemBuilder: (context, index) {
          final product = _recentProducts[index];
          final cardData = CardData.fromJson(product);
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: _buildProductCard(cardData),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(CardData product) {
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
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white,
                        child: Image.asset(
                          'assets/images/default_shoe.jpg',
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Product Info
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      product.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black, // Hard set b/c background is always white(pictures are white)
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    
                    // Title
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black, // Hard set b/c background is always white(pictures are white)
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price
                    if (product.lowestAsk != null)
                      Text(
                        '\$${product.lowestAsk!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      Text(
                        'No price',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    final totalPages = (_recentProducts.length / 3).ceil() - 1;
    
    // Ensure _currentPage is within bounds
    final currentPage = _currentPage.clamp(0, totalPages - 1);
    
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          totalPages,
          (index) => GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _jumpToPage(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == currentPage ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index == currentPage 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllLikedProductsPage(
              likedProducts: widget.likedProducts,
              onRefresh: widget.onRefresh,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withAlpha(51),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'See All ${widget.likedProducts.length} Liked Products',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
} 