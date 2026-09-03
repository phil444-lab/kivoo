import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/data_cache_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../components/skeleton_card.dart';
import 'items_list_screen.dart';

class CategoryScreen extends StatefulWidget {

  const CategoryScreen({super.key, required this.category});
  final CategoryModel category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<CategoryModel> _subcategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dataCache = context.read<DataCacheProvider>();
    final subs = await dataCache.getSubCategories(widget.category.id);
    if (mounted) setState(() { _subcategories = subs; _loading = false; });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: kToolbarHeight + 8,
        title: Text(
          widget.category.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 16),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: Responsive.iconSize(context, 18), color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            if (_loading)
              ...List.generate(6, (index) => _buildSubcategorySkeleton(isDark))
            else if (_subcategories.isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.boxOpen, size: 40,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune sous-catégorie',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_subcategories.length, (index) {
                final sub = _subcategories[index];
                final subColor = Color(int.parse(sub.color.replaceFirst('#', '0xFF')));
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemsListScreen(
                          category: sub,
                          parentCategory: widget.category,
                          isSubcategory: true,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: subColor.withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: _buildIcon(sub.icon, subColor)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.label,
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  fontSize: Responsive.fontSize(context, 14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (sub.itemCount > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${sub.itemCount} article${sub.itemCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                                    fontSize: Responsive.fontSize(context, 11),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FaIcon(
                          FontAwesomeIcons.chevronRight,
                          size: 12,
                          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Skeleton d'une ligne de sous-catégorie
  Widget _buildSubcategorySkeleton(bool isDark) {
    final baseColor = isDark
        ? const Color(0xFF2a2f35)
        : const Color(0xFFE0E0E0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          // Icône
          SkeletonPulse(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonPulse(
                  child: Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SkeletonPulse(
                  child: Container(
                    width: 80,
                    height: 11,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Flèche
          SkeletonPulse(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(dynamic icon, Color color) {
    if (icon is IconData) return Icon(icon, color: color, size: Responsive.iconSize(context, 18));
    return FaIcon(icon, color: color, size: Responsive.iconSize(context, 18));
  }
}
