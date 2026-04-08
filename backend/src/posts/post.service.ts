import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PostService {
  constructor(private prisma: PrismaService) {}

  // Helper method to format post for Flutter (snake_case)
  private formatPostForFlutter(post: any) {
    return {
      id: post.id?.toString(),
      user_id: post.userId?.toString(),
      name: post.user?.name,
      username: post.user?.username,
      photo: post.user?.photo,
      content: post.content,
      image_url: post.mediaUrl, // Maps to image_url expected by Flutter
      media_type: post.mediaType,
      likes: post._count?.likes || 0,
      comments_count: post._count?.comments || 0,
      created_at: post.createdAt,
      time: post.createdAt?.toISOString(),
      isLiked: post.likes && post.likes.length > 0,
      repost_id: post.repostId?.toString(),
      original_post: post.repost ? this.formatPostForFlutter(post.repost) : null
    };
  }

  async getPosts(user_id: string, limit: string = '10', offset: string = '0') {
    if (!user_id || isNaN(parseInt(user_id))) return [];

    const posts = await this.prisma.post.findMany({
      take: parseInt(limit),
      skip: parseInt(offset),
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true } },
        likes: { where: { userId: parseInt(user_id) } },
        repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
      }
    });

    return posts.map(post => this.formatPostForFlutter(post));
  }

  async getVideos(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];

    const posts = await this.prisma.post.findMany({
      where: {
        OR: [
          { mediaType: { contains: 'video' } },
          { mediaUrl: { contains: '.mp4' } },
          { mediaUrl: { contains: '.mov' } },
          { mediaUrl: { contains: '.avi' } }
        ]
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true } },
        likes: { where: { userId: parseInt(user_id) } }
      }
    });

    return posts.map(post => this.formatPostForFlutter(post));
  }

  async createPost(data: any, file?: any) {
    const { user_id, content, privacy, media_type } = data;
    const post = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        content,
        privacy: privacy || 'public',
        mediaType: file ? (file.mimetype.startsWith('video') ? 'video' : (file.mimetype.startsWith('image') ? 'image' : 'video')) : (media_type || 'text'),
        mediaUrl: file ? `/uploads/${file.filename}` : null
      },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true } }
      }
    });
    return this.formatPostForFlutter(post);
  }

  async repostPost(user_id: string, post_id: string) {
    const originalPost = await this.prisma.post.findUnique({ where: { id: parseInt(post_id) } });
    if (!originalPost) throw new NotFoundException('المنشور غير موجود');

    const newPost = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        repostId: parseInt(post_id),
        privacy: 'public',
        mediaType: 'text',
      }
    });
    return { success: true, message: 'تم إعادة النشر بنجاح' };
  }

  async toggleLike(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingLike = await this.prisma.like.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingLike) {
      await this.prisma.like.delete({ where: { id: existingLike.id } });
      return { message: 'Like removed', isLiked: false };
    } else {
      await this.prisma.like.create({ data: { userId: uid, postId: pid } });
      return { message: 'Post liked', isLiked: true };
    }
  }

  async toggleSave(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingSave = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingSave) {
      await this.prisma.savedPost.delete({ where: { id: existingSave.id } });
      return { message: 'Save removed', saved: false };
    } else {
      await this.prisma.savedPost.create({ data: { userId: uid, postId: pid } });
      return { message: 'Post saved', saved: true };
    }
  }

  async getSavedPosts(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];
    
    const saved = await this.prisma.savedPost.findMany({
      where: { userId: parseInt(user_id) },
      include: {
        post: {
          include: {
            user: { select: { id: true, name: true, username: true, photo: true } },
            _count: { select: { likes: true, comments: true } },
            likes: { where: { userId: parseInt(user_id) } },
            repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return saved.map(s => this.formatPostForFlutter(s.post));
  }

  async deletePost(user_id: string, post_id: string) {
    const post = await this.prisma.post.findUnique({ where: { id: parseInt(post_id) } });
    if (!post) throw new NotFoundException('المنشور غير موجود');
    if (post.userId !== parseInt(user_id)) throw new ForbiddenException('غير مصرح لك بحذف هذا المنشور');
    
    await this.prisma.post.delete({ where: { id: post.id } });
    return { message: 'تم حذف المنشور بنجاح' };
  }
}
