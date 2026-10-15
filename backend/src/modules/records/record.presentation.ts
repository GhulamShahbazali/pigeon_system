import { z } from 'zod';

export const CreateRecordSchema = z.object({
  record_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  fly_time: z.string().regex(/^\d{2}:\d{2}$/),
  total_pigeons: z.coerce.number().int().min(1).max(1000),
  privacy: z.enum(['private', 'live']).default('private'),
});
export type CreateRecordDto = z.infer<typeof CreateRecordSchema>;

export const AddPigeonSchema = z.object({
  pigeon_name: z.string().min(1).max(80),
  landing_time: z.string().datetime(),
});
export type AddPigeonDto = z.infer<typeof AddPigeonSchema>;

export function toRecord(r: any) {
  return {
    id: r.id,
    record_date: r.recordDate.toISOString().slice(0, 10),
    fly_time: r.flyTime,
    release_at: r.releaseAt ? r.releaseAt.toISOString() : null,
    total_pigeons: r.totalPigeons,
    privacy: r.privacy,
    status: r.status,
    total_avg_seconds: r.totalAvgSeconds,
    returned_count: r.returnedCount,
    like_count: r.likeCount,
    view_count: r.viewCount,
    went_live_at: r.wentLiveAt ? r.wentLiveAt.toISOString() : null,
    auto_end_at: r.autoEndAt ? r.autoEndAt.toISOString() : null,
    created_at: r.createdAt.toISOString(),
  };
}

export function toLivePreview(r: any) {
  return {
    id: r.id,
    total_avg_seconds: r.totalAvgSeconds,
    returned_count: r.returnedCount,
    total_pigeons: r.totalPigeons,
    like_count: r.likeCount,
    view_count: r.viewCount,
    owner: r.user
      ? { id: r.user.id, display_name: r.user.displayName, username: r.user.username, photo_url: r.user.photoUrl }
      : null,
  };
}

export function toRecordDetail(r: any) {
  return {
    ...toRecord(r),
    is_owner: r.isOwner ?? false,
    is_liked: r.isLiked ?? false,
    owner: r.user
      ? { id: r.user.id, display_name: r.user.displayName, username: r.user.username, photo_url: r.user.photoUrl }
      : null,
    pigeons: (r.pigeons ?? []).map((p: any) => ({
      id: p.id,
      pigeon_name: p.pigeonName,
      landing_time: p.landingTime.toISOString(),
      duration_seconds: p.durationSeconds,
    })),
  };
}
