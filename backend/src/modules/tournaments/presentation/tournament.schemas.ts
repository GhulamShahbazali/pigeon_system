import { z } from 'zod';

const hhmm = z.string().regex(/^\d{2}:\d{2}$/, 'HH:MM');
const ymd = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'YYYY-MM-DD');

export const CreateTournamentSchema = z.object({
  title: z.string().min(1).max(120),
  rules: z.string().max(5000).optional(),
  description: z.string().max(5000).optional(),
  cover_url: z.string().url().optional(),
  num_days: z.coerce.number().int().min(1).max(31),
  schedule_type: z.enum(['every_day', 'alternate_days']),
  pigeon_count: z.coerce.number().int().min(1).max(1000),
  fly_time: hhmm,
  end_time: hhmm,
  start_date: ymd,
  organizer_contact: z.string().max(40).optional(),
});
export type CreateTournamentDto = z.infer<typeof CreateTournamentSchema>;

export const AddParticipantSchema = z.object({
  name: z.string().min(1).max(80),
  photo_url: z.string().url().optional(),
  contact_no: z.string().max(40).optional(),
  phone: z.string().max(40).optional(),
  address: z.string().max(200).optional(),
});
export type AddParticipantDto = z.infer<typeof AddParticipantSchema>;

export const RecordFlightSchema = z.object({
  day_id: z.string().uuid(),
  pigeon_name: z.string().min(1).max(80),
  landing_time: z.string().datetime(),
});
export type RecordFlightDto = z.infer<typeof RecordFlightSchema>;

export const ListQuerySchema = z.object({
  tab: z.enum(['all', 'following', 'mine']).default('all'),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
export type ListQueryDto = z.infer<typeof ListQuerySchema>;
