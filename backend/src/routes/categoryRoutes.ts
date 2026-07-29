import { Router } from 'express';
import { getCategories, getCategory } from '../controllers/categoryController.js';

const router: Router = Router();

router.get('/', getCategories);
router.get('/:id', getCategory);

export default router;