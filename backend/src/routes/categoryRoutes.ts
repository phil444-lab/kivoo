import { Router } from 'express';
import { getCategories, getCategory, getSubcategories } from '../controllers/categoryController.js';

const router: Router = Router();

router.get('/', getCategories);
router.get('/:id/subcategories', getSubcategories);
router.get('/:id', getCategory);

export default router;