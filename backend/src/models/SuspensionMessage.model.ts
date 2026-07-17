import mongoose, { Schema, Document } from 'mongoose';

export interface ISuspensionMessage extends Document {
  suspensionId: string;
  senderRole: 'gym_owner' | 'superadmin';
  senderId: mongoose.Types.ObjectId;
  message: string;
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const SuspensionMessageSchema: Schema = new Schema(
  {
    suspensionId: { type: String, required: true, index: true },
    senderRole: { type: String, enum: ['gym_owner', 'superadmin'], required: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    message: { type: String, required: true },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export default mongoose.model<ISuspensionMessage>('SuspensionMessage', SuspensionMessageSchema);
