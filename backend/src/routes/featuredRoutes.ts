import { Router } from 'express';
import { getFeaturedOptions } from '../controllers/featuredController.js';

const router: Router = Router();

router.get('/', getFeaturedOptions);

export default router;
