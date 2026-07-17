import express from 'express';
import { protect } from '../middlewares/auth.middleware';
import { createEquipment, getEquipment, updateEquipment, deleteEquipment } from '../controllers/equipment.controller';

const router = express.Router();

router.use(protect);

router.post('/', createEquipment);
router.get('/', getEquipment);
router.put('/:id', updateEquipment);
router.delete('/:id', deleteEquipment);

export default router;
