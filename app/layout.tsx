import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PMLE Pathfinder",
  description: "Python 기초부터 PMLE 준비까지 이어지는 학습 운영 플랫폼 MVP"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
