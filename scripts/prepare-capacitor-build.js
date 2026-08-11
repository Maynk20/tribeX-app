import fs from "node:fs";
import path from "node:path";

const publicDir = path.resolve(process.cwd(), ".output/public");
const assetsDir = path.join(publicDir, "assets");

if (!fs.existsSync(publicDir)) {
  console.error("[Capacitor Build Helper] Error: .output/public directory does not exist!");
  process.exit(1);
}

let cssFile = "";
let jsFile = "";

if (fs.existsSync(assetsDir)) {
  const files = fs.readdirSync(assetsDir);
  cssFile = files.find((f) => f.startsWith("styles-") && f.endsWith(".css")) || "";
  jsFile =
    files.find(
      (f) =>
        (f.startsWith("index-") || f.startsWith("client-") || f.startsWith("entry-")) &&
        f.endsWith(".js"),
    ) || "";
}

console.log(
  `[Capacitor Build Helper] Found CSS chunk: '${cssFile || "none"}', JS chunk: '${jsFile || "none"}'`,
);

const htmlContent = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover" />
    <title>tribeX — Find your crew, join the plan</title>
    <meta name="description" content="tribeX is a hyper-local activity discovery app." />
    <link rel="icon" href="./favicon.png" type="image/png" />
    <link rel="icon" href="./favicon.ico" />
    <link rel="apple-touch-icon" href="./favicon.png" />
    ${cssFile ? `<link rel="stylesheet" href="./assets/${cssFile}" />` : ""}
    <link rel="preconnect" href="https://ovknvssfrsuufuopbeqf.supabase.co" />
    <link rel="dns-prefetch" href="https://ovknvssfrsuufuopbeqf.supabase.co" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@700;800;900&display=swap" />
  </head>
  <body class="bg-background text-foreground antialiased select-none">
    <div id="root"></div>
    ${jsFile ? `<script type="module" src="./assets/${jsFile}"></script>` : ""}
  </body>
</html>`;

const indexPath = path.join(publicDir, "index.html");
fs.writeFileSync(indexPath, htmlContent, "utf-8");
console.log(`[Capacitor Build Helper] Generated ${indexPath} successfully!`);
