import mongoose, { Schema, Document } from 'mongoose';

export interface IExpense extends Document {
  gymId: mongoose.Types.ObjectId;
  title: string;
  amount: number;
  date: Date;
  category: string; // 'Rent', 'Equipment', 'Salary', 'Utilities', 'Marketing'
  status: string; // 'Paid', 'Pending'
  createdAt: Date;
  updatedAt: Date;
}

const ExpenseSchema: Schema = new Schema(
  {
    gymId: { type: mongoose.Schema.Types.ObjectId, ref: 'Gym', required: true },
    title: { type: String, required: true },
    amount: { type: Number, required: true },
    date: { type: Date, default: Date.now },
    category: { type: String, default: 'Rent' },
    status: { type: String, default: 'Paid' },
  },
  { timestamps: true }
);

export default mongoose.model<IExpense>('Expense', ExpenseSchema);
