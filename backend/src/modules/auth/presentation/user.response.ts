import { UserRecord } from '../domain/auth.repository';

/** Explicit response shape — never leaks email or internal fields. */
export function toUserResponse(u: UserRecord) {
  return {
    id: u.id,
    display_name: u.displayName,
    username: u.username,
    photo_url: u.photoUrl,
    bio: u.bio,
    city: u.city,
    country_code: u.countryCode,
    language_code: u.languageCode,
    role: u.role,
    stats: {
      follower_count: u.followerCount,
      following_count: u.followingCount,
    },
    created_at: u.createdAt.toISOString(),
  };
}
