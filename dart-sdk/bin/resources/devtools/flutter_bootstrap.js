(()=>{var P=()=>navigator.vendor==="Google Inc."||navigator.agent==="Edg/",L=()=>typeof ImageDecoder>"u"?!1:P(),U=()=>typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u",W=()=>{let i=[0,97,115,109,1,0,0,0,1,5,1,95,1,120,0];return WebAssembly.validate(new Uint8Array(i))},f={hasImageCodecs:L(),hasChromiumBreakIterators:U(),supportsWasmGC:W(),crossOriginIsolated:window.crossOriginIsolated};var h=j();function j(){let i=document.querySelector("base");return i&&i.getAttribute("href")||""}function m(...i){return i.filter(t=>!!t).map((t,n)=>n===0?_(t):K(_(t))).filter(t=>t.length).join("/")}function K(i){let t=0;for(;t<i.length&&i.charAt(t)==="/";)t++;return i.substring(t)}function _(i){let t=i.length;for(;t>0&&i.charAt(t-1)==="/";)t--;return i.substring(0,t)}function I(i,t){return i.canvasKitBaseUrl?i.canvasKitBaseUrl:t.engineRevision&&!t.useLocalCanvasKit?m("https://www.gstatic.com/flutter-canvaskit",t.engineRevision):"/canvaskit"}var v=class{constructor(){this._scriptLoaded=!1}setTrustedTypesPolicy(t){this._ttPolicy=t}async loadEntrypoint(t){let{entrypointUrl:n=m(h,"main.dart.js"),onEntrypointLoaded:e,nonce:r}=t||{};return this._loadJSEntrypoint(n,e,r)}async load(t,n,e,r,s){s??=o=>{o.initializeEngine(e).then(c=>c.runApp())};let{entryPointBaseUrl:a}=e;if(t.compileTarget==="dart2wasm")return this._loadWasmEntrypoint(t,n,a,s);{let o=t.mainJsPath??"main.dart.js",c=m(h,a,o);return this._loadJSEntrypoint(c,s,r)}}didCreateEngineInitializer(t){typeof this._didCreateEngineInitializerResolve=="function"&&(this._didCreateEngineInitializerResolve(t),this._didCreateEngineInitializerResolve=null,delete _flutter.loader.didCreateEngineInitializer),typeof this._onEntrypointLoaded=="function"&&this._onEntrypointLoaded(t)}_loadJSEntrypoint(t,n,e){let r=typeof n=="function";if(!this._scriptLoaded){this._scriptLoaded=!0;let s=this._createScriptTag(t,e);if(r)console.debug("Injecting <script> tag. Using callback."),this._onEntrypointLoaded=n,document.head.append(s);else return new Promise((a,o)=>{console.debug("Injecting <script> tag. Using Promises. Use the callback approach instead!"),this._didCreateEngineInitializerResolve=a,s.addEventListener("error",o),document.head.append(s)})}}async _loadWasmEntrypoint(t,n,e,r){if(!this._scriptLoaded){this._scriptLoaded=!0,this._onEntrypointLoaded=r;let{mainWasmPath:s,jsSupportRuntimePath:a}=t,o=m(h,e,s),c=m(h,e,a);this._ttPolicy!=null&&(c=this._ttPolicy.createScriptURL(c));let p=WebAssembly.compileStreaming(fetch(o)),l=await import(c),w;t.renderer==="skwasm"?w=(async()=>{let u=await n.skwasm;return window._flutter_skwasmInstance=u,{skwasm:u.wasmExports,skwasmWrapper:u,ffi:{memory:u.wasmMemory}}})():w={};let d=await l.instantiate(p,w);await l.invoke(d)}}_createScriptTag(t,n){let e=document.createElement("script");e.type="application/javascript",n&&(e.nonce=n);let r=t;return this._ttPolicy!=null&&(r=this._ttPolicy.createScriptURL(t)),e.src=r,e}};async function S(i,t,n){if(t<0)return i;let e,r=new Promise((s,a)=>{e=setTimeout(()=>{a(new Error(`${n} took more than ${t}ms to resolve. Moving on.`,{cause:S}))},t)});return Promise.race([i,r]).finally(()=>{clearTimeout(e)})}var y=class{setTrustedTypesPolicy(t){this._ttPolicy=t}loadServiceWorker(t){if(!t)return console.debug("Null serviceWorker configuration. Skipping."),Promise.resolve();if(!("serviceWorker"in navigator)){let o="Service Worker API unavailable.";return window.isSecureContext||(o+=`
The current context is NOT secure.`,o+=`
Read more: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts`),Promise.reject(new Error(o))}let{serviceWorkerVersion:n,serviceWorkerUrl:e=m(h,`flutter_service_worker.js?v=${n}`),timeoutMillis:r=4e3}=t,s=e;this._ttPolicy!=null&&(s=this._ttPolicy.createScriptURL(s));let a=navigator.serviceWorker.register(s).then(o=>this._getNewServiceWorker(o,n)).then(this._waitForServiceWorkerActivation);return S(a,r,"prepareServiceWorker")}async _getNewServiceWorker(t,n){if(!t.active&&(t.installing||t.waiting))return console.debug("Installing/Activating first service worker."),t.installing||t.waiting;if(t.active.scriptURL.endsWith(n))return console.debug("Loading from existing service worker."),t.active;{let e=await t.update();return console.debug("Updating service worker."),e.installing||e.waiting||e.active}}async _waitForServiceWorkerActivation(t){if(!t||t.state==="activated")if(t){console.debug("Service worker already active.");return}else throw new Error("Cannot activate a null service worker!");return new Promise((n,e)=>{t.addEventListener("statechange",()=>{t.state==="activated"&&(console.debug("Activated new service worker."),n())})})}};var g=class{constructor(t,n="flutter-js"){let e=t||[/\.js$/,/\.mjs$/];window.trustedTypes&&(this.policy=trustedTypes.createPolicy(n,{createScriptURL:function(r){if(r.startsWith("blob:"))return r;let s=new URL(r,window.location),a=s.pathname.split("/").pop();if(e.some(c=>c.test(a)))return s.toString();console.error("URL rejected by TrustedTypes policy",n,":",r,"(download prevented)")}}))}};var k=i=>{let t=WebAssembly.compileStreaming(fetch(i));return(n,e)=>((async()=>{let r=await t,s=await WebAssembly.instantiate(r,n);e(s,r)})(),{})};var T=(i,t,n,e)=>window.flutterCanvasKit?Promise.resolve(window.flutterCanvasKit):(window.flutterCanvasKitLoaded=new Promise((r,s)=>{let a=n.hasChromiumBreakIterators&&n.hasImageCodecs;if(!a&&t.canvasKitVariant=="chromium")throw"Chromium CanvasKit variant specifically requested, but unsupported in this browser";let o=a&&t.canvasKitVariant!=="full",c=e;o&&(c=m(c,"chromium"));let p=m(c,"canvaskit.js");i.flutterTT.policy&&(p=i.flutterTT.policy.createScriptURL(p));let l=k(m(c,"canvaskit.wasm")),w=document.createElement("script");w.src=p,t.nonce&&(w.nonce=t.nonce),w.addEventListener("load",async()=>{try{let d=await CanvasKitInit({instantiateWasm:l});window.flutterCanvasKit=d,r(d)}catch(d){s(d)}}),w.addEventListener("error",s),document.head.appendChild(w)}),window.flutterCanvasKitLoaded);var E=(i,t,n,e)=>new Promise((r,s)=>{let a=m(e,"skwasm.js");i.flutterTT.policy&&(a=i.flutterTT.policy.createScriptURL(a));let o=k(m(e,"skwasm.wasm")),c=document.createElement("script");c.src=a,t.nonce&&(c.nonce=t.nonce),c.addEventListener("load",async()=>{try{let p=await skwasm({instantiateWasm:o,locateFile:(l,w)=>{let d=w+l;return d.endsWith(".worker.js")?URL.createObjectURL(new Blob([`importScripts("${d}");`],{type:"application/javascript"})):d}});r(p)}catch(p){s(p)}}),c.addEventListener("error",s),document.head.appendChild(c)});var C=class{async loadEntrypoint(t){let{serviceWorker:n,...e}=t||{},r=new g,s=new y;s.setTrustedTypesPolicy(r.policy),await s.loadServiceWorker(n).catch(o=>{console.warn("Exception while loading service worker:",o)});let a=new v;return a.setTrustedTypesPolicy(r.policy),this.didCreateEngineInitializer=a.didCreateEngineInitializer.bind(a),a.loadEntrypoint(e)}async load({serviceWorkerSettings:t,onEntrypointLoaded:n,nonce:e,config:r}={}){r??={};let s=_flutter.buildConfig;if(!s)throw"FlutterLoader.load requires _flutter.buildConfig to be set";let a=u=>{switch(u){case"skwasm":return f.crossOriginIsolated&&f.hasChromiumBreakIterators&&f.hasImageCodecs&&f.supportsWasmGC;default:return!0}},o=(u,b)=>{switch(u.renderer){case"auto":return b=="canvaskit"||b=="html";default:return u.renderer==b}},c=u=>u.compileTarget==="dart2wasm"&&!f.supportsWasmGC||r.renderer&&!o(u,r.renderer)?!1:a(u.renderer),p=s.builds.find(c);if(!p)throw"FlutterLoader could not find a build compatible with configuration and environment.";let l={};l.flutterTT=new g,t&&(l.serviceWorkerLoader=new y,l.serviceWorkerLoader.setTrustedTypesPolicy(l.flutterTT.policy),await l.serviceWorkerLoader.loadServiceWorker(t).catch(u=>{console.warn("Exception while loading service worker:",u)}));let w=I(r,s);p.renderer==="canvaskit"?l.canvasKit=T(l,r,f,w):p.renderer==="skwasm"&&(l.skwasm=E(l,r,f,w));let d=new v;return d.setTrustedTypesPolicy(l.flutterTT.policy),this.didCreateEngineInitializer=d.didCreateEngineInitializer.bind(d),d.load(p,l,r,e,n)}};window._flutter||(window._flutter={});window._flutter.loader||(window._flutter.loader=new C);})();
//# sourceMappingURL=flutter.js.map

if (!window._flutter) {
  window._flutter = {};
}
_flutter.buildConfig = {"engineRevision":"be7db94196fee940e319363f7ed0c486a780ae50","builds":[{"compileTarget":"dart2js","renderer":"canvaskit","mainJsPath":"main.dart.js"}]};


// Unregister the old custom DevTools service worker (if it exists). It was
// removed in: https://github.com/flutter/devtools/pull/5331
function unregisterDevToolsServiceWorker() {
  if ('serviceWorker' in navigator) {
    const DEVTOOLS_SW = 'service_worker.js';
    const FLUTTER_SW = 'flutter_service_worker.js';
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for (let registration of registrations) {
            const activeWorker = registration.active;
            if (activeWorker != null) {
                const url = activeWorker.scriptURL;
                if (url.includes(DEVTOOLS_SW) && !url.includes(FLUTTER_SW)) {
                    registration.unregister();
                }
            }
        }
    });
  }
}

// Bootstrap app for 3P environments:
function bootstrapAppFor3P() {
  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: "3036079624",
    },
    config: {
      canvasKitBaseUrl: 'canvaskit/'
    }
  });
}

// Bootstrap app for 1P environments:
function bootstrapAppFor1P() {
  _flutter.loader.load();
}

unregisterDevToolsServiceWorker();
bootstrapAppFor3P();
