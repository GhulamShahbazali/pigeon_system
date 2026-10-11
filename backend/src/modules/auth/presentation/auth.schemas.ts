import { z } from 'zod';

export const DeviceSchema = z.object({
  device_id: z.string().min(1),
  device_type: z.enum(['android', 'ios']),
  fcm_token: z.string().optional(),
  app_version: z.string().optional(),
});

export const SessionSchema = z.object({
  id_token: z.string().min(10),
  device_id: z.string().min(1),
  device_type: z.enum(['android', 'ios']),
  fcm_token: z.string().optional(),
  app_version: z.string().optional(),
});
export type SessionDto = z.infer<typeof SessionSchema>;

export const CompleteSignupSchema = z.object({
  display_name: z.string().min(1).max(60),
  username: z
    .string()
    .min(3)
    .max(30)
    .regex(/^[a-z0-9_.]+$/i, 'letters, numbers, _ and . only'),
  language_code: z.enum(['ur', 'hi', 'ar', 'en']),
  profile_photo_url: z.string().url().optional(),
  timezone: z.string().optional(),
  device_id: z.string().min(1),
  device_type: z.enum(['android', 'ios']),
  fcm_token: z.string().optional(),
  app_version: z.string().optional(),
});
export type CompleteSignupDto = z.infer<typeof CompleteSignupSchema>;

export const AdminLoginSchema = z.object({
  username: z.string().min(1).max(60),
  password: z.string().min(1).max(200),
});
export type AdminLoginDto = z.infer<typeof AdminLoginSchema>;
