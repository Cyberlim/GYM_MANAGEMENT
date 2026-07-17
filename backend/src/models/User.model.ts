import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  name: string;
  email: string;
  phone?: string;
  password?: string;
  profileImage?: string;
  authProvider: 'local' | 'google';
  role: 'gym_owner' | 'superadmin';
  googleId?: string;
  isEmailVerified: boolean;
  emailVerificationCode?: string | undefined;
  passwordResetCode?: string | undefined;
  passwordResetExpires?: Date | undefined;
  settings?: {
    emailNotifications: boolean;
    pushNotifications: boolean;
    twoFactorEnabled: boolean;
    systemAlerts: boolean;
    newGymSignups: boolean;
    paymentReceived: boolean;
    paymentFailures: boolean;
  };
  twoFactorMethod: 'none' | 'email' | 'app';
  twoFactorSecret?: string | undefined;
  twoFactorOTP?: string | undefined;
  twoFactorOTPExpires?: Date | undefined;
  status: 'active' | 'suspended';
  suspensionId?: string;
  createdBy?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String },
    password: { type: String }, // Optional for Google sign-in
    profileImage: { type: String },
    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },
    role: { type: String, enum: ['gym_owner', 'superadmin'], default: 'gym_owner' },
    googleId: { type: String },
    isEmailVerified: { type: Boolean, default: false },
    emailVerificationCode: { type: String },
    passwordResetCode: { type: String },
    passwordResetExpires: { type: Date },
    settings: {
      emailNotifications: { type: Boolean, default: true },
      pushNotifications: { type: Boolean, default: true },
      twoFactorEnabled: { type: Boolean, default: false },
      systemAlerts: { type: Boolean, default: true },
      newGymSignups: { type: Boolean, default: true },
      paymentReceived: { type: Boolean, default: true },
      paymentFailures: { type: Boolean, default: true },
    },
    twoFactorMethod: { type: String, enum: ['none', 'email', 'app'], default: 'none' },
    twoFactorSecret: { type: String },
    twoFactorOTP: { type: String },
    twoFactorOTPExpires: { type: Date },
    status: { type: String, enum: ['active', 'suspended'], default: 'active' },
    suspensionId: { type: String },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

export default mongoose.model<IUser>('User', UserSchema);
