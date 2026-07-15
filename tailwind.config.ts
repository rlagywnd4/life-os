import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#17211d",
        paper: "#fbfaf7",
        line: "#d8ddd4",
        moss: "#5f7f63",
        berry: "#8c4b5d",
        sky: "#457b9d",
        amber: "#b8792d"
      }
    }
  },
  plugins: []
};

export default config;
