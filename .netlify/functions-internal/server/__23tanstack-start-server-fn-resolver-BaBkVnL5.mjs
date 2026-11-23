//#region node_modules/.nitro/vite/services/ssr/assets/__23tanstack-start-server-fn-resolver-BaBkVnL5.js
var manifest = {
	"1c3f60340e6cffa28db7486b10fb3af65e2895164fcc6f0c6290e737ffe6498b": {
		functionName: "notifyUrgentSpot_createServerFn_handler",
		importer: () => import("./_ssr/urgent-push.functions-C8AdjJyK.mjs")
	},
	"59079731bf03f9a8585d9cec8d6c6f695db0d66e5ee6aba0348419c557e3c85e": {
		functionName: "verifySignUpOtp_createServerFn_handler",
		importer: () => import("./_ssr/otp-auth.functions-DlSk54jp.mjs")
	},
	"608745bb459720619a94d10a6e3bb42f54aa016ac1fb9c227451b745add0e540": {
		functionName: "requestSignUpOtp_createServerFn_handler",
		importer: () => import("./_ssr/otp-auth.functions-DlSk54jp.mjs")
	},
	"6573fa17d594216ecd66e568692b3abb7986d8c15394efed9495f11610aef7fa": {
		functionName: "requestSignInOtp_createServerFn_handler",
		importer: () => import("./_ssr/otp-auth.functions-DlSk54jp.mjs")
	},
	"6f633a35e95c4fa3aa8de5b5d4fdfdca34939b6f119e9f5f97b744d22b19e44d": {
		functionName: "notifyMatchingUsersPush_createServerFn_handler",
		importer: () => import("./_ssr/push.functions-BNXYDyoe.mjs")
	},
	"86c360a3410e5d9d7970f27d9fd909595fa0a33751ac31b1a62c92a0dfdb84be": {
		functionName: "verifySignInOtp_createServerFn_handler",
		importer: () => import("./_ssr/otp-auth.functions-DlSk54jp.mjs")
	}
};
async function getServerFnById(id, access) {
	const serverFnInfo = manifest[id];
	if (!serverFnInfo) throw new Error("Server function info not found for " + id);
	const fnModule = serverFnInfo.module ?? await serverFnInfo.importer();
	if (!fnModule) throw new Error("Server function module not resolved for " + id);
	const action = fnModule[serverFnInfo.functionName];
	if (!action) throw new Error("Server function module export not resolved for serverFn ID: " + id);
	return action;
}
//#endregion
export { getServerFnById as t };
