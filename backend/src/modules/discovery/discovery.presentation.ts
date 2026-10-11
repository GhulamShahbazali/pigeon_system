import { z } from 'zod';

/** Shared query shape for every search endpoint. */
export const SearchQuerySchema = z.object({
  q: z.string().trim().min(1).max(80),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});
export type SearchQueryDto = z.infer<typeof SearchQuerySchema>;

export function discoveryUserCard(u: any, isFollowing: boolean) {
  return {
    id: u.id,
    display_name: u.displayName,
    username: u.username,
    photo_url: u.photoUrl,
    city: u.city,
    country_code: u.countryCode,
    follower_count: u.followerCount,
    is_following: isFollowing,
  };
}

export function tournamentResult(t: any) {
  return {
    id: t.id,
    title: t.title,
    cover_url: t.coverUrl,
    status: t.status,
    num_days: t.numDays,
    follower_count: t.followerCount,
    link_slug: t.linkSlug,
    organizer: t.organizer
      ? { id: t.organizer.id, display_name: t.organizer.displayName, username: t.organizer.username, photo_url: t.organizer.photoUrl }
      : null,
  };
}

export function liveRecordResult(r: any) {
  return {
    id: r.id,
    total_avg_seconds: r.totalAvgSeconds,
    returned_count: r.returnedCount,
    total_pigeons: r.totalPigeons,
    like_count: r.likeCount,
    view_count: r.viewCount,
    went_live_at: r.wentLiveAt ? r.wentLiveAt.toISOString() : null,
    owner: r.user
      ? { id: r.user.id, display_name: r.user.displayName, username: r.user.username, photo_url: r.user.photoUrl }
      : null,
  };
}

export function conversationResult(c: any, other: any) {
  return {
    id: c.id,
    status: c.status,
    last_message_at: c.lastMessageAt ? c.lastMessageAt.toISOString() : null,
    other_user: other
      ? { id: other.id, display_name: other.displayName, username: other.username, photo_url: other.photoUrl }
      : null,
  };
}
