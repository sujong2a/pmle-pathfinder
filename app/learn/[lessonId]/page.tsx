import { LessonClient } from "@/components/lesson-client";

export default async function LessonPage({ params }: { params: Promise<{ lessonId: string }> }) {
  const { lessonId } = await params;
  return <LessonClient lessonId={lessonId} />;
}
