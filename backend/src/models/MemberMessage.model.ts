import mongoose, { Document, Schema } from 'mongoose';

export interface IMemberMessage extends Document {
  memberId: mongoose.Types.ObjectId;
  gymId: mongoose.Types.ObjectId;
  message: string;
  senderRole: 'member' | 'gym_owner';
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const memberMessageSchema = new Schema<IMemberMessage>(
  {
    memberId: { type: Schema.Types.ObjectId, ref: 'Member', required: true },
    gymId: { type: Schema.Types.ObjectId, ref: 'User', required: true }, // The Gym Owner
    message: { type: String, required: true },
    senderRole: { type: String, enum: ['member', 'gym_owner'], required: true },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// TTL index to automatically delete documents 30 days after creation
memberMessageSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

const MemberMessage = mongoose.model<IMemberMessage>('MemberMessage', memberMessageSchema);

export default MemberMessage;
