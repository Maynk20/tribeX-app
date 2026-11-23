import { n as HTTPResponse } from "../_libs/h3+rou3+srvx.mjs";
//#region #nitro/virtual/renderer-template
var rendererTemplate = () => new HTTPResponse("<!DOCTYPE html>\n<html lang=\"en\">\n\n<head>\n  <meta charset=\"utf-8\" />\n  <meta name=\"viewport\"\n    content=\"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover\" />\n  <title>tribeX — Find your crew, join the plan</title>\n  <meta name=\"description\"\n    content=\"tribeX is a hyper-local activity discovery app. Find box cricket, treks, jams, and pickup games happening near you tonight.\" />\n  <meta name=\"author\" content=\"tribeX\" />\n  <link rel=\"icon\" href=\"/favicon.png\" type=\"image/png\" />\n  <link rel=\"icon\" href=\"/favicon.ico\" />\n  <link rel=\"apple-touch-icon\" href=\"/favicon.png\" />\n  <link rel=\"preconnect\" href=\"https://ovknvssfrsuufuopbeqf.supabase.co\" />\n  <link rel=\"dns-prefetch\" href=\"https://ovknvssfrsuufuopbeqf.supabase.co\" />\n  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\" />\n  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin=\"anonymous\" />\n  <link rel=\"stylesheet\"\n    href=\"https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@700;800;900&display=swap\" />\n</head>\n\n<body class=\"bg-background text-foreground antialiased select-none\">\n  <div id=\"root\"></div>\n  <script type=\"module\" src=\"/src/entry-client.tsx\"><\/script>\n</body>\n\n</html>", { headers: { "content-type": "text/html; charset=utf-8" } });
//#endregion
//#region node_modules/nitro/dist/runtime/internal/routes/renderer-template.mjs
function renderIndexHTML(event) {
	return rendererTemplate(event.req);
}
//#endregion
export { renderIndexHTML as default };
