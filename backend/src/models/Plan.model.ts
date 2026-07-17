import mongoose, { Schema, Document } from 'mongoose';

export interface IPlan extends Document {
  gymId: mongoose.Types.ObjectId;
  name: string;
  price: number;
  discountPrice?: number;
  duration: string;
  features: string[];
  colorHex: string;
  currencySymbol: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const PlanSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    discountPrice: { type: Number },
    duration: { type: String, required: true },
    features: { type: [String], default: [] },
    colorHex: { type: String, default: '#CFFF50' },
    currencySymbol: { type: String, default: '₹' },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export default mongoose.model<IPlan>('Plan', PlanSchema);
