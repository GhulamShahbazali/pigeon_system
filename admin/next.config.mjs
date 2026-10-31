/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',
  // Bot avatars come from pravatar; post/cover images from loremflickr.
  images: {
    unoptimized: true,
    remotePatterns: [
      { protocol: 'https', hostname: 'i.pravatar.cc' },
      { protocol: 'https', hostname: 'loremflickr.com' },
    ],
  },
};
export default nextConfig;
