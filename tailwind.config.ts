import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx,mdx}", "./components/**/*.{js,ts,jsx,tsx,mdx}", "./lib/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        ink: "#18212f",
        paper: "#f6f7f9",
        line: "#d9dee8",
        brand: "#2563eb",
        danger: "#b42318"
      },
      boxShadow: {
        soft: "0 10px 28px rgba(24, 33, 47, 0.08)"
      }
    }
  },
  plugins: []
};

export default config;
