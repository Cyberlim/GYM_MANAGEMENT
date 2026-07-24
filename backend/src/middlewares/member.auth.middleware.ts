import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import Member from '../models/Member.model';

export interface MemberAuthRequest extends Request {
  member?: any;
}

export const protectMember = async (req: MemberAuthRequest, res: Response, next: NextFunction): Promise<void> => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      if (!token) throw new Error('Token is undefined');

      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_fallback') as any;

      req.member = await Member.findById(decoded.id).select('-password');
      
      if (!req.member) {
        res.status(401).json({ message: 'Not authorized, member not found' });
        return;
      }

      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};
