import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../route/route_constants.dart';
import '../../utils/responsive.dart';
import '../../components/item_card.dart';
import '../../components/skeleton_card.dart';
import '../../providers/auth_provider.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {

  const FavoritesScreen({super.key, this.onBack});
  /// Callback appelé lors du clic sur le bouton retour.
  /// Si null, utilise Navigator.pop(context).
  final VoidCallback? onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger les favoris après le premier build pour éviter
    // "setState() or markNeedsBuild() called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.loadFavorites();

    if (mounted) {
      setState(() {
        _loading = false;
        _currentPage = 1;
        _hasMore = authProvider.favoriteItems.length >= 20;
      });
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_loadingMore || !_hasMore) return;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    _loadingMore = true;
    setState(() {});

    final result = await authProvider.loadMoreFavorites(page: _currentPage + 1);
    if (mounted) {
      setState(() {
        _currentPage = result?['currentPage'] ?? _currentPage;
        _hasMore = result?['hasNext'] ?? false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final authProvider = context.watch<AuthProvider>();
    final favoriteCount = authProvider.favoriteItemIds.length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          favoriteCount > 0 ? 'Mes favoris ($favoriteCount)' : 'Mes favoris',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.pop(context),
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: Responsive.iconSize(context, 18),
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return _buildSkeletonList(isDark);
    }

    final authProvider = context.watch<AuthProvider>();

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.lock,
              size: 64,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Connexion requise',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour voir vos favoris',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 13),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteConstants.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Se connecter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final favoriteItems = authProvider.favoriteItems;

    if (favoriteItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.heart,
              size: 64,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun favori pour le moment',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parcourez les annonces et ajoutez vos coups de cœur en favoris',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 13),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: favoriteItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == favoriteItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          );
        }
        final item = favoriteItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ItemCard(
            item: item,
            isDark: isDark,
            imageHeight: 300,
            fillHeight: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(item: item),
                ),
              );
            },
            onFavoriteToggle: () async {
              final success = await authProvider.removeFromFavorites(item.id);
              if (success && mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Retiré des favoris'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  /// Affiche une liste de cartes skeleton pendant le chargement initial
  Widget _buildSkeletonList(bool isDark) => ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonItemCard(isDark: isDark),
        );
      },
    );
}