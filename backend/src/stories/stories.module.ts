import { Module } from '@nestjs/common';
import { StoryController } from './stories.controller';
import { StoryService } from './stories.service';

@Module({
  controllers: [StoryController],
  providers: [StoryService],
})
export class StoryModule {}
