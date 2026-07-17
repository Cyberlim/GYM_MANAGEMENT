import express from 'express';
import { getPaymentsByGym, createPayment, updatePaymentStatus, updatePayment, deletePayment } from '../controllers/payment.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.get('/', getPaymentsByGym);
router.post('/', createPayment);
router.patch('/:id/status', updatePaymentStatus);
router.put('/:id', updatePayment);
router.delete('/:id', deletePayment);

export default router;
