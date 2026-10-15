export interface ProfileView {
  user: any;
  isFollowing: boolean;
  isBlocked: boolean;
  tournamentCount: number;
  postCount: number;
}

export interface UpdateProfileInput {
  displayName?: string;
  bio?: string;
  city?: string;
  photoUrl?: string;
}

export interface ISocialRepository {
  findProfileById(id: string, viewerId: string): Promise<ProfileView | null>;
  findProfileByUsername(username: string, viewerId: string): Promise<ProfileView | null>;
  updateProfile(userId: string, input: UpdateProfileInput): Promise<any>;
  blockExistsEitherWay(a: string, b: string): Promise<boolean>;
  follow(followerId: string, followeeId: string): Promise<boolean>; // false if already / blocked-handled by caller
  unfollow(followerId: string, followeeId: string): Promise<void>;
  block(blockerId: string, blockedId: string): Promise<void>;
  unblock(blockerId: string, blockedId: string): Promise<void>;
  listFollowers(userId: string, limit: number): Promise<any[]>;
  listFollowing(userId: string, limit: number): Promise<any[]>;
  listBlocks(userId: string, limit: number): Promise<any[]>;
}

export const SOCIAL_REPOSITORY = Symbol('SOCIAL_REPOSITORY');
