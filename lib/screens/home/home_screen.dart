import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/feature_card_model.dart';
import '../../models/category_model.dart';
import '../../models/item_model.dart';
import '../../components/feature_card.dart';
import '../../components/category_item.dart';
import '../../components/item_card.dart';
import '../auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDark = true;
  String selectedLocation = 'Lagos';
  bool showLocationMenu = false;
  String searchQuery = '';
  String activeFilter = 'Tout';
  Set<int> savedItems = {};
  bool isListView = true;
  int _currentNavIndex = 0;

  // Mock data
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

  static const List<CategoryModel> categories = [
    CategoryModel(
        id: 1,
        icon: FontAwesomeIcons.car,
        label: 'Véhicules',
        color: '#ff6b35'),
    CategoryModel(
        id: 2,
        icon: FontAwesomeIcons.house,
        label: 'Immobilier',
        color: '#4f8ef7'),
    CategoryModel(
        id: 3,
        icon: FontAwesomeIcons.mobileScreen,
        label: 'Téléphones',
        color: '#22c55e'),
    CategoryModel(
        id: 4,
        icon: FontAwesomeIcons.briefcase,
        label: 'Emplois',
        color: '#f59e0b'),
    CategoryModel(
        id: 5, icon: FontAwesomeIcons.shirt, label: 'Mode', color: '#ec4899'),
    CategoryModel(
        id: 6,
        icon: FontAwesomeIcons.chair,
        label: 'Meubles',
        color: '#06b6d4'),
    CategoryModel(
        id: 7, icon: FontAwesomeIcons.paw, label: 'Animaux', color: '#a855f7'),
    CategoryModel(
        id: 8,
        icon: FontAwesomeIcons.screwdriverWrench,
        label: 'Services',
        color: '#ef4444'),
  ];

  static const List<ItemModel> trendingItems = [
    ItemModel(
      id: 1,
      title: 'iPhone 15 Pro Max — 256GB Natural Titanium',
      price: '₦950,000',
      location: 'Lagos Island, Lagos',
      condition: 'Neuf',
      time: 'Il y a 2h',
      photo:
          'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 2,
      title: '2021 Toyota Camry XSE V6 — Low Mileage',
      price: '₦14,500,000',
      location: 'Ikeja GRA, Lagos',
      condition: 'Occasion importé',
      time: 'Il y a 5h',
      photo:
          'https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 3,
      title: '3 Bedroom Apartment — Lekki Phase 1',
      price: '₦4,200,000/yr',
      location: 'Lekki Phase 1, Lagos',
      condition: 'À louer',
      time: 'Il y a 1j',
      photo:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=160&h=160&fit=crop&auto=format',
      verified: false,
    ),
    ItemModel(
      id: 4,
      title: 'Samsung Galaxy S24 Ultra — 512GB Titanium Black',
      price: '₦780,000',
      location: 'Wuse II, Abuja',
      condition: 'Légèrement utilisé',
      time: 'Il y a 3h',
      photo:
          'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=160&h=160&fit=crop&auto=format',
      verified: true,
    ),
    ItemModel(
      id: 5,
      title: 'MacBook Pro 16" M3 Max — 36GB RAM, 1TB',
      price: '₦1,850,000',
      location: 'Victoria Island, Lagos',
      condition: 'Neuf',
      time: 'Il y a 6h',
      photo:
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=160&h=160&fit=crop&auto=format',
      verified: false,
    ),
  ];

  static const List<String> filters = [
    'Tout',
    'Électronique',
    'Véhicules',
    'Immobilier',
    'Mode'
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with KIVOO branding + search bar
            _buildHeader(context, themeProvider),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Featured section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'En Vedette',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Voir tout',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Feature cards horizontal scroll
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
                          child: FeatureCard(
                            card: featureCards[index],
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categories section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Catégories',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Tout',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Categories grid - fixed overflow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = 4;
                          final spacing = 12.0;
                          final totalSpacing = spacing * (crossAxisCount - 1);
                          final availableWidth =
                              constraints.maxWidth - totalSpacing;
                          final itemWidth = availableWidth / crossAxisCount;
                          final aspectRatio = itemWidth / (itemWidth + 40);

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) => CategoryItem(
                              category: categories[index],
                              isDark: isDark,
                            ),
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
                                  color: isDark
                                      ? AppTheme.darkText
                                      : AppTheme.lightText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.arrowTrendUp,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'POPULAIRE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3d4752)
                                    : const Color(0xFF000000)
                                        .withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isListView = true;
                                    });
                                  },
                                icon: Icon(
                                  FontAwesomeIcons.list,
                                  size: 14,
                                  color: isListView
                                      ? Colors.white
                                      : (isDark
                                          ? AppTheme.darkTextMuted
                                          : AppTheme.lightTextMuted),
                                ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: isListView
                                        ? AppTheme.primaryRed
                                        : Colors.transparent,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isListView = false;
                                    });
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.grip,
                                    size: 14,
                                    color: !isListView
                                        ? Colors.white
                                        : (isDark
                                            ? AppTheme.darkTextMuted
                                            : AppTheme.lightTextMuted),
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: !isListView
                                        ? AppTheme.primaryRed
                                        : Colors.transparent,
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
                            padding: EdgeInsets.only(
                                right: index < filters.length - 1 ? 8 : 0),
                            child: FilterChip(
                              label: Text(filter),
                              onSelected: (selected) {
                                setState(() {
                                  activeFilter = filter;
                                });
                              },
                              selected: isActive,
                              backgroundColor: isDark
                                  ? AppTheme.darkCard
                                  : AppTheme.lightCard,
                              selectedColor: AppTheme.primaryRed,
                              labelStyle: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? AppTheme.darkTextMuted
                                        : AppTheme.lightTextMuted),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF3d4752)
                                    : const Color(0xFF000000)
                                        .withValues(alpha: 0.08),
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
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: ItemCard(
                                          item: item,
                                          isDark: isDark,
                                          onTap: () {},
                                        ),
                                      ))
                                  .toList(),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = 2;
                                final spacing = 12.0;
                                final totalSpacing =
                                    spacing * (crossAxisCount - 1);
                                final availableWidth =
                                    constraints.maxWidth - totalSpacing;
                                final itemWidth =
                                    availableWidth / crossAxisCount;
                                final estimatedHeight = 245.0;
                                final aspectRatio = itemWidth / estimatedHeight;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
      bottomNavigationBar: _buildBottomNav(),
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
          colors: [Color(0xFFe42226), Color(0xFFbc171a)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFbc171a).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: EdgeInsets.fromLTRB(16, isSmallScreen ? 8 : 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo KIVOO
                Row(
                  children: [
                    const Text(
                      'KIVOO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Right icons
                Row(
                  children: [
                    // Theme toggle
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
          ),

          const SizedBox(height: 14),

          // Improved search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Location dropdown - compact
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showLocationMenu = !showLocationMenu;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.all(3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.locationDot,
                              size: 13,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1a1a1a),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                selectedLocation,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1a1a1a),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 1),
                            Icon(
                              FontAwesomeIcons.chevronDown,
                              size: 16,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1a1a1a),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search input
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF1a1a1a),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Je recherche...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : const Color(0xFF6b7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                    ),

                    // Search button
                    Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFe42226), Color(0xFFbc171a)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFbc171a).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Colors.white,
                        size: 18,
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
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(FontAwesomeIcons.house, 'Accueil', 0),
      _NavItem(FontAwesomeIcons.heart, 'Favoris', 1),
      _NavItem(FontAwesomeIcons.plusCircle, 'Vendre', 2),
      _NavItem(FontAwesomeIcons.comment, 'Discussions', 3),
      _NavItem(FontAwesomeIcons.user, 'Profil', 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF3d4752).withOpacity(0.3)
                : const Color(0xFF000000).withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = _currentNavIndex == item.index;

          // Special handling for Profil tab
          if (item.index == 4) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? AppTheme.primaryRed
                        : (isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted),
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.lightTextMuted),
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentNavIndex = item.index;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? AppTheme.primaryRed
                      : (isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted),
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryRed
                        : (isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem(this.icon, this.label, this.index);
}
