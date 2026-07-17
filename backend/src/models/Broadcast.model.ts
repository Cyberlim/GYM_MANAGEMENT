import mongoose, { Schema, Document } from 'mongoose';

export interface IBroadcast extends Document {
  subject: string;
  message: string;
  recipients: mongoose.Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

const BroadcastSchema: Schema = new Schema(
  {
    subject: { type: String, required: true },
    message: { type: String, required: true },
    recipients: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

export default mongoose.model<IBroadcast>('Broadcast', BroadcastSchema);
