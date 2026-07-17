import express from 'express';
import { getStaff, addStaff, updateStaff, deleteStaff } from '../controllers/staff.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getStaff)
  .post(addStaff);

router.route('/:id')
  .put(updateStaff)
  .delete(deleteStaff);

export default router;
