import { Inter } from "next/font/google";
import "./globals.css";
import Link from "next/link";
// import { useState } from "react";
import { Nav } from "./components/Nav";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "TokenFlow",
  description: "Generated by create next app",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className={`${inter.className} mt-4`}>
        <Nav />
        {children}
        <footer className="flex justify-center mb-0 mt-[6rem]">
          Copyrights &copy; 2023
        </footer>
      </body>
    </html>
  );
}
