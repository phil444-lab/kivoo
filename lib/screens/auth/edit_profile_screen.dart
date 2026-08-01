import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';
import '../../utils/responsive.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  // Controllers pour la localisation
  final _locationService = LocationService();
  late TextEditingController _customCountryController;
  late TextEditingController _customDepartmentController;
  late TextEditingController _customCityController;
  late TextEditingController _customDistrictController;

  // États pour la localisation
  bool _useCustomLocation = true;
  bool _isLoadingLocations = false;

  // Données des listes déroulantes
  List<Country> _countries = [];
  List<Department> _departments = [];
  List<City> _cities = [];
  List<District> _districts = [];

  // Sélections actuelles
  Country? _selectedCountry;
  Department? _selectedDepartment;
  City? _selectedCity;
  District? _selectedDistrict;

  File? _selectedImage;
  bool _isLoading = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();

    _customCountryController = TextEditingController();
    _customDepartmentController = TextEditingController();
    _customCityController = TextEditingController();
    _customDistrictController = TextEditingController();

    _loadUserLocation();
    _loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _customCountryController.dispose();
    _customDepartmentController.dispose();
    _customCityController.dispose();
    _customDistrictController.dispose();
    super.dispose();
  }

  void _loadUserLocation() {
    final user = context.read<AuthProvider>().user;
    if (user?.location != null && (user!.location as Map<String, dynamic>).isNotEmpty) {
      final location = UserLocation.fromJson(user.location as Map<String, dynamic>);
      if (!location.isEmpty) {
        _customCountryController.text = location.country;
        _customDepartmentController.text = location.department;
        _customCityController.text = location.city;
        _customDistrictController.text = location.district;
      }
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingLocations = true);
    final countries = await _locationService.getCountries();
    if (mounted) {
      setState(() {
        _countries = countries;
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadDepartments(String countryId) async {
    setState(() => _isLoadingLocations = true);
    final departments = await _locationService.getDepartments(countryId);
    if (mounted) {
      setState(() {
        _departments = departments;
        _cities = [];
        _districts = [];
        _selectedDepartment = null;
        _selectedCity = null;
        _selectedDistrict = null;
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadCities(String departmentId) async {
    setState(() => _isLoadingLocations = true);
    final cities = await _locationService.getCities(departmentId);
    if (mounted) {
      setState(() {
        _cities = cities;
        _districts = [];
        _selectedCity = null;
        _selectedDistrict = null;
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadDistricts(String cityId) async {
    setState(() => _isLoadingLocations = true);
    final districts = await _locationService.getDistricts(cityId);
    if (mounted) {
      setState(() {
        _districts = districts;
        _selectedDistrict = null;
        _isLoadingLocations = false;
      });
    }
  }

  Map<String, dynamic> _getLocationData() {
    if (_useCustomLocation) {
      return {
        'country': _customCountryController.text.trim(),
        'department': _customDepartmentController.text.trim(),
        'city': _customCityController.text.trim(),
        'district': _customDistrictController.text.trim(),
      };
    }

    return {
      'country': _selectedCountry?.name ?? _customCountryController.text.trim(),
      'department': _selectedDepartment?.name ?? _customDepartmentController.text.trim(),
      'city': _selectedCity?.name ?? _customCityController.text.trim(),
      'district': _selectedDistrict?.name ?? _customDistrictController.text.trim(),
    };
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // D'abord uploader la photo si une nouvelle image est sélectionnée
      if (_selectedImage != null) {
        try {
          await authProvider.uploadPhoto(_selectedImage!.path);
        } catch (e) {
          print('⚠️ Upload photo échoué, continuation sans changer la photo: $e');
        }
      }

      // Ensuite mettre à jour les autres champs avec la localisation
      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        currentPassword: _currentPasswordController.text.isNotEmpty
            ? _currentPasswordController.text
            : null,
        newPassword: _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
        location: _getLocationData(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        if (errorMessage.contains('email') || errorMessage.contains('Email')) {
          errorMessage = 'Cet email est déjà utilisé par un autre compte';
        } else if (errorMessage.contains('phone') || errorMessage.contains('Phone') || errorMessage.contains('téléphone')) {
          errorMessage = 'Ce numéro de téléphone est déjà utilisé par un autre compte';
        } else if (errorMessage.contains('Unique constraint')) {
          errorMessage = 'Cet email ou numéro de téléphone est déjà utilisé';
        } else if (errorMessage.contains('404')) {
          errorMessage = 'Erreur de connexion au serveur';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            border: Border.all(
                              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                              width: 3,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, widget) {
                                          return Center(
                                            child: Text(
                                              _nameController.text.isNotEmpty
                                                  ? _nameController.text[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 40,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.camera,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    hintText: 'Entrez votre nom',
                    prefixIcon: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        size: Responsive.iconSize(context, 18),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (value.trim().length < 2) {
                      return 'Le nom doit contenir au moins 2 caractères';
                    }
                    if (value.trim().length > 100) {
                      return 'Le nom ne peut pas dépasser 100 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: FaIcon(
                        FontAwesomeIcons.envelope,
                        size: Responsive.iconSize(context, 18),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format d\'email invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '01XXXXXXXX',
                    prefixIcon: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: FaIcon(
                        FontAwesomeIcons.phone,
                        size: Responsive.iconSize(context, 18),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de téléphone est requis';
                    }
                    final phoneRegex = RegExp(r'^01[0-9]{8}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Le numéro doit commencer par 01 et contenir 10 chiffres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Section Localisation
                _buildSectionTitle('Localisation', isDark),
                const SizedBox(height: 12),
                _buildLocationToggle(isDark),
                const SizedBox(height: 12),
                if (_useCustomLocation)
                  _buildCustomLocationFields(isDark)
                else
                  _buildSelectLocationFields(isDark),

                const SizedBox(height: 16),

                // Bouton pour afficher/masquer les champs de mot de passe
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPasswordFields = !_showPasswordFields;
                    });
                  },
                  icon: FaIcon(
                    _showPasswordFields
                        ? FontAwesomeIcons.chevronUp
                        : FontAwesomeIcons.chevronDown,
                    size: 12,
                  ),
                  label: Text(
                    _showPasswordFields
                        ? 'Masquer le mot de passe'
                        : 'Changer le mot de passe',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),

                if (_showPasswordFields) ...[
                  const SizedBox(height: 8),
                  // Current Password Field
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      hintText: 'Entrez votre mot de passe actuel',
                      prefixIcon: Align(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: FaIcon(
                          FontAwesomeIcons.lock,
                          size: Responsive.iconSize(context, 18),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          _obscureCurrentPassword
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                          size: Responsive.iconSize(context, 18),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscureCurrentPassword,
                    validator: (value) {
                      if (_showPasswordFields && (value == null || value.isEmpty)) {
                        return 'Le mot de passe actuel est requis';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      hintText: 'Minimum 8 caractères',
                      prefixIcon: Align(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: FaIcon(
                          FontAwesomeIcons.lock,
                          size: Responsive.iconSize(context, 18),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          _obscureNewPassword
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                          size: Responsive.iconSize(context, 18),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 8) {
                        return 'Le mot de passe doit contenir au moins 8 caractères';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
        fontSize: Responsive.fontSize(context, 18),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLocationToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextMuted.withOpacity(0.1)
              : AppTheme.lightTextMuted.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _useCustomLocation = true;
                  // Préremplir les champs de saisie avec les valeurs sélectionnées
                  if (_selectedCountry != null) {
                    _customCountryController.text = _selectedCountry!.name;
                  }
                  if (_selectedDepartment != null) {
                    _customDepartmentController.text = _selectedDepartment!.name;
                  }
                  if (_selectedCity != null) {
                    _customCityController.text = _selectedCity!.name;
                  }
                  if (_selectedDistrict != null) {
                    _customDistrictController.text = _selectedDistrict!.name;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _useCustomLocation
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.pen,
                      size: 14,
                      color: _useCustomLocation
                          ? AppTheme.primaryBlue
                          : isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saisir',
                      style: TextStyle(
                        color: _useCustomLocation
                            ? AppTheme.primaryBlue
                            : isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: 13,
                        fontWeight: _useCustomLocation ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30,
            child: VerticalDivider(width: 1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useCustomLocation = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_useCustomLocation
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.list,
                      size: 14,
                      color: !_useCustomLocation
                          ? AppTheme.primaryBlue
                          : isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sélectionner',
                      style: TextStyle(
                        color: !_useCustomLocation
                            ? AppTheme.primaryBlue
                            : isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: 13,
                        fontWeight: !_useCustomLocation ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildSelectLocationFields(bool isDark) {
    return Column(
      children: [
        // Pays
        _buildDropdownField<Country>(
          label: 'Pays',
          icon: FontAwesomeIcons.globe,
          value: _selectedCountry,
          items: _countries,
          getLabel: (c) => c.name,
          isLoading: _isLoadingLocations,
          onChanged: (country) {
            setState(() {
              _selectedCountry = country;
              _selectedDepartment = null;
              _selectedCity = null;
              _selectedDistrict = null;
              _departments = [];
              _cities = [];
              _districts = [];
            });
            if (country != null) {
              _loadDepartments(country.id);
            }
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Département
        if (_selectedCountry != null)
          _buildDropdownField<Department>(
            label: 'Département',
            icon: FontAwesomeIcons.mapLocation,
            value: _selectedDepartment,
            items: _departments,
            getLabel: (d) => d.name,
            isLoading: _isLoadingLocations,
            onChanged: (department) {
              setState(() {
                _selectedDepartment = department;
                _selectedCity = null;
                _selectedDistrict = null;
                _cities = [];
                _districts = [];
              });
              if (department != null) {
                _loadCities(department.id);
              }
            },
            isDark: isDark,
          ),
        if (_selectedCountry != null) const SizedBox(height: 12),

        // Ville
        if (_selectedDepartment != null)
          _buildDropdownField<City>(
            label: 'Ville',
            icon: FontAwesomeIcons.city,
            value: _selectedCity,
            items: _cities,
            getLabel: (c) => c.name,
            isLoading: _isLoadingLocations,
            onChanged: (city) {
              setState(() {
                _selectedCity = city;
                _selectedDistrict = null;
                _districts = [];
              });
              if (city != null) {
                _loadDistricts(city.id);
              }
            },
            isDark: isDark,
          ),
        if (_selectedDepartment != null) const SizedBox(height: 12),

        // Quartier
        if (_selectedCity != null)
          _buildDropdownField<District>(
            label: 'Quartier',
            icon: FontAwesomeIcons.locationDot,
            value: _selectedDistrict,
            items: _districts,
            getLabel: (d) => d.name,
            isLoading: _isLoadingLocations,
            onChanged: (district) {
              setState(() {
                _selectedDistrict = district;
              });
            },
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required FaIconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) getLabel,
    required bool isLoading,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppTheme.darkTextMuted.withOpacity(0.1)
                : AppTheme.lightTextMuted.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextMuted.withOpacity(0.1)
              : AppTheme.lightTextMuted.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Align(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: FaIcon(icon, size: Responsive.iconSize(context, 18)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 16),
              vertical: Responsive.padding(context, 14),
            ),
          ),
          hint: Text(
            'Sélectionnez un ${label.toLowerCase()}',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontSize: 14,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                getLabel(item),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCustomLocationFields(bool isDark) {
    return Column(
      children: [
        _buildCustomTextField(
          controller: _customCountryController,
          label: 'Pays',
          icon: FontAwesomeIcons.globe,
          hint: 'Ex: Bénin',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildCustomTextField(
          controller: _customDepartmentController,
          label: 'Département',
          icon: FontAwesomeIcons.mapLocation,
          hint: 'Ex: Littoral',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildCustomTextField(
          controller: _customCityController,
          label: 'Ville',
          icon: FontAwesomeIcons.city,
          hint: 'Ex: Cotonou',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildCustomTextField(
          controller: _customDistrictController,
          label: 'Quartier',
          icon: FontAwesomeIcons.locationDot,
          hint: 'Ex: Cadjehoun',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required FaIconData icon,
    required String hint,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Align(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: FaIcon(icon, size: Responsive.iconSize(context, 18)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}