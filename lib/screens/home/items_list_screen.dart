import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/item_model.dart';
import '../../models/location_model.dart';
import '../../services/item_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../components/item_card.dart';
import 'item_detail_screen.dart';

class ItemsListScreen extends StatefulWidget {
  final CategoryModel category;
  final CategoryModel? parentCategory;
  final bool isSubcategory;

  const ItemsListScreen({
    super.key,
    required this.category,
    this.parentCategory,
    this.isSubcategory = false,
  });

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final _itemService = ItemService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _colorController = TextEditingController();
  final _brandController = TextEditingController();

  List<ItemModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  // Filtres
  String? _selectedCondition;
  String _selectedSort = 'newest';
  bool _showFilters = false;

  // Filtres localisation
  List<Department> _departments = [];
  List<City> _cities = [];
  List<District> _districts = [];
  Department? _selectedDepartment;
  City? _selectedCity;
  District? _selectedDistrict;

  // Filtre type de prix
  String? _selectedPriceType;

  final List<String> _conditions = [
    'new',
    'like_new',
    'good',
    'fair',
    'used',
  ];

  final Map<String, String> _conditionLabels = {
    'new': 'Neuf',
    'like_new': 'Comme neuf',
    'good': 'Bon état',
    'fair': 'État correct',
    'used': 'Occasion',
  };

  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Plus récent'},
    {'value': 'price_asc', 'label': 'Prix croissant'},
    {'value': 'price_desc', 'label': 'Prix décroissant'},
    {'value': 'popular', 'label': 'Plus populaire'},
  ];

  final List<Map<String, String>> _priceTypeOptions = [
    {'value': 'fixed', 'label': 'Prix fixe'},
    {'value': 'negotiable', 'label': 'Négociable'},
    {'value': 'rent', 'label': 'Location'},
    {'value': 'auction', 'label': 'Enchère'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final countries = await _locationService.getCountries();
    if (countries.isNotEmpty) {
      final deps = await _locationService.getDepartments(countries.first.id);
      if (mounted) setState(() => _departments = deps);
    }
  }

  Future<void> _onDepartmentSelected(Department? dept) async {
    setState(() {
      _selectedDepartment = dept;
      _selectedCity = null;
      _selectedDistrict = null;
      _cities = [];
      _districts = [];
    });
    if (dept != null) {
      final cities = await _locationService.getCities(dept.id);
      if (mounted) setState(() => _cities = cities);
    }
  }

  Future<void> _onCitySelected(City? city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = [];
    });
    if (city != null) {
      final districts = await _locationService.getDistricts(city.id);
      if (mounted) setState(() => _districts = districts);
    }
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
      categoryId: !widget.isSubcategory ? widget.category.id : null,
      subcategoryId: widget.isSubcategory ? widget.category.id : null,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      condition: _selectedCondition,
      minPrice: _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null,
      maxPrice: _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null,
      sort: _selectedSort,
      page: reset ? 1 : _currentPage + 1,
      departmentId: _selectedDepartment?.id,
      cityId: _selectedCity?.id,
      districtId: _selectedDistrict?.id,
      color: _colorController.text.isNotEmpty ? _colorController.text.trim() : null,
      brand: _brandController.text.isNotEmpty ? _brandController.text.trim() : null,
      priceType: _selectedPriceType,
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
          _totalPages = pagination['totalPages'] as int;
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

  void _applyFilters() {
    _loadItems(reset: true);
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    _colorController.clear();
    _brandController.clear();
    _selectedCondition = null;
    _selectedSort = 'newest';
    _selectedPriceType = null;
    _selectedDepartment = null;
    _selectedCity = null;
    _selectedDistrict = null;
    _cities = [];
    _districts = [];
    _loadItems(reset: true);
    setState(() => _showFilters = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final categoryColor = Color(int.parse(widget.category.color.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: kToolbarHeight + 8,
        title: Text(
          widget.isSubcategory && widget.parentCategory != null
              ? '${widget.parentCategory!.label} / ${widget.category.label}'
              : widget.category.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: Responsive.fontSize(context, 16),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: Responsive.iconSize(context, 18), color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: FaIcon(
              _showFilters ? FontAwesomeIcons.filter : FontAwesomeIcons.filter,
              size: Responsive.iconSize(context, 18),
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: categoryColor,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: Responsive.fontSize(context, 14),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: categoryColor,
                        size: Responsive.iconSize(context, 20),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: FaIcon(FontAwesomeIcons.circleXmark, size: Responsive.iconSize(context, 18)),
                              onPressed: () {
                                _searchController.clear();
                                _loadItems(reset: true);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _loadItems(reset: true),
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tri
                    DropdownButtonFormField<String>(
                      value: _selectedSort,
                      decoration: _filterDecoration('Trier par', isDark),
                      items: _sortOptions
                          .map((option) => DropdownMenuItem(
                                value: option['value'],
                                child: Text(
                                  option['label']!,
                                  style: TextStyle(
                                    fontSize: Responsive.fontSize(context, 13),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSort = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // État
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: _filterDecoration('État', isDark),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._conditions.map(
                          (condition) => DropdownMenuItem<String>(
                            value: condition,
                            child: Text(
                              _conditionLabels[condition]!,
                              style: TextStyle(fontSize: Responsive.fontSize(context, 13)),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCondition = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Type de prix
                    DropdownButtonFormField<String>(
                      value: _selectedPriceType,
                      decoration: _filterDecoration('Type de prix', isDark),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._priceTypeOptions.map(
                          (option) => DropdownMenuItem<String>(
                            value: option['value'],
                            child: Text(
                              option['label']!,
                              style: TextStyle(fontSize: Responsive.fontSize(context, 13)),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPriceType = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Prix min/max
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              fontSize: Responsive.fontSize(context, 13),
                            ),
                            decoration: _filterDecoration('Prix min (FCFA)', isDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              fontSize: Responsive.fontSize(context, 13),
                            ),
                            decoration: _filterDecoration('Prix max (FCFA)', isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Localisation : Département
                    DropdownButtonFormField<Department>(
                      value: _selectedDepartment,
                      decoration: _filterDecoration('Département', isDark),
                      items: [
                        const DropdownMenuItem<Department>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._departments.map(
                          (dept) => DropdownMenuItem<Department>(
                            value: dept,
                            child: Text(
                              dept.name,
                              style: TextStyle(fontSize: Responsive.fontSize(context, 13)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _onDepartmentSelected,
                    ),
                    const SizedBox(height: 12),

                    // Localisation : Ville
                    if (_cities.isNotEmpty)
                      DropdownButtonFormField<City>(
                        value: _selectedCity,
                        decoration: _filterDecoration('Ville', isDark),
                        items: [
                          const DropdownMenuItem<City>(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          ..._cities.map(
                            (city) => DropdownMenuItem<City>(
                              value: city,
                              child: Text(
                                city.name,
                                style: TextStyle(fontSize: Responsive.fontSize(context, 13)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: _onCitySelected,
                      ),
                    if (_cities.isNotEmpty) const SizedBox(height: 12),

                    // Localisation : Quartier
                    if (_districts.isNotEmpty)
                      DropdownButtonFormField<District>(
                        value: _selectedDistrict,
                        decoration: _filterDecoration('Quartier', isDark),
                        items: [
                          const DropdownMenuItem<District>(
                            value: null,
                            child: Text('Tous'),
                          ),
                          ..._districts.map(
                            (district) => DropdownMenuItem<District>(
                              value: district,
                              child: Text(
                                district.name,
                                style: TextStyle(fontSize: Responsive.fontSize(context, 13)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDistrict = value);
                        },
                      ),
                    if (_districts.isNotEmpty) const SizedBox(height: 12),

                    // Couleur
                    TextField(
                      controller: _colorController,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                      decoration: _filterDecoration('Couleur (ex: Noir)', isDark),
                    ),
                    const SizedBox(height: 12),

                    // Marque
                    TextField(
                      controller: _brandController,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        fontSize: Responsive.fontSize(context, 13),
                      ),
                      decoration: _filterDecoration('Marque (ex: Apple)', isDark),
                    ),
                    const SizedBox(height: 16),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Appliquer',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: categoryColor,
                              side: BorderSide(color: categoryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Liste des items
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadItems(reset: true),
              color: categoryColor,
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              child: _buildBody(isDark),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        fontSize: Responsive.fontSize(context, 12),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.boxOpen,
              size: 48,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun article trouvé',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 14),
              ),
            ),
          ],
        ),
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