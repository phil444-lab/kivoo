import 'dart:async';
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
import '../../components/skeleton_card.dart';
import '../../screens/home/category_screen.dart';
import '../../screens/home/item_detail_screen.dart';
import '../../screens/home/favorites_screen.dart';
import '../../screens/home/feature_items_screen.dart';
import '../../screens/home/conversations_screen.dart';
import '../auth/profile_screen.dart';
import '../sell/sell_screen.dart';
import 'notifications_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/data_cache_provider.dart';
import '../../services/feature_card_service.dart';
import '../../services/item_service.dart';
import '../../services/conversation_service.dart';

import '../../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Global key pour accéder au HomeScreen depuis d'autres écrans
final homeScreenKey = GlobalKey<_HomeScreenState>();

class _HomeScreenState extends State<HomeScreen> {
  bool isDark = true;
  String selectedLocation = 'Localisation';
  bool showLocationMenu = false;
  String searchQuery = '';
  String activeFilter = 'Tout';
  bool isListView = true;
  int _currentNavIndex = 0;
  bool _wasAuthenticated = false;
  DateTime? _lastRefreshTime;
  Timer? _searchDebounce;
  String _debouncedSearchQuery = '';

  final _featureCardService = FeatureCardService();
  final _itemService = ItemService();
  final _conversationService = ConversationService();
  int _unreadCount = 0;
  List<CategoryModel> _categories = [];
  List<FeatureCardModel> _featureCards = [];
  List<ItemModel> _trendingItems = [];
  bool _trendingLoading = true;
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
    // Charger le compteur de messages non lus immédiatement
    // Ne pas attendre mounted car initState() est appelé avant le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
    });
    
    // Écouter les changements d'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.addListener(_onAuthChanged);
      }
    });
  }
  
  @override
  void dispose() {
    // Nettoyer le listener
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_onAuthChanged);
    _searchDebounce?.cancel();
    super.dispose();
  }
  
  /// Callback appelé quand l'état d'authentification change
  void _onAuthChanged() {
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    
    // Si l'utilisateur vient de se déconnecter, réinitialiser le compteur
    if (_wasAuthenticated && !isAuthenticated) {
      setState(() {
        _unreadCount = 0;
      });
    }
    // Si l'utilisateur vient de se connecter, charger le compteur
    else if (!_wasAuthenticated && isAuthenticated) {
      _loadUnreadCount();
    }
    
    // Mettre à jour l'état précédent
    _wasAuthenticated = isAuthenticated;
  }


  Future<void> _loadData() async {
    final dataCache = context.read<DataCacheProvider>();

    final countriesFuture = dataCache.getCountries();
    final catsFuture = dataCache.getParentCategories();
    final cardsFuture = _featureCardService.getFeaturedOptions();
    final trendingFuture = _itemService.getTrendingItems();

    final countries = await countriesFuture;
    final cats = await catsFuture;
    final cards = await cardsFuture;
    final trendingResult = await trendingFuture;
    final trending = (trendingResult?['items'] as List<ItemModel>?) ?? [];

    if (!mounted) return;

    if (countries.isNotEmpty) {
      final country = countries.first;
      final deps = await dataCache.getDepartments(country.id);
      if (mounted)
        setState(() {
          _country = country;
          _departments = deps;
        });
    }

    // Trier les articles du plus récent au plus ancien
    final sorted = List<ItemModel>.of(trending);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted)
      setState(() {
        _categories = cats;
        _featureCards = cards;
        _trendingItems = sorted;
        _trendingLoading = false;
      });
    
    // Charger le compteur de messages non lus après le chargement des données
    if (mounted) {
      await _loadUnreadCount();
    }
  }

  Future<void> _refreshData() async {
    // Éviter de recharger si le dernier refresh date de moins de 30 secondes
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 30 &&
        _trendingItems.isNotEmpty) {
      return;
    }
    _lastRefreshTime = now;

    // Recharger seulement les items, sans toucher aux catégories/localisation/featured
    // pour conserver les filtres et la sélection de localisation
    setState(() => _trendingLoading = true);
    try {
      final trendingResult = await _itemService.getTrendingItems();
      if (!mounted) return;
      final trending = (trendingResult?['items'] as List<ItemModel>?) ?? [];
      // Trier les articles du plus récent au plus ancien
      final sorted = List<ItemModel>.of(trending);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _trendingItems = sorted;
        _trendingLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _trendingLoading = false);
    }
    // Rafraîchir aussi le compteur de messages non lus
    await _loadUnreadCount();
  }

  Future<int> _loadUnreadCount() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return 0;
    
    final token = authProvider.token;
    if (token == null) return 0;
    
    try {
      final conversations = await _conversationService.getConversations(token: token);
      int total = 0;
      for (final conv in conversations) {
        total += conv.getUnreadCount(authProvider.user?.id ?? '');
      }
      if (mounted) {
        setState(() => _unreadCount = total);
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  void _resetLocation() {
    setState(() {
      _selectedDepartment = null;
      _selectedCity = null;
      _selectedDistrict = null;
      _cities = [];
      _districts = [];
      selectedLocation = 'Localisation';
    });
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
    final dataCache = context.read<DataCacheProvider>();
    final cities = await dataCache.getCities(dept.id);
    if (mounted) setState(() => _cities = cities);
  }

  Future<void> _onCitySelected(City city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = [];
      selectedLocation = city.name;
    });
    final dataCache = context.read<DataCacheProvider>();
    final districts = await dataCache.getDistricts(city.id);
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
          onReset: _resetLocation,
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

  /// Construit la liste des filtres dynamiquement :
  /// "Tout" + les noms des catégories principales chargées depuis l'API.
  List<String> get _filters {
    final cats = _categories.map((c) => c.label).toList();
    return ['Tout', ...cats];
  }

  /// Filtre dynamique combinant :
  /// - catégorie sélectionnée (_filters / activeFilter)
  /// - localisation sélectionnée (selectedLocation)
  /// - recherche texte (_debouncedSearchQuery)
  List<ItemModel> get _filteredItems {
    var items = _trendingItems;

    // Filtre par catégorie
    if (activeFilter != 'Tout' && activeFilter.isNotEmpty) {
      items = items.where((item) => item.categoryName == activeFilter).toList();
    }

    // Filtre par localisation
    if (selectedLocation != 'Localisation' && selectedLocation.isNotEmpty) {
      final query = selectedLocation.toLowerCase();
      items = items
          .where((item) => item.location.toLowerCase().contains(query))
          .toList();
    }

    // Filtre par recherche texte (avec debounce)
    if (_debouncedSearchQuery.isNotEmpty) {
      final query = _debouncedSearchQuery.toLowerCase();
      items = items.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            item.condition.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (_currentNavIndex != 1 &&
                    _currentNavIndex != 3 &&
                    _currentNavIndex != 4)
                  _buildHeader(context, themeProvider),
                if (_currentNavIndex != 1 &&
                    _currentNavIndex != 3 &&
                    _currentNavIndex != 4)
                  _buildSearchBar(),
                Expanded(
                  child: _currentNavIndex == 4
                      ? const ProfileScreen(showAppBar: false)
                      : _currentNavIndex == 1
                          ? FavoritesScreen(
                              onBack: () =>
                                  setState(() => _currentNavIndex = 0),
                            )
                          : _currentNavIndex == 3
                              ? ConversationsScreen(
                                  onBack: () =>
                                      setState(() => _currentNavIndex = 0),
                                )
                              : RefreshIndicator(
                                  onRefresh: _refreshData,
                                  color: AppTheme.primaryBlue,
                                  backgroundColor: isDark
                                      ? AppTheme.darkCard
                                      : AppTheme.lightCard,
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 20),

                                        SizedBox(
                                          height: 180,
                                          child: _featureCards.isEmpty
                                              ? ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  itemCount: 4,
                                                  itemBuilder: (_, __) =>
                                                      Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 12),
                                                    child: SkeletonBlock(
                                                      isDark: isDark,
                                                      width: 155,
                                                      height: 180,
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  itemCount:
                                                      _featureCards.length,
                                                  itemBuilder:
                                                      (context, index) =>
                                                          Padding(
                                                    padding: EdgeInsets.only(
                                                      right: index <
                                                              _featureCards
                                                                      .length -
                                                                  1
                                                          ? 12
                                                          : 0,
                                                    ),
                                                    child: FeatureCard(
                                                      card:
                                                          _featureCards[index],
                                                      isDark: isDark,
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                FeatureItemsScreen(
                                                              feature:
                                                                  _featureCards[
                                                                      index],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Categories section
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: Responsive.padding(
                                                  context, 16)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Catégories',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkText
                                                      : AppTheme.lightText,
                                                  fontSize: Responsive.fontSize(
                                                      context, 15),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              const crossAxisCount = 4;
                                              const spacing = 12.0;
                                              const totalSpacing = spacing *
                                                  (crossAxisCount - 1);
                                              final itemWidth =
                                                  (constraints.maxWidth -
                                                          totalSpacing) /
                                                      crossAxisCount;
                                              // hauteur totale = card carrée (itemWidth) + 4 spacing + 36 texte
                                              // Protéger contre les largeurs <= 0 (premier frame) qui rendraient l'aspectRatio négatif
                                              final aspectRatio = itemWidth > 0
                                                  ? itemWidth / (itemWidth + 40)
                                                  : 1.0;

                                              return GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      crossAxisCount,
                                                  crossAxisSpacing: spacing,
                                                  mainAxisSpacing: spacing,
                                                  childAspectRatio: aspectRatio,
                                                ),
                                                itemCount: _categories.isEmpty
                                                    ? 8
                                                    : _categories.length,
                                                itemBuilder: (context, index) {
                                                  if (_categories.isEmpty) {
                                                    return SkeletonBlock(
                                                      isDark: isDark,
                                                      height: 100,
                                                      borderRadius: 12,
                                                    );
                                                  }
                                                  return GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            CategoryScreen(
                                                                category:
                                                                    _categories[
                                                                        index]),
                                                      ),
                                                    ),
                                                    child: CategoryItem(
                                                      category:
                                                          _categories[index],
                                                      isDark: isDark,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // News/Actualités section
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Actualités',
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? AppTheme.darkText
                                                          : AppTheme.lightText,
                                                      fontSize:
                                                          Responsive.fontSize(
                                                              context, 15),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // View toggle
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppTheme.darkCard
                                                      : AppTheme.lightCard,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF3d4752)
                                                        : const Color(
                                                                0xFF000000)
                                                            .withValues(
                                                                alpha: 0.08),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () => setState(
                                                          () => isListView =
                                                              true),
                                                      icon: FaIcon(
                                                        FontAwesomeIcons.list,
                                                        size: 14,
                                                        color: isListView
                                                            ? Colors.white
                                                            : (isDark
                                                                ? AppTheme
                                                                    .darkTextMuted
                                                                : AppTheme
                                                                    .lightTextMuted),
                                                      ),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor:
                                                            isListView
                                                                ? AppTheme
                                                                    .primaryBlue
                                                                : Colors
                                                                    .transparent,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => setState(
                                                          () => isListView =
                                                              false),
                                                      icon: FaIcon(
                                                        FontAwesomeIcons.grip,
                                                        size: 14,
                                                        color: !isListView
                                                            ? Colors.white
                                                            : (isDark
                                                                ? AppTheme
                                                                    .darkTextMuted
                                                                : AppTheme
                                                                    .lightTextMuted),
                                                      ),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor:
                                                            !isListView
                                                                ? AppTheme
                                                                    .primaryBlue
                                                                : Colors
                                                                    .transparent,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            itemCount: _filters.length,
                                            itemBuilder: (context, index) {
                                              final filter = _filters[index];
                                              final isActive =
                                                  activeFilter == filter;
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                    right: index <
                                                            _filters.length - 1
                                                        ? 8
                                                        : 0),
                                                child: FilterChip(
                                                  label: Text(filter),
                                                  onSelected: (_) => setState(
                                                      () => activeFilter =
                                                          filter),
                                                  selected: isActive,
                                                  backgroundColor: isDark
                                                      ? AppTheme.darkCard
                                                      : AppTheme.lightCard,
                                                  selectedColor:
                                                      AppTheme.primaryBlue,
                                                  labelStyle: TextStyle(
                                                    color: isActive
                                                        ? Colors.white
                                                        : (isDark
                                                            ? AppTheme
                                                                .darkTextMuted
                                                            : AppTheme
                                                                .lightTextMuted),
                                                    fontSize:
                                                        Responsive.fontSize(
                                                            context, 12),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  side: BorderSide(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF3d4752)
                                                        : const Color(
                                                                0xFF000000)
                                                            .withValues(
                                                                alpha: 0.08),
                                                    width: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Items list/grid (filtrés selon la catégorie active)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: _trendingLoading
                                              ? _buildTrendingSkeleton()
                                              : _filteredItems.isEmpty
                                                  ? const SizedBox(
                                                      height: 120,
                                                      child: Center(
                                                        child: Text(
                                                          'Aucun article dans cette catégorie',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                                    )
                                                  : isListView
                                                      ? Column(
                                                          children:
                                                              _filteredItems
                                                                  .map((item) =>
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            bottom:
                                                                                12),
                                                                        child:
                                                                            ItemCard(
                                                                          item:
                                                                              item,
                                                                          isDark:
                                                                              isDark,
                                                                          onTap: () =>
                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder: (_) => ItemDetailScreen(item: item),
                                                                                ),
                                                                              ),
                                                                        ),
                                                                      ))
                                                                  .toList(),
                                                        )
                                                      : LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            const crossAxisCount =
                                                                2;
                                                            const spacing =
                                                                12.0;
                                                            final itemWidth =
                                                                (constraints.maxWidth -
                                                                        spacing) /
                                                                    crossAxisCount;
                                                            // Hauteur totale : image 150px (grille) + contenu ~190px
                                                            // Protéger contre les largeurs <= 0 (premier frame) qui rendraient l'aspectRatio négatif
                                                            final aspectRatio =
                                                                itemWidth > 0
                                                                    ? itemWidth /
                                                                        340.0
                                                                    : 1.0;

                                                            return GridView
                                                                .builder(
                                                              shrinkWrap: true,
                                                              physics:
                                                                  const NeverScrollableScrollPhysics(),
                                                              gridDelegate:
                                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount:
                                                                    crossAxisCount,
                                                                crossAxisSpacing:
                                                                    spacing,
                                                                mainAxisSpacing:
                                                                    spacing,
                                                                childAspectRatio:
                                                                    aspectRatio,
                                                              ),
                                                              itemCount:
                                                                  _filteredItems
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                final item =
                                                                    _filteredItems[
                                                                        index];
                                                                return ItemCard(
                                                                  item: item,
                                                                  isDark:
                                                                      isDark,
                                                                  imageHeight:
                                                                      150,
                                                                  fillHeight:
                                                                      true,
                                                                  onTap: () =>
                                                                      Navigator
                                                                          .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) =>
                                                                          ItemDetailScreen(
                                                                              item: item),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                        ),

                                        const SizedBox(height: 100),
                                      ],
                                    ),
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
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
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
          Row(
            children: [
              // Bouton notifications avec badge
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: FaIcon(
                          FontAwesomeIcons.bell,
                          color: Colors.white,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${notificationProvider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
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
                  color: isDark
                      ? const Color(0xFF3d4752)
                      : const Color(0xFFd1d5db),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.locationDot,
                      size: 13, color: AppTheme.primaryBlue),
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
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Search field
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() => searchQuery = value);
                // Debounce : attendre 300ms avant de filtrer
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() => _debouncedSearchQuery = value);
                  }
                });
              },
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 13),
              ),
              decoration: InputDecoration(
                hintText: 'Je recherche...',
                hintStyle: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 13),
                ),
                prefixIcon: Align(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 15,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3d4752)
                        : const Color(0xFFd1d5db),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF3d4752)
                        : const Color(0xFFd1d5db),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSkeleton() {
    if (isListView) {
      return Column(
        children: List.generate(
            3,
            (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SkeletonItemCard(isDark: isDark, imageHeight: 200),
                )),
      );
    }

    // Mode grille
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
        final aspectRatio = itemWidth > 0 ? itemWidth / 340.0 : 1.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => SkeletonGridCard(isDark: isDark),
        );
      },
    );
  }

  Future<void> _handleNavTap(int index) async {
    // Onglets protégés : Favoris (1), Vendre (2), Discussions (3)
    const protectedIndexes = [1, 2, 3];
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (protectedIndexes.contains(index) && !isAuthenticated) {
      // Rediriger vers l'onglet Profil (index 4) qui affiche l'écran de connexion/inscription
      setState(() => _currentNavIndex = 4);
      return;
    }

    // Bouton Vendre → ouvrir la page de vente
    if (index == 2) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellScreen()),
      );
      // Rafraîchir les données si un item a été créé/modifié
      if (result == true) {
        _refreshData();
      }
      return;
    }

    setState(() => _currentNavIndex = index);

    // Rafraîchir les données quand on clique sur l'onglet Accueil
    if (index == 0) {
      _refreshData();
    }
  }

  /// Méthode publique pour rafraîchir le compteur de messages non lus
  /// Peut être appelée depuis d'autres écrans (ex: après envoi de message)
  Future<void> refreshUnreadCount() async {
    await _loadUnreadCount();
  }

  Widget _buildFloatingBottomNav() {
    final items = [
      _NavItem(FontAwesomeIcons.house, 'Accueil', 0),
      _NavItem(FontAwesomeIcons.heart, 'Favoris', 1),
      _NavItem(FontAwesomeIcons.plusCircle, 'Vendre', 2),
      _NavItem(FontAwesomeIcons.comment, 'Discussions', 3, badgeCount: _unreadCount),
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
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final isSelected = _currentNavIndex == item.index;

                return GestureDetector(
                  onTap: () => _handleNavTap(item.index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FaIcon(
                            item.icon,
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                            size: 20,
                          ),
                          if (item.badgeCount > 0)
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppTheme.darkBackground : Colors.white, width: 2),
                                ),
                                child: Text(
                                  item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
  final int badgeCount;

  const _NavItem(this.icon, this.label, this.index, {this.badgeCount = 0});
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
  final VoidCallback onReset;
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
    required this.onReset,
    required this.onDepartmentSelected,
    required this.onCitySelected,
    required this.onDistrictSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor =
        isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: mutedColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Pays (fixe)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.earthAfrica,
                    size: 13, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(countryName,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const FaIcon(FontAwesomeIcons.rotateLeft,
                      size: 12, color: AppTheme.primaryBlue),
                  label: const Text('Tout',
                      style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
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
                  selectedIndex: selectedDepartment != null
                      ? departments.indexOf(selectedDepartment!)
                      : -1,
                  onTap: (i) => onDepartmentSelected(departments[i]),
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                ),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _PickerColumn(
                  title: 'Ville',
                  items: cities.map((c) => c.name).toList(),
                  selectedIndex:
                      selectedCity != null ? cities.indexOf(selectedCity!) : -1,
                  onTap: (i) => onCitySelected(cities[i]),
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                ),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _PickerColumn(
                  title: 'Quartier',
                  items: districts.map((d) => d.name).toList(),
                  selectedIndex: selectedDistrict != null
                      ? districts.indexOf(selectedDistrict!)
                      : -1,
                  onTap: (i) => onDistrictSelected(districts[i]),
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
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
                style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          color: isSelected
                              ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          child: Text(
                            items[i],
                            style: TextStyle(
                              color:
                                  isSelected ? AppTheme.primaryBlue : textColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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