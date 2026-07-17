import mongoose, { Schema, Document } from 'mongoose';

export interface IGym extends Document {
  ownerId: mongoose.Types.ObjectId;
  name: string;
  address: string;
  contactPhone: string;
  logo: string;
  subscriptionPlan?: string;
  trialActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const GymSchema: Schema = new Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },
    name: { type: String, required: true },
    address: { type: String, required: true },
    contactPhone: { type: String, required: true },
    logo: { type: String, default: '' },
    subscriptionPlan: { type: String },
    trialActive: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export default mongoose.model<IGym>('Gym', GymSchema);
