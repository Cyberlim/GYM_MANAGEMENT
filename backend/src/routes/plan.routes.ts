import express from 'express';
import { protect } from '../middlewares/auth.middleware';
import { getPlans, addPlan, updatePlan, deletePlan } from '../controllers/plan.controller';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getPlans)
  .post(addPlan);

router.route('/:id')
  .put(updatePlan)
  .delete(deletePlan);

export default router;
