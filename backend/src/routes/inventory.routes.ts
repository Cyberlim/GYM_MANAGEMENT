import express from 'express';
import { protect } from '../middlewares/auth.middleware';
import { createInventory, getInventory, updateInventory, deleteInventory } from '../controllers/inventory.controller';

const router = express.Router();

router.use(protect);

router.post('/', createInventory);
router.get('/', getInventory);
router.put('/:id', updateInventory);
router.delete('/:id', deleteInventory);

export default router;
