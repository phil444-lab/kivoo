import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../models/category_model.dart';
import '../../models/location_model.dart';
import '../../models/feature_card_model.dart';
import '../../services/category_service.dart';
import '../../services/location_service.dart';
import '../../services/feature_card_service.dart';
import '../../services/item_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();

  final _categoryService = CategoryService();
  final _locationService = LocationService();
  final _featureCardService = FeatureCardService();
  final _itemService = ItemService();

  List<CategoryModel> _parentCategories = [];
  List<CategoryModel> _subCategories = [];
  List<Department> _departments = [];
  List<City> _cities = [];
  List<District> _districts = [];
  List<FeatureCardModel> _featureOptions = [];

  CategoryModel? _selectedParentCategory;
  CategoryModel? _selectedSubCategory;
  Department? _selectedDepartment;
  City? _selectedCity;
  District? _selectedDistrict;
  FeatureCardModel? _selectedFeature;

  String? _selectedCondition;
  final List<String> _conditions = ['new', 'like_new', 'good', 'fair', 'used'];

  final List<File> _images = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _categoryService.getParentCategories(),
      _locationService.getCountries(),
      _featureCardService.getFeaturedOptions(),
    ]);

    final cats = results[0] as List<CategoryModel>;
    final countries = results[1] as List<Country>;
    final features = results[2] as List<FeatureCardModel>;

    if (!mounted) return;

    if (countries.isNotEmpty) {
      final deps = await _locationService.getDepartments(countries.first.id);
      if (mounted) setState(() => _departments = deps);
    }

    if (mounted) {
      setState(() {
        _parentCategories = cats;
        _featureOptions = features;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 10 - _images.length;
    if (remaining <= 0) return;

    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    setState(() {
      _images.addAll(picked.map((x) => File(x.path)));
    });
  }

  Future<void> _removeImage(int index) async {
    setState(() => _images.removeAt(index));
  }

  Future<void> _onParentCategorySelected(CategoryModel? cat) async {
    setState(() {
      _selectedParentCategory = cat;
      _selectedSubCategory = null;
      _subCategories = [];
    });
    if (cat != null) {
      final subs = await _categoryService.getSubCategories(cat.id);
      if (mounted) setState(() => _subCategories = subs);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins 3 photos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une sous-catégorie'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour vendre un article'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _itemService.createItem(
      token: authProvider.token!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      categoryId: _selectedParentCategory!.id,
      subcategoryId: _selectedSubCategory!.id,
      images: _images,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      condition: _selectedCondition,
      departmentId: _selectedDepartment?.id,
      cityId: _selectedCity?.id,
      districtId: _selectedDistrict?.id,
      featureId: _selectedFeature?.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article publié avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la publication. Veuillez réessayer.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final borderColor = isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db);
    final sectionTitleStyle = TextStyle(
      color: textColor,
      fontSize: Responsive.fontSize(context, 15),
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Vendre un article',
          style: TextStyle(fontSize: Responsive.fontSize(context, 18)),
        ),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryBlue,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.padding(context, 16)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Photos (minimum 3)', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      _buildPhotoPicker(cardBg, borderColor, textColor),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Titre', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        decoration: _inputDecoration('Ex: iPhone 15 Pro Max', cardBg, borderColor),
                        validator: (v) => v == null || v.trim().length < 3 ? 'Le titre doit contenir au moins 3 caractères' : null,
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Catégorie', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      DropdownButtonFormField<CategoryModel>(
                        value: _selectedParentCategory,
                        isExpanded: true,
                        decoration: _inputDecoration('Sélectionner une catégorie', cardBg, borderColor),
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        items: _parentCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.label, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: _onParentCategorySelected,
                      ),
                      SizedBox(height: Responsive.dimension(context, 12)),
                      if (_subCategories.isNotEmpty)
                        DropdownButtonFormField<CategoryModel>(
                          value: _selectedSubCategory,
                          isExpanded: true,
                          decoration: _inputDecoration('Sélectionner une sous-catégorie', cardBg, borderColor),
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                          items: _subCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.label, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedSubCategory = v),
                        ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Marque', style: sectionTitleStyle),
                                SizedBox(height: Responsive.dimension(context, 8)),
                                TextFormField(
                                  controller: _brandController,
                                  style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                                  decoration: _inputDecoration('Ex: Apple', cardBg, borderColor),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: Responsive.dimension(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Couleur', style: sectionTitleStyle),
                                SizedBox(height: Responsive.dimension(context, 8)),
                                TextFormField(
                                  controller: _colorController,
                                  style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                                  decoration: _inputDecoration('Ex: Noir', cardBg, borderColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('État', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        isExpanded: true,
                        decoration: _inputDecoration('Sélectionner l\'état', cardBg, borderColor),
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(_conditionLabel(c)))).toList(),
                        onChanged: (v) => setState(() => _selectedCondition = v),
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Prix (FCFA)', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      TextFormField(
                        controller: _priceController,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Ex: 250000', cardBg, borderColor),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Le prix est requis';
                          final price = double.tryParse(v.trim());
                          if (price == null || price <= 0) return 'Prix invalide';
                          return null;
                        },
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Description', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        maxLines: 5,
                        decoration: _inputDecoration('Décrivez votre article...', cardBg, borderColor),
                        validator: (v) => v == null || v.trim().length < 10 ? 'La description doit contenir au moins 10 caractères' : null,
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Région', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      DropdownButtonFormField<Department>(
                        value: _selectedDepartment,
                        isExpanded: true,
                        decoration: _inputDecoration('Département', cardBg, borderColor),
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: _onDepartmentSelected,
                      ),
                      SizedBox(height: Responsive.dimension(context, 12)),
                      if (_cities.isNotEmpty)
                        DropdownButtonFormField<City>(
                          value: _selectedCity,
                          isExpanded: true,
                          decoration: _inputDecoration('Ville', cardBg, borderColor),
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: _onCitySelected,
                        ),
                      SizedBox(height: Responsive.dimension(context, 12)),
                      if (_districts.isNotEmpty)
                        DropdownButtonFormField<District>(
                          value: _selectedDistrict,
                          isExpanded: true,
                          decoration: _inputDecoration('Quartier', cardBg, borderColor),
                          dropdownColor: cardBg,
                          style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedDistrict = v),
                        ),
                      SizedBox(height: Responsive.dimension(context, 20)),

                      Text('Mise en avant', style: sectionTitleStyle),
                      SizedBox(height: Responsive.dimension(context, 8)),
                      DropdownButtonFormField<FeatureCardModel>(
                        value: _selectedFeature,
                        isExpanded: true,
                        decoration: _inputDecoration('Sélectionner (défaut: Nouveautés)', cardBg, borderColor),
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 14)),
                        items: _featureOptions.map((f) => DropdownMenuItem(value: f, child: Text(f.title))).toList(),
                        onChanged: (v) => setState(() => _selectedFeature = v),
                      ),
                      SizedBox(height: Responsive.dimension(context, 24)),

                      SizedBox(
                        width: double.infinity,
                        height: Responsive.dimension(context, 50),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.dimension(context, 12))),
                          ),
                          child: _isSubmitting
                              ? SizedBox(width: Responsive.dimension(context, 24), height: Responsive.dimension(context, 24), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Publier l\'article', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w700)),
                        ),
                      ),
                      SizedBox(height: Responsive.dimension(context, 20)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPhotoPicker(Color cardBg, Color borderColor, Color textColor) {
    return Column(
      children: [
        if (_images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: Responsive.dimension(context, 8),
              mainAxisSpacing: Responsive.dimension(context, 8),
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
                    child: Image.file(_images[index], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: Responsive.dimension(context, 4),
                    right: Responsive.dimension(context, 4),
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(Responsive.dimension(context, 4)),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: Responsive.iconSize(context, 14)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        SizedBox(height: Responsive.dimension(context, 8)),
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
          child: Container(
            width: double.infinity,
            height: Responsive.dimension(context, 80),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
              border: Border.all(color: borderColor, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.camera, color: AppTheme.primaryBlue, size: Responsive.iconSize(context, 24)),
                SizedBox(height: Responsive.dimension(context, 4)),
                Text(
                  '${_images.length}/10 photos',
                  style: TextStyle(color: textColor, fontSize: Responsive.fontSize(context, 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, Color cardBg, Color borderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        fontSize: Responsive.fontSize(context, 13),
      ),
      filled: true,
      fillColor: cardBg,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.padding(context, 12),
        vertical: Responsive.padding(context, 12),
      ),
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Responsive.dimension(context, 12)),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }

  String _conditionLabel(String condition) {
    switch (condition) {
      case 'new': return 'Neuf';
      case 'like_new': return 'Comme neuf';
      case 'good': return 'Bon état';
      case 'fair': return 'État correct';
      case 'used': return 'Occasion';
      default: return condition;
    }
  }

  bool get isDark {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDark;
  }
}