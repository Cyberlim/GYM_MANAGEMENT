import mongoose, { Schema, Document } from 'mongoose';

export interface IPayment extends Document {
  gymId: mongoose.Types.ObjectId;
  memberId: mongoose.Types.ObjectId;
  amount: number;
  currency: string;
  date: Date;
  paymentMethod: string; // 'Cash', 'Card', 'UPI', 'Bank Transfer'
  status: string; // 'Completed', 'Pending', 'Failed'
  description: string;
  createdAt: Date;
  updatedAt: Date;
}

const PaymentSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'USD' },
    date: { type: Date, default: Date.now },
    paymentMethod: { type: String, default: 'Cash' },
    status: { type: String, default: 'Completed' },
    description: { type: String, default: 'Membership fee' },
  },
  { timestamps: true }
);

export default mongoose.model<IPayment>('Payment', PaymentSchema);
