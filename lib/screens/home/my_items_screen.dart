import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../services/item_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../components/item_card.dart';
import '../../components/skeleton_card.dart';
import '../../providers/auth_provider.dart';
import 'item_detail_screen.dart';
import '../sell/sell_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  final _itemService = ItemService();
  List<ItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  Future<void> _loadMyItems() async {
    setState(() => _loading = true);
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await _itemService.getMyItems(token: token);
    final items = (result?['items'] as List<ItemModel>?) ?? [];
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Mes annonces',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: Responsive.iconSize(context, 18), 
            color: Colors.white
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyItems,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        child: _buildBody(isDark),
      ),
    );
  }

  Future<void> _toggleItemStatus(String? token, String itemId, bool activate) async {
    if (token == null) return;

    final success = activate
      ? await _itemService.activateItem(token: token, itemId: itemId)
      : await _itemService.deactivateItem(token: token, itemId: itemId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activate 
              ? 'Annonce activée avec succès' 
              : 'Annonce désactivée avec succès'),
            backgroundColor: activate ? Colors.green : Colors.orange,
          ),
        );
        await _loadMyItems();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activate 
              ? 'Erreur lors de l\'activation' 
              : 'Erreur lors de la désactivation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return _buildSkeletonList(isDark);
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.store,
              size: 48,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune annonce pour le moment',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première annonce en cliquant sur "Vendre"',
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
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              ItemCard(
                item: item,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                ),
              ),
              // Bouton modifier
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellScreen(item: item),
                      ),
                    );
                    if (result == true) {
                      await _loadMyItems();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.penToSquare, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Modifier',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bouton activer/désactiver
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    if (item.status == 'active') {
                      // Désactiver l'annonce
                      final confirm = await _showConfirmDialog(
                        'Désactiver l\'annonce',
                        'Voulez-vous désactiver cette annonce ? Elle ne sera plus visible publiquement.',
                      );
                      if (confirm == true) {
                        final authProvider = context.read<AuthProvider>();
                        final token = authProvider.token;
                        await _toggleItemStatus(token, item.id, false);
                      }
                    } else {
                      // Activer l'annonce
                      final confirm = await _showConfirmDialog(
                        'Activer l\'annonce',
                        'Voulez-vous activer cette annonce ? Elle sera à nouveau visible publiquement.',
                      );
                      if (confirm == true) {
                        final authProvider = context.read<AuthProvider>();
                        final token = authProvider.token;
                        await _toggleItemStatus(token, item.id, true);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.status == 'active' 
                        ? Colors.orange.withValues(alpha: 0.9)
                        : Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          item.status == 'active' 
                            ? FontAwesomeIcons.eyeSlash 
                            : FontAwesomeIcons.eye,
                          size: 13, 
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.status == 'active' ? 'Désactiver' : 'Activer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bouton supprimer
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final confirm = await _showConfirmDialog(
                      'Supprimer l\'annonce',
                      'Êtes-vous sûr de vouloir supprimer cette annonce ? Cette action est irréversible et supprimera également tous les commentaires et avis associés.',
                    );
                    if (confirm == true) {
                      final authProvider = context.read<AuthProvider>();
                      final token = authProvider.token;
                      if (token != null) {
                        final success = await _itemService.deleteItem(
                          token: token,
                          itemId: item.id,
                        );
                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Annonce supprimée avec succès'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            await _loadMyItems();
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de la suppression'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.trash, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Supprimer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Affiche une liste de cartes skeleton pendant le chargement
  Widget _buildSkeletonList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonItemCard(isDark: isDark),
        );
      },
    );
  }
}