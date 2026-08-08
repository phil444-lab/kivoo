import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/feature_card_model.dart';
import '../../models/item_model.dart';
import '../../services/item_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../components/item_card.dart';
import 'item_detail_screen.dart';

class FeatureItemsScreen extends StatefulWidget {
  final FeatureCardModel feature;

  const FeatureItemsScreen({super.key, required this.feature});

  @override
  State<FeatureItemsScreen> createState() => _FeatureItemsScreenState();
}

class _FeatureItemsScreenState extends State<FeatureItemsScreen> {
  final _itemService = ItemService();
  List<ItemModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentPage = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final result = await _itemService.getItems(
      featureId: widget.feature.id,
      page: reset ? 1 : _currentPage + 1,
      limit: 20,
    );

    if (mounted) {
      if (result != null) {
        final itemsList = (result['items'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = result['pagination'] as Map<String, dynamic>;

        setState(() {
          if (reset) {
            _items = itemsList;
          } else {
            _items.addAll(itemsList);
          }
          _currentPage = pagination['currentPage'] as int;
          _hasMore = pagination['hasNext'] as bool;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    await _loadItems(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final featureColor = Color(int.parse(widget.feature.borderColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: featureColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.feature.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 16),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: Responsive.iconSize(context, 18), color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadItems(reset: true),
        color: featureColor,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        child: _buildBody(isDark, featureColor),
      ),
    );
  }

  Widget _buildBody(bool isDark, Color featureColor) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (_items.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.boxOpen,
                    size: 48,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Aucun article pour cette caractéristique',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMore();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 2;
          const spacing = 12.0;
          final itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
          // Hauteur totale : image 150px (grille) + contenu ~190px
          // Protéger contre les largeurs <= 0 (premier frame) qui rendraient l'aspectRatio négatif
          final aspectRatio = itemWidth > 0 ? itemWidth / 340.0 : 1.0;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  ),
                );
              }

              final item = _items[index];
              return ItemCard(
                item: item,
                isDark: isDark,
                imageHeight: 150,
                fillHeight: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}