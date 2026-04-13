import { Controller, Get, Post, Body, Query, BadRequestException } from '@nestjs/common';
import { CommentService } from './comments.service';

@Controller('comments')
export class CommentController {
  constructor(private readonly commentService: CommentService) {}

  @Get('get_comments')
  async getComments(@Query('post_id') postId: string, @Query('user_id') userId?: string) {
    if (!postId) throw new BadRequestException('Post ID is required');
    const result = await this.commentService.getComments(
      parseInt(postId),
      userId ? parseInt(userId) : undefined,
    );
    return { success: true, data: result };
  }

  @Post('add_comment')
  async addComment(@Body() body: any) {
    const { post_id, user_id, comment, parent_id } = body;
    const result = await this.commentService.addComment(
      parseInt(post_id),
      parseInt(user_id),
      comment,
      parent_id ? parseInt(parent_id) : undefined,
    );
    return { success: true, data: result };
  }

  @Post('toggle_comment_like')
  async toggleCommentLike(@Body() body: any) {
    const { comment_id, user_id } = body;
    const result = await this.commentService.toggleCommentLike(
      parseInt(comment_id),
      parseInt(user_id),
    );
    return { success: true, ...result };
  }
}
