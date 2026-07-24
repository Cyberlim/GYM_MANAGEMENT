import mongoose, { Schema, Document } from 'mongoose';

export interface IBroadcast extends Document {
  gymId: mongoose.Types.ObjectId;
  subject: string;
  message: string;
  recipients: mongoose.Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

const BroadcastSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    subject: { type: String, required: true },
    message: { type: String, required: true },
    recipients: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Member' }],
  },
  { timestamps: true }
);

export default mongoose.model<IBroadcast>('Broadcast', BroadcastSchema);
