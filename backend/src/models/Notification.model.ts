import mongoose, { Schema, Document } from 'mongoose';

export interface INotification extends Document {
  userId: mongoose.Types.ObjectId;
  title: string;
  message: string;
  type: 'registration' | 'payment' | 'system' | 'support' | 'broadcast';
  route?: string;
  broadcastId?: mongoose.Types.ObjectId;
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationSchema: Schema = new Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
      type: String,
      enum: ['registration', 'payment', 'system', 'support', 'broadcast'],
      required: true,
    },
    route: { type: String },
    broadcastId: { type: mongoose.Schema.Types.ObjectId, ref: 'Broadcast' },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

NotificationSchema.post('save', function (doc: any) {
  // A rough heuristic to check if this is a newly created document
  if (doc.createdAt && doc.updatedAt && doc.createdAt.getTime() === doc.updatedAt.getTime()) {
    // Dynamically import to avoid circular dependencies
    import('../services/push.service')
      .then(({ sendPushNotificationToUser }) => {
        sendPushNotificationToUser(doc.userId.toString(), {
          title: doc.title,
          body: doc.message,
          url: doc.route,
          type: doc.type,
        });
      })
      .catch((err) => console.error('Failed to send push notification from hook:', err));
  }
});

export default mongoose.model<INotification>('Notification', NotificationSchema);
