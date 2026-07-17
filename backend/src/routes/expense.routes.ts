import express from 'express';
import { getExpensesByGym, createExpense, updateExpense, deleteExpense } from '../controllers/expense.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.get('/', getExpensesByGym);
router.post('/', createExpense);
router.put('/:id', updateExpense);
router.delete('/:id', deleteExpense);

export default router;
