import { defineConfig } from "@lovable.dev/vite-tanstack-config";

const isCapacitorBuild = process.env.CAPACITOR_BUILD === "true";

export default defineConfig({
  nitro: isCapacitorBuild ? false : undefined,
  tanstackStart: {
    server: { entry: "server" },
  },
  vite: {
    base: isCapacitorBuild ? "./" : "/",
    define: {
      "import.meta.env.VITE_ONESIGNAL_APP_ID": JSON.stringify(
        process.env.ONESIGNAL_APP_ID ?? process.env.VITE_ONESIGNAL_APP_ID ?? "",
      ),
    },
  },
});
