import { z } from 'zod';

export const CreatePostSchema = z.object({
  content: z.string().max(5000).optional(),
  image_url: z.string().url().optional(),
});
export type CreatePostDto = z.infer<typeof CreatePostSchema>;

export const ReportSchema = z.object({
  reason: z.enum(['spam', 'abuse', 'inappropriate', 'other']),
  note: z.string().max(500).optional(),
});
export type ReportDto = z.infer<typeof ReportSchema>;

export function toPost(p: any) {
  return {
    id: p.id,
    content: p.content,
    image_url: p.imageUrl,
    like_count: p.likeCount,
    share_count: p.shareCount,
    view_count: p.viewCount,
    is_liked: p.isLiked ?? false,
    author: p.author
      ? { id: p.author.id, display_name: p.author.displayName, username: p.author.username, photo_url: p.author.photoUrl }
      : null,
    created_at: p.createdAt.toISOString(),
  };
}
