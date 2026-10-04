import { z } from 'zod';

export const UpdateProfileSchema = z.object({
  display_name: z.string().min(1).max(60).optional(),
  bio: z.string().max(500).optional(),
  city: z.string().max(80).optional(),
  photo_url: z.string().url().optional(),
});
export type UpdateProfileDto = z.infer<typeof UpdateProfileSchema>;

export function userCard(u: any) {
  return {
    id: u.id,
    display_name: u.displayName,
    username: u.username,
    photo_url: u.photoUrl,
    city: u.city,
    country_code: u.countryCode,
    stats: { follower_count: u.followerCount, following_count: u.followingCount },
  };
}

export function profileResponse(v: any) {
  return {
    ...userCard(v.user),
    bio: v.user.bio,
    created_at: v.user.createdAt.toISOString(),
    stats: {
      follower_count: v.user.followerCount,
      following_count: v.user.followingCount,
      tournament_count: v.tournamentCount,
    },
    is_following: v.isFollowing,
    is_blocked: v.isBlocked,
  };
}
