import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AKAD BUD Lab",
  description: "Hello World - AKAD BUD Laboratory",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
