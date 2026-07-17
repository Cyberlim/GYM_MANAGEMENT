import express from 'express';
import { getMembers, addMember, updateMember, deleteMember } from '../controllers/member.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getMembers)
  .post(addMember);

router.route('/:id')
  .put(updateMember)
  .delete(deleteMember);

export default router;
