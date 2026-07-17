import express from 'express';
import { getEvents, createEvent, deleteEvent } from '../controllers/event.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getEvents)
  .post(createEvent);

router.route('/:eventId')
  .delete(deleteEvent);

export default router;
