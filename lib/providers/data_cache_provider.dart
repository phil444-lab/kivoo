import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/location_model.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';

/// Provider qui charge les catégories et la localisation une seule fois
/// au démarrage et les partage entre tous les écrans.
class DataCacheProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  final LocationService _locationService = LocationService();

  // Catégories
  List<CategoryModel> _parentCategories = [];
  Map<String, List<CategoryModel>> _subCategoriesCache = {};
  bool _categoriesLoaded = false;
  bool _categoriesLoading = false;

  // Localisation
  List<Country> _countries = [];
  Map<String, List<Department>> _departmentsCache = {};
  Map<String, List<City>> _citiesCache = {};
  Map<String, List<District>> _districtsCache = {};
  bool _locationsLoaded = false;
  bool _locationsLoading = false;

  // Getters
  List<CategoryModel> get parentCategories => List.unmodifiable(_parentCategories);
  bool get categoriesLoaded => _categoriesLoaded;
  bool get categoriesLoading => _categoriesLoading;

  List<Country> get countries => List.unmodifiable(_countries);
  bool get locationsLoaded => _locationsLoaded;
  bool get locationsLoading => _locationsLoading;

  /// Charge les catégories parentes si pas déjà chargées
  Future<List<CategoryModel>> getParentCategories({bool forceRefresh = false}) async {
    if (_categoriesLoaded && !forceRefresh) {
      return _parentCategories;
    }
    if (_categoriesLoading) {
      // Attendre que le chargement en cours se termine
      await _waitForCategories();
      return _parentCategories;
    }

    _categoriesLoading = true;
    notifyListeners();

    try {
      _parentCategories = await _categoryService.getParentCategories();
      _categoriesLoaded = true;
    } catch (e) {
      debugPrint('⚠️ DataCacheProvider: Erreur chargement catégories: $e');
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }

    return _parentCategories;
  }

  /// Récupère les sous-catégories avec cache
  Future<List<CategoryModel>> getSubCategories(String parentId, {bool forceRefresh = false}) async {
    if (_subCategoriesCache.containsKey(parentId) && !forceRefresh) {
      return _subCategoriesCache[parentId]!;
    }

    final subs = await _categoryService.getSubCategories(parentId);
    _subCategoriesCache[parentId] = subs;
    notifyListeners();
    return subs;
  }

  /// Charge les pays et départements si pas déjà chargés
  Future<List<Country>> getCountries({bool forceRefresh = false}) async {
    if (_locationsLoaded && !forceRefresh) {
      return _countries;
    }
    if (_locationsLoading) {
      await _waitForLocations();
      return _countries;
    }

    _locationsLoading = true;
    notifyListeners();

    try {
      _countries = await _locationService.getCountries();
      _locationsLoaded = true;
    } catch (e) {
      debugPrint('⚠️ DataCacheProvider: Erreur chargement pays: $e');
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }

    return _countries;
  }

  /// Récupère les départements d'un pays avec cache
  Future<List<Department>> getDepartments(String countryId, {bool forceRefresh = false}) async {
    if (_departmentsCache.containsKey(countryId) && !forceRefresh) {
      return _departmentsCache[countryId]!;
    }

    final deps = await _locationService.getDepartments(countryId);
    _departmentsCache[countryId] = deps;
    notifyListeners();
    return deps;
  }

  /// Récupère les villes d'un département avec cache
  Future<List<City>> getCities(String departmentId, {bool forceRefresh = false}) async {
    if (_citiesCache.containsKey(departmentId) && !forceRefresh) {
      return _citiesCache[departmentId]!;
    }

    final cities = await _locationService.getCities(departmentId);
    _citiesCache[departmentId] = cities;
    notifyListeners();
    return cities;
  }

  /// Récupère les quartiers d'une ville avec cache
  Future<List<District>> getDistricts(String cityId, {bool forceRefresh = false}) async {
    if (_districtsCache.containsKey(cityId) && !forceRefresh) {
      return _districtsCache[cityId]!;
    }

    final districts = await _locationService.getDistricts(cityId);
    _districtsCache[cityId] = districts;
    notifyListeners();
    return districts;
  }

  /// Charge tout le cache au démarrage (catégories + localisation)
  Future<void> initialize() async {
    await Future.wait([
      getParentCategories(),
      getCountries(),
    ]);
  }

  /// Vide le cache (utile après une déconnexion ou un changement de données)
  void clearCache() {
    _parentCategories = [];
    _subCategoriesCache.clear();
    _categoriesLoaded = false;

    _countries = [];
    _departmentsCache.clear();
    _citiesCache.clear();
    _districtsCache.clear();
    _locationsLoaded = false;

    notifyListeners();
  }

  Future<void> _waitForCategories() async {
    while (_categoriesLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _waitForLocations() async {
    while (_locationsLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}