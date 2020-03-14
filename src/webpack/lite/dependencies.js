const packages = {};

// Insert packages here

window.nativeRequire = window.require;
window.require = (path) => packages[path];

(function() {
    const script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "/$ENTRYPOINT";
    document.body.appendChild(script);
})();
