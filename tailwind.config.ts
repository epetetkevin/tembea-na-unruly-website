import type { Config } from 'tailwindcss';
const config: Config = { content: ['./app/**/*.{js,ts,jsx,tsx,mdx}'], theme: { extend: { colors: { ink:'#090909', gold:'#d7ad52', muted:'#a7a7a7' }, boxShadow: { gold:'0 0 35px rgba(215,173,82,.15)' } } }, plugins: [] };
export default config;
