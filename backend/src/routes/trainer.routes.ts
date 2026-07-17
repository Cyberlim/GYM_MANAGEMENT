import express from 'express';
import { getTrainers, addTrainer, updateTrainer, deleteTrainer } from '../controllers/trainer.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getTrainers)
  .post(addTrainer);

router.route('/:id')
  .put(updateTrainer)
  .delete(deleteTrainer);

export default router;
