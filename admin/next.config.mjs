/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Bot avatars come from pravatar; post/cover images from loremflickr.
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'i.pravatar.cc' },
      { protocol: 'https', hostname: 'loremflickr.com' },
    ],
  },
};
export default nextConfig;
