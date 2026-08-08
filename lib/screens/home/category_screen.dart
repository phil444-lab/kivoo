import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import 'items_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = CategoryService();
  List<CategoryModel> _subcategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subs = await _service.getSubCategories(widget.category.id);
    if (mounted) setState(() { _subcategories = subs; _loading = false; });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final iconColor = Color(int.parse(widget.category.color.replaceFirst('#', '0xFF')));

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
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ))
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
                            color: subColor.withOpacity(isDark ? 0.15 : 0.1),
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

  Widget _buildIcon(dynamic icon, Color color) {
    if (icon is IconData) return Icon(icon, color: color, size: Responsive.iconSize(context, 18));
    return FaIcon(icon, color: color, size: Responsive.iconSize(context, 18));
  }
}
