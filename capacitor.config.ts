import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.tribex.app",
  appName: "tribeX",
  webDir: ".output/public",
  server: {
    hostname: "localhost",
  },
};

export default config;
