import express from 'express';
import { getMembers, addMember, updateMember, deleteMember } from '../controllers/member.controller';
import { 
  getMembersWithMessages, 
  getGymOwnerMemberMessages, 
  sendGymOwnerMemberMessage, 
  markGymOwnerMemberMessagesAsRead 
} from '../controllers/gymOwner.support.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getMembers)
  .post(addMember);

router.route('/:id')
  .put(updateMember)
  .delete(deleteMember);

// Gym Owner Support Routes
router.get('/support/users', getMembersWithMessages);
router.get('/support/:memberId', getGymOwnerMemberMessages);
router.post('/support/:memberId', sendGymOwnerMemberMessage);
router.put('/support/:memberId/read', markGymOwnerMemberMessagesAsRead);

export default router;
