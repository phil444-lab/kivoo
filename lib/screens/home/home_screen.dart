import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/feature_card_model.dart';
import '../../models/category_model.dart';
import '../../models/item_model.dart';
import '../../models/location_model.dart';
import '../../components/feature_card.dart';
import '../../components/category_item.dart';
import '../../components/item_card.dart';
import '../auth/profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/category_service.dart';
import '../../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDark = true;
  String selectedLocation = 'Localisation';
  bool showLocationMenu = false;
  String searchQuery = '';
  String activeFilter = 'Tout';
  Set<int> savedItems = {};
  bool isListView = true;
  int _currentNavIndex = 0;

  final _locationService = LocationService();
  final _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  Country? _country;
  List<Department> _departments = [];
  List<City> _cities = [];
  List<District> _districts = [];
  Department? _selectedDepartment;
  City? _selectedCity;
  District? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _locationService.getCountries(),
      _categoryService.getParentCategories(),
    ]);

    final countries = results[0] as List<Country>;
    final cats = results[1] as List<CategoryModel>;

    if (!mounted) return;

    if (countries.isNotEmpty) {
      final country = countries.first;
      final deps = await _locationService.getDepartments(country.id);
      if (mounted) setState(() { _country = country; _departments = deps; });
    }

    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _onDepartmentSelected(Department dept) async {
    setState(() {
      _selectedDepartment = dept;
      _selectedCity = null;
      _selectedDistrict = null;
      _cities = [];
      _districts = [];
      selectedLocation = dept.name;
    });
    final cities = await _locationService.getCities(dept.id);
    if (mounted) setState(() => _cities = cities);
  }

  Future<void> _onCitySelected(City city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = [];
      selectedLocation = city.name;
    });
    final districts = await _locationService.getDistricts(city.id);
    if (mounted) setState(() => _districts = districts);
  }

  void _onDistrictSelected(District district) {
    setState(() {
      _selectedDistrict = district;
      selectedLocation = district.name;
    });
    Navigator.pop(context);
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => _LocationPickerSheet(
          isDark: isDark,
          countryName: _country?.name ?? 'Bénin',
          departments: _departments,
          cities: _cities,
          districts: _districts,
          selectedDepartment: _selectedDepartment,
          selectedCity: _selectedCity,
          selectedDistrict: _selectedDistrict,
          onDepartmentSelected: (d) async {
            await _onDepartmentSelected(d);
            setSheetState(() {});
          },
          onCitySelected: (c) async {
            await _onCitySelected(c);
            setSheetState(() {});
          },
          onDistrictSelected: _onDistrictSelected,
        ),
      ),
    );
  }

  static const List<FeatureCardModel> featureCards = [
    FeatureCardModel(
      id: 1,
      title: 'Offres Premium',
      subtitle: 'Jusqu\'à -60%',
      icon: FontAwesomeIcons.gift,
      borderColor: '#4f8ef7',
      darkBg: 'linear-gradient(145deg, #142035 0%, #0e1a2e 100%)',
      lightBg: 'linear-gradient(145deg, #deeaff 0%, #c8daff 100%)',
    ),
    FeatureCardModel(
      id: 2,
      title: 'Nouveautés',
      subtitle: 'Fraîchement arrivé',
      icon: FontAwesomeIcons.star,
      borderColor: '#22c55e',
      darkBg: 'linear-gradient(145deg, #0f2718 0%, #0a2014 100%)',
      lightBg: 'linear-gradient(145deg, #dcfce7 0%, #c5f4d4 100%)',
    ),
    FeatureCardModel(
      id: 3,
      title: 'Grandes Marques',
      subtitle: 'Vendeurs vérifiés',
      icon: FontAwesomeIcons.circleCheck,
      borderColor: '#f59e0b',
      darkBg: 'linear-gradient(145deg, #241a06 0%, #1c1404 100%)',
      lightBg: 'linear-gradient(145deg, #fef3c7 0%, #fde8a0 100%)',
    ),
    FeatureCardModel(
      id: 4,
      title: 'Soldes Flash',
      subtitle: 'Édition limitée',
      icon: FontAwesomeIcons.bolt,
      borderColor: '#a855f7',
      darkBg: 'linear-gradient(145deg, #1c0e34 0%, #160828 100%)',
      lightBg: 'linear-gradient(145deg, #f3e8ff 0%, #e9d5ff 100%)',
    ),
  ];

  static const List<ItemModel> trendingItems = [
    ItemModel(
      id: 1,
      title: 'iPhone 15 Pro Max — 256GB Natural Titanium',
      price: '₦950,000',
      location: 'Lagos Island, Lagos',
      condition: 'Neuf',
      time: 'Il y a 2h',
      photo: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 2,
      title: '2021 Toyota Camry XSE V6 — Low Mileage',
      price: '₦14,500,000',
      location: 'Ikeja GRA, Lagos',
      condition: 'Occasion importé',
      time: 'Il y a 5h',
      photo: 'https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 3,
      title: '3 Bedroom Apartment — Lekki Phase 1',
      price: '₦4,200,000/yr',
      location: 'Lekki Phase 1, Lagos',
      condition: 'À louer',
      time: 'Il y a 1j',
      photo: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=160&h=160&fit=crop&auto=format',
      verified: false,
    ),
    ItemModel(
      id: 4,
      title: 'Samsung Galaxy S24 Ultra — 512GB Titanium Black',
      price: '₦780,000',
      location: 'Wuse II, Abuja',
      condition: 'Légèrement utilisé',
      time: 'Il y a 3h',
      photo: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 5,
      title: 'MacBook Pro 16" M3 Max — 36GB RAM, 1TB',
      price: '₦1,850,000',
      location: 'Victoria Island, Lagos',
      condition: 'Neuf',
      time: 'Il y a 6h',
      photo: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=160&h=160&fit=crop&auto=format',
      verified: false,
    ),
  ];

  static const List<String> filters = ['Tout', 'Électronique', 'Véhicules', 'Immobilier', 'Mode'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (_currentNavIndex != 4) _buildHeader(context, themeProvider),
                if (_currentNavIndex != 4) _buildSearchBar(),
                Expanded(
                  child: _currentNavIndex == 4
                      ? const ProfileScreen(showAppBar: false)
                      : SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Featured section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'En Vedette',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        fontSize: Responsive.fontSize(context, 15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Voir tout',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontSize: Responsive.fontSize(context, 12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: featureCards.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: EdgeInsets.only(
                                      right: index < featureCards.length - 1 ? 12 : 0,
                                    ),
                                    child: FeatureCard(card: featureCards[index], isDark: isDark),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Categories section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Catégories',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                        fontSize: Responsive.fontSize(context, 15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Tout',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontSize: Responsive.fontSize(context, 12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const crossAxisCount = 4;
                                    const spacing = 12.0;
                                    const totalSpacing = spacing * (crossAxisCount - 1);
                                    final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                                    final aspectRatio = itemWidth / 90;

                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                        childAspectRatio: aspectRatio > 0 ? aspectRatio : 1.0,
                                      ),
                                      itemCount: _categories.isEmpty ? 8 : _categories.length,
                                      itemBuilder: (context, index) {
                                        if (_categories.isEmpty) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF232b34) : const Color(0xFFf0f2f5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          );
                                        }
                                        return CategoryItem(
                                          category: _categories[index],
                                          isDark: isDark,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Trending section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Tendances',
                                          style: TextStyle(
                                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                            fontSize: Responsive.fontSize(context, 15),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const FaIcon(FontAwesomeIcons.arrowTrendUp, color: Colors.white, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                'POPULAIRE',
                                                style: TextStyle(color: Colors.white, fontSize: Responsive.fontSize(context, 10), fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // View toggle
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF3d4752)
                                              : const Color(0xFF000000).withValues(alpha: 0.08),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => setState(() => isListView = true),
                                            icon: FaIcon(
                                              FontAwesomeIcons.list,
                                              size: 14,
                                              color: isListView
                                                  ? Colors.white
                                                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: isListView ? AppTheme.primaryBlue : Colors.transparent,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => setState(() => isListView = false),
                                            icon: FaIcon(
                                              FontAwesomeIcons.grip,
                                              size: 14,
                                              color: !isListView
                                                  ? Colors.white
                                                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: !isListView ? AppTheme.primaryBlue : Colors.transparent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Filter pills
                              SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filters.length,
                                  itemBuilder: (context, index) {
                                    final filter = filters[index];
                                    final isActive = activeFilter == filter;
                                    return Padding(
                                      padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
                                      child: FilterChip(
                                        label: Text(filter),
                                        onSelected: (_) => setState(() => activeFilter = filter),
                                        selected: isActive,
                                        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                        selectedColor: AppTheme.primaryBlue,
                                        labelStyle: TextStyle(
                                          color: isActive
                                              ? Colors.white
                                              : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                          fontSize: Responsive.fontSize(context, 12),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF3d4752)
                                              : const Color(0xFF000000).withValues(alpha: 0.08),
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Items list/grid
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: isListView
                                    ? Column(
                                        children: trendingItems
                                            .map((item) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 12),
                                                  child: ItemCard(item: item, isDark: isDark, onTap: () {}),
                                                ))
                                            .toList(),
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          const crossAxisCount = 2;
                                          const spacing = 12.0;
                                          final itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
                                          final aspectRatio = itemWidth / 245.0;

                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossAxisCount,
                                              crossAxisSpacing: spacing,
                                              mainAxisSpacing: spacing,
                                              childAspectRatio: aspectRatio,
                                            ),
                                            itemCount: trendingItems.length,
                                            itemBuilder: (context, index) => ItemCard(
                                              item: trendingItems[index],
                                              isDark: isDark,
                                              onTap: () {},
                                            ),
                                          );
                                        },
                                      ),
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            _buildFloatingBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
          padding: EdgeInsets.fromLTRB(16, isSmallScreen ? 8 : 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'KIVOO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          IconButton(
            onPressed: themeProvider.cycleTheme,
            icon: Icon(
              themeProvider.icon,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Location selector
          GestureDetector(
            onTap: _showLocationPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.locationDot, size: 13, color: AppTheme.primaryBlue),
                  const SizedBox(width: 5),
                  Text(
                    selectedLocation,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: Responsive.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.chevronDown,
                    size: 10,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Search field
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 13),
              ),
              decoration: InputDecoration(
                hintText: 'Je recherche...',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 13),
                ),
                prefixIcon: Align(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 15,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    final items = [
      _NavItem(FontAwesomeIcons.house, 'Accueil', 0),
      _NavItem(FontAwesomeIcons.heart, 'Favoris', 1),
      _NavItem(FontAwesomeIcons.plusCircle, 'Vendre', 2),
      _NavItem(FontAwesomeIcons.comment, 'Discussions', 3),
      _NavItem(FontAwesomeIcons.user, 'Profil', 4),
    ];

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final isSelected = _currentNavIndex == item.index;
                final isSell = item.index == 2;

                return GestureDetector(
                  onTap: () {
                    const protectedIndexes = [1, 2, 3];
                    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
                    if (protectedIndexes.contains(item.index) && !isAuthenticated) {
                      setState(() => _currentNavIndex = 4);
                      return;
                    }
                    setState(() => _currentNavIndex = item.index);
                  },
                  child: isSell
                      ? Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 20),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              item.icon,
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                              size: 20,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                                fontSize: Responsive.fontSize(context, 10),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final FaIconData icon;
  final String label;
  final int index;

  const _NavItem(this.icon, this.label, this.index);
}

class _LocationPickerSheet extends StatelessWidget {
  final bool isDark;
  final String countryName;
  final List<Department> departments;
  final List<City> cities;
  final List<District> districts;
  final Department? selectedDepartment;
  final City? selectedCity;
  final District? selectedDistrict;
  final ValueChanged<Department> onDepartmentSelected;
  final ValueChanged<City> onCitySelected;
  final ValueChanged<District> onDistrictSelected;

  const _LocationPickerSheet({
    required this.isDark,
    required this.countryName,
    required this.departments,
    required this.cities,
    required this.districts,
    required this.selectedDepartment,
    required this.selectedCity,
    required this.selectedDistrict,
    required this.onDepartmentSelected,
    required this.onCitySelected,
    required this.onDistrictSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: mutedColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Pays (fixe)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.earthAfrica, size: 13, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(countryName,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PickerColumn(
                  title: 'Département',
                  items: departments.map((d) => d.name).toList(),
                  selectedIndex: selectedDepartment != null ? departments.indexOf(selectedDepartment!) : -1,
                  onTap: (i) => onDepartmentSelected(departments[i]),
                  isDark: isDark, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor,
                ),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _PickerColumn(
                  title: 'Ville',
                  items: cities.map((c) => c.name).toList(),
                  selectedIndex: selectedCity != null ? cities.indexOf(selectedCity!) : -1,
                  onTap: (i) => onCitySelected(cities[i]),
                  isDark: isDark, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor,
                ),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _PickerColumn(
                  title: 'Quartier',
                  items: districts.map((d) => d.name).toList(),
                  selectedIndex: selectedDistrict != null ? districts.indexOf(selectedDistrict!) : -1,
                  onTap: (i) => onDistrictSelected(districts[i]),
                  isDark: isDark, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  const _PickerColumn({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(title,
                style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Divider(color: borderColor, height: 1),
          Expanded(
            child: items.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final isSelected = i == selectedIndex;
                      return GestureDetector(
                        onTap: () => onTap(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          color: isSelected
                              ? AppTheme.primaryBlue.withOpacity(0.12)
                              : Colors.transparent,
                          child: Text(
                            items[i],
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryBlue : textColor,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
