import { Router } from 'express';
import {
  getCountries,
  getDepartments,
  getCities,
  getDistricts,
  getAllLocations,
} from '../controllers/locationController.js';

const router = Router();

/**
 * @route   GET /api/locations
 * @desc    Récupérer toutes les localisations (pays, départements, villes, quartiers)
 * @access  Public
 */
router.get('/', getAllLocations);

/**
 * @route   GET /api/locations/countries
 * @desc    Récupérer tous les pays
 * @access  Public
 */
router.get('/countries', getCountries);

/**
 * @route   GET /api/locations/countries/:countryId/departments
 * @desc    Récupérer les départements d'un pays
 * @access  Public
 */
router.get('/countries/:countryId/departments', getDepartments);

/**
 * @route   GET /api/locations/departments/:departmentId/cities
 * @desc    Récupérer les villes d'un département
 * @access  Public
 */
router.get('/departments/:departmentId/cities', getCities);

/**
 * @route   GET /api/locations/cities/:cityId/districts
 * @desc    Récupérer les quartiers d'une ville
 * @access  Public
 */
router.get('/cities/:cityId/districts', getDistricts);

export default router;